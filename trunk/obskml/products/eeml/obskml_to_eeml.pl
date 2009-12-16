#obskml_to_eeml.pl

#EEML is Extended Environment Markup Language http://eeml.org related to usage by http://pachube.com

use strict;
#use warnings;
use LWP::Simple;
use XML::LibXML;

=comment
#usage notes

Watch the server path specific literals, everything gets unzipped and worked on in $target_dir so you'll want to set that to some temporary folder area that gets periodically flushed.

=cut

############
#config

my $temp_dir = '/tmp/ms_tmp';

#code runs pretty much off of obskml complex structure, with the exception that I include sensorID field with each obs from the database export which is substituted for the graph link

#on the platform table, platform_handle is used for the filename (.xml) references and 'description' is used for the link name and 'url' is used for the link

#adding new platforms,sensors and obs should result in the corresponding latest obskml and html table snippets being generated automatically

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

#process ObsKML files

foreach my $file (@files) {
#print "$file\n";
#my $xp = XML::LibXML->new->parse_file("$target_dir/obskml_latest.kml");
my $xp = XML::LibXML->new->parse_file($file);

#print `date`;

foreach my $placemark ($xp->findnodes('//Placemark')) {
	my $placemark_id = $placemark->getAttribute('id');
	if (!($placemark_id)) { $placemark_id = 'none.none.none'; }

	#making the '.' separator substition for older '_' separator
	$placemark_id =~ s/_/./g ; 
	$placemark_id = lc($placemark_id) ; 
	print "$placemark_id\n";	

	#skip/ignore placemarks in the following list
	my @ignore_placemarks = qw(vos);
	if (&search_array($placemark_id,@ignore_placemarks)) { next; }

	my ($operator,$platform,$package) = split(/\./,$placemark_id);
	
	my $datetime = $placemark->find('TimeStamp/when');
        $datetime = sprintf("%s", $datetime); 
        print $datetime."\n";

	my $coordinates = $placemark->find('Point/coordinates');
	my ($longitude,$latitude) = split(/,/,$coordinates);

	my $operator_url = $placemark->find('Metadata/obsList/operatorURL');
        $operator_url = sprintf("%s", $operator_url); 
	my $platform_url = $placemark->find('Metadata/obsList/platformURL');
        $platform_url = sprintf("%s", $platform_url); 
	my $platform_desc = $placemark->find('Metadata/obsList/platformDescription');
        $platform_desc = sprintf("%s", $platform_desc); 

	my $html_content = '';
        $html_content .= <<"END_OF_FILE";
<eeml xmlns="http://www.eeml.org/xsd/005" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd" version="5">
<environment updated="$datetime">
<title>ocean/coastal observations</title>
<feed>http://www.carocoops.org/obskml/feeds/pachube/$placemark_id.xml</feed>
<status>live</status>
<description>This is an ocean buoy</description>
<icon>http://carocoops.org/gearth/images/00FF00_circle_icon.png</icon>
<website>http://www.carocoops.org/obskml/feeds/pachube/info.htm</website>
<email>jeremy.cothran\@gmail.com</email>
<location exposure="outdoor" domain="physical" disposition="fixed">
<name>$placemark_id</name>
<lat>$latitude</lat>
<lon>$longitude</lon>
<ele/>
</location>
END_OF_FILE
	
foreach my $observation ($placemark->findnodes('Metadata/obsList/obs')) {

        #add spaces and capitlize first letters to given obsType names
	my $obs_type = sprintf("%s",$observation->find('obsType'));

	my $uom = sprintf("%s",$observation->find('uomType'));
	my $s_order = sprintf("%s",$observation->find('sOrder'));
	if ($s_order eq '') { $s_order = 1; }

	my $sensor_id = sprintf("%d",$observation->find('sensorID'));
	#print "sensor_id: $sensor_id \n";

	#have to cast measurement to float using sprintf to avoid comparison confusion later
	my $measurement = sprintf("%.2f",$observation->find('value'));

	#print "$operator:$placemark_id:$obs_type:$uom:$datetime:$longitude:$latitude:$measurement\n";

	my $date_test = substr($datetime,0,4).substr($datetime,5,2).substr($datetime,8,2);

	#don't share erroneous 'future' observations greater than today's date or obs older than yesterday
	if (($date_test >= $date_yesterday) && ($date_test <= $date_now)) { 

	#print "html: $obs_label $measure_label \n";
        $html_content .= <<"END_OF_FILE";
      <data id="$obs_type.$uom.$s_order">
      <tag>$obs_type</tag>
      <value>$measurement</value>
      <unit>$uom</unit>
      </data>
END_OF_FILE
	
	}

} #foreach obs

$html_content .= "</environment></eeml>";

open (FILE_HTML,">./$placemark_id.xml");
print FILE_HTML $html_content;
close (FILE_HTML);

} #foreach Placemark
} #foreach file

exit 0;

########################

sub search_array {

my $search_term = shift @_;
my @search_array = @_;

foreach  my $search_page (@search_array) {
        if ($search_term =~ $search_page) { return 1; }
}

return 0;
}

