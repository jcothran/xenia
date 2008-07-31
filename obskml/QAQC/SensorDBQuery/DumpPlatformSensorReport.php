#######################################################################################################
# This script parses a link to generate the drill down information in the QueryPlatformSensorReportTimes.pl script.
# This script must live in an http: accessible directory. An example of a link this script parses:
# http://nautilus.baruch.sc.edu/~dramage_prod/cgi-bin/DumpPlatformSensorReport.php?PLATFORMID=carocoops.FRP2.buoy&OBSERVATION=current_to_direction&UPDATEINTERVAL=7200&STARTDATE=2008-07-30&ENDDATE=2008-07-31&TIMEZONE=EASTERN
#######################################################################################################

<?

define( "MICROSOFT_PLATFORM", 0 );

$strPlatformID  = $_REQUEST['PLATFORMID'];
$strSensorName  = $_REQUEST['OBSERVATION'];
$iUpdateInterval= $_REQUEST['UPDATEINTERVAL'];
$strStartDate   = $_REQUEST['STARTDATE'];
$strEndDate     = $_REQUEST['ENDDATE'];
$strTimeZone    = $_REQUEST['TIMEZONE'];
$strEnvironment = $_REQUEST['ENVIRONMENT'];


if (empty($strPlatformID)) 
{ 
  echo "ERROR: Missing Required Parameter: PLATFORMID="; 
  exit( 0 );
}
if (empty($strSensorName)) 
{ 
  echo "ERROR: Missing Required Parameter: OBSERVATION="; 
  exit( 0 );
}
if (empty($strStartDate)) 
{ 
  echo "ERROR: Missing Required Parameter: STARTDATE="; 
  exit( 0 );
}
if (empty($strEndDate)) 
{ 
  echo "ERROR: Missing Required Parameter: ENDDATE="; 
  exit( 0 );
}
if (empty($strEnvironment)) 
{ 
  $strEnvironment = 'secoora'; 
}
if (empty($iUpdateInterval)) 
{ 
  $iUpdateInterval = 'default';
}
if (empty($strTimeZone)) 
{ 
  $strTimeZone = 'EASTERN';
}

$strFilename;
if( MICROSOFT_PLATFORM == 0 ) 
{
 $strCMD = "cd /usr2/home/dramage_prod/buoys/perl ; perl QueryPlatformSensorReportTimes.pl".
                " --Environment=$strEnvironment".
                " --PlatformID=$strPlatformID".
                " --SensorName=$strSensorName".
                " --UpdateInterval=$iUpdateInterval".
                " --StartDate=$strStartDate".
                " --EndDate=$strEndDate".
                " --TimeZone=$strTimeZone";
                
                
  #echo $strCMD;
  $strFilename = `$strCMD`;
}
else
{
 $strCMD = "perl QueryPlatformSensorReportTimes.pl ".
                " --Environment=$strEnvironment".
                " --PlatformID=$strPlatformID".
                " --SensorName=$strSensorName".
                " --UpdateInterval=$iUpdateInterval".
                " --StartDate=$strStartDate".
                " --EndDate=$strEndDate".
                " --TimeZone=$strTimeZone";

  $strFilename = `$strCMD`;
}
if( empty( $strFilename ) )
{
  header( "Location: http://carocoops.org/no_data.png" );
}
else
{
  #echo "Location: http://carocoops.org/ms_tmp/$strFilename";
  header( "Location: http://carocoops.org/ms_tmp/$strFilename" );
}


?>
