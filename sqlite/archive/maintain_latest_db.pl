#!/usr/bin/perl
#maintain_latest_db.pl

use strict;

##config
my $sqlite_path = '/usr/bin/sqlite3-3.5.4.bin';

my $latest_db = 'latest.db';
##

my $date_cutoff = `date --date='3 days ago' +%Y-%m-%dT%H:%M:%S`;
chomp($date_cutoff);
#$date_cutoff = '2008-01-18T13:00:00'; #manual set/debug
#print $date_cutoff;

open(SQL_OUT,">maintain.sql");
print SQL_OUT "delete from multi_obs where m_date < '$date_cutoff';\n";
print SQL_OUT "vacuum;";
close(SQL_OUT);

`$sqlite_path $latest_db < maintain.sql`;

exit 0;

