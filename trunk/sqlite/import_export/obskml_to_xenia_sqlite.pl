#!/usr/bin/perl
#script: obskml_to_xenia_sqlite.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#transforms ObsKML into SQL inserts for Xenia DB schema(version 2 sqlite)

use strict;
use XML::LibXML;
use DBI;
use LWP::Simple;

####################
#config

#note the user process under which this runs needs to have permissions to write to the following paths

#a temporary directory for decompressing, processing files
my $temp_dir = '/var/www/html/ms_tmp';

my $dbname = '/var/www/cgi-bin/microwfs/microwfs.db';

my $sqlite_path = '/usr/bin/sqlite3-3.5.4.bin';

my $undefined_platform_type_id = 6;

#note: the subroutine get_observed_property has hardcoded values for sensor:m_type_id,type_id,short_name and may need to have different values depending on the target xenia database

#provide input date cutoff for observation data
my $date_cutoff = `date --date='3 days ago' +%Y-%m-%dT%H:%M:%S`;
chomp($date_cutoff);
#$date_cutoff = '2008-01-18T13:00:00'; #manual set/debug
#print $date_cutoff;

#originally resolving seconds for dropping duplicates, but dropping time seconds resolution due to duplicates(:00, :40 secs) which are probably netcdf truncating related 
#see usage in code below
my $time_seconds_resolution_flag == 0;

open (SQL_OUT, ">./latest.sql");

###########################################################

#this is a zip of 1 or more ObsKML files which will all be processed into the necessary oostethys support files
#my $kml_zip_feed = 'http://carocoops.org/obskml/feeds/wq/wq_metadata_latest.kmz';
my $kml_zip_feed = @ARGV[0];

#create temp working directory
my $random_value = int(rand(10000000));
my $target_dir = "$temp_dir/gearth_$random_value";
`mkdir $target_dir`;
#print $target_dir."\n";

##################
#read input files to temp directory
##################

#zip_obskml_url
my $zip_filepath = "$target_dir/obskml.xml.zip";
#print $zip_filepath."\n";
getstore("$kml_zip_feed", $zip_filepath);
`cd $target_dir; unzip obskml.xml.zip`;

my $filelist = `ls $target_dir/*.kml`;
#print $filelist;
my @files = split(/\n/,$filelist);
#print @files;

#my $content = getstore('http://carocoops.org/obskml/scripts/to_xenia/seacoos_test1.kml','seacoos_test1.kml');
#die "Couldn't get document" unless defined $content;

#my @platform_ignore = qw(carocoops ndbc.MLRF1 vos);
my @platform_ignore = qw(vos);

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);

foreach my $file (@files) {
my $xp = XML::LibXML->new->parse_file("$file");

#my $xp_xml = $xp->serialize; #debug
#print $xp_xml;

foreach my $platform ($xp->findnodes('//Placemark')) {

	#get org/platform related info - only processing obskml with Placemark id attribute utilized (like 'Placemark id=carocoops.CAP1.wls')
        my $platform_id = sprintf("%s",$platform->getAttribute('id'));
	#print "$platform_id\n";

	#could develop a generic 'none.none.none' placeholder, but problems with maintenance and clean-up with temporary platform,sensor ids
        if (!($platform_id)) { next; }
	#print "$platform_id\n";

	#skip platform_id in platform_ignore list	
        if (&search_array($platform_id, @platform_ignore)) { next; }

	my $operator_url = sprintf("%s",$platform->find('Metadata/obsList/operatorURL'));
        my $platform_url = sprintf("%s",$platform->find('Metadata/obsList/platformURL'));
        my $platform_desc = sprintf("%s",$platform->find('Metadata/obsList/platformDescription'));

	my $lon_lat_string = sprintf("%s",$platform->find('Point/coordinates'));
	my ($longitude,$latitude) = split(/,/,$lon_lat_string);
	#print "$lon $lat \n";
	
        my $m_date = sprintf("%s",$platform->find('TimeStamp/when'));
        #print "$m_date \n";

	#calculate seconds to add to base time to get zulu time
	#note the below conversion could also be done using sqlite database command like
	#select datetime('2008-01-01T12:00:00','+$timezone hours')

	my ($timezone) = substr($m_date,19,3);
	my $timezone_sec = -3600 * $timezone;
	#print $timezone."\n";

	$m_date =~ s/T/ /; #swap space for 'T' for 'date' command below
	$m_date = substr($m_date,0,19); #drop timezone for 'date' command below
	my $date_converted_1 = `date --date='$m_date +0000' +%s` + $timezone_sec;
	#originally resolving seconds, but dropping second resolution due to duplicates(:00, :40) which are probably netcdf truncating related 
	if ($time_seconds_resolution_flag == 1) {
		$m_date = `date -u -d '1970-01-01 $date_converted_1 seconds' +"%Y-%m-%dT%H:%M:%S"`;
	}
	else {
		$m_date = `date -u -d '1970-01-01 $date_converted_1 seconds' +"%Y-%m-%dT%H:%M:00"`;
	}

	chomp($m_date);
        #print "$m_date \n";

	if ($m_date < $date_cutoff) { print "rejecting date: $m_date \n"; next; }

	##organization####################
	my ($organization_name,$platform_name,$platform_type) = split(/[\._]/,$platform_id);	

	$sql = qq{ SELECT row_id,short_name from organization where short_name like '$organization_name' };
	#print $sql."\n";
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	my ($organization_row_id,$organization_name_lkp) = $sth->fetchrow_array;

	if ($organization_name_lkp) {} #print "$organization_name_lkp\n"; 
	else {
		print "organization $organization_name not found - inserting\n";
	
		$sql = qq{ INSERT into organization(row_entry_date,active,short_name,url) values (datetime('now'),'t','$organization_name','$operator_url'); };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();

		#requery for new row_id
		$sql = qq{ SELECT row_id from organization where short_name like '$organization_name' };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();
		($organization_row_id) = $sth->fetchrow_array;

	}

	##platform####################
	$sql = qq{ SELECT row_id,short_name from platform where organization_id = $organization_row_id and short_name like '$platform_name' };
	#print $sql."\n";
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	my ($platform_row_id,$platform_name_lkp) = $sth->fetchrow_array;

	if ($platform_name_lkp) {} #print "$platform_name_lkp\n"; }
	else {
		print "platform $platform_name not found - inserting\n";

		$sql = qq{ INSERT into platform(row_entry_date,organization_id,type_id,short_name,platform_handle,fixed_longitude,fixed_latitude,long_name,description,url) values (datetime('now'),$organization_row_id,$undefined_platform_type_id,'$platform_name','$platform_id',$longitude,$latitude,'$platform_desc','$platform_desc','$platform_url'); };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();

		#requery for new row_id
		$sql = qq{ SELECT row_id from platform where organization_id = $organization_row_id and short_name like '$platform_name' };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();
		($platform_row_id) = $sth->fetchrow_array;
	}

        foreach my $observation ($platform->findnodes('Metadata/obsList/obs')) {
	        my $obs_type = sprintf("%s",$observation->find('obsType'));
	        my $uom_type = sprintf("%s",$observation->find('uomType'));
	        my $measurement = sprintf("%s",$observation->find('value'));
                my $elev = sprintf("%s",$observation->find('elev'));

                my ($m_type_id,$sensor_type_id,$sensor_short_name) = get_observed_property($obs_type.".".$uom_type);
		#print ": $m_type_id $sensor_type_id $sensor_short_name \n";

		if ($m_type_id eq 'undefined') { print "$obs_type.$uom_type undefined \n"; next; }

	##sensor####################
	$sql = qq{ SELECT row_id from sensor where m_type_id = $m_type_id and platform_id = $platform_row_id };
	#print $sql."\n";
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	my ($sensor_row_id) = $sth->fetchrow_array;

	if ($sensor_row_id) {} #print "$sensor_row_id\n"; }
	else {
		print "sensor $obs_type.$uom_type not found - inserting\n";

		$sql = qq{ INSERT into sensor(row_entry_date,platform_id,type_id,short_name,m_type_id,s_order) values (datetime('now'),$platform_row_id,$sensor_type_id,'$sensor_short_name',$m_type_id,1); };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();

		#requery for new row_id
		$sql = qq{ SELECT row_id from sensor where m_type_id = $m_type_id and platform_id = $platform_row_id };
		#print $sql."\n";
		$sth = $dbh->prepare( $sql );
		$sth->execute();
		($sensor_row_id) = $sth->fetchrow_array;

	}

	##observation####################

	if ($elev eq '') { $elev = -99999; }
        if (!($measurement)) { print "missing measurement \n"; next; }

	$sql = qq{ INSERT into multi_obs(row_entry_date,platform_handle,sensor_id,m_type_id,m_date,m_lon,m_lat,m_z,m_value) values (datetime('now'),'$platform_id',$sensor_row_id,$m_type_id,'$m_date',$longitude,$latitude,$elev,$measurement); };

	#tried running the above insert statement dynamically, like the others, but ran into problems with duplicates instead of being ignored
	#and the program continuing, causing the program to halt(tried getting around this using an 'eval' block but still had problems)
	#so just decided to write all these inserts to an output file and load them from there

	print SQL_OUT $sql."\n";

	} #foreach $observation


	$sth->finish();
	undef $sth; # to stop "closing dbh with active statement handles"
         	    # http://rt.cpan.org/Ticket/Display.html?id=22688
} #foreach $platform

} #foreach $file

$dbh->disconnect();

close (SQL_OUT);

`$sqlite_path microwfs.db < latest.sql`;

exit 0;

####################################################
sub search_array {

my $search_term = shift @_;
my @search_array = @_;

foreach  my $search_page (@search_array) {
        if ($search_term =~ $search_page) { return 1; }
}

return 0;
}

####################################################
sub get_observed_property {
#this subs the xenia database sensor:m_type_id,type_id,short_name for the obs_type.uom_type string provided
#got tired of specifying sensor type_id(attribute not really utilized), so using -99999 as default

my $string = shift;
my @ret_val = ();

if ($string eq 'air_temperature.celsius') { push @ret_val, 5; push @ret_val, 1; push @ret_val, "air_temperature"; }
if ($string eq 'air_pressure.millibar') { push @ret_val, 4; push @ret_val, 2; push @ret_val, "air_pressure"; }
if ($string eq 'wind_speed.m_s-1') { push @ret_val, 1; push @ret_val, 6; push @ret_val, "wind_speed"; }
if ($string eq 'wind_gust.m_s-1') { push @ret_val, 2; push @ret_val, 5; push @ret_val, "wind_gust"; }
if ($string eq 'wind_from_direction.degrees_true') { push @ret_val, 3; push @ret_val, 10; push @ret_val, "wind_from_direction"; }
if ($string eq 'relative_humidity.percent') { push @ret_val, 22; push @ret_val, 4; push @ret_val, "relative_humidity"; }
if ($string eq 'precipitation.millimeter') { push @ret_val, 29; push @ret_val, 31; push @ret_val, "precipitation"; }
if ($string eq 'solar_radiation.millimoles_per_m^2') { push @ret_val, 30; push @ret_val, 3; push @ret_val, "solar_radiation"; }

if ($string eq 'significant_wave_height.m') { push @ret_val, 13; push @ret_val, -99999; push @ret_val, "significant_wave_height"; }
if ($string eq 'dominant_wave_period.s') { push @ret_val, 14; push @ret_val, -99999; push @ret_val, "dominant_wave_period"; }
if ($string eq 'visibility.nautical_miles') { push @ret_val, 39; push @ret_val, -99999; push @ret_val, "visibility"; }
if ($string eq 'current_speed.m_s-1') { push @ret_val, 11; push @ret_val, -99999; push @ret_val, "current_speed"; }
if ($string eq 'current_to_direction.degrees_true') { push @ret_val, 12; push @ret_val, -99999; push @ret_val, "current_to_direction"; }

if ($string eq 'water_level.m(MLLW)') { push @ret_val, 23; push @ret_val, -99999; push @ret_val, "water_level"; }
if ($string eq 'chlorophyll.ug_L-1') { push @ret_val, 10; push @ret_val, -99999; push @ret_val, "chlorophyll"; }
if ($string eq 'salinity.psu') { push @ret_val, 28; push @ret_val, 20; push @ret_val, "salinity"; }
if ($string eq 'water_temperature.celsius') { push @ret_val, 6; push @ret_val, 23; push @ret_val, "water_temperature"; }
if ($string eq 'dissolved_oxygen.mg_L-1') { push @ret_val, 34; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'dissolved_oxygen.percent') { push @ret_val, 35; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'dissolved_oxygen.percent_saturation') { push @ret_val, 35; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'water_conductivity.mS_cm-1') { push @ret_val, 7; push @ret_val, 30; push @ret_val, "water_conductivity"; }
if ($string eq 'turbidity.ntu') { push @ret_val, 36; push @ret_val, 29; push @ret_val, "turbidity"; }
if ($string eq 'ph.units') { push @ret_val, 38; push @ret_val, 27; push @ret_val, "ph"; }
if ($string eq 'gage_height.m') { push @ret_val, 41; push @ret_val, 28; push @ret_val, "gage_height"; }

#also available for mapping
#dominant_wave_direction,water_conductivity,water_level(MLLW),ph,turbidity,precipitation,relative_humidity,dew_point,gage_height,stream_velocity,dissolved_oxygen.percent_saturation,vos-ships(wave_height,swell_height,swell_period,swell_from_direction)

if ($ret_val[0] eq '') { push @ret_val, "undefined"; push @ret_val, "undefined"; push @ret_val, "undefined"; }

return @ret_val;
}
