package Dist::Zilla::Plugin::ModuleIncluder;
use Moose;

with qw/Dist::Zilla::Role::ModuleIncluder Dist::Zilla::Role::FileGatherer/;

has add_module => (
	isa => 'ArrayRef',
	traits => ['Array'],
	handles => {
		modules_to_add => 'elements',
	},
	required => 1,
);

has background_perl => (
	is => 'ro',
	isa => 'Str',
	default => '5.008001',
);

sub gather_files {
	my ($self, $arg) = @_;
	$self->include_modules([$self->modules_to_add], $self->background_perl);
	return;
}

sub mvp_multivalue_args {
	return 'add_module';
}

1;

__END__

#ABSTRACT: explicitly include modules into a distribution

=for Pod::Coverage
gather_files
mvp_multivalue_args
=end

=head1 SYNOPSIS

In dist.ini:

 [ModuleIncluder]
 add_module = Foo
 add_module = Bar
 background_perl = 5.008001 #default value

=head1 DESCRIPTION

This module allows you to explicitly include a module and its dependencies in C<inc/>. At least one module must be given.
