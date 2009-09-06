use Test::More tests =>5;

use strict;
use warnings;

use FindBin qw($Bin);
use lib qq($Bin/../lib);

use_ok('Fuse::Node',"can use Fuse::Node");
use_ok('Fuse::Dir',"can use Fuse::Dir");
use_ok('Fuse::File',"can use Fuse::File");
use_ok('Fuse::Fs', "can use Fuse::Fs");
use_ok('Fuse::DNS', "can use Fuse::DNS");
