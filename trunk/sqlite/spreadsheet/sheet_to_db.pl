#!/usr/bin/perl

#this script creates the necessary initial database table structure based on the
#header lines of the associated spreadsheet file referenced

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

open (FILE,"./registry.csv");

my $row_count = 0;
foreach my $row (<FILE>) {
        $row_count++;

	#second registry row(line after header) used for creating tables
        if ($row_count == 2) {
		my @element = (split(',',$row));
		$sheet_key = $element[0];
		last;
	}
}

#print $sheet_key."\n";

#################
#create table sql

my $all_tables = '';

foreach my $sheet (keys %gid) {
print $sheet."\n";
my $sheet_url = "http://spreadsheets.google.com/pub?key=$sheet_key&output=csv&gid=$gid{$sheet}";

my $retval = getstore($sheet_url,"./$sheet.csv");
die "Couldn't get $sheet_url" unless defined $retval;

open (FILE,"./$sheet.csv");

my $row_count = 0;
foreach my $row (<FILE>) {
	$row_count++;

	if ($row_count == 1) {
		#my $table = "create table $sheet (\nrowId integer PRIMARY KEY,\nsheetKey text,\n";
		my $table = "create table $sheet (\nsheetKey text,\n";
		foreach my $element (split(',',$row)) {
			$table .= "$element text,\n";
		}
		chop($table);
		chop($table);
		$table .= ");\n";
		$all_tables .= $table;
		print $table."\n";
		last;
	}
} #foreach $row

close (FILE)
} #foreach $sheet

open (FILE_TABLES_SQL,">./create_tables.sql");
print FILE_TABLES_SQL $all_tables;
close (FILE_TABLES_SQL);

`$path_sqlite $dbname < create_tables.sql`;

exit 0;

