#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(sum);

# Warm-season turf grass watering coefficients for Austin, TX
my @coeffByMonth = (0.1, 0.2, 0.3, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.3, 0.1);

# Quality factors
my %qualityFactors = ( 
    "No stress" => 1.0,
    "Low stress" => 0.8,
    "Normal Stress" => 0.6,
    "High Stress" => 0.5,
    "V. High Stress" => 0.4
);

# Choose coeff
my $month = (localtime)[4];
my $turfCoeff = $coeffByMonth[$month];
print "Using turf coefficient: $turfCoeff\n\n";

# Get combined ETo (in.) for the last 7 days
my @weatherData = `tail -n 7 ~/Dropbox/Public/db/weather.db`;
print "Using weather data:\n@weatherData\n";
my @etoSamples = ();
foreach my $line (@weatherData) {
    my @samples = split ',',$line;
    push @etoSamples, $samples[0];
}

print "ETo (in.) : @etoSamples\n";
my $etoTotal = sum(@etoSamples);
print "Eto (in.) total : $etoTotal\n";

# Get combined rainfall (in.) for the last 7 days
my @rainfallData = `tail -n 7 ~/Dropbox/Public/db/rainfall.db`;
print "Using rainfall data:\n@rainfallData\n";
my @rainfallSamples = ();
foreach my $line (@rainfallData) {
    my @samples = split ',',$line;
    push @rainfallSamples, $samples[2];
}

print "Rainfall (in.) : @rainfallSamples\n";
my $rainfallTotal = sum(@rainfallSamples);
print "Rainfall (in.) total : $rainfallTotal\n\n";

# ETo x Tc x Qf = turf water requirement 
my %wateringRequirements = ();
foreach my $qualityFactor (keys %qualityFactors) {
    $wateringRequirements{$qualityFactor} = $etoTotal * $turfCoeff * $qualityFactors{$qualityFactor};
}

# watering amounts
my %wateringAmounts = ();
foreach my $qualityFactor (keys %qualityFactors) {
    $wateringAmounts{$qualityFactor} = $wateringRequirements{$qualityFactor} - $rainfallTotal;
}

print "Quality Factor\t Watering Req. (in.)\tWater Needed (in.)\n";
foreach my $qualityFactor (keys %qualityFactors) {
    print "$qualityFactor\t $wateringRequirements{$qualityFactor}\t\t\t$wateringAmounts{$qualityFactor}\n";
}
