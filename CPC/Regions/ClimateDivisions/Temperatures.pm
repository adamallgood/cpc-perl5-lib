#!/usr/bin/perl

package CPC::Regions::ClimateDivisions::Temperatures;

=pod

=head1 NAME

CPC::Regions::ClimateDivisions::Temperatures - Get CPC::Regions::ClimateDivisions objects loaded with temperature data

=head1 SYNOPSIS

 use CPC::Day;
 use CPC::Regions::ClimateDivisions;
 use CPC::Regions::ClimateDivisions::Temperatures;
 
 my $cdTemps    = CPC::Regions::ClimateDivisions::Temperatures->new();
 my $latest     = CPC::Day->new() - 2;  # Two days ago!
 my $tavg       = $cdTemps->fetchTAVG($latest);
 my $tavgNOHADS = $cdTemps->fetchTAVG($latest,"NOHADS")'
 my $tmax       = $cdTemps->fetchTMAX($latest);
 my $tmin       = $cdTemps->fetchTMIN($latest);

=head1 DESCRIPTION

This package supplies methods to obtain daily CPC-based temperature data loaded into 
CPC::Regions::ClimateDivisions objects.

=head2 Data Sources

The ClimateDivisions process produces and archives daily temperature data on the 344 U.S. Climate 
Divisions.  The methods in this package locate and fetch these data and return them to users in 
CPC::Regions::ClimateDivisions objects.  This way, if aspects of the ClimateDivisions data change, 
such as moving to a database rather than flat files, the methods in this package can be adjusted 
to work with the new data without requiring any changes to codes using this package.

There are three CPC-based temperature datasets produced by the ClimateDivisions process:

=over 4

=item * "Full" temperatures (available from 2003-present)

=item * "NOHADS" temperatures (available from 2006-present)

=item * "COOP" temperatures (available from 1951-2010)

=back

=head1 SEE ALSO

=over 4

=item * CPC::Day package documentation

=item * CPC::Regions package documentation

=item * CPC::Regions::ClimateDivisions package documentation

=item * CPC::Trim package documentation

=back

=head1 AUTHOR

Adam Allgood

Climate Prediction Center - DOC/NOAA/NWS/NCEP

=cut

# --- Standard and CPAN packages ---

use strict;
use warnings;
use Carp;

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::Regions::ClimateDivisions;
use CPC::Trim qw(ltrim rtrim trim);

=pod

=head1 METHODS

=cut

my $pkg = "CPC::Regions::ClimateDivisions::Temperatures";

=pod

=head3 new

 my $cdTemps = CPC::Regions::ClimateDivisions::Temperatures->new();

Returns a CPC::Regions::ClimateDivisions::Temperatures object (a Perl reference blessed into the 
CPC::Regions::ClimateDivisions::Temperatures package), which can then be used to access the package 
methods below.

=cut

sub new {
	my $class  = shift;
	my $self   = {};
	bless($self,$class);
	return $self;
}

=pod

=head3 fetchTAVG

=head3 fetchTMAX

=head3 fetchTMIN

 my $tavg = $cdTemps->fetchTAVG($day,[TYPE]);
 my $tmax = $cdTemps->fetchTMAX($day,[TYPE]);
 my $tmin = $cdTemps->fetchTMIN($day,[TYPE]);

These methods return a CPC::Regions::ClimateDivisions object set to the daily average, maximum, or 
minimum temperatures.  A CPC::Day argument is required, and an optional second argument can be set 
to either COOP or NOHADS, to return those other datasets.  If no second argument is provided, the 
"full" temperature dataset is used.

If data were not created for the day passed in, a warning will be carped and the method will return 
an object with all missing values.  If data were created but have missing values, a warning will get 
carped.  Any non-numeric data found in the archive will be set as missing data before returning.

=cut

sub fetchTAVG {
	my $self = shift;
	return &_fetch_flatfiles($self,"TAVG",@_);
}

sub fetchTMAX {
	my $self = shift;
	return &_fetch_flatfiles($self,"TMAX",@_);
}

sub fetchTMIN {
	my $self = shift;
	return &_fetch_flatfiles($self,"TMIN",@_);
}

# --- Package utilities ---

# NOTE: These subs are intended for internal package use only!

sub _fetch_flatfiles {

	# --- Sub Caller Arguments ---

	my $self      = shift;
	my $temp      = shift;  # TAVG, TMAX, or TMIN!
	my $pkgCaller = "$pkg->fetch$temp(DAY,[TYPE])";

	# --- User Arguments ---

	croak "$pkgCaller: Argument(s) required - exiting" unless(@_);
	my $day = shift;
	croak "$pkgCaller: Argument is not a CPC::Day object - exiting" unless($day->isa("CPC::Day"));

	my $type = "";

	if(@_) {
		$type = shift;
		croak "$pkgCaller: $type is an invalid TYPE - exiting" unless($type eq "COOP" or $type eq "NOHADS");
		$type = '_'.$type;
	}

	# --- Get flat file archive ---

	croak "$pkgCaller: DATA_OUT environment variable not found - exiting" unless(CheckENV('DATA_OUT'));
	my $dataOut = $ENV{DATA_OUT};
	$dataOut    = RemoveSlash($dataOut);
	my $archive = "$dataOut/observations/land_air/all_ranges/conus/ClimateDivisions344";
	croak "$pkgCaller: Directory $archive (archive) does not exist - exiting" unless(-d $archive);

	# --- Create return object ---

	my $result = CPC::Regions::ClimateDivisions->new();
	$result->SetMissing(-9999);

	# --- Open data file ---

	my $yyyymmdd = int($day);
	my $year     = $day->Year;
	my $mnum     = sprintf("%02d",$day->Mnum);
	my $filename = $temp.$type."-$yyyymmdd.txt";
	my $source   = "$archive/$year/$mnum/$filename";

	unless(-s $source) {
		carp "$pkgCaller: No data were found for $yyyymmdd";
		return $result;
	}

	# Croak instead of carp if we cannot get the file open - this is a bigger problem.
	open(SOURCE,"<",$source) or croak "$pkgCaller: Could not open $source for reading - $! - exiting";

	# --- Load data into CPC::Regions::ClimateDivisions object ---

	my @source = <SOURCE>;
	close(SOURCE);
	shift @source;
	chomp @source;

	foreach my $line (@source) {
		my($cd,$val) = split(/\|/,$line);
		$cd  = trim($cd);
		$val = trim($val);
		$result->SetData($cd,$val);
	}

	$result->Numericize();
	unless($result->IsComplete) { carp "$pkgCaller: Missing data found for $yyyymmdd";     }
	return $result;
}

1;

