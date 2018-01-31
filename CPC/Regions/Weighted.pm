#!/usr/bin/perl

package CPC::Regions::Weighted;

=pod

=head1 NAME

Weighted - Construct CPC::Regions objects using weighted averages of subregional data

=head1 SYNOPSIS

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use CPC::Regions::Weighted;
 use CPC::Regions::CensusDivisions;
 use CPC::Regions::ClimateDivisions;
 use CPC::Regions::ForecastDivisions;
 use CPC::Regions::States;
 use CPC::Regions::StatesCONUS;
 
 my $weightingTool = CPC::Regions::Weighted->new();

=head1 DESCRIPTION

U.S. Census divisions are comprised of states.  States are comprised of climate divisions.  Due to 
these relationships, it is possible to derive data for one series of regions from data on regions 
that comprise the larger ones.  A straight average of the subregions is not very useful, however, 
so this method provides a means to construct objects or data values using weighted averages.

Weighting factors can vary depending on the goals of the dataset constructor.  Utilizing land area 
as weighting factors would produce areal averaged results, while weighting based on population 
would produce data more meaningful for resource usage applications.  The methods in this package 
can handle any weighting factors, so long as they are numeric and do not sum to zero.

=head3 Computing a weighted average

Given a region comprised of N subregions, data on the subregions (X1, X2, ..., XN), and weighting 
factors on the subregions (W1, W2, ..., WN), where the weighting factors can be subregional 
populations, land area, or any other form of weighting data, the weighted average value, V, for 
the region is:

 V = F1*X1 + F2*X2 + ... + FN*XN

where F(i) = W(i) / (W1 + W2 + ... + WN)

This technique is utilized in all methods provided by this package.  WARNING: Since

W1 + W2 + ... + WN = 0

would create badness, the methods set all values F(i) to zero in this case, which would result in 
zero data values being returned (which is what you'd expect if all your weights added to zero!)

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
use CPC::Regions::ForecastDivisions;
use CPC::Regions::States;
use CPC::Regions::StatesCONUS;

=pod

=head1 METHODS

The CPC::Regions::Weighted constructor returns objects to the calling program.  Object methods take 
CPC::Regions inheritor type objects with numeric data and weighting factors as arguments and can return 
new CPC::Regions inheritor type objects or a scalar value representing the weighted average of the data.

=cut

=pod

=head3 new

 my $weighingTool = CPC::Regions::Weighted->new();

Returns a CPC::Regions::Weighted object to the calling program.  Since the object does not store unique 
data, there need only be one CPC::Regions::Weighted object constructed in the calling program.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless($self,$class);
	return $self;
}

=pod

=head3 GetStatesCONUSFromClimateDivisions

 $weightingTool->GetStatesCONUSFromClimateDivisions($data,$weights);

Given two CPC::Regions::ClimateDivisions objects, one containing numeric data and the other containing 
a set of numeric and complete weighting factors, returns a CPC::Regions::StatesCONUS object with data 
set to the weighted average of the climate divisions.

=cut

sub GetStatesCONUSFromClimateDivisions {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetStatesCONUSFromClimateDivisions';

	# --- Arguments ---

	croak "$class->$method: Insufficient arguments - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Arguments must be CPC::Regions::ClimateDivisions objects - exception thrown" unless(blessed $data and blessed $weights and $data->isa('CPC::Regions::ClimateDivisions') and $weights->isa('CPC::Regions::ClimateDivisions'));
	croak "$class->$method: Argument objects must have numeric data - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: WEIGHTS argument cannot have missing data - exception thrown" unless($weights->IsComplete);

	# --- Compute weighting factors ---

	my $conusIDs  = CPC::Regions::ClimateDivisions->newStatesIDs();
	my $conusSums = CPC::Regions::StatesCONUS->new();
	$conusSums->Initialize(0.0);
	$conusSums->SetMissing(-9999);
	my $weightsFactors = CPC::Regions::ClimateDivisions->new();
	$weightsFactors->SetMissing(-9999);

	foreach my $stcd (CPC::Regions::ClimateDivisions->new()->GetIDs) {
		my $st  = $conusIDs->GetData($stcd);
		my $wt  = $weights->GetData($stcd);
		my $sum = $conusSums->GetData($st);
		$conusSums->SetData($st,$sum+$wt);
	}

	foreach my $stcd (CPC::Regions::ClimateDivisions->new()->GetIDs) {
		my $st  = $conusIDs->GetData($stcd);
		my $wt  = $weights->GetData($stcd);
		my $sum = $conusSums->GetData($st);
		if($sum == 0) { $weightsFactors->SetData($stcd,0);        }
		else          { $weightsFactors->SetData($stcd,$wt/$sum); }
	}

	# --- Compute weighted averages ---

	my $weightedData = $data * $weightsFactors;
	my $result       = CPC::Regions::StatesCONUS->new();
	$result->SetMissing(-9999);
	$result->Initialize(0.0);

	STCD: foreach my $stcd (CPC::Regions::ClimateDivisions->new()->GetIDs) {
		next STCD if($weightsFactors->GetData($stcd) == 0);
		my $st      = $conusIDs->GetData($stcd);
		my $missing = $result->GetMissing;

		if($weightedData->IsMissing($stcd)) {
			$result->SetData($st,$missing);
		}
		elsif($result->NotMissing($st)) {
			my $val = $weightedData->GetData($stcd);
			my $sum = $result->GetData($st);
			$result->SetData($st,$sum+$val);
		}

	}  # :STCD

	# --- Return object ---

	carp "$class->$method: Return object has missing data" unless($result->IsComplete);
	return $result;
}

=pod

=head3 GetCensusDivisionsFromStatesCONUS

 $weightingTool->GetCensusDivisionsFromStatesCONUS($data,$weights);

Given two CPC::Regions::StatesCONUS objects, one containing numeric data and the other containing
a set of numeric and complete weighting factors, returns a CPC::Regions::CensusDivisions object with data
set to the weighted average of the climate divisions.

=cut

sub GetCensusDivisionsFromStatesCONUS {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetCensusDivisionsFromStatesCONUS';

	# --- Arguments ---

	croak "$class->$method: Insufficient arguments - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Arguments must be CPC::Regions::StatesCONUS objects - exception thrown" unless(blessed $data and blessed $weights and $data->isa('CPC::Regions::StatesCONUS') and $weights->isa('CPC::Regions::StatesCONUS'));
	croak "$class->$method: Argument objects must have numeric data - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: WEIGHTS argument cannot have missing data - exception thrown" unless($weights->IsComplete);

	# --- Compute weighting factors ---

	my $censusIDs  = CPC::Regions::StatesCONUS->newCensusDivisionsIDs();
	my $censusSums = CPC::Regions::CensusDivisions->new();
	$censusSums->Initialize(0.0);
	$censusSums->SetMissing(-9999);
	my $weightsFactors = CPC::Regions::StatesCONUS->new();
	$weightsFactors->SetMissing(-9999);

	foreach my $st (CPC::Regions::StatesCONUS->new()->GetIDs) {
		my $cd  = $censusIDs->GetData($st);
		my $wt  = $weights->GetData($st);
		my $sum = $censusSums->GetData($cd);
		$censusSums->SetData($cd,$sum+$wt);
	}

	foreach my $st (CPC::Regions::StatesCONUS->new()->GetIDs) {
		my $cd  = $censusIDs->GetData($st);
		my $wt  = $weights->GetData($st);
		my $sum = $censusSums->GetData($cd);
		if($sum == 0) { $weightsFactors->SetData($st,0);        }
		else          { $weightsFactors->SetData($st,$wt/$sum); }
	}

	# --- Compute weighted averages ---

	my $weightedData = $data * $weightsFactors;
	my $result       = CPC::Regions::CensusDivisions->new();
	$result->SetMissing(-9999);
	$result->Initialize(0.0);

	ST: foreach my $st (CPC::Regions::StatesCONUS->new()->GetIDs) {
		next ST if($weightsFactors->GetData($st) == 0);
		my $cd      = $censusIDs->GetData($st);
		my $missing = $result->GetMissing;

		if($weightedData->IsMissing($st)) {
			$result->SetData($cd,$missing);
		}
		elsif($result->NotMissing($cd)) {
			my $val = $weightedData->GetData($st);
			my $sum = $result->GetData($cd);
			$result->SetData($cd,$sum+$val);
		}

	}  # :ST

        # --- Return object ---

	carp "$class->$method: Return object has missing data" unless($result->IsComplete);
	return $result;
}

=pod

=head3 GetWeightedAverage

 my $avgerageValue = $weightingTool->GetWeightedAverage($data,$weights);

Given two CPC::Regions inheritor type objects of the same type, one containing numeric data and the 
other containing a set of numeric and complete weighting factors, returns the weighted average 
of the data as a numeric scalar value.

If any argument data values are missing, the return value will be whatever value is returned by 
the data argument's GetMissing method.

=cut

sub GetWeightedAverage {
	my $self   = shift;
	my $class  = blessed($self);
	my $method = 'GetWeightedAverage';

	# --- Arguments ---

	croak "$class->$method: Insufficient arguments - exception thrown" unless(@_ >= 2);
	my $data    = shift;
	my $weights = shift;
	croak "$class->$method: Arguments must be CPC::Regions type inheritor objects - exception thrown" unless(blessed $data and blessed $weights and $data->isa('CPC::Regions') and $weights->isa('CPC::Regions'));
	croak "$class->$method: Argument CPC::Regions inheritors must be the same time - exception thrown" unless($data->GetType eq $weights->GetType);
	croak "$class->$method: Argument objects must have numeric data - exception thrown" unless($data->IsNumeric and $weights->IsNumeric);
	croak "$class->$method: WEIGHTS argument cannot have missing data - exception thrown" unless($weights->IsComplete);

	# --- Compute weights factors ---

	my $sum            = 0;
	my $weightsFactors = blessed($weights)->new($weights->GetType());

	foreach my $region ($weights->GetIDs) {
		$sum = $sum + $weights->GetData($region);
	}

	foreach my $region ($weights->GetIDs) {
		my $wt = $weights->GetData($region);
		if($sum == 0) { $weightsFactors->SetData($region,0);        }
		else          { $weightsFactors->SetData($region,$wt/$sum); }
	}

	# --- Compute weighted average ---

	my $result       = 0;
	my $weightedData = $data * $weightsFactors;
	my $missing      = $data->GetMissing;

	REGION: foreach my $region ($weightedData->GetIDs) {
		next REGION if $weightsFactors->GetData($region) == 0;
		if($weightedData->IsMissing($region)) { return $missing; }
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
<li><a href="StatesCONUS.html">CPC::Regions::StatesCONUS class documentation</a></li>
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

