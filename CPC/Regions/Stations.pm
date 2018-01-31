#!/usr/bin/perl

package CPC::Regions::Stations;

=pod

=head1 NAME

CPC::Regions::Stations - Store and manipulate data for user-supplied lists of regions

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::Stations;

=head1 DESCRIPTION

CPC::Regions::Stations inherits all of the functionality of its parent CPC::Regions class. 
Unlike the other CPC::Regions::[Type] inheritors that have a pre-defined set of regional
IDs and names, the CPC::Regions::Stations object constructor takes a user-supplied list
of regional IDs and names via an external reference file.  The external filename is 
stored within the object data, so that only CPC::Regions::Stations objects constructed 
from the same reference file can be used together in arithmetic operations.

See the documentation for the parent CPC::Regions class for more information about what 
the inherior objects can do.

=head3 Structure of the reference file

The CPC::Regions::Stations object constructor must be passed a valid regional reference 
filename that defines the regional IDs and names to be used.  This file must be 
written in the following format for [n] regions:

 ID1|Name1
 ID2|Name2
 ID3|Name3
 ...
 ID[n]|Name[n]

Each region (e.g., station) must be on its own line, and the ID/Name pairs must be 
delimited by the pipe ('|') character.  The IDs do not have to be numeric.

=head3 Distinguishing objects with different reference files

It is possible to construct CPC::Regions::Stations objects in a program that were built 
with different reference files.  This can cause serious problems if two such objects 
were used, for example, in a numeric operation.  Therefore, the reference file 
argument passed to the constructor is stored as the object's "type" and is accessible 
via the CPC::Regions::Stations::GetType method.  Numeric operations are not allowed to 
be performed on two objects with different type values.  It is highly recommended 
that any software written to work with CPC::Regions::Stations objects also check this type 
value before proceeding, to ensure that the objects have identical regional lists.

Example:

 my $result = Foo($obj1,$obj2);
 
 sub Foo {
 	my($arg1,$arg2) = @_;  # Assume we know that these are CPC::Regions::Stations objects
 	croak "Cannot perform Foo on different types of CPC::Regions::Stations objects" if($arg1->GetType ne $arg2->GetType);
 	...
 }

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Hash::Util qw(lock_keys);

# --- Inheritance ---

use base qw(CPC::Regions);

=pod

=head1 CLASS METHODS

=cut

=pod

=head2 Constructors

The CPC::Regions::Stations class provides two specialized constructors to create objects in 
the calling program.

=cut

=pod

=head3 new

 my $data = CPC::Regions::Stations->new("/path/to/ref_file.txt");

Returns a CPC::Regions::Stations object to the calling program where all regional data values 
are set to the object's default missing value.  Regional IDs are defined by the user 
supplied reference file.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	croak "$class->new: Reference file required - exception thrown" if(not @_);
	my $ref   = shift;
	croak "$class->new: $ref does not exist or is empty - exception thrown" if(not -s $ref);
	croak "$class->new: Could not open $ref - $! - exception thrown" if(not open(REF,'<',$ref));
	my @ref   = <REF>; chomp(@ref);
	close(REF);

	# Ingest reference data!
	my %ref;  # Hash will be used to check for duplicate IDs!

	foreach my $region (@ref) {
		my $pipes = $region =~ tr/\|//;
		if($pipes != 1) { croak "$class->new: $region is an invalid regional reference - exception thrown"; }
		my($id,$name) = split(/\|/,$region);
		$ref{$id}     = $name;
	}

	# Check for duplicate IDs!
	croak "$class->new: Duplicate regions found in $ref - exception thrown" if(scalar(keys %ref) != scalar(@ref));

	$self->{idsNumeric} = 1;

	foreach my $id (keys %ref) {
		$self->{data}->{$id} = $self->{missing};
		unless(looks_like_number($id)) { $self->{idsNumeric} = 0; }
	}

	$self->{type} = $ref;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newNames

 my $names = CPC::Regions::Stations->newNames("/path/to/ref_file.txt");

Returns a CPC::Regions::Stations object to the calling program where all regional data values 
are set to the name of the region (e.g., station).  The regional IDs and names are defined 
via the user supplied reference file.

=cut

sub newNames {
	my $class = shift;
	my $self  = $class->SUPER::new();
	croak "$class->newNames: Reference file required - exception thrown" if(not @_);
	my $ref   = shift;
	croak "$class->newNames: $ref does not exist or is empty - exception thrown" if(not -s $ref);
	croak "$class->newNames: Could not open $ref - $! - exception thrown" if(not open(REF,'<',$ref));
	my @ref   = <REF>; chomp(@ref);
	close(REF);

	# Ingest reference data!
	my %ref;  # Hash will be used to check for duplicate IDs!

	foreach my $region (@ref) {
		my $pipes = $region =~ tr/\|//;
		if($pipes != 1) { croak "$class->newNames: $region is an invalid regional reference - exception thrown"; }
		my($id,$name) = split(/\|/,$region);
		$ref{$id}     = $name;
	}

	# Check for duplicate IDs!
	croak "$class->newNames: Duplicate regions found in $ref - exception thrown" if(scalar(keys %ref) != scalar(@ref));

	$self->{idsNumeric} = 1;

	foreach my $id (keys %ref) {
		$self->{data}->{$id} = $ref{$id};
		unless(looks_like_number($id)) { $self->{idsNumeric} = 0; }
	}

	$self->{type} = $ref;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

# --- Final POD Documentation ---

=pod

=head1 SEE ALSO

=begin html

<ul>
<li><a href="../../doc/Regions.html">CPC::Regions (parent class) documentation</a></li>
</ul>

=end html

=head1 AUTHOR

=begin html

<a href="mailto:Adam.Allgood@noaa.gov">Adam Allgood</a>
<br><br>
<a href="http://www.cpc.ncep.noaa.gov">Climate Prediction Center</a> - DOC/NOAA/NWS/NCEP
<br>

=end html

=cut

# ---------------
1;

