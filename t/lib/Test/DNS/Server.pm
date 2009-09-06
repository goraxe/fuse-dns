package Test::DNS::Server;

use strict;
use warnings;

use Net::DNS;

use Net::DNS::Nameserver;
use Carp qw(carp croak);
use Data::Dumper;
sub reply_handler {
	print Dumper \@_;
}
{
my %new_params = ( 
			LocalAddr => "127.0.0.1", 
			LocalPort => 5353,
			ReplyHandler => \&reply_handler);
sub new {
	my $class = shift;
	my $self  = { @_ };

	foreach (keys %$self) {
		if (not exists $new_params{$_}) {
			croak "Unknown parameter $_";
		}
	}

	foreach (grep {$new_params{$_}} keys %new_params) {
		if (not exists $self->{$_}) {
			$self->{$_} ||= $new_params{$_};
#			croak "Missing required parameter $_";
		}
	}
	bless $self, $class;
}
}


sub create_server {
	my $self = shift;
	return "DNS server all ready running" if $self->{child};
	my $pid = fork();
	if ($pid == 0 ) {
		print "creating Net::DNS::Nameserver  object\n";
		my $ns = Net::DNS::Nameserver->new(%$self) ||
			croak "could not create Net::DNS:::Server object";
		print Dumper $ns;
		$ns->main_loop(); # never returns

	} 
	elsif ($pid > 0) {
		$self->{child} = $pid;
	}
	else {
		croak "could not fork: $!";
	}
}

sub destroy_server {
	my $self = shift;
	
	my $pid = $self->{child};
	return unless $pid;
	kill 15, $pid;
	waitpid $pid,0; # just wait forever
}



sub DESTROY {
	my $self = shift;

	if ($self->{child}) {
		my $pid = $self->{child};
		warn "child ($pid) still runing, killing now";
		$self->destroy_server();
	}
}
