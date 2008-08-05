#!/usr/bin/perl
# Author(main body): Jeremy Cothran (jeremy.cothran@gmail.com)
# Author(support functions - parse_config_file,escape_literals,gripe,getDateTime): John R. Ulmer (PSGS Contractor for NOAA CSC)

use strict;
use DBI;

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

# instantiate CGI object
my $cgi;
$cgi = new CGI;
$| = 1; # Turn on autoflush

#####################
#config

#note the use of the 'like' operator in the sql 'offering' parameter - this is length checked but may need to be fully checked against a set list for security reasons

#note sub set_obstype_related and hardcoding there

# Edit the following line to point at your config file.
my $config_location = '/var/www/cgi-bin/microwfs/difSOSConf.xml';

#Global vars - FIX more vars here than needed
my ($config,
    $dbname, 
    $logDir, %valid_type_names,
    $obstype,$obstype_label,$offering,
    $query_min_lon, $query_min_lat, $query_max_lon, $query_max_lat,
    $response_min_lon, $response_min_lat, $response_max_lon, $response_max_lat,
    $srsName, $sensorCodeSpace, $verticalDatumCodeSpace, $verticalPositionUom,$obsNameCodeSpace,
    $query_start_datetime, $query_end_datetime,
    $response_start_datetime, $response_end_datetime);

# open/read config file
&parse_config_file();

open(LOG,">>$logDir/difSOS.log") or die "Failed to open log file($logDir/difSOS.log), $!\n";
my $run_date_time = getDateTime();

# parse and check input parameters.  Must regex each input carefully to avoid
# DB code insertion hack.  All three user supplied inputs are controlled.
&parse_check_inputs;

=comment
# print appropriate HTTP header and XML content
print $cgi->header(-type=>'text/xml'),qq(<xml></xml>);
exit 0;
=cut

######################

=comment
#testing/development values
my $query_min_lat = '32';
my $query_max_lat = '36';
my $query_min_lon = '-80';
my $query_max_lon = '-75';

#for time last, leave start/end datetime empty
my $query_start_datetime = '2008-07-30T00:00:00';
my $query_end_datetime = '2008-07-31T00:00:00';

my $obstype = 'watertemperature';

my $offering = 'usgs.021720710.wq';
my $offering = 'usgs.0217';
=cut

my $like_clause = '';
#print LOG "offering = $offering\n"; 
if ($offering) { $like_clause = "and multi_obs.platform_handle like '%$offering%'"; }

my $bbox_clause = '';
if ($query_min_lon) { $bbox_clause = "and m_lat >= $query_min_lat and m_lat <= $query_max_lat and m_lon >= $query_min_lon and m_lon <= $query_max_lon"; }

#map $obstype to $query_m_type_id
my ($query_m_type_id,$uom);
&set_obstype_related();

my $date_clause = '';

my $time_last = '';
if (!($query_start_datetime) && (!$query_end_datetime)) { $time_last = 'true'; }

if ($time_last) {
#note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones
	$date_clause = "m_date > datetime('now','-1 day')";
}
else {
	$date_clause = "m_date >= '$query_start_datetime' and m_date <= '$query_end_datetime'";
}
#print "time_last = $time_last \n$date_clause\n";

#####################

# See note below about what to expect from this DB.
my %latest_obs = ();
my $r_latest_obs = \%latest_obs;

#####################
##read sql query results into hash

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
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
    ,sensor.row_id
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
    where multi_obs.m_type_id = $query_m_type_id 
	$bbox_clause
	$like_clause
	and $date_clause
  order by multi_obs.platform_handle,m_type_display_order.row_id,m_date desc;
};

print LOG "$run_date_time \n\tSQL: $sql\n";
my $sth = $dbh->prepare($sql) or gripe("Database Error", $dbh->errstr);

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
    ,$sensor_url
    ,$platform_url
    ,$platform_desc
    ,$organization_name
    ,$organization_url
    ,$m_type_display_order
  ) = $sth->fetchrow_array) {

  #print "$platform_handle:$obs_type:$uom_type:$m_type_display_order\n";

#bounding area and time
if (!($response_min_lat)) { $response_min_lat = $m_lat; }
if (!($response_max_lat)) { $response_max_lat = $m_lat; }
if (!($response_min_lon)) { $response_min_lon = $m_lon; }
if (!($response_max_lon)) { $response_max_lon = $m_lon; }
 
if ($m_lat < $response_min_lat) { $response_min_lat = $m_lat; }
if ($m_lat > $response_max_lat) { $response_max_lat = $m_lat; }
if ($m_lon < $response_min_lon) { $response_min_lon = $m_lon; }
if ($m_lon > $response_max_lon) { $response_max_lon = $m_lon; }

if (!($response_start_datetime)) { $response_start_datetime = $m_date; }
if (!($response_end_datetime)) { $response_end_datetime = $m_date; }

if ($m_date lt $response_start_datetime) { $response_start_datetime = $m_date; }
if ($m_date gt $response_end_datetime) { $response_end_datetime = $m_date; }

  # Since the obs are ordered by time descending, we only need to keep the
  # top times per platform/sensor.  
  # note using $m_type_display_order for a unique obs&uom key 
  my $operator = $organization_name;

  #determine whether to add to the hash based on whether this is a 'latest' or 'start/end date' query
  my $add_to_hash = '';

  if (($time_last) && !defined $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}) { $add_to_hash = 'true'; }
  if (!($time_last) && !defined $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}) { $add_to_hash = 'true'; }

  if ($add_to_hash) {
    #have to add 'obs_list' for sorting level layer
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_type_id}  = $m_type_id;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{obs_type} = $obs_type;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{uom_type} = $uom_type;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_value} = $m_value;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_z}     = $m_z;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{qc_level} = $qc_level;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{sensor_url} = $sensor_url;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{sensor_id} = $sensor_id;

    #assuming all observations are basically the same lat/lon as platform
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat} = $m_lat;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon} = $m_lon;

    #assuming for one obstype(and only one, no redundant or s_order) that m_z,sensor_id is the same
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_z} = $m_z;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{sensor_id} = $sensor_id;

    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url} = $platform_url;
    $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{desc} = $platform_desc;

    $latest_obs{operator_list}{$operator}{name} = $organization_name;
    $latest_obs{operator_list}{$operator}{url} = $organization_url;

    #print "$platform_handle:$obs_type:$uom_type:$m_value\n";
  }

}
$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
	    # http://rt.cpan.org/Ticket/Display.html?id=22688

$dbh->disconnect();

#####################
##print XML from hash

my $station_count = 0;

my $xml_procedure_content = '';
my $xml_result_content = '';

my $number = 'Number'; #added this because of problems with \N interpret
my $latlon = 'LatLon'; #added this because of problems with \L interpret

my $sensor_elev = '1';  #could be missing, negative convention from obskml(multiply by -1)

##

## operators(organizations) #######################################################
foreach my $operator (sort keys %{$r_latest_obs->{operator_list}}) {

my $station_index = 0;

my $operator_name = $latest_obs{operator_list}{$operator}{name};
my $operator_url = $latest_obs{operator_list}{$operator}{url};

## platforms #######################################################
foreach my $platform_handle (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}}) {

#my $m_date = '';

$station_count++;
$station_index++;

my ($organization_id,$platform_id,$package) = split(/\./,$platform_handle);

my $station_id = "urn:x-noaa:def:station:$organization_id:$platform_id";

my $m_lat = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lat};
my $m_lon = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_lon};

my $m_z = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{m_z};
if (($m_z) && ($m_z ne '-99999')) { $m_z = -1*$m_z; }  #using '-99999' internal to db for missing value
else { $m_z = ''; }

my $sensor_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{sensor_id};
$sensor_id = "urn:x-noaa:def:station:$organization_id:$platform_id:$sensor_id";

my $platform_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{url};
$platform_url = &escape_literals($platform_url);
my $platform_desc = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{desc};
$platform_desc = &escape_literals($platform_desc);

$xml_procedure_content .= <<"END_OF_FILE";
              <ioos:CompositeContext gml:id="Station$station_index\Info">
                <gml:valueComponents>
                  <ioos:StationName>$platform_desc</ioos:StationName>
                  <ioos:Organization>$organization_id</ioos:Organization>
                  <ioos:StationId>$station_id</ioos:StationId>
                  <gml:Point gml:id="Station$station_index$latlon">
                    <gml:pos>$m_lat $m_lon</gml:pos>
                  </gml:Point>

                  <ioos:VerticalDatum>MSL</ioos:VerticalDatum>
                  <ioos:VerticalPosition>$m_z</ioos:VerticalPosition>

                  <ioos:Count name="Station$station_index$number\OfSensors">1</ioos:Count>
                  <ioos:ContextArray gml:id="Station$station_index\SensorArray">
                    <gml:valueComponents>
                      <ioos:CompositeContext gml:id="Station$station_index\Sensor1Info">
                        <gml:valueComponents>
                          <ioos:SensorId>$sensor_id</ioos:SensorId>
                          <ioos:SensorModel xsi:nil="true" xsi:nilReason="missing"/>
                          <ioos:Context name="SensorDepth" uom="m" xsi:nil="true" xsi:nilReason="missing"/>
                          <ioos:SamplingRate uom="Hz" xsi:nil="true" xsi:nilReason="missing"/>
                          <ioos:ReportingInterval uom="s" xsi:nil="true" xsi:nilReason="missing"/>
                          <ioos:ProcessingLevel xsi:nil="true" xsi:nilReason="missing"/>
                        </gml:valueComponents>
                      </ioos:CompositeContext>
                    </gml:valueComponents>
                  </ioos:ContextArray>
                </gml:valueComponents>
              </ioos:CompositeContext>
END_OF_FILE

## obs #######################################################
foreach my $m_type_display_order (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}}) {

my $times_count = scalar(keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}});
my $time_index = 0;

$xml_result_content .= <<"END_OF_FILE";
            <ioos:Composite gml:id="Station$station_index\TimeSeriesRecord">
              <gml:valueComponents>
                <ioos:Count name="Station$station_index$number\OfObservationTimes">$times_count</ioos:Count>
                <ioos:Array gml:id="Station$station_index\TimeSeries">
                  <gml:valueComponents>
END_OF_FILE


foreach my $m_date (sort keys %{$r_latest_obs->{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}}) {

#print "$m_type_display_order $m_date\n";

$time_index++;

my $m_type_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_type_id};
my $obs_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{obs_type};
my $uom_type = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{uom_type};
my $m_z = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_z};
my $m_value = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{m_value};
my $qc_level = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{qc_level};
my $sensor_id = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{sensor_id};
my $sensor_url = $latest_obs{operator_list}{$operator}{platform_list}{$platform_handle}{obs_list}{$m_type_display_order}{m_date}{$m_date}{sensor_url};
$sensor_url = &escape_literals($sensor_url);

$xml_result_content .= <<"END_OF_FILE";
                    <ioos:Composite gml:id="Station$station_index\T$time_index\Point">
                      <gml:valueComponents>
                        <ioos:CompositeContext gml:id="Station$station_index\T$time_index\ObservationConditions" processDef="#Station$station_index\Info">
                          <gml:valueComponents>
                            <gml:TimeInstant gml:id="Station$station_index\T$time_index\Time">
                              <gml:timePosition>$m_date\Z</gml:timePosition>
                            </gml:TimeInstant>
                          </gml:valueComponents>
                        </ioos:CompositeContext>
                        <ioos:ValueArray gml:id="Station$station_index\T$time_index\PointObservations" processDef="#Station$station_index\Sensor1Info">
                          <gml:valueComponents>
                            <ioos:Quantity name="$obstype_label" uom="$uom">$m_value</ioos:Quantity>
                          </gml:valueComponents>
                        </ioos:ValueArray>
                      </gml:valueComponents>
                    </ioos:Composite>
END_OF_FILE

} #foreach m_date

$xml_result_content .= <<"END_OF_FILE";
                  </gml:valueComponents>
                </ioos:Array>
              </gml:valueComponents>
            </ioos:Composite>
END_OF_FILE

} #foreach m_type_display_order

} #foreach platform_handle
} #foreach operator













########################################

my $observed_property = "<om:observedProperty xlink:href=\"http://www.csc.noaa.gov/ioos/schema/IOOS-DIF/IOOS/0.6.0/dictionaries/phenomenaDictionary.xml#$obstype_label\"/>";


#open(XML_FILE,">./dif_sos.xml");

my $xml_header = <<"END_OF_FILE";
<?xml version="1.0" encoding="ISO-8859-1"?>
<om:CompositeObservation xmlns:om="http://www.opengis.net/om/1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:swe="http://www.opengis.net/swe/1.0.2" xmlns:ioos="http://www.noaa.gov/ioos/0.6.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" gml:id="$obstype_label\PointCollectionTimeSeriesObservation" xsi:schemaLocation="http://www.opengis.net/om/1.0 ../schemas/ioosObservationSpecializations.xsd">
  <gml:metaDataProperty xlink:href="http://www.csc.noaa.gov/ioos/schema/IOOS-DIF/IOOS/0.6.0/metadata/IOOSMetaData.xml"/>
  <gml:description>$obstype_label observation(s)</gml:description>
  <gml:name>$obstype_label observation(s)</gml:name>
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:epsg::4326">
      <gml:lowerCorner>$response_min_lat $response_min_lon</gml:lowerCorner>
      <gml:upperCorner>$response_max_lat $response_max_lon</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>
  <om:samplingTime>
    <gml:TimePeriod gml:id="ST">
      <gml:beginPosition>$response_start_datetime\Z</gml:beginPosition>
      <gml:endPosition>$response_end_datetime\Z</gml:endPosition>
    </gml:TimePeriod>
  </om:samplingTime>
END_OF_FILE

#####################################
my $xml_procedure = <<"END_OF_FILE";

  <om:procedure>
    <om:Process>
      <ioos:CompositeContext gml:id="StationsSensors" recDef="http://www.csc.noaa.gov/ioos/schema/IOOS-DIF/IOOS/0.6.0/recordDefinitions/StationSensorRecordDefinition.xml">
        <gml:valueComponents>
          <ioos:Count name="NumberOfStations">$station_count</ioos:Count>
          <ioos:ContextArray gml:id="StationArray">
            <gml:valueComponents>

	      $xml_procedure_content

            </gml:valueComponents>
          </ioos:ContextArray>
        </gml:valueComponents>
      </ioos:CompositeContext>
    </om:Process>
  </om:procedure>

  $observed_property
  <om:featureOfInterest xlink:href="urn:cgi:feature:CGI:EarthOcean"/>

END_OF_FILE

#####################################
my $xml_result = <<"END_OF_FILE";

  <om:result>
    <ioos:Composite gml:id="$obstype_label\PointObservations" recDef="http://www.csc.noaa.gov/ioos/schema/IOOS-DIF/IOOS/0.6.0/dataRecordDefinitions/$obstype_label\DataRecordDefinition.xml">
      <gml:valueComponents>

        <ioos:Count name="NumberOfObservationPoints">$station_count</ioos:Count>
        <ioos:Array gml:id="$obstype_label\PointCollectionTimeSeries">
          <gml:valueComponents>

		    $xml_result_content

          </gml:valueComponents>
        </ioos:Array>
      </gml:valueComponents>
    </ioos:Composite>
  </om:result>
</om:CompositeObservation>
END_OF_FILE

#print XML_FILE $xml_header.$xml_procedure.$xml_result;
#close(XML_FILE);

# print appropriate HTTP header and XML content
print $cgi->header(-type=>'text/xml'),qq($xml_header.$xml_procedure.$xml_result);

exit 0;


##############################################################

#-------------------------------------------------------------------
#                   parse_config_file
#--------------------------------------------------------------------

sub parse_config_file {
# get configuration info
open(CFG,"<$config_location") or die "Failed to open config file, $!\n";
while (<CFG>) { $config .= $_; }
close CFG;

# parse config parameters from config file contents
if ($config =~ /<dbname>\s*(.+)\s*<\/dbname>/gs) { $dbname = $1; }
else { die "Failed to parse dbname from config.\n"; }

if ($config =~ /<logDir>\s*(.+)\s*<\/logDir>/gs) { $logDir = $1; }
else { die "Failed to parse logDir from config.\n"; }

=comment
if ($config =~ /<srsName>\s*(.+)\s*<\/srsName>/gs) { $srsName = $1; }
else { die "Failed to parse srsName from config.\n"; }

if ($config =~ /<sensorCodeSpace>\s*(.+)\s*<\/sensorCodeSpace>/gs) { $sensorCodeSpace = $1; }
else { die "Failed to parse sensorCodeSpace from config.\n"; }

if ($config =~ /<obsNameCodeSpace>\s*(.+)\s*<\/obsNameCodeSpace>/gs) { $obsNameCodeSpace = $1; }
else { die "Failed to parse obsNameCodeSpace from config.\n"; }

if ($config =~ /<verticalDatumCodeSpace>\s*(.+)\s*<\/verticalDatumCodeSpace>/gs) { $verticalDatumCodeSpace = $1; }
else { die "Failed to parse verticalDatumCodeSpace from config.\n"; }

if ($config =~ /<verticalPositionUom>\s*(.+)\s*<\/verticalPositionUom>/gs) { $verticalPositionUom = $1; }
else { die "Failed to parse verticalPositionUom from config.\n"; }
=cut

if ($config =~ /<TYPENAMES>\s*(.+)\s*<\/TYPENAMES>/gs) {
    my $items = $1;
    while ($items =~ /<item>(.+?)<\/item>/gs) { $valid_type_names{$1} = 1; }
    }
else { die "Failed to parse valid property names from config.\n"; }
}

#--------------------------------------------------------------------
#                   parse_check_inputs
#--------------------------------------------------------------------
sub parse_check_inputs {
# Bounding Box
my $bbox = $cgi->param('BBOX') || $cgi->param('bbox');
#print ":$bbox:\n";
if ($bbox) {
($query_min_lon, $query_min_lat, $query_max_lon, $query_max_lat) = split /,\s*/, $bbox;
if ($query_max_lon =~ /^-*\d+(\.\d+)*$/) {
    if (($query_max_lon < -180) || ($query_max_lon > 180)) {
    gripe("BBOX", "Bad Max Longitude: $query_max_lon."); }
    }
else { gripe("BBOX", "Failed to parse max longitude from query string."); }
if ($query_min_lon =~ /^-*\d+(\.\d+)*$/) {
    if (($query_min_lon < -180) || ($query_min_lon > 180)) {
    gripe("BBOX", "Bad Min Longitude: $query_min_lon."); }
    }
else { gripe("BBOX", "Failed to parse min longitude from query string."); }
if($query_max_lat =~ /^-*\d+(\.\d+)*$/){
    if (($query_max_lat < -90) || ($query_max_lat > 90)) {
    gripe("BBOX", "Bad Max Latitude: $query_max_lat.");}
    }
else { gripe("BBOX", "Failed to parse max latitude from query string."); }
if ($query_min_lat =~ /^-*\d+(\.\d+)*$/){
    if (($query_min_lat < -90) || ($query_min_lat > 90)) {
    gripe("BBOX", "Bad Min Latitude: $query_min_lat."); }
    }
else { gripe("BBOX", "Failed to parse max latitude from query string."); }
}

# Observed Property Name
$obstype = lc($cgi->param('OBSERVEDPROPERTY') || $cgi->param('observedproperty'));
unless ($valid_type_names{$obstype} ) {
    my $names = join ', ', keys(%valid_type_names);
    gripe("OBSERVEDPROPERTY", "Invalid OBSERVEDPROPERTY($obstype).  Must one of: $names.");
    }

# Time start and stop
my $time_range = $cgi->param('EVENTTIME') || $cgi->param('eventtime');
($query_start_datetime, $query_end_datetime) = split /\//, $time_range; 
if ($time_range) {
unless ($query_start_datetime =~ /^\d{4}-\d{2}-\d{2}T(\d{2}:\d{2}(:\d{2})*)$/) {
        gripe("EVENTTIME", "Invalid start time($query_start_datetime).  Should be like YYYY-MM-DDTHH:MM:SS");
        }
unless ($query_end_datetime   =~ /^\d{4}-\d{2}-\d{2}T(\d{2}:\d{2}(:\d{2})*)$/) {
        gripe("EVENTTIME", "Invalid end time($query_end_datetime).  Should be like YYYY-MM-DDTHH:MM:SS");
        }
}

# Observed Property Name
$offering = lc($cgi->param('OFFERING') || $cgi->param('offering'));
unless (length($offering) < 40) { gripe("OFFERING", "OFFERING must be less than 40 character length."); }

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

#--------------------------------------------------------------------
#                   gripe
#--------------------------------------------------------------------
sub gripe {
my ($locator, $ExceptionText) = @_;
print LOG "$run_date_time: --ERROR-- $locator, $ExceptionText\n";
print $cgi->header(-type=>'text/xml'),
#print $cgi->header(-type=>'text/html'),
        qq(<?xml version="1.0" encoding="UTF-8"?>
<ExceptionReport xmlns="http://www.opengis.net/ows"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.opengis.net/ows owsExceptionReport.xsd"
        version="1.0.0" language="en">
        <Exception
                exceptionCode="InvalidParameterValue"
                locator="$locator"
                ExceptionText="$ExceptionText" />
</ExceptionReport>);
exit;
}

#--------------------------------------------------------------------
#                   getDateTime
#--------------------------------------------------------------------
sub getDateTime {
my @dt = localtime;
my $yr = $dt[5]+= 1900;
my $mo = $dt[4] += 1;
my $da = $dt[3];
my $hr = $dt[2];
my $mn = $dt[1];
my $sc = $dt[0];
if (length($mo) == 1) { $mo = '0'.$mo; }
if (length($da) == 1) { $da = '0'.$da; }
if (length($hr) == 1) { $hr = '0'.$hr; }
if (length($mn) == 1) { $mn = '0'.$mn; }
if (length($sc) == 1) { $sc = '0'.$sc; }

return("$yr$mo$da $hr:$mn:$sc");
}

#--------------------------------------------------------------------
#                   set_obstype_related
#--------------------------------------------------------------------
sub set_obstype_related {

#this function relates the requested observed property to a specific database m_type_id and uom
if ($obstype eq 'windspeed') { $obstype_label = 'WindSpeed'; $query_m_type_id = 1; $uom = 'm_s-1'; }
if ($obstype eq 'windgust') { $obstype_label = 'WindGust'; $query_m_type_id = 2; $uom = 'm_s-1'; }
if ($obstype eq 'windfromdirection') { $obstype_label = 'WindFromDirection'; $query_m_type_id = 3; $uom = 'degrees_true'; }
if ($obstype eq 'airpressure') { $obstype_label = 'AirPressure'; $query_m_type_id = 4; $uom = 'mb'; }
if ($obstype eq 'airtemperature') { $obstype_label = 'AirTemperature'; $query_m_type_id = 5; $uom = 'celsius'; }
if ($obstype eq 'watertemperature') { $obstype_label = 'WaterTemperature'; $query_m_type_id = 6; $uom = 'C'; }
if ($obstype eq 'waterconductivity') { $obstype_label = 'WaterConductivity'; $query_m_type_id = 7; $uom = 'mS_cm-1'; }
if ($obstype eq 'waterpressure') { $obstype_label = 'WaterPressure'; $query_m_type_id = 8; $uom = 'dbar'; }
if ($obstype eq 'chlconcentration') { $obstype_label = 'ChlorophyllConcentration'; $query_m_type_id = 10; $uom = 'ug_L-1'; }
if ($obstype eq 'currentspeed') { $obstype_label = 'CurrentSpeed'; $query_m_type_id = 11; $uom = 'cm_s-1'; }
if ($obstype eq 'currenttodirection') { $obstype_label = 'CurrentToDirection'; $query_m_type_id = 12; $uom = 'degrees_true'; }
if ($obstype eq 'significantwaveheight') { $obstype_label = 'SignificantWaveHeight'; $query_m_type_id = 13; $uom = 'm'; }
if ($obstype eq 'dominantwaveperiod') { $obstype_label = 'DominantWavePeriod'; $query_m_type_id = 14; $uom = 's'; }
if ($obstype eq 'significantwavetodirection') { $obstype_label = 'SignificantToDirection'; $query_m_type_id = 15; $uom = 'degrees_true'; }
if ($obstype eq 'relativehumidity') { $obstype_label = 'RelativeHumidity'; $query_m_type_id = 22; $uom = 'percent'; }
if ($obstype eq 'waterlevel') { $obstype_label = 'WaterLevel'; $query_m_type_id = 23; $uom = 'm'; }
if ($obstype eq 'salinity') { $obstype_label = 'Salinity'; $query_m_type_id = 28; $uom = 'psu'; }
if ($obstype eq 'precipitation') { $obstype_label = 'Precipitation'; $query_m_type_id = 29; $uom = 'millimeter'; }
if ($obstype eq 'solarradiation') { $obstype_label = 'SolarRadiation'; $query_m_type_id = 30; $uom = 'millimoles_per_m^2'; }
if ($obstype eq 'eastwardcurrent') { $obstype_label = 'EastwardCurrent'; $query_m_type_id = 31; $uom = 'cm_s-1'; }
if ($obstype eq 'northwardcurrent') { $obstype_label = 'NorthwardCurrent'; $query_m_type_id = 32; $uom = 'cm_s-1'; }
if ($obstype eq 'oxygenconcentrationabsolute') { $obstype_label = 'OxygenConcentrationAbsolute'; $query_m_type_id = 34; $uom = 'mg_L-1'; }
if ($obstype eq 'oxygenconcentrationpercent') { $obstype_label = 'OxygenConcentrationPercent'; $query_m_type_id = 35; $uom = 'percent'; }
if ($obstype eq 'turbidity') { $obstype_label = 'Turbidity'; $query_m_type_id = 36; $uom = 'ntu'; }
if ($obstype eq 'ph') { $obstype_label = 'Ph'; $query_m_type_id = 38; $uom = 'units'; }
if ($obstype eq 'visibility') { $obstype_label = 'Visibility'; $query_m_type_id = 39; $uom = 'nautical_miles'; }
if ($obstype eq 'drifterspeed') { $obstype_label = 'DrifterSpeed'; $query_m_type_id = 41; $uom = 'm_s-1'; }
if ($obstype eq 'drifterdirection') { $obstype_label = 'DrifterDirection'; $query_m_type_id = 44; $uom = 'degrees_true'; }
if ($obstype eq 'gageheight') { $obstype_label = 'GageHeight'; $query_m_type_id = 43; $uom = 'm'; }

return;
}
