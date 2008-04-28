use strict;

use Getopt::Long;
use XML::LibXML;
use LWP::Simple;

use constant MICROSOFT_PLATFORM => 0;
use constant USE_DEBUG_PRINTS => 1;

my $strEmail = 'dan@inlet.geol.sc.edu (Dan Ramage)';
#use $strRSSXML = "<?xml version="1.0" encoding="UTF-8"?>\n

my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "ObsKMLFeed=s",
            "FeedDir=s" );
            
my $strObsKMLFeed = $CommandLineOptions{"ObsKMLFeed"};            
my $strFeedDir = $CommandLineOptions{"FeedDir"};            


if( length( $strObsKMLFeed ) == 0 || length( $strFeedDir ) == 0 )
{
  die( "Missing required command line option.\n".
       "Syntax is ObsKMLToGeoRSS --ObsKMLFeed= --FeedDir=\n".
       "--ObsKMLFeed is the url to pull the ObsKML zip file from to use for generation of the georss feed.\n".
       "--FeedDir is the directory on the server to save the georss feed.\n" );
}
my $strTempDir;
my $strTargetDir;
my $strTstProfPath;
my $RandVal  = int(rand(10000000));
my $strTmpDirName = "gearth_$RandVal";
my $FileList;
my @Files;

if( !MICROSOFT_PLATFORM )
{
  $strTempDir = '/tmp/ms_tmp';

  #create temp working directory
  
  $strTargetDir = "$strTempDir/$strTmpDirName";
  `mkdir $strTargetDir`;
  if( USE_DEBUG_PRINTS )
  {
    print "TargetDir: $strTargetDir\n";
  }
  ##################
  #read input files to temp directory
  ################## 
  $strTstProfPath = "$strTargetDir/obskml.xml.zip";
  if( USE_DEBUG_PRINTS )
  {
    print "ObsKMLFeed: $strObsKMLFeed\n";
  }
  my $RetCode = getstore( "$strObsKMLFeed", $strTstProfPath );
  if( USE_DEBUG_PRINTS )
  {
    if( is_success($RetCode) )
    {
      print( "Success($strObsKMLFeed): getstore return code: $RetCode.\n");
    }
    else
    {
      print( "Error($strObsKMLFeed): getstore return code: $RetCode.\n");   
    }
  } 
  `cd $strTargetDir; unzip obskml.xml.zip`;

  $FileList  = `ls $strTargetDir/*.kml`;
  @Files     = split(/\n/,$FileList);

}
else
{
  $strTempDir = '\\temp\\ms_tmp'; 

  #create temp working directory
  $strTargetDir = "$strTempDir\\$strTmpDirName";
  `mkdir $strTargetDir`;
  if( USE_DEBUG_PRINTS )
  {
    print "TargetDir: $strTargetDir\n";
  }

  $strTstProfPath = "$strTargetDir\\obskml.xml.zip";
  if( USE_DEBUG_PRINTS )
  {
    print "ObsKMLFeed: $strObsKMLFeed\n";
  }
  my $RetCode = getstore( $strObsKMLFeed, $strTstProfPath );
  if( USE_DEBUG_PRINTS )
  {
    if( is_success($RetCode) )
    {
      print( "Success($strObsKMLFeed): getstore return code: $RetCode.\n");
    }
    else
    {
      print( "Error($strObsKMLFeed): getstore return code: $RetCode.\n");   
    }
  }
  `cd $strTargetDir & unzip obskml.xml.zip`;
  
  $FileList  = `dir /B $strTargetDir\\*.kml`;
  @Files     = split(/\n/,$FileList);
  
}

foreach my $File (@Files) 
{
  my $xp;  
  if( !MICROSOFT_PLATFORM )
  {
    $xp = XML::LibXML->new->parse_file("$File");   
  }
  else
  {
    $xp = XML::LibXML->new->parse_file("$strTargetDir\\$File");   
  }
  foreach my $platform ($xp->findnodes('//Placemark')) 
  {

    my $platform_id = sprintf("%s",$platform->find('name'));
    if( length( $platform_id ) == 0 )
    {
      $platform_id = sprintf("%s",$platform->getAttribute('id'));      
    }
    my $operator_url          = sprintf("%s",$platform->find('Metadata/obsList/operatorURL'));
    my $platform_url          = sprintf("%s",$platform->find('Metadata/obsList/platformURL'));
    my $lon_lat_string        = sprintf("%s",$platform->find('Point/coordinates'));
    my ($longitude,$latitude) = split(/,/,$lon_lat_string);
    my $datetime = sprintf("%s",$platform->find('TimeStamp'));
    
    if( USE_DEBUG_PRINTS )
    {
      print( "Processing platform: $platform_id\n" );
    }
    ################################################################################################
    #We create a GeoRSS feed per platform.
    my $GeoRSSFile;
    my $strGeoRSSFilename;
    my $strID = $platform_id;
    $strID =~ s/\./_/g;
    if( !MICROSOFT_PLATFORM )
    {
      $strGeoRSSFilename = "$strFeedDir/$strID";
      $strGeoRSSFilename = $strGeoRSSFilename.'_GeoRSS_latest.xml'
    }
    else
    {
      $strGeoRSSFilename = "$strFeedDir\\$strID";
      $strGeoRSSFilename = $strGeoRSSFilename.'_GeoRSS_latest.xml'
    }
    if( !open( $GeoRSSFile, ">$strGeoRSSFilename" ) )
    {
      die( "ERROR: Unable to open GeoRSS file: $strGeoRSSFilename. Cannot continue.\n" );
    }
    if( USE_DEBUG_PRINTS )
    {
      print( "Successfully opened GeoRSS file: $strGeoRSSFilename\n" );
    }
    
    #Print the XML version as first line.
    my $strRow = '<?xml version="1.0" encoding="UTF-8"?>';
    print( $GeoRSSFile  $strRow."\n" );
    #RSS version next.
    $strRow = '<rss version="2.0" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml">';
    print( $GeoRSSFile  $strRow."\n" );
     
    ################################################################################################

    #initially I thought about just using $platform_name below, but decided to use the full $platform_id instead
    my ($organization_name, $platform_name, $package_name);
    my ($latlon_label_1,$latlon_label_2,$latlon_label_3);
    if ($platform_id =~ /NR/ || $platform_id =~ /SHIP/) #for vos the name element contains a bunch of junk that we need to swap out
    { 
      ($organization_name,$platform_name,$package_name) = split(/\./,'vos.none.ship');
      $platform_id = 'vos.point('.$lon_lat_string.').ship';
    }
    else
    { 
      ($organization_name, $platform_name, $package_name) = split(/\./,$platform_id); 
    }
    #Now we begin the channel information.
    $strRow = '<channel>';
    print( $GeoRSSFile  $strRow."\n" );
    
    my $strChannelDate;
    my $strRFCDate = $datetime;
    $strRFCDate =~ s/Z//;
    $strRFCDate =~ s/T/ /;
    if( !MICROSOFT_PLATFORM )
    {
      #Convert the DB date into RFC822 as per the RSS spec.
      $strRFCDate = `date --date=\"$strRFCDate\" -R`;
      #Get the current RFC822 date to use as channel publication date.
      $strChannelDate = `date -R`;
    }
    else
    {
      #Convert the DB date into RFC822 as per the RSS spec.
      $strRFCDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe --date=\"$strRFCDate\" -R`;
      #Get the current RFC822 date to use as channel publication date.
      $strChannelDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe -R`;
    }
    chomp( $strRFCDate );
    chomp( $strChannelDate );
    
    $strRow = "<title>$platform_id latest observations</title>\n<description>Latest observation data</description>\n<pubDate>$strChannelDate</pubDate>\n<webMaster>$strEmail</webMaster>\n";
    print( $GeoRSSFile  $strRow );
    
    #We must have a valid link to add the tag.
    if( length( $platform_url ) > 0 )
    {
      $strRow = "<link>$platform_url</link>\n";
    }
    else
    {
      #We MUST have a link for the georss, so if the obsKML file didn't have one, we dummy something up for now.
      $strRow = "<link>http://$platform_id</link>\n";
    }
    print( $GeoRSSFile  $strRow );
  
    #######################################################################################################################################
    # The <item> children begin here.
    $strRow = '<item>';
    print( $GeoRSSFile  $strRow."\n" );
    
    $strRow = "<title>$platform_id Latest observations</title>";
    print( $GeoRSSFile  $strRow."\n" );

    $strRow = "<pubDate>$strRFCDate</pubDate>";
    print( $GeoRSSFile  $strRow."\n" );
    
    #We must have a valid link to add the tag.
    if( length( $platform_url ) > 0 )
    {
      $strRow = "<link>$platform_url</link>\n";
    }
    else
    {
      #We MUST have a link for the georss, so if the obsKML file didn't have one, we dummy something up for now.
      $strRow = "<link>http://$platform_id</link>\n";
    }
    print( $GeoRSSFile  $strRow );
    
    $strRow = "<author>$strEmail</author>";
    print( $GeoRSSFile  $strRow."\n" );

    my $measurement = '';
    my $depth = ''; 
    my $strDesc;
    foreach my $observation ($platform->findnodes('Metadata/obsList/obs')) 
    {
      $depth                = sprintf("%s",$observation->find('elev'));
      $measurement          = sprintf("%s",$observation->find('value'));
      my $parameter         = sprintf("%s",$observation->find('obsType'));
      my $uom               = sprintf("%s",$observation->find('uomType'));
      my $observed_property = $parameter.".".$uom;
      my $data_url          = sprintf("%s",$observation->find('dataURL'));
      #Create the row. we use html table formatting to help present the data in a more readable fashion. 
      #$strDesc = $strDesc."<tr><td>$parameter:</td><td>$measurement</td><td>$uom</td><td>Depth</td><td>$depth </td></tr>\n";
      $strDesc = $strDesc."<tr><td>$parameter:</td><td>$measurement</td><td>$uom</td></tr>\n";
    } #obs
    #We use the ![CDATA]] directive to tell teh parser not to mess with the contents so we can take advantage of the HTML table
    #formatting.
    $strRow = "<description><![CDATA[$strDesc]]></description>\n";
    print( $GeoRSSFile  $strRow );
    $strRow = "<georss:where>\n<gml:Point>\n<gml:pos>$latitude $longitude</gml:pos>\n</gml:Point>\n</georss:where>\n";
    print( $GeoRSSFile  $strRow );
    
    
    #Close the item tag.
    $strRow = '</item>';
    print( $GeoRSSFile  $strRow."\n" );
    #Close the channel tag.
    $strRow = '</channel>';
    print( $GeoRSSFile  $strRow."\n" );
    #close the rss tag.
    $strRow = '</rss>';
    print( $GeoRSSFile  $strRow."\n" );
    
    close( $GeoRSSFile );
  } #Placemark
} #files




#Clean up the temp directory
if( !MICROSOFT_PLATFORM )
{
  `cd $strTempDir; rm -r $strTmpDirName`  ;
}
else
{
  `cd $strTempDir & rmdir /S /Q $strTmpDirName`;
}

