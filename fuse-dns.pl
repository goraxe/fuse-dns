#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS;
use Fuse;
use POSIX qw(ENOENT EISDIR EINVAL);
use Data::Dumper;

my $rr_methods = {
	A => {
		type 	=> 0100,
		content => [qw(address)],
	},
	SOA => {
		content => [qw(mname rname serial refresh retry expire minimum)],
		type 	=> 0100,
	},
	TXT => {
		content => [qw(char_str_list)],
		type 	=> 0100,
	},
	CNAME => {
		link => "cname",
		type 	=> 0120,
	},
};


my $mountpoint = "/mnt/amity.lan";
my $zone	   = "amity.lan";
my $dns_server = "192.168.0.1";


sub read_domain_axfr {
	my $zone = shift;

	my $res = Net::DNS::Resolver->new;
	$res->nameservers($dns_server);

	my @entries = $res->axfr($zone);

	my %fs;
	$fs{"."} = dns_dir(".");
	$fs{"content"} = \%fs;
	foreach my $rr (@entries) {
	#   $rr->print;
		my $file_name;
	#	if ($rr->{name} eq $zone) {
	#		$file_name = ".";
	#	} else {
			$file_name =  $rr->{name};
	#	}
		if (not exists $fs{$file_name}) {
			$fs{$file_name} = dns_dir($file_name); #[ { name=> $rr->{type},  ];
			push @{$fs{"."}->{content}}, $file_name;
		}
		push @{$fs{"$file_name"}->{content}}, dns_rr_2_file($rr);

}

sub dns_dir {
	my $name = shift;
	my $file = { type=>"dir", name=>$name,  content=>[] };

	
	my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,1,0,0,1,1024);
	my ($atime, $ctime, $mtime);

	my $modes = (0040 << 9) + 0755;
	my $size = 1024;
	$atime = $ctime = $mtime = time()-1000;
	$file->{stat} = [$dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks];
	$file;
}

sub dns_rr_2_file {
	my $rr = shift;
	my $file = {name => $rr->{type}, type=>"file"};

	my $rr_type = $rr_methods->{$rr->{type}};
	my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,1,0,0,1,1024);
	my ($atime, $ctime, $mtime);

	my $modes = ($rr_type->{type} << 9) + 0755;
	if (exists($rr_type->{content})) {
		my @c;
		foreach my $m (@{$rr_type->{content}}) {
			print "gonna try $m on $rr->{type} = "  . $rr->$m . "\n";
			push @c, "$m = " . $rr->$m;
		}
		$file->{content} = join "\n", @c;
	}
	my $size = 1024;
	$atime = $ctime = $mtime = time()-1000;
	$file->{stat} = [$dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks];
	$file;
}


sub filename_fixup {
	my ($file) = shift;
	$file =~ s,^/,,;
	$file = '.' unless length($file);
	return $file;
}
sub dns_find_file {
	my $file = shift;
	my @path = split /\//, $file;
	my $f = \%fs;
file:
	foreach my $p (@path) {
		print "going around the loop\n";
		print "\t->$p" .ref $f . "\n";
		if (ref $f->{content} eq "ARRAY") {
			foreach (@{$f->{content}}) {
				next if (not ref $_ eq "HASH");
				if ($_->{name} eq $p) {
					$f = $_;
					last file;
				}
			}
			return;
		} elsif (exists ($f->{content}->{$p}))  {
#			print " not an array checking $f\n";
			$f = $f->{content}->{$p}; # if exists $f->{content}->{$p};
		} else {
			#file not found
			print "file not found\n";
			return;
		}
		last if  $f->{type} eq "file";
	}

	return $f;
}

sub dns_getattr {
	my $file = shift;
	$file = filename_fixup ($file);
	print "dns_getattr called with: $file\n";
#	my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,1,0,0,1,1024);
#	my $modes = (0040 << 9) + 0755;
#	my $size = 1024;

	my $f = dns_find_file($file);

#	my ($atime, $ctime, $mtime);
#	$atime = $ctime = $mtime = time()-1000;
#	print(join(",",($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)),"\n");
#	print "here we go\n";

	return -ENOENT() unless $f;
	print "found $f->{name}\n";
	print join " ", keys %$f;
	return if not $f->{stat};
	return @{$f->{stat}}; 
#	return ($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
}

sub dns_getdir {
	my $dir = shift;
	$dir = filename_fixup($dir); 
	print "dns_getdir called with $dir\n";
#	print Dumper $fs{$dir};
#	print Dumper map [ ref $_ =~ m/HASH/ ?  $_->{name} : $_  ], (@{$fs{$dir}->{content}}),0;
#	((@{$fs{$dir}->{content}}),0);
	my @ret;# =map { ref $_ =~ /HASH/ ?  $_->{name} : $_  } (@{$fs{$dir}->{content}},0);
	foreach  (@{$fs{$dir}->{content}}) {
		if (ref $_ eq "HASH" ) {
			push @ret, $_->{name};
		} else {
			push @ret, $_;
		}
		 
	}
	push @ret, 0;
	print Dumper \@ret;
	return  @ret;
}

sub dns_open {
	my $file = shift;
	$file = filename_fixup($file);
	my $f = dns_find_file($file);
	# todo check permissions
	return 0;
}

sub dns_read {
	my $file = shift;
	my $size = shift;
	my $offset = shift;
	$file = filename_fixup($file);
	my $f = dns_find_file($file);

	return -ENOENT() unless $f;
	return -EINVAL() if $offset > length($f->{content});
	return 0 if $offset == length($f->{content});
	return substr($f->{content},$offset,$size);


}

sub dns_statfs {
	print "dns_statfs called\n";
}

Fuse::main (mountpoint=> $mountpoint,
	getattr=> "main::dns_getattr",
	getdir => "main::dns_getdir",
	statfs => "main::dns_statfs",
	open   => "main::dns_open",
	read   => "main::dns_read", 
);
