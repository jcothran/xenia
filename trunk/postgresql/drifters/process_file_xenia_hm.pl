#!/usr/bin/perl 

use DBI;

my $datafile = $ARGV[0];

$target_dir = '/home/jcleary/drifter/';

#$target_file = "$target_dir/hm_particles".time().rand();
$target_file = "$target_dir/test";
open(SQL_FILE,">$target_file");

my $db_host  = 'coriolis.marine.unc.edu';
my $db_name   = 'db_xenia_v2';
my $db_user   = 'jcleary';
my $db_passwd = '';

my ($dbh,$sth);
$dbh = DBI->connect ("dbi:Pg:dbname=$db_name;host=$db_host","$db_user","$db_passwd");
if(!defined $dbh) {die "Cannot connect to database!\n";}

my $organization_name = 'horizon_marine';
my $organization_id = 1;

open(DAT, $datafile);

while (<DAT>) {
  if ($_ =~ /^(\d+):/) {
#    print $_;
    @fields = split(" ", $_);
    # take off the colon following the drifter #
    $fields[0] =~ s/\://;

##################################

    my $m_type_id = 41; #m_type_id for drifter position info

    #check to see if particle_id is already listed in the platform:short_name 
    my $sql = qq{ SELECT row_id from platform where organization_id = $organization_id and short_name = '$fields[0]' };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($platform_id) = $sth->fetchrow_array;
    #print "platform_id:$platform_id\n";

    if (!($platform_id)) {
	#print "no id\n";

	#insert platform_id	
	my $platform_type_id = 1;
	my $sql = qq{ INSERT INTO platform (organization_id,type_id,short_name,platform_handle) VALUES ($organization_id,$platform_type_id,'$fields[0]','$organization_name:$fields[0]:drifter') };
	$sth = $dbh->prepare( $sql );
	$sth->execute();

	#get the platform_id we just inserted 
	my $sql = qq{ SELECT row_id from platform where organization_id = $organization_id and short_name = '$fields[0]' };
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	($platform_id) = $sth->fetchrow_array;

	#insert sensor_id	
	my $sensor_type_id = 1;
	my $sensor_short_name = 'drifter';
	my $sql = qq{ INSERT INTO sensor (platform_id,type_id,short_name,m_type_id,s_order) VALUES ($platform_id,$sensor_type_id,'$sensor_short_name',$m_type_id,1) };
	$sth = $dbh->prepare( $sql );
	$sth->execute();
    }

    #get the sensor_id with the associated drifter
    my $sql = qq{ SELECT row_id from sensor where platform_id = $platform_id and m_type_id = $m_type_id };
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($sensor_id) = $sth->fetchrow_array;
    #print "sensor_id:$sensor_id\n";

##################################

    print SQL_FILE 'insert into multi_obs ('
      .'row_entry_date'
      .',platform_handle'
      .',sensor_id'
      .',m_type_id'
      .',m_date'
      .',m_value'
      .',m_value_2'
      .',m_value_3'
      .',m_value_4'
      .',m_lon'
      .',m_lat'
      .',m_z'
      .',the_geom'
      .',d_label_theta'
      .')'
      .' values ('
      .'now()'
      .",'$organization_name:$fields[0]:drifter'"
      .','.$sensor_id
      .','.$m_type_id
      .",timestamp without time zone '$fields[1] $fields[2]'"
      .','.$fields[7]
      .','.sprintf("%0.2f",($fields[7] * 2.237))
      .','.sprintf("%0.2f",($fields[7] * 1.944))
      .','.sprintf("%0.2f",($fields[8])) # Direction, from true North
      .','.$fields[4]
      .','.$fields[3]
      .',0'
      .",GeometryFromText('POINT("
      .$fields[4].' '.$fields[3]
      .")',-1)"
      .','.sprintf("%0.2f",-($fields[8])) # Direction for labels in MapServer
      .');';
    print SQL_FILE "\n";
  }
}

$sth->finish();
$dbh->disconnect();

$cmd = "/bin/sort -u $target_file > $target_file.sorted.sql";
`$cmd`;
