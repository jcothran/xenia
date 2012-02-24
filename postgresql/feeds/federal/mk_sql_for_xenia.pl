#!/usr/bin/perl

use lib '/home/xeniaprod/scripts/postgresql/feeds/federal';
#use lib "C:\\Documents and Settings\\dramage\\workspace\\SVNSandbox\\xenia\\postgresql\\feeds\\federal";

use strict;
use ObsUtils;
#use SiteUtils;
#use XML::XPath;
use DBI;
use Config::IniFiles;

my $target_obs = $ARGV[0];

my %local_setup;
my (@stations);

my $start_time=time();

my $cfg=Config::IniFiles->new( -file => '/home/xeniaprod/scripts/postgresql/feeds/federal/dbConfig.ini');
#my $cfg=Config::IniFiles->new( -file => 'C:\\Documents and Settings\\dramage\\workspace\\SVNSandbox\\xenia\\postgresql\\feeds\\federal\\dbConfig.ini');
my $db_name=$cfg->val('rcoos','database');
my $db_user=$cfg->val('rcoos','username');
my $db_passwd=$cfg->val('rcoos','password');

my $sqlFilename = $ARGV[2];

# Target INSERT SQL.
my $insert_sql = "INSERT INTO multi_obs ("
  ." row_entry_date"
  .",row_update_date"
  .",platform_handle"
  .",sensor_id"
  .",m_type_id"
  .",m_date"
  .",m_lon"
  .",m_lat"
  .",m_z"
  .",m_value"
  .") VALUES";

		
#my $dbh = DBI->connect ("dbi:PgPP:dbname=$db_name;host=129.252.37.90","$db_user","$db_passwd");
my $dbh = DBI->connect ("dbi:Pg:dbname=$db_name","$db_user","$db_passwd");
if (!defined $dbh) {die "Cannot connect to database! Database: $db_name User: $db_user\n";}

# The SQL that will give us all the hash->DB lookups we'll need.

my $sql = "SELECT 
   platform.platform_handle
  ,platform.short_name
  ,case when platform.fixed_longitude is null then -99999 else platform.fixed_longitude end
  ,case when platform.fixed_latitude is null then -99999 else platform.fixed_latitude end
  ,case when sensor.fixed_z is null then -99999 else sensor.fixed_z end
  ,sensor.short_name
  ,sensor.row_id
  ,sensor.m_type_id
FROM 
     platform 
     left JOIN sensor
     ON platform.row_id = sensor.platform_id
     left JOIN organization
     on organization.row_id=platform.organization_id  
where organization.short_name='$target_obs'
ORDER BY
   platform.platform_handle
  ,sensor.short_name;";

my $sth = $dbh->prepare($sql);
#print( "$sql\n" );
$sth->execute();

my ($platform_platform_handle,$platform_name,$platform_fixed_longitude,$platform_fixed_latitude,$sensor_fixed_z,$sensor_short_name,$sensor_row_id,$sensor_m_type_id);
$sth -> bind_columns(undef,\$platform_platform_handle,\$platform_name,\$platform_fixed_longitude,\$platform_fixed_latitude,\$sensor_fixed_z,\$sensor_short_name,\$sensor_row_id,\$sensor_m_type_id);
my $curplatform = '';
while (my @row = $sth->fetchrow()) {
  if(!grep $_ eq $platform_platform_handle."|".$platform_name,@stations){
      push(@stations,$platform_platform_handle."|".$platform_name);
  }
  $local_setup{$platform_platform_handle}{$sensor_short_name}{sensor_row_id}            = $sensor_row_id;
  $local_setup{$platform_platform_handle}{$sensor_short_name}{sensor_m_type_id}         = $sensor_m_type_id;
  $local_setup{$platform_platform_handle}{$sensor_short_name}{sensor_fixed_z}           = $sensor_fixed_z;
  $local_setup{$platform_platform_handle}{$sensor_short_name}{platform_fixed_longitude} = $platform_fixed_longitude;
  $local_setup{$platform_platform_handle}{$sensor_short_name}{platform_fixed_latitude}  = $platform_fixed_latitude;
    
  print( "$platform_platform_handle $sensor_short_name $sensor_row_id $sensor_m_type_id $sensor_fixed_z $platform_fixed_longitude $platform_fixed_latitude\n" );
}
$sth->finish;
$dbh->disconnect();

##############
# Go get 'em!
##############

my %obs = %{eval('&ObsUtils::get_'.$target_obs.'_obs(@stations)')};

#############################################################################################
# Make SQL!
#############################################################################################
my $sqlFile;
if( !open( $sqlFile, ">$sqlFilename" ) )
{
  die("Unable to open SQL File: $sqlFilename\n" );
}
print( "Opened SQL File: $sqlFilename\n" );
foreach my $station (keys %obs) {
  my %o = %{$obs{$station}};
  foreach my $date (keys %o) {
    foreach my $c (keys %{$local_setup{$station}}) {
      print("$c\n");
      if (defined($obs{$station}{$date}{$c}) && $c ne 'time_stamp_utc') {
        my $sql = "$insert_sql ("
          . "now()"
          .",now()"
          .",'$station'"
          .",$local_setup{$station}{$c}{'sensor_row_id'}"
          .",$local_setup{$station}{$c}{'sensor_m_type_id'}"
          .",timestamp without time zone '".substr($date,0,length($date)-1)."'"
          .",$local_setup{$station}{$c}{'platform_fixed_longitude'}"
          .",$local_setup{$station}{$c}{'platform_fixed_latitude'}"
          .",$local_setup{$station}{$c}{'sensor_fixed_z'}"
          .",$obs{$station}{$date}{$c}"
          .");\n";
        #print "--\n-- $station $c\n$sql";
        print $sqlFile $sql;
          
      }
    }
  }
}
close($sqlFile);

print "\n-- TOTAL ELAPSED RUN TIME    ".(time() - $start_time)."\n";
