#!/usr/bin/perl
#script: obskml_to_xenia_postgresql.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SECOORA
#Date: June 10, 2009
#script description
#transforms ObsKML into SQL inserts for Xenia DB schema(version 3.1)

use strict;
use XML::LibXML;
use DBI;
use Config::IniFiles;
use LWP::Simple;

#log run out
my $date_now = `date +%Y-%m-%dT%H:%M:%S`;
chomp($date_now);
print "obskml_to_xenia_postgresql.pl run start $date_now\n";

my ($missing_count,$measurement_count);

####################
#config
#usage: perl <path>/obskml_to_xenia_sqlite.pl <input zipped kml files> <optional: debug output sql directory> <optional: output sql filename prefix> >> <log file>
#note if using debug output sql directory to create a 'archive_in' subdirectory there also which is written to in the script below

#usage: perl obskml_to_xenia_sqlite.pl http://carocoops.org/obskml/feeds/seacoos_all_latest.zip >>/tmp/debug.log 2>/dev/null

#usage debug: perl obskml_to_xenia_sqlite.pl http://carocoops.org/obskml/feeds/seacoos_all_latest.zip /mydir >>/tmp/debug.log 2>/dev/null

#VM_CONFIG_START

#$db_name = 'xenia','xenia_moving';
my $db_name   = @ARGV[3];

#config
my $cfg=Config::IniFiles->new( -file => '/home/xeniaprod/config/dbConfig.ini');
my $db_user=$cfg->val($db_name,'username');
my $db_passwd=$cfg->val($db_name,'password');
my $dbh = DBI->connect ( "dbi:Pg:dbname=$db_name", $db_user, $db_passwd);
if ( !defined $dbh ) {
       die "Cannot connect to database!\n";
       exit 0;
}
my ($sql,$sth);

#VM_CONFIG_END

#note the user process under which this runs needs to have permissions to write to the following paths

#a temporary directory for decompressing, processing files
my $temp_dir = '/home/xeniaprod/tmp';
my $path_dir_sql = @ARGV[1];
if ($path_dir_sql eq '') { $path_dir_sql = '.'; }
my $filename_sql = @ARGV[2];
if ($filename_sql eq '') { $filename_sql = 'latest'; }
my $path_sqlfile = "$path_dir_sql/$filename_sql.sql";
my $path_sqlfile_archive = "$path_dir_sql/archive_in/latest_$date_now.sql";
my $path_zipfile_archive = "$path_dir_sql/archive_in/latest_$date_now.zip";

#note: the subroutine get_m_type_id has custom substituted synonyms for certain terms
#see CONFIG_START withing get_m_type sub

#provide input date cutoff for observation data
my $date_cutoff = `date --date='3 days ago' +%Y-%m-%dT%H:%M:%S`;
chomp($date_cutoff);
#$date_cutoff = '2008-01-18T13:00:00'; #manual set/debug
#print $date_cutoff;

#lat/long bounding box cutoff
my $lat_min_cutoff = -90.00;
my $lat_max_cutoff = 90.00;
my $long_min_cutoff = -180.00;
my $long_max_cutoff = 180.00;

#originally resolving seconds for dropping duplicates, but dropping time seconds resolution due to duplicates(:00, :40 secs) which are probably netcdf truncating related
#see usage in code below
my $time_seconds_resolution_flag == 0;

open (SQL_OUT, ">$path_sqlfile");
open (SQL_OUT_ARCHIVE, ">$path_sqlfile_archive");
#print SQL_OUT "BEGIN IMMEDIATE TRANSACTION;\n";

###########################################################

#this is a zip of 1 or more ObsKML files which will all be processed into the necessary oostethys support files
#my $kml_zip_feed = 'http://carocoops.org/obskml/feeds/wq/wq_metadata_latest.kmz';
my $kml_zip_feed = @ARGV[0];
#print( "KML Feed: $kml_zip_feed\n" ); 
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

my $retVal = getstore("$kml_zip_feed", $zip_filepath); 
if( is_success( $retVal ) )
{
  print( "Success: $kml_zip_feed downloaded to $zip_filepath\n");
}
else
{   
  print( "Error: $retVal Failed to download: $kml_zip_feed\n");
}  

#getstore("$kml_zip_feed", $zip_filepath);
getstore("$kml_zip_feed", $path_zipfile_archive);
`cd $target_dir; unzip obskml.xml.zip`;

my $filelist = `ls $target_dir/*.kml`;
#print $filelist;
my @files = split(/\n/,$filelist);
#print @files;

#my $content = getstore('http://carocoops.org/obskml/scripts/to_xenia/seacoos_test1.kml','seacoos_test1.kml');
#die "Couldn't get document" unless defined $content;

#my @platform_ignore = qw(carocoops ndbc.MLRF1 vos);
my @platform_ignore = qw();

####initialize lookup hash for sub get_m_type_id

my %m_type_lookup = ();

$sql = qq{ select t0.row_id,t2.standard_name,t3.standard_name from m_type t0,m_scalar_type t1,obs_type t2,uom_type t3 where t0.m_scalar_type_id = t1.row_id and t0.num_types = 1 and t1.obs_type_id = t2.row_id and t1.uom_type_id = t3.row_id };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();

while (my ($row_id,$obs_type,$uom) = $sth->fetchrow_array) {
        #print "$row_id $obs_type $uom\n";
        $m_type_lookup{$obs_type.".".$uom} = $row_id;
};
####

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
        $operator_url = escape_literals($operator_url);
        my $platform_url = sprintf("%s",$platform->find('Metadata/obsList/platformURL'));
        $platform_url = escape_literals($platform_url);
        my $platform_desc = sprintf("%s",$platform->find('Metadata/obsList/platformDescription'));
        $platform_desc = escape_literals($platform_desc);

        my $lon_lat_string = sprintf("%s",$platform->find('Point/coordinates'));
        my ($longitude,$latitude) = split(/,/,$lon_lat_string);
        #only carry lon/lat precision to six decimal places
        $longitude = sprintf("%.6f", $longitude);
        $latitude = sprintf("%.6f", $latitude);
        #print "$lon $lat \n";

        if (($latitude < $lat_min_cutoff) || ($latitude > $lat_max_cutoff) || ($longitude < $long_min_cutoff) || ($longitude > $long_max_cutoff)) { print "rejecting lat/long\n"; next; }

        my $m_date = sprintf("%s",$platform->find('TimeStamp/when'));
        #print "$m_date :when \n";

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
        #print "$m_date :calculated\n";

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

                $sql = qq{ INSERT into organization(active,short_name,url) values (1,'$organization_name','$operator_url'); };
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

                $sql = qq{ INSERT into platform(organization_id,short_name,platform_handle,fixed_longitude,fixed_latitude,long_name,description,url) values ($organization_row_id,'$platform_name','$platform_id',$longitude,$latitude,'$platform_desc','$platform_desc','$platform_url'); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                #requery for new row_id
                $sql = qq{ SELECT row_id from platform where organization_id = $organization_row_id and platform_handle like '$platform_id' };
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
                my $sorder = sprintf("%s",$observation->find('sorder'));
                my $qclevel = sprintf("%s",$observation->find('QCLevel'));

                my $m_type_id = get_m_type_id($obs_type,$uom_type);
                if ($m_type_id eq '') { print "$obs_type.$uom_type undefined \n"; next; }

        ##sensor####################

        if ($sorder eq '') { $sorder = 1; }

        $sql = qq{ SELECT row_id from sensor where m_type_id = $m_type_id and platform_id = $platform_row_id and s_order = $sorder };
        #print $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();
        my ($sensor_row_id) = $sth->fetchrow_array;

        if ($sensor_row_id) {} #print "$sensor_row_id\n"; }
        else {
                print "sensor $obs_type.$uom_type not found - inserting\n";

                $sql = qq{ INSERT into sensor(platform_id,m_type_id,s_order) values ($platform_row_id,$m_type_id,$sorder); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                #requery for new row_id
                $sql = qq{ SELECT row_id from sensor where m_type_id = $m_type_id and platform_id = $platform_row_id and s_order = $sorder };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();
                ($sensor_row_id) = $sth->fetchrow_array;

        }

        ##observation####################

        if ($elev eq '') { $elev = -99999; }

        $measurement_count++;
        if ($qclevel ne '' && $qclevel ne '0' && $qclevel ne '3') { print "qclevel suspect/bad/missing($qclevel) measurement: $platform_id:$obs_type.$uom_type $m_date\n"; next; }
        if ($measurement eq '') { print "missing measurement: $platform_id:$obs_type.$uom_type $m_date\n"; $missing_count++; next; }
	if (!(isnumeric($measurement))) { print "nonnumeric measurement: $platform_id:$obs_type.$uom_type $m_date\n"; $missing_count++; next; }

        $sql = qq{ INSERT into multi_obs(platform_handle,sensor_id,m_type_id,m_date,m_lon,m_lat,m_z,m_value) values ('$platform_id',$sensor_row_id,$m_type_id,'$m_date',$longitude,$latitude,$elev,$measurement); };
        #print $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();

        #sqlite note: tried running the above insert statement dynamically, like the others, but ran into problems with duplicates instead of being ignored
        #and the program continuing, causing the program to halt(tried getting around this using an 'eval' block but still had problems)
        #so just decided to write all these inserts to an output file and load them from there

        print SQL_OUT $sql."\n";
        print SQL_OUT_ARCHIVE $sql."\n";

        } #foreach $observation

        #$sth->finish();
} #foreach $platform

} #foreach $file

$sth->finish();
$dbh->disconnect();

#print SQL_OUT "COMMIT TRANSACTION;\n";
close (SQL_OUT);
close (SQL_OUT_ARCHIVE);

my $missing_ratio = sprintf("%d", ($missing_count/$measurement_count)*100);
print "missing_count/measurement_count = $missing_count/$measurement_count $missing_ratio% \n";

$date_now = `date +%Y-%m-%dT%H:%M:%S`;
chomp($date_now);
print "obskml_to_xenia_postgresql.pl run stop $date_now\n";

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

sub get_m_type_id {
my ($obs_type,$uom) = @_;

##CONFIG_START

#conversions for the following which were labeled wrong on the way in to db
if ($obs_type eq 'dissolved_oxygen') { $obs_type = 'oxygen_concentration'; }
if ($uom eq 'millibar') { $uom = 'mb'; }
if ($uom eq 'percent_saturation') { $uom = 'percent'; }
if ($uom eq 'm(MLLW)') { $uom = 'm'; }

##CONFIG_END



my $ret_val = $m_type_lookup{$obs_type.".".$uom};
return $ret_val;
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

sub isnumeric {
my $arg = shift;
if ($arg =~ /^-?(\d+\.?\d*|\.\d+)$/ ) { return 1; }  # match valid number
else { return 0; }
}
