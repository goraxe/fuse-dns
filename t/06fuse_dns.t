use Test::More tests => 10;

use strict;
use warnings;

use UNIVERSAL qw(isa);
use FindBin qw($Bin);
use lib qq($Bin/../lib);

#use Net::DNS::TestNS;
########################################################
#
#			SETUP TEST HARNESSS
#
########################################################

#my $dns_server = Net::DNS::TestNS->new("./t/test_ns.xml", {Verbose=>1, Validate=>1}); 
#if ($dns_server) {
#	$dns_server->run();
#	sleep 40;
#} else {
#	print "$Net::DNS::TestNS::errorcondition\n";
#}

########################################################
#
#			Run Test Suit
#
########################################################

use_ok('Fuse::DNS', "can use Fuse::DNS");


use Data::Dumper;
# basic construction
{
	my $fs = Fuse::DNS->new(dns_server=>"192.168.0.1");
	if (not isa_ok($fs,"Fuse::DNS", "got instance off filesystem")) {
	diag Dumper $fs;
	}
}

# basic interface
{

	my $fs = Fuse::DNS->new(dns_server=>"192.168.0.1");
	if (not isa_ok($fs,"Fuse::DNS", "got instance off filesystem")) {
	diag Dumper $fs;
	}
	my $path =$fs->dns_to_path("example.com");
	is($path, "/com/example", "dns to path correctly translates");
}
my $fs = Fuse::DNS->new(dns_server=>"192.168.0.1");
ok($fs->add_zone_file(file => "$Bin/example.com.zone"), "add example.com zone file");
#$fs->add_zone("amity.lan");
#$fs->add_zone(
#	zone=>"amity.lan", 
#	axfr_key=>"njvnzkbnd",
#	update_key=>"gkjlknfdk"
#);

ok($fs->path_exists("/com/example"), 'example.com directory exists');

foreach my $name (qw(ns1 ns2 www ftp mail bill fred)) {
	ok($fs->path_exists("/com/example/$name"), "$name.example.com exists");
}

my $node1 = $fs->get_node("/com/example");
isa_ok($node1, 'Fuse::Node', 'found test zone path');
if (not isa($node1, 'Fuse::Node') ) {
	diag "could not get node '/com/example' return is " . (ref $node1 ? ref $node1 : "undef") . " Dumper output " . Dumper ($node1);
	diag ("fs dumper output " . Dumper $fs);
}
else {
	warn "fooey";
}


if (not $fs->node_exists("/com/example/SOA")) {
	my $file = $fs->create_file("/com/example/SOA");
	if (!$file) {
		die $fs->error;
	}
#	$file
}
