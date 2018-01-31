#!/usr/bin/perl

=pod

=head1 NAME

MakeDocHTML - Create HTML files of all POD documentation in this library

=head1 DESCRIPTION

This script is intended for use with the library Makefile.

 cd $PERL5LIB
 make doc

=head1 AUTHOR

=begin html

<a href="mailto:Adam.Allgood@noaa.gov">Adam Allgood</a>
<br><br>
<a href="http://www.cpc.ncep.noaa.gov">Climate Prediction Center</a> - DOC/NOAA/NWS/NCEP
<br>

=end html

=cut

use strict;
use warnings;
use File::Basename qw(fileparse basename);
use File::Path qw(mkpath);
use Cwd;

my $dir      = getcwd();
my $regions  = "$dir/CPC/Regions";
my $stations = "$dir/CPC/Regions/Stations";
my @targets;

opendir(DIR,$dir) or die "MakeDocHTML.pl: Could not access $dir - exception thrown";

foreach my $file (readdir(DIR)) {
	push(@targets,"$dir/$file") if($file =~ /.pl$/ or $file =~ /.pm$/);
}

closedir(DIR);

opendir(REG,$regions) or die "MakeDocHTML.pl: Could not access $regions - exception thrown";

foreach my $file (readdir(REG)) {
	push(@targets,"$regions/$file") if($file =~ /.pl$/ or $file =~ /.pm$/);
}

closedir(REG);

opendir(STN,$stations) or die "MakeDocHTML.pl: Could not access $stations - exception thrown";

foreach my $file (readdir(STN)) {
        push(@targets,"$stations/$file") if($file =~ /.pl$/ or $file =~ /.pm$/);
}

closedir(STN);

foreach my $target (@targets) {
	my($fileroot,$filepath,$fileSuffix) = fileparse($target, qr/\.[^.]*/);
	my $docDir    = "$filepath/doc";
	unless(-d $docDir) { mkpath($docDir) or die "MakeDocHTML.pl: Could not create directory $docDir - exception thrown"; }
	my $docFailed = system("pod2html --infile=$target --outfile=$docDir/$fileroot.html");
	if($docFailed) { warn "MakeDocHTML.pl: Could not create documentation for $target"; }
	else { system("rm $dir/pod2htm*"); }
}

exit 0;

