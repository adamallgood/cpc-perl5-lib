#!/usr/bin/perl

package CPC::Regions;

=pod

=head1 NAME

CPC::Regions - Base class for CPC Perl5 Library CPC::Regions::[Inheritor] objects

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::CensusDivisions;
 use CPC::Regions::ClimateDivisions;
 use CPC::Regions::StatesCONUS;
 use CPC::Regions::ForecastDivisions;
 use CPC::Regions::States;
 use CPC::Regions::Stations;

=head1 DESCRIPTION

The CPC::Regions class and its inheritors provide an object-oriented structure to 
store, access, and manipulate spatial based datasets.  The data are assumed to 
have two components, an "ID" value identifying the specific region (e.g., a 
station identifier, climate division number, anything), and a data value for 
the region.  Object methods can add, edit, or query these data, and several 
methods are provided for data assessment, e.g., determining if the data are 
numeric or if the dataset is complete.  Methods are also provided to work 
with missing data - e.g., defining what value constitutes a missing value when 
adding or querying the dataset.

Additionally, the four arithmetic operators (+, -, *, and /) and int() are overloaded 
to work with CPC::Regions object data, providing a powerful means to manipulate 
regional datasets with numeric data.  For example, suppose we have a 
dataset of station temperatures in degrees Celsius for thousands of stations 
stored in a CPC::Regions::Stations object.  If we want to convert these temperature 
data to degrees Fahrenheit, we can simply do:

 my $tempsFahrenheit = (9/5)*$tempsCelsius + 32;

We now have a new CPC::Regions::Stations object with the temperature data set to 
degrees Fahrenheit, and the second command ensures that missing data in this 
new dataset are treated in the same manner as the original object.

The CPC::Regions base class itself is not intended for direct use in a calling 
script; in fact, there is no way to add new regions to a plain CPC::Regions 
object.  Instead, this package provides most of the functionality to its 
inheritor classes.

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Hash::Util qw(lock_keys);
use overload
        '+'        => \&plus,
        '-'        => \&minus,
        '*'        => \&multiply,
        '/'        => \&divide,
	'int'      => \&integer,
        'nomethod' => \&CatchAll;

=pod

=head1 METHODS

=cut

=pod

=head2 Constructor

=cut

=pod

=head3 new

 my $regions = CPC::Regions->new();

Returns a CPC::Regions object to the calling program.  No regional IDs are set, and since there is no 
SetRegions method, you can't really do anything meaningful with this object, so use a CPC::Regions 
inheritor package to construct your object instead.

Since this is a template package, the object constructed is just a template.

=cut

sub new {
	my $class        = shift;
	my $self         = {};
	$self->{data}    = {};     # The data hash will contain ID and data value pairs!
	$self->{missing} = undef;  # Object-based missing data value!
	$self->{type}    = undef;  # Regions type (unique name for the set of regions stored in the object!)
	$self->{missingNumeric} = undef;
	$self->{idsNumeric}     = undef;
	bless($self,$class);
	return $self;
}

=pod

=head2 Change Methods

These methods allow the calling program to add or edit the object data.

=cut

=pod

=head3 Initialize

 $regions->Initialize(0.0);

Sets the data value for all regions to the argument value.

If the argument value is the same as the value returned by the GetMissing method, 
then all data will be set to missing.

=cut

sub Initialize {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'Initialize';

	# --- Argument ---

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my $value   = shift;
	my $missing = 0;

	if(defined $self->{missing}) {
		if($self->{missingNumeric}) { if($value == $self->{missing}) { $missing = 1; } }
		elsif($value eq $self->{missing})                            { $missing = 1; }
	}

	# --- Set the data values ---

	if($missing) {
		foreach my $id (keys %{$self->{data}}) { undef $self->{data}->{$id};    }
	}
	else {
		foreach my $id (keys %{$self->{data}}) { $self->{data}->{$id} = $value; }
	}

	return 1;
}

=pod

=head3 SetData

 $regions->SetData($id,$value);
 $regions->SetData(\%hashData);

Given a region ID and a data value argument, sets the regional data value in the object to the 
argument value.  Alternatively, given a single reference argument that, when dereferenced, is a 
hash with keys set to region IDs, sets the corresponding regional data values in the object to 
the hash values.

An invalid (does not match any region ID in the object) region ID will prompt carping, but missing 
IDs in the hash reference will not.

=cut

sub SetData {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'SetData';

	# --- Single region case ---

	if(@_ == 2) {
		my $id    = shift;
		my $value = shift;
		if(defined $value) {
			if($self->{missingNumeric}) { if($value == $self->{missing})   { undef $value; } }
			elsif(defined $self->{missing} and $value eq $self->{missing}) { undef $value; }
		}
		eval { $self->{data}->{$id} = $value };
		if($@) { carp "$class->$method: $id is an invalid regional ID"; }
	}

	# --- Data hash case ---

	elsif(@_ == 1 and ref $_[0] eq 'HASH') {
		my $data = shift;

		while(my($id,$value) = each %{$data}) {
			if(defined $value) {
				if($self->{missingNumeric}) { if($value == $self->{missing})   { undef $value; } }
				elsif(defined $self->{missing} and $value eq $self->{missing}) { undef $value; }
			}
			eval   { $self->{data}->{$id} = $value };
			if($@) { carp "$class->$method: $id is an invalid regional ID"; }
		}

	}

	# --- Invalid arguments ---

	else {
		croak "$class->$method: Invalid or missing arguments - exception thrown";
	}

	return 1;
}

=pod

=head3 SetMissing

my $missingVal = -9999;
$regions->SetMissing($missingVal);

Sets the value considered by the object to be a missing data value.  The GetMissing method will 
return the value passed into this method, GetData will return the value for regions with missing 
data, and data passed into the object via SetData or Initialize that are equal to this value 
will be considered as missing data.  Also, any existing data in the object equal to the value 
passed into this method will be considered missing.

=cut

sub SetMissing {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'SetMissing';

	# --- Argument ---

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my $missingVal   = shift;
	unless(defined $missingVal) { return 1; }

	# --- Determine if missing value is numeric ---

	if(looks_like_number($missingVal)) { $self->{missingNumeric} = 1; }
	else                               { $self->{missingNumeric} = 0; }

	# --- Undef (make missing) any existing data equivalent to this value ---

	VAL: while(my($id,$value) = each %{$self->{data}}) {
		next VAL unless(defined $value);
		if($self->{missingNumeric}) { if($value == $missingVal) { undef $self->{data}->{$id}; } }
		else                        { if($value eq $missingVal) { undef $self->{data}->{$id}; } }
	}

	# --- Set object missing value ---

	$self->{missing} = $missingVal;
	return 1;
}

=pod

=head2 Query Methods

These methods allow the calling program to access the object data.

=cut

=pod

=head3 Exists

 if($regions->Exists($id)) { do something... }
 else                      { warn "$id is not a valid region"; }

Returns a TRUE value to the calling program if the argument is an existing regional ID.

=cut

sub Exists {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'Exists';

	# --- Argument ---

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my $id = shift;

	# --- Return value ---

	return exists($self->{data}->{$id});
}

=pod

=head3 GetIDs

 my @IDs = $regions->GetIDs;

Returns a list of all of the regional IDs stored in the object.  If the IDs are all numeric, the 
list is sorted numerically ascending.  Otherwise, it is sorted lexically.

=cut

sub GetIDs {
	my $self    = shift;
	my @IDs     = keys %{$self->{data}};
	if($self->{idsNumeric}) { return sort { $a <=> $b } @IDs; }
	else { return sort { $a cmp $b } @IDs; }
}

=pod

=head3 GetData

 # --- Get a hash reference of all of the object data ---
 
 my $regionsData = $regions->GetData;
 my $regionValue = $$regionsData{$id};    # Dereferenced!
 
 # --- Get data value for a single region ---
 
 $regionValue = $regions->GetData($id);

Given no arguments, returns the object's data hash reference, where the keys are the regional IDs. 
Given a regional ID argument, returns that region's data value.  If a missing value was provided 
to the object via the SetMissing method, that value will be returned for missing data.  Otherwise, 
undef will be returned for missing data.  An invalid ID argument will prompt a warning and return 
undef to the calling program.

=cut

sub GetData {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetData';

	# --- Single region case ---

	if(@_) {
		my $id = shift;

		if(exists $self->{data}->{$id}) {
			if(defined $self->{data}->{$id}) { return $self->{data}->{$id}; }
			else                             { return $self->{missing};     }
		}
		else {
			carp "$class->$method: $id is an invalid regional ID";
			return undef;
		}

	}

	# --- Data hash case ---

	else {
		my $data = $self->{data};

		if(defined($self->GetMissing)) {

			foreach my $id (keys %{$data}) {
				unless(defined($data->{$id})) { $data->{$id} = $self->GetMissing; }
			}

		}

		return $data;
	}

}

=pod

=head3 GetMissing

 my $missingValue = $data->GetMissing;

Returns the object-specific missing data value as set by the SetMissing method.  If nothing was 
set, returns undef.

=cut

sub GetMissing {
	my $self = shift;
	return $self->{missing};
}

=pod

=head3 IsComplete or Complete

 if($data->IsComplete) { print "No missing regional data!"; }

Returns a TRUE value if no regions in the object have missing data.

=cut

sub IsComplete {
	my $self = shift;
	foreach my $id (keys %{$self->{data}}) { if($self->IsMissing($id)) { return 0; } }
	return 1;
}

sub Complete {
	goto &IsComplete;
}

=pod

=head3 IsEqual or Equal

 if($regions->IsEqual) { print "All regional values are equal to each other"; }

Returns a TRUE value if all of the regional data values are equal to each other, even if they all 
are missing.

=cut

sub IsEqual {
	my $self = shift;
	my @test = values %{$self->{data}};
	if(keys %{{ map {$_,1} @test }} == 1) { return 1; }
	else                                  { return 0; }
}

sub Equal {
	goto &IsEqual;
}

=pod

=head3 IsMissing or Missing

 if($regions->IsMissing($id)) { print "Region $id is missing"; }

Given a regional ID argument, returns a TRUE value if the data value for that region is missing 
in the object.  A false but defined value is returned if the region has data.

A missing or invalid argument prompts a warning and an undef value returned to the calling program.

=cut

sub IsMissing {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'IsMissing';

	# --- Argument ---

	unless(@_) {
		carp "$class->$method: Argument required";
		return undef;
	}

	my $id = shift;

	# --- Return value ---

	unless(exists $self->{data}->{$id}) {
		carp "$class->$method: $id is an invalid regional ID";
		return undef;
	}

	unless(defined $self->{data}->{$id}) { return 1; }
	else  { return 0; }
}

sub Missing {
	goto &IsMissing;
}

=pod

=head3 NotMissing

 unless($regions->NotMissing($id)) { print "Region $id is missing"; }

Given a regional ID argument, returns a TRUE value if the data value for that region is not 
missing in the object.  A false but defined value is returned if the region has missing data. 
This method is functionally the opposite of IsMissing.

A missing or invalid argument prompts a warning and an undef value returned to the calling program.

=cut

sub NotMissing {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'NotMissing';

	# --- Argument ---

	unless(@_) {
		carp "$class->$method: Argument required";
		return undef;
	}

	my $id = shift;

	# --- Return value ---

	unless(exists $self->{data}->{$id}) {
		carp "$class->$method: $id is an invalid regional ID";
		return undef;
	}

	unless(defined $self->{data}->{$id}) { return 0; }
	else                                 { return 1; }
}

=pod

=head3 IsMissingValue or MissingValue

 my $missing = -9999;
 if($regions->IsMissingValue($missing)) { print "$missing is the missing value for the data"; }

Given a value argument, returns TRUE if that value is equivalent to the object-specific data 
missing value (e.g., the value returned by GetMissing).

=cut

sub IsMissingValue {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'IsMissingValue';

	# --- Argument ---

	croak "$class->$method: Argument required - exception thrown" unless(@_);
	my $missingValue = shift;

	# --- Return value ---

	if(not defined($self->GetMissing) and not defined($missingValue)) { return 1; }
	elsif(not defined($self->GetMissing) and defined($missingValue))  { return 0; }
	elsif(defined($self->GetMissing) and not defined($missingValue))  { return 0; }
	elsif($self->{missingNumeric})                                    { return $missingValue == $self->GetMissing; }
	else                                                              { return $missingValue eq $self->GetMissing; }
}

sub MissingValue {
	goto &IsMissingValue;
}

=pod

=head3 IsNumeric or Numeric

 if($regions->IsNumeric) { print "We have all numeric data";  }
 else                    { print "Some data are not numeric"; }
 
 if($regions->IsNumeric($id)) { print "Region $id has numeric data";     }
 else                         { print "Region $id has non-numeric data"; }

Given a regional ID argument, returns a TRUE value if the regional data value is numeric. 
Given no arguments, the method returns a TRUE value if all of the non-missing object data 
are numeric values.

NOTE: If a region ID is supplied as an argument and the corresponding regional data 
value is missing, the value returned by the GetMissing method will be evaluated.  In 
other words, if you pass a numeric missing value into SetMissing, this method will return 
a TRUE value for a missing region.

An invalid ID argument will cause an exception.

=cut

sub IsNumeric {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'IsNumeric';

	# --- All regions case ---

	unless(@_) {

		ID: foreach my $id (keys %{$self->{data}}) {
			next ID unless(defined $self->{data}->{$id});
			return 0 unless(looks_like_number($self->{data}->{$id}));
		}

		return 1;
	}

	# --- Single region case ---

	else {
		my $id = shift;
		croak "$class->$method: $id is an invalid regional ID - exception thrown" unless(exists $self->{data}->{$id});
		unless(defined($self->{data}->{$id})) { return looks_like_number($self->{missing}); }
		else { return looks_like_number($self->{data}->{id}) }
	}

}

sub Numeric {
	goto &IsNumeric;
}

=pod

=head3 GetType

 unless($region1->GetType eq $region2->GetType) { print "Comparing two different region types"; }

Returns the regions "type" value to the calling program.  Two regions of the same type have the 
exact same set of regional IDs and can therefore be utilized in arithmetic operations together.

=cut

sub GetType {
	my $self = shift;
	return $self->{type};
}

=pod

=head3 GetHTMLTable

 my $table = $regions->GetHTMLTable('REGION','DATA');
 open(REGIONS,'>',$htmlFilename) or die "Could not open $htmlFilename for writing - $! - exception thrown";
 print REGIONS $table;
 close(REGIONS);

Returns an HTML formatted table containing all of the regional data stored in the object.  Each row in the 
table represents a region, with the first column containing the region's ID, and the second column containing 
the region's data value.  If the method is passed two arguments, those arguments are inserted as a header row. 
If an object specific missing value was defined using SetMissing, all missing data will be output with this 
value.  Otherwise, missing data will be output to the table as MISSING.

This method is primarily designed as a tool for quick viewing of your data as a debugging aid, so use caution 
if you decide to use this method as a tool to create data output files.  The HTML is as simple as can be.

=cut

sub GetHTMLTable {
	my $self = shift;

	# --- Arguments ---

	my($titleID,$titleValue);

	if(@_ >= 2) {
		$titleID    = shift;
		$titleValue = shift;
	}

	# --- Generate data hash ---

	my $data = $self->{data};

	foreach my $id (keys %{$data}) {

		unless(defined($data->{$id})) {
			if(defined($self->GetMissing)) { $data->{$id} = $self->GetMissing; }
			else                           { $data->{$id} = 'MISSING';         }
		}

	}

	# --- Generate HTML table ---

	my $result;
	$result = join("\n","<html>","<table border=\"1\">");

	if(defined $titleID and defined $titleValue) {
		$result = join("\n",$result,"<tr>","<th>$titleID</th>","<th>$titleValue</th>","</tr>");
	}

	foreach my $id ($self->GetIDs) {
		my $value = $data->{$id};
		$result = join("\n",$result,"<tr>","<td>$id</td>","<td>$value</td>","</tr>");
	}

	$result = join("\n",$result,"</table>","</html>");
	return $result;
}

=pod

=head2 Arithmetic Operations

The CPC::Regions class overloads the following arithmetic operators: +, -, *, and /. When two 
CPC::Regions objects are utilized in an arithmetic operation, that operation is performed between 
each of the two equivalent regional data values in the objects, with the resulting values 
stored in a new object.  When a CPC::Regions object is utilized in an arithmetic operation with a 
numeric value, the operation is carried out among all of the regional data values.

For example, given two regions with the following data:

=begin html

<h2><b>$region1</b></h2>
<table border="1">
<tr>
	<th>ID</th>
	<th>Value</th>
</tr>
<tr>
	<td>Reg1</td>
	<td>1</td>
</tr>
<tr>
	<td>Reg2</td>
	<td>2</td>
</tr>
<tr>
	<td>Reg3</td>
	<td>3</td>
</tr>
</table>

<br>

<h2><b>$region2</b></h2>
<table border="1">
<tr>
        <th>ID</th>
        <th>Value</th>
</tr>
<tr>
        <td>Reg1</td>
        <td>4</td>
</tr>
<tr>
        <td>Reg2</td>
        <td>3</td>
</tr>
<tr>
        <td>Reg3</td>
        <td>2</td>
</tr>
</table>

=end html

Adding the two objects would result in a third object with regions set to the sum of the two addend regions:

 my $region3 = $region1 + $region2;

=begin html

<h2><b>$region3</b></h2>
<table border="1">
<tr>
        <th>ID</th>
        <th>Value</th>
</tr>
<tr>
        <td>Reg1</td>
        <td>5</td>
</tr>
<tr>
        <td>Reg2</td>
        <td>5</td>
</tr>
<tr>
        <td>Reg3</td>
        <td>5</td>
</tr>
</table>

=end html

And

 my $region4 = $region3 + 5;

would result in:

=begin html

<h2><b>$region4</b></h2>
<table border="1">
<tr>
        <th>ID</th>
        <th>Value</th>
</tr>
<tr>
        <td>Reg1</td>
        <td>10</td>
</tr>
<tr>
        <td>Reg2</td>
        <td>10</td>
</tr>
<tr>
        <td>Reg3</td>
        <td>10</td>
</tr>
</table>

=end html

Due to the nature of these operations, CPC::Regions objects can only be used with other CPC::Regions 
objects with the same GetType value or numeric values in arithmetic operations.  Also, when 
dividing by an object, beware of any data values set to zero!

If a regional value is missing in an object used in an operation, that same region will be 
set to missing in the resulting object.  If two objects that have the same object-specific 
missing value (e.g., the value you set using SetMissing) are used in an operation, the 
resulting object will have the same value upon invocation of GetMissing.  If the two objects 
have different missing values, however, neither value will be bequeathed to the resulting 
object.  In an operation involving a CPC::Regions object and a numeric scalar, if the numeric 
scalar is equal to the object's specific missing value, the resulting object will be missing 
all data and its missing value will be set to the argument object's missing value.

An exception will be thrown if any CPC::Regions object used in an arithmetic operation has 
non-numeric data, or if a non-numeric scalar is used in the operation.  This is safer than Perl's 
default behavior, where the interpreter attempts to convert non-numeric strings to numeric 
values before performing the operation.

=cut

sub plus {
	my($self,$thing,$switched) = @_;
	my $class                  = blessed($self);
	my $selfType               = $self->GetType;
	my $result                 = $class->new($selfType);
	croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($self->IsNumeric);

	# --- Two objects ---

	if(blessed($thing) and $thing->isa($class)) {
		croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($thing->IsNumeric);
		my $thingType = $thing->GetType;
		croak "Cannot use a '$selfType' type $class object and a '$thingType' type $class object in an arithmetic operation - exception thrown" unless($selfType eq $thingType);

		if(defined $thing->GetMissing and $self->IsMissingValue($thing->GetMissing)) { $result->SetMissing($thing->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and $thing->NotMissing($id));
			my $selfValue  = $self->GetData($id);
			my $thingValue = $thing->GetData($id);
			if($switched) { $result->SetData($id,$thingValue + $selfValue); }
			else          { $result->SetData($id,$selfValue + $thingValue); }
		}  # :ID
	
	}

	# --- Object and numeric scalar ---

	elsif(looks_like_number($thing)) {

		if(defined $self->GetMissing) { $result->SetMissing($self->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and not $self->IsMissingValue($thing));
			my $selfValue = $self->GetData($id);
			if($switched) { $result->SetData($id,$thing + $selfValue); }
			else          { $result->SetData($id,$selfValue + $thing); }
		}  # :ID

	}

	# --- Invalid operation ---

	else {
		croak "Invalid operation involving a $selfType $class object - exception thrown";
	}

	# --- Return result ---

	return $result;
}

sub minus {
	my($self,$thing,$switched) = @_;
	my $class                  = blessed($self);
	my $selfType               = $self->GetType;
	my $result                 = $class->new($selfType);
	croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($self->IsNumeric);

	# --- Two objects ---

	if(blessed($thing) and $thing->isa($class)) {
		croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($thing->IsNumeric);
		my $thingType = $thing->GetType;
		croak "Cannot use a '$selfType' type $class object and a '$thingType' type $class object in an arithmetic operation - exception thrown" unless($selfType eq $thingType);

		if(defined $thing->GetMissing and $self->IsMissingValue($thing->GetMissing)) { $result->SetMissing($thing->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and $thing->NotMissing($id));
			my $selfValue  = $self->GetData($id);
			my $thingValue = $thing->GetData($id);
			if($switched) { $result->SetData($id,$thingValue - $selfValue); }
			else          { $result->SetData($id,$selfValue - $thingValue); }
		}  # :ID

	}

	# --- Object and numeric scalar ---

	elsif(looks_like_number($thing)) {

		if(defined $self->GetMissing) { $result->SetMissing($self->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and not $self->IsMissingValue($thing));
			my $selfValue = $self->GetData($id);
			if($switched) { $result->SetData($id,$thing - $selfValue); }
			else          { $result->SetData($id,$selfValue - $thing); }
		}  # :ID

	}

	# --- Invalid operation ---

	else {
		croak "Invalid operation involving a $selfType $class object - exception thrown";
	}

	# --- Return result ---

	return $result;
}

sub multiply {
	my($self,$thing,$switched) = @_;
	my $class                  = blessed($self);
	my $selfType               = $self->GetType;
	my $result                 = $class->new($selfType);
	croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($self->IsNumeric);

	# --- Two objects ---

	if(blessed($thing) and $thing->isa($class)) {
		croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($thing->IsNumeric);
		my $thingType = $thing->GetType;
		croak "Cannot use a '$selfType' type $class object and a '$thingType' type $class object in an arithmetic operation - exception thrown" unless($selfType eq $thingType);

		if(defined $thing->GetMissing and $self->IsMissingValue($thing->GetMissing)) { $result->SetMissing($thing->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and $thing->NotMissing($id));
			my $selfValue  = $self->GetData($id);
			my $thingValue = $thing->GetData($id);
			if($switched) { $result->SetData($id,$thingValue * $selfValue); }
			else          { $result->SetData($id,$selfValue * $thingValue); }
		}  # :ID

	}

	# --- Object and numeric scalar ---

	elsif(looks_like_number($thing)) {

		if(defined $self->GetMissing) { $result->SetMissing($self->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and not $self->IsMissingValue($thing));
			my $selfValue = $self->GetData($id);
			if($switched) { $result->SetData($id,$thing * $selfValue); }
			else          { $result->SetData($id,$selfValue * $thing); }
		}  # :ID

	}

	# --- Invalid operation ---

	else {
		croak "Invalid operation involving a $selfType $class object - exception thrown";
	}

	# --- Return result ---

	return $result;
}

sub divide {
	my($self,$thing,$switched) = @_;
	my $class                  = blessed($self);
	my $selfType               = $self->GetType;
	my $result                 = $class->new($selfType);
	croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($self->IsNumeric);

	# --- Two objects ---

	if(blessed($thing) and $thing->isa($class)) {
		croak "Cannot use a $class object with non-numeric data in an arithmetic operation - exception thrown" unless($thing->IsNumeric);
		my $thingType = $thing->GetType;
		croak "Cannot use a '$selfType' type $class object and a '$thingType' type $class object in an arithmetic operation - exception thrown" unless($selfType eq $thingType);

		if(defined $thing->GetMissing and $self->IsMissingValue($thing->GetMissing)) { $result->SetMissing($thing->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and $thing->NotMissing($id));
			my $selfValue  = $self->GetData($id);
			my $thingValue = $thing->GetData($id);
			if($switched) { $result->SetData($id,$thingValue / $selfValue); }
			else          { $result->SetData($id,$selfValue / $thingValue); }
		}  # :ID

	}

	# --- Object and numeric scalar ---

	elsif(looks_like_number($thing)) {

		if(defined $self->GetMissing) { $result->SetMissing($self->GetMissing); }

		ID: foreach my $id ($class->new($self->GetType)->GetIDs) {
			next ID unless($self->NotMissing($id) and not $self->IsMissingValue($thing));
			my $selfValue = $self->GetData($id);
			if($switched) { $result->SetData($id,$thing / $selfValue); }
			else          { $result->SetData($id,$selfValue / $thing); }
		}  # :ID

	}

	# --- Invalid operation ---

	else {
		croak "Invalid operation involving a $selfType $class object - exception thrown";
	}

	# --- Return result ---

	return $result;
}

=pod

=head2 Other Operations

Here is some other stuff you can do to the object data.

=cut

=pod

=head3 int

 my $obj = CPC::Regions::ClimateDivisions->new();
 $obj->Initialize(20.3);
 int($obj);  # All object values are now 20!

The int() function on CPC::Regions objects is overloaded by CPC::Regions::integer, which performs 
int() on every numeric and non-missing regional data value.

=cut

sub integer {
	my $self  = shift;
	my $class = blessed($self);

	ID: foreach my $id ($self->GetIDs) {
		my $val = $self->GetData($id);
		next ID unless($self->NotMissing($id) and looks_like_number($val));
		$self->SetData($id,int($val));
	}  # :ID

	return $self;
}

=pod

=head3 Numericize

 $obj->Numericize();

Sets as missing any non-numeric regional data value in the object, so that the object will return 
true in the case of $obj->IsNumeric().

=cut

sub Numericize {
	my $self  = shift;
	my $class = blessed($self);

	REGION: while(my($id,$value) = each %{$self->{data}}) {
		next REGION unless(defined $value);
		unless(looks_like_number($value)) { undef $self->{data}->{$id}; }
	}  # :REGION

	return 1;
}

=pod

=head3 CatchAll

 if($region1 == $region2) { # Will throw exception }

Any operation other than the four arithmetic operators (+, -, *, and /) or int() used on a CPC::Regions object will invoke 
this method, which throws an exception telling you that you cannot use that operation!

=cut

sub CatchAll {
	my $self     = shift;
	my $class    = blessed($self);
	my $operator = pop;
	croak "Operator $operator cannot be performed with a $class object - exception thrown";
}

=pod

=head1 SEE ALSO

=over 4

=item * Operator Overloading in Perl L<http://perldoc.perl.org/overload>

=item * Perl Object Oriented Programming Tutorial L<http://perldoc.perl.org/perlootut.html>

=item * Perl Objects L<http://perldoc.perl.org/perlobj.html>

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

