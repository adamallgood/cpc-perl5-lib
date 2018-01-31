#!/usr/bin/perl

use strict;
use warnings;
use CPC::Day;

=pod

=head1 NAME

ListDays.pl - Print consecutive days in YYYYMMDD format

=head1 SYNOPSIS

 > ./ListDays.pl YYYYMMDD1 YYYYMMDD2 > SomeFile.txt

=head1 DESCRIPTION

Given a starting and ending calender date in YYYYMMDD, prints a list 
of all of the calendar days between and including the starting and 
ending dates, in YYYYMMDD format.  Each date is printed on a separate 
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
eval { $start = CPC::Day->new($intStart); };
die "$intStart is not a valid date - exception thrown" if($@);
eval { $end   = CPC::Day->new($intEnd); };
die "$intEnd is not a valid date - exception thrown" if($@);

if($start > $end) {
	warn "$start comes after $end - reversing argument order...\n";
	my $temp = $start;
	$start   = $end;
	$end     = $temp;
}

for(my $day=$start; $day<=$end; $day++) { print int($day)."\n"; }

exit 0;

