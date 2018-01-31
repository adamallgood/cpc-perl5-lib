#!/usr/bin/perl

package CPC::Regions::ClimateDivisions::DailyData;

=pod

=head1 NAME

CPC::Regions::ClimateDivisions::DailyData - Load daily values from CPC sources into CPC::Regions::ClimateDivisions objects

=head1 SYNOPSIS

 use CPC::Day;
 use CPC::Regions::ClimateDivisions;
 use CPC::Regions::ClimateDivisions::DailyData;
 
 my $cdDailyObj  = CPC::Regions::ClimateDivisions::DailyData->new();
 my $day         = CPC::Day->new() - 1;
 my $missingVal  = -9999;
 my $dailyPrecip = $cdDailyObj->GetPrecipitationFromGridded($day,$missingVal);
 unless($dailyPrecip->IsComplete) { die "Some or all data missing for $day"; }

=head1 DESCRIPTION

=head1 REQUIREMENTS

CPC::Regions::ClimateDivisions::DailyData requires the following CPC Perl5 Library packages:

=over 4

=item * CPC::Day

=item * CPC::Regions::ClimateDivisions

=back

The following external software is required:

=over 4

=item * wgrib2

=back

The following reference files are required (should be located in the same directory as the package):

=over 4

=back

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;

use Carp;
use File::Basename;
use File::Copy qw(copy move);
use Scalar::Util qw(blessed looks_like_number);

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::Regions::ClimateDivisions;

# --- Package directory ---

my $pkgInstallFilename = $INC{"CPC/Regions/ClimateDivisions/DailyData.pm"};
my($pkgName,$pkgPath,$pkgSuffix) = fileparse($pkgInstallFilename,qr/\.[^.]*/);

# --- Load 0.125 degree grid to climate divisions map file ---

my $grid2climdivMapFile = $pkgPath."Conus0.125DegreeGrid-ClimateDivisions.map"
croak "CPC::Regions::ClimateDivisions::DailyData: $grid2climdivMapFile is empty or not found" unless(-s $grid2climdivMapFile);
open(MAP,'<',$grid2climdivMapFile) or die "CPC::Regions::ClimateDivisions::DailyData: Could not open $grid2climdivMapFile for reading - $!";
{ my $mapHeaderLine = <MAP>; }
my @grid2cdMap;

while (<MAP>) {
	my $line = $_;
	chomp $line;
	my($lon,$lat,$stcd) = split(/\|/,$line);
	croak "CPC::Regions::ClimateDivisions::DailyData: $grid2climdivMapFile is corrupted - $line - exception thrown" unless(looks_like_number $stcd);
	push(@grid2cdMap,$stcd);
}

close(MAP);

=pod

=head1 METHODS

=cut

=pod

=head3 new

 my $pkgObject = CPC::Regions::ClimateDivisions::DailyData->new();

Returns a reference blessed into the CPC::Regions::ClimateDivisions::DailyData package, for use as 
an object in the calling program.

The constructor assigns a random set of digits to serve in temporary filenames.  Some methods in 
this package require the creation and deletion of temporary files during runtime, and adding these 
random digits to the temporary filenames prevents problems when multiple instances of this package 
are running at the same time.

=cut

sub new {
	my $class     = shift;
	my $self      = {};
	$self->{RAND} = rand(10);
	$self->{RAND} =~ s/\.//;
	bless($self,$class);
	return $self;
}

=pod

=head3 GetPrecipitationFromGridded

 my $dailyPrecip = $pkgObject->GetPrecipitationFromGridded($day,$missingVal);

Given a valid CPC::Day object set to a date no later than yesterday, returns a 
CPC::Regions::ClimateDivisions object loaded with daily precipitation data based on CPC's daily 
gridded precipitation analyses.

The CPC::Day object is a required argument.  An optional second argument can be passed to set 
the resultant CPC::Regions::ClimateDivisions object's missing value.

Any non-numeric data detected after the computation of the climate divisional values will be 
set to missing.  The method will carp a warning if there are any missing data (including if the 
source file itself is missing), but will not croak, so make sure to run "IsComplete" on the results.

=cut

sub GetPrecipitationFromGridded {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetPrecipitationFromGridded";
	my $unique = $self->{RAND};

	# --- Validate arguments ---

	croak "$class->$method: No argument was provided" unless(@_);
	my $day = shift;
	croak "$class->$method: Argument must be a CPC::Day object" unless($day->isa("CPC::Day"));
	croak "$class->$method: CPC::Day object must be set to no later than yesterday" unless($day < CPC::Day->new());

	my $missing = undef;

	if(@_) {
		$missing = shift;
	}

	# --- Create return object ---

	my $result = CPC::Regions::ClimateDivisions->new();
	if($missing) { $result->SetMissing($missing); }

	# --- Validate input data source ---

	croak "$class->$method: DATA_IN must be set to a directory in your environment" unless(CheckENV("DATA_IN"));
	my $cpcData  = $ENV{"DATA_IN"};
	$cpcData     = RemoveSlash($cpcData);
	my $yyyy     = $day->Year;
	my $yyyymmdd = int($day);
	my $input    = $method.$unique.".gridded";
	my $source   = "$cpcData/cpcsat/cpcUniGaugeRT/PRODUCTS/GRID/$yyyy/gridCONUS/DEG0.125P/PRCP_CU_GAUGE_V1.0CONUS_0.125deg.lnx.$yyyymmdd.RT"

	if(not -s $source and -s "$source.gz") { $source = $source.".gz"; }

	unless(-s $source) {
		carp "$class->$method: $source not found - returning all missing values";
		return $result;
	}

	# --- Load source ---

	

}

=pod

=head3 GetTemperaturesFromGridded

 my ($dailyTMAX,$dailyTMIN) = $pkgObject->GetTemperaturesFromGridded($day,$missingVal);

Given a valid CPC::Day object set to a date no later than two days ago, returns two
CPC::Regions::ClimateDivisions objects loaded with daily maximum and minimum temperature data based 
on CPC's daily gridded temperature analyses.

The CPC::Day object is a required argument.  An optional second argument can be passed to set
the resultant CPC::Regions::ClimateDivisions objects' missing values.

Any non-numeric data detected after the computation of the climate divisional values will be
set to missing.  The method will carp a warning if there are any missing data (including if the
source files themselves are missing), but will not croak, so make sure to run "IsComplete" on the 
results.

=cut

sub GetTemperaturesFromGridded {

}

=pod

=head3 GetTemperaturesFromGriddedNOHADS

 my ($dailyTMAX,$dailyTMIN) = $pkgObject->GetTemperaturesFromGriddedNOHADS($day,$missingVal);

Given a valid CPC::Day object set to a date no later than two days ago, returns two
CPC::Regions::ClimateDivisions objects loaded with daily maximum and minimum temperature data based
on CPC's daily 'NOHADS' gridded temperature analyses.

The CPC::Day object is a required argument.  An optional second argument can be passed to set
the resultant CPC::Regions::ClimateDivisions objects' missing values.

Any non-numeric data detected after the computation of the climate divisional values will be
set to missing.  The method will carp a warning if there are any missing data (including if the
source files themselves are missing), but will not croak, so make sure to run "IsComplete" on the
results.

=cut

sub GetTemperaturesFromGriddedNOHADS {

}

=pod

=head1 SEE ALSO

=head1 AUTHOR

=cut

1;

