package Dist::Zilla::Role::ModuleIncluder;

use Moose::Role;

use Dist::Zilla::File::InMemory;
use File::Slurp 'read_file';
use List::MoreUtils 'uniq';
use Module::CoreList;
use Module::Metadata;
use Perl::PrereqScanner;

use namespace::autoclean;

with 'Dist::Zilla::Role::FileInjector';

sub _mod_to_filename {
	my $module = shift;
	return File::Spec->catfile('inc', split / :: | ' /x, $module) . '.pm';
}

## no critic (Variables::ProhibitPackageVars)
sub _core_has {
	my ($module, $wanted_version, $background_perl) = @_;
	my $offered_version = $Module::CoreList::version{$background_perl}{$module};
	return defined $offered_version and $offered_version >= $wanted_version;
}

sub _get_reqs {
	my ($reqs, $scanner, $module, $background) = @_;
	my $module_file = Module::Metadata->find_module_by_name($module) or confess "Could not find module $module";
	my %new_reqs = %{ $scanner->scan_file($module_file)->as_string_hash };
	my @real_reqs = grep { $_ ne 'perl' and (not defined $reqs->{$_} or $reqs->{$_} < $new_reqs{$_} ) and not _core_has($_, $new_reqs{$_}, $background) } keys %new_reqs;
	for my $req (@real_reqs) {
		$reqs->{$req} = $new_reqs{$req};
		_get_reqs($reqs, $scanner, $req, $background);
	}
	return;
}

sub include_modules {
	my ($self, $modules, $background, $options) = @_;
	my %reqs;
	my $scanner = Perl::PrereqScanner->new;
	_get_reqs(\%reqs, $scanner, $_, $background->numify) for @{$modules};
	my %location_for = map { _mod_to_filename($_) => Module::Metadata->find_module_by_name($_) } uniq(($options->{only_deps} ? () : @{$modules}), keys %reqs);
	for my $filename (keys %location_for) {
		my $file = Dist::Zilla::File::InMemory->new({name => $filename, content => scalar read_file($location_for{$filename})});
		$self->add_file($file);
	}
	return;
}

1;

__END__

#ABSTRACT: Include a module and its dependencies in inc/

=head1 DESCRIPTION

This role allows your plugin to include one or more modules into the distribution for build time purposes. The modules will not be installed.

=method include_modules($modules, $background_perl, $options)

Include all modules in C<@$modules> and their dependencies in C<inc/>, except those that are core modules as of perl version C<$background_perl> (which is expected to be a version object). C<$options> is a hash that currently has only one possible key, only_deps, to specify the dependencies of the modules should be included without the module itself.
