#!/usr/bin/perl
use strict;

my ($now_year,$now_month,$now_day,$now_hour,$now_minute);

#################################
#convert file data to arrays

my @east_current = ();
my @north_current = ();

my @east_current_accuracy = ();
my @north_current_accuracy = ();

open (RADAR_FILE, "latest.txt");

my $header_lines = 11;
my $header_line_count = 0;
foreach my $line (<RADAR_FILE>) {
	$header_line_count++;

	if ($header_line_count == 2) {
		my ($junk,$now_date,$now_time) = split(/\s+/,$line);
		#print "$now_date\n";
		my $temp_date_string = substr($now_date,3,3).' '.substr($now_date,0,2).' '.substr($now_date,7,4); 
		my $temp_date = `date +%Y%m%d -d "$temp_date_string"`;
		#print "$temp_date_string $temp_date \n";

		$now_year = substr($temp_date,0,4); 
		$now_month = substr($temp_date,4,2); 
		$now_day = substr($temp_date,6,2); 

		$now_hour = substr($now_time,0,2); 
		$now_minute = substr($now_time,3,2);
		#round 53 minutes, etc up to '00' for Chapel Hill script which is dependent on the 00 minute mark 
		if ($now_minute > 31) {

			#print "$now_year $now_month $now_day $now_hour $now_minute \n";
			my $num_sec = `date --date='$now_year-$now_month-$now_day $now_hour:00 UTC' +%s`;	
			#$num_sec = $num_sec + 3600;
			#print $num_sec."\n";
			#JTC 2009-10-29 fix for daylight savings hour fluctuation
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
			my $zone = '';
			if ($isdst == 0) { $num_sec += 3600; }
			#if ($isdst == 0) { $zone = 'EST'; } else { $zone = 'EDT'; }
			#if ($isdst == 0) { $num_sec += 5*60*60; } else { $num_sec += 4*60*60; }
			#my $new_date = `date -d '1970-01-01 $num_sec sec $zone' +"%Y %m %d %H %M"`;		
			my $new_date = `date -d '1970-01-01 $num_sec sec' +"%Y %m %d %H %M"`;		
			#print $new_date;
			($now_year,$now_month,$now_day,$now_hour,$now_minute) = split('\s+',$new_date);
			#print "$now_year $now_month $now_day $now_hour $now_minute \n";
		}
	}

	if ($header_line_count < $header_lines) { next; }
	my ($junk,$x_pos,$y_pos,$u_current,$v_current,$k,$u_current_accuracy,$v_current_accuracy) = split(/\s+/,$line);

	#get rid of lines which are not based on input from both radials
	if ($k != 0) { next; }

	#print $line."\n";
	#print "$x_pos $y_pos $u_current $v_current\n";

	#file values are in m/s so convert these to cm/s by multiplying by 100

	$east_current[$x_pos][$y_pos] = $u_current*100;
	$north_current[$x_pos][$y_pos] = $v_current*100;

	$east_current_accuracy[$x_pos][$y_pos] = $u_current_accuracy*100;
	$north_current_accuracy[$x_pos][$y_pos] = $v_current_accuracy*100;
}
close (RADAR_FILE);

############################################################
#convert arrays into strings

my ($nc_east_current,$nc_north_current,$nc_east_current_accuracy,$nc_north_current_accuracy);

my $grid_size = 250;

for (my $i = 0; $i < 250; $i++) {
	for (my $j = 0; $j < 250; $j++) {

                #only forward current data where > error
                #corrected - only forward where abs(currents) < 150 cm/s

                #print "$i $j $east_current[$i][$j] \n";
                if ($east_current[$i][$j] eq "") { $nc_east_current .= "-999.9," ; }
                #elsif (abs($east_current[$i][$j])*1.5 > abs($east_current_accuracy[$i][$j])) { $nc_east_current .= $east_current[$i][$j]."," ; }
                elsif (abs($east_current[$i][$j]) < 150) { $nc_east_current .= $east_current[$i][$j]."," ; }
                else { $nc_east_current .= "-999.9," ; }

                #print "$i $j $north_current[$i][$j] \n";
                if ($north_current[$i][$j] eq "") { $nc_north_current .= "-999.9," ; }
                #elsif (abs($north_current[$i][$j])*1.5 > abs($north_current_accuracy[$i][$j])) { $nc_north_current .= $north_current[$i][$j]."," ; }
                elsif (abs($north_current[$i][$j]) < 150) { print "ok\n"; $nc_north_current .= $north_current[$i][$j]."," ; }
                else { $nc_north_current .= "-999.9," ; }

                #print "$i $j $east_current_accuracy[$i][$j] \n";
                if ($east_current_accuracy[$i][$j]) { $nc_east_current_accuracy .= $east_current_accuracy[$i][$j]."," ; }
                else { $nc_east_current_accuracy .= "-999.9," ; }

                #print "$i $j $north_current_accuracy[$i][$j] \n";
                if ($north_current_accuracy[$i][$j]) { $nc_north_current_accuracy .= $north_current_accuracy[$i][$j]."," ; }
                else { $nc_north_current_accuracy .= "-999.9," ; }
	}
}
$nc_east_current = substr($nc_east_current,0,-1);
$nc_north_current = substr($nc_north_current,0,-1);
$nc_east_current_accuracy = substr($nc_east_current_accuracy,0,-1);
$nc_north_current_accuracy = substr($nc_north_current_accuracy,0,-1);

############################################################
#testing
=comment
my $lat;
for (my $i = 0; $i < 150; $i++) {
	$lat .= "$i,";
}
$lat = substr($lat,0,-1);
$content =~ s/<LAT>/$lat/g;
$content =~ s/<LONG>/$lat/g;

my $current;
for (my $i = 0; $i < 1600; $i++) {
	my $value = $i*0.1;
	print "$value\n";
	$current = $current."$value,";
}
$current = substr($current,0,-1);
=cut

############################################################
#get time info, substitute strings into template, generate netcdf

my $time_sec = `date -u --date '$now_year-$now_month-$now_day $now_hour:$now_minute:00' '+%s'`;
chomp($time_sec);
#print "$date_now_year-$date_now_month_day $date_now_hour:$date_now_minute:00\n";
my $time_string = `date --date '$now_year-$now_month-$now_day $now_hour:$now_minute:00' '+%Y-%m-%d %H:%M:00'`;
chomp($time_string);

my $content = `cat template_radar.txt`;

$content =~ s/<TIME_SEC>/$time_sec/g;
$content =~ s/<TIME_STRING>/$time_string/g;

$content =~ s/<EAST_CURRENT>/$nc_east_current/g;
$content =~ s/<NORTH_CURRENT>/$nc_north_current/g;
$content =~ s/<EAST_CURRENT_ACCURACY>/$nc_east_current_accuracy/g;
$content =~ s/<NORTH_CURRENT_ACCURACY>/$nc_north_current_accuracy/g;

open (NETCDF_FILE, ">latest.nc.txt");
print NETCDF_FILE $content;
close (NETCDF_FILE);

my $nc_filename = "seacoos.usf.wera_hf_radar_$now_year\_$now_month\_$now_day\_$now_hour\_$now_minute\_latest.nc";
`/home/xeniaprod/scripts/dap/netcdf-4.1.1/ncgen/ncgen -o $nc_filename latest.nc.txt`;
`mv $nc_filename /var/www/netcdf_latest/wera`;

exit 0;

