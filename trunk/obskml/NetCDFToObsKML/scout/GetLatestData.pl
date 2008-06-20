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
            "UseLastNTimeStamps:s"  #Optional. Integer representing the last N time entries to use when converting the data to obsKML. DWR v1.1.0.0 6/2/2008
             );

my $strURLControlFile  = $CommandLineOptions{"URLControlFile"}; 
my $strFilter          = $CommandLineOptions{"FileFilter"};
my $strDirForObsKml    = $CommandLineOptions{"DirForObsKml"}; 
my $strDelete          = $CommandLineOptions{"DeleteFiles"}; 
my $strNetCDFDir       = $CommandLineOptions{"NetCDFDir"};
my $strFetchLogDir     = $CommandLineOptions{"FetchLogDir"};
my $strLastNTimeStamps   = $CommandLineOptions{"UseLastNTimeStamps"}; #DWR v1.1.0.0 6/2/2008
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
              "--UseLastNTimeStamps Integer representing the last N time entries to use when converting the data to obsKML. Optional.\n" );
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

print( "Command Line Options: strURLControlFile = $strURLControlFile strFilter = $strFilter strDirForObsKml = $strDirForObsKml strDelete = $strDelete strNetCDFDir = $strNetCDFDir strFetchLogDir = $strFetchLogDir UseLastNTimeStamps = $strLastNTimeStamps\n" );

# qs needs its own individual cycle
#my $qs_only = @ARGV[0];

#12/5/05 Payne Seal changed all http://nccoos.unc.edu to http://nemo.isis.unc.edu per Sara Haines
#April 9, 2008 Jeremy Cothran changed all http://nemo.isis.unc.edu to http://whewell.marine.unc.edu per Jesse Cleary

=comment
if (length($qs_only) <= 0) {
  @dir_urls = (
    ##'http://nccoos.unc.edu/data/nos/proc_data/latest_v2.0'
    #'http://carocoops.org/~mkanoth/seacoos_netcdf/'
    #,'http://whewell.marine.unc.edu/data/nos/proc_data/latest_v2.0/'
    'http://seacoos.skio.peachnet.edu/proc_data/latest_v2.0'
    ##,'http://nccoos.unc.edu/data/nws_metar/proc_data/latest_v2.0'
    ,'http://whewell.marine.unc.edu/data/nws_metar/proc_data/latest_v2.0/'
    #,'http://trident.baruch.sc.edu/usgs_data'
    #,'http://trident.baruch.sc.edu/storm_surge_data/latest'
    #,'http://trident.baruch.sc.edu/storm_surge_data/netcdf_latest'
    ,'http://seacoos.marine.usf.edu/data/seacoos_rt_v2'
    #,'http://oceanlab.rsmas.miami.edu/ELWX5/v2'
    #,'http://aigeann.ucsc.edu/cimtLatest'
    ##,'http://nccoos.unc.edu/data/nc-coos/latest_v2.0'
    #,'http://nemo.isis.unc.edu/data/nc-coos/latest_v2.0/' #nccoos hf radar
    ##,'http://iwave.rsmas.miami.edu/wera/efs/data'
    #,'http://oceanlab.rsmas.miami.edu/wera' #miami hf radar
    ##,'http://ak.aoos.org/seacoos/codar'
    ,'http://www.cormp.org/data'
    ##'http://www.cormp.org/data'
  );
}
else {
  @dir_urls = (
   #'http://trident.baruch.sc.edu/po.daac_data/OVW'
  );
  $qs_prefix = 'qs_';
}
=cut

#DWR v1.1.0.0
#Remove the conversion log. We do this since the log gets concatenated every run, so it will get huge fast.
#We just keep the log of the last run.
if( !MICROSOFT_PLATFORM )
{
  my $cmd = "rm /home/dramage/log/cdl_0master.log";
  print( "Remove Log: $cmd\n" );
  `$cmd`;      
  #Open up a new log file.
  $cmd = "echo cdl_0master log opened > /home/dramage/log/cdl_0master.log";
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
    
    print "$this_dir_url\n";
    my @latest = get_index_match( $this_dir_url, $strFilter );
    foreach (@latest) 
    {
      my $latest_file = $_;
      my $strLatestFile;
      if( !MICROSOFT_PLATFORM )
      {
        $strLatestFile = "$this_dir_url/$latest_file"
      }
      else
      {
        $strLatestFile = "$this_dir_url\\$latest_file"
      }
      my ($content_type, $document_length, $modified_time, $expires, $server) = head($strLatestFile);
      
      print "  $latest_file\n     ";
      my $latest_file_filter = $_;
      my $latest_file_filter =~ s/-/_/g;
      my $strSourceFile;
      my $strDestFile;
      my $strLogFile;
      $strSourceFile = "$this_dir_url/$latest_file";
      if( !MICROSOFT_PLATFORM )
      {
        $strDestFile   = "$strNetCDFDir/$latest_file";
        $strLogFile    = "$strFetchLogDir/$latest_file";
      }
      else
      {
        $strDestFile   = "$strNetCDFDir\\$latest_file";
        $strLogFile    = "$strFetchLogDir\\$latest_file";
      }
      print( "strDestFile = $strDestFile strLogFile = $strLogFile\n" );
      
      my $bDownloadFile = 0;
      if (open(LAST_FETCH,$strLogFile)) 
      {
        my $last_fetch_time = <LAST_FETCH>;
        print 'file last modified on record  = '.scalar localtime($last_fetch_time)."\n     ";
        chop($last_fetch_time);
        if ($modified_time > $last_fetch_time)
        {
          $bDownloadFile = 1;
        }
      }
      else 
      {
        $bDownloadFile = 1;
      }
      if( $bDownloadFile )
      {
        my $RetVal = getstore($strSourceFile,$strDestFile);
        if( is_success($RetVal) )
        {        
          print "Downloaded: $strSourceFile to $strDestFile";
          if( $bWriteObsKML )
          {
            $bProcessNetCDF = 1;
          }
        }
        else
        {
          print "ERROR: Fail Download: $strSourceFile to $strDestFile, Return Code: $RetVal";
        }
      }
      print "\n     ".'file last modified            = '.scalar localtime($modified_time)."\n";
      my $cmd;
      if( !MICROSOFT_PLATFORM )
      {
        $cmd = "touch $strFetchLogDir/$latest_file";
      }
      else
      {
        $cmd = "\\UnixUtils\\usr\\local\\wbin\\touch $strFetchLogDir/$latest_file";
      }
      print( "Touch: $cmd\n" );
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
      if( $bProcessNetCDF )
      {
        if( !MICROSOFT_PLATFORM )
        {
          #DWR v1.1.0.0 6/2/2008 
          #Added the passing of $strLastNTimeStamps onto the command line.
          $cmd = "cd /home/dramage/netcdf; /usr/bin/perl /home/dramage/netcdf/cdl_0master.pl $strDestFile 1 $strDirForObsKml $strLastNTimeStamps >> /home/dramage/log/cdl_0master.log 2>&1";
          print( "ObsKML Script: $cmd\n" );
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
  if( !MICROSOFT_PLATFORM )
  {
    `cd /home/dramage; /home/dramage/DirZip.sh $strDirForObsKml kml >> GetLatestData.log 2>&1`
  }
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
