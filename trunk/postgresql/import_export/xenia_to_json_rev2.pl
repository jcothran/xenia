#
# Revisions:
# Version: 1.1
# Author: DWR
# Date: 10/21/2010
# Changes: Added the qc_level field to the output of the json file.
#
#!/usr/bin/perl
#xenia_sqlite_to_obskml.pl

# This script reads from the multi_obs table and creates latest hours GeoJSON data file for each platform

#note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones


print `date`;

use strict;
use Config::IniFiles;
use DBI;

#####################
#config
my $target_dir = '/home/xeniaprod/feeds/obsjson/all/latest_hours_24/simple/';
#my $target_dir = './json'; #testing

#####################

#database connect
my $cfg=Config::IniFiles->new( -file => '/home/xeniaprod/config/dbConfig.ini');
my $db_name="xenia";
my $db_user=$cfg->val($db_name,'username');
my $db_passwd=$cfg->val($db_name,'password');
my $dbh = DBI->connect ( "dbi:Pg:dbname=$db_name", $db_user, $db_passwd);
if ( !defined $dbh ) {
       die "Cannot connect to database!\n";
       exit 0;
}

my %latest_obs = ();
my $r_latest_obs = \%latest_obs;

#################
#process sql to hash

#and m_date > strftime('%Y-%m-%dT%H:%M:%S','now','-24 hours') #sqlite

my $sql = qq{
select
     organization.url 
    ,multi_obs.platform_handle
    ,platform.url
    ,obs_type.standard_name
    ,uom_type.standard_name
    ,m_date
    ,m_lon
    ,m_lat
    ,m_z
    ,m_value
    ,qc_level
  from multi_obs
    left join platform on platform.platform_handle=multi_obs.platform_handle
    left join organization on organization.row_id=platform.organization_id
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id  
    left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id  
  where m_date > now() - interval '1 day'
order by multi_obs.platform_handle,obs_type.standard_name,m_date;
};

my $sth = $dbh->prepare($sql);
$sth->execute();

while (my (
    $org_url,
    $platform_handle,
    $platform_url,
    $obs_type,
    $uom_type,
    $m_date,
    $m_lon,
    $m_lat,
    $m_z,
    $m_value,
    $qc_level
  ) = $sth->fetchrow_array) {

$latest_obs{platform_list}{$platform_handle}{org_url} = $org_url;
$latest_obs{platform_list}{$platform_handle}{platform_url} = $platform_url;
$latest_obs{platform_list}{$platform_handle}{m_lon} = $m_lon;
$latest_obs{platform_list}{$platform_handle}{m_lat} = $m_lat;

$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_type} = $uom_type;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_z} = $m_z;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{m_value} = $m_value;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{qc_level} = $qc_level;

} #process sql to hash 


######################################################
#open KML file for embedded

######################################################

my $missing_z = '-99999'; #represents missing z value

#process hash to GeoJSON file
foreach my $platform_handle (sort keys %{$r_latest_obs->{platform_list}}) {

my $org_url = $latest_obs{platform_list}{$platform_handle}{org_url};
my $platform_url = $latest_obs{platform_list}{$platform_handle}{platform_url};
my $platform_lon = $latest_obs{platform_list}{$platform_handle}{m_lon};
my $platform_lat = $latest_obs{platform_list}{$platform_handle}{m_lat};

my ($time_list,$obs_list,$point_list);

my $data_score = 0;

$obs_list = '';
#obsList
foreach my $obs_type (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}}) {
  $data_score++;

  my $uom_type = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_type};
  my $m_z = ','.$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_z};
  if ($m_z eq ",$missing_z") { $m_z = ""; } #don't want to confuse others with in-house convention for missing elev

#timeList
#assuming all obs report at same time for platform
#repeat creating time list - could optimize to just the first pass
$time_list = '';
$point_list = '';
my $value_list = '';
my $qc_level_list = '';
foreach my $m_date (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}}) {
  #print "m_date:$m_date\n";
  $time_list .= "\"$m_date\Z\",";

  my $m_value = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{m_value};
  $value_list .= "\"$m_value\","; 

  my $qc_level = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{qc_level};
  $qc_level_list .= "\"$qc_level\","; 

  $point_list .= "[$platform_lon,$platform_lat$m_z],"; 
}
chop($time_list); #drop trailing comma
chop($value_list); #drop trailing comma
chop($point_list); #drop trailing comma

if(length($obs_list))
{
  $obs_list .= ',';
}
$obs_list .= <<"END_OF_LIST";
        {"type": "Feature",
            "geometry": {
                "type": "MultiPoint",
                "coordinates": [$point_list] 
            },
         "properties": {
            "obsType": "$obs_type",
            "uomType": "$uom_type",
            "time": [$time_list],
            "value": [$value_list],
            "qc_level" : [$qc_level_list] 
        }}
END_OF_LIST

} #foreach $obs
#chop($obs_list); #drop trailing comma

######################################################
#write GeoJSON,KML file

my ($org_name,$platform_name,$package_name) = split(/\./,$platform_handle);
$platform_handle =~ s/\./:/g ;

my $platformName = lc($platform_handle);
#metadata
open (JSON_FILE, ">$target_dir/$platformName\_metadata.json");

my $json_content_metadata = <<"END_OF_LIST";
{
"type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [$platform_lon,$platform_lat]
            },
"properties": {
    "schemaRef": "ioos_blessed_schema_name_reference",
    "dictionaryRef": "ioos_blessed_obstype_uom_dictionary_reference",
    "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",
    "organizationName": "$org_name",
    "organizationURL": "$org_url",
    "stationURL": "$platform_url",
    "stationTypeName": "buoy",
    "stationTypeImage": "http://www.ndbc.noaa.gov/images/stations/3m.jpg",
    "stationId": "urn:x-noaa:def:station:$org_name\::$platform_name",

    "origin":"National Data Buoy Center",
    "useconst":"The information on government servers are in the public domain, unless specifically annotated otherwise, and may be used freely by the public so long as you do not 1) claim it is your own (e.g. by claiming copyright for NWS information -- see below), 2) use it in a manner that implies an endorsement or affiliation with NOAA/NWS, or 3) modify it in content and then present it as official government material. You also cannot present information of your own in a way that makes it appear to be official government information."
}
}
END_OF_LIST

print JSON_FILE $json_content_metadata;
close (JSON_FILE);


#data
open (JSON_FILE, ">$target_dir/$platformName\_data.json");

my $json_content_data = <<"END_OF_LIST";
{
"type": "FeatureCollection",
"properties": {
    "stationId": "urn:x-noaa:def:station:$org_name\::$platform_name",

    "features": [$obs_list]
}
}
END_OF_LIST

print JSON_FILE $json_content_data;
close (JSON_FILE);


} #foreach $platform_handle - process hash to json

#####


$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
	    # http://rt.cpan.org/Ticket/Display.html?id=22688

$dbh->disconnect();

print `date`;
exit 0;

#--------------------------------------------------------------------
#                   escape_literals
#--------------------------------------------------------------------

#$operator_url = &escape_literals($operator_url);

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

