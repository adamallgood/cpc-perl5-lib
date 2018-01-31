#!/usr/bin/perl

package CPC::Trim;

=pod

=head1 NAME

CPC::Trim - Trim whitespace from strings

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Trim qw(ltrim rtrim trim);
 
 my $trimmed = trim($string);

=head1 DESCRIPTION

The CPC::Trim package provides three functions to the calling program: ltrim, rtrim, and trim. 
When passed a string argument, the ltrim function removes all leading whitespace, the 
rtrim function removes all trailing whitespace, and the trim function removes both leading 
and trailing whitespace.

The functions are not exported by default, so either export them in the use statement as 
shown above, or invoke them directly as:

 my $trimmed = CPC::Trim::trim($string);

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(ltrim rtrim trim);

# --- Functions ---

sub trim {
	croak "CPC::Trim::trim: Argument required - exception thrown" if(not @_);
        my $string = shift;
        $string    =~s/^\s+//;
        $string    =~s/\s+$//;
        return $string;
}

sub ltrim {
	croak "CPC::Trim::ltrim: Argument required - exception thrown" if(not @_);
        my $string = shift;
        $string    =~s/^\s+//;
        return $string;
}

sub rtrim {
	croak "CPC::Trim::rtrim: Argument required - exception thrown" if(not @_);
        my $string = shift;
        $string    =~s/\s+$//;
        return $string;
}

# --- Final POD Documentation ---

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

