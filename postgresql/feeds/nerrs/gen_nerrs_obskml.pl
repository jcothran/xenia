#JTC gen_nerrs_obskml.pl
#!/usr/bin/perl

use strict;
use XML::LibXML;

########################################################
####config specific

#note $m_date is particular to the file setup
#note the @platform and @obs which are specific to the platform_type and setup

####

my $output_name = $ARGV[0];
my $output_base_dir = $ARGV[1];
my $platform_list = $ARGV[2];
my $input_file_dir = $ARGV[3];

#daylight savings time consideration
my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);

##header section

#normally kml tag would include xmlns like following, but xmlns has processing problem issues with XML::LibXML - <kml xmlns="http://earth.google.com/kml/2.1">
my $kml_content = <<"END_OF_FILE";
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns:kml="http://earth.google.com/kml/2.1" xmlns:obsList="http://carocoops.org/obskml/1.0.0/obskml_simple.xsd">
<!-- JTC - please forgive any unorthodoxy in the namespace declaration above, there's a bug with the perl XML::XPath package I'm using where all xmlns must be declared in the root element using prefix notation -->
<Document>
<name>Near Real-Time Water Quality Data published by SEACOOS</name>
<open>1</open>
END_OF_FILE

########################################################
#process platforms same one by one, xml->obskml

#my $xp_platform = XML::LibXML->new->parse_file('nerrs_platform_list.xml');
my $xp_platform = XML::LibXML->new->parse_file($platform_list);

foreach my $platform ($xp_platform->findnodes('//platform')) {

  my $platform_type = sprintf("%s",$platform->find('type_name'));
  my $platform_name = $platform->find('short_name');
  my $platform_description = $platform->find('description');
  #nerrs doesn't take daylight saving time into account
  #my $time_add = sprintf("%d", $platform->find('time_add')) - $isdst;
  my $time_add = sprintf("%d", $platform->find('time_add'));
  my $m_lon = $platform->find('fixed_longitude');
  my $m_lat = $platform->find('fixed_latitude');

  my $platform_handle = 'nerrs.'.$platform_name.'.'.$platform_type ;

  #my $filename = '/usr2/prod/buoys/perl/xenia/tmp/cdmo_'.$platform_name;
  my $filename = $input_file_dir . '/cdmo_' . $platform_name;

  print $filename.".xml\n";

  ########################################################
  #process the clean xml document into SQL statements

  my $xp = XML::LibXML->new->parse_file($filename.'.xml');
  my $operator_url = 'http://cdmo.baruch.sc.edu';
  my $platform_url = 'http://cdmo.baruch.sc.edu/QueryPages/googlemap.cfm';


  my $line_count = 0;
  foreach my $row ($xp->findnodes('//data/r')) {
	$line_count++;
	if ($line_count < 2) { next; }

	print "###################\n";

        #possible vars used
        my @obs = ();
        my $m_date;
        my $frequency;
	my ($row_id,$historical);
        my ($air_temp,$air_temp_qc,$rh,$rh_qc,$air_pressure,$air_pressure_qc,$wind_speed,$wind_speed_qc,$wind_from_direction,$wind_from_direction_qc,$precipitation,$precipitation_qc,$solar,$solar_qc);
        my ($water_temp,$water_temp_qc,$water_conductivity,$water_conductivity_qc,$salinity,$salinity_qc,$do_percent,$do_percent_qc,$do_mgl,$do_mgl_qc,$water_level,$water_level_qc,$ph,$ph_qc,$turbidity,$turbidity_qc);

	#push attribute values into array and then array into correct variables
	my @values = ();
	foreach my $element ($row->findnodes('c/@v')) 
  { 
    push (@values, $element->string_value()); 
  }

  ##file types
  if ($platform_type eq 'met') 
  {
    ($row_id,$historical,$m_date,$air_temp,$air_temp_qc,$rh,$rh_qc,$air_pressure,$air_pressure_qc,$wind_speed,$wind_speed_qc,$wind_from_direction,$wind_from_direction_qc,$precipitation,$precipitation_qc,$solar,$solar_qc) = @values;
    print "Air Temp: $air_temp\n";
    @obs = (1,$air_temp,$air_temp_qc,2,$rh,$rh_qc,3,$air_pressure,$air_pressure_qc,4,$wind_speed,$wind_speed_qc,5,$wind_from_direction,$wind_from_direction_qc,6,$precipitation,$precipitation_qc,7,$solar,$solar_qc);
  }
  if ($platform_type eq 'metf') 
  {
    ($row_id,$historical,$frequency,$m_date,$air_temp,$air_temp_qc,$rh,$rh_qc,$air_pressure,$air_pressure_qc,$wind_speed,$wind_speed_qc,$wind_from_direction,$wind_from_direction_qc,$precipitation,$precipitation_qc,$solar,$solar_qc) = @values;
    print "Air Temp: $air_temp\n";
    @obs = (1,$air_temp,$air_temp_qc,2,$rh,$rh_qc,3,$air_pressure,$air_pressure_qc,4,$wind_speed,$wind_speed_qc,5,$wind_from_direction,$wind_from_direction_qc,6,$precipitation,$precipitation_qc,7,$solar,$solar_qc);
  }
  if ($platform_type eq 'wq') 
  {
    ($row_id,$historical,$m_date,$water_temp,$water_temp_qc,$water_conductivity,$water_conductivity_qc,$salinity,$salinity_qc,$do_percent,$do_percent_qc,$do_mgl,$do_mgl_qc,$water_level,$water_level_qc,$ph,$ph_qc,$turbidity,$turbidity_qc) = @values;
    print "Water Temp: $water_temp\n";
    @obs = (8,$water_temp,$water_temp_qc,9,$water_conductivity,$water_conductivity_qc,10,$salinity,$salinity_qc,11,$do_percent,$do_percent_qc,12,$do_mgl,$do_mgl_qc,13,$water_level,$water_level_qc,14,$ph,$ph_qc,15,$turbidity,$turbidity_qc);
  }

	#don't include old rows(historical tag)
	if ($historical eq '1') 
  { 
    next; 
  }

  #my $date_label = '20'.substr($m_date,6,2).'-'.substr($m_date,0,2).'-'.substr($m_date,3,2).' '.substr($m_date,9,5).':00';
  #my $timestamp = '20'.substr($m_date,6,2).'-'.substr($m_date,0,2).'-'.substr($m_date,3,2).'T'.substr($m_date,9,5).':00-'.substr("00".$time_add, -2).':00';
  #date format like: 03/23/2010 08:30
  my $date_label = substr($m_date,6,4).'-'.substr($m_date,0,2).'-'.substr($m_date,3,2).' '.substr($m_date,11,5).':00';
  my $timestamp = substr($m_date,6,4).'-'.substr($m_date,0,2).'-'.substr($m_date,3,2).'T'.substr($m_date,11,5).':00-'.substr("00".$time_add, -2).':00';

  print "$m_date $timestamp\n";

  $kml_content .= "<Placemark id=\"$platform_handle\">";
  my $metadata_content = "<Metadata><obsList>\n";
  $metadata_content .= "<operatorURL>$operator_url</operatorURL><platformURL>$platform_url</platformURL><platformDescription>$platform_description</platformDescription>\n";
  my $desc = "<table border=\"1\">";

  while (@obs) 
  {

    my $parameter_code = shift(@obs);
    my $m_value = shift(@obs);
    my $qc_level = shift(@obs);
    print( "parameter_code: $parameter_code m_value: $m_value qc_level: $qc_level\n");
    my ($obsType,$uomType,$found,$conversion) = split(/\:/,&get_observed_property($parameter_code));
    if ($found eq 'found') 
    {
          
      if ($conversion) {
            $conversion =~ s/var1/$m_value/g;
            #print ":conv:$conversion:\n";
            #note the use of eval and that we're trusting the input from the source data here and considering potential security issues
            $m_value = eval "sprintf($conversion)";
            #print ":$m_value:\n";
      }

      $metadata_content .= <<"END_OF_FILE";
      <obs>
              <obsType>$obsType</obsType>
              <uomType>$uomType</uomType>
              <value>$m_value</value>
              <elev></elev>
      </obs>
END_OF_FILE

      $desc .= "<tr><td>$obsType</td><td>$m_value</td><td>$uomType</td></tr>";
    }
    else 
    { 
      print "notfound:$obsType:$uomType\n"; 
    }

  } #while @obs

  $metadata_content .= "</obsList></Metadata>\n";
  #print("metadata_content: $metadata_content\n");
  $kml_content .= $metadata_content;

  $kml_content .= <<"END_OF_FILE";
  <name>$platform_handle</name>
  <description><![CDATA[Date: $date_label<br />Description: $platform_description<br /><a href="$operator_url">operatorURL</a><br /><a href="$platform_url">PlatformURL</a><br />$desc</table>]]></description>
  <Point>
  <coordinates>$m_lon,$m_lat</coordinates>
  </Point>
  <TimeStamp><when>$timestamp</when></TimeStamp>
  </Placemark>
END_OF_FILE

  } #foreach $row of data

}

$kml_content .= <<"END_OF_FILE";
</Document>
</kml>
END_OF_FILE

my $current_date = `date -u +"%Y%m%d%H%M%S"`;
chomp($current_date);

my $output_name = 'nerrs';
##write file
#open (KML_OUT,">$kml_out");
#open (FILE_KML,">/var/www/html/obskml/feeds/$output_name/archive/$output_name\_metadata_$current_date.kml");
my $outfile_name = "$output_base_dir/$output_name/$output_name\_metadata_$current_date.kml";
open (FILE_KML,">$outfile_name")  or die("Failed to open file $outfile_name");

print FILE_KML $kml_content;
close (FILE_KML);

##zip file
#`cd /var/www/html/obskml/feeds/$output_name/archive ; zip -m $output_name\_metadata_$current_date.kmz $output_name\_metadata_$current_date.kml`;
`cd $output_base_dir/$output_name ; zip -m $output_name\_metadata_$current_date.kmz $output_name\_metadata_$current_date.kml`;

##copy file to latest
#`cp -f /var/www/html/obskml/feeds/$output_name/archive/$output_name\_metadata_$current_date.kmz /var/www/html/obskml/feeds/$output_name/$output_name\_metadata_latest.kmz`;
`cp -f $output_base_dir/$output_name/$output_name\_metadata_$current_date.kmz $output_base_dir/$output_name/$output_name\_metadata_latest.kmz`;
exit 0;

########################################################

sub get_observed_property {

my $string = shift;

#met
if ($string eq '1') { $string = 'air_temperature:celsius:found'}
elsif ($string eq '2') { $string = 'relative_humidity:percent:found'}
elsif ($string eq '3') { $string = 'air_pressure:millibar:found'}
elsif ($string eq '4') { $string = 'wind_speed:m_s-1:found'}
elsif ($string eq '5') { $string = 'wind_from_direction:degrees_true:found'}
elsif ($string eq '6') { $string = 'precipitation:millimeter:found'}
elsif ($string eq '7') { $string = 'solar_radiation:millimoles_per_m^2:found'}

#wq
elsif ($string eq '8') { $string = 'water_temperature:celsius:found'}
elsif ($string eq '9') { $string = 'water_conductivity:mS_cm-1:found'}
elsif ($string eq '10') { $string = 'salinity:psu:found'}  #actual units 'ppt'
elsif ($string eq '11') { $string = 'dissolved_oxygen:percent_saturation:found'}
elsif ($string eq '12') { $string = 'dissolved_oxygen:mg_L-1:found'}
elsif ($string eq '13') { $string = 'gage_height:m:found'}
elsif ($string eq '14') { $string = 'ph:units:found'}
elsif ($string eq '15') { $string = 'turbidity:ntu:found'}  #actually units 'nu'

else { $string .= '::notfound'; }

#print $string."\n";
return $string;
}

