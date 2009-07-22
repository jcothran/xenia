<?php

#$_REQUEST['PLATFORMID']     = $argv[1];
#$_REQUEST['OBSERVATION']    = $argv[2];
#$_REQUEST['UPDATEINTERVAL'] = $argv[3];
#$_REQUEST['STARTDATE']      = $argv[4];
#_REQUEST['ENDDATE']        = $argv[5];
#_REQUEST['TIMEZONE']       = $argv[6];
#$_REQUEST['ENVIRONMENT']    = $argv[7];


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
$strCMD = "cd /var/myscheduler/flowmonitor ; perl QueryPlatformSensorReportTimes.pl".
              " --Environment=$strEnvironment".
              " --PlatformID=$strPlatformID".
              " --SensorName=$strSensorName".
              " --UpdateInterval=$iUpdateInterval".
              " --StartDate=$strStartDate".
              " --EndDate=$strEndDate".
              " --TimeZone=$strTimeZone";
                
                
#echo $strCMD;
$strFilename = `$strCMD`;
if( empty( $strFilename ) )
{
  header( "Location: http://carocoops.org/no_data.png" );
}
else
{
  #echo "Location: http://carocoops.org/ms_tmp/$strFilename";
  header( "Location: http://152.20.240.19/tmp/diags/$strFilename" );
}


?>
