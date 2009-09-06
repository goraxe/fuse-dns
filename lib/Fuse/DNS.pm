package Fuse::DNS;

=head1 NAME

Fuse::DNS - Create a virtaule filesystem from DNS queries

=head1 VERSION

Version 1.08

=cut

use strict;
use warnings;
use Net::DNS;
use Net::DNS::ZoneFile::Fast;
use Carp qw(carp croak);

use vars qw($VERSION);
$VERSION='0.1';


use base 'Fuse::Fs';

=head1 SYNOPSIS

	use Fuse::DNS;
	my $fs = Fuse::DNS->new(mount_point=>"/mnt/dns");

=head1 METHODS

=head2 add_zone( zone => $zone )

Performs a zone tansfer against the supplied I<$zone> and populates the filesystem with returned results

=cut

sub add_zone {
	my $self = shift;
	my $zone = shift;
	
	# get the dns records
	my $RR = $self->get_dns_zone($zone)
		or croak "could not get dns zone $zone";
	# translate the zone into a path
	my $path = $self->dns_to_path($zone)
		or croak "could not convert $zone to a path";
	# make sure the path exists
	my $dir = $self->create_path($path)
		or croak "could not create path";
	# create records as files
	return;
}

=head2 add_zone_file ( zone_file => [ $file | $fh ] )

parses a zone file using Net::DNS::ZoneFile::Fast which supports Bind8/9 zone format files.  The Parsed zone is then populated into the virtual filesystem.  Arguemnts are passed straight to Net::DNS::ZoneFile::Fast::parse check that documentation for semantics.

=cut
#die "got here";
sub add_zone_file {
	my $self = shift;
#	my $args = { @_ };
	my $rr = Net::DNS::ZoneFile::Fast::parse(@_);
	$self->add_resources_records($rr);
}

sub add_resources_records {
	my $self = shift;
	my $rr = shift;
	if (ref $rr ne "ARRAY") {
		$rr = [ $rr ];
	}
	foreach my $r (@$rr) {

		my $path = $self->dns_to_path($r->name);
		my $dir = $self->create_path($path);
		warn "adding resource ". $r->name . " at $dir";
	}
	return 1;
}

sub get_dns_zone {
	my $self = shift;
	my $zone = shift;
	my $res = $self->{resolver};

	if (not defined($res)) {
		$res = $self->create_resolver()
			or croak "could not create DNS::Resolver";
	}

	my @entries = $res->axfr($zone);
	return unless scalar @entries;
	return \@entries;
}

sub create_resolver {
	my $self = shift;
	$self->{resolver} = Net::DNS::Resolver->new;
	my $dns_servers = $self->{dns_server}
		or carp "no dns servers given";
	$self->{resolver}->nameservers($dns_servers);

	return $self->{resolver};
}

sub dns_to_path {
	my ($self, $domain) = @_;
	my $path = "/";
	my @parts = split /\./, $domain;
	@parts = reverse @parts;
	$path .= join "/", @parts;
	return wantarray ? @parts : $path;
}



1;
