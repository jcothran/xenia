###############################################################################
#Rev: 1.2.0.0
#Author: DWR
#Changes: Added new command line option to specifiy a specific providers last N records.
###############################################################################

#!/usr/bin/perl 

use strict;
use LWP::Simple;
use Getopt::Long;
use XML::LibXML;

use constant MICROSOFT_PLATFORM => 0;

#Get the minute so we know when we are at the top of the hour, we can delete the last hours .zip file.
=comment
my $Minute;
if( !MICROSOFT_PLATFORM )
{
  $Minute = `date %M`;
}
else
{
  $Minute = `\\UnixUtils\\usr\\local\\wbin\\date %M`;
}
=cut
my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "URLControlFile=s",     #The XML file we use to list the URLs we want to grab files(normally netcdfs) from.
            "FileFilter:s",         #Optional. The filter we apply to the http document we are tryng to download.
            "DirForObsKml:s",       #Optional. If we want the script to convert the netcdfs to obskml, this is the directory we store the obskml.
            "Delete:s",             #Optional. If we are converting to obsKML and want to get rid of the netcdfs afterwards, set this to yes.
            "DownloadDir:s",        #Optional. Directory to store the downloaded netcdf files in. Default is ./latest_netcdf_files.
            "FetchLogDir:s",        #Optional. Directory for log files we use to determine what the new netcdf files are to download. Default is ./fetch_logs.
            "UseLastNTimeStamps:s",  #Optional. Integer representing the last N time entries to use when converting the data to obsKML. DWR v1.1.0.0 6/2/2008
            "UseLastNTimeStampsForOrg:s"  #Optional. List specifing orginization and the last N time entries to use for them. Whereas the UseLastNTimeStamps is applied
                                    #to every organization, this can tailor to the specific. If not provided and UseLastNTimeStamps is provided, it is used.
             );

my $strURLControlFile  = $CommandLineOptions{"URLControlFile"}; 
my $strFilter          = $CommandLineOptions{"FileFilter"};
my $strDirForObsKml    = $CommandLineOptions{"DirForObsKml"}; 
my $strDelete          = $CommandLineOptions{"DeleteFiles"}; 
my $strNetCDFDir       = $CommandLineOptions{"NetCDFDir"};
my $strFetchLogDir     = $CommandLineOptions{"FetchLogDir"};
my $strLastNTimeStamps   = $CommandLineOptions{"UseLastNTimeStamps"}; #DWR v1.1.0.0 6/2/2008
my $strLastNTimeStampsPerOrg = $CommandLineOptions{"UseLastNTimeStampsForOrg"}; #DWR v1.2.0.0 9/17/2008
if( length( $strURLControlFile ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --URLControlFile --Delete\n". 
              "--URLControlFile is the XML file with the URL list the script will download the files from.\n".
              "--FileFilter is the filter to apply to the file listings to allow the script to download the files we really want. Optional.\n".
              "--DirForObsKml provides the path to the store the ObsKML files created. This is an optional argument, if not provided no ObsKML files are written.\n".             
              "--Delete specifies we delete the netcdf files after we write the ObsKML files. This is an optional argument.\n".
              "--DownloadDir is the directory to store the downloaded files. Optional, default is ./latest_netcdf_files.\n".
              "--FetchLogDir is the directory were the file time stamps are stored. The script uses these files to determine which files are really the latest. Optional, default is ./fetch_logs.\n".
              "--UseLastNTimeStamps Integer representing the last N time entries to use when converting the data to obsKML. Optional.\n".
              "--UseLastNTimeStampsForOrg Optional. List specifing orginization and the last N time entries to use for them. Whereas the UseLastNTimeStamps is applied to every organization, this can tailor to the specific. If not provided and UseLastNTimeStamps is provided, it is used.\n"            
            );
}
if( length( $strNetCDFDir) == 0 )
{
  if( !MICROSOFT_PLATFORM )
  {
    $strNetCDFDir = './latest_netcdf_files';
  }
  else
  {
    $strNetCDFDir = '.\\latest_netcdf_files';
  }
}
#Check to see if the directory we want to save the NetCDF files in exists. If not, exit with an error.
if( ( -d "$strNetCDFDir" ) == 0 )
{
  die("ERROR: The directory: $strNetCDFDir does not exist. Create the directory with rwx priveledges and re-run script.\n" );
}

if( length( $strFetchLogDir ) == 0 )
{
  if( !MICROSOFT_PLATFORM )
  {
    $strFetchLogDir = './fetch_logs';
  }
  else
  {
    $strFetchLogDir = '.\\fetch_logs';
  }
}
#Check to see if the directory we want to save the NetCDF files in exists. If not, exit with an error.
if( ( -d "$strFetchLogDir" ) == 0 )
{
  die("ERROR: The directory: $strFetchLogDir does not exist. Create the directory with rwx priveledges and re-run script.\n" );
}

#if no file filter given, default to this for netcdfs.
if( length( $strFilter ) == 0 )
{
  $strFilter = "latest.nc|old.nc|OVW-QS-NRT-SECOOS102-.*.nc|Tot_PWSS.*";
}

my $bWriteObsKML = 0;
if( length( $strDirForObsKml ) != 0 )
{
  $bWriteObsKML = 1;
}

#DWR v1.1.0.0 6/2/2008
if( length( $strLastNTimeStamps ) == 0 )
{
  $strLastNTimeStamps = 0;
}

print( "Command Line Options: strURLControlFile = $strURLControlFile strFilter = $strFilter strDirForObsKml = $strDirForObsKml strDelete = $strDelete strNetCDFDir = $strNetCDFDir strFetchLogDir = $strFetchLogDir UseLastNTimeStamps = $strLastNTimeStamps UseLastNTimeStampsForOrg=$strLastNTimeStampsPerOrg\n" );

# qs needs its own individual cycle
#my $qs_only = @ARGV[0];

my $strStartTime = `date +%s`;
print( "Start Time: $strStartTime\n" );


#DWR v1.1.0.0
#Remove the conversion log. We do this since the log gets concatenated every run, so it will get huge fast.
#We just keep the log of the last run.
if( !MICROSOFT_PLATFORM )
{
  my $cmd = "rm /home/dramage/log/cdl_0master.log";
  print( "Remove Log: $cmd\n" );
  `$cmd`;      
  #Open up a new log file.
  $cmd = "echo cdl_0master log opened >> /home/dramage/log/cdl_0master.log";
  `$cmd`;
}

my $bProcessNetCDF = 0;
my $XMLObj = XML::LibXML->new->parse_file($strURLControlFile);
#Loop through the urls.
foreach my $URLList ($XMLObj->findnodes('//URLList'))
{
  foreach my $URL ($URLList->findnodes('URL'))
  {
    my $this_dir_url = $URL->string_value();;
    print('-------------------------------------------------------------------------------------------------'."\n" );
    print( "NetCDF Source URL: $this_dir_url\n" );
    my @latest = get_index_match( $this_dir_url, $strFilter );
    foreach (@latest) 
    {
      my $latest_file = $_;
      my $strLatestFile;

      $strLatestFile = "$this_dir_url/$latest_file";

      my ($content_type, $document_length, $modified_time, $expires, $server) = head($strLatestFile);
      
      print( "File to check against cache: $latest_file\n" );
      my $latest_file_filter = $_;
      my $latest_file_filter =~ s/-/_/g;
      my $strSourceFile;
      my $strDestFile;
      my $strLogFile;
      $strSourceFile = "$this_dir_url/$latest_file";
      
      #DWR v1.1.1.0
      #Find the file extension.
      my $iPos = rindex( $latest_file, '.' );
      my $strFileName = $latest_file;
      if( $iPos != -1 )
      {
        $strFileName = substr( $latest_file, 0, $iPos );
      }
      if( !MICROSOFT_PLATFORM )
      {
        #my $strDate    = `date  +%Y%m%d%H%M%S`;
        #chomp( $strDate );
        #$strFileName   = $strFileName."-$strDate.nc";
        #$strDestFile   = "$strNetCDFDir/$strFileName";
        
        $strDestFile   = "$strNetCDFDir/$latest_file";
        $strLogFile    = "$strFetchLogDir//$latest_file";
      }
      else
      {
        #my $strDate    = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y%m%d%H%M%S`;
        #chomp( $strDate );
        #$strFileName   = $strFileName."-$strDate.nc";
        #$strDestFile   = "$strNetCDFDir\\$strFileName";
        
        $strDestFile   = "$strNetCDFDir\\$latest_file";
        $strLogFile    = "$strFetchLogDir\\$latest_file";
      }
      #print( "strDestFile = $strDestFile strLogFile = $strLogFile\n" );
      
      my $bDownloadFile = 0;
      if (open(LAST_FETCH,$strLogFile)) 
      {
        my $last_fetch_time = <LAST_FETCH>;
        chop($last_fetch_time);
        if ($modified_time > $last_fetch_time)
        {
          $bDownloadFile = 1;
          print( "\t".'File modified: Remote file mod time: '. scalar localtime( $modified_time ) .' Fetch log file: '.$strLogFile.' last modified on record  = '.scalar localtime($last_fetch_time)."\n" );       
        }
        else
        {
          print( "\t".'Fetch log file: '.$strLogFile.' last modified on record  = '.scalar localtime($last_fetch_time)."\n" );       
        }
      }
      else 
      {
        print( "\tUnable to open Fetch log file: $strLogFile.\n" );
        $bDownloadFile = 1;
      }
      if( $bDownloadFile )
      {
        my $RetVal = getstore($strSourceFile,$strDestFile);
        if( is_success($RetVal) )
        {        
          print( "\tDownloaded: $strSourceFile to $strDestFile\n" );
          if( $bWriteObsKML )
          {
            $bProcessNetCDF = 1;
          }
        }
        else
        {
          print( "ERROR: Fail Download: $strSourceFile to $strDestFile, Return Code: $RetVal\n" );
        }
      }
      else
      {
        print( "\tNot downloaded.\n" );
      }
      print( "\t".'File last modified = '.scalar localtime($modified_time)."\n" );
      my $cmd;
      if( !MICROSOFT_PLATFORM )
      {
        $cmd = "touch $strFetchLogDir/$latest_file";
      }
      else
      {
        $cmd = "\\UnixUtils\\usr\\local\\wbin\\touch $strFetchLogDir/$latest_file";
      }
      #print( "\tTouch: $cmd\n" );
      `$cmd`;
      if( !MICROSOFT_PLATFORM )
      {
        $cmd = "echo '$modified_time' > $strFetchLogDir/$latest_file";
      }
      else
      {
        $cmd = "\\UnixUtils\\usr\\local\\wbin\\echo '$modified_time' > $strFetchLogDir\\$latest_file";
      }
      `$cmd`;
      if( $bDownloadFile )
      {
        if( !MICROSOFT_PLATFORM )
        {
          #DWR v1.1.0.0 6/2/2008 
          #Added the passing of $strLastNTimeStamps onto the command line.
          $cmd = "cd /home/dramage/netcdf; /usr/bin/perl /home/dramage/netcdf/cdl_0master.pl $strDestFile 1 $strDirForObsKml $strLastNTimeStamps \"$strLastNTimeStampsPerOrg\" >> /home/dramage/log/cdl_0master.log 2>&1";
          print( "\tObsKML Script: $cmd\n" );
          `$cmd`;      
        }
        else
        {
        }
      }
    }
  }
}
if( $bProcessNetCDF )
{   
  #`cd /home/dramage; /home/dramage/netcdf/DirZip.sh $strDirForObsKml kml`
  my $strDirtoList;
  my @aFeedDirs; 
  if( !MICROSOFT_PLATFORM )
  { 
    $strDirtoList = $strDirForObsKml."/*";
    @aFeedDirs    = `ls -dq $strDirtoList`;
    
    #`cd /home/dramage; /home/dramage/netcdf/DirZip.sh $strDirForObsKml kml`
  }
  else
  {
    $strDirtoList = $strDirForObsKml."\\*";
    @aFeedDirs    = `\\UnixUtils\\usr\\local\\wbin\\ls -dq $strDirtoList`;
  }
  print( "\nNumber of directories to zip: ". @aFeedDirs . "\n" );
  foreach my $strDir (@aFeedDirs)
  {
    chomp( $strDir );
      
    my $iPos;
    if( !MICROSOFT_PLATFORM )
    { 
      #Get rid of KML files older than 4 hours.
      #print( "\tfind $strDir -maxdepth 1 -cmin +240 -exec rm -f {}\n");
      #`find $strDir -maxdepth 1 -cmin +240 -exec rm -f {} \;`;
      $iPos = rindex( $strDir, '/' );
      my $strDirName = $strDir;
      if( $iPos != -1 )
      {
        $strDirName = substr( $strDir, $iPos+1, length( $strDir ) );
      }
      my $strZipName = $strDir.'/'.$strDirName.'_latest_obskml.zip';
      print( "\tRemoving previous zip: $strZipName.\n");
      `rm $strZipName`;
      #print( "\tZipping: zip -j $strZipName $strDir/*.kml\n" ); 
      print( "\tcd $strDir ; find -iname \'*.kml\' | zip -j $strZipName -@\n" ); 
      `cd $strDir ; find -iname '*.kml' | zip -j $strZipName -@`;
      
      #`zip -j $strZipName $strDir/*.kml`;       
    }
    else
    {
      #Get rid of KML files older than 4 hours.
      #print( "\tfind $strDir -maxdepth 1 -cmin +240 -exec rm -f {}\n");
      #`\\UnixUtils\\usr\\local\\wbin\\find $strDir -maxdepth 1 -cmin +240 -exec rm -f {} \;`;
      $iPos = rindex( $strDir, '\\' );
      my $strDirName = $strDir;
      if( $iPos != -1 )
      {
        $strDirName = substr( $strDir, $iPos+1, length( $strDir ) );
      }
      my $strZipName = $strDir.'\\'.$strDirName.'_latest_obskml.zip';
      print( "\tRemoving previous zip: $strZipName.\n");
      `\\UnixUtils\\usr\\local\\wbin\\rm $strZipName`;
      print( "\tcd $strDir ; \\UnixUtils\\usr\\local\\wbin\\find -iname \'*.kml\' | zip -j $strZipName -@\n" );      
      #print( "\tZipping: zip -j $strZipName $strDir\\*.kml\n" );       
      `cd $strDir ; \\UnixUtils\\usr\\local\\wbin\\find -iname '*.kml' | zip -j $strZipName -@`;
      #`\\UnixUtils\\usr\\local\\wbin\\zip -j $strZipName $strDir\\*.kml`;       
    }
  }
  my $strEndTime = `date +%s`;
  print( "End Time: $strEndTime\n" );  
}

sub get_index_match {
# Processing:
#    (0) Get html document--no checking done to make sure this is an index
#            or that it's live and accessible.  (future upgrade?)
#    (1) Screen scrape http index listing sent by server for all HREF data
#    (2) further limit it by regexp match to pattern desired by user

    # add libraries needed for this function
    use LWP::Simple;
    
    # passed parameters
    my ($path, $pattern) = @_;

    # (0) Get html document
    my $doc = get($path);

    # (1) Screen scrape http for href lines
    my @all_href = $doc =~ m{href\s*=[\s|"]*(.*?)[\s|"]*>}gi;
  
    # (2) further limit with users pattern
    my @matched = grep /$pattern$/, @all_href;

    return @matched;
} 
# ----------------------------------------------------------------
