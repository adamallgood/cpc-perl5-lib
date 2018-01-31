#!/usr/bin/perl

package CPC::Regions::ClimateDivisions;

=pod

=head1 NAME

CPC::Regions::ClimateDivisions - Store and manipulate data for the 344 U.S. Climate Divisions

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::ClimateDivisions;

=head1 DESCRIPTION

CPC::Regions::ClimateDivisions inherits all of the functionality of its parent CPC::Regions class and
applies this functionality specifically to data on the 344 U.S. Climate Divisions.  The regional
IDs are integer values defined as STCD, where ST is a number representing the U.S. state in
which the division resides excluding Alaska and Hawaii (e.g., 1 for Alabama, 48 for Wyoming),
and CD is the division number in the order provided by the National Climatic Data Center in
Asheville, NC.  For example, Alabama's "Northern Valley" climate division has an ID of 101, while
Florida's "Keys" division has an ID of 807.  Maryland's "Upper Southern" division, which also
contains most of the District of Columbia, has an ID of 1804.

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

my @ID = (101,102,103,104,105,106,107,108,201,202,203,204,205,206,207,301,302,303,304,305,306,307,308,309,401,402,403,404,405,406,407,
501,502,503,504,505,601,602,603,701,702,801,802,803,804,805,806,807,901,902,903,904,905,906,907,908,909,1001,1002,1003,1004,1005,1006,
1007,1008,1009,1010,1101,1102,1103,1104,1105,1106,1107,1108,1109,1201,1202,1203,1204,1205,1206,1207,1208,1209,1301,1302,1303,1304,1305,
1306,1307,1308,1309,1401,1402,1403,1404,1405,1406,1407,1408,1409,1501,1502,1503,1504,1601,1602,1603,1604,1605,1606,1607,1608,1609,1701,
1702,1703,1801,1802,1803,1804,1805,1806,1807,1808,1901,1902,1903,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2101,2102,2103,2104,
2105,2106,2107,2108,2109,2201,2202,2203,2204,2205,2206,2207,2208,2209,2210,2301,2302,2303,2304,2305,2306,2401,2402,2403,2404,2405,2406,
2407,2501,2502,2503,2505,2506,2507,2508,2509,2601,2602,2603,2604,2701,2702,2801,2802,2803,2901,2902,2903,2904,2905,2906,2907,2908,3001,
3002,3003,3004,3005,3006,3007,3008,3009,3010,3101,3102,3103,3104,3105,3106,3107,3108,3201,3202,3203,3204,3205,3206,3207,3208,3209,3301,
3302,3303,3304,3305,3306,3307,3308,3309,3310,3401,3402,3403,3404,3405,3406,3407,3408,3409,3501,3502,3503,3504,3505,3506,3507,3508,3509,
3601,3602,3603,3604,3605,3606,3607,3608,3609,3610,3701,3801,3802,3803,3804,3805,3806,3807,3901,3902,3903,3904,3905,3906,3907,3908,3909,
4001,4002,4003,4004,4101,4102,4103,4104,4105,4106,4107,4108,4109,4110,4201,4202,4203,4204,4205,4206,4207,4301,4302,4303,4401,4402,4403,
4404,4405,4406,4501,4502,4503,4504,4505,4506,4507,4508,4509,4510,4601,4602,4603,4604,4605,4606,4701,4702,4703,4704,4705,4706,4707,4708,
4709,4801,4802,4803,4804,4805,4806,4807,4808,4809,4810);

my @NAME = ('NORTHERN VALLEY','APPALACHIAN MOUNTAIN','UPPER PLAINS','EASTERN VALLEY','PIEDMONT PLATEAU','PRAIRIE','COASTAL PLAIN','GULF',
'NORTHWEST','NORTHEAST','NORTH CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST','NORTHWEST','NORTH CENTRAL','NORTHEAST',
'WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST','NORTH COAST DRAINAGE','SACRAMENTO DRNG.',
'NORTHEAST INTER. BASINS','CENTRAL COAST DRNG.','SAN JOAQUIN DRNG.','SOUTH COAST DRNG.','SOUTHEAST DESERT BASIN',
'ARKANSAS DRAINAGE BASIN','COLORADO DRAINAGE BASIN','KANSAS DRAINAGE BASIN','PLATTE DRAINAGE BASIN','RIO GRANDE DRAINAGE BASIN',
'NORTHWEST','CENTRAL','COASTAL','NORTHERN','SOUTHERN','NORTHWEST','NORTH','NORTH CENTRAL','SOUTH CENTRAL','EVERGLADES','LOWER EAST COAST',
'KEYS','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST','PANHANDLE',
'NORTH CENTRAL PRAIRIES','NORTH CENTRAL CANYONS','CENTRAL MOUNTAINS','SOUTHWESTERN VALLEYS','SOUTHWESTERN HIGHLANDS','CENTRAL PLAINS',
'NORTHEASTERN VALLEYS','UPPER SNAKE RIVER PLAINS','EASTERN HIGHLANDS','NORTHWEST','NORTHEAST','WEST','CENTRAL','EAST','WEST SOUTHWEST',
'EAST SOUTHEAST','SOUTHWEST','SOUTHEAST','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST',
'SOUTH CENTRAL','SOUTHEAST','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL',
'SOUTHEAST','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST',
'WESTERN','CENTRAL','BLUE GRASS','EASTERN','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST',
'SOUTH CENTRAL','SOUTHEAST','NORTHERN','SOUTHERN INTERIOR','COASTAL','SOUTHEASTERN SHORE','CENTRAL EASTERN SHORE','LOWER SOUTHERN',
'UPPER SOUTHERN','NORTHEASTERN SHORE','NORTHERN CENTRAL','APPALACHIAN MOUNTAIN','ALLEGHENY PLATEAU','WESTERN','CENTRAL','COASTAL',
'WEST UPPER','EAST UPPER','NORTHWEST','NORTHEAST LOWER','WEST CENTRAL LOWER','CENTRAL LOWER','EAST CENTRAL LOWER','SOUTHWEST LOWER',
'SOUTH CENTRAL LOWER','SOUTHEAST LOWER','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST',
'SOUTH CENTRAL','SOUTHEAST','UPPER DELTA','NORTH CENTRAL','NORTHEAST','LOWER DELTA','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL',
'SOUTHEAST','COASTAL','NORTHWEST PRAIRIE','NORTHEAST PRAIRIE','WEST CENTRAL PLAINS','WEST OZARKS','EAST OZARKS','BOOTHEEL','WESTERN',
'SOUTHWESTERN','NORTH CENTRAL','CENTRAL','SOUTH CENTRAL','NORTHEASTERN','SOUTHEASTERN','PANHANDLE','NORTH CENTRAL','NORTHEAST','CENTRAL',
'EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST','NORTHWESTERN','NORTHEASTERN','SOUTH CENTRAL','EXTREME SOUTHERN','NORTHERN',
'SOUTHERN','NORTHERN','SOUTHERN','COASTAL','NORTHWESTERN PLATEAU','NORTHERN MOUNTAINS','NORTHEASTERN PLAINS','SOUTHWESTERN MOUNTAINS',
'CENTRAL VALLEY','CENTRAL HIGHLANDS','SOUTHEASTERN PLAINS','SOUTHERN DESERT','WESTERN PLATEAU','EASTERN PLATEAU','NORTHERN PLATEAU',
'COASTAL','HUDSON VALLEY','MOHAWK VALLEY','CHAMPLAIN VALLEY','ST. LAWRENCE VALLEY','GREAT LAKES','CENTRAL LAKES','SOUTHERN MOUNTAINS',
'NORTHERN MOUNTAINS','NORTHERN PIEDMONT','CENTRAL PIEDMONT','SOUTHERN PIEDMONT','SOUTHERN COASTAL PLAIN','CENTRAL COASTAL PLAIN',
'NORTHERN COASTAL PLAIN','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL',
'SOUTHEAST','NORTHWEST','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','NORTHEAST HILLS','SOUTHWEST','SOUTH CENTRAL',
'SOUTHEAST','PANHANDLE','NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST',
'COASTAL AREA','WILLAMETTE VALLEY','SOUTHWESTERN VALLEYS','NORTHERN CASCADES','HIGH PLATEAU','NORTH CENTRAL','SOUTH CENTRAL','NORTHEAST'
,'SOUTHEAST','POCONO MOUNTAINS','EAST CENTRAL MOUNTAINS','SOUTHEASTERN PIEDMONT','LOWER SUSQUEHANNA','MIDDLE SUSQUEHANNA',
'UPPER SUSQUEHANNA','CENTRAL MOUNTAINS','SOUTH CENTRAL MOUNTAINS','SOUTHWEST PLATEAU','NORTHWEST PLATEAU','ALL','MOUNTAIN','NORTHWEST',
'NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','SOUTHERN','NORTHWEST','NORTH CENTRAL','NORTHEAST','BLACK HILLS','SOUTHWEST',
'CENTRAL','EAST CENTRAL','SOUTH CENTRAL','SOUTHEAST','EASTERN','CUMBERLAND PLATEAU','MIDDLE','WESTERN','HIGH PLAINS','LOW ROLLING PLAINS',
'NORTH CENTRAL','EAST TEXAS','TRANS PECOS','EDWARDS PLATEAU','SOUTH CENTRAL','UPPER COAST','SOUTHERN','LOWER VALLEY','WESTERN','DIXIE',
'NORTH CENTRAL','SOUTH CENTRAL','NORTHERN MOUNTAINS','UINTA BASIN','SOUTHEAST','NORTHEASTERN','WESTERN','SOUTHEASTERN','TIDEWATER',
'EASTERN PIEDMONT','WESTERN PIEDMONT','NORTHERN','CENTRAL MOUNTAIN','SOUTHWESTERN MOUNTAIN','WEST OLYMPIC COAST','NE OLYMPIC SAN JUAN',
'PUGET SOUND LOWLANDS','E OLYMPIC CASCADE FOOTHILLS','CASCADE MOUNTAINS WEST','EAST SLOPE CASCADES','OKANOGAN BIG BEND','CENTRAL BASIN',
'NORTHEASTERN','PALOUSE BLUE MOUNTAINS','NORTHWESTERN','NORTH CENTRAL','SOUTHWESTERN','CENTRAL','SOUTHERN','NORTHEASTERN','NORTHWEST',
'NORTH CENTRAL','NORTHEAST','WEST CENTRAL','CENTRAL','EAST CENTRAL','SOUTHWEST','SOUTH CENTRAL','SOUTHEAST','YELLOWSTONE DRAINAGE',
'SNAKE DRAINAGE','GREEN AND BEAR DRAINAGE','BIG HORN','POWDER & LITTLE MISSOURI & TONGU','BELLE FOURCHE DRAINAGE',
'CHEYENNE & NIOBRARA DRAINAGE','LOWER PLATTE','WIND RIVER','UPPER PLATTE');

=pod

=head1 CLASS METHODS

=cut

=pod

=head2 Constructors

In addition to the standard constructor (new), the CPC::Regions::ClimateDivisions class provides several 
specialized constructors to create objects with preset data in the calling program.

=cut

=pod

=head3 new

 my $data = CPC::Regions::ClimateDivisions->new();

Returns a CPC::Regions::ClimateDivisions object to the calling program where all regional data values
are set to the object's default missing value.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'ClimateDivisions';
	foreach my $id (@ID) { $self->{data}->{$id} = $self->{missing}; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newNames

 my $names = CPC::Regions::ClimateDivisions->newNames();

Returns a CPC::Regions::ClimateDivisions object to the calling program where all regional data values
are set to the name of the climate division.  Names are provided without commas (but does use the
ampersand & character) and in all caps, so do ucfirst(lc()) on each name to get it looking nice.

=cut

sub newNames {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'ClimateDivisions';
	for(my $i=0; $i<scalar(@ID); $i++) { $self->{data}->{$ID[$i]} = $NAME[$i]; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newStatesIDs

 my $stateIDs = CPC::Regions::ClimateDivisions->newStatesIDs();

Returns a CPC::Regions::ClimateDivisions object to the calling program with divisional data values 
set to the Regions::States ID of the state containing the division.

=cut

sub newStatesIDs {
	my $class     = shift;
	my $self      = $class->SUPER::new();
	$self->{type} = 'ClimateDivisions';
	# List the 48 contiguous U.S. states!
	my @stateIDs  = ('AL','AZ','AR','CA','CO','CT','DE','FL','GA',
	                 'ID','IL','IN','IA','KS','KY','LA','ME','MD',
	                 'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
	                 'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
	                 'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY');
	for(my $i=0; $i<scalar(@ID); $i++) { $self->{data}->{$ID[$i]} = $stateIDs[substr($ID[$i],0,-2) - 1]; }
	$self->{idsNumeric} = 1;
	bless($self,$class);
	lock_keys(%{$self});
	return $self;
}

=pod

=head3 newForecastDivisionsIDs

 my $fdIDs = CPC::Regions::ClimateDivisions->newForecastDivisionsIDs();

Returns a CPC::Regions::ClimateDivisions object to the calling program with climate divisional data 
values set to the Regions::ForecastDivisions ID of the forecast division containing the climate 
division.

=cut

sub newForecastDivisionsIDs {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{type} = 'ClimateDivisions';

	my @ForecastDivisions = (50,57,57,57,57,57,69,69,95,97,96,96,96,96,98,52,52,51,52,59,51,59,59,59,89,88,87,92,91,93,94,47,48,46,46,99,4,4,4,7,7,
                                 69,66,67,67,68,68,68,56,56,56,56,56,56,66,66,66,72,73,73,78,79,79,77,78,77,77,25,25,41,24,24,41,24,40,39,24,23,23,24,24,
                                 6,39,39,38,34,33,33,34,33,33,36,33,33,45,44,43,45,44,43,45,44,43,39,39,38,38,59,59,59,71,70,70,71,70,70,1,2,2,7,7,7,7,7,
                                 7,9,9,4,4,4,14,14,22,22,22,22,22,22,23,23,15,15,15,28,27,27,28,27,27,51,51,51,58,58,58,58,58,58,70,42,41,42,52,40,40,21,
                                 21,19,20,20,18,18,37,35,34,36,36,35,36,36,87,86,90,95,1,2,4,7,7,99,99,100,101,101,101,100,102,5,3,3,4,4,3,3,3,5,5,11,11,
                                 13,13,13,12,12,10,17,16,16,17,16,16,17,17,16,23,6,5,6,6,6,6,6,38,6,45,53,43,53,53,52,54,53,52,82,81,81,81,80,74,80,73,79,
                                 8,7,7,7,8,8,8,8,8,5,4,11,13,13,12,13,13,12,30,29,28,30,30,29,28,29,34,11,50,50,51,55,54,61,60,65,64,62,71,63,63,85,85,83,
                                 84,83,83,84,1,3,4,10,10,10,7,9,11,76,76,75,75,75,74,72,74,72,73,9,9,9,9,9,9,26,26,14,26,26,14,25,25,25,32,32,49,32,31,31,
                                 31,37,32,49);

	for(my $i=0; $i<scalar(@ID); $i++) { $self->{data}->{$ID[$i]} = $ForecastDivisions[$i]; }
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

