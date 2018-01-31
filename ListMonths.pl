#!/usr/bin/perl

use strict;
use warnings;
use CPC::Month;

=pod

=head1 NAME

ListMonths.pl - Print consecutive months in YYYYMM format

=head1 SYNOPSIS

 > ./ListMonths.pl YYYYMM1 YYYYMM2 > SomeFile.txt

=head1 DESCRIPTION

Given a starting and ending calender month in YYYYMM, prints a list 
of all of the calendar months between and including the starting and 
ending months, in YYYYMM format.  Each month is printed on a separate 
line.

=head1 AUTHOR

=begin html

<a href="mailto:Adam.Allgood@noaa.gov">Adam Allgood</a>
<br><br>
<a href="http://www.cpc.ncep.noaa.gov">Climate Prediction Center</a> - DOC/NOAA/NWS/NCEP
<br>

=end html

=cut

die "Two arguments required - exception thrown" if(not @ARGV == 2);
my $intStart = $ARGV[0]; chomp($intStart);
my $intEnd   = $ARGV[1]; chomp($intEnd);
my($start,$end);
eval { $start = CPC::Month->new($intStart); };
die "$intStart is not a valid month - exception thrown" if($@);
eval { $end   = CPC::Month->new($intEnd); };
die "$intEnd is not a valid month - exception thrown" if($@);

if($start > $end) {
	warn "$start comes after $end - reversing argument order...\n";
	my $temp = $start;
	$start   = $end;
	$end     = $temp;
}

for(my $mon=$start; $mon<=$end; $mon++) { print int($mon)."\n"; }

exit 0;

