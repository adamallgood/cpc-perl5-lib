#!/usr/bin/perl

package CPC::EmailLog;

=pod

=head1 NAME

CPC::EmailLog - Email a file to one or more recipients with a custom subject line at run time

=head1 SYNOPSIS

 use strict;
 use warnings;
 use EmailLog;

=head1 DESCRIPTION

The CPC::EmailLog class constructs a CPC::EmailLog object via the new() method.  A CPC::EmailLog object
can store one or more e-mail addresses, change the subject line of an e-mail message, and
send an e-mail message to the recipients with the contents of a text file as the e-mail
body.  By default, the name of the calling process is included in the e-mail subject line.

=head1 REQUIREMENTS

=over 4

=item * mutt - a text based mail client for Linux/Unix operating systems

=back

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

# --- CPC Perl5 Library packages ---

use CPC::Trim qw(ltrim rtrim trim);

=pod

=head1 METHODS

=cut

=pod

=head2 Constructors

=cut

=pod

=head3 new

 my $msg = CPC::EmailLog->new();
 my $log = CPC::EmailLog->new(/path/to/logFile);

Returns a new CPC::EmailLog object to the calling program.  The new method can optionally take
the filename of the file to be used as the e-mail body as an argument.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	$self->{RECIPIENTS} = [];
	$self->{CALLER}     = $0;
	$self->{BODY}       = undef;
	$self->{SUBJECT}    = $0;
	$self->{ATTACHED}   = [];
	if(@_) { $self->{BODY} = shift; chomp($self->{BODY}); }
	bless($self,$class);
	return $self;
}

=pod

=head2 Object Data

Use these methods to set the e-mail body file, subject line, and recipients!

=cut

=pod

=head3 AddRecipient

 my $log = CPC::EmailLog->new(/path/to/logfile);
 $log->AddRecipient('first.last@noaa.gov');
 $log->AddRecipient('another.name@noaa.gov', 'yet.another@noaa.gov');
 $log->AddRecipient('and.another@noaa.gov, foo.bar@noaa.gov');

Sets e-mail address(es) to whom the message will be sent upon invoking the Send() method.
Multiple e-mail addresses can be sent as a list (multiple arguments), or as a comma-separated
string.  Leading or trailing space will be trimmed, but the addresses themselves are not
verified to be valid addresses.  That you have to do on your own.

=cut

sub AddRecipient {
	my $self       = shift;
	my $class      = blessed($self);
	croak "$class->AddRecipient: Argument(s) required - exception thrown" if(not @_);
	my @recipients = @_;
	@recipients    = split(/,/,join(',',@recipients));

	foreach my $address (@recipients) {
		$address = trim($address);
		push(@{$self->{RECIPIENTS}},$address);
	}

	return 1;
}

=pod

=head3 AddAttachment

 $log->AddAttachment($file1,$file2,$file3);
 $log->AddAttachment("THIS,THAT,WHATEVER");

Given the full path and filename of existing and non-empty file(s), adds them to a list of 
attachments that will be performed by the Send() method.  The files can be passed as a list, or 
within a comma-delimited string, or a combination of both.  Any whitespace around the commas will 
be trimmed off.

=cut

sub AddAttachment {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'AddAttachment';

	# --- Argument(s) ---

	croak "$class->$method: No arguments provided - exception thrown" unless(@_);
	my @attachments = @_;
	@attachments = split(/,/,join(',',@attachments));

	# --- Load attachments into object data ---

	ATTACHMENT: foreach my $attachment (@attachments) {
		$attachment = trim($attachment);

		unless(-s $attachment) {
			warn "$class->$method: $attachment is empty or does not exist - skipping";
			next ATTACHMENT;
		}

		push(@{$self->{ATTACHED}},$attachment);
	}

	return 1;		
}

=pod

=head3 AddBody

 my $log = EmailLog->new();
 $log->AddBody(/path/to/logfile);

Sets the filename of the text file to be used as the e-mail's body.  This method DOES NOT
CHECK to see if the file exists or has text.  That is done during the Send() method.
If a file was already set, this method will replace that value with the new argument.

=cut

sub AddBody {
	my $self  = shift;
	my $class = blessed($self);
	if(not @_) { carp "$class->AddBody: Nothing provided"; }
	else { $self->{BODY} = shift; }
	return $self->{BODY};
}

=pod

=head3 ChangeSubject

 my $log = CPC::EmailLog->new(/path/to/logfile);
 $log->ChangeSubject(" - SUCCESS on $today"); # Subject becomes "$0 - SUCCESS on $today"
 $log->ChangeSubject("Do not keep the caller name in the subject line");

The default subject line of an CPC::EmailLog object is the full path and filename of the calling
process.  If the argument string to this method begins with a whitespace character, then
the string is appended to the default subject line, even if the subject had been previously
changed.  Otherwise the argument string becomes the new subject line.

If no argument is provided, the subject line becomes "".

=cut

sub ChangeSubject {
	my $self    = shift;
	my $class   = blessed($self);
	my $subject = "";
	my $caller  = $self->{CALLER};
	if(not @_) { $self->{SUBJECT} = ""; return 1; }
	$subject = shift;
	chomp($subject);
	if($subject =~ /^\s+/) { $self->{SUBJECT} = $caller.$subject; }
	else { $self->{SUBJECT} = $subject; }
	return $self->{SUBJECT};
}

=pod

=head2 Send E-mail Messages

=cut

=pod

=head3 Send

 my $log = CPC::EmailLog->new(/path/to/logfile);
 $log->AddRecipient('Jon.Doe@noaa.gov');
 $log->Send();

Attempts to send the e-mail message to all recipients.  Croaks upon any send failure(s).
The Send method uses the Linux mutt command to send messages.

=cut

sub Send {
	my $self  = shift;
	my $class = blessed($self);
	if(not @{$self->{RECIPIENTS}}) { carp "$class->Send: No one to send to"; return 0; }
	if(not $self->{BODY})          { carp "$class->Send: Nothing to send";   return 0; }
	my $subject = $self->{SUBJECT};
	my $body    = $self->{BODY};
	my $nFailed = 0;
	my $nRecipients = @{$self->{RECIPIENTS}};

	foreach my $recipient (@{$self->{RECIPIENTS}}) {
		my $failed = undef;

		if(scalar(@{$self->{ATTACHED}})) {
			my $attachments = join(' ',@{$self->{ATTACHED}});
			$failed = system("/usr/bin/mutt -s \"$subject\" -a $attachments -- $recipient < $body");
		}
		else {
			$failed = system("/usr/bin/mutt -s \"$subject\" $recipient < $body");
		}

		if($failed) { carp "$class->Send: Could not send to $recipient"; $nFailed++; }
	}

	if($nFailed) { croak "$class->Send: $nFailed out of $nRecipients messages failed - exception thrown"; }
	return 1;
}

# --- Final POD Documentation ---

=pod

=head1 SEE ALSO

=over 4

=item * Perl Object Oriented Programming Tutorial L<http://perldoc.perl.org/perlootut.html>

=item * Perl Objects L<http://perldoc.perl.org/perlobj.html>

=item * Linux Mutt Documentation L<http://www.mutt.org/#doc>

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

