#!/usr/bin/perl

package CPC::Day;

=pod

=head1 NAME

CPC::Day - Perl class for calendar day processing

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Day;

=head1 DESCRIPTION

The CPC::Day class constructs a CPC::Day object via the new() method.  A CPC::Day object can return the following
information about a calendar day: the year, month number, month name, day of the month, day of the
year, day of the week, day of week number, and the Julian Day Number.

Users can manipulate calendar data using operations with CPC::Day objects.  Integers can be added to or
subtracted from CPC::Day objects to obtain new CPC::Day objects with dates set before or after the original
object's date.  Two CPC::Day objects can be compared to each other, which allows for easy looping of
date ranges.  Dates can also be expressed as strings or integers for ease of display.

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);
use overload
	'+'        => \&Plus,
	'-'        => \&Minus,
	'<=>'      => \&Compare,
	'cmp'      => \&Compare,
	'""'       => \&Stringify,
	'int'      => \&Int,
	'nomethod' => \&CatchAll;

# --- Package data ---

my @dayNames     = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
my @monthNames   = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
my @monthLengths = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

=pod

=head1 METHODS

=cut

=pod

=head2 Constructors

=cut

=pod

=head3 new

 my $today     = CPC::Day->new();
 my $birthdate = CPC::Day->new(19820206);
 $birthdate    = CPC::Day->new(1982,2,6);

Returns a new CPC::Day object to the calling program.  With no arguments provided, the CPC::Day object is set
to the current date as defined by Perl's localtime() function.  Otherwise, the date is set by 
arguments to the constructor.  A single argument is expected to be in YYYYMMDD format, and the
year, month number, and day of the month can be passed as a list.  The new() constructor croaks
with bad arguments, so if you are using it to test the arguments for validity, wrap it in an
eval block and check $@ for errors.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	# --- Set Year, Mnum, and Mday ---

	my($year,$mnum,$mday);

	if(not @_) {
		my @currentTime = localtime(time);
		$year           = $currentTime[5];  $year += 1900;
		$mnum           = $currentTime[4];  $mnum++;
		$mday           = $currentTime[3];
	}
	elsif(@_ == 1) {
		my $ymd = shift;
		$year   = substr($ymd,0,-4);
		$mnum   = substr($ymd,-4,2);
		$mday   = substr($ymd,-2);
	}
	elsif(@_ == 3) {
		$year = shift;
		$mnum = shift;
		$mday = shift;
	}
	else { confess "$class->new: Invalid number of arguments - exception thrown"; }

	# --- Validate calendar data ---

	# Validate Year!
	confess "$class->new: $year is an invalid year - exception thrown" if(not $year =~ /^[+-]?\d+$/ or $year == 0);

	# Validate Mnum!
	confess "$class->new: $mnum is an invalid month number - exception thrown" if(not $mnum =~ /^[+-]?\d+$/ or $mnum < 1 or $mnum > 12);

	# Validate Mday!
	my $mLength = $monthLengths[$mnum-1];
	if($mnum == 2 and ($year % 4) == 0) { if(($year % 100) != 0 or ($year % 400) == 0) { $mLength++; } } # Leap year!
	confess "$class->new: $mday is an invalid day of the month - exception thrown" if(not $mday =~ /^[+-]?\d+$/ or $mday < 1 or $mday > $mLength);

	# --- Set object data ---

	$self->{YEAR} = $year;
	$self->{MNUM} = $mnum;
	$self->{MDAY} = $mday;
	$self->{JDAY} = &_Gregorian2Julian($year,$mnum,$mday);

	bless($self,$class);
	return $self;
}

=pod

=head2 Object Data

Use these methods to access calendar data from the CPC::Day object!

=cut

=pod

=head3 Year

 my $today = CPC::Day->new();
 my $year  = $today->Year;

Returns the calendar year of the CPC::Day object as an integer.

=cut

sub Year {
	my $self = shift;
	return $self->{YEAR};
}

=pod

=head3 Mnum

 my $today = CPC::Day->new();
 my $mnum  = $today->Mnum;

Returns the calendar month number as an integer.

=cut

sub Mnum {
	my $self = shift;
	return $self->{MNUM};
}

=pod

=head3 Mday

 my $today = CPC::Day->new();
 my $mday  = $today->Mday;

Returns the calendar day of the month as an integer.

=cut

sub Mday {
	my $self = shift;
	return $self->{MDAY};
}

=pod

=head3 Jday

 my $today = CPC::Day->new();
 my $jday  = $today->Jday;

Returns the Julian day number corresponding to the calendar date as an integer.

=cut

sub Jday {
	my $self = shift;
	return $self->{JDAY};
}

=pod

=head3 Mname

 my $today = CPC::Day->new();
 my $Month = $today->Mname;

Returns the full name of the calendar month (e.g., January).

=cut

sub Mname {
	my $self = shift;
	return $monthNames[$self->{MNUM} - 1];
}

=pod

=head3 Wday

 my $today = CPC::Day->new();
 my $wday  = $today->Wday;

Returns the calendar day of the week in integer format (e.g., Sunday => 1, Saturday => 7).

=cut

sub Wday {
	my $self = shift;
	return (($self->{JDAY} + 1) % 7) + 1;
}

=pod

=head3 WdayName

 my $today   = CPC::Day->new();
 my $Weekday = $today->WdayName;

Returns the calendar day of the week (e.g., Sunday).

=cut

sub WdayName {
	my $self = shift;
	return $dayNames[($self->{JDAY} + 1) % 7];
}

=pod

=head3 Yday

 my $today = CPC::Day->new();
 my $yday  = $today->Yday;

Returns the calendar day of the year in integer format (e.g., 1 February => 32).

=cut

sub Yday {
	my $self = shift;
	return $self->{JDAY} - &_Gregorian2Julian($self->{YEAR}, 1, 1) + 1;
}

=pod

=head2 Operations

The CPC::Day class overloads the following operators: +, -, <, <=, >, >=, ==, !=, 
lt, le, gt, ge, eq, ne, "", and int().  This allows the calling programs to manipulate calendar
data in a powerful manner via CPC::Day objects.

=cut

=pod

=head3 Addition and Subtraction (+,-)

 my $today      = CPC::Day->new();
 my $yesterday  = $today - 1;
 my $tomorrow   = $today + 1;
 my $yearLength = CPC::Day->new(20121231) - CPC::Day->new(20120101) + 1; # Returns 366
 my $daysBack   = CPC::Day->new(20120101) - CPC::Day->new(20120102);     # Returns -1

The CPC::Day class overloads Perl's addition (+) and subtraction (-) operators to work with CPC::Day objects.
Adding an integer value "N" to a CPC::Day object returns a new CPC::Day object "N" days subsequent from the
date of the initial CPC::Day object.  Subtracting "N" from a CPC::Day object returns a new CPC::Day object "N"
days prior to the initial CPC::Day object.  Additionally, subtracting two CPC::Day objects returns the
difference of their dates.  The incrementing and assignment operators ++, --, +=, and -= also work
under the same principles, though the assignment operators do not make much sense with CPC::Day objects.

=cut

sub Plus {
	my($self,$thing,$switched) = @_;
	confess "Cannot add a CPC::Day object and $thing - exception thrown" if(not $thing =~ /^[+-]?\d+$/);
	return CPC::Day->new(&_Julian2Gregorian($self->{JDAY} + $thing));
}

sub Minus {
	my($self,$thing,$switched) = @_;

	# --- Subtract two Day objects ---

	if(blessed($thing)) { if(blessed($thing) eq blessed($self)) {
		if($switched) { return $thing->{JDAY} - $self->{JDAY}; }
		else          { return $self->{JDAY} - $thing->{JDAY}; }
	} }

	# --- Subtract an integer from a Day object ---

	elsif($thing =~ /^[+-]?\d+$/) {
		if($switched) { confess "Cannot subtract a CPC::Day object from an integer - exception thrown"; }
		else          { return CPC::Day->new(&_Julian2Gregorian($self->{JDAY} - $thing)); }
	}

	# --- Invalid subtraction ---

	else {
		confess "Invalid subtraction operation involving a CPC::Day object - exception thrown";
	}

}

=pod

=head3 CPC::Day Object Comparison (<,<=,>,>=,==,!=, or lt,le,gt,ge,eq,ne)

 my $weekEnd   = CPC::Day->new();
 my $weekStart = $weekEnd - 6;
 for(my $day=$dayStart; $day<=$dayEnd; $day++) { }
 
 print "$day2 comes after $day1" if($day2 > $day1);
 print "$day2 and $day1 are different days" if($day2 != $day1);

The CPC::Day class compares two CPC::Day objects by numerically comparing their Julian Day Number values.
Therefore, a later day is numerically "greater than" an earlier day.  String comparison operators
are equivalent to numeric comparison operators when using CPC::Day objects.

=cut

sub Compare {
	my($self,$thing,$switched) = @_;
	if(not blessed($thing) eq blessed($self)) { confess "Cannot compare a CPC::Day object to a non-CPC::Day object - exception thrown"; }
	if($switched) { return $thing->{JDAY} <=> $self->{JDAY}; }
	else          { return $self->{JDAY} <=> $thing->{JDAY}; }
}

=pod

=head3 Stringify and Int ('""',int())

 my $today    = CPC::Day->new();
 my $yyyymmdd = int($today);
 print "Today is $today\n";

If a CPC::Day object is used in a string, the calendar day is returned in DDMonYYYY format
(e.g., 01Jan2012).  Using a CPC::Day object in the int() function returns the calendar day as a
YYYYMMDD integer (e.g., 20120101).

=cut

sub Stringify {
	my $self = shift;
	my $Mon  = substr($self->Mname,0,3);
	my $year = $self->Year;
	return sprintf("%02d",$self->Mday).$Mon.$year;
}

sub Int {
	my $self = shift;
	return 10000*$self->Year + 100*$self->Mnum + $self->Mday;
}

sub CatchAll {
	my $operator = pop;
	confess "Operator $operator cannot be used with a Day object - exception thrown";
}

# --- Utilities ---

# While these methods are not encapsulated (Perl doesn't really do encapsulation well),
# they were not intended for use outside of this package - so use them at your own peril.

sub _Gregorian2Julian {
	use integer;
	my $year = shift;
	my $mnum = shift;
	my $mday = shift;
	return 367 * $year - 7 * ($year + ($mnum + 9)  / 12) / 4
	       - 3 * (($year + ($mnum - 9) / 7) / 100 + 1) / 4
	       + 275 * $mnum / 9 + $mday + 1721029;
}

sub _Julian2Gregorian {
	use integer;
	my $jd = shift;

	my $l = $jd + 68569;
	my $n = (4*$l) / 146097;
	$l    = $l - (146097*$n + 3) / 4;
	my $i = (4000 * ($l + 1)) / 1461001;
	$l    = $l - (1461*$i) / 4 + 31;
	my $j = (80*$l) / 2447;

	my $mday = $l - (2447*$j) / 80;
	$l       = $j / 11;
	my $mnum = $j + 2 - 12*$l;
	my $year = 100 * ($n - 49) + $i + $l;

	if($year <= 0) { $year--; }
	return ($year, $mnum, $mday);
}

# --- Final POD Documentation ---

=pod

=head1 SEE ALSO

=over 4

=item * Operator Overloading in Perl L<http://perldoc.perl.org/overload>

=item * Perl Object Oriented Programming Tutorial L<http://perldoc.perl.org/perlootut.html>

=item * Perl Objects L<http://perldoc.perl.org/perlobj.html>

=item * Perl localtime function L<http://perldoc.perl.org/functions/localtime.html>

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

