use strict;

use XML::XPath;
use Getopt::Long;
use LWP::Simple;
use DBI;
use DBI::Profile;

#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.

use constant MICROSOFT_PLATFORM => 0;

#1 enables the various debug print statements, 0 turns them off.
use constant USE_DEBUG_PRINTS   => 0;

###path config#############################################

my $DebugLog;
if( USE_DEBUG_PRINTS )
{
  open ( $DebugLog,">QueryPlatformSensorReportTimes.log") || die( "ERROR: Unable to open file: QueryPlatformSensorReportTimes.log");   
}

my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "Environment=s",
            "PlatformID=s",
            "SensorName=s",
            "UpdateInterval=s",
            "StartDate=s",
            "EndDate=s",
            "TimeZone:s");

my $strEnvironment = $CommandLineOptions{"Environment"}; 
my $strPlatformID  = $CommandLineOptions{"PlatformID"}; 
my $strSensorName  = $CommandLineOptions{"SensorName"}; 
my $iUpdateInterval= $CommandLineOptions{"UpdateInterval"}; 
my $strStartDate   = $CommandLineOptions{"StartDate"};
my $strEndDate     = $CommandLineOptions{"EndDate"};
my $strTimeZone    = $CommandLineOptions{"TimeZone"};

if( USE_DEBUG_PRINTS )
{
  print( $DebugLog "Command Line: --Environment=$strEnvironment --PlatformID=$strPlatformID --SensorName=$strSensorName --UpdateInterval=$iUpdateInterval --StartDate=$strStartDate --EndDate=$strEndDate --TimeZone=$strTimeZone \n" );
}

if( length( $strEnvironment ) == 0  ||
    length( $strPlatformID ) == 0   ||
    length( $strSensorName ) == 0   || 
    length( $strStartDate ) == 0    || 
    length( $strEndDate ) == 0   || 
    length( $strTimeZone ) == 0   
  )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --Environment --PlatformID --SensorName --StartDate --EndDate\n". 
              "--Environment\n".
              "--PlatformID .\n".
              "--SensorName \n".
              "--UpdateInterval \n".
              "--StartDate\n".
              "--EndDate\n".
              "--TimeZone\n"
            );
  if( USE_DEBUG_PRINTS )
  {
    print( $DebugLog "ERROR: Command line parameter missing.\n" );
  }
}
#load database and path info
my $env = shift; 
my $xp_env = XML::XPath->new(filename => "environment_xenia_$strEnvironment.xml");

#print DEBUG "$env ";

#load graph info
my $strDBName   = $xp_env->findvalue('//db/name');
#print "db_name: $db_name\n";
my $strDBUser   = $xp_env->findvalue('//db/user');
my $strDBPwd    = $xp_env->findvalue('//db/passwd');
my $strTempDir  = $xp_env->findvalue('//path/dir_tmp');


#Optional command line arguments.


if( length( $strTimeZone ) == 0 )
{
  $strTimeZone = 'EASTERN';
}

#Try and connect to the database.
my $DB = DBI->connect("dbi:SQLite:dbname=$strDBName", "", "",
                      { RaiseError => 1, AutoCommit => 1 });
if(!defined $DB) 
{
  die "ERROR: Cannot connect to database: $strDBName\n";
}
my( $platform_url, $platform_long, $platform_lat,$org_url,$org_name );


my $strHtmlFilename = 'sensorreport'.int(rand(10000000)).'.html';
my $strHtmlFile = $strTempDir.$strHtmlFilename;
open (HTML_FILE,">$strHtmlFile") || die( "ERROR: Unable to open file: $strHtmlFile");

#if you want to reference other time zones, add them here
my %time_zone = ('GMT',0,'EST',-5,'EDT',-4,'CST',-6,'CDT',-5,'MST',-7,'MDT',-6,'PST',-8,'PDT',-7);
#print 'time_zone='.$time_zone{$strTimeZone}."\n";

#daylight savings time consideration
my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);

#correct $strTimeZone depending on whether $isdst is set for EASTERN,etc
if ($strTimeZone eq 'EASTERN') 
{
  if ($isdst) 
  { 
    $strTimeZone = 'EDT';
  } 
  else
  { 
    $strTimeZone = 'EST'; 
  }
}
if ($strTimeZone eq 'CENTRAL')
{
  if ($isdst)
  { 
    $strTimeZone = 'CDT'; 
  } 
  else
  { 
    $strTimeZone = 'CST'; 
  }
}
if ($strTimeZone eq 'MOUNTAIN')
{
  if ($isdst)
  { 
    $strTimeZone = 'MDT';
  }
  else
  {
    $strTimeZone = 'MST'; 
  }
}
if ($strTimeZone eq 'PACIFIC')
{
  if ($isdst)
  { 
    $strTimeZone = 'PDT'; 
  } 
  else
  { 
    $strTimeZone = 'PST'; 
  }
}
#print 'strTimeZone='.$strTimeZone."\n";
#print 'time_zone='.$time_zone{$strTimeZone}."\n";

my $iTimeZoneShift = -1*$time_zone{$strTimeZone};

my $strStartDateRange;
my $strEndDateRange;
$strStartDateRange = $strStartDate.'T00:00:00';
$strEndDateRange = $strEndDate.'T00:00:00';

my %PlatformInfo;
my $PlatformInfoRef = \%PlatformInfo;
GetPlatformInfo( $DB, $strPlatformID, \%PlatformInfo );

my $strHTML = <<"END_OF_FILE";
<title>Query Results</title>
<body>
<form name='details'>
<table bgcolor="#999999" border="0" cellspacing="1" cellpadding="4">
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"><b>Platform</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2"><a href="$PlatformInfoRef->{url}" target="new">$strPlatformID</a></font></td>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
<b>Organization</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2"><a href="$PlatformInfoRef->{organizationurl}" target="new">$PlatformInfoRef->{organization}</a></font></td>
</tr>
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
<b>Lon, Lat</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2">$PlatformInfoRef->{longitude} E, $PlatformInfoRef->{latitude} N</font></td>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
</tr>
</table>
</br>
<table bgcolor="#999999" width="100%" border="0" cellspacing="1" cellpadding="4">
END_OF_FILE

#my $sth_profile = DBI::Profile->new;
#$sth_profile->{Profile} =  4;

#$DB->{Profile} = 4;

my $sensor_id     = QuerySensorID( $DB,$strPlatformID,$strSensorName,1,$strStartDateRange,$strEndDateRange, $iTimeZoneShift);#$DBI,$strPlatform,$strSensorName,$iSOrder,$strStartDate,$strEndDate

#print( "PROFILE: Following data is for QuerySensorID.\n");
#print( $sth_profile->{Profile}->format ); 
#$sth_profile->{Profile}->{Data} = undef;

my $column_value  = 'default';
my $qc_clause     = 'default';
my $output        = 'graph';
my $range_min     = -10000;
my $range_max     = 10000; 
my $title         = 'default';
my $y_title       = 'default';
my $unit_conversion = 'default';
my $size_x          = 'default';
my $size_y          = 'default';

my $strGraphFilename;
if( !MICROSOFT_PLATFORM )
{
  my $strCMD = "cd ./graph ; perl graphSingleLine.pl $strEnvironment time_date \"$strStartDate\" \"$strEndDate\" $sensor_id $column_value \"$qc_clause\" $strTimeZone $output $range_min $range_max \"$title\" $y_title $unit_conversion $iUpdateInterval $size_x $size_y"; 
  $strGraphFilename = `$strCMD` ;
}
else
{
#  my $strCMD = "cd \"C:\\Documents and Settings\\dramage\\workspace\\obsKMLLimits\\processObsKML\\Uptime\\graphlib\" & perl graphSingleLine.pl $strEnvironment time_date \"$strStartDate\" \"$strEndDate\" $sensor_id $column_value \"$qc_clause\" $strTimeZone $output $range_min $range_max \"$title\" $y_title $unit_conversion $iUpdateInterval $size_x $size_y"; 
#  $strGraphFilename = `$strCMD` ;
}

$strHTML .= <<"END_OF_FILE";
<tr><td colspan="4" bgcolor="#ffffff"><img src="/ms_tmp/$strGraphFilename"></td></tr>
END_OF_FILE
my $strData = QuerySensorEntryDates( $DB, $strPlatformID, $sensor_id, 1, $strStartDateRange, $strEndDateRange, $iTimeZoneShift );
#print( "PROFILE: Following data is for QuerySensorEntryDates.\n");
#print( $sth_profile->{Profile}->format ); 
#$sth_profile->{Profile}->{Data} = undef;

$strHTML .= <<"END_OF_FILE";
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"> <b>NetCDF Row Date/Time</b></font></td><td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"> <b>DB Row Entry Date/Time</b></font></td><td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"> <b>$strSensorName</b></font></td>
</tr>
$strData
</table>
</form>
</body>
END_OF_FILE
  
print( HTML_FILE $strHTML );
close (HTML_FILE);

print( $strHtmlFilename );

#$sth_profile->{Profile} = 0; 

#Disconnect database.
$DB->disconnect();

###########################################################

######################################################################################################################
#Subroutine: QuerySensorEntryDates
# Queries the database for a given date range, platform and sensor and returns the html table which contains
# the netcdf date for the row, the database row entry date(when the database inserted the data) and the value at that sample.
# Parameters:
# $DBI connected database object
# $strPlatform is the platform ID we are searching.
# $strSensorName is the observation we are searching for.
# $iSOrder is the sensor order for the given strSensorName we are looking for. Used to distinguish multiple same sensors on a platform.
# $strStartDate the starting date for our query.
# $strEndDate the ending date for our query
# $iTimeZoneShift all data is stored in GMT in the database, this is the shift we apply to move to a different time zone.
######################################################################################################################

sub QuerySensorEntryDates
{
  my ( $DBI,$strPlatform,$iSensorID,$iSOrder,$strStartDate,$strEndDate, $iTimeZoneShift ) = @_;
   
  my $strSQL = "SELECT 
                  multi_obs.row_id,
                  datetime(substr(multi_obs.m_date,1,19),'-$iTimeZoneShift hours'),
                  multi_obs.row_entry_date,
                  multi_obs.m_value 
                FROM sensor
                LEFT JOIN multi_obs on sensor.row_id=multi_obs.sensor_id
                WHERE 
                  sensor.s_order = $iSOrder                                              AND 
                  sensor.row_id = '$iSensorID'                                           AND
                  datetime(m_date) >= datetime('$strStartDate','$iTimeZoneShift hours')  AND 
                  datetime(m_date) < datetime('$strEndDate','$iTimeZoneShift hours')     
                ORDER BY multi_obs.m_date ASC;";
  my $hSt = $DBI->prepare( $strSQL );
  #$sth_profile = $DBI->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( -1 );
  }         
  if( !$hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( -1 );    
  }
  my $strDataTable;
  while( my( $RowID,$NetCDFRowDate,$DBRowEntryDate,$Value ) = $hSt->fetchrow_array() )
  {
    $strDataTable .= "<tr><td>$NetCDFRowDate</td><td>$DBRowEntryDate</td><td>$Value</td></tr>\n";
  }
  $hSt->finish;
  undef $hSt; # to stop "closing dbh with active statement handles"
              # http://rt.cpan.org/Ticket/Display.html?id=22688  
  return( $strDataTable );
}
########################################################################################################################
#QuerySensorID
# For the given platform, sensor name and date range, this sub returns its sensor ID.
# If found, the ID, otherwise -1.
########################################################################################################################

sub QuerySensorID
{
  my ( $DBI,$strPlatform,$strSensorName,$iSOrder,$strStartDate,$strEndDate, $iTimeZoneShift ) = @_;
  
  my $strSQL = "SELECT sensor.row_id
                FROM multi_obs
                LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id
                WHERE  
                  platform_handle = '$strPlatform'                                        AND
                  sensor.short_name = '$strSensorName'                                    AND
                  sensor.s_order = $iSOrder                                               AND
                  datetime(m_date) >= datetime('$strStartDate','$iTimeZoneShift hours')   AND 
                  datetime(m_date) < datetime('$strEndDate','$iTimeZoneShift hours')                       
                ORDER BY sensor.row_id ASC;";
  
  my $hSt = $DBI->prepare( $strSQL );
  #$sth_profile = $DBI->prepare( $strSQL );
  
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( -1 );
  }         
  if( !$hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( -1 );    
  }
  my $iID = -1;
  my @row = $hSt->fetchrow_array();
  if( @row )
  {
    $iID = @row[0];
  }
  
  return( $iID );

}

########################################################################################################################
#GetPlatformInfo
# For the given platform, returns the associated metadata.
# Parameters
# 1. $DB is a DBI database connected to the data source.
# 2. $strPlatformID is a string representing the platform we are looking up.
# Return;
# If found, the URL, otherwise undef.
########################################################################################################################
sub GetPlatformInfo #( $DB, $strPlatformID, \%PlatformInfo )
{
  my( $DB, $strPlatformID, $PlatformInfo ) = @_;
  my $strURL = undef;
  my $strSQL = "SELECT platform.row_id,
                       organization.short_name,organization.url,
                       platform.short_name,platform.fixed_longitude,platform.fixed_latitude,platform.active,platform.url 
                FROM platform 
                LEFT JOIN organization on organization.row_id = platform.organization_id
                WHERE platform_handle = '$strPlatformID';";

  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( $strURL );
  }         
  if( $hSt->execute( ) )
  {
    my @row = $hSt->fetchrow_array;
    my $iNdx = 1;
    %$PlatformInfo->{organization}  = @row[$iNdx++];
    %$PlatformInfo->{organizationurl} = @row[$iNdx++];
    %$PlatformInfo->{short_name}    = @row[$iNdx++];
    %$PlatformInfo->{longitude}     = @row[$iNdx++];
    %$PlatformInfo->{latitude}      = @row[$iNdx++];
    %$PlatformInfo->{active}        = @row[$iNdx++];
    %$PlatformInfo->{url}           = @row[$iNdx++];
  }  
  else
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
  }
}
