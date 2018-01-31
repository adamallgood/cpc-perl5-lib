#!/usr/bin/perl

package CPC::Season;

=pod

=head1 NAME

CPC::Season - Perl class for calendar season (3-month) processing

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use Day;       # Some CPC::Season methods return Day objects!
 use Month;     # Some CPC::Season methods return Month objects!
 use CPC::Season;

=head1 DESCRIPTION

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Switch;
use overload
	'+'        => \&Plus,
	'-'        => \&Minus,
	'<=>'      => \&Compare,
	'cmp'      => \&Compare,
	'""'       => \&Stringify,
	'int'      => \&Int,
	'nomethod' => \&CatchAll;

# --- Package data ---

my @seasonNames = ("DJF","JFM","FMA","MAM","AMJ","MJJ","JJA","JAS","ASO","SON","OND","NDJ");

=pod

=head1 METHODS

=cut

=pod

=head2 Constructors

=cut

=pod

=head3 new

 my $thisSeason = CPC::Season->new();
 my $winter2012 = CPC::Season->new(Month->new(201201));
 my $JJA2012    = CPC::Season->new('FIRST',Month->new(201206));

Returns a new CPC::Season object to the calling program.  With no arguments provided, the CPC::Season 
object is set to the current season where the current month as defined by Perl's localtime() 
function is the middle month of the season.  A single Month object argument is taken to be 
the middle month of the season to be returned.  Otherwise, users can pass a string containing 
'FIRST', 'MIDDLE', or 'LAST' followed by a Month object to establish a season where the Month 
object argument is the first, middle, or last month of the season, respectively.  The new() 
constructor croaks with bad arguments, so if you are using it to test the arguments for 
validity, wrap it in an eval block and check $@ for errors.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	# --- Get the three months of the season ---

	my($first,$middle,$last);

	if(not @_) {
		my @currentTime = localtime(time);
		$year           = $currentTime[5]; $year += 1900;
		$mnum           = $currentTime[4]; $mnum++;
		$center         = Month->new($mnum,$year);
		$first          = $center - 1;
		$last           = $center + 1;
	}
	elsif(@_ == 1) {
		$center         = shift;
		croak "$class->new: Invalid argument - exception thrown" if(not blessed($center) eq 'Month');
		$first          = $center - 1;
		$last           = $center + 1;
	}
	elsif(@_ == 2) {
		my $flag        = shift;
		$flag           = uc($flag);
		my $month       = shift;
		croak "$class->new: Invalid second argument - exception thrown" if(not blessed($mont) eq 'Month');

		switch($flag) {
			case 'FIRST'  { $first = $month; $middle = $month + 1; $last = $month + 2; }
			case 'MIDDLE' { $first = $month - 1; $middle = $month; $last = $month + 1; }
			case 'LAST'   { $first = $month - 2; $middle = $month - 1; $last = $month; }
			else          { croak "$class->new: Invalid first argument - exception thrown"; }
		}

	}
	else { croak "$class->new: Invalid number of arguments - exception thrown"; }

	# --- Set object data ---

	$self->{FIRST}  = $first;
	$self->{MIDDLE} = $middle;
	$self->{LAST}   = $last;
	$self->{NAME}   = $seasonNames[$middle->Number - 1];

	bless($self,$class);
	return $self;
}

=pod

=head2 Object Data

Use these methods to access calendar data from the CPC::Season object!

=cut

=pod

=head3 Name

 my $thisSeason = CPC::Season->new();
 my $seasonName = $thisSeason->Name;

Returns the CPC::Season object's name, which is a three letter acronym of the season's month names.

=cut

sub Name {
	my $self = shift;
	return $self->{Name};
}

=pod

=head3 Length

 my $thisSeason = CPC::Season->new();
 my $ndays      = $thisSeason->Length;

Returns the length of the season in number of days.

=cut

sub Length {
	my $self = shift;
	return $self->{FIRST}->Length + $self->{MIDDLE}->Length + $self->{LAST}->Length;
}

=pod

=head3 FirstMonth

 my $thisSeason = CPC::Season->new();
 my $firstMonth = $thisSeason->FirstMonth;

Returns the first month of the season as a Month object.

=cut

sub FirstMonth {
	my $self = shift;
	return $self->{FIRST};
}

=pod

=head3 FirstDay

 my $thisSeason  = CPC::Season->new();
 my $seasonStart = $thisSeason->FirstDay;

Returns the first calendar day of the 3-month period as a Day object.

=cut

sub FirstDay {
	my $self = shift;
	return Day->new($self->{FIRST}->Year,$self->{FIRST}->Number,1);
}

=pod

=head3 MiddleMonth

 my $thisSeason  = CPC::Season->new();
 my $middleMonth = $thisSeason->MiddleMonth;

Returns the middle month of the season as a Month object.

=cut

sub MiddleMonth {
	my $self = shift;
	return $self->{MIDDLE};
}

=pod

=head3 LastMonth

 my $thisSeason = CPC::Season->new();
 my $lastMonth  = $thisSeason->LastMonth;

Returns the last month of the season as a Month object.

=cut

sub LastMonth {
	my $self = shift;
	return $self->{LAST};
}

=head3 LastDay

 my $thisSeason = CPC::Season->new();
 my $seasonEnd  = $thisSeason->LastDay;

Returns the last calendar day of the 3-month period as a Day object.

=cut

sub LastDay {
        my $self = shift;
        return Day->new($self->{LAST}->Year,$self->{LAST}->Number,$self->{LAST}->Length);
}

=pod

=head2 Operations

The CPC::Season class overloads the following operators: +, -, <, <=, >, >=, ==, !=, 
lt, le, gt, ge, eq, ne, "", and int().  This allows the calling programs to manipulate 
calendar data in a powerful manner via CPC::Season objects.

=cut

=pod

=head3 Addition and Subtraction (+,-)

Addition and subtraction involving CPC::Season objects is performed utilizing the Month 
object's addition and subtraction operators on the middle month of the season.  Please 
see the documentation for addition and subtraction of Month objects for more information.

=cut

sub Plus {
	my($self,$thing,$switched) = @_;
	confess "Cannot add a CPC::Season object and $thing - exception thrown" if(not $thing =~ /^[+-]?\d+$/);
	return $self->{MIDDLE} + $thing;
}

sub Minus {
	my($self,$thing,$switched) = @_;

	# --- Subtract two CPC::Season objects ---

	if(blessed($thing) and $thing->isa(blessed($self))) {
		if($switched) { return $thing->{MIDDLE} - $self->{MIDDLE}; }
		else          { return $self->{MIDDLE} - $thing->{MIDDLE}; }
	}

	# --- Subtract an integer from a CPC::Season object ---

	elsif($thing =~ /^[+-]?\d+$/) {
		if($switched) { confess "Cannot subtract a CPC::Season object from an integer - exception thrown"; }
		else          { return $self->{MIDDLE} - $thing; }
	}

	# --- Invalid subtraction ---

	else {
		confess "Invalid subtraction operation involving a CPC::Season object - exception thrown"; }
	}

}

=pod

=head3 CPC::Season Object Comparison (<,<=,>,>=,==,!=, or lt,le,gt,ge,eq,ne)

 if($season1 > $season2) { print "$season1 comes after $season2"; }

The CPC::Season class compares two CPC::Season objects by comparing their middle month "int" 
values, e.g., their YYYYMM values.  Therefore, a season with a middle month coming 
later than another season's is numerically "greater than" the other season.  String 
comparison operators are equivalent to numeric comparison operators when using CPC::Season 
objects.

=cut

sub Compare {
	my($self,$thing,$switched) = @_;
	if(not blessed($thing) eq blessed($self)) { confess "Cannot compare a CPC::Season object to a non-CPC::Season object - exception thrown"; }
	if($switched) { return int($thing->{MIDDLE}) <=> int($self->{MIDDLE}); }
	else          { return int($self->{MIDDLE}) <=> int($thing->{MIDDLE}); }
}

=pod

=head3 Stringify and Int ('""',int())

 my $thisSeason = CPC::Season->new();
 my $YYYYMMM   = int($thisSeason);
 print "This season is $thisSeason\n";

If a CPC::Season object is invoked as a string, the season information is returned in MMMYYYY format
(e.g., JFM2012).  The year is taken as the year of the final month in the season.  Using a Month 
object in the int() function returns the season in YYYYMMM format (e.g., 2012010203) where the 
year is taken as the year of the final month in the season.

=cut

sub Stringify {
        my $self = shift;
        my $name = $self->Name;
        my $year = $self->LastMonth->Year;
        return $name.$year;
}

sub Int {
        my $self = shift;
        my $year = $self->LastMonth->Year;
	my $mm1  = $self->FirstMonth->Number;
	my $mm2  = $self->MiddleMonth->Number;
	my $mm3  = $self->LastMonth->Number;
	return 1000000*$year + 10000*$mm1 + 100*$mm2 + $mm3;
}

sub CatchAll {
        my $operator = pop;
        confess "Operator $operator cannot be used with a CPC::Season object - exception thrown";
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

