#!/usr/bin/perl
#script: obskml_to_xenia.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#Date: October 18, 2007
#script description
#transforms ObsKML into SQL inserts for Xenia DB schema(version 1) - may need SQL tweaking for version 2

use strict;
use XML::LibXML;
use DBI;
use LWP::Simple;

####################
#config
my $db_host  = 'db_server';
my $db_name   = 'db_xenia_wx';
my $db_user   = 'postgres';
my $db_passwd = '';

#note the user process under which this runs needs to have permissions to write to the following paths

#a temporary directory for decompressing, processing files
my $temp_dir = '/var/tmp/ms_tmp';

my $undefined_platform_type_id = 6;

#note: the subroutine get_observed_property has hardcoded values for sensor:m_type_id,type_id,short_name and may need to have different values depending on the target xenia database

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

my @platform_ignore = qw(carocoops ndbc.MLRF1 vos);

my $dbh = DBI->connect ("dbi:Pg:dbname=$db_name;host=$db_host","$db_user","$db_passwd");
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);

foreach my $file (@files) {
my $xp = XML::LibXML->new->parse_file("$file");

#my $xp_xml = $xp->serialize; #debug
#print $xp_xml;

foreach my $platform ($xp->findnodes('//Placemark')) {

	#get org/platform related info
        my $platform_id = sprintf("%s",$platform->find('name'));
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

	my ($timezone) = substr($m_date,19,3);
	$timezone = -1 * $timezone;
	#print $timezone."\n";

	$sql = qq{ SELECT to_timestamp('$m_date','YYYY-MM-DD HH:MI:SS') + interval '$timezone hour' };
	#print $sql."\n";
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	($m_date) = $sth->fetchrow_array;

        print "$m_date \n";

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
	
		$sql = qq{ INSERT into organization(active,short_name,url) values ('t','$organization_name','$operator_url'); };
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

		$sql = qq{ INSERT into platform(organization_id,type_id,short_name,platform_handle,fixed_longitude,fixed_latitude,long_name,description,url) values ($organization_row_id,$undefined_platform_type_id,'$platform_name','$platform_id',$longitude,$latitude,'$platform_desc','$platform_desc','$platform_url'); };
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

		$sql = qq{ INSERT into sensor(platform_id,type_id,short_name,m_type_id,s_order) values ($platform_row_id,$sensor_type_id,'$sensor_short_name',$m_type_id,1); };
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

	$sql = qq{ INSERT into multi_obs(row_entry_date,row_update_date,platform_handle,sensor_id,m_type_id,m_date,m_lon,m_lat,m_z,m_value) values (now(),now(),'$platform_id',$sensor_row_id,$m_type_id,'$m_date',$longitude,$latitude,$elev,$measurement); };
	print $sql."\n";
	$sth = $dbh->prepare( $sql );
	$sth->execute();

	} #foreach $observation


	$sth->finish();
} #foreach $platform

} #foreach $file

$dbh->disconnect();

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

#if ($string eq 'significant_wave_height.m') { $string = 'SIGNIFICANT_HEIGHT_OF_WIND_AND_SWELL_WAVES'}
#if ($string eq 'dominant_wave_period.s') { $string = 'DOMINANT_WAVE_PERIOD'}
#if ($string eq 'visibility.nautical_miles') { $string = 'VISIBILITY_IN_AIR'}
#if ($string eq 'current_speed.m_s-1') { $string = 'SEA_WATER_SPEED'}
#if ($string eq 'current_to_direction.degrees_true') { $string = 'DIRECTION_OF_SEA_WATER_VELOCITY'}

#if ($string eq 'chlorophyll.ug_L-1') { $string = 'CHLOROPHYLL'}
if ($string eq 'salinity.psu') { push @ret_val, 28; push @ret_val, 20; push @ret_val, "salinity"; }
if ($string eq 'water_temperature.celsius') { push @ret_val, 6; push @ret_val, 23; push @ret_val, "water_temperature"; }
if ($string eq 'dissolved_oxygen.mg_L-1') { push @ret_val, 34; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'dissolved_oxygen.percent') { push @ret_val, 35; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'dissolved_oxygen.percent_saturation') { push @ret_val, 35; push @ret_val, 25; push @ret_val, "oxygen_concentration"; }
if ($string eq 'water_conductivity.mS_cm-1') { push @ret_val, 7; push @ret_val, 30; push @ret_val, "water_conductivity"; }
if ($string eq 'turbidity.ntu') { push @ret_val, 36; push @ret_val, 29; push @ret_val, "turbidity"; }
if ($string eq 'water_conductivity.mS_cm-1') { push @ret_val, 38; push @ret_val, 27; push @ret_val, "ph"; }
if ($string eq 'gage_height.m') { push @ret_val, 41; push @ret_val, 28; push @ret_val, "gage_height"; }

#also available for mapping
#dominant_wave_direction,water_conductivity,water_level(MLLW),ph,turbidity,precipitation,relative_humidity,dew_point,gage_height,stream_velocity,dissolved_oxygen.percent_saturation,vos-ships(wave_height,swell_height,swell_period,swell_from_direction)

if ($ret_val[0] eq '') { push @ret_val, "undefined"; push @ret_val, "undefined"; push @ret_val, "undefined"; }

return @ret_val;
}

