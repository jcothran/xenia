#!/usr/bin/perl

#this script populates/refreshes the local sqlite database with the
#latest google spreadsheet values.  Spreadsheets are located via the google
#spreadsheet registry file.

use strict;
use LWP::Simple;

########################
#CONFIG BEGIN

my $registry_key = 'rZGUM4s620-UQ_OQ1AI6R_g';

#FIX - dynamically populate sheet hash from initial registry?
my %gid = ('organization' => 0,
           'platform' => 1);

my $path_sqlite = '/usr/bin/sqlite3-3.6.1.bin';
my $dbname = 'si.db';

#CONFIG END

########################
my $sheet_key;

#get sheet from registry
my $sheet_url = "http://spreadsheets.google.com/pub?key=$registry_key&output=csv&gid=0";
my $retval = getstore($sheet_url,"./registry.csv");
die "Couldn't get $sheet_url" unless defined $retval;

open (FILE_REGISTRY,"./registry.csv");

my $row_count_registry = 0;
foreach my $row (<FILE_REGISTRY>) {
$row_count_registry++;

if ($row_count_registry == 1) { next; } #skip header line
my @element = (split(',',$row));
$sheet_key = $element[0];

####

foreach my $sheet (keys %gid) {
print $sheet."\n";
my $sheet_url = "http://spreadsheets.google.com/pub?key=$sheet_key&output=csv&gid=$gid{$sheet}";

my $retval = getstore($sheet_url,"./$sheet.csv");
die "Couldn't get $sheet_url" unless defined $retval;


open (FILE_SHEET,"./$sheet.csv");
open (FILE_SHEET_OUT,">./$sheet\_out.csv");

my $row_count_sheet = 0;
my @element = ();
my ($total_column_size,$this_column_size);
foreach my $row (<FILE_SHEET>) {
	$row_count_sheet++;

	#don't include empty or google formula rows
	if ( ($row =~ m/^\s/ ) || ($row =~ m/^\[/ ) ) { next;}

	chop($row);
	
	if ($row_count_sheet == 1) {
		@element = (split(',',$row));
		$total_column_size = @element;
		#print "$row\n";
		#print "total_column_size = $total_column_size\n";
		next;
	}
	#print $row_count_sheet." ".$row."\n";

	#google spreadsheet doesn't supply missing null commas at end of file
	#using TSV instead of CSV because sqlite mistakes comma-within-double-quote convention on import
        my @element = ();
	#regex magic - borrowed from elsewhere - handling commas within double quotes
        @element = split /,(?!(?:[^",]|[^"],[^"])+")/, $row;

	my $tab_row = '';
        foreach my $field (@element) { $tab_row .= $field."\t"; }
	chop($tab_row);

	$this_column_size = @element;
	#print $this_column_size."\n";
	for(my $i = 0; $i < ($total_column_size - $this_column_size); $i++) {
		$tab_row .= "\tx";
	}

	#$row =~ s/\"/\'/g;
	$tab_row =~ s/\[*\]//g;
	print FILE_SHEET_OUT "$sheet_key\t$tab_row\n";
	
} #foreach $row

close (FILE_SHEET);
close (FILE_SHEET_OUT);

open (FILE_SQL,">./temp.sql");
print FILE_SQL ".separator \"\t\"\n.import $sheet\_out.csv $sheet";
close (FILE_SQL);
`$path_sqlite $dbname < temp.sql`;

} #foreach $sheet
} #foreach $registry
close (FILE_REGISTRY);

exit 0;

