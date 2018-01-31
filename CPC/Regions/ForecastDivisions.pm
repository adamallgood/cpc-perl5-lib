#!/usr/bin/perl

package CPC::Regions::ForecastDivisions;

=pod

=head1 NAME

CPC::Regions::ForecastDivisions - Store and manipulate data for the 102 CPC Forecast Divisions

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::ForecastDivisions;

=head1 DESCRIPTION

CPC::Regions::ForecastDivisions inherits all of the functionality of its parent CPC::Regions class and
applies this functionality specifically to data on the 102 CPC Forecast Divisions.  The regional
IDs are integer values numbered from 1 to 102, corresponding to the names of the divisions as 
they appear in CPC products.

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

my @ID;
for(my $i=1; $i<103; $i++) { push(@ID,$i); }

my @NAME = ("NORTHERN NEW ENGLAND","NORTHEAST NEW ENGLAND","NORTHERN NEW YORK","SOUTHERN NEW ENGLAND","EASTERN GREAT LAKES","OHIO","MID-ATLANTIC COAST",
"NORTHERN APPALACHAIN","CENTRAL APPALACHAIN","COASTAL VIRGINIA","SOUTHERN APPALACHAIN","COASTAL CAROLINAS","INTERIOR CAROLINAS","MICHIGAN UPPER PEN.",
"NORTHERN MINNISOTA","EASTERN NORTH DAKOTA","WESTERN NORTH DAKOTA","EASTERN MONTANA","NORTH-CENTRAL MONTANA","SOUTH CENTRAL MONTANA","WESTERN MONTANA",
"NORTH-CENTRAL MICHIGAN","SOUTHERN MICHIGAN","EAST-CENTRAL ILLINOIS","NORTHERN ILLINOIS","NORTHERN WISCONSIN","SOUTHEASTERN MINNISOTA","EASTERN SOUTH DAKOTA",
"CENTRAL SOUTH DAKOTA","WESTERN SOUTH DAKOTA","NORTHEAST WYOMING","NORTHWEST WYOMING","EASTERN IOWA","NORTHWEST IOWA","CENTRAL NEBRASKA","SOUTHERN NEBRASKA",
"WESTERN NEBRASKA/CHEYENE","EASTERN KENTUCKY","WESTERN KENTUCKY","SOUTHEAST MISSOURI","NORTHEAST MISSOURI","NORTHWEST MISSOURI","EASTERN KANSAS",
"CENTRAL KANSAS","WESTERN KANSAS","NORTHEAST COLORADO","SOUTHEAST COLORADO","WESTERN COLORADO","SOUTHWEST WYOMING","CENTRAL TENNESSEE","WESTERN TENNESSEE",
"OZARK MOUNTAINS","CENTRAL OKLAHOMA","TEXAS WEST OF ABILENE","NORTH HIGH PLAINS TEXAS","NORTHERN GEORGIA","NORTHERN ALABAMA","CENTRAL MISSISSIPPI",
"SOUTHERN ARKANSAS","EAST TEXAS","DALLAS AREA TEXAS","SAN ANTINIO AREA TEXAS","FAR SOUTHERN TEXAS","WEST-CENTRAL TEXAS","WESTERN TEXAS PANHANDLE",
"JACKSONVILLE FLORIDA AREA","CENTRAL FLORIDA","SOUTHERN FLORIDA","FLORIDA PANHANDLE","COASTAL LOUISIANA","COASTAL TEXAS NEAR HOUSTON","NORTHEAST WASHINGTON",
"PENDELTON AREA OREGON","CENTRAL WASHINGTON","SEATTLE AREA WASHINGTON","WASHINGTON COAST","EASTERN IDAHO","IDAHO CENTRAL MOUNTAINS","SOUTHWEST IDAHO",
"EASTERN OREGON","OREGON COASTAL VALLEY","OREGON COAST","NORTHEAST UTAH","SOUTHEAST UTAH","WESTERN UTAH","NORTHEAST NEVADA","NORTHWEST NEVADA",
"SACREMENTO AREA CALIFORNIA","NORTHERN CALIFORNIA COAST","CENTRAL NEVADA","FRESNO AREA CALIFORNIA","CENTRAL CALIFORNIA COAST","SOUTHERN CALIFORNIA COAST",
"SOUTHEAST CALIFORNIA","LAS VEGAS NEVADA AREA","SOUTHWEST ARIZONA","NORTHEAST ARIZONA","SOUTHEAST ARIZONA","NORTHERN NEW MEXICO","EASTERN NEW MEXICO",
"CENTRAL NEW MEXICO","SOUTHERN NEW MEXICO");

=pod

=head1 CLASS METHODS

=cut

=pod

=head2 Constructors

The CPC::Regions::ForecastDivisions class provides two specialized constructors to create objects in
the calling program.

=cut

=pod

=head3 new

 my $data = CPC::Regions::ForecastDivisions->new();

Returns a CPC::Regions::ForecastDivisions object to the calling program where all regional data values
are set to the object's default missing value.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'ForecastDivisions';
	foreach my $id (@ID) { $self->{data}->{$id} = $self->{missing}; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newNames

 my $names = CPC::Regions::ForecastDivisions->newNames();

Returns a CPC::Regions::ForecastDivisions object to the calling program where all regional data values
are set to the name of the forecast division.  Names are provided in all caps, so do ucfirst(lc()) 
on each name to get it looking nice.

=cut

sub newNames {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'ForecastDivisions';
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

