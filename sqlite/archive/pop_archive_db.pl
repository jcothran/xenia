#!/usr/bin/perl
#pop_archive_db.pl
#populates latest and weekly/monthly archival db's
 
use strict;
use LWP::Simple;

##config

#note this script assumes folders ./weekly and ./monthly for storing weekly and monthly archive db's

my $path_batch_insert = 'perl /var/www/cgi-bin/microwfs/batch_insert.pl';
my $path_sqlite = '/usr/bin/sqlite3-3.5.4.bin';

my $latest_db = 'latest.db';

#latest sql feed
my $source_url = 'http://carocoops.org/secoora_data/archival/all_obs/sqlite/recent/latest.sql';
getstore("$source_url",'./latest.sql') or die "Couldn't get $source_url \n";

#latest

#populate latest.db 
`$path_batch_insert $latest_db latest.sql`;

#weekly

my $year_week = `date '+%Y_%V'`; 
chomp($year_week);
#print $year_week."\n";
my $db_name_weekly = 'secoora_weekly_'.$year_week.'.db';

my $previous_year_week = `date --date='1 week ago' '+%Y_%V'`; 
chomp($previous_year_week);
#print $previous_year_week."\n";
my $previous_db_name_weekly = 'secoora_weekly_'.$previous_year_week.'.db';

if (!(-e "./weekly/$db_name_weekly")) {
	#print "file $db_name_weekly does not exist\n";
	`cp ./weekly/$previous_db_name_weekly ./weekly/$db_name_weekly`; 

	`$path_sqlite ./weekly/$db_name_weekly 'delete from multi_obs;'	`;
	`$path_sqlite ./weekly/$db_name_weekly 'vacuum;' `;

	`$path_sqlite ./weekly/$previous_db_name_weekly 'vacuum;' `;
}

#populate weekly archival db
`$path_batch_insert ./weekly/$db_name_weekly latest.sql`;

#monthly

my $year_month = `date '+%Y_%m'`; 
chomp($year_month);
#print $year_month."\n";
my $db_name_monthly = 'secoora_monthly_'.$year_month.'.db';

my $previous_year_month = `date --date='1 month ago' '+%Y_%m'`; 
chomp($previous_year_month);
#print $previous_year_month."\n";
my $previous_db_name_monthly = 'secoora_monthly_'.$previous_year_month.'.db';

if (!(-e "./monthly/$db_name_monthly")) {
	#print "file $db_name_monthly does not exist\n";
	`cp ./monthly/$previous_db_name_monthly ./monthly/$db_name_monthly`; 

	`$path_sqlite ./monthly/$db_name_monthly 'delete from multi_obs;'	`;
	`$path_sqlite ./monthly/$db_name_monthly 'vacuum;' `;

	`$path_sqlite ./monthly/$previous_db_name_monthly 'vacuum;' `;
}

#populate monthly archival db
`$path_batch_insert ./monthly/$db_name_monthly latest.sql`;

exit 0;

