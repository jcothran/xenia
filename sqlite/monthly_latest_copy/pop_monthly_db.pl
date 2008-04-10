#!/usr/bin/perl
#pop_archive_db.pl

use strict;
use LWP::Simple;

##config

my $sqlite_path = '/usr/bin/sqlite3-3.5.4.bin';

my $latest_db = 'latest.db';

#latest sql feed
my $source_url = 'http://carocoops.org/obskml/feeds/xenia/archive/latest.sql';
getstore("$source_url",'./latest.sql') or die "Couldn't get $source_url \n";

##

my $year_month = `date '+%Y_%m'`; 
chomp($year_month);
#print $year_month."\n";
my $db_name = 'secoora_'.$year_month.'.db';

my $previous_year_month = `date --date='1 month ago' '+%Y_%m'`; 
chomp($previous_year_month);
#print $previous_year_month."\n";
my $previous_db_name = 'secoora_'.$previous_year_month.'.db';

if (!(-e "$db_name")) {
	#print "file $db_name does not exist\n";
	`cp $previous_db_name $db_name`; 

	`$sqlite_path $db_name 'delete from multi_obs;'	`;
	`$sqlite_path $db_name 'vacuum;'	`;

	`$sqlite_path $previous_db_name 'vacuum;'	`;
}

#print "process sql against file db\n";

#populate monthly archival db
`$sqlite_path $db_name < latest.sql`;

#go ahead and populate latest.db also
`$sqlite_path $latest_db < latest.sql`;

exit 0;

