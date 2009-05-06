#!/usr/bin/perl

#this script converts a combined org/platform spreadsheet into two separate
#TSV spreadsheets org, platform with the correct field mappings for load/import
#by the google spreadsheet SecooraSensorInventory_v1.0

use strict;

my $line_count = 0;

my $line_record;
open (INPUT_FILE, "./si.csv");
open (FILE_PLATFORM,">si_platform.tsv");

my %organization;

foreach $line_record (<INPUT_FILE>) {
	$line_count++;
	my @element = split(/,/,$line_record);
	#my $converted_line = "$element[6] $element[5]\t\t$element[3]<br/>$element[8]\n";

	if ($element[1] eq '') { $element[1] = $element[0]; }
	$organization{$element[1]} = $element[0];

	if ($element[4] eq 'Y') { $element[4] = 'near real-time'; }
	if ($element[4] eq 'N') { $element[4] = 'delayed'; }

        my $line_platform = "$element[3]\t$element[1]\t \t \t$element[8]\t$element[2]\t \t \t \t$element[6]\t$element[5]\t \t \t$element[4]\n";	
	print FILE_PLATFORM $line_platform;
}

#id	platformType	platformSensorType	URL	description	imageURL	statusType	statusDescription	longitude	latitude	locationWKT	locationDescription	reportType	reportInterval	reportUnitsType	reportDescription	timeSpanList	timeStart	timeEnd	describeSensorURL										



close(INPUT_FILE);
close(FILE_PLATFORM);

open (FILE_ORG,">si_organization.tsv");

foreach my $org (keys %organization) {
	my $line_org = "$org\t \t \t \t$organization{$org}\n";
	print FILE_ORG $line_org;
}

close(FILE_ORG);

exit 0;
