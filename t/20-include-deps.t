use strict;
use warnings;
# vim: ts=4 sts=0 sw=0 noet

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use Test::Deep;

my $tzil = Builder->from_config(
	{ dist_root => 'does-not-exist' },
	{
		add_files => {
			path(qw(source dist.ini)) => simple_ini(
				[ GatherDir => ],
				[ ModuleIncluder => {
						module => [ 'DateTime' ],
						background_perl => '5.8.1',
						include_dependencies => 0,
					},
				],
			),
			path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
		},
	},
);

$tzil->chrome->logger->set_debug(1);
is(
	exception { $tzil->build },
	undef,
	'build proceeds normally',
) or diag 'got log messages: ', explain $tzil->log_messages;

my $build_dir = path($tzil->tempdir)->child('build');

ok(-e, "$_ exists in inc/")
	for map {
		my $file = "$_.pm";
		$build_dir->child('inc', split /::|'/, $file)
	} qw{DateTime};

ok( ! -e, "$_ doesn't exist in inc/")
	for map {
		my $file = "$_.pm";
		$build_dir->child('inc', split /::|'/, $file)
	} qw{DateTime::Locale Params::Validate strict warnings Scalar::Util};

diag 'saw log messages: ', explain($tzil->log_messages)
	if not Test::Builder->new->is_passing;

done_testing;
