#!/usr/bin/perl

package CPC::Regions::CensusDivisions;

=pod

=head1 NAME

CPC::Regions::CensusDivisions - Store and manipulate data for the nine U.S. Census Divisions

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::CensusDivisions;

=head1 DESCRIPTION

CPC::Regions::CensusDivisions inherits all of the functionality of its parent CPC::Regions class and applies 
this functionality specifically to data on the nine U.S. Census Divisions.  The regional IDs and
names are as follows:

=over 4

=item * ID => NAME

=item * 1  => NEW ENGLAND

=item * 2  => MIDDLE ATLANTIC

=item * 3  => E N CENTRAL

=item * 4  => W N CENTRAL

=item * 5  => SOUTH ATLANTIC

=item * 6  => E S CENTRAL

=item * 7  => W S CENTRAL

=item * 8  => MOUNTAIN

=item * 9  => PACIFIC

=back

See the POD documentation for the parent CPC::Regions class for more information about what objects
created by this class can do.

=cut

# --- Standard Perl Packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Hash::Util qw(lock_keys);

# --- Inheritance ---

use base qw(CPC::Regions);

# --- Package data ---

my @ID = (1,2,3,4,5,6,7,8,9);

my @NAME = ('NEW ENGLAND','MIDDLE ATLANTIC','E N CENTRAL','W N CENTRAL','SOUTH ATLANTIC',
'E S CENTRAL','W S CENTRAL','MOUNTAIN','PACIFIC');

=pod

=head1 CLASS METHODS

=cut

=pod

=head2 Constructors

The CPC::Regions::CensusDivisions class provides two specialized constructors to create objects in
the calling program.

=cut

=pod

=head3 new

 my $data = CPC::Regions::CensusDivisions->new();

Returns a CPC::Regions::CensusDivisions object to the calling program where all regional data values
are set to the object's default missing value.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'CensusDivisions';
	foreach my $id (@ID) { $self->{data}->{$id} = $self->{missing}; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newNames

 my $names = CPC::Regions::CensusDivisions->newNames();

Returns a CPC::Regions::CensusDivisions object to the calling program where all regional data values
are set to the name of the division.  Names are provided in all caps, so do a ucfirst(lc()) on
each name to make it look nice.

=cut

sub newNames {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'CensusDivisions';
	for(my $i=0; $i<scalar(@ID); $i++) { $self->{data}->{$ID[$i]} = $NAME[$i]; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

# --- Final POD Documentation ---

=pod

=head1 SEE ALSO

=over 4

=begin html

<ul>
<li><a href="../../doc/Regions.html">CPC::Regions (parent class) documentation</a></li>
</ul>

=end html

=back

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

