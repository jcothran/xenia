use strict;
#use warnings;

##config

##

=comment
#usage notes

Watch the server path specific literals, everything gets unzipped and worked on in $target_dir so you'll want to set that to some temporary folder area that gets periodically flushed.

The other xml files this script uses is style.xml .

style.xml provides the default observation range limits to be used and can also be ignored in favor of a user supplied style.xml via $styel_url  

Also there is a literal http address returned to the calling php page which will need to be changed accordingly. 

#see line time filter below to control acceptable date range used in creating output file
#my $date_yesterday = `date +%Y%m%d%H%M --date='12 hours ago'`;

=cut

use LWP::Simple;
use XML::LibXML;

my ($zip_obskml_url, $style_url, $feed_name) = @ARGV;
if ($feed_name) { $feed_name = $feed_name.'_'; }

open (LOG_FILE,">$feed_name\obskml_style.log");
open (DEBUG,">./debug_genPlacemarks.txt");

my $count = @ARGV;
if ($count < 1) {
 print "usage: zip_obskml_url style_url\n";
 exit;
}

#using print `date` for script time benchmarking
#print `date`;

#create temp working directory
my $random_value = int(rand(10000000));
my $target_dir = "/tmp/ms_tmp/gearth_$random_value";
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

#style_url
if (!($style_url) || ($style_url eq 'null')) { `cp /var/www/html/obskml/scripts/style.xml $target_dir`; }
else {
my $style_filepath = "$target_dir/style.xml";
my $content = getstore($style_url, $style_filepath);
die "Couldn't get $style_url" unless defined $content;
}

##################
#global hashes

#note that the below hashing convention assumes each element contains only one type of child element except at the terminals
my %HoH = ();
my $rHoH = \%HoH;

my %HoH_stats = ();

#below hash used later for sorting by ObsTypes
my %ObsTypes = ();
my $rObsTypes = \%ObsTypes;

##################
#convert kml files to hash
##################

my $filelist = `ls $target_dir/*.kml`;
#print $filelist;
my @files = split(/\n/,$filelist);
#print @files;
#exit 0;

my $date_now = `date +%Y%m%d%H%M --date='+12 hours'`;
chomp($date_now);
#the below seems to catch 2+4(EDT) = 6 hours
my $date_yesterday = `date +%Y%m%d%H%M --date='-12 hours'`;
chomp($date_yesterday);

foreach my $file (@files) {
#print "$file\n";
#my $xp = XML::LibXML->new->parse_file("$target_dir/obskml_latest.kml");
my $xp = XML::LibXML->new->parse_file($file);

#print `date`;

foreach my $placemark ($xp->findnodes('//Placemark')) {
	my $placemark_id = $placemark->getAttribute('id');
	if (!($placemark_id)) { $placemark_id = 'none.none.none'; }
	#print "$placemark_id\n";	
	my $local_platform = $placemark_id;	
	my ($operator,$platform,$package) = split(/\./,$placemark_id);
	
	my $datetime = $placemark->find('TimeStamp/when');
        $datetime = sprintf("%s", $datetime); 
	my $coordinates = $placemark->find('Point/coordinates');
	my ($longitude,$latitude) = split(/,/,$coordinates);
	if ($platform eq 'none') { $local_platform = "point($longitude,$latitude)"; } #lon/lat stand in for placemark id if none given

	my $operator_url = $placemark->find('Metadata/obsList/operatorURL');
        $operator_url = sprintf("%s", $operator_url); 
	my $platform_url = $placemark->find('Metadata/obsList/platformURL');
        $platform_url = sprintf("%s", $platform_url); 
	my $platform_desc = $placemark->find('Metadata/obsList/platformDescription');
        $platform_desc = sprintf("%s", $platform_desc); 

	
foreach my $observation ($placemark->findnodes('Metadata/obsList/obs')) {

	my $obs_property = $observation->find('obsType');
	my $uom = $observation->find('uomType');
	$obs_property .= '.'.$uom;

	#have to cast measurement to float using sprintf to avoid comparison confusion later
	my $measurement = sprintf("%.2f",$observation->find('value'));

        #using the below hash trick to get a list of unique ObsTypes
        $ObsTypes{ $obs_property } = 1;

	#print "$operator:$local_platform:$obs_property:$datetime:$longitude:$latitude:$measurement\n";

	my $date_test = substr($datetime,0,4).substr($datetime,5,2).substr($datetime,8,2).substr($datetime,11,2).substr($datetime,14,2);
	#print "date_test: $date_test \n";

	#don't share erroneous 'future' observations greater than today's date or obs older than yesterday
	if (($date_test >= $date_yesterday) && ($date_test <= $date_now)) { 
	print DEBUG "date pass: $date_yesterday $date_now $date_test \n"; 

	#for logging purposes
        #only want to increment count for just latest measurements, not earlier
	#tried $HoH_stats{$operator}{$placemark_id}{$obs_property} but hash complains/fails for more than one unknown level reference ??
	if (!($HoH_stats{$operator}{$placemark_id.$obs_property})) {
		$HoH_stats{$operator}{$placemark_id.$obs_property} = 1;
		$HoH_stats{ $operator }{ $obs_property }{ obs_count }++;
        }

	#if ($operator eq 'nerrs') { print "$date_test $date_now $date_yesterday\n"; }
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'operator_url' } = $operator_url;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'platform_url' } = $platform_url;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'platform_desc' } = $platform_desc;

	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'longitude' } = $longitude;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'latitude' } = $latitude;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'data_url' } = $observation->find('dataURL');
	
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'datetime' } = $datetime;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'measurement' } = $measurement;
	$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'elev' } = $observation->find('elev');
	#$HoH{ $operator }{ $local_platform }{ $datetime }{ $obs_property }{ 'uom' } = $uom;
	}
	else { print DEBUG "date fail: $date_yesterday $date_now $date_test \n"; }

} #foreach obs
        #only want to increment count for just latest measurements, not earlier
        if ($HoH_stats{$operator}{$placemark_id} != 1) {
                $HoH_stats{$operator}{$placemark_id} = 1;
		$HoH_stats{ $operator }{ platform_count }++;
	}
} #foreach Placemark
} #foreach file

#################
#kml content
##################

my $kml_content = <<"END_OF_FILE";
<kml xmlns="http://earth.google.com/kml/2.0">
<Folder>
<name>Ocean/Coastal Observing Platform Data</name>
<visibility>0</visibility>
<description><![CDATA[The following is a listing of primarily ocean/coastal observing platform data(some platform measurements from inland may also be included) shared by using http accessible xml and data files detailed at <a href="http://carocoops.org/twiki_dmcc/bin/view/Main/ObsKML">ObsKML</a>  Here are links to the <a href="http://carocoops.org/obskml/feeds">original source ObsKML data</a> and the <a href="http://carocoops.org/obskml/scripts/genPlacemarksObsKML.pl">styling script</a> used to generate this KML file.  Please email <a href="mailto:jeremy.cothran\@gmail.com">jeremy.cothran\@gmail.com</a> regarding questions or comments on this kml product or sharing/registering your observation data using these tools.]]></description>
END_OF_FILE

#generating the kml content below if not directly output to $kml_content is sent to 'buffer' variables so that the buffer can be used
# or cleared depending on the available data 

##################
#list by operator
##################
#print "by operator: ";
#print `date`;

$kml_content .= "<Folder><name>List by operator</name><visibility>0</visibility>";

foreach my $operator ( sort keys %{$rHoH} ) {
        #print "operator:$operator\n";
	
	print LOG_FILE "operator $operator $HoH_stats{$operator}{platform_count}\n";

	foreach my $obs_type ( sort keys %{$rObsTypes} ) {
		my $obs_count = $HoH_stats{$operator}{$obs_type}{obs_count};
		if ($obs_count > 0) {
			print LOG_FILE "obs_type $obs_type $HoH_stats{$operator}{$obs_type}{obs_count}\n";
		}
	}
	print LOG_FILE "\n\n";

$kml_content .= "<Folder><name>$operator</name><visibility>0</visibility>";

foreach my $local_platform ( sort keys %{$rHoH->{$operator}} ) {
        #print "localPlatformName:$local_platform\n";

	$kml_content .= "<Folder><name>$local_platform</name><visibility>0</visibility>";

foreach my $datetime ( sort keys %{$rHoH->{$operator}{$local_platform}} ) {
       	#print "datetime:$datetime\n";

        my $desc_header = '';
        my $desc_table = '';
        my $desc_footer = '';

        my $operator_url = '';
        my $platform_url = '';
        my $platform_desc = '';
	my $longitude = '';
	my $latitude = '';
	my $measurement = '';
	#my $uom = '';
	my $datetime_label = '';
	my $data_url = '';
        my $elev = '';

	foreach my $obs_property ( sort keys %{$rHoH->{$operator}{$local_platform}{ $datetime }} ) {
        	#print "obs_property:$obs_property\n";

	        #only need to do this initially once per platform
        	if (!($datetime_label)) {

                        $datetime_label = $datetime;
                        $datetime_label =~ s/T/ /g;
                        #$datetime_label = substr($datetime_label,0,16).' GMT';
                        #print "$datetime_label\n";

        		$desc_header .= '<![CDATA[';
                        $desc_header .= "Last update: $datetime_label<br />";

                	$platform_desc = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'platform_desc'};
		        if ($platform_desc) { $desc_header .= 'Description: '.$platform_desc.'<br />'; }
                	$operator_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'operator_url'};
		        if ($operator_url) { $desc_header .= '<a href="'.$operator_url.'">OperatorURL</a><br />'; }
                	$platform_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'platform_url'};
		        if ($platform_url) { $desc_header .= '<a href="'.$platform_url.'">PlatformURL</a><br />'; }

     			$desc_header .= "Related links: ";
        		$desc_header .= "<a href=\"http://carocoops.org/twiki_dmcc/bin/view/Main/ObsKML\">ObsKML</a> ";
        		$desc_header .= "<a href=\"http://secoora.org\">http://secoora.org</a><br /><br />";

                	$data_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'data_url'};
			if ($data_url) {
                        	$desc_header .= "Click on the latest observation reading to view graphs of previous observations.<br /><br />";
			}
                        $desc_table .= '<table  border="1">';
        	}

        	$longitude = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'longitude'};
        	$latitude = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'latitude'};
		
                $measurement = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'measurement'};
                #print "$measurement\n";

                #$uom = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'uom'};
                $elev = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'elev'};
                $data_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'data_url'};

                $desc_table .= unit_convert_table($obs_property,$measurement,$data_url,$elev);

        }

	#only closing table if exists
	#note that could sort table entries by elevation at this point if wanted
        if ($desc_table ne '') { $desc_table .= '</table>'; }

        $desc_footer .= ']]>';

my $description = $desc_header.$desc_table.$desc_footer;

$kml_content .= <<"END_OF_FILE";
<Placemark>
  <TimeStamp><when>$datetime</when></TimeStamp>
  <name>$local_platform</name>
  <visibility>1</visibility>
  <description>$description</description>
  <Point>
    <coordinates>$longitude,$latitude,0</coordinates>
  </Point>
</Placemark>
END_OF_FILE

} #foreach $datetime 

$kml_content .= "</Folder>";
} #foreach $local_platform 

$kml_content .= "</Folder>";

} #foreach $operator

$kml_content .= "</Folder>";

##################
#list by observation
##################
#print "by observation: ";
#print `date`;

#the below is a cut and paste for the most part of the 'list be operator' except running through the ObsTypes list and comparing to determine #whether kml is output or not and the style application of colored ranges on the icons

my $xp_style = XML::LibXML->new->parse_file("$target_dir/style.xml");

$kml_content .= "<Folder><name>List by observation</name><visibility>0</visibility>";
$kml_content .= "<Style><ListStyle><listItemType>radioFolder</listItemType></ListStyle></Style>";
$kml_content .= "<Folder><name>none</name><visibility>0</visibility></Folder>";

my $kml_temp_content;

foreach my $obs_type ( sort keys %{$rObsTypes} ) {
        #print "obs_type:$obs_type\n";

	$kml_content .= "<Folder><name>$obs_type</name><visibility>0</visibility>";

	#must convert below to int, otherwise errors out on pass to subroutines and improper type handline
	my $range_high = int($xp_style->findvalue('//style[@id="'.$obs_type.'"]/range_high'));
	#print "range_high:$range_high\n";
	my $range_low = int($xp_style->findvalue('//style[@id="'.$obs_type.'"]/range_low'));
	#print "range_low:$range_low\n";

	my $yellow_range = '<strong>yellow</strong> = below '.$range_low;
	my $orange_range = '<strong>orange</strong> = above '.$range_high;

	my $color_span = ($range_high - $range_low)/3;
	my $blue_range = '<strong>blue</strong> = '.$range_low.' to '.int($range_low+$color_span);	
	my $green_range = '<strong>green</strong> = '.int($range_low+$color_span).' to '.int($range_low+$color_span*2);	
	my $red_range = '<strong>red</strong> = '.int($range_low+$color_span*2).' to '.$range_high;	


	$kml_content .= "<description>The following color ranges apply to this observation<br/><strong>violet</strong> range not defined<br/>$yellow_range<br/>$blue_range<br/>$green_range<br/>$red_range<br/>$orange_range</description>";

	$kml_content .= "<Folder><name>Toggle all on/off</name><visibility>0</visibility>";

foreach my $operator ( sort keys %{$rHoH} ) {
        #print "operator:$operator\n";

	#my $kml_temp_content = '';

	$kml_content .= "<Folder><name>$operator</name><visibility>0</visibility>";

foreach my $local_platform ( sort keys %{$rHoH->{$operator}} ) {
        #print "localPlatformName:$local_platform\n";

	#$kml_content .= "<Folder><name>$local_platform</name><visibility>0</visibility>";

foreach my $datetime ( sort keys %{$rHoH->{$operator}{$local_platform}} ) {

	$kml_temp_content = '';

        my $desc_header = '';
        my $desc_table = '';
        my $desc_footer = '';

        my $operator_url = '';
        my $platform_url = '';
        my $platform_desc = '';
        my $longitude = '';
        my $latitude = '';
        my $measurement = '';
        #my $uom = '';
        my $datetime_label = '';
        my $data_url = '';
        my $elev = '';
	my $color = '';

        foreach my $obs_property ( sort keys %{$rHoH->{$operator}{$local_platform}{ $datetime }} ) {
                #print "obs_property:$obs_property:$operator:$local_platform\n";
		if ($obs_property ne $obs_type) { next; }
                #print "obs_property:$obs_property:$operator:$local_platform\n";

                #only need to do this initially once per platform
                if (!($datetime_label)) {

                        $datetime_label = $datetime;
                        $datetime_label =~ s/T/ /g;
                        #$datetime_label = substr($datetime_label,0,16).' GMT';
                        #print "$datetime_label\n";

                        $desc_header .= '<![CDATA[';
                        $desc_header .= "Last update: $datetime_label<br />";
 
                	$platform_desc = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'platform_desc'};
		        if ($platform_desc) { $desc_header .= 'Description: '.$platform_desc.'<br />'; }
                	$operator_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'operator_url'};
		        if ($operator_url) { $desc_header .= '<a href="'.$operator_url.'">OperatorURL</a><br />'; }
                	$platform_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'platform_url'};
		        if ($platform_url) { $desc_header .= '<a href="'.$platform_url.'">PlatformURL</a><br />'; }

                        $desc_header .= "Related links: ";
                        $desc_header .= "<a href=\"http://carocoops.org/twiki_dmcc/bin/view/Main/ObsKML\">ObsKML</a> ";
                        $desc_header .= "<a href=\"http://secoora.org\">http://secoora.org</a><br /><br />";

                	$data_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'data_url'};
			if ($data_url) {
                        	$desc_header .= "Click on the latest observation reading to view graphs of previous observations.<br /><br />";
			}
                        $desc_table .= '<table  border="1">';
                }

                $longitude = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'longitude'};
                $latitude = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'latitude'};

                $measurement = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'measurement'};
                #print "$measurement\n";

		$color = conv_measurement_to_color($range_high,$range_low,$measurement);
		#print "color:$color\n";


                #$uom = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'uom'};
                $elev = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'elev'};
                $data_url = $HoH{$operator}{$local_platform}{ $datetime }{$obs_property}{'data_url'};

                $desc_table .= unit_convert_table($obs_property,$measurement,$data_url,$elev);

        }

	#only closing table if exists
	#note that could sort table entries by elevation at this point if wanted
        if ($desc_table ne '') { $desc_table .= '</table>'; }

        $desc_footer .= ']]>';

my $description = $desc_header.$desc_table.$desc_footer;

if ($latitude) {  #testing for content before output kml - using latitude, but could be any of above content vars
#print "debug\n";
$kml_temp_content .= <<"END_OF_FILE";
<Placemark>
  <TimeStamp><when>$datetime</when></TimeStamp>
  <name>$local_platform</name>
  <visibility>0</visibility>
  <description>$description</description>
  <Point>
    <coordinates>$longitude,$latitude,0</coordinates>
  </Point>
  <Style>
    <IconStyle>
      <scale>1.0</scale>
      <Icon>
        <href>http://carocoops.org/gearth/images/$color\_circle_icon.png</href>
      </Icon>
    </IconStyle>
  </Style>
</Placemark>
END_OF_FILE
}

if ($kml_temp_content) {
	#print "debug\n";
	$kml_content .= "<Folder><name>$local_platform</name><visibility>0</visibility>";
	$kml_content .= $kml_temp_content;
	$kml_content .= "</Folder>";
}

} #foreach $datetime
} #foreach $local_platform

$kml_content .= "</Folder>";
} #foreach $operator

$kml_content .= "</Folder>";
$kml_content .= "</Folder>";
} #foreach $obs_type

$kml_content .= "</Folder>";

##################
#kml close and return file handle
##################

$kml_content .= <<"END_OF_FILE";
</Folder>
</kml>
END_OF_FILE

open (FILE_KML,">$target_dir/latest_placemarks.kml");
print FILE_KML $kml_content;
close (FILE_KML);

`cd $target_dir; zip latest_placemarks.kmz latest_placemarks.kml`;

my $kml_url = 'http://nautilus.baruch.sc.edu/ms_tmp/gearth_'.$random_value.'/latest_placemarks.kmz';
print $kml_url;

`rm -f $target_dir/*.kml ; rm -f $target_dir/*.xml`;

#print `date`;

close (LOG_FILE);
close (DEBUG);

exit 0;

##subroutines################################

sub unit_convert_table
{
#this sub takes $parameter_id, $parameter_value and uses an xml lookup to convert them to another unit of measure returned as an html table row

my ($parameter_id, $parameter_value, $graph, $elev) = @_;
#print "$parameter_id $parameter_value\n";

$elev = sprintf("%.2f", $elev);
#print ":$elev:\n";
if ($elev ne '0.00' && $elev ne '-99999.00') { $parameter_id .= " at $elev m"; }

my $string;
if ($graph) {
	$string = "<tr><td>$parameter_id</td><td><a href=\"$graph\" target=\"new\">$parameter_value</a></td></tr>";
}
else {
	$string = "<tr><td>$parameter_id</td><td>$parameter_value</td></tr>";
}
#print "$string\n";

return $string;
}

sub conv_measurement_to_color
{
   #note this function biased to use integer ranges and numbers (so avoid narrow ranges or recode to work with better)

    my ($range_high, $range_low, $measurement) = @_;
    #$measurement = int($measurement);
    #if ($measurement == 1037) { print ":$measurement:$range_low:$range_high:"; }
    if ($range_high == $range_low ) { return 'FF00FF'; } #violet
    if ($measurement <= $range_low) { return '00FFFF'; } #yellow
    if ($measurement >= $range_high) { return '0099FF'; } #orange

    #NOTE: google kml color scheme is bgr(blue green red) instead of rgb(red green blue) preceeded by alpha/transparency - I've hardcoded the
    #transparency as not transparent (ff) in the <color> element and the below are the bgr hex that are substituted from the color scale.  
    #The color scale is low to high: light blue->dark blue, light green->dark green, light red->dark red
    #anything which falls outside the range low is yellow and outside the range high is orange
    #anything where the range or measurement is not defined is violet
    #found the following website helpful also: http://www.yvg.com/twrs/RGBConverter.html

    my $color_scale_count = 21;
    my @color_scale = qw(FFBEBE FF9E9E FF7E7E FF5F5F FF3F3F FF1F1F FF0000 BEFFBE 9EFF9E 7EFF7E 5FFF5F 3FFF3F 1FFF1F 00FF00 BEBEFF 9E9EFF 7E7EFF 5F5FFF 3F3FFF 1F1FFF 0000FF);

    my $increment = ($range_high - $range_low) / $color_scale_count;
    my $choice = int(($measurement - $range_low)/$increment);
    #print "$measurement:$increment:$choice\n";

    return @color_scale[$choice];
}

