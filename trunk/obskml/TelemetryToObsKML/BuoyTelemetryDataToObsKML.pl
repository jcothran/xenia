#!/usr/bin/perl

use constant MICROSOFT_PLATFORM => 0;
if( !MICROSOFT_PLATFORM )
{
  require "./obsKMLSubRoutines.lib";
}
else
{
  require ".\\obsKMLSubRoutines.lib";  
}



#use warnings;
use strict;
use DBI;
use Config::IniFiles;
use Getopt::Long;


my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "DataFile=s",
            "ControlFile=s",
            "DirForKml=s"
             );

my $currentFile  = $CommandLineOptions{"DataFile"}; 
my $strControlFile  = $CommandLineOptions{"ControlFile"}; 
my $strKMLDir  = $CommandLineOptions{"DirForKml"}; 
if( length( $strControlFile ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --DataFile --ControlFile\n". 
              "--DataFile provides the path to the WLS station data file to process.\n".
              "--DirForKml provides the path to the store the KML files created.\n".             
              "--ControlFile provides the XML file to be used to update the database.\n" );
}



my $FCAT_ELEV = -1;
my $PCAT10M_ELEV = -10; 
my $PCAT30M_ELEV = -30; 
my $WLS_ELEV = -2.5; 


my $cfg = undef;
my $strUnitsXMLFilename;
if( !MICROSOFT_PLATFORM )
{
  $cfg = new Config::IniFiles( -file => "./processBuoys.ini" );
  $strUnitsXMLFilename = './UnitsConversion.xml';
}
else
{
  $cfg = new Config::IniFiles( -file => ".\\processBuoys.ini" ); 
  $strUnitsXMLFilename = '.\\UnitsConversion.xml';
}
my $currentPath = $cfg->val('BUOY', 'processed_dir'); 
#my $currentFile = $ARGV[0];

##################################################################################
##################################################################################
##################################################################################

if (($currentFile =~ /Buoy8-/) || ($currentFile =~ /Buoy10-/) || ($currentFile =~ /Buoy6-/) || ($currentFile =~ /Buoy4-/) || ($currentFile =~ /Buoy11-/) || ($currentFile =~ /Buoy13-/) || ($currentFile =~ /Buoy2-/)) 
{

	my ($buoy_id, $buoy_lat, $buoy_long, $buoy_battery, $buoy_temp);
	my $measurement_timestamp_dbformat; #for ndbc fm13 message

	my ($station_id, $wind_sensor_id);
	#10 meter depth line
	if ($currentFile =~ /Buoy8-/) { $buoy_id = 'buoy2'; $station_id = 'cc_buoy2'; $wind_sensor_id = 7; }
	if ($currentFile =~ /Buoy10-/) { $buoy_id = 'buoy4'; $station_id = 'cc_buoy4'; $wind_sensor_id = 8; }
	if ($currentFile =~ /Buoy6-/) { $buoy_id = 'buoy6'; $station_id = 'cc_buoy6'; $wind_sensor_id = 9; }
	if ($currentFile =~ /Buoy13-/) { $buoy_id = 'buoy20'; $station_id = 'cormp_ilm2'; $wind_sensor_id = 12; }
	#30 meter depth line
	if ($currentFile =~ /Buoy4-/) { $buoy_id = 'buoy5'; $station_id = 'cc_buoy5'; $wind_sensor_id = 10; }
	if ($currentFile =~ /Buoy2-/) { $buoy_id = 'buoy7'; $station_id = 'cc_buoy7'; $wind_sensor_id = 11; }	
	if ($currentFile =~ /Buoy11-/) { $buoy_id = 'buoy21'; $station_id = 'cormp_ilm3'; $wind_sensor_id = 13; }	

	print "$currentFile processed\n";

  my %PlatformIDHash;
  LoadPlatformControlFile($strControlFile, \%PlatformIDHash, $buoy_id);

=comment  #JTC 2008/03/12 commenting this section out since the reformatting of the initial file should be handled in an earlier step
	#replace empty ADCP statement with appropriate number of empty fields
	if( !MICROSOFT_PLATFORM )
	{
	 `sed -e 's/ADCP,,/ADCP,0,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/' $currentPath$currentFile > processBuoyTemp1 && mv processBuoyTemp1 $currentPath$currentFile`;
	}
	else
	{
   `\\UnixUtils\\usr\\local\\wbin\\sed.exe -e 's/ADCP,,/ADCP,0,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/' $currentPath$currentFile > processBuoyTemp1 && mv processBuoyTemp1 $currentPath$currentFile`;	  
	}
=cut

	#replace 'termination' string with empty field from there forward

	open(BUOY_FILE, $currentPath.$currentFile)
	or die "Can't find file $currentPath$currentFile: $!\n";


	#the following code reads 0,1,many lines of buoy updates, ignoring lines starting with # and partial lines
	foreach my $line_record (<BUOY_FILE>) {

		#ignore lines which start with '#'
		if (substr($line_record,0,1) eq '#') {next};

		#@record = split(/\,/,$line_record);
		my @init_record = split(/\,/,$line_record);

		my @record = &removeTerminationData(@init_record);
		#print "#records = ".scalar(@record)."\n";

		#ignore lines with date only - technically should be able to mark records that are being rebroadcast, but issues exist
		if (scalar(@record) < 3) {next};

		#skip lines where the first field(buoy id) or more might have gotten dropped
		if (@record[8] ne 'PCAT') { print "row beginning truncated \n"; next; } #using the 'PCAT' field here as a check

                #if ($buoy_id eq 'buoy2') { if (!(@record[5] =~ /3216./)) { next; }} #double checking latitude position

		#double check buoy id
                if ($buoy_id eq 'buoy2') { if (!(@record[0] == 8)) { next; }} 
                if ($buoy_id eq 'buoy4') { if (!(@record[0] == 10)) { next; }} 
                if ($buoy_id eq 'buoy6') { if (!(@record[0] == 6)) { next; }}
                if ($buoy_id eq 'buoy20') { if (!(@record[0] == 13)) { next; }} 
                if ($buoy_id eq 'buoy5') { if (!(@record[0] == 4)) { next; }}
                if ($buoy_id eq 'buoy7') { if (!(@record[0] == 2)) { next; }} 
                if ($buoy_id eq 'buoy21') { if (!(@record[0] == 11)) { next; }}
	
		if ($buoy_id eq 'buoy20' || $buoy_id eq 'buoy21') { splice(@record, 13, 1); } #not sure what this extra field represents
	
		#good to go here
		my $valid_fields = 2;

		#assign record array fields to variables
		my $measurement_date = @record[1];	
		my $measurement_time = @record[2]; #note this is data logger time - assuming this is 'close enough' to UTC

		#$measurement_timestamp_webformat = substr($measurement_date,3,5)." ".substr($measurement_time,0,5);
		#print $measurement_timestamp_webformat."\n";

		$measurement_timestamp_dbformat = substr($measurement_date,3,5)."/".substr($measurement_date,0,2)." ".$measurement_time;
		#print $measurement_timestamp_dbformat."\n";
		if ($measurement_timestamp_dbformat eq '') {$measurement_timestamp_dbformat = 'NULL'};

		my $measurement_timestamp_webformat = get_local_time($measurement_timestamp_dbformat, -4); 
		print $measurement_timestamp_webformat."\n";

		$buoy_battery = 'NULL';
		$buoy_temp = 'NULL';
		$buoy_lat = 'NULL';
		$buoy_long = 'NULL';
		my $utc = 'NULL';
	
                if (scalar( (@record) > 2) && (!(@record[3] eq '' || @record[3] eq 'NODATA')) ) {
                        $buoy_battery = @record[3];
                        $valid_fields++;
                }

                if (scalar( (@record) > 3) && (!(@record[4] eq '' || @record[4] eq 'NODATA')) ) {
                        $buoy_temp = @record[4];
                        $valid_fields++;
                }

                if (scalar( (@record) > 4) && (!(@record[5] eq '' || @record[5] eq 'NODATA')) ) { 
                        $buoy_lat = @record[5];
                        $valid_fields++;
                }

                if (scalar( (@record) > 5) && (!(@record[6] eq '' || @record[6] eq 'NODATA')) ) {
                        $buoy_long = @record[6];
                        $valid_fields++;
                }

                if (scalar( (@record) > 6) && (!(@record[7] eq '' || @record[7] eq 'NODATA')) ) { 
                        $utc = @record[7];
                        $valid_fields++;
                }


		#PCAT

		my $pcat_pressure = 'NULL';
		my $pcat_conductivity = 'NULL';
		my $pcat_temp = 'NULL';
		my $pcat_salinity = 'NULL';

		print "PCAT\n";

		if (scalar( (@record) > 8) && (!(@record[9] eq '' || @record[9] eq 'NODATA')) ) {		
			$pcat_pressure = @record[9];
			$valid_fields++;
		}
		
		if (scalar( (@record) > 9) && (!(@record[10] eq '' || @record[10] eq 'NODATA')) ) {		
			$pcat_conductivity = sprintf("%.4f", @record[10]);
			$valid_fields++;
		}

		if (scalar( (@record) > 10) && (!(@record[11] eq '' || @record[11] eq 'NODATA')) ) {		
			$pcat_temp = @record[11];
			$valid_fields++;
		}

		if (scalar( (@record) > 11) && (!(@record[12] eq '' || @record[12] eq 'NODATA')) ) {		
			$pcat_salinity = @record[12];
			$valid_fields++;
		}

		#FCAT - also using for uCAT

		my $fcat_pressure = 'NULL';
 		my $fcat_temp = 'NULL';
 		my $fcat_conductivity = 'NULL';
    my $fcat_salinity = 'NULL';
    my $fcat_voltage = 'NULL';
  
		my $marker = "";
		$marker = test_array_for_string(\@record, 'FCAT');
		
		if (!($marker)) {
			$marker = test_array_for_string(\@record, 'uCAT');
		}	

	
		if ($marker) {

		print "FCAT or uCAT\n";
 
		#offset config
		my $fcat_pressure_offset = "";
		my $fcat_temp_offset = "";
		my $fcat_conductivity_offset = "";
		my $fcat_salinity_offset = "";
		my $fcat_voltage_offset = "";

		if ($buoy_id eq 'buoy5' || $buoy_id eq 'buoy7') {
		$fcat_pressure_offset = "1";
		$fcat_temp_offset = "3";
		$fcat_conductivity_offset = "2";
		$fcat_salinity_offset = "";
		$fcat_voltage_offset = "";
		}
		else {  #all the other buoys
		$fcat_pressure_offset = "1";
		$fcat_temp_offset = "3";
		$fcat_conductivity_offset = "";
		$fcat_salinity_offset = "4";
		$fcat_voltage_offset = "5";
		}

                if (scalar( (@record) > $marker) && (!(@record[$marker+$fcat_pressure_offset] eq '' || @record[$marker+$fcat_pressure_offset] eq 'NODATA')) ) {
                                $fcat_pressure = @record[$marker+$fcat_pressure_offset];
                                $valid_fields++;
                }
                
                if (scalar( (@record) > $marker+$fcat_temp_offset-1) && (!(@record[$marker+$fcat_temp_offset] eq '' || @record[$marker+$fcat_temp_offset] eq 'NODATA')) ) {
                                $fcat_temp = @record[$marker+$fcat_temp_offset];
                                 $valid_fields++;
                }

		if ($fcat_salinity_offset) {
                if (scalar( (@record) > $marker+$fcat_salinity_offset-1) && (!(@record[$marker+$fcat_salinity_offset] eq '' || @record[$marker+$fcat_salinity_offset] eq 'NODATA')) ) {
                                $fcat_salinity = @record[$marker+$fcat_salinity_offset];
                                 $valid_fields++;
                }
		}
		#derive salinity from conductivity - call c program which uses (r,t,p) to compute
		elsif ($fcat_conductivity_offset) {
                if (scalar( (@record) > $marker+$fcat_conductivity_offset-1) && (!(@record[$marker+$fcat_conductivity_offset] eq '' || @record[$marker+$fcat_conductivity_offset] eq 'NODATA')) ) {
                                $fcat_conductivity = @record[$marker+$fcat_conductivity_offset];
				my $r_value = 10*$fcat_conductivity/42.914;
				$fcat_salinity = `../c/salinity $r_value $fcat_temp $fcat_pressure`;
				#print "$r_value $fcat_salinity";
                                 $valid_fields++;
                }
		}

		if ($fcat_voltage_offset) {
                if (scalar( (@record) > $marker+$fcat_voltage_offset-1) && (!(@record[$marker+$fcat_voltage_offset] eq '' || @record[$marker+$fcat_voltage_offset] eq 'NODATA')) ) {
                                $fcat_voltage = @record[$marker+$fcat_voltage_offset];
                                $valid_fields++;
                }
		} #if $fcat_voltage_offset
		} #if marker


		#ADCP

		my $adcp_bin1_velocity = 'NULL' ;
		my $adcp_bin1_direction = 'NULL' ;
		my $adcp_bin2_velocity = 'NULL' ;
		my $adcp_bin2_direction = 'NULL' ;
		my $adcp_bin3_velocity = 'NULL' ;
		my $adcp_bin3_direction = 'NULL' ;
		my $adcp_bin4_velocity = 'NULL' ;
		my $adcp_bin4_direction = 'NULL' ;
		my $adcp_bin5_velocity = 'NULL' ;
		my $adcp_bin5_direction = 'NULL' ;
		my $adcp_bin6_velocity = 'NULL' ;
		my $adcp_bin6_direction = 'NULL' ;
		my $adcp_bin7_velocity = 'NULL' ;
		my $adcp_bin7_direction = 'NULL' ;
		my $adcp_bin8_velocity = 'NULL' ;
		my $adcp_bin8_direction = 'NULL' ;
		my $adcp_bin9_velocity = 'NULL' ;
		my $adcp_bin9_direction = 'NULL' ;
		my $adcp_bin10_velocity = 'NULL' ;
		my $adcp_bin10_direction = 'NULL' ;

		$marker = "";
		$marker = test_array_for_string(\@record, 'ADCP');
		
		if ($marker) {
		print "ADCP\n";

		if (scalar( (@record) > $marker+3) && (!(@record[$marker+4] eq '' || @record[$marker+4] eq 'NODATA')) ) {		
			$adcp_bin1_velocity = @record[$marker+4];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+4) && (!(@record[$marker+5] eq '' || @record[$marker+5] eq 'NODATA')) ) {		
			$adcp_bin1_direction = convertTo360(@record[$marker+5]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+6) && (!(@record[$marker+7] eq '' || @record[$marker+7] eq 'NODATA')) ) {		
			$adcp_bin2_velocity = @record[$marker+7];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+7) && (!(@record[$marker+8] eq '' || @record[$marker+8] eq 'NODATA')) ) {		
			$adcp_bin2_direction = convertTo360(@record[$marker+8]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+9) && (!(@record[$marker+10] eq '' || @record[$marker+10] eq 'NODATA')) ) {		
			$adcp_bin3_velocity = @record[$marker+10];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+10) && (!(@record[$marker+11] eq '' || @record[$marker+11] eq 'NODATA')) ) {		
			$adcp_bin3_direction = convertTo360(@record[$marker+11]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+12) && (!(@record[$marker+13] eq '' || @record[$marker+13] eq 'NODATA')) ) {		
			$adcp_bin4_velocity = @record[$marker+13];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+13) && (!(@record[$marker+14] eq '' || @record[$marker+14] eq 'NODATA')) ) {		
			$adcp_bin4_direction = convertTo360(@record[$marker+14]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+15) && (!(@record[$marker+16] eq '' || @record[$marker+16] eq 'NODATA')) ) {		
			$adcp_bin5_velocity = @record[$marker+16];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+16) && (!(@record[$marker+17] eq '' || @record[$marker+17] eq 'NODATA')) ) {		
			$adcp_bin5_direction = convertTo360(@record[$marker+17]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+18) && (!(@record[$marker+19] eq '' || @record[$marker+19] eq 'NODATA')) ) {		
			$adcp_bin6_velocity = @record[$marker+19];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+19) && (!(@record[$marker+20] eq '' || @record[$marker+20] eq 'NODATA')) ) {		
			$adcp_bin6_direction = convertTo360(@record[$marker+20]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+21) && (!(@record[$marker+22] eq '' || @record[$marker+22] eq 'NODATA')) ) {		
			$adcp_bin7_velocity = @record[$marker+22];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+22) && (!(@record[$marker+23] eq '' || @record[$marker+23] eq 'NODATA')) ) {		
			$adcp_bin7_direction = convertTo360(@record[$marker+23]);
			$valid_fields++;
		}
				
		if (scalar( (@record) > $marker+24) && (!(@record[$marker+25] eq '' || @record[$marker+25] eq 'NODATA')) ) {		
			$adcp_bin8_velocity = @record[$marker+25];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+25) && (!(@record[$marker+26] eq '' || @record[$marker+26] eq 'NODATA')) ) {		
			$adcp_bin8_direction = convertTo360(@record[$marker+26]);
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+27) && (!(@record[$marker+28] eq '' || @record[$marker+28] eq 'NODATA')) ) {		
			$adcp_bin9_velocity = @record[$marker+28];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+28) && (!(@record[$marker+29] eq '' || @record[$marker+29] eq 'NODATA')) ) {		
			$adcp_bin9_direction = convertTo360(@record[$marker+29]);
			$valid_fields++;
		}
		
		if (scalar( (@record) > $marker+30) && (!(@record[$marker+31] eq '' || @record[$marker+31] eq 'NODATA')) ) {		
			$adcp_bin10_velocity = @record[$marker+31];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+31) && (!(@record[$marker+32] eq '' || @record[$marker+32] eq 'NODATA')) ) {		
			$adcp_bin10_direction = convertTo360(@record[$marker+32]);
			$valid_fields++;
		}		

		} #if ADCP

                $marker = "";
                $marker = test_array_for_string(\@record, 'CRNTS');

                if ($marker) {

                print "CRNTS\n";

		my $u_vec = "";
		my $v_vec = "";

                if (scalar( (@record) > $marker+7) && (!(@record[$marker+8] eq '' || @record[$marker+8] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+8];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+8) && (!(@record[$marker+9] eq '' || @record[$marker+9] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+9];
                        $valid_fields++;
                }

		($adcp_bin1_velocity, $adcp_bin1_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 
		#print "bin1_v:$adcp_bin1_velocity bin1_d:$adcp_bin1_direction\n";

                if (scalar( (@record) > $marker+10) && (!(@record[$marker+11] eq '' || @record[$marker+11] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+11];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+11) && (!(@record[$marker+12] eq '' || @record[$marker+12] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+12];
                        $valid_fields++;
                }

		($adcp_bin2_velocity, $adcp_bin2_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+13) && (!(@record[$marker+14] eq '' || @record[$marker+14] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+14];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+14) && (!(@record[$marker+15] eq '' || @record[$marker+15] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+15];
                        $valid_fields++;
                }

		($adcp_bin3_velocity, $adcp_bin3_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+16) && (!(@record[$marker+17] eq '' || @record[$marker+17] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+17];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+17) && (!(@record[$marker+18] eq '' || @record[$marker+18] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+18];
                        $valid_fields++;
                }

		($adcp_bin4_velocity, $adcp_bin4_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+19) && (!(@record[$marker+20] eq '' || @record[$marker+20] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+20];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+20) && (!(@record[$marker+21] eq '' || @record[$marker+21] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+21];
                        $valid_fields++;
                }

		($adcp_bin5_velocity, $adcp_bin5_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+22) && (!(@record[$marker+23] eq '' || @record[$marker+23] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+23];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+23) && (!(@record[$marker+24] eq '' || @record[$marker+24] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+24];
                        $valid_fields++;
                }

		($adcp_bin6_velocity, $adcp_bin6_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+25) && (!(@record[$marker+26] eq '' || @record[$marker+26] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+26];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+26) && (!(@record[$marker+27] eq '' || @record[$marker+27] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+27];
                        $valid_fields++;
                }

		($adcp_bin7_velocity, $adcp_bin7_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+28) && (!(@record[$marker+29] eq '' || @record[$marker+29] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+29];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+29) && (!(@record[$marker+30] eq '' || @record[$marker+30] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+30];
                        $valid_fields++;
                }

		($adcp_bin8_velocity, $adcp_bin8_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+31) && (!(@record[$marker+32] eq '' || @record[$marker+32] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+32];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+32) && (!(@record[$marker+33] eq '' || @record[$marker+33] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+33];
                        $valid_fields++;
                }

		($adcp_bin9_velocity, $adcp_bin9_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

                if (scalar( (@record) > $marker+33) && (!(@record[$marker+34] eq '' || @record[$marker+34] eq 'NODATA')) ) {
                        $u_vec = @record[$marker+34];
                        $valid_fields++;
                }

                if (scalar( (@record) > $marker+34) && (!(@record[$marker+35] eq '' || @record[$marker+35] eq 'NODATA')) ) {
                        $v_vec = @record[$marker+35];
                        $valid_fields++;
                }

		($adcp_bin10_velocity, $adcp_bin10_direction) = &get_mag_and_dir($u_vec, $v_vec, 1000); 

		} #if CRNTS

		##########
		#weatherpack variables
		
		my $wxpak_wind_speed = 'NULL';   #default unit is knots
		my $wxpak_wind_speed_mps = 'NULL';
		my $wxpak_wind_direction = 'NULL';
		my $wxpak_wind_gust = 'NULL'; #default unis is knots
		my $wxpak_wind_gust_mps = 'NULL'; 
    my $wxpak_air_temp = 'NULL';
		my $wxpak_humidity ='NULL';
		my $wxpak_air_pressure = 'NULL';
		my $wxpak_solar = 'NULL';
    my $buoy_visibility = 'NULL';

		$marker = "";
		$marker = test_array_for_string(\@record, 'WXPAK');
    my $marker_bad_1 = test_array_for_string(\@record, 'Watchdog');
    my $marker_bad_2 = test_array_for_string(\@record, 'Seattle');

    if ($marker && !($marker_bad_1) && !($marker_bad_2)) {

		print "WXPAK\n";

		#offset config
		my $wind_speed_offset = "";
		my $wind_direction_offset = "";
		my $wind_gust_offset = "";
		my $air_temp_offset = "";
		my $humidity_offset = "";
		my $air_pressure_offset = "";
		my $solar_offset = "";
		my $visibility_offset = "";
    my $wind_speed_units = "";
                if ($buoy_id eq 'buoy4' || $buoy_id eq 'buoy20' || $buoy_id eq 'buoy21') {
                #April 2007
                $wind_speed_offset = 7;
                $wind_direction_offset = 8;
                $wind_gust_offset = 9;
                $air_temp_offset = 2;
                $humidity_offset = 3;
                $air_pressure_offset = 4;
                $solar_offset = 5;
                $visibility_offset = 10;

                $wind_speed_units = "knots";
                }

                if ($buoy_id eq 'buoy2' || $buoy_id eq 'buoy6' || $buoy_id eq 'buoy7') {
                #Dec 2007
                $wind_speed_offset = 9;
                $wind_direction_offset = 10;
                $wind_gust_offset = 11;
                $air_temp_offset = 4;
                $humidity_offset = 5;
                $air_pressure_offset = 6;
                $solar_offset = 7;
                $visibility_offset = 12;

                $wind_speed_units = "knots";
                }

                if ($buoy_id eq 'buoy5') {
                
                if ((@record[$marker+1] =~ /<D><A>/) && !($marker_bad_1) && !($marker_bad_2)) {
                print "correct - all obs\n"; 
                #December 2007
                $wind_speed_offset = 9;
                $wind_direction_offset = 10;
                $wind_gust_offset = 11;
                $air_temp_offset = 4;
                $humidity_offset = 5;
                $air_pressure_offset = 6;
                $solar_offset = 7; 
                $visibility_offset = 12;
                
                $wind_speed_units = "knots";
                }
                else {
                print "wind only\n";
                #December 2007
                $wind_speed_offset = 2;
                $wind_direction_offset = 3;
                $wind_gust_offset = 4;
                
                $wind_speed_units = "knots";
                }
                } #if buoy5

		if ($buoy_id eq 'buoyNever') {
		$wind_speed_offset = 9;
		$wind_direction_offset = 10;
		$wind_gust_offset = 11;
		$air_temp_offset = 4;
		$humidity_offset = 5;
		$air_pressure_offset = 6;
		$solar_offset = 7;
		$visibility_offset = 12;

		$wind_speed_units = "knots";
		}

		if ($buoy_id eq 'buoyNever') {  #FIX when missing initial fields restored - was Buoy4
                $wind_speed_offset = 8;
                $wind_direction_offset = 9;
                $wind_gust_offset = 10;
                $air_temp_offset = 4;
                $humidity_offset = 5;
                $air_pressure_offset = 6;
                $solar_offset = 1000;
                $visibility_offset = 11;

                $wind_speed_units = "knots";
		}

=comment
		else {  #all the other buoys
		$wind_speed_offset = 4;
		$wind_direction_offset = 5;
		$wind_gust_offset = 7;
		$air_temp_offset = 8;
		$humidity_offset = 9;
		$air_pressure_offset = 10;
		$solar_offset = 11;
		$visibility_offset = 13;

		$wind_speed_units = "mps";
		}
=cut

                if (scalar( (@record) > $marker+$wind_speed_offset-1) && (!(@record[$marker+$wind_speed_offset] eq '' || @record[$marker+$wind_speed_offset] eq 'NODATA') && ($wind_speed_offset ne "")) ) {   
                        $wxpak_wind_speed = @record[$marker+$wind_speed_offset];
			if ($wind_speed_units eq 'knots') { $wxpak_wind_speed = sprintf("%.1f", $wxpak_wind_speed*0.51); }
                        $valid_fields++;
                }

		if (scalar( (@record) > $marker+$wind_direction_offset-1) && (!(@record[$marker+$wind_direction_offset] eq '' || @record[$marker+$wind_direction_offset] eq 'NODATA') && ($wind_direction_offset ne "")) ) {
			$wxpak_wind_direction = @record[$marker+$wind_direction_offset];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+$wind_gust_offset-1) && (!(@record[$marker+$wind_gust_offset] eq '' || @record[$marker+$wind_gust_offset] eq 'NODATA') && ($wind_gust_offset ne "")) ) {
			$wxpak_wind_gust = @record[$marker+$wind_gust_offset];
			if ($wind_speed_units eq 'knots') { $wxpak_wind_gust = sprintf("%.1f", $wxpak_wind_gust*0.51); }
			$valid_fields++;
		}


                if (scalar( (@record) > $marker+$air_temp_offset-1) && (!(@record[$marker+$air_temp_offset] eq '' || @record[$marker+$air_temp_offset] eq 'NODATA') && ($air_temp_offset ne "")) ) {
			$wxpak_air_temp = @record[$marker+$air_temp_offset];
			$valid_fields++;
                }

		if (scalar( (@record) > $marker+$humidity_offset-1) && (!(@record[$marker+$humidity_offset] eq '' || @record[$marker+$humidity_offset] eq 'NODATA') && ($humidity_offset ne "")) ) {		
			$wxpak_humidity = @record[$marker+$humidity_offset];
			$valid_fields++;
		}	

		if (scalar( (@record) > $marker+$air_pressure_offset-1) && (!(@record[$marker+$air_pressure_offset] eq '' || @record[$marker+$air_pressure_offset] eq 'NODATA') && ($air_pressure_offset ne "")) ) {		
			$wxpak_air_pressure = @record[$marker+$air_pressure_offset];
			$valid_fields++;
		}

		if (scalar( (@record) > $marker+$solar_offset-1) && (!(@record[$marker+$solar_offset] eq '' || @record[$marker+$solar_offset] eq 'NODATA') && ($solar_offset ne "")) ) {		
			$wxpak_solar = @record[$marker+$solar_offset];
			$valid_fields++;
		}

		##########
		#visibility variable


                if ($buoy_id eq 'buoy4') { #FIX depending
			if (scalar( (@record) > $marker+$visibility_offset-1) && (!(@record[$marker+$visibility_offset] eq '' || @record[$marker+$visibility_offset] eq 'NODATA')) ) {		
				$buoy_visibility = @record[$marker+$visibility_offset];
				#print "visibility:$buoy_visibility\n";
				$valid_fields++;
			}                
                }

		} #if WXPAK

		print "valid fields=".$valid_fields."\n";

    #Format a DB friendly DB date-time.
    my $strDBDate = $measurement_date;
    $strDBDate =~ s!/!-!g;
    my $iYearCnt = index( $strDBDate, '-');
    my $strYear;
    #Date in data only has 2 digits. Just so I can mess around with perl string stuff, I make
    # this complex piece of code.
    if( $iYearCnt == 2 )
    {
      # To save anyone in the next century from having to come back and fix up code.
      # We want the first 2 digits in the year.
      if( !MICROSOFT_PLATFORM )
      {
        $strYear = `date +%Y`;
        chomp( $strYear );
      }
      else
      {
        $strYear = `\\UnixUtils\\usr\\local\\wbin\\date.exe +%Y`;
        chomp( $strYear );   
      }  
    }    
    $strYear = substr( $strYear, 0, 2 );
    $strDBDate = $strYear.$strDBDate."T".$measurement_time;
    
    
          
    #Find the platform ID and URL.
    my $strPlatformID = $buoy_id;
    my $strPlatformURL = '';
    my $rPlatformIDHash = \%PlatformIDHash;  
    my %ObsHash;
    my $rObsHash = \%ObsHash;
    
    my %PlatformObsSettings;
    
    GetPlatformData( \%PlatformIDHash, $buoy_id, \%PlatformObsSettings );
    $strPlatformID = %PlatformObsSettings->{PlatformID};
    $rObsHash->{PlatformID}{$strPlatformID}{Latitude} = $buoy_lat;
    $rObsHash->{PlatformID}{$strPlatformID}{Longitude} = $buoy_long;
    $rObsHash->{PlatformID}{$strPlatformID}{PlatformURL} = %PlatformObsSettings->{PlatformURL};
    
    #( $strObsName, $strDate, $Value, $SensorSOrder, $rObsHash, $rPlatformControlFileInfo, $rPlatformObsSettings )
    KMLAddObsHashEntry( 'water_pressure', $strDBDate, $pcat_pressure, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_depth', $strDBDate, ($pcat_pressure * 0.98), 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_conductivity', $strDBDate, $pcat_conductivity, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_temperature', $strDBDate, $pcat_temp, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'salinity', $strDBDate, $pcat_salinity, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_pressure', $strDBDate, $fcat_pressure, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_depth', $strDBDate, ($fcat_pressure * 0.98), 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_conductivity', $strDBDate, $fcat_conductivity, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_temperature', $strDBDate, $fcat_temp, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'salinity', $strDBDate, $fcat_salinity, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );


    KMLAddObsHashEntry( 'voltage', $strDBDate, $fcat_voltage, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    my $chlorophyll = undef;
    if( $fcat_voltage ne 'NULL')
    {
      if ($buoy_id eq 'buoy2') {
              #$chlorophyll = 12.66*$fcat_voltage; #FIX
              #$chlorophyll = 14.1*$fcat_voltage+0.061; #FIX 06/05/11
              $chlorophyll = 14.0*$fcat_voltage+0.060; #FIX 07/12/05
      }
      elsif ($buoy_id eq 'buoy4') {
              #$chlorophyll = 14.1*$fcat_voltage;  #FIX
              #$chlorophyll = 14.0*$fcat_voltage+0.059;  #FIX 06/05/11
              #$chlorophyll = 14.7*$fcat_voltage+0.052;  #FIX 07/01/30
              #$chlorophyll = 14.8*$fcat_voltage+0.053;  #FIX 07/04/30
              $chlorophyll = 15.2*$fcat_voltage+0.062;  #FIX 07/11/07
      }
      elsif ($buoy_id eq 'buoy6') {
              #$chlorophyll = 14.00*$fcat_voltage;  #FIX
              #$chlorophyll = 14.9*$fcat_voltage+0.053;  #FIX
              $chlorophyll = 15.4*$fcat_voltage+0.056; #FIX 07/12/05
      }				
  
      elsif ($buoy_id eq 'buoy3') {
              $chlorophyll = 12.66*$fcat_voltage;
      }
      elsif ($buoy_id eq 'buoy5') {
              #$chlorophyll = 14.40*$fcat_voltage;
              #$chlorophyll = 12.66*$fcat_voltage; #as of last deployment
              $chlorophyll = 14.10*$fcat_voltage; #as of deployment 05/08/13
      }
      elsif ($buoy_id eq 'buoy7') {
              #$chlorophyll = 12.84*$fcat_voltage;
              $chlorophyll = 14.00*$fcat_voltage; #as of deployment 05/07/27
      }
    }
    KMLAddObsHashEntry( 'chl_concentration', $strDBDate, $chlorophyll, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );

    # The current_speed is natively mm_s-1 however we want to store it in cm_s-1, so we convert.
    GetObsData( \%PlatformIDHash, 'current_speed', 1, \%PlatformObsSettings );
    my $strCurrentUnits = %PlatformObsSettings->{UoM};
    my $ConvertedValue = MeasurementConvert($adcp_bin1_velocity, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $ConvertedValue, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin1_direction, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin2_velocity, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin2_direction, 2, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin3_velocity, 3, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin3_direction, 3, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin4_velocity, 4, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin4_direction, 4, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin5_velocity, 5, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin5_direction, 5, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin6_velocity, 6, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin6_direction, 6, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin7_velocity, 7, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin7_direction, 7, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin8_velocity, 8, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin8_direction, 8, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin9_velocity, 9, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin9_direction, 9, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    
    $ConvertedValue = MeasurementConvert($ConvertedValue, 'mm_s-1', $strCurrentUnits, $XMLControlFile );
    KMLAddObsHashEntry( 'current_speed', $strDBDate, $adcp_bin10_velocity, 10, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'current_to_direction', $strDBDate, $adcp_bin10_direction, 10, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );

    #Weather pack.
    KMLAddObsHashEntry( 'wind_speed', $strDBDate, $wxpak_wind_speed, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'wind_from_direction', $strDBDate, $wxpak_wind_direction, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'wind_gust', $strDBDate, $wxpak_wind_gust, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'air_temperature', $strDBDate, $wxpak_air_temp, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'relative_humidity', $strDBDate, $wxpak_humidity, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'air_pressure', $strDBDate, $wxpak_air_pressure, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'solar_radiation', $strDBDate, $wxpak_solar, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'visibility', $strDBDate, $buoy_visibility, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );

    
    my $strXMLPath = ''; 
    $strPlatformID =~ s/\./-/g; 
    if( !MICROSOFT_PLATFORM )
    {
      my $strDate = `date  +%Y-%m-%dT%H-%M-%S`;
      chomp( $strDate );      
      $strXMLPath = "$strKMLDir/$strPlatformID-$strDate.kml";
    }
    else
    {
      my $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y-%m-%dT%H-%M-%S`;
      chomp( $strDate );      
      $strXMLPath = "$strKMLDir\\$strPlatformID-$strDate.xml"; 
    }

    BuildKMLFile( \%ObsHash, $strXMLPath, $strControlFile );
    	
	}  #foreach $record (<BUOY_FILE) 

	close(BUOY_FILE);

}
elsif (($currentFile =~ /WLS1/) || ($currentFile =~ /WLS2/) || ($currentFile =~ /WLS3/)) 
{
	my $station_id;
	if ($currentFile =~ /WLS1/) { $station_id = 'WLS1'; }
	if ($currentFile =~ /WLS2/) { $station_id = 'WLS2'; }
	if ($currentFile =~ /WLS3/) { $station_id = 'WLS3'; }	

	print "$currentFile processed\n";

	open(BUOY_FILE, $currentPath.$currentFile)
	or die "Can't find file $currentPath$currentFile: $!\n";

  my %PlatformIDHash;
  LoadPlatformControlFile($strControlFile, \%PlatformIDHash, $station_id);

	#the following code reads 0,1,many lines of buoy updates, ignoring lines starting with # and partial lines
	foreach my $line_record (<BUOY_FILE>) {

		#ignore lines which start with '#'
		if (substr($line_record,0,1) eq '#') {next};	

		my @record = split(/\,/,$line_record);

		#assign record array fields to variables
	
		#note this is cron job time, not datalogger time
		my $measurement_timestamp_dbformat = substr(@record[1],5,2)."/".substr(@record[1],8,2)."/".substr(@record[1],2,2)." ".substr(@record[1],11,8);
		#print $measurement_timestamp_dbformat."\n";
		if ($measurement_timestamp_dbformat eq '') {$measurement_timestamp_dbformat = 'NULL'};

		#####
		my $water_level_metric = 'NULL';
		my $water_level = 'NULL';

		if ( !(@record[2] eq '') ) {
			$water_level_metric = @record[2];
			$water_level = sprintf("%.1f", @record[2]*3.28);
		}

		my $water_level_timestamp = wls_timestamp_format(@record[3]);

		#####
		my $water_temperature = 'NULL';
		my $water_temperature_celcius = 'NULL';

		if ( !(@record[4] eq '') ) {
			$water_temperature = sprintf("%.1f", @record[4]*9/5+32);
			$water_temperature_celcius = sprintf("%.1f", @record[4]);			
		}

		my $water_temperature_timestamp = wls_timestamp_format(@record[5]);

		#####
		my $wind_speed_mps = 'NULL';
		my $wind_speed = 'NULL';
		my $wind_speed_display = 'CALM';

		if ( !((@record[6] eq '') or (@record[6] == 0)) ) {
			$wind_speed_mps = @record[6];
			$wind_speed = sprintf("%.1f", @record[6]*1.9438);
		}

		#####
		my $wind_direction = 'NULL';

		if ( !(@record[7] eq '') ) {
			$wind_direction = sprintf("%d", @record[7]);
		}

		#####
		my $wind_gust_mps = 'NULL';
		my $wind_gust = 'NULL';
		my $wind_gust_display = 'CALM';

		if ( !((@record[8] eq '') or (@record[8] == 0)) ) {
			$wind_gust_mps = @record[8];
			$wind_gust = sprintf("%.1f", @record[8]*1.9438);
		}

		my $wind_timestamp = wls_timestamp_format(@record[9]);

		if ($wind_speed ne 'NULL') {			
                	$wind_speed_display = "from ".conv_degrees_to_compass($wind_direction)." (".$wind_direction." deg) (".$wind_speed." knots)";
		}
		if ($wind_gust ne 'NULL') {
			$wind_gust_display = $wind_gust." knots";
		} 

		#####
		my $air_temperature = 'NULL';
		my $air_temperature_celcius = 'NULL';

		#if ($station_id ne 'WLS3') { #FIX when SUN1 air temp sensor working again
		if ( !(@record[10] eq '') ) {
			$air_temperature = sprintf("%.1f", @record[10]*9/5+32);
			$air_temperature_celcius = sprintf("%.1f", @record[10]);
		}
		#}		

		my $air_temperature_timestamp = wls_timestamp_format(@record[11]);

		#####
		my $air_pressure = 'NULL';

		if ( !((@record[12] eq '') or (@record[12] == 0)) ) {
			$air_pressure = sprintf("%d", @record[12]);
		}

		my $air_pressure_timestamp = wls_timestamp_format(@record[13]);

                #####
                my $humidity = 'NULL';

                if ( !((@record[14] eq '') or (@record[14] == 0)) ) {
                        $humidity = sprintf("%d", @record[14]);
                }

    #Format a DB friendly DB date-time.
    my $strDBDate = @record[1];
    #$strDBDate ~= s/ /T;
    #Find the platform ID and URL.
    my $strPlatformID = $station_id;

    my $strPlatformURL = '';
    my $rPlatformIDHash = \%PlatformIDHash;  
    my %ObsHash;
    my $rObsHash = \%ObsHash;

    my %PlatformObsSettings;

    GetPlatformData( \%PlatformIDHash, $station_id, \%PlatformObsSettings );
    $strPlatformID = %PlatformObsSettings->{PlatformID};

    KMLAddPlatformHashEntry( %PlatformObsSettings->{PlatformID}, %PlatformObsSettings->{PlatformURL}, '', '', $rObsHash );
    #( $strObsName, $strDate, $Value, $SensorSOrder, $rObsHash, $rPlatformControlFileInfo, $rPlatformObsSettings )
    KMLAddObsHashEntry( 'water_level', $strDBDate, $water_level, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'wind_speed', $strDBDate, $wind_speed, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'wind_from_direction', $strDBDate, $wind_direction, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'wind_gust', $strDBDate, $wind_gust, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'air_temperature', $strDBDate, $air_temperature, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'air_pressure', $strDBDate, $water_level, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
    KMLAddObsHashEntry( 'water_temperature', $strDBDate, $water_temperature, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );

    my $strXMLPath = ''; 
    $strPlatformID =~ s/\./-/g; 
    if( !MICROSOFT_PLATFORM )
    {
      my $strDate = `date  +%Y-%m-%dT%H-%M-%S`;
      chomp( $strDate );      
      $strXMLPath = "./$strPlatformID-$strDate.kml";
    }
    else
    {
      my $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y-%m-%dT%H-%M-%S`;
      chomp( $strDate );      
      $strXMLPath = "C:\\Documents and Settings\\dramage\\workspace\\TelemetryDataToObsKML\\$strPlatformID-$strDate.xml"; 
    }

    BuildKMLFile( \%ObsHash, $strXMLPath, $strControlFile );

  }
  
}
	
##################################################################################
##################################################################################

sub get_local_time
{

my ($date, $time_shift) = @_;

#print "date:".$date."\n";
#print "time_shift:".$time_shift."\n";

my ($month, $day, $year, $hour, $minute, $second) = split(/[\/ :]/,$date);

my $time_subtract = -1*$time_shift*3600; #time_shift negative west of gmt
#print "time_subtract:".$time_subtract."\n";

my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);

if (!$isdst) {
	$time_subtract = $time_subtract + 3600; #subtract one more hour
}
#print "time_subtract:".$time_subtract."\n";

my $date_converted_1;
my $date_converted_2;
my $date_converted_3;
if( !MICROSOFT_PLATFORM )
{
 $date_converted_1 = `date --date='20$year-$month-$day $hour:$minute:$second +0000' +%s` - $time_subtract;
 $date_converted_2 = `date -u -d '1970-01-01 $date_converted_1 seconds' +"%m/%d %r"`;
}
else
{
 $date_converted_1 = `\\UnixUtils\\usr\\local\\wbin\\date.exe --date=\"20$year-$month-$day $hour:$minute:$second +0000\" +%s` - $time_subtract;
 $date_converted_2 = `\\UnixUtils\\usr\\local\\wbin\\date.exe -u -d \"1970-01-01 $date_converted_1 seconds\" +"%m/%d %r"`;
}
 $date_converted_3 = substr($date_converted_2,0,11).substr($date_converted_2,14,3);

#print "date_converted_3:".$date_converted_3."\n";

return $date_converted_3;

}

sub removeTerminationData
{

my @init_record = @_;

#@record = (); 	#clear the array
my @record; 	#a better way of making sure the record is cleared each time

foreach my $field (@init_record) {
	if ($field =~ /termination/) {
		#print "yes\n";
		last;
	}
	else {
		#print $field."\n";
		push(@record, $field); 
	}
}

return @record;
}

sub convertTo360
{
my $i = @_[0];

# added here to convert from polar to compass coordinate.
$i=90-$i;

#this just converts negative direction values to their positive counterpart
if ( $i < 0 ) {
        $i = 360 + $i ;
}       
#direction values to the range of 0~360
if ( $i > 360 ) { 
        $i = $i-360 ;
}       

return $i
}


sub test_array_for_string {

my ($test_array, $test_value) = @_;

my $index;
my $i = 0;
foreach my $element (@{$test_array}) {
        if ($element =~ /$test_value/) {
                $index = $i;
        }
        $i++;
}

return $index;

}

sub get_mag_and_dir {

my ($x, $y, $scale) = @_;
my ($mag,$angle);

$mag = sprintf("%d",$scale*sqrt($x*$x+$y*$y));
#print "$mag\n";

$angle = atan2($y,$x);
$angle = sprintf("%d",180/3.1416*$angle);

#only return positive degrees
if ($angle < 0) { $angle = 360 + $angle; }

my @result = ($mag, $angle);

return (@result);

}



sub wls_timestamp_format {

	my $input_date = shift;

	my $str_month = substr($input_date,0,2);   
	$str_month =~ s/^0+//;

	my $str_day = substr($input_date,3,2);
	$str_day =~ s/^0+//;

	my $str_time = substr($input_date,6,8);
	$str_time =~ s/^0+//;

	return $str_month."/".$str_day." ".$str_time;
}
sub conv_degrees_to_compass{
    my $degrees = shift;
    
    if ($degrees eq 'NULL') { return $degrees; }
    
    my @compass = qw(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW);

    $degrees = ($degrees + 22.5) / 22.5;
    $degrees -= .5;
    my $quad = $degrees % 16;

    return $compass[$quad];
}

