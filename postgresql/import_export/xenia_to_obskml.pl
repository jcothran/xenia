#!/usr/bin/perl
#xenia_to_obskml.pl

# This script reads from the multi_obs table and creates an ObsKML file
# latest readings from each sensor on each platform.

#note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones

use DBI;
use XML::LibXML;
use strict;

#####################
#config
my $db_host  = 'db_server';
my $db_name   = 'db_xenia_wx';
my $db_user   = 'postgres';
my $db_passwd = '';
my $temp_dir = '/var/tmp/ms_tmp/obskml';

my $feed_name = 'sverdrup';

#####################

my $file_name = "$feed_name\_obskml_latest";

# See note below about what to expect from this DB.
my %latest_obs = ();
my $r_latest_obs = \%latest_obs;

#####################
##read sql query results into hash

my $dbh = DBI->connect ("dbi:Pg:dbname=$db_name;host=$db_host","$db_user","$db_passwd");
if(!defined $dbh) {die "Cannot connect to database!\n";}

#note: the below sql will get observations from the previous day -- now() - interval '1 day'
#note: make sure support table m_type_display_order is populated -- see http://carocoops.org/twiki_dmcc/pub/Main/XeniaTableSchema/m_type_display_order.sql

my $sql = qq{
  select m_date
    ,multi_obs.platform_handle
    ,obs_type.standard_name
    ,uom_type.standard_name
    ,multi_obs.m_type_id
    ,m_lon
    ,m_lat
    ,m_z
    ,m_value
    ,qc_level
    ,sensor.url
    ,platform.url
    ,organization.short_name
    ,organization.url
    ,m_type_display_order.row_id
  from multi_obs
    left join sensor on sensor.row_id=multi_obs.sensor_id
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join obs_type on obs_type.row_id=m_type.obs_type_id
    left join uom_type on uom_type.row_id=m_type.uom_type_id
    left join platform on platform.row_id=sensor.platform_id
    left join organization on organization.row_id=platform.organization_id
    left join m_type_display_order on m_type_display_order.m_type_id=multi_obs.m_type_id
    where m_date > now() - interval '1 day'
  order by platform_handle,m_type_display_order.row_id,m_date desc;
};

my $sth = $dbh->prepare($sql);
$sth->execute();

while (my (
     $m_date
    ,$platform_handle
    ,$obs_type
    ,$uom_type
    ,$m_type_id
    ,$m_lon
    ,$m_lat
    ,$m_z
    ,$m_value
    ,$qc_level
    ,$sensor_url
    ,$platform_url
    ,$organization_name
    ,$organization_url
    ,$m_type_display_order
  ) = $sth->fetchrow_array) {

  #print "$platform_handle:$obs_type:$uom_type:$m_type_display_order\n";

  # Since the obs are ordered by time descending, we only need to keep the
  # top times per platform/sensor.  
  # note using $m_type_display_order for a unique obs&uom key 
  my $operator = $organization_name;
  if (!defined $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}) {
    #have to add 'obs_list' for sorting level layer
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_type_id}  = $m_type_id;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{obs_type} = $obs_type;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{uom_type} = $uom_type;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}  = $m_date;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_value} = $m_value;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_z}     = $m_z;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{qc_level} = $qc_level;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{url} = $sensor_url;

    #assuming all observations are basically the same lat/lon as platform
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat} = $m_lat;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon} = $m_lon;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url} = $platform_url;

    $latest_obs{operator_list}{$operator}{name} = $organization_name;
    $latest_obs{operator_list}{$operator}{url} = $organization_url;

    #print "$platform_handle:$obs_type:$uom_type\n";
  }

}
$sth->finish;
$dbh->disconnect();

#####################
##print XML from hash

open (XML_FILE, ">$temp_dir/$file_name.kml");

my $xml_snippet = <<"END_OF_LIST";
<kml xmlns:kml="http://earth.google.com/kml/2.1" xmlns:obsList="http://carocoops.org/obskml/1.0.0/obskml_simple.xsd">
<!-- JTC - please forgive any unorthodoxy in the namespace declaration above, there's a bug with the perl XML::XPath package I'm using where all xmlns must be declared in the root element using prefix notation -->
<Document>
  <name>Obskml latest</name>
    <open>1</open>
END_OF_LIST

print XML_FILE $xml_snippet;

foreach my $operator (sort keys %{$r_latest_obs->{operator_list}}) {

my $operator_name = $latest_obs{operator_list}{$operator}{name};
my $operator_url = $latest_obs{operator_list}{$operator}{url};

foreach my $platform_handle (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}}) {

my $m_lat = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat};
my $m_lon = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon};
my $platform_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url};
$platform_url = &escape_literals($platform_url);

my $m_date = '';

print XML_FILE "<Placemark id=\"$platform_handle\">";

print XML_FILE "<Metadata>";
print XML_FILE "<obsList>";
print XML_FILE "<operatorURL>$operator_url</operatorURL>";
print XML_FILE "<operatorName>$operator_name</operatorName>";
print XML_FILE "<platformURL>$platform_url</platformURL>";
print XML_FILE "<platformName>$platform_handle</platformName>";

foreach my $m_type_display_order (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}}) {
print XML_FILE "<obs>";

$m_date = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date};
$m_date =~ s/ /T/g;
$m_date .= 'Z';

my $m_type_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_type_id};
my $obs_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{obs_type};
my $uom_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{uom_type};
my $m_z = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_z};
my $m_value = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_value};
my $qc_level = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{qc_level};
my $sensor_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{sensor_url};
$sensor_url = &escape_literals($sensor_url);

print XML_FILE "<obsType>$obs_type</obsType>";
print XML_FILE "<uomType>$uom_type</uomType>";
print XML_FILE "<value>$m_value</value>";
print XML_FILE "<elev>$m_z</elev>";
print XML_FILE "<qc_level>$qc_level</qc_level>";
print XML_FILE "<dataURL>$sensor_url</dataURL>";

print XML_FILE "</obs>";
}
print XML_FILE "</obsList>";
print XML_FILE "</Metadata>";

print XML_FILE "<name>$platform_handle</name>";
print XML_FILE "<Point><coordinates>$m_lon,$m_lat</coordinates></Point>";
print XML_FILE "<TimeStamp><when>$m_date</when></TimeStamp>";

print XML_FILE "</Placemark>";
} #foreach platform_handle
} #foreach operator

my $xml_snippet = <<"END_OF_LIST";
</Document>
</kml>
END_OF_LIST

print XML_FILE $xml_snippet;
close (XML_FILE);

##zip latest_obs.kml file
`cd $temp_dir; zip $file_name.kmz $file_name.kml`;

exit 0;

sub escape_literals {

my $platform_url = shift;
$platform_url =~ s/&/&amp;/ ;

return $platform_url;

}
