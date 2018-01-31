#!/usr/bin/perl

package CPC::LeapYear;

=pod

=head1 NAME

CPC::LeapYear - Perl package to determine if a Gregorian year is a leap year

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::LeapYear qw(isLeapYear notLeapYear);
 if(isLeapYear(2004))  { ... }  # TRUE
 if(notLeapYear(2005)) { ... }  # TRUE

=head1 DESCRIPTION

The CPC::LeapYear package provides two functions:

=over 4

=item * isLeapYear - Returns 1 if the argument is a leap year, 0 if not (including non-integer input)

=item * notLeapYear - Returns 1 if the argument is not a leap year (including non-integer input), 0 if it is

=back

The functions are not exported by default, so either export them in the use statement as
shown above, or invoke them directly as:

 if(CPC::LeapYear::isLeapYear($YYYY)) { ... }

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(isLeapYear notLeapYear);

sub isLeapYear {
	croak "LeapYear::isLeapYear: Argument required - exception thrown" if(not @_);
	my $year = shift;
	if($year =~ /^[+-]?\d+$/ and 0 == $year % 4 and 0 != $year % 100 or 0 == $year % 400) { return 1; }
	else                                                                                  { return 0; }
}

sub notLeapYear {
	croak "LeapYear::notLeapYear: Argument required - exception thrown" if(not @_);
	my $year = shift;
	if($year =~ /^[+-]?\d+$/ and 0 == $year % 4 and 0 != $year % 100 or 0 == $year % 400) { return 0; }
	else                                                                                  { return 1; }
}

=pod

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

