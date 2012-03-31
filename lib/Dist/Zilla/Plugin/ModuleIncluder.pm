package Dist::Zilla::Plugin::ModuleIncluder;
use version;
use Moose;

use version;
use MooseX::Types::Perl 'VersionObject';

with qw/Dist::Zilla::Role::ModuleIncluder Dist::Zilla::Role::FileGatherer/;

has module => (
	isa => 'ArrayRef[Str]',
	traits => ['Array'],
	handles => {
		modules => 'elements',
	},
	required => 1,
);

has blacklist => (
	isa => 'ArrayRef[Str]',
	traits => ['Array'],
	handles => {
		blacklisted_modules => 'elements',
	},
	default => sub { [] },
);

has background_perl => (
	is => 'ro',
	isa => VersionObject,
	default => sub { version->new('5.008001') },
	coerce => 1,
);

has only_deps => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

sub gather_files {
	my ($self, $arg) = @_;
	$self->include_modules({ map { ($_ => $self->only_deps ) } $self->modules }, $self->background_perl, { blacklist => [ $self->blacklisted_modules ] });
	return;
}

sub mvp_multivalue_args {
	return qw/module blacklist/;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

#ABSTRACT: explicitly include modules into a distribution

__END__

=for Pod::Coverage
gather_files
mvp_multivalue_args
=end

=head1 SYNOPSIS

In dist.ini:

 [ModuleIncluder]
 module = Foo
 module = Bar
 background_perl = 5.008001 #default value
 only_deps = 0 #default

=head1 DESCRIPTION

This module allows you to explicitly include a module and its dependencies in C<inc/>. At least one module must be given.

=over 4

=item * module

Add a module to be included. This option can be given more than once.

=item * background_perl

Set the background perl version. If the (appropriate version of the) module was present in that release of perl, it will be omitted from C<inc>. It defaults to 5.8.1.

=item * only_deps

Do not include the specified modules, only their dependencies. Note that it still includes the module if something else depends on it.

=back
