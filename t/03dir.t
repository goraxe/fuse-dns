
use strict;
use warnings;

use Test::More tests =>2;

use FindBin qw($Bin);
use lib qq($Bin/../lib);

use_ok('Fuse::Dir',"can use Fuse::Dir");


my $dir = Fuse::Dir->new(name=>'test');

isa_ok($dir, "Fuse::Dir", "created a dir");


