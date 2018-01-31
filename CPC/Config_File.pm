#!/usr/bin/perl

package CPC::Config_File;
use Exporter;

@ISA = ('Exporter');
@EXPORT = ('load_settings');

=head1 NAME

CPC::Config_File - Reads settings from a configuration file

=head1 SYNOPSIS

 use CPC::Config_File;
 %settings = load_settings("file.conf","multi");

=head1 DESCRIPTION

Contains one or more methods pertaining to loading settings from a configuration file.

=head1 REQUIRES

Exporter

=head1 SEE ALSO



=cut

=head1 SUBROUTINES

=cut

=head2 load_settings(file,[sectionFlag])

=begin html

<p>Loads the settings from a given configuration file. The configuration file should have the following format:</p>
<ul>
<li>Comments begin with a '#' or a ';'</li>
<li>Setting names are all left-aligned</li>
<li>A '=' separates the setting name from its value, with optional spaces surrounding the '#'</li>
<li>Blank lines are allowed; they are simply ignored</li>
<li>All single and double quotes are ignored when part of the setting's value</li>
<li>Multiple sections are optional</li>
</ul>

<p>For example:</p>

<pre class="block">
; This file contains settings
name = Jimi Hendrix
age = 42
weight = 170lbs
</pre>

<p>or for multiple sections:</p>
<pre class="block">
; This file contains settings
[personal]
name = Jimi Hendrix
age = 42
weight = 170lbs
[financial]
worth = $50 million
taxes = 20%
</pre>

<p>Input</p>
<ul>
<li>file - Configuration file containing the settings</li>
<li>sectionFlag - Optional flag specifying whether there are multiple sections ("multi") or a single ("single") section</li>
</ul>

<p>Output</p>
<ul>
<li>Hash array containing the settings.</li>
</ul>

=cut
sub load_settings ($;$) {
	# Get the file name
	my $configFile = $_[0];
	# Get the optional flag to store in a 1-d hash (single-section INI)
	my $sectionFlag = $_[1];
	# Initialize a hash variable to store the settings
	my %settings;
	# Open the config file
	open (CONFIG, "$configFile") || die "Can't open the settings file $configFile: $!\n";
		# Loop over all lines of the file
		while (<CONFIG>) {
			# Remove the return character
			chomp;
			# See if this is a section header
			if (/^\s*\[(.+)\].*/) {
				$section = $1;
			}
			# See if this line is a "setting = value" line
			if (/^(\w+)\s*\=\s*[\'\"]?([^'"]*)[\'\"]?$/) {
				# Pull the desired components from the regex in the if-statement
				my $keyword = $1;
				my $value = $2;
				# Put the components into the hash array
				if ($sectionFlag eq "multi") {
					$settings{$section}{$keyword} = $value;
				} else {
					$settings{$keyword} = $value;
				}
			}
		}
	# Close the config file
	close (CONFIG);
	# Return the settings hash
	return %settings;
}

1;

