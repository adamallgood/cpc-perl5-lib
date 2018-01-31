#!/usr/bin/perl

package CPC::SpawnGrads;

=pod

=head1 NAME

CPC::SpawnGrads - Run a grads -blc command in Perl

=head1 SYNOPSIS

 use strict;
 use warnings;
 use CPC::SpawnGrads qw(grads);

=head1 DESCRIPTION

=head1 REQUIREMENTS

=head1 AUTHOR

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;
use Carp;

use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(grads);

=pod

=head1 METHODS

=cut

=pod

=head2 grads

=cut

sub grads {
    unless(@_) { return "CPC::SpawnGrads::grads error: Argument required\n"; }
    my $gradsCmd = shift;
    chomp $gradsCmd;

    # --- Execute GrADS and collect STDOUT ---

    my $result = `grads -blc \"$gradsCmd\"`;

    # --- Check for GrADS failure ---

    unless(defined $result) { return "CPC::SpawnGrads::grads error: GrADS did not run correctly\n"; }

    # --- Check results from GrADS for errors ---

    my $r = $result;
    $r    =~ tr/\n/ /;

    if($r =~ /warning/i or $r =~ /undefined/i or $r =~ /constant/i or $r =~ /cannot/i or $r =~ /error/i) {
        return "CPC::SpawnGrads::grads: Potential GrADS runtime problem detected. Output from GrADS:\n$result\n";
    }
    else {
        return 0;
    }

}

=pod

=head1 AUTHOR

=cut

# ---------------
1;

