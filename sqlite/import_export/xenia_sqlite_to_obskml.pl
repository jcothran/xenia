#!/usr/bin/perl
#xenia_sqlite_to_obskml.pl

# This script reads from the multi_obs table and creates an ObsKML file
# latest readings from each sensor on each platform.

#note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones

use DBI;
use XML::LibXML;
use strict;

#####################
#config
my $temp_dir = '.';

my $feed_name = 'secoora';

my $dbname = '/var/www/cgi-bin/microwfs/microwfs.db';

#####################

my $file_name = "$feed_name\_obskml_latest";

# See note below about what to expect from this DB.
my %latest_obs = ();
my $r_latest_obs = \%latest_obs;

#####################
##read sql query results into hash

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}

##note: the below sql will get observations from the previous day -- now() - interval '1 day'
#note: the below sql will get observations from the previous 8 hours (12 - 4 UTC = 8) - to counteract that the readout assumes synchronous obs composite on last measurement
#note: make sure support table m_type_display_order is populated -- see http://carocoops.org/twiki_dmcc/pub/Main/XeniaTableSchema/m_type_display_order.sql

#results ordered by multi_obs.platform_handle,m_type_display_order.row_id,sensor.s_order,m_date

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
    ,sensor.row_id
    ,sensor.s_order
    ,sensor.url
    ,platform.url
    ,platform.description
    ,organization.short_name
    ,organization.url
    ,m_type_display_order.row_id
  from multi_obs
    left join sensor on sensor.row_id=multi_obs.sensor_id
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id
    left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id
    left join platform on platform.row_id=sensor.platform_id
    left join organization on organization.row_id=platform.organization_id
    left join m_type_display_order on m_type_display_order.m_type_id=multi_obs.m_type_id
    where m_date > datetime('now','-12 hours')
  union
select null,platform.platform_handle,null,null,null,platform.fixed_longitude,platform.fixed_latitude,null,null,null,null,null,null,platform.url,platform.description,organization.short_name,organization.url,0 from platform
left join organization on organization.row_id=platform.organization_id
  where platform.active = 1
  order by 2,18,12,1 desc;
};

=comment
  union
select null,platform.platform_handle,null,null,null,platform.fixed_longitude,platform.fixed_latitude,null,null,null,null,null,platform.url,platform.long_name,organization.short_name,organization.url,null from platform
left join organization on organization.row_id=platform.organization_id
  where platform.active = 1
=cut

#  order by multi_obs.platform_handle,m_type_display_order.row_id,m_date desc;

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
    ,$sensor_id
    ,$s_order
    ,$sensor_url
    ,$platform_url
    ,$platform_desc
    ,$organization_name
    ,$organization_url
    ,$m_type_display_order
  ) = $sth->fetchrow_array) {

  #print "query:$platform_handle:$obs_type:$uom_type:$m_type_display_order\n";

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
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{sensor_url} = $sensor_url;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{sensor_id} = $sensor_id;

    #assuming all observations are basically the same lat/lon as platform
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat} = $m_lat;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon} = $m_lon;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url} = $platform_url;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{platform_desc} = $platform_desc;

    $latest_obs{operator_list}{$operator}{name} = $organization_name;
    $latest_obs{operator_list}{$operator}{url} = $organization_url;

    #print "obs:$platform_handle:$obs_type:$uom_type:$m_value\n";
  }

}
$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
	    # http://rt.cpan.org/Ticket/Display.html?id=22688

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
$operator_name = &escape_literals($operator_name);
my $operator_url = $latest_obs{operator_list}{$operator}{url};
$operator_url = &escape_literals($operator_url);

foreach my $platform_handle (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}}) {

my $m_lat = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat};
my $m_lon = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon};
my $platform_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url};
$platform_url = &escape_literals($platform_url);
my $platform_desc = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{platform_desc};
$platform_desc = &escape_literals($platform_desc);
my $platform_name = &escape_literals($platform_handle);

my $m_date = '';

print XML_FILE "<Placemark id=\"$platform_handle\">";

print XML_FILE "<Metadata>";
print XML_FILE "<obsList>";
print XML_FILE "<operatorURL>$operator_url</operatorURL>";
print XML_FILE "<operatorName>$operator_name</operatorName>";
print XML_FILE "<platformURL>$platform_url</platformURL>";
print XML_FILE "<platformName>$platform_name</platformName>";
print XML_FILE "<platformDescription>$platform_desc</platformDescription>";

foreach my $m_type_display_order (sort { $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$a} <=> $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$b} } keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}}) {

if ($m_type_display_order eq '0') { next; }

print XML_FILE "<obs>";

my $this_date = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date};

#only associating latest obs measurement date from platform for all platform obs - may be incorrect when missing certain platform obs at time
if ($this_date gt $m_date) { $m_date = $this_date; }

my $m_type_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_type_id};
my $obs_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{obs_type};
my $uom_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{uom_type};
my $m_z = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_z};
my $m_value = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_value};
my $qc_level = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{qc_level};
my $sensor_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{sensor_id};
my $sensor_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{sensor_url};
$sensor_url = &escape_literals($sensor_url);

print XML_FILE "<obsType>$obs_type</obsType>";
print XML_FILE "<uomType>$uom_type</uomType>";
print XML_FILE "<value>$m_value</value>";
print XML_FILE "<elev>$m_z</elev>";
print XML_FILE "<qc_level>$qc_level</qc_level>";
print XML_FILE "<dataURL>$sensor_url</dataURL>";
print XML_FILE "<sensorID>$sensor_id</sensorID>";

print XML_FILE "</obs>";
}
print XML_FILE "</obsList>";
print XML_FILE "</Metadata>";

print XML_FILE "<name>$platform_handle</name>";
print XML_FILE "<Point><coordinates>$m_lon,$m_lat</coordinates></Point>";

$m_date =~ s/ /T/g;
$m_date = substr($m_date,0,22);
#$m_date .= ':00'; #JTC - not sure what this line was for
if ($m_date ne '') { $m_date .= 'Z'; }
#print $m_date."\n";

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

