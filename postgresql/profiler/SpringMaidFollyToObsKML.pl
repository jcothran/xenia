use strict;

use DBI;
use XML::LibXML;
use obsKMLSubRoutines;

my $Environ = XML::LibXML->new->parse_file('./environment.xml');


my $platform_id = $ARGV[0];
my $measurement_date = $ARGV[1];
my $strDestinationDir = $ARGV[2];
my $iADCPOrientation = $ARGV[3]; #Orientation of the ADCP sensor, 0 is surface mounted, 1 is bottom mounted. We need to know this so we can correctly
                            #assign the SOrders.
if( !defined( $iADCPOrientation ) )
{
  $iADCPOrientation = 1;
}                           

my $platform_ref;
my ($netcdf_header, $netcdf_final);
my $file_ref;
my $content;
my $record_created = 0;

print( "Comand line args: ARGV[0] $platform_id ARGV[1] $measurement_date ARGV[2] $strDestinationDir\n" );

my $measurement_date_query;
if ($measurement_date eq 'latest') {
        $measurement_date_query = 'order by <TIME_ID> desc limit 1';
}
else {
        $measurement_date_query = "and <TIME_ID> = '$measurement_date'";
}
my $platform_handle;

my %env;
$env{platform_handle}=$platform_handle;	
$env{hostname} = $Environ->findvalue('//DB/host');
$env{db_name} = $Environ->findvalue('//DB/db_name');
$env{db_user} = $Environ->findvalue('//DB/db_user');
$env{db_passwd} = $Environ->findvalue('//DB/db_passwd');

my $dbh_wls = DBI->connect( "dbi:Pg:dbname=$env{db_name};host=$env{hostname};",
                            $env{db_user}, 
                            $env{db_passwd});
if ( !defined $dbh_wls ) {
	die "Cannot connect to database!\n";
}

if (($platform_id eq 'springmaid') || ($platform_id eq 'follybeach')) 
{
  if( ( -d "$strDestinationDir" ) == 0 )
  {
    if( mkdir( "$strDestinationDir", 0777 ) == 0 )
    {
      print( "ERROR::Unable to create directory: $strDestinationDir.\n" );
    }
    else
    {
      print( "Created directory: $strDestinationDir\n" );
    }
  }
	my $record_created = 1;
  my $strURL;
  my $fLat;
  my $fLong;
  my $NDBCId;
  my $iNumBins = 20;  #Maximum number of bins.
  my $Bin1Height = 1.55;
	if ($platform_id eq 'follybeach') 
	{ 
	  $platform_ref = 1; 
	  $file_ref = 'seacoos_follybeach_adcp'; 
	  $netcdf_header = './netcdf/follybeach_header.txt'; 
	  $netcdf_final = './netcdf/follybeach_final.txt'; 
	  $strURL = 'http://nautilus.baruch.sc.edu/waves/folly/index.php';
    $fLat = 32.65;
    $fLong = -79.937;
    $NDBCId = 'fbps1';
	}
	if($platform_id eq 'springmaid')
	 { 
	   $platform_ref = 2; 
	   $file_ref = 'seacoos_springmaid_adcp';
	   $netcdf_header = './netcdf/springmaid_header.txt';
	   $netcdf_final = './netcdf/springmaid_final.txt'; 
     $strURL = 'http://nautilus.baruch.sc.edu/waves/springmaid/index.php';
     $fLat = 33.653;
     $fLong = -78.914;
     $NDBCId = 'smbs1';
	 }

  #Build our bin to SORder mapping.
  my %SOrderMap;
  my $iSorderCnt = $iNumBins - 1;
  for( my $i = 0; $i < $iNumBins; $i++ )
  {
    my $BinName = 'bin_'.$i;
    %SOrderMap->{$BinName} = $iSorderCnt--;
  }
	#open (NETCDF_FILE, ">$netcdf_final");
	#$content = `cat $netcdf_header`;

  
	#Get the depth and figure out the latest measurement to then query the currents table.
	my $sql = qq{ SELECT measurement_value_depth,<TIME_ID> FROM waves where platform_id = $platform_ref $measurement_date_query };
	$sql =~ s/<TIME_ID>/measurement_date/g;
	print $sql."\n";
  my $sth = $dbh_wls->prepare( $sql );
  $sth->execute();
	my $depth;
	($depth,$measurement_date) = $sth->fetchrow_array;
  $sth->finish;
	if (!$depth)
	{ 
	  $depth = -99999; 
	}
	my %ObsHash;
	my $refObsHash = \%ObsHash;
	my $strPlatformID = 'scnms.'.$NDBCId.'.'.'adcp';
	                                     
	$measurement_date = substr($measurement_date,0,19); 
	my $time_sec = `date --date='$measurement_date +0000' +%s`; 
	chomp($time_sec);
	
	my $strDate = $measurement_date;
  $strDate =~ s/ /T/;
	
  ############################################################################################################
  #Get the ADCP data
  ############################################################################################################
	$sql = "SELECT measurement_value_current_speed,measurement_value_current_to_direction,z,z_desc,<TIME_ID>
	        FROM currents 
	        WHERE platform_id = $platform_ref AND measurement_date = '$measurement_date'
	        ORDER BY z ASC;";
	$sql =~ s/<TIME_ID>/measurement_date/g;
  print( "SQL: $sql\n" );
  $sth = $dbh_wls->prepare( $sql );
  if( defined $sth )
  {
    if( $sth->execute() )
    {      
      obsKMLSubRoutines::KMLAddPlatformHashEntry( $strPlatformID, $strURL, $fLat, $fLong, $refObsHash );
    	obsKMLSubRoutines::KMLAddObsToHash( 'depth',
    	                                     $strDate,
    	                                     $depth,
    	                                     1,
    	                                     $strPlatformID,
    	                                     ( $depth * -1 ),
    	                                     'm',
    	                                     $refObsHash );
    
    	while( my ($current_speed, $current_to_direction, $depth_bin_bottom,$bin_desc) = $sth->fetchrow_array )
    	{
    	  #surface and bottom are redundant data, no need to add them since we will already get a bin with the same data.
    	  if( $bin_desc ne 'surface' && $bin_desc ne 'bottom' && $bin_desc ne 'average')
    	  {
        	if (!$current_speed)
        	{ 
        	  $current_speed = -99999; 
        	}
        	else
        	{
        		$current_speed *= 100; #convert from m/s to cm/s
        	}
    #    	print( "Current: $current_speed Direction: $current_to_direction Z: $depth_bin_bottom Desc: $bin_desc\n" );
          my $iSOrder = %SOrderMap->{$bin_desc};
          my $RoundedDepth = RoundTo( $depth_bin_bottom, 0.5, 1 );
       
          if( $RoundedDepth > 0 )
          {
            $RoundedDepth *= -1;
          }
        	obsKMLSubRoutines::KMLAddObsToHash( 'current_speed',
        	                                     $strDate,
        	                                     $current_speed,
        	                                     $iSOrder,
        	                                     $strPlatformID,
        	                                     $RoundedDepth,
        	                                     'cm_s-1',
        	                                     $refObsHash );
        	obsKMLSubRoutines::KMLAddObsToHash( 'current_to_direction',
        	                                     $strDate,
        	                                     $current_to_direction,
        	                                     $iSOrder,
        	                                     $strPlatformID,
        	                                     $RoundedDepth,
        	                                     'degrees_true',
        	                                     $refObsHash );
          $iSOrder++;
    	  }
    	}
    }
    else
    {
      my $strErr = $sth->errstr;
      print( "ERROR::$strErr\n" );
    }      	                                     
  }
  else
  {
    print( "ERROR: Unable to prepare SQL statement.\n" );
  }     	                                     
  ############################################################################################################
  #Get the bulk parameters
  ############################################################################################################
	$sql = "SELECT measurement_value_significant_wave_height,measurement_value_peak_period,measurement_value_peak_direction,measurement_value_depth,measurement_value_maximum_height,measurement_value_mean_period,<TIME_ID>
	        FROM waves 
	        WHERE platform_id = $platform_ref AND measurement_date = '$measurement_date';";
	$sql =~ s/<TIME_ID>/measurement_date/g;
  print( "SQL: $sql\n" );
  $sth = $dbh_wls->prepare( $sql );
  if( defined $sth )
  {
    if( $sth->execute() )
    {
      my ($measurement_value_significant_wave_height, 
          $measurement_value_peak_period, 
          $measurement_value_peak_direction,
          $measurement_value_depth,
          $measurement_value_max_height,
          $measurement_value_mean_period) = $sth->fetchrow_array; 
          
        	obsKMLSubRoutines::KMLAddObsToHash( 'significant_wave_height',
        	                                     $strDate,
        	                                     $measurement_value_significant_wave_height,
        	                                     1,
        	                                     $strPlatformID,
        	                                     0,
        	                                     'm',
        	                                     $refObsHash );
    
        	obsKMLSubRoutines::KMLAddObsToHash( 'dominant_wave_period',
        	                                     $strDate,
        	                                     $measurement_value_peak_period,
        	                                     1,
        	                                     $strPlatformID,
        	                                     0,
        	                                     's',
        	                                     $refObsHash );
    
        	obsKMLSubRoutines::KMLAddObsToHash( 'mean_wave_direction_peak_period',
        	                                     $strDate,
        	                                     $measurement_value_peak_direction,
        	                                     1,
        	                                     $strPlatformID,
        	                                     0,
        	                                     'degrees_true',
        	                                     $refObsHash );
    }
    else
    {
      my $strErr = $sth->errstr;
      print( "ERROR::$strErr\n" );
    }      	                                     
  }
  else
  {
    print( "ERROR: Unable to prepare SQL statement.\n" );
  }     	                                     
  ############################################################################################################

  $sth->finish;
  #Now build the KML file.
  my $strKMLFilename = "$strDestinationDir/$platform_id-$strDate" . '_latest.kml'; 
  print( "KMLFile: $strKMLFilename\n" ); 
  obsKMLSubRoutines::BuildKMLFile( \%ObsHash, $strKMLFilename );
}

sub RoundTo#( $Value, $Ceiling, $RoundUp )
{
  my( $Value, $Ceiling, $RoundUp ) = @_;
  if( !defined( $RoundUp ) )
  {
    $RoundUp = 1;
  }
  #Round up to a whole integer -
  # Any decimal value will force a round to the next integer.
  #i.e. 0.01 = 1 or 0.8 = 1
 
  my $tmpVal = (($Value / $Ceiling) + (-0.5 + ($RoundUp & 1)));
  print( "tmpVal: $tmpVal " );
  
  my $tmp = int($tmpVal);
  print( "tmp: $tmp " );
  
  $tmpVal = sprintf( "%d", ( $tmpVal - $tmp ) );
  print( "tmpVal: $tmpVal " );
  
  my $nValue = $tmp + $tmpVal ;
  print( "nValue: $nValue " );

  #Multiply by ceiling value to set RoundtoValue
  my $RoundToValue = $nValue * $Ceiling;
  print( "RoundToValue: $RoundToValue\n" );
 
  return( $RoundToValue ); 
}
