use strict;
use warnings;

use Test::More tests =>1;

use FindBin qw($Bin);
use lib qq($Bin/../lib);

use_ok('Fuse::Fs',"can use Fuse::Fs");

my $mnt = "$Bin/mnt";

my $fs = Fuse::Fs->new(mount_point => $mnt);

isa_ok($fs,"Fuse::Fs", "Fuse Object Created");

ok($fs->create_path("/test1"), "create new directory");
