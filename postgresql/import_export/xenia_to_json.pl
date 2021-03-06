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
my $target_dir = '/home/xeniaprod/feeds/obsjson/all/latest_hours_24/';
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
    ,sensor.s_order
  from multi_obs
    left join platform on platform.platform_handle=multi_obs.platform_handle
    left join organization on organization.row_id=platform.organization_id
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join sensor on sensor.row_id=multi_obs.sensor_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id  
    left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id  
  where m_date > now() - interval '1 day' AND sensor.active=1
order by multi_obs.platform_handle,obs_type.standard_name,m_date;
};
#where m_date > now() - interval '1 day' and multi_obs.platform_handle like 'scdnr.%'   #debug
my $lastPlatform = "";
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
    $sorder
  ) = $sth->fetchrow_array) {

#print "$platform_handle:$obs_type:$uom_type:$m_date:$m_z:$sorder:$m_value\n"; #debug
$platform_handle = lc($platform_handle);

$latest_obs{platform_list}{$platform_handle}{org_url} = $org_url;
$latest_obs{platform_list}{$platform_handle}{platform_url} = $platform_url;
$latest_obs{platform_list}{$platform_handle}{m_lon} = $m_lon;
$latest_obs{platform_list}{$platform_handle}{m_lat} = $m_lat;

$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{uom_type} = $uom_type;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{m_z} = $m_z;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{m_date}{$m_date}{m_value} = $m_value;

} #process sql to hash 


######################################################
#open KML file for embedded
open (KML_FILE, ">$target_dir/all_latest.kml");

my $kml_content .= <<"END_OF_LIST";
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
   <!-- A simple KML example demonstrating the parsing of an ObsJSON v2 file Google Earth 5,. giencke@[gmail|google].com -->
    <name>Parsing ObsJSON v3 in KML</name>
END_OF_LIST

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
foreach my $uom_type (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}}) {
foreach my $sorder (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}}) {
  $data_score++;

  my $uom_type = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{uom_type};
  my $m_z = ','.$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{m_z};
  if ($m_z eq ",$missing_z") { $m_z = ""; } #don't want to confuse others with in-house convention for missing elev

#timeList
#assuming all obs report at same time for platform
#repeat creating time list - could optimize to just the first pass
$time_list = '';
$point_list = '';
my $value_list = '';
foreach my $m_date (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{m_date}}) {
  #print "m_date:$m_date\n";
  $time_list .= "\"$m_date\Z\",";

  my $m_value = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_list}{$uom_type}{sorder_list}{$sorder}{m_date}{$m_date}{m_value};
  #print "$platform_handle:$obs_type:$uom_type:$m_date:$m_z:$sorder:$m_value\n"; #debug
  $value_list .= "\"$m_value\","; 

  $point_list .= "[$platform_lon,$platform_lat$m_z],"; 
}
chop($time_list); #drop trailing comma
chop($value_list); #drop trailing comma
chop($point_list); #drop trailing comma

#substitute spaces for underscore for search engine discovery purposes
my $obs_type_space = $obs_type;
$obs_type_space =~ s/_/ /g;

$obs_list .= <<"END_OF_LIST";
        {"type": "Feature",
            "geometry": {
                "type": "MultiPoint",
                "coordinates": [$point_list] 
            },
         "properties": {
            "obsTypeDesc": "$obs_type_space",
            "obsType": "$obs_type",
            "uomType": "$uom_type",
            "sorder": "$sorder",
            "time": [$time_list],
            "value": [$value_list]
        }},
END_OF_LIST

} #foreach $sorder
} #foreach $uom
} #foreach $obs
chop($obs_list); #drop trailing comma

######################################################
#write GeoJSON,KML file

my ($org_name,$platform_name,$package_name) = split(/\./,$platform_handle);
$platform_handle =~ s/\./:/g ;

#metadata
open (JSON_FILE, ">$target_dir/$platform_handle\_metadata.json");

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
open (JSON_FILE, ">$target_dir/$platform_handle\_data.json");

my $json_content_data = <<"END_OF_LIST";
json_callback({
"type": "FeatureCollection",
    "stationId": "urn:x-noaa:def:station:$org_name\::$platform_name",
    "features": [$obs_list]
})
END_OF_LIST

print JSON_FILE $json_content_data;
close (JSON_FILE);

#print KML
$kml_content .= <<"END_OF_LIST";
    <Placemark id="$platform_handle">
      <name>$platform_handle</name>
      <description><![CDATA[]]></description>
      <!--using personal Sites page for hosting, file replicated on ioos-kml Groups page-->
      <styleUrl>http://sites.google.com/site/giencke/Home/obs_json_style_v3.kml#json_embedded</styleUrl>

<ExtendedData>
<!--From http://code.google.com/p/xenia/wiki/ObsJSON#Demo_1 -->
<Data name="ObsJSON_Example_metadata">
<value>$json_content_metadata</value>
</Data>
<Data name="score">
<value>$data_score</value>
</Data>
<Data name="ObsJSON_Example_data">
<value>$json_content_data</value>
</Data>
</ExtendedData>

      <Point>
        <coordinates>$platform_lon,$platform_lat,0</coordinates>
      </Point>
    </Placemark>
END_OF_LIST

} #foreach $platform_handle - process hash to json

#####

$kml_content .= <<"END_OF_LIST";
  </Document>
</kml>
END_OF_LIST

print KML_FILE $kml_content;
close (KML_FILE);
`cd $target_dir; zip all_latest.kmz all_latest.kml`;

$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
	    # http://rt.cpan.org/Ticket/Display.html?id=22688

$dbh->disconnect();

print `date`;
exit 0;

sub getPlatformStatus()
{
  my $platform_handle = shift;
  $sql = "SELECT begin_date,reason FROM platform_status WHERE platform_handle = '$platform_handle' AND end_date IS NULL;";

  my $sth = $dbh->prepare($sql);
  if(!$sth->execute())
  {
    print("Failed to execute query $sth->errstr\n SQLStatement: $sql\n");
    return(-1);
  }
  my @row_ary = $sth->fetchrow_array();
  if(@row_ary != undef)
  {
    my %status = {};
    $status{begin_date} = $row_ary[0];
    $status{reason} = 'No data received from platform.';
    if(length($row_ary[1]))
    {
      $status{reason} = $row_ary[1]; 
    }
    return(\%status);
  }
  return(undef);
}
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

