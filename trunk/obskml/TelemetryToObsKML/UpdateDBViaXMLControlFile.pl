use warnings;
use strict;
use DBI;
use Getopt::Long;
use LWP::Simple;
use XML::LibXML;

use constant MICROSOFT_PLATFORM => 1;
use constant DEBUG_PRINT_SQL    => 1;

my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "Database=s",
            "ControlFile=s" );

my $strDBName       = $CommandLineOptions{"Database"};
my $strControlFile  = $CommandLineOptions{"ControlFile"}; 

if( length( $strDBName ) == 0 || 
    length( $strControlFile ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --Database --$strControlFile\n". 
              "--Database provides the SQLite database to be used.\n".
              "--ControlFile provides the XML file to be used to update the database.\n" );
}

#Try and connect to the database.
my $DB = DBI->connect("dbi:SQLite:dbname=$strDBName", "", "",
                      { RaiseError => 1, AutoCommit => 1 });
if(!defined $DB) 
{
  die "ERROR: Cannot connect to database: $strDBName\n";
}

my %PlatformHash;
#LoadPlatformControlFile( $DB, $strControlFile, \%PlatformHash );
UpdateDBFromControlFile( $DB, $strControlFile );

;
sub UpdateDBFromControlFile#( $DB, $strControlFile )
{
  my( $DB, $strControlFileName ) = @_;
  
  my $strSQL;
  my $XMLControlFile = XML::LibXML->new->parse_file($strControlFileName);
  if( defined $XMLControlFile )
  { 
    foreach my $ControlSet ($XMLControlFile->findnodes('//ControlSet'))
    {
      my $strID = sprintf("%s", $ControlSet->find('id') );
      foreach my $Platform ($ControlSet->findnodes('PlatformList/Platform'))
      {
        my $strTelemetryID = sprintf("%s",$Platform->find('TelemetryID'));
        my $strBuoyOldName = sprintf("%s",$Platform->find('PlatformOldName'));
        my $strPlatform = sprintf("%s",$Platform->find('PlatformID'));       
        my $strPlatformURL = sprintf("%s",$Platform->find('PlatformURL'));
                    
        #Now let's get the observations for the platform.
        foreach my $obs ($ControlSet->findnodes('ObsList/Obs'))
        {
          my $strobsHandle= sprintf("%s", $obs->find('ObsHandle') );
          my $strElev     = sprintf("%s", $obs->find('Elev') );
          my $strSorder   = sprintf("%s", $obs->find('SOrder') );
          my $strSensorID = GetPlatformSensorID( $DB, $strobsHandle, $strPlatform, $strElev, $strSorder );
          #If the sensor does not exist, then we need to add it.
          if( $strSensorID eq '' )
          {
            # Check to see if the sensor exists, but doesn't have the fixed_z. 
            $strSensorID = GetPlatformSensorID( $DB, $strobsHandle, $strPlatform, '', $strSorder );
            if( $strSensorID eq '' )
            {
              #Add the sensor.
              AddSensorToPlatform( $DB, $strobsHandle, $strPlatform, $strElev, $strSorder );           
            }
            else
            {
              $strSQL = "UPDATE sensor
                        SET fixed_z = $strElev, s_order = $strSorder
                        WHERE row_id = '$strSensorID'";
              if( DEBUG_PRINT_SQL )
              {
                print( "$strSQL\n");
              }                    
              my $hSt = $DB->prepare( $strSQL );
              if( !defined $hSt )
              {
                print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
              }         
              if(! $hSt->execute( ) )
              {
                print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
              }                              
            }                                            
          }
          #Only the ADCPs should have the bin cell tags. 
          my $strBinDepth = sprintf("%s", $obs->find('BinCellSize') );
        }
      }
    }
    return( 1 );
  }
  return( 0 );  
}
=comment
#######################################################################################################
# LoadPlatformControlFile
#######################################################################################################
sub LoadPlatformControlFile
{
  my( $DB, $strControlFileName, $rPlatformHash ) = @_;
  
  my $strSQL;
  my $XMLControlFile = XML::LibXML->new->parse_file($strControlFileName);
  if( defined $XMLControlFile )
  { 
    foreach my $ControlSet ($XMLControlFile->findnodes('//ControlSet'))
    {
      my $strID = sprintf("%s", $ControlSet->find('id') );
      foreach my $Platform ($ControlSet->findnodes('PlatformList/Platform'))
      {
        my $strTelemetryID = sprintf("%s",$Platform->find('TelemetryID'));
        my $strBuoyOldName = sprintf("%s",$Platform->find('PlatformOldName'));
        my $strPlatformID = sprintf("%s",$Platform->find('PlatformID'));       
        my $strPlatformURL = sprintf("%s",$Platform->find('PlatformURL'));
             
        #$rPlatformHash->{ControlSet}{$strID}{PlatformID}{$strPlatformID}{TelemetryID} = $strTelemetryID;
        #$rPlatformHash->{ControlSet}{$strID}{PlatformID}{$strPlatformID}{BuoyOldName} = $strBuoyOldName;
        #$rPlatformHash->{ControlSet}{$strID}{PlatformID}{$strPlatformID}{PlatformURL} = $strPlatformURL;
        
        #Now let's get the observations for the platform.
        foreach my $obs ($ControlSet->findnodes('ObsList/Obs'))
        {
          my $strobsHandle= sprintf("%s", $obs->find('ObsHandle') );
          my $strElev     = sprintf("%s", $obs->find('Elev') );
          my $strSorder   = sprintf("%s", $obs->find('SOrder') );
          #%$rPlatformHash->{ControlSet}{$strID}{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{elev} = $strElev;
          #$rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{elev} = $strElev;
          #$rPlatformHash->{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{elev} = 1;
          #Only the ADCPs should have the bin cell tags. 
          my $strBinDepth = sprintf("%s", $obs->find('BinCellSize') );
          #%$rPlatformHash->{ControlSet}{$strID}{PlatformID}{$strPlatformID}{sorder}{$strSorder}{obsHandle}{$strobsHandle}{BinDepth} = $strBinDepth; 
        }
      }
    }
#=comment    
    foreach my $ID ( keys %{$rPlatformHash->{ControlSet}} )
    {
      foreach my $Platform ( keys %{$rPlatformHash->{ControlSet}{$ID}{PlatformID}} )
      {
        my $strURL = $rPlatformHash->{ControlSet}{$ID}{PlatformID}{$Platform}{PlatformURL}; 
        my $strTelemetryID = $rPlatformHash->{ControlSet}{$ID}{PlatformID}{$Platform}{TelemetryID};
        my $strOldName = $rPlatformHash->{ControlSet}{$ID}{PlatformID}{$Platform}{BuoyOldName};
        print( "ControlID: $ID Platform: $Platform $strURL\n");
        foreach my $SOrder ( %{$rPlatformHash->{ControlSet}{$ID}{PlatformID}{$Platform}{sorder}} )
        {
          print( "\tSOrder: $SOrder " );          
          foreach my $ObsHandle ( %{$rPlatformHash->{ControlSet}{$ID}{PlatformID}{$Platform}{sorder}{$SOrder}{obsHandle}} )
          {
            print( "\t\tObsHandle: $ObsHandle\n");
            my $i = 0;
          }
        }
      }
    }
#=cut    
    return( 1 );
  }
  return( 0 );
}
=cut
sub GetPlatformID #( $DB, $strPlatformID )
{
  my ( $DB, $strPlatform ) = @_;
  my $strPlatformID = '';
  #We have to lookup the sensor id for the platform.
  my $strSQL = "SELECT row_id 
                FROM platform
                WHERE platform_handle = '$strPlatform'
                LIMIT 1;";

  if( DEBUG_PRINT_SQL )
  {
    print( "$strSQL\n");
  }                    
  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( $strPlatformID );
  }         
  if(! $hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( $strPlatformID );    
  }
  $strPlatformID = $hSt->fetchrow_array();
  
  return( $strPlatformID );  
}
sub GetPlatformSensorID #( $DB, $strSensorName, $strPlatformID, $Elev, $SOrder  )
{
  my ( $DB, $strSensorName, $strPlatformID, $Elev, $SOrder ) = @_;
  my $strSensorID = '';
  my $strWHERE = "platform_handle = '$strPlatformID' AND sensor.short_name = '$strSensorName' ";
  if( $Elev eq '' )
  {
    $strWHERE = $strWHERE."AND fixed_z IS NULL ";  
  }
  else
  {
    $strWHERE = $strWHERE."AND fixed_z = $Elev ";      
  }
  if( $SOrder eq '' )
  {
    $strWHERE = $strWHERE."AND s_order IS NULL ";      
  }
  else
  {
    $strWHERE = $strWHERE."AND s_order = '$SOrder' ";          
  }
  #We have to lookup the sensor id for the platform.
  my $strSQL = "SELECT sensor.row_id 
                FROM sensor
                LEFT JOIN platform on platform.row_id=sensor.platform_id
                WHERE $strWHERE
                LIMIT 1;";

  if( DEBUG_PRINT_SQL )
  {
    print( "$strSQL\n");
  }                    
  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( $strSensorID );
  }         
  if(! $hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( $strSensorID );    
  }
  $strSensorID = $hSt->fetchrow_array();
  
  return( $strSensorID );
}
sub GetMTypeForSensor #( $DB, $strSensor )
{
  my ( $DB, $strSensor ) = @_;
  
  my $strMType = '';
  
  my $strSQL = "SELECT m_type.row_id
               FROM m_type
               LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id
               LEFT JOIN obs_type on obs_type.row_id = m_scalar_type.obs_type_id
               WHERE obs_type.standard_name = '$strSensor'";
  if( DEBUG_PRINT_SQL )
  {
    print( "$strSQL\n");
  }                    
  my $hSt = $DB->prepare( $strSQL );
  if( !defined $hSt )
  {
    print( "ERROR: Unable to prepare SQL statement; $strSQL.\n");
    return( $strMType );
  }         
  if(! $hSt->execute( ) )
  {
    print( "ERROR: Failed execute: $hSt->errstr()\n SQLStatement: $strSQL\n");    
    return( $strMType );    
  }
  $strMType = $hSt->fetchrow_array();
  
  return( $strMType );

}

sub AddSensorToPlatform #( $DB, $ObsHandle, $Platform, 'NULL', $SOrder )
{
  my ( $DB, $ObsHandle, $Platform, $Elev, $SOrder ) = @_;
  
  my $strMType = GetMTypeForSensor( $DB, $ObsHandle );
  if( !defined $strMType )
  {
    print( "ERROR: Sensor Type: $ObsHandle does not exist.\n");
    return( -1 );
  }
  my $strPlatformID = GetPlatformID( $DB, $Platform );
  my $TypeID  = -99999;
  my $strDate;
  if( !MICROSOFT_PLATFORM )
  {
    $strDate = `date +%Y-%m-%d''%k:%M:%S`;
    chomp( $strDate );
  }
  else
  {
    $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y-%m-%dT%k:%M:%S`;
    chomp( $strDate );   
  }  
  
  my $strSQL = "INSERT INTO sensor
            (row_entry_date,platform_id,type_id,short_name,m_type_id,fixed_z,begin_date,s_order)
            VALUES('$strDate','$strPlatformID',$TypeID,'$ObsHandle','$strMType',$Elev,'$strDate',$SOrder)
            ";
  if( DEBUG_PRINT_SQL )
  {
    print( "$strSQL\n");
  }                    
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
  return( 1 );
}