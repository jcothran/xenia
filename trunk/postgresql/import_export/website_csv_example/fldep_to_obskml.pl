#!/usr/bin/perl
use strict;
use LWP::Simple;

#get timezone EST/EDT
#my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);
#$temp_year = 1900+$temp_year; 
#my $time_zone = '-05';                
#if ($isdst) { $time_zone = '-04'; } else { $time_zone = '-05'; } 
#print "year:$temp_year $time_zone\n";

my $time_zone = '-00';                

#####
my $obs_list;
my $obs_url;
my $datetime; 
my $placemark_list;
my $org_name = 'Near Real-Time Data published by FLDEP(Florida Department of Environmental Protection)'; #custom
my $kml_org_template;

my @station_list = qw(8720757 8722213 8720767 8725081 8721842 8725114 8721147 8721073 8720625 8720503 8722375 8720494 8722125);
#my @station_list = qw(8722375); #debug

while (@station_list) {

my $station = shift(@station_list);

$obs_url = "http://www.fldep-stevens.com/data-$station.php"; #custom


#get recent date range
my $date_from = `date --date='-30 minutes' +'%m%d%YT%H'`;
#my $date_from = `date --date='-3 hours' +'%m%d%YT%H'`; 
chomp($date_from);
my $date_from_month = substr($date_from,0,2);
my $date_from_day = substr($date_from,2,2);
my $date_from_year = substr($date_from,4,4);
my $date_from_hour = substr($date_from,9,2);

my $date_to = `date --date='1 hours' +'%m%d%YT%H'`;
chomp($date_to);
my $date_to_month = substr($date_to,0,2);
my $date_to_day = substr($date_to,2,2);
my $date_to_year = substr($date_to,4,4);
my $date_to_hour = substr($date_to,9,2);

#select metric units and water level = NAVD88 default
my $url = "http://www.fldep-stevens.com/export-$station\.php?t=c&txtFDate=$date_from_month%2F$date_from_day%2F$date_from_year&selFTime=$date_from_hour&txtTDate=$date_to_month%2F$date_to_day%2F$date_to_year&selTTime=$date_to_hour&selChannel=&rdoDateTime=1&rdoWTemp=1&rdoWSpeed=1&rdoATemp=1&rdoPressure=1&rdoRainfall=1&rdoWLevel=1";
#print $url."\n";
getstore($url,"./latest.csv") or die "Couldn't get $url\n";

open(FILE,"./latest.csv");

my $water_temp_upper_column = '';
my $water_temp_upper = '';
my $water_temp_lower_column = '';
my $water_temp_lower = '';
my $water_temp_column = '';
my $water_temp = '';

my $water_conductivity_upper_column = '';
my $water_conductivity_upper = '';
my $water_conductivity_lower_column = '';
my $water_conductivity_lower = '';
my $water_conductivity_column = '';
my $water_conductivity = '';

my $salinity_upper_column = '';
my $salinity_upper = '';
my $salinity_lower_column = '';
my $salinity_lower = '';
my $salinity_column = '';
my $salinity = '';

my $ph_column = '';
my $ph = '';

my $wind_direction_column = '';
my $wind_direction = '';
my $wind_speed_column = '';
my $wind_speed = '';
my $air_temp_column = '';
my $air_temp = '';
my $air_pressure_column = '';
my $air_pressure = '';
my $rh_column = '';
my $rh = '';
my $precip_column = '';
my $precip = '';
my $water_level_column = '';
my $water_level = '';

my $line_count = 0;
foreach my $line (<FILE>) {
  $line_count++;
  chop($line); #get rid of trailing newline on lines
  chop($line); #get rid of trailing double-quote on lines
  if ($line_count == 1) {
    my @header_elements = split(/,/,$line);  

    my $column_count = 0;
    foreach my $element (@header_elements) {
      #print "header:$element\n";

      if ($element =~ /Water\s+Temp\s+\(C\)\s+Upper/) { $water_temp_upper_column = $column_count; }
      if ($element =~ /Water\s+Temp\s+\(C\)\s+Lower/) { $water_temp_lower_column = $column_count; }
      if ($water_temp_upper_column eq '' && $element =~ /Water Temp/) { $water_temp_column = $column_count; }

      if ($element =~ /Water\s+Conductivity\s+\(mS\/cm\)\s+Upper/) { $water_conductivity_upper_column = $column_count; }
      if ($element =~ /Water\s+Conductivity\s+\(mS\/cm\)\s+Lower/) { $water_conductivity_lower_column = $column_count; }
      if ($water_conductivity_upper_column eq '' && $element =~ /Water Conductivity/) { $water_conductivity_column = $column_count; }

      if ($element =~ /Salinity\s+\(ppt\)\s+Upper/) { $salinity_upper_column = $column_count; }
      if ($element =~ /Salinity\s+\(ppt\)\s+Lower/) { $salinity_lower_column = $column_count; }
      if ($salinity_upper_column eq '' && $element =~ /Salinity/) { $salinity_column = $column_count; }

      if ($element =~ /pH/) { $ph_column = $column_count; }
      if ($element =~ /Wind\s+Direction/) { $wind_direction_column = $column_count; }
      if ($element =~ /Wind\s+Speed/) { $wind_speed_column = $column_count; }
      if ($element =~ /Air\s+Temp/) { $air_temp_column = $column_count; }
      if ($element =~ /Barometric\s+Pressure/) { $air_pressure_column = $column_count; }
      if ($element =~ /Relative\s+Humidity/) { $rh_column = $column_count; }
      if ($element =~ /Rainfall/) { $precip_column = $column_count; }
      if ($element =~ /Water\s+Level/) { $water_level_column = $column_count; }

      $column_count++;
    } 

  }
  else {
    my @data_elements = split(/\",\"/,$line); 

    #date like "Sep 28, 2011  19:30
    $datetime = @data_elements[0];
    $datetime = substr($datetime,1);

    $datetime = `date --date='$datetime' +'%Y-%m-%dT%H:%M:00'`;
    chomp($datetime);
    $datetime .= $time_zone;

    $obs_list = '';

    #below lines create obsList
    if ($water_temp_upper_column ne '') { $water_temp_upper = @data_elements[$water_temp_upper_column]; &add_obs('water_temperature','celsius',$water_temp_upper); }
    if ($water_temp_lower_column ne '') { $water_temp_lower = @data_elements[$water_temp_lower_column]; &add_obs('water_temperature','celsius',$water_temp_lower,2); }
    if ($water_temp_column ne '') { $water_temp = @data_elements[$water_temp_column]; &add_obs('water_temperature','celsius',$water_temp); }

    if ($water_conductivity_upper_column ne '') { $water_conductivity_upper = @data_elements[$water_conductivity_upper_column]; &add_obs('water_conductivity','mS_cm-1',$water_conductivity_upper); }
    if ($water_conductivity_lower_column ne '') { $water_conductivity_lower = @data_elements[$water_conductivity_lower_column]; &add_obs('water_conductivity','mS_cm-1',$water_conductivity_lower,2); }
    if ($water_conductivity_column ne '') { $water_conductivity = @data_elements[$water_conductivity_column]; &add_obs('water_conductivity','mS_cm-1',$water_conductivity); }

    if ($salinity_upper_column ne '') { $salinity_upper = @data_elements[$salinity_upper_column]; &add_obs('salinity','psu',$salinity_upper); }
    if ($salinity_lower_column ne '') { $salinity_lower = @data_elements[$salinity_lower_column]; &add_obs('salinity','psu',$salinity_lower,2); }
    if ($salinity_column ne '') { $salinity = @data_elements[$salinity_column]; &add_obs('salinity','psu',$salinity); }

    if ($ph_column ne '') { $ph = @data_elements[$ph_column]; &add_obs('ph','units',$ph); }
    if ($wind_direction_column ne '') { $wind_direction = @data_elements[$wind_direction_column]; &add_obs('wind_from_direction','degrees_true',$wind_direction); }
    if ($wind_speed_column ne '') { $wind_speed = @data_elements[$wind_speed_column]; &add_obs('wind_speed','m_s-1',$wind_speed); }
    if ($air_temp_column ne '') { $air_temp = @data_elements[$air_temp_column]; &add_obs('air_temperature','celsius',$air_temp); }
    if ($air_pressure_column ne '') { $air_pressure = @data_elements[$air_pressure_column]; &add_obs('air_pressure','mb',$air_pressure); }
    if ($rh_column ne '') { $rh = @data_elements[$rh_column]; &add_obs('relative_humidity','percent',$rh); }
    if ($precip_column ne '') { $precip = @data_elements[$precip_column]; &add_obs('precipitation','millimeter',$precip); }
    if ($water_level_column ne '') { $water_level = @data_elements[$water_level_column]; &add_obs('water_level','m',$water_level); }

    #print "station:$station:date:$datetime:water_temp:$water_temp:wind_direction:$wind_direction:wind_speed:$wind_speed\n"; 
    
     
#  } # data line

  #####create placemark
  my $kml_placemark_template = `cat placemark_template.kml`;
  
  $kml_placemark_template =~ s/OBS_LIST/$obs_list/ ;

  $kml_placemark_template =~ s/PLACEMARK_WHEN/$datetime/ ;

  my ($placemark_id,$placemark_url,$placemark_name,$placemark_desc,$placemark_coords);
  #custom 
  if ($station =~ /8720757/) { $placemark_id = 'fldep.bingslanding'; $placemark_url = 'http://www.fldep-stevens.com/readings-8720757.php'; $placemark_name = 'fldep.bingslanding(872-0757)'; $placemark_desc = 'Bing\'s Landing station'; $placemark_coords = '-81.204917,29.615417,0'; }
  if ($station =~ /8722213/) { $placemark_id = 'fldep.binneydock'; $placemark_url = 'http://www.fldep-stevens.com/readings-8722213.php'; $placemark_name = 'fldep.binneydock(872-2213)'; $placemark_desc = 'Binney Dock station'; $placemark_coords = '-80.30085,27.467547,0'; }
  if ($station =~ /8720767/) { $placemark_id = 'fldep.buffalobluff'; $placemark_url = 'http://www.fldep-stevens.com/readings-8720767.php'; $placemark_name = 'fldep.buffalobluff(872-0767)'; $placemark_desc = 'Buffalo Bluff station'; $placemark_coords = '-81.681389,29.594333,0'; }
  if ($station =~ /8725081/) { $placemark_id = 'fldep.gordonriverinlet'; $placemark_url = 'http://www.fldep-stevens.com/readings-8725081.php'; $placemark_name = 'fldep.gordonriverinlet(872-5081)'; $placemark_desc = 'Gordon River Inlet station'; $placemark_coords = '-81.798139,26.093139,0'; }
  if ($station =~ /8721842/) { $placemark_id = 'fldep.melbourne'; $placemark_url = 'http://www.fldep-stevens.com/readings-8721842.php'; $placemark_name = 'fldep.melbourne(872-1842)'; $placemark_desc = 'Melbourne station'; $placemark_coords = '-80.591972,28.083675,0'; }
  if ($station =~ /8725114/) { $placemark_id = 'fldep.naplesbay'; $placemark_url = 'http://www.fldep-stevens.com/readings-8725114.php'; $placemark_name = 'fldep.naplesbay(872-5114)'; $placemark_desc = 'Naples Bay station'; $placemark_coords = '-81.790056,26.141778,0'; }
  if ($station =~ /8721147/) { $placemark_id = 'fldep.poncedeleonsouth'; $placemark_url = 'http://www.fldep-stevens.com/readings-8721147.php'; $placemark_name = 'fldep.poncedeleonsouth(872-1147)'; $placemark_desc = 'Ponce De Leon South station'; $placemark_coords = '-80.916083,29.063472,0'; }
  if ($station =~ /8721073/) { $placemark_id = 'fldep.portorange'; $placemark_url = 'http://www.fldep-stevens.com/readings-8721073.php'; $placemark_name = 'fldep.portorange(872-1073)'; $placemark_desc = 'Port Orange station'; $placemark_coords = '-80.975306,29.148,0'; }
  if ($station =~ /8720625/) { $placemark_id = 'fldep.racypoint'; $placemark_url = 'http://www.fldep-stevens.com/readings-8720625.php'; $placemark_name = 'fldep.racypoint(872-0625)'; $placemark_desc = 'Racy Point station'; $placemark_coords = '-81.549889,29.800167,0'; }
  if ($station =~ /8720503/) { $placemark_id = 'fldep.redbaypoint'; $placemark_url = 'http://www.fldep-stevens.com/readings-8720503.php'; $placemark_name = 'fldep.redbaypoint(872-0503)'; $placemark_desc = 'Red Bay Point station'; $placemark_coords = '-81.633806,29.982111,0'; }
  if ($station =~ /8722375/) { $placemark_id = 'fldep.stlucieinlet'; $placemark_url = 'http://www.fldep-stevens.com/readings-8722375.php'; $placemark_name = 'fldep.stlucieinlet(872-2375)'; $placemark_desc = 'St Lucie Inlet station'; $placemark_coords = '-80.162778,27.165278,0'; }
  if ($station =~ /8720494/) { $placemark_id = 'fldep.tolomatoriver'; $placemark_url = 'http://www.fldep-stevens.com/readings-8720494.php'; $placemark_name = 'fldep.tolomatoriver(872-0494)'; $placemark_desc = 'Tolomato River station'; $placemark_coords = '-81.329556,29.994722,0'; }
  if ($station =~ /8722125/) { $placemark_id = 'fldep.verobeach'; $placemark_url = 'http://www.fldep-stevens.com/readings-8722125.php'; $placemark_name = 'fldep.verobeach(872-2125)'; $placemark_desc = 'Vero Beach station'; $placemark_coords = '-80.371222,27.632056,0'; }


  my $operator_url = 'http://www.fldep-stevens.com';
  $kml_placemark_template =~ s/OPERATOR_URL/$operator_url/ ;

  $kml_placemark_template =~ s/PLACEMARK_ID/$placemark_id/ ;
  $kml_placemark_template =~ s/PLACEMARK_URL/$placemark_url/ ;
  $kml_placemark_template =~ s/PLACEMARK_NAME/$placemark_name/ ;
  $kml_placemark_template =~ s/PLACEMARK_DESC/$placemark_desc/g ;
  $kml_placemark_template =~ s/PLACEMARK_COORDS/$placemark_coords/ ;

  $placemark_list .= $kml_placemark_template;

  } # data line

} #foreach line

  $kml_org_template = `cat org_template.kml`;
  $kml_org_template =~ s/PLACEMARK_LIST/$placemark_list/ ;
  $kml_org_template =~ s/ORG_NAME/$org_name/ ;
  #print $kml_org_template; 

close(FILE);

} #while @station_list

open(FILE,">./fldep.kml");
print FILE $kml_org_template;
close(FILE);

`zip fldep.kmz fldep.kml`;
`cp fldep.kmz /var/www/xenia/feeds/scout/fldep/fldep_metadata_latest.kmz`;

exit 0;

sub add_obs {

my ($obs_type,$obs_uom,$obs_value,$obs_sorder) = @_;

if ($obs_sorder eq '') { $obs_sorder = 1; }

my $this_obs = `cat obs_template.kml`;

$this_obs =~ s/OBS_TYPE/$obs_type/ ;
$this_obs =~ s/OBS_UOM/$obs_uom/ ;
$this_obs =~ s/OBS_VALUE/$obs_value/ ;
$this_obs =~ s/OBS_URL/$obs_url/ ;
$this_obs =~ s/OBS_SORDER/$obs_sorder/ ;

$obs_list .= $this_obs;

}



