use strict;
use warnings;

use Test::More tests=>5;


use FindBin qw($Bin);
use lib qq($Bin/../lib);

use_ok('Fuse::Node','use module Fuse::Node');

my $n1 = Fuse::Node->new(name=>"root");

# create a node
isa_ok($n1, 'Fuse::Node', "created a node");

# create another node
my $n2 = Fuse::Node->new("subdir");

# create a node
isa_ok($n2, 'Fuse::Node', "created a node");

# add first node to 2nd node
my $n3 = $n1->add_node($n2);
is_deeply($n3,$n2, "correct node returned");

# check we had add as child
ok($n1->get_node("subdir"), "has sub directory");
