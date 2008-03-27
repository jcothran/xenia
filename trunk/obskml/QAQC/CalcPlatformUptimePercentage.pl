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
use constant USE_DEBUG_PRINTS   => 0;

###path config#############################################
my $strDBName     = '';
my $strSQLitePath = '';

#a temporary directory for decompressing, processing files
my $strTempDir;
if( !MICROSOFT_PLATFORM )
{
  $strTempDir = '/tmp/ms_tmp';
  $strDBName     = '/var/www/cgi-bin/microwfs/microwfs.db';
  $strSQLitePath = '/usr/bin/sqlite3-3.5.4.bin';
}
else
{
  $strTempDir = '\\temp\\ms_tmp'; 
  $strDBName     = '\\Program Files\\sqlite-3_5_6\\microwfs\\microwfs.db';
  $strSQLitePath = '\\Program Files\\sqlite-3_5_6';
}
my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "WorkingDir=s",
            "TstProfFeed=s",
            "UpdateDatabase:s",
            "Date:s" );

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
              "--Date specifies the day, in YYYY-MM-DD format, to get the stats for, this is optional and if not provided the default is the last full day( date '1 day ago')\n" );
}
#Optional command line arguments.
my $iUpdateDatabase = 0;
if( uc( $CommandLineOptions{"UpdateDatabase"} ) eq "YES" )
{
  $iUpdateDatabase = 1;
}

my $strDate         = $CommandLineOptions{"Date"};
if( !length( $strDate ) )
{
  if( !MICROSOFT_PLATFORM )
  {
    $strDate = `date --d=\"1 days ago\" +%Y-%m-%d`;
    chomp( $strDate );
  }
  else
  {
    $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe --d=\"1 days ago\" +%Y-%m-%d`;
    chomp( $strDate );   
  }  
}

###########################################################


my $random_value  = int(rand(10000000));
my $strTmpDirName = "gearth_$random_value";
my $target_dir    = '';
my $strTstProfPath = '';
my $SensorFile    = undef;
my $strPercentagesFileName = "PlatformUptimePercentages.csv";
my $SensorHTMLFile    = undef;
my $strPercentagesHTMLFile = "PlatformUptimePercentages.html";

if( !MICROSOFT_PLATFORM )
{
  #create temp working directory
  
  $target_dir = "$strTempDir/$strTmpDirName";
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
}
else
{
  #create temp working directory
  $target_dir = "$strTempDir\\$strTmpDirName";
  `mkdir $target_dir`;
  if( USE_DEBUG_PRINTS )
  {
    print "TargetDir: $target_dir\n";
  }

  $strTstProfPath = "$target_dir\\test_profiles.xml";
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
  open( $SensorFile, ">$strWorkingDir\\$strPercentagesFileName") || die( "ERROR: Unable to open file: $strWorkingDir\\$strPercentagesFileName");      
}

#Try and connect to the database.
my $DB = DBI->connect("dbi:SQLite:dbname=$strDBName", "", "",
                      { RaiseError => 1, AutoCommit => 1 });
if(!defined $DB) 
{
  die "ERROR: Cannot connect to database: $strDBName\n";
}


my $strBeginDateRange = $strDate.'T00:00:00';
my $strEndDateRange   = $strDate.'T24:00:00';

my %PlatformIDs;
my $xp_tests = XML::LibXML->new->parse_file($strTstProfPath);
#Loop through the test_profiles.xml and handle each individual test profile.
foreach my $test_profile ($xp_tests->findnodes('//testProfile'))
{
  my $test_profile_id = sprintf("%s",$test_profile->find('id'));
  if( USE_DEBUG_PRINTS )
  {
   	print( "TestProfileID: $test_profile\n"); 
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
      
      my $strStart = $strDate."T00:00:00";
      my $strEnd   = $strDate."T24:00:00";
      QueryPlatformSensorReportCount( $DB, $strPlatformID, $strStart, $strEnd, $strObsName, $iUpdateInterval, \%PlatformIDs );
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
  `cd $strTempDir; rm -r $strTempDir/$strTmpDirName`  ;
}
else
{
  my $strCmd = "cd $strTempDir & rmdir /S /Q $strTempDir\\$strTmpDirName"; 
  `$strCmd`;
}

########################################################################################################################
# QueryReportingSensorsForPlatform
# Parameters
# 1. $DB is a DBI object which is connected to the database.
# 2. $strPlatform is the platform handle we are querying.
# 3. $strStartDate is a date in YYYY-MM-DDTHH:MM:SS format which is the beginning of the search range.
# 4. $strEndDate is a date in YYYY-MM-DDTHH:MM:SS format which is the end of the search range.
# 5. $SensorIDs is a reference to a hash which will be populated as: key=Sensor ID from sensor.m_type_id column, value=Sensor Name from sensor.short_name column.
########################################################################################################################
sub QueryReportingSensorsForPlatform #( $DB, $strPlatformID, $strStartDate, $strEndDate, \%SensorIDs )
{
  my $DBI           = shift @_;
  my $strPlatform   = shift @_;
  my $strStartDate  = shift @_;
  my $strEndDate    = shift @_;
  my $SensorIDs     = shift @_;
   
  my $strSQL = "SELECT DISTINCT(sensor.m_type_id), sensor.short_name 
                FROM multi_obs
                LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id
                WHERE m_date >= '$strStartDate' AND m_date < '$strEndDate' AND platform_handle = '$strPlatform'
                ORDER BY sensor.row_id ASC;";
  
  my $hSt = $DBI->prepare( $strSQL );
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
  my $iCnt = 0;
  while( my( $SensorID, $strName ) = $hSt->fetchrow_array() )
  {
    %$SensorIDs->{SensorID}{$SensorID}{Name} = $strName;
    $iCnt++;
  }
  return( $iCnt );
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
sub QueryPlatformSensorReportCount #( $DB, $strPlatformID, $strStart, $strEnd, $strSensorName, $iUpdateInterval, \%PlatformIDs )
{
  my ( $DB, $strPlatformID, $strStart, $strEnd, $strSensorName, $iUpdateInterval, $PlatformIDs ) = @_;
     
  #This query will return the number of entries of the sensor type given for the given platform and date range.
  #In other words how many times do we have an entry for that sensor for that platform during that date/time interval.
  my $strSQL = "SELECT COUNT( sensor.m_type_id )
                FROM multi_obs 
                LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id
                WHERE platform_handle = '$strPlatformID' AND m_date >= '$strStart' AND m_date < '$strEnd' AND sensor.short_name = '$strSensorName';";

  my $hSt = $DB->prepare( $strSQL );
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
  my $iCnt = $hSt->fetchrow_array();   
  my $strDay = substr( $strStart, 0, 10);
  %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{Day}{$strDay}{Count} = $iCnt;  
  %$PlatformIDs->{Platform}{$strPlatformID}{Sensor}{$strSensorName}{UpdateInterval} = $iUpdateInterval;
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
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
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
      $fSensorAvg = (( $fSensorAvg / $iDayCnt ) / $iUpdateInterval) * 100.0 ;
      if( $iSensorCnt == 0 )
      {
        $strRow = $strRow.",$PlatformIDs->{Platform}{$strPlatformID}{URL},$strStartDate";        
      }
      if( length( $strRow ) )
      {
        $strRow = $strRow.',';
      } 
      my $strSensorAvg = sprintf( "%.2f",$fSensorAvg );
      $strRow = $strRow."$strSensorAvg";
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
  
  #We have to lookup the sensor id for the platform.
  my $strSQL = "SELECT sensor_id 
                FROM multi_obs
                LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id
                WHERE platform_handle = '$strPlatformID' AND sensor.short_name = '$Sensor'
                LIMIT 1;";

  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( -1 );
  }         
  if(! $hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( -1 );    
  }
  my $strSensorID = $hSt->fetchrow_array();
  if( defined $strSensorID )
  {
    #Now we can update our sensor metrics table.
    #$strDate = $strDate.'T23:59:59';  # Set the time on the date to be the last hour/minute/second of the day since
                                      # the metric is for the day.
    $strSQL = "INSERT INTO metric_sensor_daily
              (app_day,sensor_id,percentage_uptime)
              VALUES('$strDate', $strSensorID, $strSensorAvg);";
              
    $hSt = $DB->prepare( $strSQL );
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
    return( 1 );
  } 
  return( 0 );                 
}

