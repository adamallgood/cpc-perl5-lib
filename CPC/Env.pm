#!/usr/bin/perl

package CPC::Env;

=pod

=head1 NAME

CPC::Env - Includes several utilities to work with environment variables

=head1 SYNOPSIS

 #!/usr/bin/perl
 use strict;
 use warnings;
 use CPC::Env qw(CheckENV RemoveSlash getENV);

=head1 DESCRIPTION

 if(CheckENV(VAR))            { # VAR is set to a directory in your environment! }
 elsif(defined CheckENV(VAR)) { # VAR is defined in your environment but not set to a directory! }
 else                         { # VAR is not defined in your environment! }

 $dir = RemoveSlash($dir);    { # /some/directory/path/ becomes /some/directory/path
                                # D:\some\directory\path\ becomes D:\some\directory\path
                                # /this and D:\this are left unchanged }

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(CheckENV RemoveSlash getENV);

=pod

=head1 METHODS

=cut

=pod

=head2 CheckENV()

 my $result = CheckENV(VAR);

=over 4

=item * Returns a true value when (-d $ENV{VAR}) is true

=item * Returns 0 - a false but defined value - when $ENV{VAR} is defined but not a directory

=item * Returns undef when $ENV{VAR} is not defined or if user supplies no argument

=back

=cut

sub CheckENV {

	unless(@_) {
		carp "Env::CheckENV: Argument required";
		return undef;
	}

	my $var = shift;

	if(defined $ENV{$var}) {
		if(-d $ENV{$var}) { return 1; }
		else              { return 0; }
	}
	else                      { return undef; }

}

=pod

=head2 RemoveSlash()

 STRING = RemoveSlash(STRING);

Chomps the string argument, then removes the final character if it is a slash (/ or \).
Croaks if no argument is provided.

=cut

sub RemoveSlash {
	croak "Env::RemoveSlash: Argument required" unless(@_);
	my $dir = shift;
	chomp $dir;
	$dir =~ s/\/\z//;
	$dir =~ s/\\\z//;
	return $dir;
}

=pod

=head2 getENV()

Retrieves all environment variables from a given source file

 %HASH = getENV(FILE,SHELL);

 where
     FILE is the file containing all the environment variable definitions, and
     SHELL is the shell associated with FILE (currently only bash, ksh, and csh are supported)

This will insert all environment from FILE into %HASH. Note that you shouldn't use a tilde (~) in the
file name, since Perl won't know that redirects to the home dir. Instead, use $ENV{HOME}. For example:

 %env_vars = getENV("$ENV{HOME}/.profile","bash");

=cut

sub getENV {
	# Get args
	my $file  = shift;
	my $shell = shift;
	# See if file exists
	croak "Usage: getENV(FILE,SHELL) -> FILE $file doesn't exist" unless -e $file;
	# See if the shell arg is a valid shell
	my $regex = 'bash|csh|ksh';
	croak "Usage: getENV(FILE,SHELL) -> SHELL doesn't match regex" unless $shell =~ m/\b($regex)\b/;
	# Get environment variables
	my $env_str;
	if ($shell eq 'bash') {
		$env_str = `$shell -c '. $file ; env'`;
	} elsif ($shell eq 'ksh') {
		$env_str = `$shell -c '. $file ; env'`;
	} elsif ($shell eq 'csh') {
		$env_str = `$shell -c 'source $file ; env'`;
	}
	# Loop over environment variables in the returned string and place in hash
	my %env_hash;
	foreach my $line (split /\n/, $env_str) {
		my ($key, $val) = split(/=/,$line);
		$env_hash{$key} = $val;
	}
	# Return the hash of environment variables
	return %env_hash;
}

=pod

=head1 AUTHOR

=begin html

<a href="mailto:Adam.Allgood@noaa.gov">Adam Allgood</a>
<br>
<a href="mailto:Mike.Charles@noaa.gov">Mike Charles</a>
<br><br>
<a href="http://www.cpc.ncep.noaa.gov">Climate Prediction Center</a> - DOC/NOAA/NWS/NCEP
<br>

=end html

=cut

# ---------------
1;

