#!/usr/bin/perl
use strict; 
# Some required libraries.
use Time::Local;
use File::Basename;
use XML::LibXML;
use CGI ":cgi";

#print "Content-type: text/html\n\n";
#print "hello";
#exit 0;

# if using the SOS Config file DBI is optional
#### LOCAL EDIT
use DBI;
#### END LOCAL EDIT
################################################################################
# SOS OVERVIEW
#  This Perl script implements the OGC's Sensor Observation Service Version 1.0
#    The three mandatory core operations/requests are supported:
#       - GetCapabilities
#       - DescribeSensor
#       - GetObservation
#
#  There are two wasy to use this script controlled by the $use_config variable below.
#    1. It allows sensor and organization metadata to be retrieved either from a simple XML configuration file
#       the sos_config.xml file  which must be edited with your local Metadata information.
#       Observation data is retrieved from ASCII text files named in the configuration file.
#    2. OR it allows sensor and organization metadata and observations to be retrieved from a local database via the DBI module
#       with two separate SQL queries. One for Metadata and another for Observation data.
#    Note: it is possible to use the sos_config.xml file to set Metadata and still use the Database to retrieve observation
#    data.  This is done by setting the <SOSDataFile> element in the config file to DataBase.
#
#  Each core operation has a corresponding XML template which is parsed via the XML::LibXML Perl library and the
#  SOS servers metadata and observations are inserted into the template and returned as XML.
#    SOS Templates:
#       - sosGetCapabilities.xml
#       - sosDescribeSensor.xml
#       - sosGetObservation.xml
#  The assumption is that the templates are in the same directory as the script but can reside anywhere by setting the $base_dir global
#  In general the templates contain all the necessary required elements without local values for SOS the response, but some of the elements or
#  attributes are hard coded and are not modified by the script. 
#  These can be edited in the templates. For example, in the sosGetCapabilites.xml, the timeInterval attribute which is set to 1 hour.
#  Some of the elements exist as models which are cloned by this script and updated and repeatedly output as necessary. For example the list
#  of observedProperties.
#  Since XML->appendText is often used for element values, elements should not have holding values.  Attribute values can and do have holding
#  values since they get overwritten.
#  
#  SOS is a Web Service and a Web Server such as Apache is required.  The script runs in your Web Servers
#  /cgi-bin directory or sub directtory and must be made executable:  chmod 755 and owned by the Web user.
################################################################################
################################################################################
# This is a Units of Measure lookup table based on the values and units used by GoMOOS
# It must be edited to match the observedProperty names and units utilized by your service database.
# For Database users all the observedProperties you wish to serve must be listed here.
# It is not used at all by the XML configuration file which contains a <uom> member for each Platform/observedProperty
################################################################################
#### LOCAL EDIT
# To utilize your database set $use_config to 0. To utilize the sos_config.xml file set to 1.
# Note: You can keep set $use_config = 1  get your metadata from your local config file but still get observation data from you database by setting the <SOSDataFile> element to 'DataBase' instead of a local ASCII file name
# E.g. <SOSDataFile>DataBase</SOSDataFile>
our $use_config = 0;

=comment
our %uom_lookup = (
	'air_temperature'								=> 'celsius',
	'chlorophyll'									=> 'mg_m-3',
	'dissolved_oxygen'								=> 'ml_l-1',
	'percent_oxygen_saturation'						=> 'percent',
	'oxygen_saturation'								=> 'ml_l-1',,
	'Ed_PAR'										=> 'W_m-2_sr-1',
	'sea_level_pressure'							=> 'mbars',
	'sea_water_density'								=> 'kg_m-3',
	'sea_water_salinity'							=> 'psu',
 	'sea_water_electrical_conductivity'				=> 'siemens_m-1',
	'sea_water_speed'								=> 'cm_s-1',
	'direction_of_sea_water_velocity'				=> 'degree',
	'sea_water_temperature'							=> 'celsius',
	'wind_speed'									=> 'mps',
	'wind_gust'										=> 'mps',
	'wind_from_direction'							=> 'degrees',
	'visibility_in_air'								=> 'm',
	'significant_height_of_wind_and_swell_waves'	=> 'm',
	'dominant_wave_period'							=> 's',
	'turbidity'										=> 'ntu',
);
=cut

my $dbname = '/var/www/cgi-bin/microwfs/microwfs.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
    { RaiseError => 1, AutoCommit => 1 });

unless ($dbh){ die("Database Error", DBI->errstr); }

my $sth;

our %uom_lookup = ();

my $sql = qq{ select t0.row_id,t2.standard_name,t3.standard_name from m_type t0,m_scalar_type t1,obs_type t2,uom_type t3 where t0.m_scalar_type_id = t1.row_id and t0.num_types = 1 and t1.obs_type_id = t2.row_id and t1.uom_type_id = t3.row_id };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();

while (my ($row_id,$obs_type,$uom) = $sth->fetchrow_array) {
        #print "$row_id $obs_type $uom\n";
        $uom_lookup{$obs_type} = $uom;
};


#### END LOCAL EDIT

# This is the location of the XML Templates
# The base_dir can be hard-coded.  We assume the XML Templates are located in the same directory as this script is.
our $base_dir = dirname($0);

our $parser = XML::LibXML->new();

########################################
# EXCEPTION HANDLING
########################################

our $etemplate = <<EOT;
<?xml version="1.0" ?>
<ExceptionReport
    xmlns="http://www.opengis.net/ows"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.opengis.net/ows owsExceptionReport.xsd"
	version="1.0.0" language="en">
<Exception locator="service"></Exception>
</ExceptionReport>
EOT

########################################
sub exception_error
{
	my ($code, $msg) = @_;

	my  @exception_codes = (
	'OperationNotSupported',
	'MissingParameterValue',
	'InvalidParameterValue',
	'VersionNegotiationFailed',
	'InvalidUpdateSequence',
	'NoApplicableCode'
	);

	my $exception = $parser->parse_string($etemplate);
	my $xc = XML::LibXML::XPathContext->new($exception);
	$xc->registerNs('ows' => 'http://www.opengis.net/ows');
	my $node = ($xc->findnodes("/ows:ExceptionReport/ows:Exception"))[0];
	my $ecode = $exception_codes[$code];
	warn "Exception: $ecode $msg";
	$node->setAttribute('exceptionCode', $exception_codes[$code]);
	$node->appendTextChild('ExceptionText', $msg);
	print header(
			-type => 'text/xml',
	);
	print $exception->serialize;

$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
 	  # http://rt.cpan.org/Ticket/Display.html?id=22688	
$dbh->disconnect();

	exit;
}

########################################
# METADATA
#  All the core operations/requests require some metadata about the sensor and the datatypes the sensor measures.
#  So we set the metadata no matter what the SOS request is.
########################################
# Some Global MetaData Values
# These globals are used by various responses.
# They must be set here if you are using a database for using metadata.
# If you are using the sos_config.xml configuration file they will be overrwritten by the
# values found in the sos_config.xml file.
########################################
#### LOCAL EDIT
# Full name of your organization
our $org = 'Southeast Atlantic Coastal Ocean Observing System';
our $short_org = 'SECOORA';
our $org_acronym = 'SECOORA';
our @key_words = ('OCEANOGRAPHY', 'Ocean Observations', 'SECOORA', 'Southeast Atlantic');
our $org_url = 'http://secoora.org/';
our $title = "SECOORA SOS";
our $ra_name = 'SECOORA';
our $contact = 'Jeremy Cothran';
our $email = 'jeremy.cothran@gmail.com';

# This must point to the full URL path to this CGI script.
our $sos_url = 'http://nautilus.baruch.sc.edu/cgi-bin/sos/oostethys_sos.cgi';

#####################
# platform_urn.  To ensure unique platform identifiers acroos the internet your local platform or sensor id 
# should be turned into a urn.   Typically this should be: urn:your_org.your_domaine:source.moooring#
# The local platform name will be appended after the #
#####################
our $platform_uri = 'urn:secoora.org:source.mooring#';

#### END LOCAL EDIT

# All observed properties (data types are preceeded by this urn to ensure uniqueness)
our $observed_property_url = 'http://mmisw.org/cf#';
# All observed properties units of measure (uom) are preceeded by this urn to ensure uniqueness
our $uom_urn = 'urn:mmisw.org:units#';

# Metadata about each sensor and arrays of observedProperties and Units of Measure reported by that sensor.
my %sensor_list = ();

getMetaData($use_config, \%sensor_list);

#######################################
# Determine the REQUEST type and make it upper case.
#######################################
my %in_params;
getInputParams(\%in_params);

my $request = '';
$request = $in_params{REQUEST} if ( $in_params{REQUEST});

# Default request is GetCapabilities
$request = 'GetCapabilities' if ! $request;

exception_error(0, "Uknown request parameter: $request") if ( $request ne 'GetCapabilities' and $request ne 'GetObservation' and $request ne 'DescribeSensor');

####################################################
# Call proper sub routine based on in_params
####################################################

my $sos;
my ($SensorID, $observedProperty, $time, $urn) = ('','','', '');
#################################################################
# GetCapabilities
#################################################################
if( $request eq 'GetCapabilities' ){
	# GetCapabilities has no parameters we care about
	# in fact we  should check the SERVICE=SOS and the VERSION=1.0.0 parameters
	$sos = doGetCapabilities(\%sensor_list);
}
#################################################################
# DescribeSensor
#################################################################
#  Required Input Parameters
#     procedure:   local sensor name optionally preceeded by the platform urn:
#        Examples:  procedure=urn:gomoos.org:source.mooring#A01
#                   procedure=urn:gomoos.org:source.mooring:A01
#################################################################
if( $request eq 'DescribeSensor' ){
	$SensorID = $in_params{PROCEDURE} if $in_params{PROCEDURE};
	exception_error(1, "procedure parameter required") if (!$SensorID);

	# deal with 2 possible urns '#' vs ':' (both contain :)
	# $tmp[$#tmp] (the list element is the value we want
	my @tmp = ();
	if($SensorID =~ /#/){
		@tmp = split(/#/, $SensorID);
	}else{
		@tmp = split(/:/, $SensorID);
	}
	$SensorID =  $tmp[$#tmp];
	exception_error(1, "procedure parameter required") if (!$SensorID);
	$sos = doDescribeSensor($SensorID, \%sensor_list);
}
#################################################################
# GetObservation
#  Required Input Parameters
#     offering:           local sensor name optionally preceeded by the platform urn:
#     observedProperty:   local observedProperty name optionally preceeded by the MMI uri:
#  Optional Input Parameters
#     observedProperty:   multiple properties as a comma separated list.
#     time:               ISO8601 formatted time or time range (time1/time2)
#     bbox:               minimum_longitude,minimum_latitude,maximum_longitude,maximum_latitude
#
#     The default is to currently return the most recent or latest observedProperty for the offering.
#################################################################
if( $request eq 'GetObservation' ){
	$SensorID = $in_params{OFFERING} if ($in_params{OFFERING});
	exception_error(1, "offering parameter required") if (!$SensorID);

	# deal with 2 possible urns '#' vs ':' (both contain :)
	# $tmp[$#tmp] (the list element is the value we want
	my @tmp = ();
	if($SensorID =~ /#/){
		@tmp = split(/#/, $SensorID);
	}else{
		@tmp = split(/:/, $SensorID);
	}
	$SensorID =  $tmp[$#tmp];

	$observedProperty = $in_params{OBSERVEDPROPERTY} if $in_params{OBSERVEDPROPERTY};
	exception_error(1, "observedProperty parameter required") if (!$observedProperty);

	$sos = doGetObservation($SensorID, \%in_params, \%sensor_list);
}

########################################
# Now build the SOS from XML templates
########################################

my $sos_xml = $sos->serialize;

print header(
		-type => 'text/xml',
);

print $sos_xml;

$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
 	  # http://rt.cpan.org/Ticket/Display.html?id=22688	
$dbh->disconnect();

exit;

#################################################################
#  SUBROUTINES
#################################################################

#################################################################
#  GetCapabilities
#################################################################
sub doGetCapabilities
{
	my ($sensor_list) = @_;

	my $sos = $parser->parse_file("$base_dir/sosGetCapabilities.xml");
	exception_error(5, "Could not open SOS template: sosGetCapabilities.xml") if ! $sos;
	
	my $tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceIdentification/ows:Title"))[0];
	$tmpl_node->appendText($title) if ($tmpl_node);

	$tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceIdentification/ows:Keywords"))[0];
	if(@key_words and $tmpl_node) {
		foreach my $child ($tmpl_node->childNodes){
			$tmpl_node->removeChild($child);
		}
		foreach my $word (@key_words){
			my $kw = $sos->createElement('ows:Keyword');
			$kw->appendText($word);
			$tmpl_node->appendChild($kw);
		}
	}

	
	$tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceProvider/ows:ProviderName"))[0];
	$tmpl_node->appendText($org_acronym);
	
	$tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceProvider/ows:ProviderSite"))[0];
	$tmpl_node->setAttribute('xlink:href', $org_url);
	
	# Another way to handle attributes
	#my @attrs = $tmpl_node->attributes();
	#$attrs[0]->setValue($org_url);
	
	$tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:IndividualName"))[0];
	$tmpl_node->appendText($contact);
	
	$tmpl_node = ($sos->findnodes("//sos:Capabilities/ows:ServiceProvider/ows:ServiceContact/ows:ContactInfo/ows:Address/ows:ElectronicMailAddress"))[0];
	$tmpl_node->appendText("$email");
	
	#############################
	# Three Operations: GetCapabilities, GetObservation and Describe Sensor
	#############################
	foreach my $node ( $sos->findnodes("//sos:Capabilities/ows:OperationsMetadata/ows:Operation") ){
		my $op = $node->getAttribute('name');
		# We assume all use the same sos_url with the Operation appended. Perhaps this should be a ? vs a /
		# Java and Perl may handle this differently 
		foreach my $http ($node->findnodes("ows:DCP/ows:HTTP/*")->get_nodelist){
			$http->setAttribute('xlink:href', "$sos_url");
		};
	
		if($op eq 'GetObservation' ){
			foreach my $param ($node->findnodes("ows:Parameter")){
				# offering is the name of the GetObservation sensor Parameter.
				if($param->getAttribute('name') eq 'offering'){
					# Here we are creating a piece of xml outside the template.<ows:Value></ows:Value>.
					# so get rid of any existing children.
					foreach my $child ($param->childNodes){
						$param->removeChild($child);
					}
					# add a Value for each sensor, but only 1
					my %done;
					my $allowedVals = $sos->createElement('ows:AllowedValues');
					foreach my $sensor (sort keys %{$sensor_list} ){
						next if exists($done{$sensor});
						$allowedVals->appendTextChild('ows:Value', $sensor);
						$done{$sensor} = 1;
					}
					$param->appendChild($allowedVals);
				}

				if($param->getAttribute('name') eq 'observedProperty'){
					foreach my $child ($param->childNodes){
						$param->removeChild($child);
					}
					# create a list of all observed properties across all sensors.
					my %obsprops = ();
					foreach my $sensor (sort keys %{$sensor_list} ){
						foreach my $prop (sort keys %{ $sensor_list->{$sensor}->{obsproplist} } ) {
							$obsprops{$prop} = 1;
						}
					}
					my $allowedVals = $sos->createElement('ows:AllowedValues');
					foreach my $prop (sort keys %obsprops ){
						$allowedVals->appendTextChild('ows:Value', $prop);
					}
					$param->appendChild($allowedVals);
				}
			}
		}
		if($op eq 'DescribeSensor'){
			foreach my $param ($node->findnodes("ows:Parameter")){
				if($param->getAttribute('name') eq 'procedure'){
					foreach my $child ($param->childNodes){
						$param->removeChild($child);
					}
					# add a Value for each sensor, but only 1
					my %done;
					my $allowedVals = $sos->createElement('ows:AllowedValues');
					foreach my $sensor (sort keys %{$sensor_list} ){
						next if exists( $done{$sensor});
						$allowedVals->appendTextChild('ows:Value', $sensor_list->{$sensor}->{urn});

						$done{$sensor} = 1;
					}
					$param->appendChild($allowedVals);
				}
			}
		}
	}
	
	################################################################
	# Observation Offering List, one for each Sensor and Parameter.
	################################################################
	my $offering_list = ($sos->findnodes("//sos:Capabilities/sos:Contents/sos:ObservationOfferingList"))[0];
	
	# Get the first entry from the OfferingList. This is used as the template to build the
	# Offering for each sensor and is then deleted below
	my $offering = ( $offering_list->findnodes("sos:ObservationOffering") )[0];
	# TODO: what depth to use for a sensor?
	my $depth = 0;	
	my %done;
	foreach my $sensor (sort keys %{$sensor_list} ){
		# In sensor_list there is one entry for each sensorID and parameter but we only want
		# one per sensor
		next if exists($done{$sensor});
		my $offer = $offering->cloneNode(1);
		$offer->setAttribute('gml:id', $sensor);
	
		my $node = ($offer->findnodes("gml:description"))[0];
		$node->appendText($sensor_list->{$sensor}->{comments});

		$node = ($offer->findnodes("gml:name"))[0];
		$node->appendText($sensor);
	
		# save this as ref  placeholder for property insertion.
		my $procedure = ($offer->findnodes("sos:procedure"))[0];
		$procedure->setAttribute('xlink:href', $sensor_list->{$sensor}->{urn});
	
		$node = ($offer->findnodes("gml:boundedBy/gml:Envelope/gml:lowerCorner"))[0];
		$node->appendText( $sensor_list->{$sensor}->{lat} . ' ' . $sensor_list->{$sensor}->{lon} . ' ' . $depth );
		$node = ($offer->findnodes("gml:boundedBy/gml:Envelope/gml:upperCorner"))[0];
		if($sensor eq 'ALL_PLATFORMS'){
			$node->appendText('46.0 -63.0' . ' ' . $depth );
		}else{
			$node->appendText($sensor_list->{$sensor}->{lat} . ' ' . $sensor_list->{$sensor}->{lon} . ' ' . $depth );
		}

		$node = ($offer->findnodes("sos:eventTime/gml:TimePeriod"))[0];
		$node->setAttribute('gml:id', $sensor . '_valid_times');

		$node = ($offer->findnodes("sos:eventTime/gml:TimePeriod/gml:beginPosition"))[0];
		$node->appendText($sensor_list->{$sensor}->{start_time} ) if($sensor_list->{$sensor}->{start_time} ne "");
		$node->setAttribute('indeterminatePosition', 'unknown') if($sensor_list->{$sensor}->{start_time} eq "");

		$node = ($offer->findnodes("sos:eventTime/gml:TimePeriod/gml:endPosition"))[0];
		# empty Time endPostion implies data available up to now.
		$node->appendText($sensor_list->{$sensor}->{end_time} ) if($sensor_list->{$sensor}->{end_time} ne ""); 
		$node->setAttribute('indeterminatePosition', 'now') if($sensor_list->{$sensor}->{end_time} eq "");
	
		# Get rid of existing properites
		foreach my $node ($offer->findnodes("sos:observedProperty")){
			$offer->removeChild($node);
		}
	
		foreach my $param (sort keys %{ $sensor_list->{$sensor}->{obsproplist} } ){
			my $property = $sos->createElement('sos:observedProperty');
			my $urn = $observed_property_url . $param;
			$property->setAttribute('xlink:href', $urn);
			$offer->insertAfter($property, $procedure);
		} # end for each $#params
	
		$offering_list->appendChild($offer);
		$done{$sensor} = 1;
	
	} # end foreach sensor_list
	
	# Delete the existing child from the Offering List. we're just using it as template for new entries
	$offering_list->removeChild($offering);
	
	return $sos;
}

#################################################################
#  doDescribeSensor()
#################################################################
sub doDescribeSensor
{
	my ($sensorID, $sensor_list) = @_;


	# TODO what depth to use for a sensor?
	my ($lat, $lon, $depth, $urn, $long_name, $comments, $provider_name) = ('','',0,'', '', '', '');
	my ($stime, $etime) = ('','');
	# Get info for this sensor and param.
	if( not exists($sensor_list->{$sensorID})){
		exception_error(2, "Unknown DescribeSensor SensorId: $sensorID");
	}
	$comments = $sensor_list->{$sensorID}->{comments};
	$lat = $sensor_list->{$sensorID}->{lat};
	$lon = $sensor_list->{$sensorID}->{lon};
	$urn = $sensor_list->{$sensorID}->{urn};
	$long_name = $sensor_list->{$sensorID}->{long_name};
	$stime = $sensor_list->{$sensorID}->{start_time};
	$etime = $sensor_list->{$sensorID}->{end_time};
	$provider_name = $sensor_list->{$sensorID}->{provider_name};

	my $sos = $parser->parse_file("$base_dir/sosDescribeSensor.xml");
	exception_error(5, "Could not open SOS template: sosDescribeSystem.xml") if ! $sos;
	# Because the sosDescribeSensor.xml template has a default namespace for SML with no sml: prefixes
	# we need to use XPathContext to register the namespace. This allows XPath queries
	# using sml: The XPath Spec makes no provisions for default namespaces for some reason.
	my $xc = XML::LibXML::XPathContext->new($sos);
	$xc->registerNs('sml' => 'http://www.opengis.net/sensorML/1.0.1'); 

	my $node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System"))[0];
	$node->setAttribute('gml:id', $sensorID);
	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/gml:description"))[0];
	$node->appendText($comments);

	# Keywords
	if(@key_words){
		#$node = ($xc->findnodes("//sos:Capabilities/ows:ServiceIdentification/ows:Keywords"))[0];
		$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:keywords/sml:KeywordList"))[0];
		foreach my $child ($node->childNodes){
			$node->removeChild($child);
		}
		foreach my $word (@key_words){
			my $kw = $sos->createElement('keyword');
			$kw->appendText($word);
			$node->appendChild($kw);
		}
	}


	#############################
	# Six Identifications.
	#############################
	foreach my $node ( $xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:identification/sml:IdentifierList/sml:identifier/sml:Term") ){
		my $name = $node->getAttribute('definition');
		# Note: needed the sml: prefix was trying "value" which did not work
		my $value = ($xc->findnodes("sml:value", $node))[0];
		$value->appendText($long_name) if ($name =~ /identifier:OGC:longName$/);
		$value->appendText($sensorID) if ($name =~ /identifier:OGC:shortName$/);
		$value->appendText($urn) if ($name eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#ID');

		$value->appendText($short_org) if ($name =~ /qualifier#operatorShortName$/);
		$value->appendText($short_org) if ($name =~ /qualifier#dataProviderShortName$/);
		$value->appendText($ra_name) if ($name =~ /qualifier#regionalAssociationShortName$/);
	}

	#############################
	# validTime
	#############################
	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:validTime/gml:TimePeriod/gml:beginPosition"))[0];
	$node->appendText($stime );
	$node->setAttribute('indeterminatePosition', 'unknown') if (not $stime);
	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:validTime/gml:TimePeriod/gml:endPosition"))[0];
	$node->appendText( $etime );
	$node->setAttribute('indeterminatePosition', 'now') if (not $etime);

	#############################
	# Contact Info
	#############################
	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:individualName"))[0];
	$node->appendText($contact);

	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:organizationName"))[0];
	$node->appendText($org);
	
	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:contactInfo/sml:address/sml:electronicMailAddress"))[0];
	$node->appendText("$email");

	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:contact/sml:ResponsibleParty/sml:contactInfo/sml:onlineResource"))[0];
	$node->setAttribute('xlink:href', $org_url );


	#############################
	# classification
	#############################
	foreach $node ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:classification/sml:ClassifierList/sml:classifier")){
		my $name = $node->getAttribute('name');
		if($name eq 'Platform'){
			my $node2 = ($xc->findnodes("sml:Term/sml:value", $node))[0];
			$node2->appendText($sensorID);
		}
	}

	#############################
	# location
	#############################

	$node = ($xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:location/gml:Point/gml:coordinates"))[0];
	$node->appendText("$lat $lon $depth");

	#############################
	#  Output and DataRecord
	#############################
	my $output = ( $xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:outputs/sml:OutputList/sml:output/swe:DataArray/swe:elementType") )[0];
	my @params = (sort keys %{ $sensor_list->{$sensorID}->{obsproplist} } );
	setDataRecord($xc, $output, $sensorID, $sensor_list, \@params);

	my $element_count = checkDataRecord($xc);

	$node = ( $xc->findnodes("//sml:SensorML/sml:member/sml:System/sml:outputs/sml:OutputList/sml:output/swe:DataArray/swe:elementCount/swe:Count/swe:value") )[0];
	$node->appendText( $element_count );


	return $sos;
}

#################################################################
sub doGetObservation
{
	my ($sensorID, $in_params, $sensor_list) = @_;

	my $in_time = $in_params->{TIME};
	# $OBSERVEDPROPERTY can be a comma separated list.
	my @params = split(',', $in_params->{OBSERVEDPROPERTY});
	# get rid of the uri portion
	for my $i (0..$#params){
		my @tmp = ();
		if($params[$i] =~ /#/){
			@tmp = split(/#/, $params[$i]);
		}else{
			@tmp = split(/:/, $params[$i]);
		}
		$params[$i] = $tmp[$#tmp];
	}

	my $bbox = $in_params->{BBOX};

	if( not exists($sensor_list->{$sensorID})){
		exception_error(2, "Unknown GetObservation sensor: $sensorID");
	}
	foreach my $param ( @params ){
		if ( not exists( $sensor_list->{$sensorID}->{obsproplist}{$param} ) ){
			exception_error(2, "Unknown GetObservation observedPropetry: $param");
		}

	}
	my $sensor_urn = $sensor_list->{$sensorID}->{urn};
	my $lat = $sensor_list->{$sensorID}->{lat};
	my $lon = $sensor_list->{$sensorID}->{lon};
	# TODO: depth issue platform depth is 0
	my 	$depth = 0;
	
	my $sos = $parser->parse_file("$base_dir/sosGetObservation.xml");

	exception_error(5, "Could not open SOS template: sosGetObservation.xml") if not $sos;

	my $xc = XML::LibXML::XPathContext->new($sos);
	$xc->registerNs('om' => 'http://www.opengis.net/om/1.0');
	$xc->registerNs('swe' => 'http://www.opengis.net/swe/1.0.1');
	$xc->registerNs( 'gml' => 'http://www.opengis.net/gml');

	my $node;

	my @output_data = getDataDB($sensorID, $in_time, $bbox, \@params);

	my $stime = '';
	my $etime = '';
	if(@output_data){
		# use the first record time for the beginPosition time
		my @vals = split(/,/, $output_data[0]);
		$stime = $vals[1];
		$stime .= 'Z' if $stime !~ /Z/;
		# use the last record's time for the TimeInstant element.
		@vals = split(/,/, $output_data[$#output_data]);
		$etime = $vals[1];
		$etime .= 'Z' if $stime !~ /Z/;
	}

	my $root = $sos->documentElement();
	$root->setAttribute('gml:id', $org_acronym . '_sensor');


	# using the same description and name and lowerCorner and upperCorner
	# for both the <ObservationCollection> and <Observation>
	my $description = uc($params[0]);
	$description = 'Observable' if(@params > 1);
	$description .=  " measurements from $org_acronym $sensorID";

	foreach $node ($xc->findnodes("//gml:description")){
		$node->appendText( $description );
	}

	$node = ( $xc->findnodes("/om:ObservationCollection/gml:name") )[0];
	$node->appendText($description);
	$node = ( $xc->findnodes("/om:ObservationCollection/om:member/om:Observation/gml:name") )[0];
	$node->appendText($description);

	# this is different than root gml:id above.
	$node = ( $xc->findnodes("/om:ObservationCollection/om:member/om:Observation") )[0];
	$node->setAttribute('gml:id', $org_acronym . '_' . $sensorID );

	#################
	# GML boundedBy, appears twice
	#################
	foreach $node ($xc->findnodes("//gml:lowerCorner")){
		$node->appendText("$lat $lon $depth");
	}
	foreach $node ($xc->findnodes("//gml:upperCorner")){
		$node->appendText("$lat $lon $depth");
	}

	#################
	# DATA_TIME Instant or Period
	#################
	my $t_elem;
	if($stime eq $etime){
		$t_elem = $sos->createElement('gml:timeInstant');
		$t_elem->appendTextChild('gml:timePosition', $etime);
	}else{
		$t_elem = $sos->createElement('gml:TimePeriod');
		$t_elem->appendTextChild('gml:beginPosition', $stime);
		$t_elem->appendTextChild('gml:endPosition', $etime);
	}
	#$t_elem->setAttribute('gml:id', 'DATA_TIME' );

	$node = ($xc->findnodes("//om:Observation/om:samplingTime"))[0];

	$node->appendChild($t_elem);

	#################
	# procedure or sensor URN
	#################
	$node = ($xc->findnodes("//om:Observation/om:procedure"))[0];
	$node->setAttribute('xlink:href', $sensor_urn );

	#################
	# observedProperty, can be one or more, but we always use CompositePhenomenon which can have a dimesnion of 1
	#################
	$node = ($xc->findnodes("//om:Observation/om:observedProperty/swe:CompositePhenomenon"))[0];
	$node->setAttribute('dimension', scalar(@params));
	#$node->appendTextChild('gml:name', 'Buoy Observables');
	foreach my $param (@params){
		my $obs_prop = $sos->createElement('swe:component');
		$obs_prop->setAttribute('xlink:href', $observed_property_url . $param);
		$node->appendChild($obs_prop);
	}


	$node = ($xc->findnodes("//om:Observation/om:result/swe:DataArray/swe:elementType"))[0];

	setDataRecord($xc, $node, $sensorID, $sensor_list, \@params);
	my $element_count = checkDataRecord($xc);

	$node = ($xc->findnodes("//om:Observation/om:result/swe:DataArray/swe:elementCount/swe:Count/swe:value"))[0];
	$node->appendText( $element_count );

	# Add the data
	my $results = '';
	foreach (@output_data){
		chomp;
		$results .= $_ . ' ';
	}
	$results =~ s/ $//;
	$node = ($xc->findnodes("//om:Observation/om:result/swe:DataArray/swe:values"))[0];
	$node->appendText($results);

	return $sos;
}

################################################################# SUPPORT ROUTINES

#######################################
# setDataRecord - utilized by doDescribeSensor and doGetObservation
# The assumption is that observedProperty list is the last value in the tupple
#######################################
sub setDataRecord
{
	my ($xc, $node, $sensorID, $sensor_list, $obsproplist) = @_;

	$node->setAttribute('name', $sensorID . 'Observations');

	my $data_record =  ($xc->findnodes("swe:DataRecord", $node))[0];

	foreach my $field ( $node->findnodes("swe:DataRecord/*") ){
		next if ($field->getAttribute('name') ne 'observedProperty');
		my $clone = $field->cloneNode(1);
		$data_record->removeChild($field);

		my $param_count = 1;
		foreach my $param ( @{ $obsproplist } ){
			my $param_uom = $sensor_list->{$sensorID}->{obsproplist}->{$param}->{uom};
			my $param_def = $observed_property_url . $param;
			# Leave this generic, actual definition is in the definition attribute
			$clone->setAttribute('name', 'observedProperty' . $param_count );
			my $quantity =  ($clone->findnodes("swe:Quantity"))[0];
			$quantity->setAttribute('definition', $param_def);
			my $swe_uom =  ($quantity->findnodes("swe:uom"))[0];
			$swe_uom->setAttribute('code', $param_uom);

			$data_record->appendChild($clone);
			$clone = $clone->cloneNode(1);
			$param_count++;
		}
	}


}

#######################################
# checkDataRecord 
#######################################
# This is not yet used but is intended to help us deal with differing DataRecord definitions in the future, 
# in particular to deal with multiple observedProperties in one request and for the inclusion of QA/QC values in
# the responses.
# Currently use to check the number of fields in the DataRecord for setting DataArray/elementCount
#######################################
sub checkDataRecord
{
	my ($xc) = @_;

	my ($platform_pos, $time_pos, $lat_pos, $lon_pos, $depth_pos, $quality_pos, $data_pos) =
		(-1,-1,-1,-1,-1,-1,-1);
	my $fld_cnt = 0;
	# All elements with a definition attribute
	foreach my $node ( $xc->findnodes('//swe:DataRecord/swe:field/*[@definition]') )
	{
		my $def = $node->getAttribute('definition');
		$platform_pos = $fld_cnt if($def =~ /platform/i);
		$time_pos = $fld_cnt if($def =~ /time/i);
		$lat_pos = $fld_cnt if($def =~ /latitude/i);
		$lon_pos = $fld_cnt if($def =~ /longitude/i);
		$depth_pos = $fld_cnt if($def =~ /depth/i);
		$quality_pos = $fld_cnt if($def =~ /quality/i);
		# HERE This only allows for one data_pos, one quality_pos, etc.
		# This must be fixed
		$data_pos = $fld_cnt if($def =~ /observedProperty/i);
		$fld_cnt++;
	}
	#return ($platform_pos, $time_pos, $lat_pos, $lon_pos, $depth_pos, $quality_pos, $data_pos);
	return ($fld_cnt);
}

#######################################
# getInputParams ()
# Get the SOS input Parameters.
# Supports both HTTP GET Key Value Pairs and POST XML methods.  Assumes that both  use identical KVP key names and element names.
# observedProperty is really a misnomer: it can be a comma separated list of observedProperties
#######################################
sub getInputParams
{
	my $param_ref = shift;

	my $q = new CGI;

	# Some Command line tests
	# Uncommenting these allows the script to be run from the command line outputting XML for testing
	# They must be modifed for local platforms and observedProperites
	#my $q = new CGI('request=GetCapabilities');
	#my $q = new CGI('request=DescribeSensor&procedure=urn:gomoos.org:platform#B01');
	#my $q = new CGI('request=GetObservation&offering=A01&observedProperty=sea_water_salinity,sea_water_temperature&eventTime=2008-04-10T10:00:00Z/2008-04-10T14:00:00Z');
	#my $q = new CGI('request=GetObservation&offering=A01&observedProperty=sea_water_salinity,sea_water_temperature&bbox=-71.50,39.0,-63.0,40.0&eventTime=2008-04-10T10:00:00Z/2008-04-10T14:00:00Z');

	#my $q = new CGI('request=GetObservation&offering=A01&observedProperty=significant_height_of_wind_and_swell_waves,sea_water_temperature');
	#my $q = new CGI('request=GetObservation&offering=A01&observedProperty=SEA_WATER_SALINITY');
	#my $q = new CGI('request=GetObservation&offering=A01&observedProperty=sea_water_temperature');

	# Parse XML submitted via POST 
	if( uc($q->request_method()) eq 'POST'){
		my $in = $q->param('POSTDATA');
		exception_error(1, "No input parameters") if (not $in);
		my $xml_in = $parser->parse_string($in);
		# Parameter xml has a default namespace of sos
		my $xc = XML::LibXML::XPathContext->new($xml_in);
		# sos prefix may be the default namespace
		$xc->registerNs( 'sos' => 'http://www.opengis.net/sos/1.0');
		$xc->registerNs( 'ogc' => 'http://www.opengis.net/ogc');
		$xc->registerNs( 'gml' => 'http://www.opengis.net/gml');
		# get the name of the root element
		my $request = $xml_in->documentElement()->nodeName;
		#  Root element name may or may not have a prefix. So remove it
		$request =~ s/.+://;
		$param_ref->{REQUEST} = $request;
		if($request eq 'GetObservation'){
			$param_ref->{TIME} = '';
			$param_ref->{BBOX} = '';
			my $val =  $xc->find('//sos:GetObservation/sos:offering')->string_value;
			$param_ref->{OFFERING} = $val;
			# Turn into comma separate list
			foreach my $node ( $xc->findnodes("//sos:GetObservation/sos:observedProperty") ){
				$param_ref->{OBSERVEDPROPERTY} .= $node->string_value . ',';
			}
			# remove final comma
			chop( $param_ref->{OBSERVEDPROPERTY} );

			my @nodes = $xc->findnodes("/sos:GetObservation/sos:eventTime/ogc:T_During/*");
			if(@nodes){
				my $node = $nodes[0];
				my $time = '';
				# We handle single time or min/max times
				if($node->nodeName eq 'gml:TimeInstant'){
					$time= $xc->find("gml:timePosition", $node)->string_value;
				}
				if($node->nodeName eq 'gml:TimePeriod'){
					$time= $xc->find("gml:beginPosition", $node)->string_value;
					$time .= '/';
					$time .= $xc->find("gml:endPosition", $node)->string_value;
				}
				$param_ref->{TIME} = $time;
			}
			my @nodes = $xc->findnodes("/sos:GetObservation/sos:featureOfInterest/ogc:BBOX/gml:Envelope/*");
			if(@nodes){
				my ($lc, $uc) = ('','');
				foreach my $node (@nodes){
					if($node->nodeName eq 'gml:lowerCorner'){
						$lc = $node->string_value;
						$lc =~ s/ /,/g;
					}
					if($node->nodeName eq 'gml:upperCorner'){
						$uc = $node->string_value;
						$uc =~ s/ /,/g;
					}
				}
				$param_ref->{BBOX} = "$lc,$uc";
			}
		}

		if($request eq 'DescribeSensor'){
			my $val =  $xc->find('//sos:DescribeSensor/sos:procedure')->string_value;
			$param_ref->{PROCEDURE} = $val;
		}
	}else{
		# Convert all Keys in KVP to all uppercase.
		# Param names can be uppercase, e.g. request or REQUEST or Request
		my @param_names = $q->param;
		foreach my $p (@param_names){
			$param_ref->{uc($p)} = $q->param($p);
		}
	}
}

########################################
# GoMOOS Specific routines
########################################
#  getMetaData()
########################################
#  This routine populates the global hash, %sensor_list
#  %sensor_list contains the metadata for each sensor  and one hash: obsproplist with the
#  observedProperites as the keys and the Units of Measure and the observation file or 'DataBase' as the values.
########################################
#
# 'A01' => {
#   'platform' => 'A01',
#   'urn' => 'urn:gomoos.org:source.mooring#A01',
#   'long_name' => 'Mooring A01 GoMOOS',
#   'provider_name' => 'GoMOOS',
#   'lat' => '42.5227336883545',
#   'lon' => '-70.5647239685059',
#   'start_time' => '2001-07-10T03:00:00Z',
#   'end_time' => '',
#   'comments' => 'Mooring A01 data from the Gulf of Maine Ocean Observing System (GoMOOS) located Massachusetts Bay',
#   'obsproplist' => {
#      'sea_water_temperature' => {
#         'obs_file' => '/home/data/web_tmp/sos/A01_SEA_WATER_TEMPERATURE.txt',
#         'uom' => 'celsius'
#        },
#      'sea_water_salinity' => {
#          'obs_file' => 'DataBase',
#         'uom' => 'psu'
#      }
#   },
# }
###############################################
sub getMetaData
{
	my ($use_config, $sensor_list) = @_;
	return (getMetaDB($sensor_list));
}
###############################################
sub getMetaDB
{

	my $sensor_list = shift;

# LOCAL EDIT

##########SQL
	my $sql_statement =  <<ESQL;
select distinct platform.platform_handle as platform
    ,fixed_longitude as longitude
    ,fixed_latitude as latitude
    ,'2009-01-02T15:00:00Z'
    ,''
    ,platform.description as description 
    ,obs_type.standard_name as observed_property
  from platform
    left join sensor on platform.row_id=sensor.platform_id
    left join m_type on m_type.row_id=sensor.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id
  order by platform_handle,obs_type.standard_name;
ESQL
##########SQL

# END LOCAL EDIT

	$sth = $dbh->prepare($sql_statement) or die("Database Error", $dbh->errstr);
	if ($sth->execute()) {
		while (my $ref = $sth->fetchrow_hashref()) {
			my $platform = $ref->{platform};
			my $obsprop = $ref->{observed_property};
			my $start_time = get_start_time($dbh, $platform);
			my $comments = "Mooring $platform data from the $org ($short_org) located ";
			$comments .= $ref->{description};

			$sensor_list->{$platform}->{platform} = $platform;
			$sensor_list->{$platform}->{urn} = $platform_uri . $platform;
			$sensor_list->{$platform}->{long_name} = "Mooring $platform $short_org";
			$sensor_list->{$platform}->{provider_name} = $short_org;
			$sensor_list->{$platform}->{lat} = $ref->{latitude};
			$sensor_list->{$platform}->{lon} = $ref->{longitude};
			$sensor_list->{$platform}->{start_time} = $start_time;
			$sensor_list->{$platform}->{end_time} = '';
			$sensor_list->{$platform}->{comments} = $comments;
			# All observed properties must be in the %uom_lookup table
			next if (not exists($uom_lookup{$obsprop}));
			my $uom = $uom_lookup{$obsprop};

			$sensor_list->{$platform}->{obsproplist}->{$obsprop}->{uom} = $uom;
			$sensor_list->{$platform}->{obsproplist}->{$obsprop}->{obs_file} = 'DataBase';

		}
	}else{
		die("Database Error", $dbh->errstr);
	}

	#########################
	# An Example of adding a procedure which allows retrieval of obervedProperties for all GoMOOS Platforms
	# ALL_PLATFORMS
	#########################

	#my $comments = "Mooring data for all buoys from the $org ($short_org) located in the Gulf of Maine";
	#my $platform = 'ALL_PLATFORMS';
	#$sensor_list->{$platform}->{platform} = $platform;
	#$sensor_list->{$platform}->{urn} = $platform_uri . $platform;
	#$sensor_list->{$platform}->{long_name} = "Mooring $platform $short_org";
	#$sensor_list->{$platform}->{provider_name} = $short_org;
	# Hmmmm here we  would need bounding box! This is the BBox centroid
	#$sensor_list->{$platform}->{lat} = '42.75';
	#$sensor_list->{$platform}->{lon} = '-67.25';
	# Earliest GoMOOS start time
	#$sensor_list->{$platform}->{start_time} = '2000-07-10T20:00:00Z';
	#$sensor_list->{$platform}->{end_time} = '';
	#$sensor_list->{$platform}->{comments} = $comments;
	# List all observed properties in the %uom_lookup table
	#foreach my $obsprop (sort keys %uom_lookup){
	#	my $uom = $uom_lookup{$obsprop};
	#	$sensor_list->{$platform}->{obsproplist}->{$obsprop}->{uom} = $uom;
	#	$sensor_list->{$platform}->{obsproplist}->{$obsprop}->{obs_file} = 'DataBase';
	#}

}

###############################################
sub get_start_time
{

		return '2009-01-01T00:00:00Z'; #LOCAL EDIT
=comment
	my ($dbh, $platform) = @_;
#LOCAL EDIT - SQL
	my $sql_statement =  "select min(start_time) at time zone 'UTC' as start_time from time_series where program = 'GoMOOS' AND display_platform = '$platform'";
	my $sth = $dbh->prepare($sql_statement) or die("Database Error", $dbh->errstr);
	if ($sth->execute()) {
		my $ref = $sth->fetchrow_hashref();
		my $t = $ref->{start_time};
		$t =~ s/ /T/;
		$t .= 'Z';
		return $t;
	}
=cut
}


########################################
#  getDataDB()
#    This routine should return a array of strings containing your data tuples for a GetObservation request.
#    At GoMOOS have set up two different views for returning data based on time query versus a query for the
#    most recent observations.
#    The OOSTethys SOS defines a data tuple as:
#    platform,time,latitude,longitude,depth,observedProperty, .. (with a comma field separator and a space record separator)
#      additional observedProperties for the same time and depth may be appended to the tuple when the
#      getObservation request contains a list of observedProperties.
#    e.g.
#   'platform,YYYY-MM-DDTHH:MM:SSZ,latitude,longitude,depth,observedValue1,observedValue2,observedValue3'
#	Note: no spaces, space is the record separator
#    $data = [
#        'A01,2008-13-02T18:00:00Z,43.5695,-70.055,1,3.171'
#        'A01,2008-13-02T18:00:00Z,43.5695,-70.055,2,3.157801'
#        'A01,2008-13-02T18:00:00Z,43.5695,-70.055,20,3.178'
#    ];
#######################################

sub getDataDB
{
	my ($sensorID, $in_time, $bbox, $params) = @_;

	my @params = @{$params};

# LOCAL EDITS

	my ($date_column,$date_clause,$group_clause);	
	#my $obstype_clause = "obs_type.standard_name = 'wind_speed'"; #testing
	my $obstype_clause = "";
        my $platform_clause = "platform_handle = '$sensorID'";
	my $location_clause = '1=1'; #bbox here but not really working right


        ###########################
        # Handle ALL_PLATFORMS procedure
        ###########################
        #if($sensorID ne 'ALL_PLATFORMS'){
        #       $platform_clause = "platform_handle like '%$sensorID%'";
        #}

        ###########################
        # Handle BBOX queries $bbox = 'min_longitude, min_latitude, max_longitude, max_latitude'
        ###########################
        if($bbox){
                my @latlons = split(',', $bbox);
                $location_clause = "m_lon >= $latlons[0] and m_lon <= $latlons[2]";
                $location_clause .= " and m_lat >= $latlons[1] and m_lat <= $latlons[3]";
        }

        ###########################
        # Handle time range parameters(or absence=latest)
        ###########################
        if($in_time){
                my ($time1, $time2) = ('','');;
                # '/' is the separator
                if($in_time =~ /\// ){
                        ($time1, $time2) = split( /\//, $in_time);
                }else{
                        $time1 = $in_time;
                        $time2 = $in_time;
                }
                #strip Z from $in_time
                $time1 =~ s/Z$//;
                $time2 =~ s/Z$//;
                $date_column = "m_date";
                $group_clause = "";
                $date_clause = "m_date >= '$time1' and m_date <= '$time2'";
        }
        else {
                #note 'where m_date > now()' is based on EST/EDT which gives us a 4-5 hour window for latest obs in consideration, will need to add/subtract additional hours for other time zones
                $date_column = "max(m_date)";
                $group_clause = "group by platform_handle,obs_type.standard_name";
                $date_clause = "m_date > strftime('%Y-%m-%dT%H:%M:%S','now','-1 day')";        
        }

        ###########################
        # Handle mulitple parameters
        # E.g. we need:  AND (observed_property = 'salinity' OR observed_property = 'water_temperature')
        ###########################

        $obstype_clause .= 'AND (';
        for my $idx (0 .. $#params){
                $obstype_clause .= " OR observed_property =  '$params[$idx]' " if ($idx > 0);
                $obstype_clause .= " observed_property =  '$params[$idx]' " if ($idx == 0);
        }
        $obstype_clause .= ')';
 

##########SQL
#note SQL WHERE column order should match search indexes or vice versa for performance

	my $sql_statement =  <<ESQL;
select platform_handle as platform
    ,obs_type.standard_name as observed_property
    ,$date_column as date_time
    ,m_lat as latitude
    ,m_lon as longitude
    ,m_z as depth
    ,m_value as observation
  from multi_obs
    left join m_type on m_type.row_id=multi_obs.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id
  where $date_clause
  $obstype_clause
  and $platform_clause
  and $location_clause
$group_clause;
ESQL
##########SQL

#since apache process, must write log file to apache-owned folder like /tmp/ms_tmp
#open (DEBUG_FILE,">/tmp/ms_tmp/debug.txt");
#print DEBUG_FILE "$in_time \n $sql_statement";
#close (DEBUG_FILE);

# END LOCAL EDITS

	my @return_data = ();
	my %data_by_time = ();

	$sth = $dbh->prepare($sql_statement) or die("Database Error", $dbh->errstr);
	if ($sth->execute()) {
		my $rows = $sth->fetchall_arrayref({});
		foreach my $row ( @{$rows} ){
			my $platform = $row->{platform};
			my $t = $row->{date_time};
			$t =~ s/ /T/;
			$t .= 'Z';
			my $depth = $row->{depth};
			my $lat = $row->{latitude};
			my $lon = $row->{longitude};
			$data_by_time{$platform}{$t}{$depth} = "$platform,$t,$lat,$lon,$depth";
		}
		exception_error(5,  "Data not available for the requested Time or BBOX.") if  not %data_by_time;

		foreach my $this_param (@params){
			# Add trailing comma for each param
			foreach my $plt (keys %data_by_time){
				foreach my $dt (keys %{ $data_by_time{$plt} }){
					foreach my $dp (keys %{ $data_by_time{$plt}{$dt} }){
						$data_by_time{$plt}{$dt}{$dp} .= ',';
					}
				}
			}
			foreach my $row ( @{$rows} ){
				next if ($row->{observed_property} ne "$this_param");
				my $plt = $row->{platform};
				my $t = $row->{date_time};
				$t =~ s/ /T/;
				$t .= 'Z';
				my $depth = $row->{depth};
				my $obs = $row->{observation};
				$data_by_time{$plt}{$t}{$depth} .= $obs;
			}
		} # end foreach $this_param

	}else{
		die("Database Error", $dbh->errstr);
	}

	foreach my $plt (sort keys %data_by_time){
		foreach my $dt (sort keys %{ $data_by_time{$plt} }){
			foreach my $dp (sort {$a <=> $b} keys %{ $data_by_time{$plt}{$dt} }){
				push (@return_data, $data_by_time{$plt}{$dt}{$dp});
			}
		}
	}

	return @return_data;
}

