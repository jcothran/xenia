#obskml_to_html_content_sqlite.pl

use strict;
#use warnings;
use LWP::Simple;
use XML::LibXML;

=comment
#usage notes

Created this variation for use with Openlayers and GetFeatureInfo requests for substituting html snippets back to the browser on the shapefile query

Watch the server path specific literals, everything gets unzipped and worked on in $target_dir so you'll want to set that to some temporary folder area that gets periodically flushed.

=cut

############
#config

my $temp_dir = '/tmp/ms_tmp';

my $sqlite_path = '/usr/bin/sqlite3-3.5.4.bin';
my $html_db = 'html_content.db';

#note this script assumes the folder './html_content.sql' for writing files out

#load graph info (contains needed unit conversions) 
my $xp_graph = XML::LibXML->new->parse_file('./graph.xml');

my $graph_link = '<a href="http://nautilus.baruch.sc.edu/xenia_sqlite/get_graph.php?sensor_id=var1&output=webpage&time_interval=-1 day&unit_conversion=en&time_zone_arg=EASTERN" target=new onclick="">';

#see custom formatting sections labeled CONFIG in code below

#code runs pretty much off of obskml complex structure, with the exception that I include sensorID field with each obs from the database export which is substituted for the graph link

#on the platform table, platform_handle is used for the filename (.htm) references and 'description' is used for the link name and 'url' is used for the link

#adding new platforms,sensors and obs should result in the corresponding latest obskml and html table snippets being generated automatically

#the 'active' field on both the platform and sensor table could be used to control further display behaviors

#the local graph.xml file is used for some conversions for this file - it is slightly different from the original graph.xml file in that m_type_id has been replaced by the standard name and some specific conversions

#to get a specific unit conversion graph in the graph link, just subtitute the default '=en' with your target unit like '=mph' making sure that there is a corresponding conversion formula and y_title in the graph.xml file which get_graph.php utilizes

#the display order of observations in the latest obskml and html tables is determined by the m_type_display_order table listing

############

my ($zip_obskml_url) = @ARGV;
my $count = @ARGV;
if ($count < 1) {
 print "usage: zip_obskml_url style_url\n";
 exit;
}

#using print `date` for script time benchmarking
#print `date`;

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
my $content = getstore($zip_obskml_url, $zip_filepath);
die "Couldn't get $zip_obskml_url" unless defined $content;

`cd $target_dir; unzip obskml.xml.zip`;

##################
#convert kml files to html tables (one file per placemark/platform)
##################

my $filelist = `ls $target_dir/*.kml`;
#print $filelist;
my @files = split(/\n/,$filelist);
#print @files;
#exit 0;

#time considerations

my $date_now = `date +%Y%m%d --date='1 day'`;
chomp($date_now);
my $date_yesterday = `date +%Y%m%d --date='1 day ago'`;
chomp($date_yesterday);

#daylight savings time consideration
my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);
my $gmt_time_difference;

#my $gmtTimeDifference = -4; #(timelocal(localtime())-timelocal(gmtime()))/3600;
if ($isdst) { $gmt_time_difference = -4; }
else { $gmt_time_difference = -5; }

open (FILE_HTML,">./html_content.sql");

#process ObsKML files

foreach my $file (@files) {
#print "$file\n";
#my $xp = XML::LibXML->new->parse_file("$target_dir/obskml_latest.kml");
my $xp = XML::LibXML->new->parse_file($file);

#print `date`;

my $previous_placemark_id;

foreach my $placemark ($xp->findnodes('//Placemark')) {
	my $placemark_id = $placemark->getAttribute('id');
	if (!($placemark_id)) { $placemark_id = 'none.none.none'; }

	#making the '.' separator substition for older '_' separator
	$placemark_id =~ s/_/./g ; 
	$placemark_id = lc($placemark_id) ; 

	print "$placemark_id\n";	

	#the following line makes sure we're only getting the top listed (hopefully most recent) obs and not others for each platform
	if ($placemark_id eq $previous_placemark_id) { next; }
	$previous_placemark_id = $placemark_id;

	my ($operator,$platform,$package) = split(/\./,$placemark_id);
	
	my $coordinates = $placemark->find('Point/coordinates');
	my ($longitude,$latitude) = split(/,/,$coordinates);
        $longitude = sprintf("%f", $longitude); 
        $latitude = sprintf("%f", $latitude); 

	if (invalid_lon_lat($longitude,$latitude)) { next; }

	my $datetime = $placemark->find('TimeStamp/when');
        $datetime = sprintf("%s", $datetime); 
        print $datetime."\n";

	my $datetime_label = $datetime;
	$datetime_label =~ s/T/ /g;
	$datetime_label =~ s/Z/-00:00/g;

        my $date_now_sec = `date +%s`;
        chomp ($date_now_sec);
        #print '$date_now'.$date_now_sec."\n";

        #my $date_top_sec = `date --date='$line +0000' +%s` ;  #commented out since this was wrongly increasing by 18000 sec(local offset)

	my $local_time = get_local_time($datetime_label, $gmt_time_difference);
	#print "local_time: $local_time \n";
        my $date_top_sec = `date --date='$local_time' +%s` ;
        chomp ($date_top_sec);
        #print '$date_top'.$date_top_sec."\n";

        my $date_diff_sec = $date_now_sec - $date_top_sec ;
        #print '$date_diff'.$date_diff_sec."\n";

        if ($date_diff_sec > 21600) { $datetime_label = "<span class=\"old\">No data available within the past 6 hours</span>"; }
        else {
             my @line_array = split(/\s+/, timestamp_format($local_time));
             $datetime_label = "Surface conditions as of ".@line_array[1]." ".@line_array[2]." ".($gmt_time_difference==-5?"EST":"EDT")." on ".@line_array[0] ;
             if ($date_diff_sec > 7200) {
                 $datetime_label .= "<br><span class=\"old\">Note: This report is more than 2 hours old</span>" ;
             }
	}

        #print $datetime_label."\n";

	my $operator_url = $placemark->find('Metadata/obsList/operatorURL');
        $operator_url = sprintf("%s", $operator_url); 
        $operator_url = escape_literals($operator_url); 
	my $platform_url = $placemark->find('Metadata/obsList/platformURL');
        $platform_url = sprintf("%s", $platform_url); 
        $platform_url = escape_literals($platform_url); 
	my $platform_desc = $placemark->find('Metadata/obsList/platformDescription');
        $platform_desc = sprintf("%s", $platform_desc); 
        $platform_desc = escape_literals($platform_desc); 

	my $html_content = '';

        $html_content .= "INSERT INTO html_content(wkt_geometry,organization,html) values ('POINT($longitude $latitude)','$operator','<hr/><br/><a href=\"$operator_url\" target=new onclick=\"\">organization: $operator</a><br/><a href=\"$platform_url\" target=new onclick=\"\">platform: $placemark_id</a><br/>$platform_desc<table cellpadding=\"2\" cellspacing=\"2\"><caption>$datetime_label</caption>";

#  <caption>Surface conditions as of 10:00 AM EASTERN on 2/19</caption>
	
foreach my $observation ($placemark->findnodes('Metadata/obsList/obs')) {

        #add spaces and capitlize first letters to given obsType names
	my $obs_type = sprintf("%s",$observation->find('obsType'));
	my $obs_label = $obs_type;
	$obs_label =~ s/_/ /g ;
	$obs_label  =~ s/\b(\w)/uc($1)/eg ;

	my $uom = sprintf("%s",$observation->find('uomType'));

	my $sensor_id = sprintf("%d",$observation->find('sensorID'));
	#print "sensor_id: $sensor_id \n";

	#have to cast measurement to float using sprintf to avoid comparison confusion later
	my $measurement = sprintf("%.2f",$observation->find('value'));

	my $measure_label = measure_convert($placemark_id,$obs_type,$uom,$measurement,$sensor_id);
	#print "$operator:$placemark_id:$obs_type:$uom:$datetime:$longitude:$latitude:$measurement\n";

	my $date_test = substr($datetime,0,4).substr($datetime,5,2).substr($datetime,8,2);

	#don't share erroneous 'future' observations greater than today's date or obs older than yesterday
	if (($date_test >= $date_yesterday) && ($date_test <= $date_now)) { 

	#print "html: $obs_label $measure_label \n";
        $html_content .= "<tr><th scope=\"row\">$obs_label</th><td>$measure_label</td></tr>";
	
	}

} #foreach obs

$html_content .= "</table>'";
$html_content .= ");\n";

print FILE_HTML $html_content;

} #foreach Placemark
} #foreach file

close (FILE_HTML);

#CONFIGSTART
`$sqlite_path $html_db < delete_html_content.sql`;
`$sqlite_path $html_db < html_content.sql`;
#CONFIGEND

exit 0;

##subroutines################################

sub measure_convert {

my ($platform_handle,$obs_type,$uom,$measurement,$sensor_id) = @_;

my $label = '';
my $unit_conversion = '';

##CONFIG_START

#conversions for the following which were labeled wrong on the way in to db
if ($obs_type eq 'dissolved_oxygen') { $obs_type = 'oxygen_concentration'; }

if ($uom eq 'millibar') { $uom = 'mb'; }
if ($uom eq 'percent_saturation') { $uom = 'percent'; }

##CONFIG_END

my $unit_conversion = $xp_graph->findvalue('//observation_list/observation[@standard_name="'.$obs_type.'"]/standard_uom_en');
if ($unit_conversion eq '') { print "not found: $obs_type $uom \n"; return $label; }

my $y_title = $xp_graph->findvalue('//unit_conversion_list/unit_conversion[@id="'.$uom.'_to_'.$unit_conversion.'"]/y_title');
my $conversion_formula = $xp_graph->findvalue('//unit_conversion_list/unit_conversion[@id="'.$uom.'_to_'.$unit_conversion.'"]/conversion_formula');

#unit conversion using supplied equation(e.g. celcius to fahrenheit)
my $conversion_string = $conversion_formula;
$conversion_string =~ s/var1/$measurement/g;
my $conversion_val = eval $conversion_string;

#print "$obs_type $unit_conversion $uom $y_title $conversion_formula $conversion_val \n"; 

my $this_graph_link = $graph_link;
$this_graph_link =~ s/var1/$sensor_id/g;

my $this_graph_link_2 = $this_graph_link; #used just for wind_speed and gust

##CONFIG_START

if ($obs_type eq 'air_pressure') { $this_graph_link =~ s/=en/=mb/g ; }
if ($obs_type eq 'wind_speed' || $obs_type eq 'wind_gust') { $this_graph_link_2 =~ s/=en/=mph/g ; }
if ($obs_type eq 'water_level') { $y_title .= ' (MLLW)' ; }

$label = "$this_graph_link$conversion_val $y_title</a>";

#exceptional cases
if ($obs_type eq 'wind_from_direction') { $label = conv_degrees_to_compass($conversion_val)." (".$this_graph_link.$conversion_val." $y_title</a>)" ; }
if ($obs_type eq 'wind_speed' and $uom eq 'm_s-1') { $label = $this_graph_link_2.sprintf("%.1f",$measurement*2.2369)." mph</a> (".$this_graph_link.$conversion_val." $y_title</a>)" ; }
if ($obs_type eq 'wind_gust' and $uom eq 'm_s-1') { $label = $this_graph_link_2.sprintf("%.1f",$measurement*2.2369)." mph</a> (".$this_graph_link.$conversion_val." $y_title</a>)" ; }

##CONFIG_END

#print "$label \n";
return $label;

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

sub get_local_time {

my ($date, $time_shift) = @_;
#assuming $time_zone_hour is negative
my ($year, $month, $day, $hour, $minute, $second, $time_zone_hour) = split(/[- :]/,$date);

my $time_subtract = -1*($time_shift + $time_zone_hour)*3600; #time_shift negative west of gmt

my $date_converted_1 = `date --date='$year-$month-$day $hour:$minute:$second +0000' +%s` - $time_subtract;
my $date_converted_2 = `date -u -d '1970-01-01 $date_converted_1 seconds' +"%m/%d %r"`;
my $date_converted_3 = substr($date_converted_2,0,11).substr($date_converted_2,14,3);

return $date_converted_3;
} #get_local_time


sub timestamp_format {
        my $input_date = shift;
        
        my $str_month = substr($input_date,0,2);
        $str_month =~ s/^0+//;
        
        my $str_day = substr($input_date,3,2);
        $str_day =~ s/^0+//;
        
        my $str_time = substr($input_date,6,8);
        $str_time =~ s/^0+//;
        
        return $str_month."/".$str_day." ".$str_time;
}       

sub invalid_lon_lat {
	my ($lon, $lat) = @_;

	if ($lon < -82 || $lon > -74) { return 1; }
	if ($lat < 31.65 || $lat > 36.60) { return 1; }

	if ($lat > 35.25 &&  $lon < -77.50) { return 1; }

	my $diff_lon = 82 + $lon;
	my $percent_diff = $diff_lon/4.5;
	my $diff_lat = 2.6*$percent_diff;
	my $test_lat = 32.65+$diff_lat;
	if ($lat > $test_lat) { return 1; }

	return 0;
}

#--------------------------------------------------------------------
#                   escape_literals
#--------------------------------------------------------------------
# Must make sure values don't contain XML reserved chars
sub escape_literals {
my $str = shift;
$str =~ s/</&lt;/gs;
$str =~ s/>/&gt;/gs;
$str =~ s/&/&amp;/gs;
$str =~ s/"/&quot;/gs;
$str =~ s/'/&#39;/gs;
return ($str);
}

