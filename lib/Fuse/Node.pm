package Fuse::Node;

use Moose;


use Carp qw(croak carp);

use Data::Dumper;

has name => (
	is	=> 'ro',
	isa	=> 'Str',
);

has 'Dev' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'inode' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'type' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	1
);

has 'rdev' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'blocks' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	1
);

has 'gid' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'uid' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'nlink' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	1
);

has 'blksize' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	1024
);

has 'atime' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'mtime' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'ctime' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);

has 'size' => (
	is	=>	'ro',
	isa	=>	'Int',
	default	=>	0
);


has nodes => (
	is	=> 'ro',
	isa	=> 'HashRef[Fuse::Node]',
	lazy_build => 1
);

sub _build_nodes {
	return {};
}

my $mode_shift = {
	S_IFMT  => 0170000,
	S_IFSOCK=> 0140000,
	S_IFLNK => 0120000,
	S_IFREG => 0100000,
	S_IFBLK => 0060000,
	S_IFDIR => 0040000,
	S_IFCHR => 0020000,
	S_IFIFO => 0010000,
	S_ISUID => 0004000,
	S_ISGID => 0002000,
	S_ISVTX => 0001000,
};

#sub new {
#	my $class = shift;
#	my $opts =  (@_ % 2) ?  { name => shift } :  {@_} ;
#
#	$opts->{nodes} = {};
#
#	# check required parms 
#	foreach my $key (qw(name)) {
#		if (not exists($opts->{$key})) {
#			croak "$key is a required option";
#		}
#	}
#
#	# set defaults
#	foreach my $key (keys %$defaults) {
#		next if (exists ($opts->{$key}));
#		$opts->{$key} = $defaults->{$key};
#	}
#
#	return bless ($opts, $class);
#}
#
#>---$file->{stat} = [$dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks];@
#sub stat {
#	
#}

sub BUILDARGS {
	my $class = shift;
	if ( @_ == 1 && not ref $_[0] ) {
		return { name => $_[0] };
	} else {
		return $class->SUPER::BUILDARGS(@_);
	}
}

sub add_node {
	my $self = shift;
	my $node = shift;
	$node->{parent} = $self;
	die unless defined ($node->does('Fuse::Node'));
	$self->nodes->{$node->{name}} = $node;
	return $node;
}

sub get_node {
	my ($self, $node) = @_;
	return unless $self->has_nodes;

	my $paths;
	warn "translating $node";
	if (not ref $node) {

		$paths = $self->path_split($node);
	} elsif (ref ($node) eq 'ARRAY')  {
		$paths = $node;
	} else {
		die "unknown path type ". ref $node;
	}
	warn "paths contains " . Dumper $paths;
	my $path  = shift @$paths;
	warn "looking up $path";
	return if (not defined $path);

	# if non existant path return
#	return if (not defined ($self->nodes()->{$path}));

	# recurse the call if we have more to drill down
	if (@$paths > 0 ) {
		return $self->nodes->{$path}->get_node($path);
	} elsif ( @$paths == 0 && $path eq $self->name() ) {
		return $self;
	}
	warn "ookay my name is " . $self->name();

	# else we should have the node (or not) so return it
	return $self->nodes->{$node};
}


sub node_exists {
	my ($self, $node) = @_;
	return defined $self->get_node($node);
}

sub path_split {
	my ($self, $path) = @_;
#	return wantarray ? ("/") : ["/"] if ($path eq "/") ;

	my @path = split /\//, $path;
	if (@path && $path[0] eq "") {
		$path[0] = '/';
	};
#	unshift @path, "/";
	return wantarray ?  @path : \@path;
}

1;
