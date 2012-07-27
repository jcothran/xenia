#####################################################################################################################
# This is a simple sample script demonstrating how to take observation data and use a couple of subroutines to create
# an ObsKML file. The ObsKML file created is a basic, non-stylized, KML file.
# The obsKMLSubRoutines.pm module uses the module XML::LibXML so you need to make sure you have it installed.
# One thiing to note is I do most of my development under windows, so the shell commands I use are ones I grabbed
# to emulate the Unix/Linux variants. If you don't have something similar, you will need
# to grab them.
# You can run it under Linux by setting the MICROSOFT_PLATFORM constant to 0.
#####################################################################################################################
use constant MICROSOFT_PLATFORM => 1;
if( !MICROSOFT_PLATFORM )
{
  use lib "./"; #Linux seems to check the working dir, however I do this just in case.
}
else
{
  use lib ".\\";  #In windows, apparently perl doesn't seem to search your working directory for modules, so I added this to force it to since
                  #I drop the obsKMLSubRoutines.pm into the script directory.
}
use warnings;
use strict;
use obsKMLSubRoutines;  


#The data for the obsKML is stored in a hash, %ObsHash.
my %ObsHash;        
my $rObsHash = \%ObsHash;

#The format we use for platform IDs is: "Institution Code.Platform Name.Platform Type". If it were a water level station, it would be
#"carocoops.SUN3.wls". This is just a standard we adopted internal to USC.
my $strPlatformID = 'carocoops.SUN2.buoy';
my $strPlatformURL = 'http://nautilus.baruch.sc.edu/carocoops_website/buoy_detail.php?buoy=buoy6';
my $Latitude =  33.83;
my $Longitude = -78.48;
#KMLAddPlatformHashEntry( Platform ID String, Platform URL, Latitude, Longitude, Reference to an empty Hash )
#To begin creating the hash for a platform, you must first call the subroutine obsKMLSubRoutines::KMLAddPlatformHashEntry.
obsKMLSubRoutines::KMLAddPlatformHashEntry( $strPlatformID, 
                                            $strPlatformURL, 
                                            $Latitude, 
                                            $Longitude, 
                                            $rObsHash );

#Once we added the platform, we can now start populating the observations. To do so, we call
#obsKMLSubRoutines::KMLAddObsToHash.
my $KMLTimeStamp;
if( !MICROSOFT_PLATFORM )
{
  $KMLTimeStamp = `date --d=\"now\" +%Y-%m-%dT%T`;#KML requires the date to be formatted in a YYYY-MM-DDThh:mm:ss format
}
else
{
  $KMLTimeStamp = `\\UnixUtils\\usr\\local\\wbin\\date.exe --d=\"now\" +%Y-%m-%dT%T`;#KML requires the date to be formatted in a YYYY-MM-DDThh:mm:ss format
}
chomp( $KMLTimeStamp );   

my $DataVal = 0;

my $SensorOrder = 1; #Sensor order is used to seperate multiple same type sensors that are installed on a platform. 
                     #In this example we will have 2 water_temperature sensors on the platform. The one closest to the surface gets a value
                     #of 1, and each deeper sensor will get a value incremented by one. This keeps the observation naming convention clean, 
                     #so we don't end up with 'water_temperature_surface', 'water_temperature_bottom, ect.
                     
my $Height = -2.5;   #This is the relative height of the sensor on the platform. 0 would normally refer to the surface level.

obsKMLSubRoutines::KMLAddObsToHash( 'water_temperature',  #Observation name. 
                                    $KMLTimeStamp,      
                                    $DataVal,           #Data value
                                    $SensorOrder,       #Sensor Order
                                    $strPlatformID,     #Platform ID
                                    $Height,            #Relative height of sensor
                                    'celsius',          #Units of measurement
                                    $rObsHash );        #Observation hash

#Now we add the sea bottom water temperature value.
$SensorOrder = 2; 
$DataVal = 0;
obsKMLSubRoutines::KMLAddObsToHash( 'water_temperature',  #Observation name. 
                                    $KMLTimeStamp,      
                                    $DataVal,           #Data value
                                    $SensorOrder,       #Sensor Order
                                    $strPlatformID,     #Platform ID
                                    $Height,            #Relative height of sensor
                                    'celsius',          #Units of measurement
                                    $rObsHash );        #Observation hash

#Finally we add an air temperature observation.
$SensorOrder = 1; #Note that even though we only have one air temperature sensor, we still set the sensor order to 1.
$DataVal = 26;
obsKMLSubRoutines::KMLAddObsToHash( 'air_temperature',  #Observation name. 
                                    $KMLTimeStamp,      
                                    $DataVal,           #Data value
                                    $SensorOrder,       #Sensor Order
                                    $strPlatformID,     #Platform ID
                                    $Height,            #Relative height of sensor
                                    'celsius',          #Units of measurement
                                    $rObsHash );        #Observation hash
                                    

#Here we create the filename for the KML file we want to create. Then we call the obsKMLSubRoutines::BuildKMLFile subroutine which takes
#our observation hash and 
my $strXMLFilename; 
my $strDate;
if( !MICROSOFT_PLATFORM )
{
  $strDate = `date  +%Y-%m-%dT%H-%M-%S`;
  chomp( $strDate );      
  $strXMLFilename = "./$strPlatformID-$strDate.kml";  #I use the platform ID and a date/time to help more easily ID what/where when browsing the directory.
}
else
{
  $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y-%m-%dT%H-%M-%S`;
  chomp( $strDate );      
  $strXMLFilename = ".\\$strPlatformID-$strDate.kml";  #I use the platform ID and a date/time to help more easily ID what/where when browsing the directory.
}
obsKMLSubRoutines::BuildKMLFile( \%ObsHash, $strXMLFilename );


