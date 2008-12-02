###############################################################################
# Revisions
# Rev: 1.3.1.0
# Module: fixed_profiler
# Sunroutine: ProcessADCPVar
# Changes: Compare the data value to the missing value or fill value so we can correctly handle those cases.
# Subroutine:ProcessVar
# Changes: If the measurement is either water_depth or water_level, we handle their elevation differently.

# Rev: 1.3.0.0
# Author: DWR
# Subroutine: fixed_point
# Changes: Added in the eastward_current variable for the obskml.
#          Convert the current_speed into cm_s-1 from m_s-1.
#          get_mag_dir changed the formatting from %d to %f.

# Rev: 1.2.0.0
# Author: DWR
# Changes: Added fixed-profiler processing via cdl_profiler_adcp.pl.
# Rev: 1.1.2.0
# Author: DWR
# Subroutine: fixed_point
# Changes: Removed the "!= ''" comparisons when dealing with numerics. Was causing values of 0 to be considered no good.
#
# Rev: 1.1.1.0
# Author: DWR
# Changes: Hardcoded air_pressure units to millibars.
# REv: 1.1.0.0
# Author: DWR
# Date: 6/2/2008
# Changes: Optional. Added command line argument LastNTimeStamps to allow the use of only the last N time stamps
# of the data.
# Author: DWR
# Date: 4/18/2008
# Changes: Added "use lib ./" to force perl to look in the working dir for packages.
#
# Date: 4/7/2008
# CHanges: Added the ability to turn on the writing of an obsKml file. 
# The script now takes 2 optional command line arguments.
# The 2nd command line argument is which file(s) to create. The following values are defined:
# 0 = default value which only produces the orignal sql files.
# 1 = Writes only an obsKML file
# 2 = Writes both the sql files and obsKML file.
# The 3rd command line argument specifies what directory to create the obsKML file in. 
# The directory must already exist.
#
# THis script now uses the obsKMLSubRoutines package to create the obsKML file. For now, make sure this
# package is in the same directory as this script or in a directory which is in the Perl path.
################################################################################
#!/bin/perl

#use strict;
#use warnings;

use lib "./";

use NetCDF;
use UDUNITS;
use Time::Local;
use obsKMLSubRoutines;
use Math::Trig;

use constant USE_DEBUG_PRINTS => 1;

#DWR 4/7/2008 Added constants for use with ARGV[1] to tell us what file(s) to write.
use constant {
  DEFAULTWRITESQLONLY      => 0,
  WRITEKMLONLY             => 1,
  WRITEBOTH                => 2
};

#
# includes
do 'cdl_fixed_point.pl';
do 'cdl_moving_point.pl';
do 'cdl_grid.pl';
do 'cdl_grid_jpl.pl';
do 'cdl_fixed_map.pl';
do 'cdl_fixed_profile_adcp.pl';
do 'cdl_profiler_adcp.pl';

# oldest incoming time stamp tolerated (14 days)
$oldest_ok_timestamp = time() - 60 * 60 * 24 * 14;

# where the latest obs timestamps are
#$latest_obs_by_station_id_dir = '/home/scscout/sc/obs/2.0/latest_obs_by_station_id';
$latest_obs_by_station_id_dir = '/home/dramage/netcdf/fetch_logs';

#
# udunits initialization

UDUNITS::init("/usr/local/lib/perl/5.8.8/udunits/udunits-1.12.4/etc/udunits.dat") == 0 
  || die "ABORT! Cannot initialize udunits.\n";

#
# command line arguments

# filename
$net_cdf_file = @ARGV[0];

#DWR 4/7/2008
#Optional file creation arguments
my $FileCreationOption = 0;
my $strObsKMLFilePath;
my $iLastNTimeStamps = 0;
if( @ARGV == 0 )
{
  die( "ERROR: Missing command line arguments. Ths script uses the following command line parameters:\n".
       "Parameter 0 is the netcdf filename to process.\n".
       "Parameter 1 is an optional parameter. Valid values are: 0 Write only SQL files, 1 Write only obsKML file, or 2 Write both SQL files and obsKML file. Default value is 0.\n".
       "Parameter 2 is the directory where the obsKML file is stored. If not provided the default directory is the current directory.\n".
       "Parameter 3 is the optional number of last N time stamps to use.\n" .
       "Parameter 4 is the option organization/last N time stamps to use for organization. Format is \"Org1;NTimes,Org2,NTimes\"\n"
     );
}
if( @ARGV > 1 )
{
  $strObsKMLFilePath = './'; 
  if( @ARGV[1] >= DEFAULTWRITESQLONLY && @ARGV[1] <= WRITEBOTH )
  {
  $FileCreationOption = @ARGV[1];
  }
  else
  { 
  print( "ERROR: Command line argument 2: @ARGV[1] not valid\n. Valid values are: 0 Write only SQL files\n 1: Write only obsKML file\n or 2: Write both SQL files and obsKML file.\nDefault value will be 0.\n" );
  }  
  # 3rd command line argument is the path to store the obsKML files.
  if( @ARGV >= 3 )
  {
    $strObsKMLFilePath = @ARGV[2];
  }
  if( @ARGV >= 4 )
  {
    $iLastNTimeStamps = @ARGV[3];
  }
  #DWR v1.2.0.0 9/17/2008
  if( @ARGV >= 5 )
  {
    $strLastNTimeStampsPerOrg = @ARGV[4];
  }
}
 
#DWR v1.2.0.0 9/17/2008
my %UpdatePerOrg;
my $refUpdatePerOrg = \%UpdatePerOrg;
if( length( $strLastNTimeStampsPerOrg ) )
{ 
  my @OrgList = split( /\,/, $strLastNTimeStampsPerOrg );
  foreach my $Org (@OrgList)
  {
    my @Data = split( /\;/, $Org );
    $refUpdatePerOrg->{@Data[0]} = @Data[1];
    print( "Org: @Data[0] LastNUpdates: @Data[1]\n" );
  }
}

print( "---------------------------------------------------------------------------------------------------------\n" );
print( "Command Line Args: net_cdf_file: $net_cdf_file FileType=$FileCreationOption ObsKMLPath=$strObsKMLFilePath LastNTimes=$iLastNTimeStamps LastNTimeStampsPerOrg=$strLastNTimeStampsPerOrg LastNTimeStampsPerOrg=$strLastNTimeStampsPerOrg\n" );
my $strStartTime = `date +%s`;
print( "Start Time: $strStartTime\n" );
#
# Turn off fatal error aborts.  We need to allow some attributes to error out w/o crashing.
NetCDF::opts(VERBOSE) ;

#
# Throughout this .pl, declare variables thanks to . . .
#   For technical reasons, output variables must be initialized,
#   i.e.  any variable argument that is to have its value set by
#   a function must already have a value.

#
# Open the netCDF file

$ncid = NetCDF::open($net_cdf_file, NetCDF::READ);
if ($ncid < 0) {die "ABORT!  Cannot open netCDF file.\n";}

#
# General file query

$inquire = NetCDF::inquire($ncid,$ndims,$nvars,$natts,$recdim);
if ($inquire < 0) {die "ABORT!  Cannot query netCDF file.\n";}

#
# Get global attributes (optional, so don't fatal-error our)

$institution_code_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'institution_code',\$institution_code_value);
if (substr($institution_code_value,length($institution_code_value)-1) eq chr(0)) {chop($institution_code_value);}
$platform_code_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'platform_code',\$platform_code_value);
if (substr($platform_code_value,length($platform_code_value)-1) eq chr(0)) {chop($platform_code_value);}
$package_code_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'package_code',\$package_code_value);
if (substr($package_code_value,length($package_code_value)-1) eq chr(0)) {chop($package_code_value);}
$title_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'title',\$title_value);
if (substr($title_value,length($title_value)-1) eq chr(0)) {chop($title_value);}
$institution_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'institution',\$institution_value);
if (substr($institution_value,length($institution_value)-1) eq chr(0)) {chop($institution_value);}
$institution_url_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'institution_url',\$institution_url_value);
if (substr($institution_url_value,length($institution_url_value)-1) eq chr(0)) {chop($institution_url_value);}
$institution_dods_url_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'institution_dods_url',\$institution_dods_url_value);
if (substr($institution_dods_url_value,length($institution_dods_url_value)-1) eq chr(0)) {chop($institution_dods_url_value);}
$source_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'source',\$source_value);
if (substr($source_value,length($source_value)-1) eq chr(0)) {chop($source_value);}
$references_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'references',\$references_value);
if (substr($references_value,length($references_value)-1) eq chr(0)) {chop($references_value);}
$contact_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'contact',\$contact_value);
if (substr($contact_value,length($contact_value)-1) eq chr(0)) {chop($contact_value);}
$missing_value_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'missing_value',\$missing_value_value);
if (substr($contact_value,length($contact_value)-1) eq chr(0)) {chop($contact_value);}
if (substr($missing_value_value,length($missing_value_value)-1) eq chr(0)) {chop($missing_value_value);}
if (length $missing_value_value <= 0) {
  $missing_value_value = -999999999;
}
$Fill_value_value = '';
$attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'_FillValue',\$Fill_value_value);
if (substr($Fill_value_value,length($Fill_value_value)-1) eq chr(0)) {chop($Fill_value_value);}
if (length $Fill_value_value <= 0) {
  $Fill_value_value = -999999999;
}

#
# Determine which sea-coos netCDF format we're using

# special case for PODAAC data = make one up
if ($institution_value =~ /JPL/ && $platform_code_value ne 'ak_jpl_quikscat') {
  $format_category_value = 'jpl_grid';
}
else {
  $format_category_value = '';
  $attget = NetCDF::attget($ncid,NetCDF::GLOBAL,'format_category_code',\$format_category_value);
  if ($attget < 0) {die "ABORT!  Cannot get format_category_code.\n";}
  if (substr($format_category_value,length($format_category_value)-1) eq chr(0)) {chop($format_category_value);}
}
# Check for supported types
if (!($format_category_value eq 'fixed-point')
  && !($format_category_value eq 'moving-point-2D')
  && !($format_category_value eq 'Seacoos_grid')
  && !($format_category_value eq 'jpl_grid')
  && !($format_category_value eq 'fixed-map')
  && !($format_category_value eq 'fixed-profiler')) {die "ABORT! $format_category_value is not a supported format.\n";}

# get latest timestamp for this station_id if there is one
$this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
#print( "$latest_obs_by_station_id_dir.'/'.$this_station_id\n" );
open (TS, $latest_obs_by_station_id_dir.'/'.$this_station_id);
while (<TS>) {
  $this_station_id_top_ts = $_;
}
close (TS);

#
# go to correct data scout method

if ($format_category_value eq 'fixed-point') {
  #DWR 4/7/2008
  #Check to see if the institution specific directory exists.
  my $strObsKMLDir = "$strObsKMLFilePath/$institution_code_value";
  if( ( -d "$strObsKMLFilePath/$institution_code_value" ) == 0 )
  {
    if( mkdir( "$strObsKMLFilePath/$institution_code_value", 0777 ) == 0 )
    {
      print( "ERROR::Unable to create directory: $strObsKMLFilePath/$institution_code_value.\n" );
      $strObsKMLDir = $strObsKMLFilePath;
    }
    else
    {
      $strObsKMLDir = "$strObsKMLFilePath/$institution_code_value";
      print( "Created directory: $strObsKMLDir\n" );
    }
  } 
  
  #DWR v1.2.0.0 9/17/2008
  #Are we using per organization last N time stamps? If so see if this org is in the list.
  if( length( $strLastNTimeStampsPerOrg ) )
  {
    print( "Org code: $institution_code_value\n" );
    my $iNTimeStamps = -1;
    if( exists $refUpdatePerOrg->{$institution_code_value} )
    {
      $iNTimeStamps = $refUpdatePerOrg->{$institution_code_value};
      $iLastNTimeStamps = $iNTimeStamps;
      print( "LastNTimeStamps: $iLastNTimeStamps\n" );
    }    
  }
  fixed_point($this_station_id_top_ts, $FileCreationOption, $strObsKMLDir, $iLastNTimeStamps );
}
elsif( $format_category_value eq 'fixed-profiler')
{
  my $strObsKMLDir = "$strObsKMLFilePath/profiler";
  #For now we only put carocoops and nccoos profile data into directorys to get pulled for processing.
  if( $institution_code_value eq 'carocoops' || 
      $institution_code_value eq 'nccoos' )
  {
    $strObsKMLDir = "$strObsKMLFilePath/$institution_code_value";
  }
  #Check to see if the institution specific directory exists.
  if( ( -d "$strObsKMLDir" ) == 0 )
  {
    if( mkdir( "$strObsKMLDir", 0777 ) == 0 )
    {
      print( "ERROR::Unable to create directory: $strObsKMLDir.\n" );
      $strObsKMLDir = $strObsKMLFilePath;
    }
    else
    {
      print( "Created directory: $strObsKMLDir\n" );
    }
  } 
  #Are we using per organization last N time stamps? If so see if this org is in the list.
  if( length( $strLastNTimeStampsPerOrg ) )
  {
    print( "Org code: $institution_code_value\n" );
    my $iNTimeStamps = -1;
    if( exists $refUpdatePerOrg->{$institution_code_value} )
    {
      $iNTimeStamps = $refUpdatePerOrg->{$institution_code_value};
      $iLastNTimeStamps = $iNTimeStamps;
      print( "LastNTimeStamps: $iLastNTimeStamps\n" );
    }    
  }
  fixed_profiler($this_station_id_top_ts, $FileCreationOption, $strObsKMLDir, $iLastNTimeStamps );
}
elsif ($format_category_value eq 'moving-point-2D') {
  moving_point();
}
elsif ($format_category_value eq 'Seacoos_grid') {
  grid();
}
elsif ($format_category_value eq 'jpl_grid') {
  grid_jpl();
}
elsif ($format_category_value eq 'fixed-map') {
  fixed_map();
}

my $strEndTime = `date +%s`;
print( "End Time: $strEndTime\n" );

