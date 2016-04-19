package Dist::Zilla::Role::ModuleIncluder;

use Moose::Role;

use Dist::Zilla::File::InMemory;
use File::Slurp::Tiny 'read_file';
use Scalar::Util qw/reftype/;
use List::Util 1.45 'uniq';
use Module::CoreList;
use Module::Metadata;
use Perl::PrereqScanner;

use namespace::autoclean;

with 'Dist::Zilla::Role::FileInjector';

sub _mod_to_filename {
	my $module = shift;
	return File::Spec->catfile('inc', split / :: | ' /x, $module) . '.pm';
}

my $version = \%Module::CoreList::version;

## no critic (Variables::ProhibitPackageVars)

sub _should_skip {
	my ($module, $version, $blacklist, $background) = @_;
	return $blacklist->{$module} || exists $background->{$module} && ($version <= 0 || $background->{$module} >= $version);
}

sub _get_reqs {
	my ($reqs, $scanner, $module, $background, $blacklist) = @_;
	my $module_file = Module::Metadata->find_module_by_name($module) or confess "Could not find module $module";
	my %new_reqs = %{ $scanner->scan_file($module_file)->as_string_hash };
	my @real_reqs = grep { !_should_skip($_, $new_reqs{$_}, $blacklist, $background) } keys %new_reqs;
	for my $req (@real_reqs) {
		if (defined $reqs->{$module}) {
			next if $reqs->{$module} >= $new_reqs{$req};
			$reqs->{$req} = $new_reqs{$req};
		}
		else {
			$reqs->{$req} = $new_reqs{$req};
			_get_reqs($reqs, $scanner, $req, $background, $blacklist);
		}
	}
	return;
}

sub _version_normalize {
	my $version = shift;
	return $version >= 5.010 ? sprintf "%1.6f", $version->numify : $version->numify;
}

sub include_modules {
	my ($self, $modules, $background, $options) = @_;
	my %modules = reftype($modules) eq 'HASH' ? %{$modules} : map { $_ => 0 } @{$modules};
	my %reqs;
	my $scanner = Perl::PrereqScanner->new;
	my %blacklist = map { ( $_ => 1 ) } 'perl', @{ $options->{blacklist} || [] };
	_get_reqs(\%reqs, $scanner, $_, $version->{ _version_normalize($background) }, \%blacklist) for keys %modules;
	my @modules = grep { !$modules{$_} } keys %modules;
	my %location_for = map { _mod_to_filename($_) => Module::Metadata->find_module_by_name($_) } uniq(@modules, keys %reqs);
	return map {
		my $filename = $_;
		my $file = Dist::Zilla::File::InMemory->new({name => $filename, content => read_file($location_for{$filename})});
		$self->add_file($file);
		$file;
	} keys %location_for;
}

1;

#ABSTRACT: Include a module and its dependencies in inc/

__END__

=head1 DESCRIPTION

This role allows your plugin to include one or more modules into the distribution for build time purposes. The modules will not be installed.

=method include_modules($modules, $background_perl, $options)

Include all modules (and their dependencies) in C<@$modules>, in F<inc/>, except those that are core modules as of perl version C<$background_perl> (which is expected to be a version object). C<$options> is a hash that currently has only one possible key, C<blacklist>, to specify dependencies that shouldn't be included.

All the file objects that were added to the distribution are returned as a list.

=cut

