package Fuse::Fs;

#use strict;
#use warnings;

#use base 'Fuse::Node';


use Moose;

use Fuse::Dir;

extends 'Fuse::Node';


#sub new {
#	my $class= shift;
#	my $opts = {@_};
#	$opts->{name} = ".";
##	my $self = $class->SUPER::new(%$opts);

#	return bless($self, $class);

#}

has '+name' => (
	default => '/',
);

sub create_path {
	my $self = shift;
	my $path = shift;
	my @parts = split /\//, $path;

	my $node = $self;
	warn "attempting to create path for $path";
	foreach my $dir (@parts) {
		$dir = "/" if ($dir eq "");
		if ($node->get_node($dir)){
			warn "got existing node $dir";
			$node = $node->get_node($dir);

		} else {
			warn "creating new node $dir";
			my $dd = Fuse::Dir->new(
				name=>$dir, 
				perms=> $self->{umask}
			);
			$node = $node->add_node($dd);
		}
	}
	return $node;
}

sub path_exists {
	my $self = shift;
	my $path = shift;

	my @parts = split /\//, $path;
	my $node = $self->nodes;
	while (my $dir = shift @parts) {
		return unless $node->get_node($dir);
		$node = $node->get_node($dir);
	}
	return $node;
}


1;
