#!/usr/bin/perl

package CPC::Month;

=pod

=head1 NAME

CPC::Month - Perl class for calendar month processing

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Month;

=head1 DESCRIPTION

The CPC::Month class constructs a CPC::Month object via the new() method.  A CPC::Month object can return the 
following information about a calendar month: the year, month number, month name, and the length
of the month in days.

Users can manipulate calendar data using operations with CPC::Month objects.  Integers can be added to or
subtracted from CPC::Month objects to obtain new CPC::Month objects with dates set before or after the
original object's date.  Two CPC::Month objects can be compared to each other, which allows for easy looping of month ranges.  Months can also be expressed as strings or integers for ease of display.

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

 my $thisMonth      = CPC::Month->new();
 my $birthmonth = CPC::Month->new(198202);
 $birthmonth    = CPC::Month->new(2,1982);

Returns a new CPC::Month object to the calling program.  With no arguments provided, the CPC::Month object 
is set to the current month as defined by Perl's localtime() function.  Otherwise, the month is 
set by arguments to the constructor.  A single argument is expected to be in YYYYMM format, and 
the month number and year of the month can be passed as a list.  The new() constructor croaks
with bad arguments, so if you are using it to test the arguments for validity, wrap it in an
eval block and check $@ for errors.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	# --- Set Year and Mnum ---

	my($year,$mnum);

	if(not @_) {
		my @currentTime = localtime(time);
		$year           = $currentTime[5];  $year += 1900;
		$mnum           = $currentTime[4];  $mnum++;
	}
	elsif(@_ == 1) {
		my $ym  = shift;
		$year   = substr($ym,0,-2);
		$mnum   = substr($ym,-2);
	}
	elsif(@_ == 2) {
		$mnum = shift;
		$year = shift;
	}
	else { croak "$class->new: Invalid number of arguments - exception thrown"; }

	# --- Validate calendar data ---

	# Validate Year!
	croak "$class->new: $year is an invalid year - exception thrown" if(not $year =~ /^[+-]?\d+$/ or $year == 0);

	# Validate Mnum!
	croak "$class->new: $mnum is an invalid month number - exception thrown" if(not $mnum =~ /^[+-]?\d+$/ or $mnum < 1 or $mnum > 12);

	# --- Set object data ---

	$self->{YEAR} = $year;
	$self->{MNUM} = $mnum;

	bless($self,$class);
	return $self;
}

=pod

=head2 Object Data

Use these methods to access calendar data from the CPC::Month object!

=cut

=pod

=head3 Year

 my $thisMonth = CPC::Month->new();
 my $year      = $thisMonth->Year;

Returns the calendar year of the CPC::Month object as an integer.

=cut

sub Year {
	my $self = shift;
	return $self->{YEAR};
}

=pod

=head3 Number

 my $thisMonth = CPC::Month->new();
 my $mnum      = $thisMonth->Number;

Returns the calendar month number as an integer.  Mnum does the same thing as Number.

=cut

sub Number {
	my $self = shift;
	return $self->{MNUM};
}

sub Mnum {
	my $self = shift;
	return $self->{MNUM};
}

=pod

=head3 Name

 my $thisMonth = CPC::Month->new();
 my $Month     = $thisMonth->Name;

Returns the full name of the calendar month (e.g., January).  Mname does the same thing as Name.

=cut

sub Name {
	my $self = shift;
	return $monthNames[$self->{MNUM} - 1];
}

sub Mname {
	my $self = shift;
	return $monthNames[$self->{MNUM} - 1];
}

=pod

=head3 Length

 my $thisMonth = CPC::Month->new();
 my $length    = $thisMonth->Length;

Returns the number of days in the calendar month.

=cut

sub Length {
	my $self   = shift;
	my $length = $monthLengths[$self->{MNUM} - 1];
	if($self->{MNUM} == 2 and ($self->{YEAR} % 4) == 0) { if(($self->{YEAR} % 100) != 0 or ($self->{YEAR} % 400) == 0) { $length++; } }
	return $length;
}

=pod

=head2 Operations

The CPC::Month class overloads the following operators: +, -, <, <=, >, >=, ==, !=, 
lt, le, gt, ge, eq, ne, "", and int().  This allows the calling programs to manipulate calendar
data in a powerful manner via CPC::Month objects.

=cut

=pod

=head3 Addition and Subtraction (+,-)

 my $thisMonth  = CPC::Month->new();
 my $lastMonth  = $thisMonth - 1;
 my $nextMonth  = $thisMonth + 1;
 my $yearLength = CPC::Month->new(201212) - CPC::Month->new(201201) + 1; # Returns 12
 my $monthsBack = CPC::Month->new(201201) - CPC::Month->new(201112);     # Returns -1

The CPC::Month class overloads Perl's addition (+) and subtraction (-) operators to work with CPC::Month 
objects.  Adding an integer value "N" to a CPC::Month object returns a new CPC::Month object "N" months 
subsequent from the initial month.  Subtracting "N" from a CPC::Month object returns a new CPC::Month object 
"N" months prior to the initial month.  Additionally, subtracting two CPC::Month objects returns the
difference in months.  The incrementing and assignment operators ++, --, +=, and -= also work
under the same principles, though the assignment operators do not make much sense with CPC::Month 
objects.

=cut

sub Plus {
	my($self,$thing,$switched) = @_;
	confess "Cannot add a CPC::Month object and $thing - exception thrown" if(not $thing =~ /^[+-]?\d+$/);
	if($thing < 0) { return $self - abs($thing); }
	if($self->{MNUM} + $thing <= 12) { return CPC::Month->new($self->{MNUM}+$thing,$self->{YEAR}); }
	my $mnum = ($self->{MNUM} + $thing) % 12;
	my $year = $self->{YEAR} + int(($self->{MNUM} + $thing) / 12);
	return CPC::Month->new($mnum,$year);
}

sub Minus {
	my($self,$thing,$switched) = @_;

	# --- Subtract two CPC::Month objects ---

	if(blessed($thing)) { if(blessed($thing) eq blessed($self)) {
		if($switched) { return 12 * ($self->{YEAR} - $thing->{YEAR}) + $self->{MNUM} - $thing->{MNUM}; }
		else          { return 12 * ($thing->{YEAR} - $self->{YEAR}) + $thing->{MNUM} - $self->{MNUM}; }
	} }

	# --- Subtract an integer from a CPC::Month object ---

	elsif($thing =~ /^[+-]?\d+$/) {
		if($switched) { confess "Cannot subtract a CPC::Month object from an integer - exception thrown"; }
		else          {
			if($thing < 0) { return $self + abs($thing); }
			if($self->{MNUM} - $thing >= 1) { return CPC::Month->new($self->{MNUM}-$thing,$self->{YEAR}); }
			my $mnum = $self->{MNUM} - $thing + 12*int(1 + abs($self->{MNUM} - $thing) / 12);
			my $year = $self->{YEAR} - int(1 + abs($self->{MNUM} - $thing) / 12);
			return CPC::Month->new($mnum,$year);
		}
	}

	# --- Invalid subtraction ---

	else {
		confess "Invalid subtraction operation involving a CPC::Month object - exception thrown";
	}

}

=pod

=head3 CPC::Month Object Comparison (<,<=,>,>=,==,!=, or lt,le,gt,ge,eq,ne)

 my $monthEnd   = CPC::Month->new();
 my $monthStart = $monthEnd - 6;
 for(my $month=$monthStart; $month<=$monthEnd; $month++) { }
 
 print "$month2 comes after $month1" if($month2 > $month1);
 print "$month2 and $month1 are different months" if($month2 != $month1);

The CPC::Month class compares two CPC::Month objects by numerically comparing their YYYYMM values.
Therefore, a later month is numerically "greater than" an earlier month.  String comparison operators
are equivalent to numeric comparison operators when using CPC::Month objects.

=cut

sub Compare {
	my($self,$thing,$switched) = @_;
	if(not blessed($thing) eq blessed($self)) { confess "Cannot compare a CPC::Month object to a non-CPC::Month object - exception thrown"; }
	if($switched) { return int($thing) <=> int($self); }
	else          { return int($self) <=> int($thing); }
}

=pod

=head3 Stringify and Int ('""',int())

 my $thisMonth = CPC::Month->new();
 my $yyyymm    = int($thisMonth);
 print "This month is $thisMonth\n";

If a CPC::Month object is invoked as a string, the calendar day is returned in MonYYYY format
(e.g., Jan2012).  Using a CPC::Month object in the int() function returns the calendar month as a
YYYYMM integer (e.g., 201201).

=cut

sub Stringify {
	my $self = shift;
	my $Mon  = substr($self->Name,0,3);
	my $year = $self->Year;
	return $Mon.$year;
}

sub Int {
	my $self = shift;
	return 100*$self->Year + $self->Mnum;
}

sub CatchAll {
	my $operator = pop;
	confess "Operator $operator cannot be used with a CPC::Month object - exception thrown";
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

