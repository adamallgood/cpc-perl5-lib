#!/usr/bin/perl

package CPC::Regions::Stations::QZReader;

=pod

=head1 NAME

CPC::Regions::Stations::QZReader - Create CPC::Regions::Stations objects with CPC's CADB based daily station data

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Day;
 use CPC::Regions::Stations;
 use CPC::Regions::Stations::QZReader;

=head1 DESCRIPTION

The Climate Assessment Database (CADB) provides CPC operations with an archive of daily station based 
meteorological data.  The current operational CADB utilizes a series of flat files called the "QZ" data 
to archive these data.  A line of QZ data includes station identifier information, the meteorological 
fields, and a series of data quality flags.

This package provides a simple means to access QZ data and store them in CPC::Regions::Stations objects. 
Given a CPC::Regions::Stations style reference file, where the IDs are set to the station identifier 
information used by the QZ data, a CPC::Regions::Stations::QZReader object can open existing files in the 
archive and return:

=over 4

=item * Daily accumulated precipitation data (millimeters)

=item * Daily average temperatures (degrees Celsius)

=item * Daily maximum temperatures (degrees Celsius)

=item * Daily minimum temperatures (degrees Celsius)

=back

No checks are made for data completion, which means that the methods below can return missing data to 
the user if the station identifier is not found in the QZ file, or if the data are missing or invalid 
in the archive file.

Bad arguments or a missing QZ archive file for the corresponding date will result in a croak - so a 
good practice when using objects in this package is to wrap the method calls into eval blocks.

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::Regions::Stations;
use CPC::Trim qw(ltrim rtrim trim);

# --- Package data ---

my $cadbDir;

BEGIN {
	croak "DATA_IN is not set to a directory in your environment - exception thrown" unless(CheckENV('DATA_IN'));
	$cadbDir = $ENV{DATA_IN};
	$cadbDir = RemoveSlash($cadbDir);
	$cadbDir = $cadbDir."/operations/cadb/output";
}

=pod

=head1 METHODS

=cut

=pod

=head3 new

 my $reader = CPC::Regions::Stations::QZReader->new("/path/to/ref_file.txt");

Given a user supplied reference file used to construct CPC::Regions::Stations objects, 
returns a CPC::Regions::Stations::QZReader object to the calling program.

=cut

sub new {
	my $class  = shift;
	my $self   = {};
	my $method = 'new';

	# --- Argument ---

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my $ref = shift; chomp $ref;
	my $stations;
	eval   { $stations = CPC::Regions::Stations->new($ref); };
	if($@) { croak "$class->$method: $ref is an unsuitable reference file for CPC::Regions::Stations object creation - $@ - exception thrown"; }
	$self->{STATIONS} = $stations;

	bless($self,$class);
	return $self;
}

=pod

=head3 GetAPCP

 my $yesterday     = CPC::Day->new() - 1;
 my $yesterdayAPCP = $reader->GetAPCP($yesterday);

Given a CPC::Day object, returns a CPC::Regions::Stations object with data values set to the 
accumulated precipitation observed on that day.

=cut

sub GetAPCP {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetAPCP';

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my @qzData = &_check(shift);
	if(@qzData == 1) { croak "$class->$method: ".$qzData[1]; }

	my $result = $self->{STATIONS};
	$result->SetMissing(-999);
	my $offset = 49;
	my $length = 4;

	ID: foreach my $id ($result->GetIDs) {

		LINE: foreach my $line (@qzData) {
			next LINE unless(substr($line,8,20) =~ $id);
			my $value = substr($line,$offset,$length);
			$value    = trim($value);
			next LINE unless(looks_like_number($value) and $value >= 0);
			$result->SetData($id,$value/10);
		} # :LINE

	} # :ID

	return $result;
}

=pod

=head3 GetTAVG

 my $yesterday     = CPC::Day->new() - 1;
 my $yesterdayTAVG = $reader->GetTAVG($yesterday);

Given a CPC::Day object, returns a CPC::Regions::Stations object with data values set to the
average temperatures observed on that day.

=cut

sub GetTAVG {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetTAVG';

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my @qzData = &_check(shift);
	if(@qzData == 1) { croak "$class->$method: ".$qzData[1]; }

	my $result = $self->{STATIONS};
	$result->SetMissing(-999);
	my $tmaxOffset = 37;
	my $tminOffset = 43;
	my $length     = 4;

	ID: foreach my $id ($result->GetIDs) {

		LINE: foreach my $line (@qzData) {
			next LINE unless(substr($line,8,20) =~ $id);
			my $tmaxValue = substr($line,$tmaxOffset,$length);
			my $tminValue = substr($line,$tminOffset,$length);
			$tmaxValue    = trim($tmaxValue);
			$tminValue    = trim($tminValue);
			next LINE unless(looks_like_number($tmaxValue) and looks_like_number($tminValue) and $tmaxValue > -900 and $tminValue > -900);
			$result->SetData($id,($tmaxValue + $tminValue)/20);
		}  # :LINE

	}  # :ID

	return $result;
}

=pod

=head3 GetTMAX

 my $yesterday     = CPC::Day->new() - 1;
 my $yesterdayTMAX = $reader->GetTMAX($yesterday);

Given a CPC::Day object, returns a CPC::Regions::Stations object with data values set to the
maximum temperatures observed on that day.

=cut

sub GetTMAX {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetTMAX';

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my @qzData = &_check(shift);
	if(@qzData == 1) { croak "$class->$method: ".$qzData[1]; }

	my $result = $self->{STATIONS};
	$result->SetMissing(-999);
	my $offset = 37;
	my $length = 4;

	ID: foreach my $id ($result->GetIDs) {

		LINE: foreach my $line (@qzData) {
			next LINE unless(substr($line,8,20) =~ $id);
			my $value = substr($line,$offset,$length);
			$value    = trim($value);
			next LINE unless(looks_like_number($value) and $value > -900);
			$result->SetData($id,$value/10);
		} # :LINE

	} # :ID

	return $result;
}

=pod

=head3 GetTMIN

 my $yesterday     = CPC::Day->new() - 1;
 my $yesterdayTMIN = $reader->GetTMIN($yesterday);

Given a CPC::Day object, returns a CPC::Regions::Stations object with data values set to the
minimum temperatures observed on that day.

=cut

sub GetTMIN {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetTMIN';

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my @qzData = &_check(shift);
	if(@qzData == 1) { croak "$class->$method: ".$qzData[1]; }

	my $result = $self->{STATIONS};
	$result->SetMissing(-999);
	my $offset = 43;
	my $length = 4;

	ID: foreach my $id ($result->GetIDs) {

		LINE: foreach my $line (@qzData) {
			next LINE unless(substr($line,8,20) =~ $id);
			my $value = substr($line,$offset,$length);
			$value    = trim($value);
			next LINE unless(looks_like_number($value) and $value > -900);
			$result->SetData($id,$value/10);
		} # :LINE

	} # :ID

	return $result;
}

# --- For internal use only ---

# 1. Check if value passed is a valid CPC::Day object
# 2. Check if QZFL file exists for that day
# 3. Return list of QZ data!

sub _check {
	my $day      = shift;
	unless(blessed $day and $day->isa('CPC::Day')) { return "$day is not a CPC::Day object"; }
	my $yyyymmdd = int($day);
	my $qzFile   = "$cadbDir/qzfl_$yyyymmdd.dat";
	return "Could not open $qzFile for reading" unless(open(QZ, '<', $qzFile));
	my @qzData   = <QZ>;
	chomp @qzData;
	close(QZ);
	return @qzData;
}

=pod

=head1 SEE ALSO

=begin html

<ul>
<li><a href="../../doc/Stations.html">CPC::Regions::Stations class documentation</a></li>
<li><a href="../../../doc/Regions.html">CPC::Regions (parent class of CPC::Regions::Stations) class documentation</a></li>
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

