#!perl
use strict;
use warnings;
# vim: ts=4 sts=0 sw=0 noet

use Test::More 0.88;

use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/' },
  { },
);

$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');

ok -e, "$_ exists" for map { my $file = "$_.pm"; $build_dir->child('inc', split /::|'/, $file) } qw{DateTime DateTime::Locale Params::Validate};
ok ! -e, "$_ doesn't exists" for map { my $file = "$_.pm"; $build_dir->child('inc', split /::|'/, $file) } qw{strict warnings Scalar::Util};

done_testing;
