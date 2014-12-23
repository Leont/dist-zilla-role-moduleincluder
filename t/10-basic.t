#!perl
use strict;
use warnings;
# vim: ts=2 sts=2 sw=2 noet

use Test::More 0.88;

use Test::DZil;
use Path::Class;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/' },
  { },
);

$tzil->build;

my $dir = dir($tzil->tempdir, 'build');

ok -e, "$_ exists" for map { my $file = "$_.pm"; $dir->file('inc', split /::|'/, $file) } qw{DateTime DateTime::Locale Params::Validate};
ok ! -e, "$_ doesn't exists" for map { my $file = "$_.pm"; $dir->file('inc', split /::|'/, $file) } qw{strict warnings Scalar::Util};

done_testing;
