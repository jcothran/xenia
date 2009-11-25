#! /usr/bin/perl -w

use strict;
use warnings;
use LWP::Simple;
use Math::Trig qw(great_circle_distance great_circle_direction rad2deg deg2rad );
use Math::Complex;
use Date::Parse;
use Getopt::Long;

my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "BBOX=s",
            "DestDir=s" );

if( length( %CommandLineOptions ) < 2 )
{
  die( "Command Line options:\n --BBOX is the lat/longs of the bounding box.\n--DestDir is the destination directory for the ascii data file.\n" );
}
my @bbox = split( ',', $CommandLineOptions{"BBOX"} );
if( @bbox != 4 )
{
  die( "Bounding box does not have all the coordinates required.")
}
my $dest_dir = $CommandLineOptions{"DestDir"};

# Create URL AOML base + data paramters
#my $aoml_url_base='http://www.aoml.noaa.gov/cgi-bin/trinanes/datosxbt.cgi?latN=46&latS=10&lonW=-100&lonE=-40';
my $aoml_url_base="http://www.aoml.noaa.gov/cgi-bin/trinanes/datosxbt.cgi?latN=$bbox[2]&latS=$bbox[0]&lonW=$bbox[3]&lonE=$bbox[1]";
my $aoml_arguments='&type=2&id=&tipo=1';
#my $dest_dir = '/home/jcleary/drifter/';

#set time arguments for today
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime time;
my $use_year = $year + 1900;
my $use_month = $mon+1;
my $use_day = $mday;

#set time variables for yesterday
my ($ysec,$ymin,$yhour,$ymday,$ymon,$yyear,$ywday,$yyday,$yisdst) = gmtime(time - 24 * 60 * 60);
my $y_use_year = $yyear + 1900;
my $y_use_month = $ymon+1;
my $y_use_day = $ymday;

#combine into data request URL
#using date range of yesterday ~ today
my $url = $aoml_url_base.'&year='.$y_use_year.'&month='.$y_use_month.'&day='.$y_use_day.'&year1='.$use_year.'&month1='.$use_month.'&day1='.$use_day.$aoml_arguments;

#Hit URL and save html to file
my $html_target = $dest_dir.'drifter.html';
getstore($url,$html_target);

#find data link in HTML returned from above URL
#something like <a href="http://www.aoml.noaa.gov/phod/trinanes/tmp/dxbt1158871175.dat">
open (HTML, $html_target);
my @h = readline HTML;
my @url_line = grep(/http:\/\/www.aoml.noaa.gov\/phod\/trinanes\/tmp\/dxbt.+\.dat/, @h);
close HTML;

#cut out CSV link URL only
$url_line[0] =~ m/<a href="(http:\/\/www.aoml.noaa.gov\/phod\/trinanes\/tmp\/dxbt.+\.dat)?"/;
my $csv_url = $1;

# Save CSV to file 
my $csv_target = $dest_dir.'drifter.dat';
getstore($csv_url,$csv_target);


# format drifters.txt to HM format (below)
# FHD_ID Date      Time        Lat        Lon         Dist        DelTime   Speed   Heading
#                  UTC                                 KM          HOURS     M/S      deg

# print header rows
open (TAB, "> ".$dest_dir."aoml_drifters.txt");
print TAB "#ID\tDate\t\tTime\tLat\tLon\tDist\tDelTime\tSpeed\tHeading\tWaterTemp\tWindDir(/10)\tWindSpeed(m/s)\tPressure(mbar)\n";
print TAB "#\t\t\tUTC\t\t\tKM\tHOURS\tM/S\tdeg\n";


# parse AOML format 

open (DAT, $dest_dir."drifter.dat");
my @dat = <DAT>; 
close (DAT);

my $i = 0;
my $dat;
foreach $dat(@dat)
{

	# Lat       Lon      ID        Date        WaterTemp WindDir(/10) WindSpeed(m/s) Pressure(mBar)

	# parse line as prior obs b/c ordering is oldest to newest
	my($lat, $lon, $id, $timestamp, $temp, $wind_dir, $wind_speed, $pressure) = split(/\t/, $dat);
	
	# parse next line as observation to evaluate
        # error msg on last line of dat file since no next line exists
	my($lat2, $lon2, $id2, $timestamp2, $temp2, $wind_dir2, $wind_speed2, $pressure2) = split(/\t/, $dat[$i+1]);

	#skip header rows in input DAT file
	if ($lat =~ /^-?\d+\.?\d*$/ && $lat2 =~ /^-?\d+\.?\d*$/)
	{
		# if ID is the same, then calc distance and time diff -> speed and bearing if D and TD are sufficiently removed
		if ($id eq $id2)
		{
			sub NESW { deg2rad($_[0]), deg2rad(90 - $_[1]) }
			my @L = NESW($lon, $lat);
			my @T = NESW($lon2, $lat2);
			my $dist_km = great_circle_distance(@L, @T, 6378); # About 9600 km.
      #my $dist_km = great_circle_distance(@L, @T);
			$dist_km = sprintf("%.1f",$dist_km);
			my $time_dif = str2time($timestamp2)-str2time($timestamp);
      my $time_dif_hours = $time_dif/3600;
      $time_dif_hours = sprintf("%.2f",$time_dif_hours);

			# only run bearing and speed calcs if the drifter has actually moved significantly: dist_km > .5 km
			# OR not too close in time: time_dif_hours > 0.5 hrs
			my ($bearing, $speed);

			if ($dist_km > .1 && $time_dif_hours > .25)
			{
        # bearing in radians
        my $rad = great_circle_direction(@L, @T);			
                          
        # convert bearing into degrees
        $bearing  = rad2deg($rad);
        if( index( $bearing, 'i' ) != -1 )
        {
          my $i = 0;
        }
        $bearing = sprintf("%.1f",$bearing);
                          
        # calcuate speed in m/s
        $speed = ($dist_km*1000)/$time_dif;
        $speed = sprintf("%.2f",$speed);
 
			}
			else
			{
        $bearing = "-NaN";	
        $speed = 0.0;
			}
			
			# split up timestamp into date and time
			my($date2, $time2) = split(/ /, $timestamp2);
			# replace - with / in date	  
			$date2 =~ s/-/\//g;
		
			# print to open file
			print TAB $id2."\t".$date2."\t".$time2."\t".$lat2."\t".$lon2."\t".$dist_km."\t".$time_dif_hours."\t".$speed."\t".$bearing."\t".$temp2."\t\t".$wind_dir2."\t\t".$wind_speed2."\t\t".$pressure2;
		}
	  
		else
		{
               	#debug to be sure ID splitting is working
		#print $id." is not equal to ".$id2."\n";
		}	
	}
	else
	{
	print "Processing non-data row\n";
	}
		
	$i++;
}

close (TAB);

#File cleanup
if (-s $csv_target)
    {
    print "Data collected!\n";
    }
else
    {
     print "No CSV returned by AOML server\n";
    }

system ("rm ".$dest_dir."drifter.html");                                                                                                            
system ("rm ".$dest_dir."drifter.dat");
#system ("mv ".$dest_dir."aoml_drifters.txt /var/www/html/drifters/");
exit 0;


