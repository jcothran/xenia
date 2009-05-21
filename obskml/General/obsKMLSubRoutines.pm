#######################################################################################################
#Revisions
#Rev: 1.2.0.0
#Author: DWR
#Sub: KMLAddObsToHash, KMLAddObsList
#Changes: In the observation hash, the sorder is now a hash key and not simply a value. This allows us to have the same sensor
# at the same elevation, and we can distinguish them by the sorder.
#Rev: 1.1.0.0
#Author: DWR
#Date: 6/4/2008
#Sub: KMLAddPlacemarkSimple
#Changes: Added call to KMLAddDescription to add in the observation HTML table into a description tag.
#         Also added the creation of the <name> tag to properly name our placemark.
#Sub: KMLAddObsList
#Changes: Added building the observation HTML table string while building the metadata.
#Sub: KMLAddDescription
#Changes: Added subroutine.
#######################################################################################################

package obsKMLSubRoutines; 

use strict;
use XML::LibXML;

my $QCLEVEL_DATAMISSING = -9; #missing value
my $QCLEVEL_DATANOTEVALD=  0; #quality not evaluated
my $QCLEVEL_DATABAD     =  1; #bad
my $QCLEVEL_DATASUSPECT =  2; #questionable/suspect
my $QCLEVEL_DATAGOOD    =  3; #good

#######################################################################################################
# LoadPlatformControlFile
#######################################################################################################
#######################################################################################################
# LoadPlatformControlFile
# This sub loads up the platforms and observation for the platform into a hash.
# The structure of the XML file should be:
#  <ControlSet>
#    <id>NameForThisGrouping</id>
#    <PlatformList>
#      <Platform>
#        <TelemetryID></TelemetryID>
#        <PlatformOldName>buoy2</PlatformOldName>
#        <PlatformID>carocoops.FRP2.buoy</PlatformID>
#        <PlatformURL>http://nautilus.baruch.sc.edu/carocoops_website/buoy_detail.php?buoy=buoy2</PlatformURL>
#      </Platform>
#    </PlatformList>
#    <ObsList>
#      <Obs>
#        <ObsHandle>water_pressure</ObsHandle>        
#        <Elev>-1</Elev>
#        <SOrder>1</SOrder>       
#        <uomType>mb</uomType>
#        <BinCellSize></BinCellSize>
#      </Obs>
#    </ObsList>
#  </ControlSet>
#  
# Parameters:
# 1) $strControlFileName is a string to the filename of the xml control file we are going to parse.
# 2) $rPlatformHash is a reference to a hash in which we populate the date.
# 3) $strBuoyID is an optional argument if we only want to load the specified platform.
#     The resulting hash will be structured as follows:
#          $rPlatformHash->{PlatformID}{TelemetryID}
#          $rPlatformHash->{PlatformID}{BuoyOldName}
#          $rPlatformHash->{PlatformID}{PlatformURL}
#          $rPlatformHash->{PlatformID}{sorder}{obsHandle}{elev}
#          $rPlatformHash->{PlatformID}{sorder}{obsHandle}{UoMType}        
#          $rPlatformHash->{PlatformID}{sorder}{obsHandle}{BinDepth}
#   where:
#   PlatformID is the name of the platform, such as carocoops.CAP2.buoy.
#   TelemetryID is the unique ID in the source data file.
#   BuoyOldName is used for the filenames(Buoy1.....) and translating that name to the PlatformID
#   PlatformURL is the URL for the platform.
#   sorder number(1...N) which is used to distinguish between multiple similar sensors on the platform, such as water_temperature.
#   obsHandle is the observation name, such as water_temperature.
#   elev is the elevation, relative to the platform, of the sensors. Can be positive(above surface) or negative(below)
#   UoMType is the unit of measurement the sensor uses from the platform.
#   BinDepth is the spacing of the trays in an ADCP setup.
#######################################################################################################
sub LoadPlatformControlFile
{
  my( $strControlFileName, $rPlatformHash, $strStationID ) = @_;
  
  my $strSQL;
  my $XMLControlFile = XML::LibXML->new->parse_file($strControlFileName);
  my $iLoadSinglePlatform = 0;
  if( length( $strStationID ) )
  {
    $iLoadSinglePlatform = 1;
  }
  if( defined $XMLControlFile )
  { 
    foreach my $ControlSet ($XMLControlFile->findnodes('//ControlSet'))
    {
      my $strID = sprintf("%s", $ControlSet->find('id') );
      foreach my $Platform ($ControlSet->findnodes('PlatformList/Platform'))
      {
        my $iSavePlatformData = 1;
        my $strBuoyOldName = sprintf("%s",$Platform->find('PlatformOldName'));
        if( $iLoadSinglePlatform )
        {
          if( $strStationID ne $strBuoyOldName )
          {
            $iSavePlatformData = 0;
          }
        }
        if( $iSavePlatformData )
        {       
          my $strTelemetryID = sprintf("%s",$Platform->find('TelemetryID'));
          my $strPlatformURL = sprintf("%s",$Platform->find('PlatformURL'));
          my $strPlatformID = sprintf("%s",$Platform->find('PlatformID'));
               
          $rPlatformHash->{PlatformID}{$strPlatformID}{TelemetryID} = $strTelemetryID;
          $rPlatformHash->{PlatformID}{$strPlatformID}{PlatformOldName} = $strBuoyOldName;
          $rPlatformHash->{PlatformID}{$strPlatformID}{PlatformURL} = $strPlatformURL;
          #Now let's get the observations for the platform.
          foreach my $obs ($ControlSet->findnodes('ObsList/Obs'))
          {
            my $strobsHandle= sprintf("%s", $obs->find('ObsHandle') );      #The observation name.
            my $strSorder   = sprintf("%s", $obs->find('SOrder') );         #The sensor order used to distinguish multiple like sensors.
            #my $strElev     = sprintf("%s", $obs->find('Elev') );           #The elevation, relative to the platform.
            #my $strUOM      = sprintf("%s", $obs->find('uomType') );        #Unit of measurement for the measurement.
            #my $strSrcUOM   = sprintf("%s", $obs->find('DataSrcUOMType') ); #Unit of measurement for the measurement of the source data.
            #print( "ControlSet: $strID PlatformID: $strPlatformID sorder: $strSorder obsHandle: $strobsHandle elev: $strElev\n");
            $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{elev}          = sprintf("%s", $obs->find('Elev') );           #The elevation, relative to the platform. 
            $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{UoMType}       = sprintf("%s", $obs->find('uomType') );        #Unit of measurement for the measurement.       
            #$rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{DataSrcUoMType}= sprintf("%s", $obs->find('DataSrcUOMType') ); #Unit of measurement for the measurement of the source data.         
            #Normally only the ADCPs should have the bin cell tags. 
            $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{BinDepth} = sprintf("%s", $obs->find('BinCellSize') );; 
                                                                                                           
          }
        }
      }
    }
=comment    
    #foreach my $ID ( keys %{$rPlatformHash->{ControlSet}} )
    {
      foreach my $Platform ( keys %{$rPlatformHash->{PlatformID}} )
      {
        my $strURL = $rPlatformHash->{PlatformID}{$Platform}{PlatformURL}; 
        my $strTelemetryID = $rPlatformHash->{PlatformID}{$Platform}{TelemetryID};
        my $strOldName = $rPlatformHash->{PlatformID}{$Platform}{BuoyOldName};
        print( "Platform: $Platform $strURL\n");
        foreach my $SOrder ( sort keys %{$rPlatformHash->{PlatformID}{$Platform}{sorder}} )
        {
          print( "\tSOrder: $SOrder\n" );          
          foreach my $ObsHandle ( keys %{$rPlatformHash->{PlatformID}{$Platform}{sorder}{$SOrder}{obsHandle}} )
          {
            print( "\t\tObsHandle: $ObsHandle\n");
            my $i = 0;
          }
        }
      }
    }
=cut    
    return( 1 );
  }
  return( 0 );
}

#######################################################################################################
#GetPlatformData
# This subroutines parses the hash created from LoadPlatformControlFile and populates looking for the 
# platfrom with the old name of $strInternalName.
# the hash reference $Results. It adds the following hash entries:
#   $Results->{PlatformURL}
#   $Results->{PlatformID}
#
#Parameters
# 1) $rPlatformHash is a reference to a populated hash created from LoadPlatformControlFile.
# 2) $strInternalName is the name of the stations old(script internal name) we are looking for.
# 3) $Results is the hash we populate from our search.
#
# Return
#  1 if we found something, otherwise 0.
#######################################################################################################
sub GetPlatformData #( $rPlatformHash, $strInternalName, $Results )
{
  my ( $rPlatformHash, $strInternalName, $Results ) = @_;
  foreach my $ID( keys %{$rPlatformHash->{PlatformID}} )
  {
    my $strOldName = $rPlatformHash->{PlatformID}{$ID}{PlatformOldName};        
    if( $strOldName eq $strInternalName )
    {
      $Results->{PlatformURL}= $rPlatformHash->{PlatformID}{$ID}{PlatformURL};
      $Results->{PlatformID} = $ID;
      return( 1 );
    }
  }
  return( 0 );
} 
#######################################################################################################
# Subroutine: GetObsData
#  This subroutine searches the $rPlatformHash populated from LoadPlatformControlFile looking for the 
#   passed in observation name and sensor order. If it finds a match, it then populates the 
#   $Results hash reference with the following entries:
#     $Results->{PlatformID}
#     $Results->{BinDepth}
#     $Results->{UoM}
#######################################################################################################
sub GetObsData #( $rPlatformHash, $strObsHandle, $SOrder, $Results )
{
  my ( $rPlatformHash, $strObsHandle, $SOrder, $Results ) = @_;
  my $strPlatformID = $Results->{PlatformID};
  my $strElev = undef;
  my $strBin  = undef;
  my $strUOM  = undef; 
  my $iFoundItems = 0;
  if( exists( $rPlatformHash->{PlatformID} ) )
  {
    if( exists( $rPlatformHash->{PlatformID}{$strPlatformID}{sorder} ) )
    {
      if( exists( $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$SOrder}{obsHandle} ) )
      {
        $strElev = $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$SOrder}{obsHandle}{$strObsHandle}{elev};
        $strBin = $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$SOrder}{obsHandle}{$strObsHandle}{BinDepth};
        $strUOM = $rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$SOrder}{obsHandle}{$strObsHandle}{UoMType};
        $iFoundItems = 1;
      }
    }
  }
  if( $iFoundItems == 0 )
  {
    print( "ERROR::GetObsData: Platform: $rPlatformHash Obs: $strObsHandle SOrder: $SOrder was not found in the lookup.\n");
  }
  elsif( length( $strElev ) == 0 )
  {
    print( "WARNING::GetObsData: Missing elev Platform: $strPlatformID Obs: $strObsHandle SOrder: $SOrder Elev: $strElev UoMType: $strUOM\n");
  }
  $Results->{elev}      = $strElev;
  $Results->{BinDepth}  = $strBin;
  $Results->{UoM}       = $strUOM;
  return( $iFoundItems );
}
#######################################################################################################
#Subroutine: GetConversionUnits
#Given a unit of one measurement system, this subroutine will return the equivalent unit from the 
# specified system. IE if you have "m" in the metric system and want the equivalent in the Imperial system.
#######################################################################################################
sub GetConversionUnits #($strCurrentUnits, $strDesiredUOMSystem )
{
  my ( $strCurrentUnits, $strDesiredUOMSystem ) = @_;
  if( $strDesiredUOMSystem eq 'en' )
  {
    if( $strCurrentUnits eq 'm' )
    {
      return( 'ft' );
    }
    elsif( $strCurrentUnits eq  'm_s-1' )
    {
      return( 'mph' );
    }
    elsif( $strCurrentUnits eq 'celsius' )
    {
      return( 'fahrenheit' );
    }
    elsif( $strCurrentUnits eq 'cm_s-1' )
    {
      return( 'mph' );
    }
    elsif( $strCurrentUnits eq 'mph' )
    {
      return( 'knots' );
    }
  }
  else
  {
  }
  return('')
}

#######################################################################################################
# Subroutine: MeasurementConvert
# Given a measurement, source units and desired units, this sub tries to find a conversion function.
# if successful it then applies the function against the measurement value and returns the result.
# Parameters
# 1) $Measurement is the measurement value we want to convert.
# 2) $strSourceUOM is a string with the units of measurements the $Measurement is currently in.
# 3) $strDesiredUOM is a string with the units of measurements we want to convert to.
# 4) $XMLDoc is a XML document that represents the UnitsConversion.xml file.
#######################################################################################################
sub MeasurementConvert #($Measurement,$strSourceUOM,$strDesiredUOM,$XMLDoc)
{
  my ($Measurement,$strSourceUOM,$strDesiredUOM,$XMLDoc) = @_;
  my $strConvertedVal = '';
  my $strConversionFormula = $XMLDoc->findvalue('//unit_conversion_list/unit_conversion[@id="'.$strSourceUOM.'_to_'.$strDesiredUOM.'"]/conversion_formula');
  if( length( $strConversionFormula ) )
  {
    #unit conversion using supplied equation(e.g. celcius to fahrenheit)
    my $strConversionString = $strConversionFormula;
    $strConversionString =~ s/var1/$Measurement/g;
    $strConvertedVal = eval $strConversionString;
  }
  #print "$strConvertedVal \n";
  return $strConvertedVal;

}
#######################################################################################################
# Subroutine: CleanString
# Takes a string and removes unprintable characters from it. Tries to make sure the string contains
# only alpha numerics.
#######################################################################################################
sub CleanString #( $strString )
{
  my $strString = shift @_;
  my $strClean;
  $strClean = $strString;
  $strClean =~ tr/\x80-\xFF//d;
  $strClean =~ s/\x//;
  $strClean =~ s/\x00$//;
  
  return $strClean;
}
#######################################################################################################
# Subroutine: UnitsStringConversion
# Takes a given units string and converts it into a string that we use internally.
#######################################################################################################
sub UnitsStringConversion #($strFromUOMString, $XMLDoc)
{
  my ($strFromUOMString, $XMLDoc) = @_;

  my $strConvertedString = '';
  #DWR 4/15/2008
  #Remove any characters we don't want used. I did notice the unicode char "\x" was in some ndbc files.
  #$strFromUOMString =~ tr/\x80-\xFF//d;
  #$strFromUOMString =~ s/\x//;
  #$strFromUOMString =~ s/\x00$//;
  my $strUOM = CleanString( $strFromUOMString );
  
  #print( "UnitsStringConversion:: XMLLookup: //unit_conversion_list/unit_conversion[\@id=\"$strFromUOMString\"]/units\n");
  my $strConversionString = $XMLDoc->findvalue('//unit_conversion_list/unit_conversion[@id="'.$strUOM.'"]/units');
  if( length( $strConversionString ) )
  {
    $strConvertedString = $strConversionString;
  }
  #print "UnitsStringConversion::Units: $strConvertedString \n";
  return $strConvertedString;
 
}

#######################################################################################################


#######################################################################################################
# When building the observation hash that is to eventually be written into the obsKML file, we have some
# helper functions. Either we can use a control file that has information about the platforms we want to 
# add, thus adding only what is in the control file( use subroutines KMLAddPlatformHashEntry and AddObsHashEntry )
# or we can freely add platforms and obs using subroutines KMLAddPlatformHashEntry and KMLAddObsToHash.
# In either case the user should be mindful of the calling sequence:
# 
# To start the platform call either KMLAddPlatformHashEntry then add the observations
# using KMLAddObsHashEntry or KMLAddObsToHash. When another platform is to be added, start the sequence again.
# When you are done, call BuildKMLFile giving it the observation hash and the name of the file you want to
# create and hopefully everything works alright. 
#######################################################################################################


#######################################################################################################
# Hash building subs that use the control file
#######################################################################################################
#######################################################################################################
# Subroutine:
# KMLAddPlatformHashEntry
# Adds the Platform specific items to the passed in $rObsHash.
#
#######################################################################################################
sub KMLAddPlatformHashEntry #( $strPlatformID, $strPlatformURL, $Latitude, $Longitude, $rObsHash )
{
  my ( $strPlatformID, $strPlatformURL, $Latitude, $Longitude, $rObsHash ) = @_;
  $rObsHash->{PlatformID}{$strPlatformID}{Latitude}     = $Latitude;
  $rObsHash->{PlatformID}{$strPlatformID}{Longitude}    = $Longitude;
  $rObsHash->{PlatformID}{$strPlatformID}{PlatformURL}  = $strPlatformURL;    
}
#######################################################################################################
# Subroutine: AddObsHashEntry
# Purpose:
#   This sub builds the hash that we in turn use to drive the BuildKMLFile() subroutine with.
#   It builds up a hash with the following structure:
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{uomType}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{value}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{QCLevel}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{sorder}
# Parameters
# 1) $strObsName is a string that holds the observation name we are adding.
# 2) $strDate is a string representing the date of the observation.
# 3) $Value is the value of the observation.
# 4) $SensorSOrder is the sensor order for the obs.
# 5) $rObsHash is the hash we are adding everything into.
# 6) $rPlatformControlFileInfo is a hash reference to the control file so we can look up the info we need for the obs.
# 7) $rPlatformObsSettings is a reference to a hash that has info such as the platform that we can use to look up the observation data from via GetObsData.
#######################################################################################################
sub KMLAddObsHashEntry #( $strObsName, $strDate, $Value, $SensorSOrder, $rObsHash, $rPlatformControlFileInfo, $rPlatformObsSettings )
{
  my ( $strObsName, $strDate, $Value, $SensorSOrder, $rObsHash, $rPlatformControlFileInfo, $rPlatformObsSettings ) = @_;
 
  my $QCLevel = $QCLEVEL_DATANOTEVALD;
  my $strPlatformID = $rPlatformObsSettings->{PlatformID};
  GetObsData( $rPlatformControlFileInfo, $strObsName, $SensorSOrder, $rPlatformObsSettings );
  $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$rPlatformObsSettings->{elev}}{obsType}{$strObsName}{uomType} = $rPlatformObsSettings->{UoM};
  $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$rPlatformObsSettings->{elev}}{obsType}{$strObsName}{sorder}  = $SensorSOrder;
  if( $Value ne 'NULL')
  {
    $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$rPlatformObsSettings->{elev}}{obsType}{$strObsName}{value} = $Value;
  }
  else
  {
    $QCLevel = $QCLEVEL_DATAMISSING;
  }
  $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$rPlatformObsSettings->{elev}}{obsType}{$strObsName}{QCLevel} = $QCLevel;  
}

#######################################################################################################
#Hash building subs that can be used without the control file
#######################################################################################################

#######################################################################################################
# Subroutine: KMLAddObsToHash
# Purpose:
#   This sub builds the hash that we in turn use to drive the BuildKMLFile() subroutine with.
#   It builds up a hash with the following structure:
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{uomType}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{value}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{QCLevel}
#   $rObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{sorder}
# Parameters
# 1) $strObsName is a string that holds the observation name we are adding.
# 2) $strDate is a string representing the date of the observation.
# 3) $Value is the value of the observation.
# 4) $SensorSOrder is the sensor order for the obs.
# 6) $strPlatformID is the platform name the observation is from.
# 7) $ObsElevation is teh elevation of the sensor.
# 8) $strUnits are the units of measurement for the observation.
# 9) $rObsHash is the hash we are adding everything into
#######################################################################################################
sub KMLAddObsToHash #( $strObsName, $strDate, $Value, $SensorSOrder, $strPlatformID, $ObsElevation, $strUnits, $rObsHash  )
{
  my ( $strObsName, $strDate, $Value, $SensorSOrder, $strPlatformID, $ObsElevation, $strUnits, $rObsHash ) = @_;
  print( "KMLAddObsToHash::Adding Obs: $strObsName Date: $strDate Val: $Value SORder: $SensorSOrder Platform: $strPlatformID Elev: $ObsElevation Units: $strUnits Lat: $rObsHash->{PlatformID}{$strPlatformID}{Latitude} Long: $rObsHash->{PlatformID}{$strPlatformID}{Longitude}\n" );
  my $QCLevel = $QCLEVEL_DATANOTEVALD;
  #DWR v1.2.0.0 Use the sorder as a has key, not just a value.
  $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{sorder}{$SensorSOrder}{obsType}{$strObsName}{uomType} = $strUnits;
  #$rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{obsType}{$strObsName}{sorder}  = $SensorSOrder;  
  if( $Value ne 'NULL')
  {
    #$rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{obsType}{$strObsName}{value} = $Value;
    #DWR v1.2.0.0 Use the sorder as a has key.
    $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{sorder}{$SensorSOrder}{obsType}{$strObsName}{value} = $Value;
  }
  else
  {
    $QCLevel = $QCLEVEL_DATAMISSING;
  }
  #$rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{obsType}{$strObsName}{QCLevel} = $QCLevel;  
  #DWR v1.2.0.0 Use the sorder as a has key.
  $rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}{$strDate}{elev}{$ObsElevation}{sorder}{$SensorSOrder}{obsType}{$strObsName}{QCLevel} = $QCLevel;  
}

                                    
######################################################################################################
#Subroutine: BuildKMLFile
# Given a hash and a filename, this set of subroutines will build an obsKML file.
# Parameters:
# 1) A reference to an observation hash. The hash needs to be contructed in the following manner:
#     ObsHash{PlatformID}{Latitude}
#     ObsHash{PlatformID}{Longitude}
#     ObsHash{PlatformID}{PlatformURL}
#     ObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{uomType}
#     ObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{value}
#     ObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{QCLevel}
#     ObsHash->{PlatformID}{TimeStamp}{elev}{obsType}{sorder}
# 2) $strKMLFileName is a string that contains the fully qualified filename to use to write the XML to.
########################################################################################################

sub BuildKMLFile #( $rObsHash, $strKMLFileName )
{
  my( $rObsHash, $strKMLFileName, $strPlatformControlFile ) = @_;
  
  my %PlatformIDHash;
   
  my $XMLFile = undef;
  #Create the XML document object.
  my $XMLDoc = XML::LibXML::Document->new();

  #Open the file we write the XML into.
  open( $XMLFile, ">", $strKMLFileName );
  if( !defined $XMLFile )
  {
   print( "ERROR: Unable to open file: $strKMLFileName\n" );
   die;
  }
  
  my $strName = 'Near Real-Time Ocean Data published by SECOORA';
  
  my $DocRoot = KMLAddHeader( $XMLDoc, $strName ); 
  if( defined $DocRoot )
  { 
    # We build the hash per date, however when we build the Placemark, it is done for one
    #set of measurements at a given time, so we loop through each date in the hash and
    # build the placemarks one by one that way.
    foreach my $strPlatformID ( keys %{$rObsHash->{PlatformID}} )
    {     
      foreach my $Date ( keys %{$rObsHash->{PlatformID}{$strPlatformID}{TimeStamp}} ) 
      {        
        KMLAddPlacemarkSimple( $XMLDoc, $DocRoot, $strPlatformID, $Date, $rObsHash );
      }
    }
  }
  # Write the XML data to the file.
  print( $XMLFile $XMLDoc->toString );      
  close( $XMLFile );
}

#######################################################################################################
#Subroutine: KMLAddHeader
# Builds the KMl header, adding the root node, as well as the Document node.
# Parameters:
# 1) $Doc is a valid XML::LibXML::Document->new() object.
# 2) $strName is a string representing the text for the <name> tag.
# Return:
# Returns the $DocumentTag node to work off of.
########################################################################################################
sub KMLAddHeader
{
 my $Doc = shift @_;
 my $DocumentTag = undef;
 my $RootTag = undef;
 if( defined $Doc )
 {
  my $strName = shift @_;
  $RootTag = $Doc->createElement( 'kml');
  $RootTag->setAttribute('xmlns:kml', "http://earth.google.com//kml//2.2" );
  $Doc->setDocumentElement($RootTag);

  $DocumentTag = $Doc->createElement( 'Document');
  $RootTag->appendChild( $DocumentTag );
      
  AddChild( $Doc, $DocumentTag, 'name', $strName );
  AddChild( $Doc, $DocumentTag, 'open', '1' );     
 }
 return( $DocumentTag );
}
########################################################################################################
#Subroutine: KMLAddPlacemarkSimple
#
# Description:
# Adds a placemark with the minimal data set needed.
#Parameters:
# 1. A valid XMLDoc 
# 2. A valid Parent node to build from. Should be the return of the sub KMLAddHeader.
# 3. A string name for the placemark.
# 4. A string description of the placemark.
# 5. A string representing the platform ID.
# 6. A hash with our observations.
########################################################################################################
sub KMLAddPlacemarkSimple  #( $XMLDoc, $ParentTag, $strPlatformID, $Date, $rObsHash );
{
 my $Doc = shift @_;
 if( defined $Doc )
 {
  my $Parent  = shift @_;
  my $strPlatformID = shift @_;
  my $Date    = shift @_;
  my $hObsList= shift @_;
  
  my $Placemark = $Doc->createElement( 'Placemark');
  $Placemark->setAttribute('id', $strPlatformID );

  my $Metadata = $Doc->createElement( 'Metadata');

  #Now add the obsList.  When building the obs list, we only want to give the function a hash that is 
  # for the specific platform and date.
  my $rObsForPlatformDate = $hObsList->{PlatformID}{$strPlatformID}{TimeStamp}{$Date};
  my $strPlatformURL = $hObsList->{PlatformID}{$strPlatformID}{PlatformURL};
  #DWR v1.1.0.0
  #Added the string strDesc to be populated while building the obs list. This will contain an html table that Google Earth
  #can display of the obs/values when we click on a point.
  my $strDesc;
  KMLAddObsList( $Doc, $Metadata, $strPlatformURL, $rObsForPlatformDate, \$strDesc );
  #print( "KMLAddPlacemarkSimple::Desc: $strDesc\n");

  $Placemark->appendChild( $Metadata ); 
  
  my $Latitude =  $hObsList->{PlatformID}{$strPlatformID}{Latitude};       
  my $Longitude =  $hObsList->{PlatformID}{$strPlatformID}{Longitude};       
  KMLAddLatLong( $Doc, $Placemark, $Latitude, $Longitude );
  KMLAddTimeStamp( $Doc, $Placemark, $Date );
  #DWR v1.1.0.0
  KMLAddDescription( $Doc, $Placemark, $strDesc );
  AddChild( $Doc, $Placemark, 'name', $strPlatformID );
  
  $Parent->appendChild( $Placemark );
  return(1);
 }
 return(0);
}
########################################################################################################
# KMLAddLatLong
# Adds the lat and long into the placemark tag.
########################################################################################################

sub KMLAddLatLong #( $Doc, $Parent, $dLat, $dLong )
{
  my ( $Doc, $Parent, $dLat, $dLong ) = @_;
  
  my $Points = $Doc->createElement( 'Point');
  my $strCoords = "$dLong,$dLat";
  AddChild( $Doc, $Points, 'coordinates', $strCoords );  
  $Parent->appendChild( $Points );
}
########################################################################################################
# KMLAddTimeStamp
# Adds the timestamp into the placemark tag.
########################################################################################################
sub KMLAddTimeStamp#( $Doc, $Parent, $strTimeStamp )
{
  my ( $Doc, $Parent, $strTimeStamp ) = @_;
  
  my $TimeStamp = $Doc->createElement( 'TimeStamp');
  AddChild( $Doc, $TimeStamp, 'when', $strTimeStamp );  
  $Parent->appendChild( $TimeStamp );

}
########################################################################################################
# KMLAddDescription
# Adds the timestamp into the placemark tag.
########################################################################################################
sub KMLAddDescription#( $Doc, $Parent, $strDesc )
{
  my ( $Doc, $Parent, $strDesc ) = @_;
  
  my $Desc = $Doc->createElement( 'description'); 
  my $CDATADesc = $Doc->createCDATASection( $strDesc );
  $Desc->appendChild( $CDATADesc );
  $Parent->appendChild( $Desc );
}

########################################################################################################
#KMLAddObsList
# This sub builds the <obsList> tag with all the individual <obs> observations from the platform.
# Parameters
# 1) $Doc is the valid XML document.
# 2) $Parent is the parent node in the XML document we will be adding the children tags to.
# 3) $strPlatformURL is the url for the platform used in the <platformURL> tag.
# 4) $hObsList is a reference to a hash that contains the observation for a specific platform at a specific
#    date. The structure should be:
#     $hObsList{elev}{obsType}{value}
#     $hObsList{elev}{obsType}{uomType}
# 5) $strDescription a reference to a string that will get populated with an HTML table displaying 
#     the observations.
########################################################################################################

sub KMLAddObsList #( $Doc, $Parent, $strPlatformURL, $hObsList, \$strDescription )
{
  my( $Doc, $Parent, $strPlatformURL, $hObsList, $strDescription ) = @_;  #DWR v1.1.0.0 Add description reference.
  
  #Create the obsList parent tag to place the obs under.
  my $ObsList = $Doc->createElement( 'obsList');
  AddChild( $Doc, $ObsList, 'platformURL', $strPlatformURL );
  
  #DWR v1.1.0.0
  #Create the data for the descrition tag.
  $$strDescription = '<table>';
  foreach my $Elev ( reverse sort { $a <=> $b } keys %{$hObsList->{elev}} )  
  {
    #foreach my $ObsType ( sort keys %{$hObsList->{elev}{$Elev}{obsType}} )
    foreach my $SensorSOrder ( sort keys %{$hObsList->{elev}{$Elev}{sorder}} )
    {   
      foreach my $ObsType ( sort keys %{$hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}} )
      {
        #Create the obs child tag.
        my $Obs = $Doc->createElement( 'obs');

        #my $strVal = $hObsList->{elev}{$Elev}{obsType}{$ObsType}{value};
        #my $strUOM = $hObsList->{elev}{$Elev}{obsType}{$ObsType}{uomType};
        #Add all the data for the obs.
        AddChild( $Doc, $Obs, 'obsType', $ObsType );
        
        #DWR v1.2.0.0 Use the sorder as a has key.
        #AddChild( $Doc, $Obs, 'value', $hObsList->{elev}{$Elev}{obsType}{$ObsType}{value} );
        AddChild( $Doc, $Obs, 'value', $hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{value} );        
        #AddChild( $Doc, $Obs, 'uomType', $hObsList->{elev}{$Elev}{obsType}{$ObsType}{uomType} );
        AddChild( $Doc, $Obs, 'uomType', $hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{uomType} );
        AddChild( $Doc, $Obs, 'elev', $Elev );
        #DWR v1.2.0.0 Use the sorder as a has key.
        #AddChild( $Doc, $Obs, 'sorder', $hObsList->{elev}{$Elev}{obsType}{$ObsType}{sorder} );
        AddChild( $Doc, $Obs, 'sorder', $SensorSOrder );
        #DWR v1.2.0.0 Use the sorder as a has key.
        #if( exists $hObsList->{elev}{$Elev}{obsType}{$ObsType}{QCLevel} )
        if( exists $hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{QCLevel} )
        {
          #my $QCLevel = $hObsList->{elev}{$Elev}{obsType}{$ObsType}{QCLevel};
          my $QCLevel = $hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{QCLevel};
          AddChild( $Doc, $Obs, 'QCLevel', $QCLevel );
        }
        #Add the child tag to the parent, ObsList.
        $ObsList->appendChild( $Obs );
        #print( "obsType: $ObsType value: $hObsList->{elev}{$Elev}{obsType}{$ObsType}{value} uomType: $hObsList->{elev}{$Elev}{obsType}{$ObsType}{uomType}\n" );
        #DWR v1.1.0.0
        #Each obs has its own row with the observation type, value, and units of measurement.
        #DWR v1.2.0.0 Use the sorder as a has key.
        $$strDescription = $$strDescription."<tr><td>$ObsType</td><td>$hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{value}</td><td>$hObsList->{elev}{$Elev}{sorder}{$SensorSOrder}{obsType}{$ObsType}{uomType}</td></tr>";
        #print( "KMLAddObsList::strDescription: $$strDescription\n" );
      }
    }
  }
  $$strDescription = $$strDescription.'</table>';
  #print( "KMLAddObsList::Desc: $$strDescription\n");
  
  # Add the ObsList tag with all attached obs to the parent.
  $Parent->appendChild( $ObsList );  
}

########################################################################################################
#Subroutine: AddChild
#
#Parameters:
# 1: XML::LibXML::Document variable This is the valid "newed" document object we are going to work on.
# 2: The createElement parent variable to which we attach the child.
# 3: string representing the name of the element we are going to add.
# 4: string representing the text field we want to add to the element.
#
# Return:
# none 
########################################################################################################
sub AddChild
{
 my $Doc = shift @_;
 my $Parent = shift @_;
 my $Element = shift @_;
 my $Text    = shift @_;
 
 my $ChildEle = $Doc->createElement( $Element );
 $ChildEle->appendText( $Text );
 $Parent->appendChild($ChildEle);

 return;
}
1;