#!/usr/bin/perl

use strict;

# $time_offset = number of hours older than current time to assign time_start ; this is working on the idea that new data is arriving into the database all the time, but after a certain number of hours we can assume that we have collected all the data we are going to collect 
#my $time_offset = 336; #336 = 2 weeks
my $time_offset = 6; 

# $time_interval = number of hours between time_start and time_stop ; should be equal to the time interval between when the cron job which calls this process is run, so if 168 = 1 week, then the cron should also be run once a week
#my $time_interval = 168; #168 = 1 week
my $time_interval = 1;

#################################################

#3600 sec/hour

my $sec_now = `date '+%s'`;
chomp($sec_now);

my $sec_time_start = $sec_now - $time_offset*3600 - $time_interval*3600;
my $sec_time_stop = $sec_now - $time_offset*3600;

my $time_start = `date -d '1970-01-01 $sec_time_start seconds' +"%Y_%m_%d_%H"`;
chomp($time_start);

my $time_stop = `date -d '1970-01-01 $sec_time_stop seconds' +"%Y_%m_%d_%H"`;
chomp($time_stop);

#uncomment for manual testing purposes
#my $time_start = '2007_01_01_00-05';
#my $time_stop = '2007_02_01_00-05';

print $time_start."\n";
print $time_stop."\n";

`perl process_copy.pl environment_copy.xml create $time_start $time_stop`;

#the below create step is commented out for now since there is no local archive table that I'm populating or testing against
#`perl process_copy.pl environment_copy.xml copy $time_start $time_stop`;

#the below delete step is commented out initially, uncomment when confident that the earlier steps and copy file creation is working
#`perl process_copy.pl environment_copy.xml delete $time_start $time_stop`;

#may want to include database commands for 'vacuum analyze' or 'reindex' here as needed

exit 0;

