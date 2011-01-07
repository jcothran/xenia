#!/usr/bin/perl
use strict;
use XML::LibXML;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new((timeout => 100));

#use HTTP::Date;

#the next sections jump between outputting the kml file and querying the repeating xml elements for subtitution in the corresponding file elements.

##header section


my $output_name = $ARGV[0];
my $output_base_dir = $ARGV[1];
my $platform_list = $ARGV[2];


#normally kml tag would include xmlns like following, but xmlns has processing problem issues with XML::LibXML - <kml xmlns="http://earth.google.com/kml/2.1">
my $xml_content = <<"END_OF_FILE";
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns:kml="http://earth.google.com/kml/2.1" xmlns:obsList="http://carocoops.org/obskml/1.0.0/obskml_simple.xsd">
<!-- JTC - please forgive any unorthodoxy in the namespace declaration above, there's a bug with the perl XML::XPath package I'm using where all xmlns must be declared in the root element using prefix notation -->
<Document>
<name>Near Real-Time Water Quality Data published by SEACOOS</name>
<open>1</open>
END_OF_FILE

##repeating elements section

my $xp = XML::LibXML->new->parse_file($platform_list);
my $operator_url = 'http://waterdata.usgs.gov/nwis/rt';

my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);

my $time_zone;                
if ($isdst) { $time_zone = '-04:00'; } else { $time_zone = '-05:00'; } 

####

my @url_list = (
#SC
'http://waterdata.usgs.gov/sc/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=02110815,02176585,321603080432202,02176603,02176611,02176635,02176589,02176640,02172020,02172050,021720698,02172080,02172002,02172040,02175000,02172053,021720677,021720709,02171639,021720710'
,'http://waterdata.usgs.gov/sc/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=02172084,02110760,02110805,02110809,02135200,02110777,02110704,02110802,02110770,02110755,021108125,02110725'
#GA
,'http://waterdata.usgs.gov/ga/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=022035975,02198840'
#NC
,'http://waterdata.usgs.gov/nc/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=0208455155,0208455560,02092162,0209265810,0208453300,0208114150,0209262905,02084472,02081022,02081094,02108690'
#FL
,'http://waterdata.usgs.gov/fl/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=294213081345300,02248380,02297100,02301721,02310678,02301638,02301988,02306774,023000095,02312000,02300021,264053081572501,02326550,02310663,023060003'
,'http://waterdata.usgs.gov/fl/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=02323592,02300009,02310650,02310545,02306000,02304510,02301718,02313000,022908295'
);

foreach my $url (@url_list) {

# get the page
#thought about using the multi-station request, but there's a 20 station limit which creates some setup work on the request end - just getting all for one state at a time for now
#my $url = "http://waterdata.usgs.gov/sc/nwis/current?result_md=1&result_md_minutes=60&format=rdb&multiple_site_no=02110815,021720698,02176603";
#my $url = "http://waterdata.usgs.gov/sc/nwis/current?result_md=1&result_md_minutes=60&format=rdb";

print "$url\n";
my $response = $ua->get($url);

# die If we timeout, but keep going if we 404
if (!$response->is_success && !($response->status_line =~ /404/)) {
  die $response->status_line.' : '.$url;
}

foreach my $organization ($xp->findnodes('//organization')) {
        my $organization_name = $organization->find('short_name');
	print "organization_name:$organization_name\n"; #debug

	my $depth = '';

	my @d = sort split(/\n/,$response->content);

	#initialize vars
	my $metadata_content = '';	
	my $desc = '';	
	my $previous_platform_name = '';
	my $date_label = '';
	my $previous_date = '';
	my $previous_date_label = '';
	my ($usgs,$platform_name,$dd_nu,$parameter_code,$date,$tz,$measurement);

	my ($platform_type,$fixed_longitude,$fixed_latitude);
        my ($platform_label,$platform_url,$description);        

	foreach my $l (@d) {
	  if ($l =~ /^USGS/) {
	    ($usgs,$platform_name,$dd_nu,$parameter_code,$date,$tz,$measurement) = split(/\t/,$l);
   	    #print "$platform_name $date $measurement\n";
	
	    $date_label = $date;
	    $date =~ s/ /T/g;
	    #$date .= ":00-05";
	    #$date .= "Z";
	    $date .= $time_zone;

	############################
	
	#check to see if platform is new or platform or date have changed
	#print "$platform_name:$previous_platform_name:$date_label:$previous_date_label\n";
	if (($platform_name ne $previous_platform_name) || ($date_label ne $previous_date_label) || ($previous_platform_name eq '')) {

		if ($previous_platform_name ne '') {
		#print out footer part of earlier platform 
	        $metadata_content .= "</obsList></Metadata>\n";

       		$xml_content .= $metadata_content;

                #print "$platform_label $previous_date_label<br />$desc</table></description>\n";
 	        $xml_content .= <<"END_OF_FILE";
                <name>$platform_label</name>
                <description><![CDATA[Date: $previous_date_label<br />Description: $description<br /><a href="$operator_url">operatorURL</a><br /><a href="$platform_url">PlatformURL</a><br />$desc</table>]]></description>
                <Point>
                <coordinates>$fixed_longitude,$fixed_latitude</coordinates>
                </Point>
                <TimeStamp><when>$previous_date</when></TimeStamp>
                </Placemark>
END_OF_FILE
		}

	    #skip platform if not on checklist
            my $found_platform = 0;
            foreach my $platform ($organization->findnodes('//platform[@id="'.$platform_name.'"]')) {
                $found_platform = 1;
                $fixed_longitude = $platform->find('fixed_longitude');
                $fixed_latitude = $platform->find('fixed_latitude');
                $platform_type = $platform->find('type_name');
                $description = $platform->find('description');
                #print "platform_type:$platform_type\n"; #debug
            }
            #if ($found_platform == 0) { print "not found platform: $platform_name\n"; }
            if ($found_platform == 0) { $previous_platform_name = ''; $previous_date = ''; $previous_date_label = ''; next; }

	    #initialize new placemark,metadata,table
	    $platform_label = $organization_name.'.'.$platform_name.'.'.$platform_type;
            $platform_url = "http://waterdata.usgs.gov/nwis/uv/?site_no=$platform_name";

	    $xml_content .= "<Placemark id=\"$platform_label\">";
	    $metadata_content = "<Metadata><obsList>\n";
	    $metadata_content .= "<operatorURL>$operator_url</operatorURL><platformURL>$platform_url</platformURL><platformDescription>$description</platformDescription>\n";
	    $desc = "<table border=\"1\">";
	}

	#print "$platform_name:$previous_platform_name:$date_label:$previous_date_label\n";
	$previous_platform_name = $platform_name;
	$previous_date = $date;
	$previous_date_label = $date_label;

	############################

	my ($obsType,$uomType,$found,$conversion) = split(/\:/,&get_observed_property($parameter_code));
	if ($found eq 'found') {

	if ($conversion) {
		$conversion =~ s/var1/$measurement/g;
		#print ":conv:$conversion:\n";
		#note the use of eval and that we're trusting the input from the source data here and considering potential security issues
		$measurement = eval "sprintf($conversion)";
		#print ":$measurement:\n";
	}

	$metadata_content .= <<"END_OF_FILE";
	<obs>
		<obsType>$obsType</obsType>
		<uomType>$uomType</uomType>
		<value>$measurement</value>
		<elev>$depth</elev>
	</obs>
END_OF_FILE

	  $desc .= "<tr><td>$obsType</td><td>$measurement</td><td>$uomType</td></tr>";
	}
	else { print "notfound:$obsType:$uomType\n"; }

	  }  #if USGS
	} #foreach line 

                ############################
                #last line

                if ($previous_platform_name ne '') {
		#print out footer part of earlier platform 
		#print "ll:$platform_name:$previous_platform_name:$date_label:$previous_date_label\n";

                $metadata_content .= "</obsList></Metadata>\n";

                $xml_content .= $metadata_content;

                #print "$platform_label $previous_date_label<br />$desc</table></description>\n";
                $xml_content .= <<"END_OF_FILE";
                <name>$platform_label</name>
                <description>Date: $previous_date_label<br />Description: $description<br /><a href="$operator_url">operatorURL</a><a href="$platform_url">PlatformURL</a><br />$desc</table></description>
                <Point>
                <coordinates>$fixed_longitude,$fixed_latitude</coordinates>
                </Point>
                <TimeStamp><when>$previous_date</when></TimeStamp>
                </Placemark>
END_OF_FILE
		}
                ############################


} #foreach organization
} #foreach url

##footer section

$xml_content .= <<"END_OF_FILE";
</Document>
</kml>
END_OF_FILE

my $current_date = `date -u +"%Y%m%d%H%M%S"`;
chomp($current_date);

#my $output_name = 'wq';
##write file

#open (FILE_XML,">/var/www/html/obskml/feeds/$output_name/archive/$output_name\_metadata_$current_date.kml");
my $outfile_name = "$output_base_dir/$output_name/$output_name\_metadata_$current_date.kml";
open (FILE_XML,">$outfile_name");
print FILE_XML $xml_content;
close (FILE_XML);

##zip file

#`cd /var/www/html/obskml/feeds/$output_name/archive ; zip -m $output_name\_metadata_$current_date.kmz $output_name\_metadata_$current_date.kml`;
`cd $output_base_dir/$output_name ; zip -m $output_name\_metadata_$current_date.kmz $output_name\_metadata_$current_date.kml`;

##copy file to latest
#`cp -f /var/www/html/obskml/feeds/$output_name/archive/$output_name\_metadata_$current_date.kmz /var/www/html/obskml/feeds/$output_name/$output_name\_metadata_latest.kmz`;
`cp -f $output_base_dir/$output_name/$output_name\_metadata_$current_date.kmz $output_base_dir/$output_name/$output_name\_metadata_latest.kmz`;

exit 0;

###########################################

sub get_observed_property {

my $string = shift;

if ($string eq '00300') { $string = 'dissolved_oxygen:mg_L-1:found'}
elsif ($string eq '00301') { $string = 'dissolved_oxygen:percent_saturation:found'}
elsif ($string eq '00010') { $string = 'water_temperature:celsius:found'}
elsif ($string eq '00011') { $string = 'water_temperature:celsius:found:"%.2f",(var1-32)*5/9'} #convert fahrenheit to celsius
elsif ($string eq '00095') { $string = 'water_conductivity:mS_cm-1:found'}
elsif ($string eq '00076') { $string = 'turbidity:ntu:found'}
elsif ($string eq '63680') { $string = 'turbidity:ntu:found'}  #actually units 'nu'
elsif ($string eq '00065') { $string = 'gage_height:m:found:"%.2f",var1*.3048'} #convert feet to meters
elsif ($string eq '00400') { $string = 'ph:units:found'}

elsif ($string eq '00055') { $string = 'stream_velocity:ft_s-1:found'}
elsif ($string eq '00060') { $string = 'discharge:cubic_ft_s-1:found'}

elsif ($string eq '00025') { $string = 'air_pressure:millibar:found:"%.2f",var1*1.333224'} #convert mmHg to mb
elsif ($string eq '00052') { $string = 'relative_humidity:percent:found'}
elsif ($string eq '00020') { $string = 'air_temperature:celsius:found'}
elsif ($string eq '00021') { $string = 'air_temperature:celsius:found:"%.2f",(var1-32)*5/9'} #convert fahrenheit to celsius
elsif ($string eq '00035') { $string = 'wind_speed:m_s-1:found:"%.2f",var1*0.447'} #convert mph to m_s-1
elsif ($string eq '00036') { $string = 'wind_from_direction:degrees_true:found'}
elsif ($string eq '62608') { $string = 'solar_radiation:watts_per_m^2:found'}
elsif ($string eq '00096') { $string = 'salinity:mg_per_milliliter:found'}
elsif ($string eq '00480') { $string = 'salinity:psu:found'}  #actual units 'ppt'

else { $string .= '::notfound'; }

#print $string."\n";
return $string;


=comment
http://nwis.waterdata.usgs.gov/usa/nwis/pmcodes?pm_group=ALL&pm_search=&format=html_table&show=parameter_cd&show=parameter_group_nm&show=parameter_nm

 00090	physical property	Oxidation reduction potential, millivolts
 72020	physical property	Elevation above NGVD 1929, feet 
 74207	physical property	Moisture content, soil, volumetric, percent of total volume 

 00025	physical property	Barometric pressure, millimeters of mercury
 00052	physical property	Relative humidity, percent
 00020	physical property	Temperature, air, degrees Celsius 
 00021	physical property	Temperature, air, degrees Fahrenheit
 00035	physical property	Wind speed, miles per hour
 00036	physical property	Wind direction, degrees clockwise from true north
 62608	physical property	Total solar radiation (direct + diffuse radiation on a horizontal surface), watts per square meter 
 00096	physical property	Salinity, water, unfiltered, milligrams per milliliter at 25 degrees Celsius
 
 72019	physical property	Depth to water level, feet below land surface
 00062	physical property	Elevation of reservoir water surface above datum, feet
=cut

}

