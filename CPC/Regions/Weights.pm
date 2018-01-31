#!/usr/bin/perl

package CPC::Regions::Weights;

=pod

=head1 NAME

CPC::Regions::Weights - Create weighted average data utilizing CPC::Regions::[Type] objects

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::[TYPE1];
 use CPC::Regions::[TYPE2];
 ...
 use CPC::Regions::Weights;

=head1 DESCRIPTION

As noted in the CPC::Regions::Util documentation, some CPC::Regions::[TYPE] regions are comprised of regions from another 
CPC::Regions::[TYPE] class.  Therefore, if a user has a dataset for one set of regions, it is possible to create data 
for a different set of regions that are built of the former regions by summing and averaging the regional data 
into the larger regions.  Since a straight average is rarely helpful for spatial data comprised of irregularly 
shaped regions, this package provides the means to compute weighted averages based on user supplied weighting 
factors.

=head3 Computing a weighted average

Given a region comprised of N subregions, data on the subregions (X1, X2, ..., XN), and weighting factors on the 
subregions (W1, W2, ..., WN), where the weighting factors can be subregional populations, land area, or another 
form of weighting data, the weighted average value, V, for the region is:

 V = F1*X1 + F2*X2 + ... + FN*XN

where F(i) = W(i) / (W1 + W2 + ... + WN)

This technique is utilized in all methods provided by this package.  WARNING: W1 + W2 + ... + WN cannot sum to 
zero, as this would create badness.

=cut

# --- Standard Perl packages ---

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed looks_like_number);

# --- CPC Perl5 Library packages ---

use CPC::Regions;
use CPC::Regions::CensusDivisions;
use CPC::Regions::ClimateDivisions;
use CPC::Regions::States;
use CPC::Regions::Util qw(newClimateDivisionsWithStatesIDs newClimateDivisionsWithForecastDivisionsIDs newStatesWithCensusDivisionsIDs);

=pod

=head1 METHODS

=cut

=pod

=head3 new

 my $weightingTool = CPC::Regions::Weights->new();

Returns a reference blessed into the CPC::Regions::Weights package (a CPC::Regions::Weights object).

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless($self,$class);
	return $self;
}

=pod

=head3 GetStatesFromClimateDivisions

 my $statesData = $weightingTool->GetStatesFromClimateDivisions($data,$weights);

Given two CPC::Regions::ClimateDivisions objects, one containing numeric data and the other a complete set of numeric 
weighting factors, returns a CPC::Regions::States object with state data set to the weighted average of the climate 
divisions within each state.

NOTE: Since the 344 climate divisions only cover the contiguous United States, data for Alaska (AK) and Hawaii 
(HI) will be set to missing.

A missing weighting factor value will cause an exception, and a missing climate divisional value will cause the 
state containing the division's value to be set as missing.

=cut

sub GetStatesFromClimateDivisions {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetStatesFromClimateDivisions";

	# --- Arguments ---

	croak "$class->$method: Two arguments required - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Argument(s) must be CPC::Regions::ClimateDivisions objects - exception thrown" unless(blessed($data) and blessed($weights) and $data->isa("CPC::Regions::ClimateDivisions") and $weights->isa("CPC::Regions::ClimateDivisions"));
	croak "$class->$method: Argument data must be numeric - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: Weights argument cannot have missing data - exception thrown" unless($weights->Complete);

	# --- Compute weights ---

	my $states = newClimateDivisionsWithStatesIDs;  # A CPC::Regions::ClimateDivisions object!
	my $sums   = CPC::Regions::States->new();
	$sums->Initialize(0);

	foreach my $stcd ($weights->GetIDs) {
		my $st = $states->GetData($stcd);
		$sums->SetData($st,$sums->GetData($st) + $weights->GetData($stcd));
	}

	foreach my $stcd ($weights->GetIDs) {
		my $st = $states->GetData($stcd);
		$weights->SetData($stcd,$weights->GetData($stcd) / $sums->GetData($st));
	}

	# --- Compute weighted average ---

	my $result       = CPC::Regions::States->new();
	$result->Initialize(0);
	$result->SetMissing($data->GetMissing);
	my $weightedData = $weights * $data;

	STCD: foreach my $stcd ($weightedData->GetIDs) {
		my $st = $states->GetData($stcd);

		if($weightedData->IsMissing($stcd)) {
			$result->SetData($st,$result->GetMissing);
			next STCD;
		}

		unless($result->IsMissing($st)) {
			$result->SetData($st,$result->GetData($st) + $weightedData->GetData($stcd));
		}

	}  # :STCD

	return $result;
}

=pod

=head3 GetCensusDivisionsFromStates

 my $CensusDivisionsData = $weightingTool->GetCensusDivisionsFromStates($data,$weights);

Given two CPC::Regions::States objects, one containing numeric data and the other a complete* set of numeric
weighting factors, returns a CPC::Regions::CensusDivisions object with divisional data set to the weighted 
average of the states within each Census division.

A missing weighting factor value will cause an exception, and a missing state value will cause the
Census division containing the state's value to be set as missing.

* Contiguous U.S. only case: If weights for both Alaska (HI) and Hawaii (HI) are missing, the states 
will be ignored (e.g., their weight and value will both be set to zero) in the calculation.  As a good 
practice, therefore, don't use zero as the missing value!

=cut

sub GetCensusDivisionsFromStates {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetCensusDivisionsFromStates";

	# --- Arguments ---

	croak "$class->$method: Two arguments required - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Argument(s) must be CPC::Regions::States objects - exception thrown" unless(blessed($data) and blessed($weights) and $data->isa("CPC::Regions::States") and $weights->isa("CPC::Regions::States"));
	croak "$class->$method: Argument data must be numeric - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
#	croak "$class->$method: Weights argument cannot have missing data - exception thrown" unless($weights->IsCompleteContiguous);
#****************************
	print "\n\n";
	foreach my $ST (CPC::Regions::States->new()->GetIDs) {
		my $VAL = $weights->GetData($ST);
		print join(' , ',$ST,"$VAL\n");
	}
	print "\n";
	my $MV = $weights->GetMissing;
	print "Missing Value: $MV\n\n";
#****************************
		
	# Zero out AK and HI for CONUS cases!
	if($weights->IsCompleteContiguous and not $weights->IsComplete) {
		$weights->SetData('AK',0);
		$weights->SetData('HI',0);
		$data->SetData('AK',0);
		$data->SetData('HI',0);
	}
	else { croak "$class->$method: Weights argument cannot have missing data - exception thrown"; }

	# --- Compute weights ---

	my $divisions = newStatesWithCensusDivisionsIDs;  # A CPC::Regions::States object!
	my $sums   = CPC::Regions::CensusDivisions->new();
	$sums->Initialize(0);

	foreach my $st ($weights->GetIDs) {
		my $div = $divisions->GetData($st);
		$sums->SetData($div,$sums->GetData($div) + $weights->GetData($st));
	}

	foreach my $st ($weights->GetIDs) {
		my $div = $divisions->GetData($st);
		$weights->SetData($st,$weights->GetData($st) / $sums->GetData($div));
	}

	# --- Compute weighted average ---

	my $result       = CPC::Regions::CensusDivisions->new();
	$result->Initialize(0);
	$result->SetMissing($data->GetMissing);
	my $weightedData = $weights * $data;

	ST: foreach my $st ($weightedData->GetIDs) {
		my $div = $divisions->GetData($st);

		if($weightedData->IsMissing($st)) {
			$result->SetData($div,$result->GetMissing);
			next ST;
		}

		unless($result->IsMissing($div)) {
			$result->SetData($div,$result->GetData($div) + $weightedData->GetData($st));
		}

	}  # :ST

	return $result;
}

=pod

=head3 GetForecastDivisionsFromClimateDivisions

 my $ForecastDivisionsData = $weightingTool->GetForecastDivisionsFromClimateDivisions($data,$weights);

Given two CPC::Regions::ClimateDivisions objects, one containing numeric data and the other a complete set of numeric
weighting factors, returns a CPC::Regions::ForecastDivisions object with forecast divisional data set to the weighted 
average of the climate divisions within each forecast division.

A missing weighting factor value will cause an exception, and a missing climate divisional value will cause the
forecast division containing the climate division's value to be set as missing.

=cut

sub GetForecastDivisionsFromClimateDivisions {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetForecastDivisionsFromClimateDivisions";

	# --- Arguments ---

	croak "$class->$method: Two arguments required - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Argument(s) must be CPC::Regions::ClimateDivisions objects - exception thrown" unless(blessed($data) and blessed($weights) and $data->isa("CPC::Regions::ClimateDivisions") and $weights->isa("CPC::Regions::ClimateDivisions"));
	croak "$class->$method: Argument data must be numeric - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: Weights argument cannot have missing data - exception thrown" unless($weights->Complete);

	# --- Compute weights ---

	my $fds    = newClimateDivisionsWithForecastDivisionsIDs;  # A CPC::Regions::ClimateDivisions object!
	my $sums   = CPC::Regions::ForecastDivisions->new();
	$sums->Initialize(0);

	foreach my $stcd ($weights->GetIDs) {
		my $fd = $fds->GetData($stcd);
		$sums->SetData($fd,$sums->GetData($fd) + $weights->GetData($stcd));
	}

	foreach my $stcd ($weights->GetIDs) {
		my $fd = $fds->GetData($stcd);
		$weights->SetData($stcd,$weights->GetData($stcd) / $sums->GetData($fd));
	}

	# --- Compute weighted average ---

	my $result       = CPC::Regions::ForecastDivisions->new();
	$result->Initialize(0);
	$result->SetMissing($data->GetMissing);
	my $weightedData = $weights * $data;

	STCD: foreach my $stcd ($weightedData->GetIDs) {
		my $fd = $fds->GetData($stcd);

		if($weightedData->IsMissing($stcd)) {
			$result->SetData($fd,$result->GetMissing);
			next STCD;
		}

		unless($result->IsMissing($fd)) {
			$result->SetData($fd,$result->GetData($fd) + $weightedData->GetData($stcd));
		}

	}  # :STCD

	return $result;
}

=pod

=head3 GetConusFromStates

 my $ConusValue = $weightingTool->GetConusFromStates($data,$weights);

Given two CPC::Regions::States objects, one containing numeric data for the CONUS (Contiguous United 
States) and the other a complete set of numeric weighting factors for the CONUS, returns a scalar 
value set to the weighted average of the contiguous states.

A missing weighting factor (excluding non-contiguous states) will cause an exception, and a missing 
contiguous state value will cause the result to be returned as missing.

=cut

sub GetConusFromStates {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetWeightedAverage";

	# --- Arguments ---

	croak "$class->$method: Two arguments required - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Argument(s) must be CPC::Regions::States type objects - exception thrown" unless(blessed($data) and blessed($weights) and $data->isa("CPC::Regions::States") and $weights->isa("CPC::Regions::States"));
	croak "$class->$method: Argument(s) must be the same CPC::Regions type - exception thrown" unless($data->GetType eq $weights->GetType);
	croak "$class->$method: Argument data must be numeric - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: Weights argument cannot have missing data - exception thrown" unless($weights->CompleteContiguous);

        # --- Compute weights ---

	my $sum = 0;
	foreach my $region ($weights->GetIDsContiguous) { $sum = $sum + $weights->GetData($region); }
	foreach my $region ($weights->GetIDsContiguous) { $weights->SetData($region, $weights->GetData($region) / $sum); }

	# --- Compute weighted average ---

	my $result = 0;
	my $weightedData = $weights * $data;

	REGION: foreach my $region ($weightedData->GetIDsContiguous) {
		if($weightedData->IsMissing($region)) { return $data->GetMissing; }
		else { $result = $result + $weightedData->GetData($region); }
	}  # :REGION

	return $result;
}

=pod

=head3 GetWeightedAverage

 my $scalar = $weightingTool->GetWeightedAverage($data,$weights);

Given two CPC::Regions::[TYPE] objects, one containing numeric data and the other a complete set of numeric
weighting factors, returns a scalar value set to the weighted average of the regions.

A missing weighting factor value will cause an exception, and a missing data value will cause the
weighted average to be returned as missing.

=cut

sub GetWeightedAverage {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = "GetWeightedAverage";

	# --- Arguments ---

	croak "$class->$method: Two arguments required - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Argument(s) must be CPC::Regions type objects - exception thrown" unless(blessed($data) and blessed($weights) and $data->isa("CPC::Regions") and $weights->isa("CPC::Regions"));
	croak "$class->$method: Argument(s) must be the same CPC::Regions type - exception thrown" unless($data->GetType eq $weights->GetType);
	croak "$class->$method: Argument data must be numeric - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: Weights argument cannot have missing data - exception thrown" unless($weights->Complete);

	# --- Compute weights ---

	my $sum = 0;
	foreach my $region ($weights->GetIDs) { $sum = $sum + $weights->GetData($region); }
	foreach my $region ($weights->GetIDs) { $weights->SetData($region, $weights->GetData($region) / $sum); }

	# --- Compute weighted average ---

	my $result = 0;
	my $weightedData = $weights * $data;

	REGION: foreach my $region ($weightedData->GetIDs) {
		if($weightedData->IsMissing($region)) { return $data->GetMissing; }
		else { $result = $result + $weightedData->GetData($region); }
	}  # :REGION

	return $result;
}

=pod

=head1 SEE ALSO

=begin html

<ul>
<li><a href="../../doc/Regions.html">CPC::Regions class documentation</a></li>
<li><a href="CensusDivisions.html">CPC::Regions::CensusDivisions class documentation</a></li>
<li><a href="ClimateDivisions.html">CPC::Regions::ClimateDivisions class documentation</a></li>
<li><a href="ForecastDivisions.html">CPC::Regions::ForecastDivisions class documentation</a></li>
<li><a href="States.html">CPC::Regions::States class documentation</a></li>
<li><a href="Stations.html">CPC::Regions::Stations class documentation</a></li>
</ul>

=end html

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

