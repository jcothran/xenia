#!/usr/bin/perl
#xenia_sqlite_to_obskml.pl

# This script reads from the multi_obs table and creates latest hours GeoJSON data file for each platform

#note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones

use DBI;
use strict;

#####################
#config
my $target_dir = '/var/www/html/obsjson/feeds/all/latest_hours_12/';
#my $target_dir = './json'; #testing

my $dbname = '/var/www/cgi-bin/microwfs/microwfs.db';

#####################

#database connect
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}

my %latest_obs = ();
my $r_latest_obs = \%latest_obs;

#################
#process sql to hash

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
  from multi_obs
    left join platform on platform.platform_handle=multi_obs.platform_handle
    left join organization on organization.row_id=platform.organization_id
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id  
    left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id  
  and m_date > strftime('%Y-%m-%dT%H:%M:%S','now','-12 hours')
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
    $m_value
  ) = $sth->fetchrow_array) {

$latest_obs{platform_list}{$platform_handle}{org_url} = $org_url;
$latest_obs{platform_list}{$platform_handle}{platform_url} = $platform_url;
$latest_obs{platform_list}{$platform_handle}{m_lon} = $m_lon;
$latest_obs{platform_list}{$platform_handle}{m_lat} = $m_lat;

$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_type} = $uom_type;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_z} = $m_z;
$latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{m_value} = $m_value;

} #process sql to hash 


######################################################
#process hash to GeoJSON file
foreach my $platform_handle (sort keys %{$r_latest_obs->{platform_list}}) {

my $org_url = $latest_obs{platform_list}{$platform_handle}{org_url};
my $platform_url = $latest_obs{platform_list}{$platform_handle}{platform_url};
my $platform_lon = $latest_obs{platform_list}{$platform_handle}{m_lon};
my $platform_lat = $latest_obs{platform_list}{$platform_handle}{m_lat};

my ($time_list,$obs_list);

$obs_list = '';
#obsList
foreach my $obs_type (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}}) {
  my $uom_type = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{uom_type};
  my $m_z = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_z};
  if ($m_z eq '-99999') { $m_z = ""; } #don't want to confuse others with in-house convention for missing elev

#timeList
#assuming all obs report at same time for platform
#repeat creating time list - could optimize to just the first pass
$time_list = '';
my $value_list = '';
foreach my $m_date (sort keys %{$r_latest_obs->{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}}) {
  #print "m_date:$m_date\n";
  $time_list .= "\"$m_date\Z\",";

  my $m_value = $latest_obs{platform_list}{$platform_handle}{obs_list}{$obs_type}{m_date}{$m_date}{m_value};
  $value_list .= "\"$m_value\","; 
}
chop($time_list); #drop trailing comma
chop($value_list); #drop trailing comma

$obs_list .= <<"END_OF_LIST";
        {
            "obsType": "$obs_type",
            "uomType": "$uom_type",
            "valueList": [$value_list],
            "elevRel": "$m_z"
        }
END_OF_LIST
$obs_list .= ",";

} #foreach $obs
chop($obs_list); #drop trailing comma

######################################################
#write GeoJSON file

open (JSON_FILE, ">$target_dir/$platform_handle.json");

my ($org_name,$platform_name,$package_name) = split(/\./,$platform_handle);

my $json_content = <<"END_OF_LIST";
$platform_handle({
"type": "Feature",
"geometry": {
    "type": "Point",
    "coordinates": [$platform_lon,$platform_lat,0] 
},
"properties": {
    "schemaRef": "ioos_blessed_schema_name_reference",
    "dictionaryRef": "ioos_blessed_obstype_uom_dictionary_reference",
    "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",
    "operatorName": "$org_name",
    "operatorURL": "$org_url",
    "platformName": "$platform_name",
    "platformURL": "$platform_url",
    "stationId": "urn:x-noaa:def:station:$org_name\::$platform_name",

    "time": [$time_list],

    "obsList": [$obs_list]
}
}) 
END_OF_LIST

print JSON_FILE $json_content;

close (JSON_FILE);

} #foreach $platform_handle - process hash to json

#####

$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
	    # http://rt.cpan.org/Ticket/Display.html?id=22688

$dbh->disconnect();

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

