#######################################################################################################
#Revisions
# Rev: 1.4.0.0
# Author: DWR
# Sub: QueryPlatformSensorReportCount
# Changes: reworked the query to get the sensor count to drastically improve the speed.
# Sub: GetMTypeFromObsType
# Changes: Added the subroutine. Given a platform and observation name, it returns the sensor type. Used in QueryPlatformSensorReportCount
# to help speed up the query. Elimates the need to LEFT JOIN the sensor table.

# Rev: 1.3.0.0
# Author: DWR
# Changes: Fixed the database error handling. On the database connect statement, changed RaiseError to 0 so the errors don't cause us to exit out.
# 
# Sub: AddRecordToDatabase(...)
# Changes: Added retry ability for INSERTS if the database is locked. Added timeout value for database when retrying to keep CPU cycles down.
# 
#Rev: 1.2.0.0
#Author: DWR
#Changes: Added handling of time zones. The data is stamped in GMT in the database, so we want to be able to move the time
# frame to be EST for us east coasters.
# Added command line option -TimeZone to allow for compensation away from GMT.
#
#Sub: TabulatePlatformResults()
#Changes: Added a query URL to allow the ability to drill down on a sensor/platform to see the data for the time period.
#
#Rev: 1.1.0.0
#Author: DWR
#Date: 6/27/2008
#Sub: TabulatePlatformResults()
#Changes: Added the sensor count out of expected interval value in the percentage output.
#######################################################################################################
#######################################################################################################
#This script uses a Test Profile XML file to query each platform's sensors and do a percentage uptime
# calculation. The default output is a csv file, broken down by test profiles as they are defined in the 
# test profile xml file. Optionally(for use in a cron job, once a day) the results can populate a
# metrics table.
# Uses the following command line options:
#  "Command Line format: --WorkingDir --TstProfFeed --UpdateDatabase --Date\n". 
#  "--WorkingDir provides the directory used to store the results file, test_results.csv Should provide a unique name, such as carocoops to denote where the data originated.\n".
#  "--TstProfFeed provides the url where the test_profiles.xml file resides.\n".
#  "--UpdateDatabase specifies if the metrics table in the database is to be updated. Values are \"yes\" to update, or \"no\". This value is optional, default is \"no\" \n".
#  "--Date specifies the day, in YYYY-MM-DD format, to get the stats for, this is optional and if not provided the default is the last full day( date '1 day ago')\n" );
#######################################################################################################
use strict;

use XML::LibXML;
use Getopt::Long;
use LWP::Simple;
use DBI;

#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.

use constant MICROSOFT_PLATFORM => 0;

#1 enables the various debug print statements, 0 turns them off.
use constant USE_DEBUG_PRINTS   => 1;

use constant SECONDS_PER_DAY => ( 24 * 60 * 60 );
###path config#############################################
my %EnvSettings;
my $XMLCfg;

#a temporary directory for decompressing, processing files
=comment
if( !MICROSOFT_PLATFORM )
{
  $EnvSettings{TmpDir} = '/tmp/ms_tmp';
  $strDBName     = '/var/www/cgi-bin/microwfs/microwfs.db';
}
else
{
  $EnvSettings{TmpDir} = '\\temp\\ms_tmp'; 
  $strDBName     = '\\Program Files\\sqlite-3_5_6\\microwfs\\microwfs.db';
}
=cut

my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "WorkingDir=s",
            "TstProfFeed=s",
            "XMLConfigFile=s",
            "UpdateDatabase:s",
            "Date:s", 
            "TimeZone:s"
            );

my $strWorkingDir   = $CommandLineOptions{"WorkingDir"};
my $strTstProfFeed  = $CommandLineOptions{"TstProfFeed"}; 

if( length( $strWorkingDir ) == 0 || 
    length( $strTstProfFeed ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --WorkingDir --TstProfFeed --UpdateDatabase --Date\n". 
              "--WorkingDir provides the directory used to store the results file, test_results.csv Should provide a unique name, such as carocoops to denote where the data originated.\n".
              "--TstProfFeed provides the url where the test_profiles.xml file resides.\n".
              "--UpdateDatabase specifies if the metrics table in the database is to be updated. Values are \"yes\" to update, or \"no\". This value is optional, default is \"no\" \n".
              "--Date specifies the day, in YYYY-MM-DD format, to get the stats for, this is optional and if not provided the default is the last full day( date '1 day ago')\n".
              "--TimeZone optional timezone argument. The data dates in the DB are all in GMT. Options are EASTERN, CENTRAL, MOUNTAIN, PACIFIC. Default is EASTERN.\n".
              "--XMLConfigFile specifies the XML config file\n"
              );
              
}
#Optional command line arguments.
my $iUpdateDatabase = 0;
if( uc( $CommandLineOptions{"UpdateDatabase"} ) eq "YES" )
{
  $iUpdateDatabase = 1;
}

my $strDate         = $CommandLineOptions{"Date"};
#DWR v1.2.0.0
my $strEndDate;
if( !length( $strDate ) )
{
  if( !MICROSOFT_PLATFORM )
  {
    $strDate = `date --d=\"1 days ago\" +%Y-%m-%d`;
    chomp( $strDate );
    
    $strEndDate = `date +%Y-%m-%d`;
    chomp( $strEndDate );
  }
  else
  {
    $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe --d=\"1 days ago\" +%Y-%m-%d`;
    chomp( $strDate );   

    $strEndDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe +%Y-%m-%d`;
    chomp( $strEndDate );
  }  
}
my $strTimeZone = $CommandLineOptions{"TimeZone"};
if( length( $strTimeZone ) == 0 )
{
  $strTimeZone = 'EASTERN';
}

my $XMLConfigFile = $CommandLineOptions{"XMLConfigFile"};
if( length( $XMLConfigFile ) == 0 )
{
  die( "ERROR: No XMl configuration file provided, cannot continue.\n");
}

$XMLCfg = XML::LibXML->new->parse_file($XMLConfigFile);     
print( "Successfully opened config file: $XMLConfigFile\n" );

$EnvSettings{DBType}=$XMLCfg->findvalue('//DB/type');
if( $EnvSettings{DBType} eq 'sqlite' )
{
  $EnvSettings{DBName}=$XMLCfg->findvalue('//DB/name');
}
else
{
  $EnvSettings{DBName}=$XMLCfg->findvalue('//DB/name');
  $EnvSettings{DBUser}=$XMLCfg->findvalue('//DB/user');
  $EnvSettings{DBPwd}=$XMLCfg->findvalue('//DB/pwd');
}
$EnvSettings{TmpDir}=$XMLCfg->findvalue('//Settings/tmpdir');
$EnvSettings{SensorPlotPHP}=$XMLCfg->findvalue('//Settings/sensorplotphp');

###########################################################


my $random_value  = int(rand(10000000));
my $strTmpDirName = "gearth_$random_value";
my $target_dir    = '';
my $strTstProfPath = '';
my $SensorFile    = undef;
my $strPercentagesFileName = "PlatformUptimePercentages.csv";
my $SensorHTMLFile    = undef;
my $strPercentagesHTMLFile = "PlatformUptimePercentages.html";

#create temp working directory
$target_dir = "$EnvSettings{TmpDir}/$strTmpDirName";
`mkdir $target_dir`;
if( USE_DEBUG_PRINTS )
{
  print "TargetDir: $target_dir\n";
}
##################
#read input files to temp directory
################## 
$strTstProfPath = "$target_dir/test_profiles.xml";
if( USE_DEBUG_PRINTS )
{
  print "TstProfFeed: $strTstProfFeed\n";
}
my $RetCode = getstore( "$strTstProfFeed", $strTstProfPath );
if( USE_DEBUG_PRINTS )
{
  if( is_success($RetCode) )
  {
    print( "Success($strTstProfFeed): getstore return code: $RetCode.\n");
  }
  else
  {
    print( "Error($strTstProfFeed): getstore return code: $RetCode.\n");   
  }
} 
open( $SensorFile, ">$strWorkingDir/$strPercentagesFileName") || die( "ERROR: Unable to open file: $strWorkingDir/$strPercentagesFileName");

#Try and connect to the database.
my $DB;
if( $EnvSettings{DBType} eq 'sqlite' )
{
  my $strDBName = $EnvSettings{DBName};
  $DB = DBI->connect("dbi:SQLite:dbname=$strDBName", "", "",
                        { RaiseError => 0, AutoCommit => 1 });
  if(!defined $DB) 
  {
    die "ERROR: Cannot connect to database: $strDBName\n";
  }
}
else
{
  $DB = DBI->connect ("dbi:Pg:dbname=$EnvSettings{DBName}","$EnvSettings{DBUser}","$EnvSettings{DBPwd}");
  if (!(defined $DB))
  {
    die "Cannot connect to database: $EnvSettings{DBName}\n";
  }
}

#########################################################################################################
#DWR v1.2.0.0
#Add support for time zone handling.

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
my $iTimeZoneShift = -1*$time_zone{$strTimeZone};

#########################################################################################################

my %PlatformIDs;
my $xp_tests = XML::LibXML->new->parse_file($strTstProfPath);
#Loop through the test_profiles.xml and handle each individual test profile.
foreach my $test_profile ($xp_tests->findnodes('//testProfile'))
{
  my $test_profile_id = sprintf("%s",$test_profile->find('id'));
  if( USE_DEBUG_PRINTS )
  {
   	print( "TestProfileID: $test_profile_id\n"); 
  }
  my %SensorIDs;
   
  foreach my $platform_id ($test_profile->findnodes('platformList/platform')) 
  {
    my $strPlatformID = $platform_id->string_value();
	  foreach my $obs ($test_profile->findnodes('obsList/obs'))
  	{
  	  #Obs is formated: ObsType.UnitOfMeasurement.
  	  my $strObsHandle = sprintf("%s",$obs->find('obsHandle') );
  		my ($strObsName, $strUOM) = split( /\./, $strObsHandle );

      #Get the interval that the sensor sends updates.
  		my $iUpdateInterval = sprintf( "%d", $obs->find('UpdateInterval') );
      
      my $strStart = $strDate.'T00:00:00';
      my $strEnd   = $strEndDate.'T00:00:00';
      #DWR v1.2.0.0
      #Added $iTimeZoneShift to compensate for time zones. Measurements in the DB are all stored in GMT.
      QueryPlatformSensorReportCount( $DB, $strPlatformID, $strStart, $strEnd, $strObsName, $iUpdateInterval, \%PlatformIDs, $iTimeZoneShift );
    }#obstypes
    #PlotPlatformResults( $DB, $strPlatformID, \%PlatformIDs, $strWorkingDir );
    my $strURL = GetPlatformURL( $DB, $strPlatformID );
    %PlatformIDs->{Platform}{$strPlatformID}{URL} = $strURL;
    
  }#platform 
  TabulatePlatformResults( $SensorFile, \%PlatformIDs, $iUpdateDatabase );
  
  %PlatformIDs = ();
}#testprofiles


#Disconnect database.
$DB->disconnect();
#Close stats file
close( $SensorFile );
#Clean up the temp directory
if( !MICROSOFT_PLATFORM )
{
  `cd $EnvSettings{TmpDir}; rm -r $EnvSettings{TmpDir}/$strTmpDirName`  ;
}
else
{
  my $strCmd = "cd $EnvSettings{TmpDir} & rmdir /S /Q $EnvSettings{TmpDir}\\$strTmpDirName"; 
  `$strCmd`;
}

########################################################################################################################
# QueryPlatformSensorReportCount
# Parameters
# 1. $DB is a DBI object which is connected to the database.
# 2. $strPlatform is the platform handle we are querying.
# 3. $strStartDate is a date in YYYY-MM-DDTHH:MM:SS format which is the beginning of the search range.
# 4. $strEndDate is a date in YYYY-MM-DDTHH:MM:SS format which is the end of the search range.
# 5. $strSensorName is a string representing the sensor we are looking up.
# 6. $PlatformInfo is a reference to a hash which will be populated with per platform/sensor information.
########################################################################################################################
sub QueryPlatformSensorReportCount #( $DB, $strPlatformID, $strStart, $strEnd, $strSensorName, $iUpdateInterval, \%PlatformIDs, $iTimeZoneShift )
{
  my ( $DB, $strPlatformID, $strStart, $strEnd, $strSensorName, $iUpdateInterval, $PlatformIDs,$iTimeZoneShift ) = @_;
  my $iCnt      = -1;
  
  #This query will return the number of entries of the sensor type given for the given platform and date range.
  #In other words how many times do we have an entry for that sensor for that platform during that date/time interval.
  # m_date >= '$strStart' AND m_date < '$strEnd'      AND 
  #$strPlatformID = 'usf.C14.IMET';

  #DWR v1.3.0.0
  #Query the m_type_id to alleviate the need below to JOIN on the sensor table.
  my $iType = GetMTypeFromObsType ( $DB, $strSensorName, $strPlatformID, 1);#($dbh, $strObsName, $strPlatformHandle, $iSOrder )
  if( defined( $iType ) )
  {
    #DWR v1.2.0.0
    #Added time zone adjustment into WHERE clause for start/end date range.
    #DWR v1.3.0.0
    #Reworked the SQL query for speed. Dropped the join the the sensor table since we are now
    #looking up the sensor m_type_id above.
    my $strSQL;
    if( $EnvSettings{DBType} eq 'sqlite' )
    {
      $strSQL = "SELECT COUNT( m_type_id )
                    FROM multi_obs 
                    WHERE  
                      multi_obs.m_type_id = $iType                              AND 
                      m_date >= strftime( '%Y-%m-%dT%H:00:00',datetime('$strStart','$iTimeZoneShift hours') )   AND  
                      m_date < strftime( '%Y-%m-%dT%H:00:00', datetime('$strEnd','$iTimeZoneShift hours') )     AND      
                      platform_handle = '$strPlatformID';";                
    }
    else
    {
      $strSQL = "SELECT COUNT( m_type_id )
                    FROM multi_obs 
                    WHERE  
                      multi_obs.m_type_id = $iType                              AND 
                      m_date >= ( timestamp '$strStart' - interval '$iTimeZoneShift hours' )   AND  
                      m_date < ( timestamp '$strEnd' - interval '$iTimeZoneShift hours' )      AND      
                      platform_handle = '$strPlatformID';";                
    }
    
    my $hSt       = $DB->prepare( $strSQL );
    #print( "$strSQL\n" );
    if( defined $hSt )
    {
      if( $hSt->execute( ) )
      {
        $iCnt = $hSt->fetchrow_array();   
        my $strDay = substr( $strStart, 0, 10);
        %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{Day}{$strDay}{Count} = $iCnt;  
        %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{UpdateInterval} = $iUpdateInterval;
      }
      else
      {
        my $strErr = $hSt->errstr;
        print( "QueryPlatformSensorReportCount::ERROR: Failed execute: $strErr\n SQLStatement: $strSQL\n");    
      }
    }
    else
    {
      print( "QueryPlatformSensorReportCount::ERROR: Unable to prepare SQL statement: $strSQL.\n");
    }
  }
  #No m_type_id for the sensor on the platform. We'll create a placeholder and give a count of 0.
  else
  {
    my $strDay = substr( $strStart, 0, 10);
    %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{Day}{$strDay}{Count} = 0;  
    %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{UpdateInterval} = $iUpdateInterval;    
  }    
  return( $iCnt );

}

########################################################################################################################
#GetPlatformURL
# For the given platform, this sub returns its URL.
# Parameters
# 1. $DB is a DBI database connected to the data source.
# 2. $strPlatformID is a string representing the platform we are looking up.
# Return;
# If found, the URL, otherwise undef.
########################################################################################################################
sub GetPlatformURL #( $DB, $strPlatformID)
{
  my( $DB, $strPlatformID ) = @_;
  my $strURL = undef;
  my $strSQL = "SELECT url 
                FROM platform 
                WHERE platform_handle = '$strPlatformID';";

  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( $strURL );
  }         
  if( $hSt->execute( ) )
  {
    $strURL = $hSt->fetchrow_array(); 
  }
  else
  {
    my $strErr = $hSt->errstr;
    print( "ERROR: Failed execute: $strErr\n SQLStatement: $strSQL\n");    
  }
  return( $strURL );
}
########################################################################################################################
# PlotPlatformResults
# Parameters
# 1. $DB is a DBI object which is connected to the database.
# 2. $strPlatform is the platform handle we are querying.
########################################################################################################################

sub PlotPlatformResults #( $DB, $strPlatformID, \%PlatformIDs, $strWorkingDir )
{
  my( $DB, $strPlatformID, $PlatformIDs, $strWorkingDir ) = @_; 
  
  my $iXTicNdx    = 1;
  my $strXTicLabels;

  my $SensorFile    = undef;
  my $strFileName; 
  if( !MICROSOFT_PLATFORM )
  {
    $strFileName = "$strPlatformID";
    open( $SensorFile, ">$strWorkingDir/$strFileName") || die( "ERROR: Unable to open file: $strWorkingDir/$strFileName");
  }
  else
  {
    $strFileName = "$strPlatformID";
    open( $SensorFile, ">$strWorkingDir\\$strFileName") || die( "ERROR: Unable to open file: $strWorkingDir\\$strFileName");      
  }

  foreach my $Sensor ( sort keys %{$PlatformIDs->{Platform}{$strPlatformID}{Sensor}} )
  {    
    my $fSensorAvg  = 0;
    my $iMaxCnt     = 0;
    # Build the XTics labels for use in gnuplot.
    if( length($strXTicLabels) )
    {
      $strXTicLabels = $strXTicLabels.',';
    }
    $strXTicLabels = $strXTicLabels."\"$Sensor\" $iXTicNdx";
    
    my $iDayCnt = 0;
    foreach my $strDay ( keys %{$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}} )
    {
      if( %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count} > $iMaxCnt )
      {
        $iMaxCnt = %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count};
      }
      $fSensorAvg += %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count};
      $iDayCnt++;
    }
    #Protect from divide by 0.
    if( $iMaxCnt == 0 )
    {
      $iMaxCnt = 1;
    }
    if( $iDayCnt == 0 )
    {
      $iDayCnt = 1;
    }
    my $iUpdateInterval = %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{UpdateInterval};
    if( $iUpdateInterval < $iMaxCnt )
    {
      print( "WARNING: Sensor: %s has $iMaxCnt updates when the specified update interval is $iUpdateInterval.\n");
    }
    $fSensorAvg = (( $fSensorAvg / $iDayCnt ) / $iUpdateInterval) * 100.0 ;
    print( $SensorFile "$iXTicNdx,$fSensorAvg\n");
    
    $iXTicNdx++;
  }
  close( $SensorFile );
  
  my $strTitle = "$strPlatformID Sensor % Uptime for 3 day period";
  my $SizeX = 600;
  my $SizeY = 300;
  Graph( $strFileName, $strTitle, "Percentage", $strWorkingDir, $SizeX, $SizeY, $strXTicLabels );
}


sub Graph
{
  my ($strGraphDataFile, $strTitle, $YUnits,  $strWorkingDir, $SizeX, $SizeY, $strXTicLabels) = @_;
  
  if (!($SizeX)) { $SizeX = 600; }
  if (!($SizeY)) { $SizeY = 300; }
  
  $SizeX = $SizeX*0.001562499;
  $SizeY = $SizeY*0.00205;
  
  if( !MICROSOFT_PLATFORM )
  {
    open (SCRIPT,">$strWorkingDir/$strGraphDataFile.script") || die( "ERROR: Unable to open file: $strWorkingDir/$strGraphDataFile.script");
  }
  else
  {
    open (SCRIPT,">$strWorkingDir\\$strGraphDataFile.script") || die( "ERROR: Unable to open file: $strWorkingDir\\$strGraphDataFile.script");
  }
  
  print SCRIPT "
  set terminal png
  set output \"$strGraphDataFile.png\"
  #640x480 default
  set bmargin 5
  set lmargin 10
  set tmargin 2
  set rmargin 1
  set style data boxes
  set style fill  solid
  set boxwidth 0.5 absolute
  set size $SizeX,$SizeY
  set title \"$strTitle\" font \"Arial,8\"
  set yrange[0:100]
  set ylabel \"$YUnits\" font \"Arial,8\" offset 2,0
  set ytics font \"Arial,6\"
  
  set xlabel \"Sensors\" font \"Arial,8\" offset 0,0
  set xtics border in scale 1,0.5 nomirror rotate by -45  
  set xtics font \"Arial,6\"
  set xtics ($strXTicLabels)
  set grid
  unset key
  
  plot \"$strGraphDataFile\" using 1:2 \"%lf,%lf\" 
  
  reset
  quit";
  close SCRIPT;
  
  if( !MICROSOFT_PLATFORM )
  {
    `gnuplot $strGraphDataFile.script`;
  }
  else
  {
    `cd $strWorkingDir & "\\Program Files\\gnuplot\\gnuplot\\bin\\wgnuplot.exe" $strGraphDataFile.script`;
  }  
}
########################################################################################################################
# TabulatePlatformResults
# Parameters
# 1. $SensorFile is the csv file we are writing our results into.
# 2. %PlatformIDs is a hash reference with our platform/sensor data we are calcing the percentages on.
# 3. $iUpdateDatabase is a flag which if non zero specifies we insert the data into the metric_sensor_daily table.
########################################################################################################################

sub TabulatePlatformResults #( $SensorFile, \%PlatformIDs, $iUpdateDatabase );
{
  
  my( $SensorFile, $PlatformIDs, $iUpdateDatabase ) = @_;
  
  my $iRowCnt = 0;
  my $strHeader;
  my %SensorAvgs;
  foreach my $strPlatformID ( keys %{$PlatformIDs->{Platform}} )
  {
    my $strRow;
    if( $iRowCnt == 0 )
    {
      $strHeader = 'PlatformID,URL,Date';  
    } 
    $strRow    = $strPlatformID;     
    my $strStartDate;
    my $iSensorCnt = 0;
    foreach my $Sensor ( sort keys %{$PlatformIDs->{Platform}{$strPlatformID}{Sensor}} )
    {    
      my $fSensorAvg  = 0;
      my $iMaxCnt     = 0;

      #DWR v1.2.0.0
      #Build link to query data for sensor
      #my $strURL = 'http://nautilus.baruch.sc.edu/~dramage_prod/cgi-bin/DumpPlatformSensorReport.php?';
      my $strURL = $EnvSettings{SensorPlotPHP};
      # If the ENVIRONMENT string is specified in the URL, we need to add the & seperator.
      if( rindex( $strURL, 'ENVIRONMENT' ) != -1 )
      {
        $strURL .= '&';
      }
      
      if( $iRowCnt == 0 )
      {
        if( length( $strHeader) )
        {
          $strHeader = $strHeader.',';
        }
        $strHeader = $strHeader."$Sensor-UpdateInterval %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{UpdateInterval}";
      }      
      my $iDayCnt = 0;
      foreach my $strDay ( keys %{$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}} )
      {
        if( $iSensorCnt == 0 )
        {
          $strStartDate = $strDay;
        }
        if( %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count} > $iMaxCnt )
        {
          $iMaxCnt = %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count};
        }
        $fSensorAvg += %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{Day}{$strDay}{Count};
        $iDayCnt++;
      }
      #Protect from divide by 0.
      if( $iMaxCnt == 0 )
      {
        $iMaxCnt = 1;
      }
      if( $iDayCnt == 0 )
      {
        $iDayCnt = 1;
      }
      my $iUpdateInterval = %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$Sensor}{UpdateInterval};
      if( $iUpdateInterval < $iMaxCnt )
      {
        print( "WARNING: Platform: $strPlatformID Sensor: $Sensor has $iMaxCnt updates when the specified update interval is $iUpdateInterval.\n");
      }
      #DWR v1.1.0.0
      my $fAvg = $fSensorAvg / $iDayCnt;
      if( $iUpdateInterval == 0 )
      {
        $iUpdateInterval = 1;
      }
      $fSensorAvg = ($fAvg / $iUpdateInterval) * 100.0 ;
      if( $iSensorCnt == 0 )
      {
        $strRow = $strRow.",$PlatformIDs->{Platform}{$strPlatformID}{URL},$strStartDate";        
      }
      if( length( $strRow ) )
      {
        $strRow = $strRow.',';
      } 
      #DWR v1.2.0.0
      #Build the url for our drill down into the database for this platform/sensor data.
      my $iUpdatesInSeconds = SECONDS_PER_DAY / $iUpdateInterval;
      $strURL .= "PLATFORMID=$strPlatformID&OBSERVATION=$Sensor&UPDATEINTERVAL=$iUpdatesInSeconds&STARTDATE=$strDate&ENDDATE=$strEndDate&TIMEZONE=EASTERN";
      my $strSensorAvg = sprintf( "%.2f",$fSensorAvg );
      $strRow = $strRow."$strSensorAvg($fAvg/$iUpdateInterval);$strURL";
      
      if( $iUpdateDatabase )
      {
        AddRecordToDatabase( $DB, $strPlatformID, $Sensor, $strSensorAvg, $strStartDate );
      }
      
      $iSensorCnt++;
    }#foreach sensor
    #First row, let's print a column header.
    if( $iRowCnt == 0 )
    {
      print( $SensorFile "$strHeader\n" );     
    }
    $iRowCnt++;
    print( $SensorFile "$strRow\n" );
  }#foreach platformid
}


sub AddRecordToDatabase #( $DB, $strPlatformID, $Sensor, $strSensorAvg, $strDate )
{
  my ( $DB, $strPlatformID, $Sensor, $strSensorAvg, $strDate ) = @_;
  
  
  # DWR v1.3.0.0
  # Set the timout value to 2 seconds. This is applicable to the execute statement if the database is locked for instance, we'll wait 2 seconds
  # waiting on the lock before we give up.
  $DB->func( 2000, 'busy_timeout' );

  #We have to lookup the sensor id for the platform.
  my $strSQL = "SELECT sensor_id 
                FROM multi_obs
                LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id
                WHERE platform_handle = '$strPlatformID' AND sensor.short_name = '$Sensor'
                LIMIT 1;";

  my $iSuccess  = 0;
  my $iRetry    = 0;
  my $strSensorID;
  my $hSt = $DB->prepare( $strSQL );
  if( defined $hSt )
  {
    if( $hSt->execute( ) )
    {
      $strSensorID = $hSt->fetchrow_array();
    }
    else
    {
      my $strErr = $hSt->errstr;
      print( "AddRecordToDatabase::ERROR: Failed execute: $strErr\n SQLStatement: $strSQL\n");    
      return( -1 );
    }
  }  
  else
  {
    print( "AddRecordToDatabase::ERROR: Unable to prepare SQL statement: $strSQL.\n");
    return( -1 );
  }         

  $iSuccess  = 0;
  $iRetry    = 0;
  
  if( defined $strSensorID )
  {
    #Now we can update our sensor metrics table.
    #$strDate = $strDate.'T23:59:59';  # Set the time on the date to be the last hour/minute/second of the day since
                                      # the metric is for the day.
    $strSQL = "INSERT INTO metric_sensor_daily
              (app_day,sensor_id,percentage_uptime)
              VALUES('$strDate', $strSensorID, $strSensorAvg);";
              
    #DWR v1.3.0.0
    # Added retry capability if the database is locked.
    while( !$iSuccess )
    {
      $hSt = $DB->prepare( $strSQL );
      if( defined $hSt )
      {
        if( $hSt->execute( ) )
        {
          return( 1 );
        }
        else
        {
          my $strErr = $hSt->errstr;
          if( $strErr =~ 'locked' )
          {
            print( "AddRecordToDatabase::ERROR: Failed execute: $strErr\n SQLStatement: $strSQL\n Retry Attempt: $iRetry\n");    
          }
          else
          {
            print( "AddRecordToDatabase::ERROR: Failed execute: $strErr\n SQLStatement: $strSQL\n");    
            return( -1 );
          }
        }
      }
      else
      {
        print( "AddRecordToDatabase::ERROR: Unable to prepare SQL statement: $strSQL.\n DBI::errstr()\n");
        return( -1 );
      }      
      $hSt->finish();
      undef $hSt;
      
      $iRetry++;
    }      
  } 
  return( 0 );                 
}

sub GetMTypeFromObsType
{
  my ($dbh, $strObsName, $strPlatformHandle, $iSOrder ) = @_;
  
  my $strSOrder = '';
  if( defined $iSOrder )
  {
    $strSOrder = "sensor.s_order = $iSOrder AND";
  }
  my $strSQL = "SELECT DISTINCT(sensor.m_type_id) FROM m_type, m_scalar_type, obs_type, sensor, platform
                WHERE  sensor.m_type_id = m_type.row_id AND
                m_scalar_type.row_id = m_type.m_scalar_type_id AND
                obs_type.row_id = m_scalar_type.obs_type_id AND
                platform.row_id = sensor.platform_id AND
                $strSOrder
                obs_type.standard_name = '$strObsName' AND
                platform.platform_handle = '$strPlatformHandle';";
  #print( "GetMTypeFromObsType SQL: $strSQL\n" ) ;
  my $iMType = -1;
  my $sth = $dbh->prepare( $strSQL );
  if( defined $sth )
  {
    if( $sth->execute() )
    {      
      $iMType = $sth->fetchrow_array();
    }
    else
    {
      my $strErr = $sth->errstr;
      print( "ERROR::$strErr\n");
    }
  }
  else
  {
    print( "ERROR::Unable to prepare SQL statement: $strSQL\n");
  } 
  $sth->finish();
  return( $iMType );
}