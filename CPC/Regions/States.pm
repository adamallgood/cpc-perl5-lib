#!/usr/bin/perl

package CPC::Regions::States;

=pod

=head1 NAME

CPC::Regions::States - Store and manipulate data for the 50 states of the United States of America

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::States;

=head1 DESCRIPTION

CPC::Regions::States inherits all of the functionality of its parent CPC::Regions class and applies this
functionality specifically to data on the 50 U.S. states.  The regional IDs are the two letter
state postal IDs.  For example, Alabama is AL, and Alaska is AK.

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

my @ID = ('AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA',
'ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA',
'RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY');

my @NAME = ('Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut',
'Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky',
'Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri',
'Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina',
'North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina',
'South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia',
'Wisconsin','Wyoming');

=pod

=head1 CLASS METHODS

=cut

=pod

=head2 Constructors

In addition to the standard constructor (new), the CPC::Regions::States class provides two specialized 
constructors to create objects in the calling program with preset data.

=cut

=pod

=head3 new

 my $data = CPC::Regions::States->new();

Returns a CPC::Regions::States object to the calling program where all regional data values
are set to the object's default missing value.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'States';
	foreach my $id (@ID) { $self->{data}->{$id} = $self->{missing}; }
	$self->{idsNumeric} = 0;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newNames

 my $names = CPC::Regions::States->newNames();

Returns a CPC::Regions::States object to the calling program where all regional data values
are set to the name of the state.  Names are provided with the first letters capitalized only.

=cut

sub newNames {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'States';
	for(my $i=0; $i<scalar(@ID); $i++) { $self->{data}->{$ID[$i]} = $NAME[$i]; }
	$self->{idsNumeric} = 0;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newCensusDivisionsIDs

 my $censusIDs = CPC::Regions::States->newCensusDivisionsIDs();

Returns a CPC::Regions::States object to the calling program with state data set to the 
CPC::Regions::CensusDivisions IDs of the Census division containing the states.

=cut

sub newCensusDivisionsIDs {
	my $class           = shift;
	my $self            = $class->SUPER::new();
	$self->{type}       = 'States';
	my @CensusDivisions = ('CT,ME,MA,NH,RI,VT',
	                       'NJ,NY,PA',
	                       'IN,IL,MI,OH,WI',
	                       'IA,KS,MN,MO,NE,ND,SD',
	                       'DE,FL,GA,MD,NC,SC,VA,WV',
	                       'AL,KY,MS,TN',
	                       'AR,LA,OK,TX',
	                       'AZ,CO,ID,NM,MT,VT,UT,NV,WY',
	                       'AK,CA,HI,OR,WA');
	my $divID = 1;

	foreach my $cd (@CensusDivisions) {
		my @states = split(/,/,$cd);
		foreach my $st (@states) { $self->{data}->{$st} = $divID; }
		$divID++;
	}

	$self->{idsNumeric} = 0;
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

