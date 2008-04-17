#!/usr/bin/perl
#script: gen_csv_obskml.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#Date: August 10, 2007
#script description
#Converts a set of ObsKML files to CSV

use strict;
use XML::LibXML;
use LWP::Simple;

###path config#############################################

#note the user process under which this runs needs to have permissions to write to the following paths

#a temporary directory for decompressing, processing files
my $temp_dir = '/tmp/ms_tmp';

my $csv_dir = '/var/www/html/obskml/feeds';

#this is a zip of 1 or more ObsKML files which will all be processed into the necessary oostethys support files
my $kml_zip_feed = 'http://nautilus.baruch.sc.edu/obskml/feeds/seacoos_all_latest.zip';

###########################################################

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

my $csv_content .= "platform_handle,observation_type.unit_of_measure,time,latitude,longitude,depth,measurement_value,data_url,operator_url,platform_url\n";

#the next sections jump between outputting the sos_config.xml file and querying the repeating xml elements for subtitution in the corresponding file elements.

##repeating elements section

foreach my $file (@files) {
my $xp = XML::LibXML->new->parse_file("$file");

#my $xp_xml = $xp->serialize; #debug
#print $xp_xml;

foreach my $platform ($xp->findnodes('//Placemark')) {
	#print "platform:$platform\n"; #debug

        #my $platform_id = $platform->find('Placemark[@id]');
        my $platform_id = sprintf("%s",$platform->find('name'));
        #my $platform_id = 'one';

        my $operator_url = sprintf("%s",$platform->find('Metadata/obsList/operatorURL'));
        my $platform_url = sprintf("%s",$platform->find('Metadata/obsList/platformURL'));

	my $lon_lat_string = sprintf("%s",$platform->find('Point/coordinates'));
	my ($longitude,$latitude) = split(/,/,$lon_lat_string);
	#print "$lon $lat \n";

	my $datetime = sprintf("%s",$platform->find('TimeStamp'));
	#print "$datetime \n";

	#initially I thought about just using $platform_name below, but decided to use the full $platform_id instead
	my ($organization_name, $platform_name, $package_name);
	my ($latlon_label_1,$latlon_label_2,$latlon_label_3);
	#if platform name is point like from VOS 'point(-81.3,32.5)' then parse differently than usual 
	#if ($platform_id =~ /point/) { ($organization_name, $latlon_label_1, $latlon_label_2, $latlon_label_3, $package_name) = split(/\./,$platform_id); $platform_name = $latlon_label_1.".".$latlon_label_2.".".$latlon_label_3; }
	if ($platform_id =~ /NR/ || $platform_id =~ /SHIP/) { #for vos the name element contains a bunch of junk that we need to swap out
		 ($organization_name,$platform_name,$package_name) = split(/\./,'vos.none.ship');
		 $platform_id = 'vos.point('.$lon_lat_string.').ship';
	}
	else { ($organization_name, $platform_name, $package_name) = split(/\./,$platform_id); }

	my $measurement = '';
	my $depth = '';	

        foreach my $observation ($platform->findnodes('Metadata/obsList/obs')) {
                $depth = sprintf("%s",$observation->find('elev'));
                $measurement = sprintf("%s",$observation->find('value'));
                my $parameter = sprintf("%s",$observation->find('obsType'));
                my $uom = sprintf("%s",$observation->find('uomType'));

		my $observed_property = $parameter.".".$uom;
		#print "$parameter $measurement \n";

                my $data_url = sprintf("%s",$observation->find('dataURL'));

		$csv_content .= '"'.$platform_id.'",'.$parameter.'.'.$uom.','.$datetime.','.$latitude.','.$longitude.','.$depth.','.$measurement.','.$data_url.','.$operator_url.','.$platform_url."\n";

        } #obs

} #Placemark

} #files

close (FILE_IN);

#write CSV file
open (FILE_CSV,">$csv_dir/all_latest.csv");
print FILE_CSV $csv_content;
close (FILE_CSV);

##zip CSV file
`cd $csv_dir; zip all_latest.csv.zip all_latest.csv`;

exit 0;

