#!/usr/bin/perl

use strict;
use Net::Telnet;
use Getopt::Long;

use constant MICROSOFT_PLATFORM => 1;
if( !MICROSOFT_PLATFORM )
{
  require "./obsKMLSubRoutines.lib";
}
else
{
  require ".\\obsKMLSubRoutines.lib";  
}



my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "Host=s",
            "StationID=s",            
            "ControlFile=s"
             );

my $host_label      = $CommandLineOptions{"Host"};
my $station_id      = $CommandLineOptions{"StationID"};
my $strControlFile  = $CommandLineOptions{"ControlFile"}; 
if( length( $strControlFile ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --ControlFile\n". 
              "--ControlFile provides the XML file to be used to update the database.\n" );
}

my %PlatformIDHash;
LoadPlatformControlFile($strControlFile, \%PlatformIDHash, $station_id);

#my ($host_label, $station_id) = @ARGV;
my $host; 

my $sensor_id;
my $sensor_id_secondary;

#open (HOST_FILE, ">>telnet_host.txt");
my $date_now;
if( !MICROSOFT_PLATFORM )
{
  $date_now = `date`;
}
else
{
  $date_now = `\\UnixUtils\\usr\\local\\wbin\\date.exe`;
}

chomp($date_now);

#print HOST_FILE "\n$date_now ";
#print HOST_FILE "$host_label ";

#using dig to get around how slow our default DNS server is, not providing the correct recent DNS
#List of public DNS servers http://www.dns.net/dnsrd/tools.html
#this is an array list of public DNS servers - if one fails, it proceeds to the next one in the list until a successful lookup is found
my @public_dns = qw(86.64.145.140 212.30.96.108 195.154.223.1);

while (@public_dns) {
my $this_dns = shift @public_dns;
print "this_dns:$this_dns\n";
if ($host_label eq 'sunset.eairlink.com') 
{ 
  if( !MICROSOFT_PLATFORM )
  {
    $host = `dig +short \@$this_dns sunset.eairlink.com`;
  }
  else 
  {
    $host = `\\UnixUtils\\usr\\local\\wbin\\dig.exe +short \@$this_dns sunset.eairlink.com`;
  }
}
if ($host_label eq 'capers.eairlink.com') 
{ 
  if( !MICROSOFT_PLATFORM )
  {
    $host = `dig +short \@$this_dns capers.eairlink.com`;
  }
  else
  {
    $host = `\\UnixUtils\\usr\\local\\wbin\\dig.exe +short \@$this_dns capers.eairlink.com`; 
  }
}
if ($host_label eq 'fripps.eairlink.com')
{ 
  if( !MICROSOFT_PLATFORM )
  {
    $host = `dig +short \@$this_dns fripps.eairlink.com`;
  } 
  else
  {
    $host = `\\UnixUtils\\usr\\local\\wbin\\dig.exe +short \@$this_dns fripps.eairlink.com`;     
  }
}

chomp($host);
print $host."\n";

#if this host didn't time out (we got a result) exit the dns trial loop
if (!($host =~ /timed out/)) { last; }
}

#print HOST_FILE "$host\n";
#close (HOST_FILE);

my $telnet = new Net::Telnet (Timeout => 60, Errmode=>'return');

my $tries = 3;
while ($tries > 0) {
	print "connection try#:$tries\n";
	$telnet->open(Host => $host, Port => 12345);
	print $telnet->errmsg."\n";
	$tries--;
	if ($telnet->errmsg =~ /connect timed-out/) { next; } else { last; }
}

if ($telnet->errmsg) { exit 0; }

=comment
if ($host eq 'sunset.eairlink.com') {

	#$telnet->waitfor('/CONNECT/');
	#$telnet->print("");
	$telnet->waitfor('/Login user:/');	

}

else {

	$telnet->waitfor('/Bad/');
	$telnet->waitfor('/Bad/');

	my ($retval_prematch, $retval_match) = $telnet->waitfor(Match => '/Login user:/', Match => '/Flash Disk>/');

	print "retval_match:".$retval_match."\n";
	if ($retval_match eq 'Flash Disk>') {
		$telnet->print("exit");
		$telnet->waitfor('/Login user:/');	
	}
}
=cut

my ($retval_prematch, $retval_match) = $telnet->waitfor(Match => '/Login user:/', Match => '/Flash Disk>/');

print "retval_match:".$retval_match."\n";
if ($retval_match eq 'Flash Disk>') {
	$telnet->print("exit");
	$telnet->waitfor('/Login user:/');	
}

#$telnet->waitfor('/Login user:/');	
$telnet->print("p");

$telnet->waitfor('/Password:/');
$telnet->print("");

my $line;
my @line_array;

$telnet->getline; #blank line

$line = $telnet->getline;
print $line;
@line_array = split(/\s+/, $line);
my $actual_station_id = @line_array[1];
my $date = @line_array[2];
my $time = @line_array[3];

#added the following 3 lines to gaurantee that station reported is same as requested
if ($actual_station_id eq '86684981') { $station_id eq '8668498'; }
if ($actual_station_id eq '86649411') { $station_id eq '8664941'; }
if ($actual_station_id eq '86598971') { $station_id eq '8659897'; }

if ($station_id eq '8668498') { $sensor_id = 1; $sensor_id_secondary = 4; }
if ($station_id eq '8664941') { $sensor_id = 2; $sensor_id_secondary = 5; }
if ($station_id eq '8659897') { $sensor_id = 3; $sensor_id_secondary = 6; }

my $water_level = 'NULL';
my $water_level_secondary = 'NULL';
my $sigma = 'NULL';
my $wind_speed = 'NULL';
my $wind_speed_secondary = 'NULL';
my $wind_direction = 'NULL';
my $wind_direction_secondary = 'NULL';
my $wind_gust = 'NULL';
my $wind_gust_secondary = 'NULL';
my $air_temperature = 'NULL';
my $water_temperature = 'NULL';
my $air_pressure = 'NULL';
my $humidity = 'NULL';
my $battery = 'NULL';
my $battery_secondary = 'NULL';
my $nitrogen_pressure = 'NULL';
my $wl_c2 = 'NULL';
my $wl_c1 = 'NULL';

while (process_line()) {} ;

#water level is actual not MLLW
if ($water_level ne 'NULL' && $wl_c2 ne 'NULL' && $wl_c1 ne 'NULL') {
	$water_level = sprintf("%.3f", $wl_c2 - $wl_c1 - $water_level); 
}

print "parsed\n";

my $datetime = $date." ".$time;

print "datetime:".$datetime."\n";
print "water_level:".$water_level."\n";
print "water_level_secondary:".$water_level_secondary."\n";
print "wind_speed:".$wind_speed."\n";
print "wind_speed_secondary:".$wind_speed_secondary."\n";
print "wind_direction:".$wind_direction."\n";
print "wind_direction_secondary:".$wind_direction_secondary."\n";
print "wind_gust:".$wind_gust."\n";
print "wind_gust_secondary:".$wind_gust_secondary."\n";
print "air_temperature:".$air_temperature."\n";
print "water_temperature:".$water_temperature."\n";
print "air_pressure:".$air_pressure."\n";
print "humidity:".$humidity."\n";
print "battery:".$battery."\n";
print "battery_secondary:".$battery_secondary."\n";
print "nitrogen_pressure:".$nitrogen_pressure."\n";
print "wl_c2:".$wl_c2."\n";
print "wl_c1:".$wl_c1."\n";



my $strPlatformControlFile = undef;
if( !MICROSOFT_PLATFORM )
{
  $strPlatformControlFile = './PlatformIDControlFile.xml';
}
else
{
  $strPlatformControlFile = "C:\\Documents and Settings\\dramage\\workspace\\TelemetryDataToObsKML\\PlatformIDControlFile.xml";
}

#Format a DB friendly DB date-time.
my $strDBDate;
my $iM = index( $date, '/');
my $iD = index( $date, '/', $iM );
my $iY = index( $date, '/', $iD);

$strDBDate = substr( $date, $iY + $iM + $iD );
$strDBDate = $strDBDate.'-'.substr( $date, 0, 2 );
$strDBDate = $strDBDate.'-'.substr( $date, $iM + 1, 2 );

$strDBDate = $strDBDate.'T'.$time;



#Find the platform ID and URL.
my $strPlatformID = $station_id;

my $strPlatformURL = '';
my $rPlatformIDHash = \%PlatformIDHash;  
my %ObsHash;
my $rObsHash = \%ObsHash;

my %PlatformObsSettings;

GetPlatformData( \%PlatformIDHash, $station_id, \%PlatformObsSettings );
$strPlatformID = %PlatformObsSettings->{PlatformID};

KMLAddPlatformHashEntry( %PlatformObsSettings->{PlatformID}, %PlatformObsSettings->{PlatformURL}, '', '', $rObsHash );
#( $strObsName, $strDate, $Value, $SensorSOrder, $rObsHash, $rPlatformControlFileInfo, $rPlatformObsSettings )
KMLAddObsHashEntry( 'water_level', $strDBDate, $water_level, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'wind_speed', $strDBDate, $wind_speed, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'wind_from_direction', $strDBDate, $wind_direction, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'wind_gust', $strDBDate, $wind_gust, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'air_temperature', $strDBDate, $air_temperature, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'air_pressure', $strDBDate, $water_level, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );
KMLAddObsHashEntry( 'water_temperature', $strDBDate, $water_temperature, 1, $rObsHash, \%PlatformIDHash, \%PlatformObsSettings );

my $strXMLPath = ''; 
$strPlatformID =~ s/\./-/g; 
if( !MICROSOFT_PLATFORM )
{
  my $strDate = `date.exe  +%Y-%m-%dT%H-%M-%S`;
  $strXMLPath = "./$strPlatformID-$strDate.kml";
}
else
{
  my $strDate = `\\UnixUtils\\usr\\local\\wbin\\date.exe  +%Y-%m-%dT%H-%M-%S`;
  chomp( $strDate );      
  $strXMLPath = "C:\\Documents and Settings\\dramage\\workspace\\TelemetryDataToObsKML\\$strPlatformID-$strDate.xml"; 
}

BuildKMLFile( \%ObsHash, $strXMLPath, $strPlatformControlFile );

=comment
open(WLS_TMP, ">./wls.sql");

if ($water_level ne 'NULL') {
	#print WLS_TMP "INSERT INTO water_level (row_id,station,d,se,wl,sigma,o,f,r,t,l,entry_date,datetime,dat,sns,wl_secondary) VALUES (nextval('water_level_seq'),$station_id,1,'A1',$water_level,$sigma,0,0,0,0,0,now(),'$datetime',$wl_c2,$wl_c1,$water_level_secondary);\n"; 
	print WLS_TMP "UPDATE water_level set wl = $water_level, sigma = $sigma, update_date = now(), dat = $wl_c2, sns = $wl_c1, wl_secondary = $water_level_secondary where station = '$station_id' and datetime = '$datetime';\n"; 
}
if ($wind_speed ne 'NULL') {
	print WLS_TMP "INSERT INTO wind (row_id,station,d,se,ws,wd,wg,x,r,entry_date,datetime,sensor_id) VALUES (nextval('wind_seq'),$station_id,1,'C1',$wind_speed,$wind_direction,$wind_gust,0,0,now(),'$datetime',$sensor_id);\n"; 
}
if ($wind_speed_secondary ne 'NULL') {
	print WLS_TMP "INSERT INTO wind (row_id,station,d,se,ws,wd,wg,x,r,entry_date,datetime,sensor_id) VALUES (nextval('wind_seq'),$station_id,1,'C2',$wind_speed_secondary,$wind_direction_secondary,$wind_gust_secondary,0,0,now(),'$datetime',$sensor_id_secondary);\n"; 
}
if ($air_temperature ne 'NULL') {
	print WLS_TMP "INSERT INTO air_temperature (row_id,station,d,se,at,x,n,r,entry_date,datetime) VALUES (nextval('air_temperature_seq'),$station_id,1,'D1',$air_temperature,0,0,0,now(),'$datetime');\n"; 
}
if ($water_temperature ne 'NULL') {
	print WLS_TMP "INSERT INTO water_temperature (row_id,station,d,se,wt,x,n,r,entry_date,datetime) VALUES (nextval('water_temperature_seq'),$station_id,1,'E1',$water_temperature,0,0,0,now(),'$datetime');\n"; 
}
if ($air_pressure ne 'NULL') {
	print WLS_TMP "INSERT INTO barometric_pressure (row_id,station,d,se,bp,x,n,r,entry_date,datetime) VALUES (nextval('barometric_pressure_seq'),$station_id,1,'F1',$air_pressure,0,0,0,now(),'$datetime');\n"; 
}
if ($humidity ne 'NULL') {
	print WLS_TMP "INSERT INTO humidity (row_id,row_entry_date,row_update_date,station_id,measurement_date,measurement_value) VALUES (nextval('humidity_row_id_seq'),now(),now(),$station_id,'$datetime',$humidity);\n"; 
}

print WLS_TMP "INSERT INTO station (row_id,row_entry_date,row_update_date,station_id,last_reading,battery,nitrogen_pressure,battery_secondary) VALUES (nextval('station_row_id_seq'),now(),now(),$station_id,'$datetime',$battery,$nitrogen_pressure,$battery_secondary);\n"; 

close (WLS_TMP);
`/usr/local/pgsql/bin/psql -U postgres -d wls -f wls.sql`;
=cut

exit 0;

sub process_line {

$line = $telnet->getline;
print $line;
@line_array = split(/\s+/, $line);

if ($line =~ /Data flagged/) {
  return 1;
}

if (@line_array[0] eq 'B1') {
  $water_level_secondary = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'A1') {
  $water_level = @line_array[2];
  $sigma = @line_array[3];

  return 1;
}

if (@line_array[0] eq 'C1') {
	$wind_speed = @line_array[2];
	$wind_direction = @line_array[3];
	$wind_gust = @line_array[4];
	
  return 1;	
}

if (@line_array[0] eq 'C2') {
	$wind_speed_secondary = @line_array[2];
	$wind_direction_secondary = @line_array[3];
	$wind_gust_secondary = @line_array[4];
	
  return 1;	
}

if (@line_array[0] eq 'D1') {
	$air_temperature = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'E1') {
	$water_temperature = @line_array[2];

  return 1;
}
	
if (@line_array[0] eq 'F1') {
	$air_pressure = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'R1') {
	$humidity = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'L1') {
	$battery = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'L2') {
	$battery_secondary = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'M1') {
	$nitrogen_pressure = @line_array[2];

  return 1;
}

if (@line_array[0] eq 'DAT') {
	$wl_c2 = @line_array[1];

  return 1;
}

if (@line_array[0] eq 'SNS') {
	$wl_c1 = @line_array[1];

  return 1;
}

return 0;

}

