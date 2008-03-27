###################################################################################################################
# Revision: DWR
# Date: 3/13/2008
# Added the use of the SOrder from the kml and from the test_profile.xml file. Currently we are in transition from the
# method of generating the obsKML from the old database to generating obsKMl directly from the telemetry. We are implementing
# all teh sensor data, so for the ADCPs and other multiple same type sensors we use the <sorder> tag(Sensor order) to distinguish.
#
# Date: 1/24/2008
# Added ability to run under windows using the MICROSOFT_PLATFORM. When defined as 1, Microsoft centric things are done,
# mostly dealing with shell commands and file paths.
# Also added a categorizing of the results so platforms with failing sensors for a given test profile are at the top of
# the list.
# ToDo: 
# -Break out the HTTP kmz feed to another command line paramter.
###################################################################################################################

#!/usr/bin/perl 
#script: test_profiles.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#Date: August 10, 2007
#script description
#Compares a given ObsKML file against a set of test profiles to cause notification and website documentation
  
use strict;
use XML::LibXML;
use LWP::Simple;
use Getopt::Long;

#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.
#NOTE: There is no builtin unzip for Windows, you will need to modify the code where the unzip occurs to suit.

use constant MICROSOFT_PLATFORM => 1;

#1 enables the various debug print statements, 0 turns them off.
use constant USE_DEBUG_PRINTS   => 0;
###path config#############################################

#note the user process under which this runs needs to have permissions to write to the following paths

#a temporary directory for decompressing, processing files
 my $temp_dir;
if( !MICROSOFT_PLATFORM )
{
  $temp_dir = '/usr2/home/dramage_prod/tmp';
}
else
{
  $temp_dir = '\\temp\\ms_tmp'; 
}
my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "WorkingDir=s",
            "KMZFeed=s",
            "TstProfFeed=s" );

my $output_name     = $CommandLineOptions{"WorkingDir"};
my $strKMZFeed      = $CommandLineOptions{"KMZFeed"};
my $strTstProfFeed  = $CommandLineOptions{"TstProfFeed"}; 
#my $output_name = $ARGV[0];
if( length( $output_name ) == 0 || 
    length( $strKMZFeed ) == 0  ||
    length( $strTstProfFeed ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --WorkingDir --KMZFeed --TstProfFeed\n". 
              "--WorkingDir provides the directory used to store the results file, test_results.csv Should provide a unique name, such as carocoops to denote where the data originated.\n".
              "--KMZFeed provides the url where the KMZ file resides.\n".
              "--TstProfFeed provides the url where the test_profiles.xml file resides.\n" );
}

#this is a zip of 1 or more ObsKML files which will all be processed into the necessary oostethys support files
#my $kml_zip_feed = "http://carocoops.org/obskml/feeds/$output_name/$output_name\_metadata_latest.kmz";

###########################################################
###################################################
# Constants defining the various test states.
use constant {
 TEST_UNINIT    => -1,
 TEST_PASSED    => 0,
 TEST_LAGGING   => 1,
 TEST_NO_DATA   => 2,
 TEST_FAILED    => 3
};

my $random_value  = int(rand(10000000));
my $strTmpDirName = "gearth_$random_value";
my $target_dir    = '';
my $zip_filepath  = '';
my $strTstProfPath = '';
my $filelist      = '';
my @files;
if( !MICROSOFT_PLATFORM )
{
  #create temp working directory
  
  $target_dir = "$temp_dir/$strTmpDirName";
  `mkdir $target_dir`;
  if( USE_DEBUG_PRINTS )
  {
    print "TargetDir: $target_dir\n";
  }

  ##################
  #read input files to temp directory
  ##################
  
  #zip_obskml_url
  $zip_filepath = "$target_dir/obskml.xml.zip";
  $strTstProfPath = "$target_dir/test_profiles.xml";
  if( USE_DEBUG_PRINTS )
  {
    print "KmlZipFeed: $strKMZFeed\n";
    print "ZipFilePath: $zip_filepath\n";
    print "TstProfFeed: $strTstProfFeed\n";
  }
  my $RetCode = getstore("$strKMZFeed", $zip_filepath);
  if( USE_DEBUG_PRINTS )
  {
    if( is_success($RetCode) )
    {
      print( "Success($strKMZFeed): getstore return code: $RetCode.\n");
    }
    else
    {
      print( "Error($strKMZFeed): getstore return code: $RetCode.\n");   
    }
  }
  $RetCode = getstore( "$strTstProfFeed", $strTstProfPath );
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
  `cd $target_dir; unzip obskml.xml.zip`;
  
  $filelist = `ls $target_dir/*.kml`;
  
  #print $filelist;
  @files = split(/\n/,$filelist);
  
  if( USE_DEBUG_PRINTS )
  {
    print "Files: @files";
  }
}
else
{
  #create temp working directory
  $target_dir = "$temp_dir\\$strTmpDirName";
  `mkdir $target_dir`;
  if( USE_DEBUG_PRINTS )
  {
    print "TargetDir: $target_dir\n";
  }

  ##################
  #read input files to temp directory
  ##################
  
  #zip_obskml_url
  $zip_filepath = "$target_dir\\obskml.xml.zip";
  $strTstProfPath = "$target_dir\\test_profiles.xml";
  if( USE_DEBUG_PRINTS )
  {
    print "KmlZipFeed: $strKMZFeed\n";
    print "ZipFilePath: $zip_filepath\n";
    print "TstProfFeed: $strTstProfFeed\n";
  }
  my $RetCode = getstore("$strKMZFeed", $zip_filepath);
  if( USE_DEBUG_PRINTS )
  {
    if( is_success($RetCode) )
    {
      print( "Success($strKMZFeed): getstore return code: $RetCode.\n");
    }
    else
    {
      print( "Error($strKMZFeed): getstore return code: $RetCode.\n");   
    }
  }
  $RetCode = getstore( "$strTstProfFeed", $strTstProfPath );
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
  #NOTE If your system does not have an unzip.exe, this is going to fail.
  `cd $target_dir & unzip.exe $target_dir\\obskml.xml.zip`;
  #`cd $target_dir unzip.exe obskml.xml.zip`;
  
  $filelist = `dir /B /S $target_dir\\*.kml`;     #/B flag gives barebones info, /S gives fully qualified path.
  
  if( USE_DEBUG_PRINTS )
  {
    print "Filelist: $filelist\n";
  }
  @files = split(/\n/,$filelist);
  if( USE_DEBUG_PRINTS )
  {
    print "Files: @files";
    print "\n";
  }
}
#my $csv_content .= "platform_handle,observation_type.unit_of_measure,time,latitude,longitude,depth,measurement_value,data_url,operator_url,platform_url\n";

#the next sections jump between outputting the sos_config.xml file and querying the repeating xml elements for subtitution in the corresponding file elements.

#note that the below hashing convention assumes each element contains only one type of child element except at the terminals
my %HoH = ();
my $rHoH = \%HoH;

##repeating elements section

foreach my $file (@files) 
{
  my $xp = XML::LibXML->new->parse_file("$file");
  
  #my $xp_xml = $xp->serialize; #debug
  #print $xp_xml;
  
  foreach my $platform ($xp->findnodes('//Placemark')) 
  {
    #if( USE_DEBUG_PRINTS )
    #{
    #  print "platform:$platform\n"; #debug
    #}
    #my $platform_id = $platform->find('Placemark[@id]');
    my $platform_id = sprintf("%s",$platform->find('name'));
    if( length( $platform_id ) == 0 )
    {
      $platform_id = sprintf("%s",$platform->getAttribute('id'));      
    }
    #my $platform_id = 'one';
  
    my $operator_url = sprintf("%s",$platform->find('Metadata/obsList/operatorURL'));
    my $platform_url = sprintf("%s",$platform->find('Metadata/obsList/platformURL'));
  
  	my $lon_lat_string = sprintf("%s",$platform->find('Point/coordinates'));
  	my ($longitude,$latitude) = split(/,/,$lon_lat_string);
  	#print "$lon $lat \n";
  
  	my $datetime = sprintf("%s",$platform->find('TimeStamp'));
    #if( USE_DEBUG_PRINTS )
    #{
    #	print "$datetime \n";
    #}
  
  	#initially I thought about just using $platform_name below, but decided to use the full $platform_id instead
  	my ($organization_name, $platform_name, $package_name);
  	my ($latlon_label_1,$latlon_label_2,$latlon_label_3);
  	#if platform name is point like from VOS 'point(-81.3,32.5)' then parse differently than usual 
  	#if ($platform_id =~ /point/) { ($organization_name, $latlon_label_1, $latlon_label_2, $latlon_label_3, $package_name) = split(/\./,$platform_id); $platform_name = $latlon_label_1.".".$latlon_label_2.".".$latlon_label_3; }
  	if ($platform_id =~ /NR/ || $platform_id =~ /SHIP/)
  	{ #for vos the name element contains a bunch of junk that we need to swap out
  		 ($organization_name,$platform_name,$package_name) = split(/\./,'vos.none.ship');
  		 $platform_id = 'vos.point('.$lon_lat_string.').ship';
  	}
  	else
  	{
  	 ($organization_name, $platform_name, $package_name) = split(/\./,$platform_id); 
  	}
  
  	my $measurement = '';
  	my $depth = '';	
  
    foreach my $observation ($platform->findnodes('Metadata/obsList/obs')) 
    {
      $depth = sprintf("%s",$observation->find('elev'));
      $measurement = sprintf("%s",$observation->find('value'));
      my $parameter = sprintf("%s",$observation->find('obsType'));
      my $uom = sprintf("%s",$observation->find('uomType'));
      my $SOrder = sprintf("%s",$observation->find('sorder'));
      #DWR 3/13/2008 Check to see if the <sorder> tag is present, if not we'll assign it to 1.
      if( length( $SOrder == 0 ) )
      {
        $SOrder = 1;
      }
  
  		my $observed_property = $parameter.".".$uom;
  		#print "$parameter $measurement \n";
  
      my $data_url = sprintf("%s",$observation->find('dataURL'));
  
  		#$csv_content .= '"'.$platform_id.'",'.$parameter.'.'.$uom.','.$datetime.','.$latitude.','.$longitude.','.$depth.','.$measurement.','.$data_url.','.$operator_url.','.$platform_url."\n";
  	
      if( USE_DEBUG_PRINTS )
      {
  		  print "{ $platform_id }{ $parameter".".$uom }{ $datetime } $measurement\n";
      }
  		$HoH{$platform_id}{$platform_url}{$datetime}{sorder}{$SOrder}{$parameter.'.'."$uom"}{'measurement'} = $measurement;
  		#Set initial status to no data.
    } #obs 
  } #Placemark
} #files

close (FILE_IN);

#now apply tests to hash
my $xp_tests = XML::LibXML->new->parse_file($strTstProfPath);
#if( !MICROSOFT_PLATFORM )
#{
  #$xp_tests = XML::LibXML->new->parse_file($strTstProfPath);
  #$xp_tests = XML::LibXML->new->parse_file("$output_name/test_profiles.xml");
#}
#else
#{
  #$xp_tests = XML::LibXML->new->parse_file("$output_name\\test_profiles.xml");
  #my $xp_tests = XML::LibXML->new->parse_file("C:\\Documents and Settings\\dramage\\workspace\\obsKMLLimits\\processObsKML\\nerrs\\test_profiles.xml");
#}

my $error_message = '';

my %hPrintHash;
my $rhPrintHash = \%hPrintHash;
my $iTestNdx = 0;
my $iBuildHeader = 1;
my @HeaderStrings;
my $iAllDataLagging = 1;

#Loop through the test_profiles.xml and handle each individual test profile.
foreach my $test_profile ($xp_tests->findnodes('//testProfile'))
{
	my $test_profile_id = sprintf("%s",$test_profile->find('id'));
  if( USE_DEBUG_PRINTS )
  {
   	print( "TestProfileID: $test_profile\n"); 
  }    
	#print CSV_FILE "test_profile_$test_profile_id,time";

	my $time_lag_limit = sprintf("%s",$test_profile->find('notify/timeLagLimit'));
	#print "time_lag_limit:".$time_lag_limit."\n"; #debug
	
	foreach my $platform_id ($test_profile->findnodes('platformList/platform')) 
	{
  	$platform_id = $platform_id->string_value();
  	
  	#my $platform_url = $rHoH->{$platform_id}{'PlatformURL'};
  	my $platform_url;
  	#NOTE: Probably not the best way to get the URL as data.
  	foreach my $UrlKey ( keys %{$rHoH->{$platform_id}})
  	{
  	  $platform_url = $UrlKey;
      if( USE_DEBUG_PRINTS )
      {
        print "URL: $platform_url\n";
      }  	  
  	}
  	my $datetime = '';
  	my $datetime_old = 'begin';
  	my $strHeader = '';
 		my $strRowData = "$platform_url";
 		my $iColumnCnt = 0;
    my $status_flag = TEST_UNINIT;
       
    #if( USE_DEBUG_PRINTS )
    #{
    #  print( "RowData: $strRowData");
    #}  	
    my $bPlatformInKML = 0;
  	foreach my $DateKey ( reverse sort keys %{$rHoH->{$platform_id}{$platform_url}})
  	{
  	  $bPlatformInKML = 1;
  	  $datetime = $DateKey;
			$datetime =~ s/T/ /g;
			$datetime =~ s/Z//g;
			$datetime = substr($datetime,0,-3); #truncate time zone minutes 
  	  
		  my $date_test;
		  my $date_now;
		  if( !MICROSOFT_PLATFORM )
		  {
				$date_test = `date --date='$datetime' +%s`;	
				chomp($date_test);
				$date_now = `date +%s`;	
				chomp($date_now);
		  }
		  else
		  {
        #NOTE: Using UnxUtils: http://sourceforge.net/project/showfiles.php?group_id=9328 to emulate the date function in windows.
        # Will need to adjust the path based on where you install them.  		
        $date_test = `\\UnixUtils\\usr\\local\\wbin\\date.exe --d=\"$datetime\" +%s;`;
				chomp($date_test);
        my $date_now = `\\UnixUtils\\usr\\local\\wbin\\date.exe +%s`;
				chomp($date_now);
		  }
			my $time_difference = $date_now - $date_test - 18000;
			#print "$date_now,$date_test,$time_difference,$time_lag_limit\n"; #debug1
			if ($time_difference > $time_lag_limit) 
			{
        $strRowData = $strRowData.",$datetime(lagging)";			
        $status_flag = TEST_LAGGING; 				             
			}
			else
			{			  
        $strRowData = $strRowData.",$datetime";			   
			}  	  
      #if( USE_DEBUG_PRINTS )
      #{
      #  print( "$strRowData");
      #}  	
			
    	foreach my $obs ($test_profile->findnodes('obsList/obs'))
    	{
    		my $measurement = '';
     		my $obs_handle = sprintf("%s",$obs->find('obsHandle'));
     		#print "obs_handle:$obs_handle\n"; #debug1
    
    		my $range_high = sprintf("%s",$obs->find('rangeHigh'));
    		my $range_low = sprintf("%s",$obs->find('rangeLow'));
        #DWR 3/13/2008
        my $SOrder = sprintf("%s",$obs->find('sorder'));
        if( length( $SOrder ) == 0 )
        {
          $SOrder = 1;
        }
        
        #Build the header string in the same order as the tests. We only want 1 header per test profile.
        if( $iBuildHeader )
        {
         if( length( $strHeader ) == 0 )
         {
           $strHeader = "Test_Profile_$test_profile_id,platform_url,time,$obs_handle,range $range_low < x < $range_high";
         }
         else
         {
           $strHeader = $strHeader.",$obs_handle,range $range_low < x < $range_high";
         } 		
        }		          	
    		my $bObsInKML = 0;
        foreach my $fMeas ( sort keys %{$rHoH->{$platform_id}{$platform_url}{$DateKey}{sorder}{$SOrder}{$obs_handle}} )  		
    		{
    		  $bObsInKML = 1;
     			$measurement = sprintf("%s",$rHoH->{$platform_id}{$platform_url}{$DateKey}{sorder}{$SOrder}{$obs_handle}{$fMeas});
   			
          my $strStatusText = '';
          if( $measurement ne '' )
          {
            if($measurement < $range_low ) 
            { 
             $status_flag = TEST_FAILED;
             $strStatusText = 'fail low'; 
            }
            elsif( $measurement > $range_high )
            {
             $status_flag = TEST_FAILED;
             $strStatusText = 'fail high';          
            }
            else
            {
              $strStatusText = 'pass';             
            }
           #We want to hold the worst state over for test profiles that have multiple observations. This is because
           #we may have 4 good sensors, but one bad, so we  want to make sure that platform is flagged as having an issue.
           if( $status_flag != TEST_FAILED && $status_flag != TEST_LAGGING )
           {
            $status_flag = TEST_PASSED;
           }         
           $strRowData = $strRowData.",$strStatusText,$measurement";           
          }    			
    			$datetime_old = $datetime;     
    		}
    		if( $status_flag == TEST_UNINIT || $measurement eq '' )
    		{
         if( $status_flag != TEST_FAILED && $status_flag != TEST_LAGGING )
         {
      		 $status_flag = TEST_NO_DATA;
         }
         #The measurement was found in the KML file, however no data was reported.
#         if( $bObsInKML )
#         {
          $strRowData = $strRowData.",missing,none";
#         }
#         else
#         {
#          $strRowData = $strRowData.",missing in KML feed,none";         
#         }		 
    		}
    	}	#foreach obs
		  last; #only looking at latest measurements for now	
  	} #foreach $datetime
  	if( $iBuildHeader )
  	{
 		 push( @HeaderStrings, $strHeader );
 		 $iBuildHeader = 0;
  	}
  	if( !$bPlatformInKML )
  	{  	  
  	  $strRowData = $strRowData.",Platform not present in KML feed,missing all";
  	  $status_flag = TEST_NO_DATA;
  	}
  	if( USE_DEBUG_PRINTS )
  	{
  	  print( "RowData: $strRowData\n");
  	}
		$rhPrintHash->{TestProfile}{$iTestNdx}        #Each test profile is used as a key so we group our data correctly.
		              {Status}{$status_flag}          #Status is used so for each test profile case, we can sort our data from worst to best.
		              {PlatformID}{$platform_id}      #Platform the data pertains to, could probably get away with adding this into the row data and get rid of this key.
		              {RowData} = $strRowData; 			  #The row data we want to print.              
	} #foreach $platform_id
	$iTestNdx++;
	$iBuildHeader = 1;
} #foreach $test_profile

#Clean up the temp directory
if( !MICROSOFT_PLATFORM )
{
  `cd $temp_dir; rm -r $strTmpDirName`  ;
}
else
{
  `cd $temp_dir & rmdir /S /Q $strTmpDirName`;
}
#################################################################################################
#Sort the hash according to the status field then write the csv file.
my $iHeaderNdx = 0;
if( !MICROSOFT_PLATFORM )
{
  open(CSV_FILE,">$output_name/test_results.csv");
}
else
{
  open(CSV_FILE,">$output_name\\test_results.csv");
  #open(CSV_FILE,">C:\\Documents and Settings\\dramage\\workspace\\obsKMLLimits\\processObsKML\\nerrs\\test_results.csv");
}

my $iCurTextNdx = -1;
#Write out the CSV in order of TestNdx which corresponds with the order the test_profile was handled, then based on the Status
#which is high to low order(failures to passing).
foreach my $TestNdx (sort keys %{$rhPrintHash->{TestProfile}}) 
{
  if( $iCurTextNdx != $TestNdx )
  {
   my $strHeader = "$HeaderStrings[$iHeaderNdx]\n";
   print CSV_FILE $strHeader;
   $iHeaderNdx++;
   $iCurTextNdx = $TestNdx;
  }  
  foreach my $StatusFlag (reverse sort keys %{$rhPrintHash->{TestProfile}{$TestNdx}{Status}}) 
  {     
   foreach my $ID (keys %{$rhPrintHash->{TestProfile}{$TestNdx}{Status}{$StatusFlag}{PlatformID}} )
   {
    my $strRow = %hPrintHash->{TestProfile}{$TestNdx}{Status}{$StatusFlag}{PlatformID}{$ID}{RowData};
    print CSV_FILE "$ID,$strRow\n";
   }      
  }    
}
close(CSV_FILE);

exit 0;

