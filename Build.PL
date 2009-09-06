#!/usr/bin/perl 

use Module::Build;
use strict;
use warnings;
my $build = Module::Build->new (
	module_name => 'Fuse::DNS',
	license		=> 'perl',
);
$build->create_build_script();
