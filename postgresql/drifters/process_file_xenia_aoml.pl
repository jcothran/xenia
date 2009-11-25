#!/usr/bin/perl 

use DBI;
use XML::LibXML;
use Getopt::Long;
use POSIX qw(strftime);

my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "DataFile=s",
            "XMLConfigFile=s"
            );

if( length(%CommandLineOptions) < 3 )
{
  die("Command Line Options:\n--DataFile is the drifter text file to process.\n--XMLConfigFile is the configuration file.")
}
my $datafile = $CommandLineOptions{"DataFile"};
my $xmlConfigFile = $CommandLineOptions{"XMLConfigFile"};

$xmlCfg = XML::LibXML->new->parse_file($xmlConfigFile); 
my %envSettings;    
$envSettings{DBType}=$xmlCfg->findvalue('//Database/type');
if( $envSettings{DBType} eq 'sqlite' )
{
  $envSettings{DBName}=$xmlCfg->findvalue('//Database/name');
}
else
{
  $envSettings{DBName}=$xmlCfg->findvalue('//Database/name');
  $envSettings{DBUser}=$xmlCfg->findvalue('//Database/user');
  $envSettings{DBPwd}=$xmlCfg->findvalue('//Database/pwd');
}
my $target_dir = $xmlCfg->findvalue('//DestDir');

#my $datafile = $ARGV[0];


my $dbh;
if( $envSettings{DBType} eq 'sqlite' )
{
  $dbh = DBI->connect("dbi:SQLite:dbname=$envSettings{DBName}", "", "",
                        { RaiseError => 0, AutoCommit => 1 });
  if(!defined $dbh) 
  {
    die "ERROR: Cannot connect to database: $envSettings{DBName}\n";
  }
}
else
{
  $dbh = DBI->connect ("dbi:Pg:dbname=$envSettings{DBName}","$envSettings{DBUser}","$envSettings{DBPwd}");
  if (!defined $dbh)
  {
    die "Cannot connect to database: $EnvSettings{DBName}\n";
  }
}

#$target_dir = '/home/jcleary/drifter/';

#$target_file = "$target_dir/aoml_particles".time().rand();
$target_file = "$target_dir/aoml_drifter.sql";
open(SQL_FILE,">$target_file") || die( "Unable to open file: $target_file\n");

#my $db_host  = 'coriolis.marine.unc.edu';
#my $db_name   = 'db_xenia_v2';
#my $db_user   = 'jcleary';

#my ($dbh,$sth);
#$dbh = DBI->connect ("dbi:Pg:dbname=$db_name;host=$db_host","$db_user","");
#if(!defined $dbh) {die "Cannot connect to database!\n";}


my $organization_name = 'aoml';
my $organization_id;

open(DAT, $datafile) || die( "Unable to open file: $datafile\n");
my $lastPlatform;
my $sensor_id;

my $rowEntryDate = strftime( '%Y-%m-%dT%H:%M:%S', gmtime() );  

while (<DAT>) {
  if (!($_ =~ /^#/)) {
#    print $_;
    @fields = split(" ", $_);
    # take off the colon following the drifter #
    $fields[0] =~ s/\://;

##################################
    my $m_type_id = 41; #m_type_id for drifter position info
    if( $lastPlatform ne $fields[0] )
    {
      $lastPlatform = $fields[0];
      
      
      $organization_id = getOrganizationID( $dbh );
      #check to see if particle_id is already listed in the platform:short_name 
      my $sql = qq{ SELECT row_id from platform where organization_id = $organization_id and short_name = '$fields[0]' };
      #print $sql."\n";    
      $sth = $dbh->prepare( $sql );
      my $platform_id;
      if( defined $sth )
      {
        if( $sth->execute( ) )
        {
          $platform_id = $sth->fetchrow_array;
        }
        else
        {
          my $strErr = $sth->errstr;        
          die( "ERROR: $strErr\nSQL: $sql\n");
        }
      }
      else
      {
        die( "ERROR: Failed to prepare SQL: $sql\n");
      }  
      if (!($platform_id)) 
      {
      	#print "no platform id defined yet\n";
      
      	#insert platform_id	
      	my $platform_type_id = 1;
      	#my $sql = qq{ INSERT INTO platform (organization_id,type_id,short_name,platform_handle) VALUES ($organization_id,$platform_type_id,'$fields[0]','$organization_name:$fields[0]:drifter') };
      	my $sql = qq{ INSERT INTO platform (organization_id,short_name,platform_handle) VALUES ($organization_id,'$fields[0]','$organization_name.$fields[0].drifter') };
      	$sth = $dbh->prepare( $sql );
        if( defined $sth )
        {
          if( $sth->execute( ) )
          {    
          	#get the platform_id we just inserted 
          	my $sql = qq{ SELECT row_id from platform where organization_id = $organization_id and short_name = '$fields[0]' };
          	$sth = $dbh->prepare( $sql );
            if( defined $sth )
            {
              if( $sth->execute( ) )
              {
               $platform_id = $sth->fetchrow_array;
              }
              else
              {
                my $strErr = $sth->errstr;        
                die( "ERROR: $strErr\nSQL: $sql\n");
              }
            }
            else
            {
              die( "ERROR: Failed to prepare SQL: $sql\n");
            }
          
          	#insert sensor_id	
          	my $sensor_type_id = 1;
          	my $sensor_short_name = 'drifter';
          	#my $sql = qq{ INSERT INTO sensor (platform_id,type_id,short_name,m_type_id,s_order) VALUES ($platform_id,$sensor_type_id,'$sensor_short_name',$m_type_id,1) };
          	my $sql = qq{ INSERT INTO sensor (platform_id,short_name,m_type_id,s_order) VALUES ($platform_id,'$sensor_short_name',$m_type_id,1) };
          	$sth = $dbh->prepare( $sql );
            if( defined $sth )
            {
              if( !$sth->execute( ) )
              {
                my $strErr = $sth->errstr;        
                die( "ERROR: $strErr\nSQL: $sql\n");
              }
            }
            else
            {
              die( "ERROR: Failed to prepare SQL: $sql\n");
            }
          }
          else
          {
            my $strErr = $sth->errstr;        
            die( "ERROR: $strErr\nSQL: $sql\n");
          }        
        }
        else
        {
          die( "ERROR: Failed to prepare SQL: $sql\n");
        }      
      }
      print "platform_id:$platform_id\n";
  
      #get the sensor_id with the associated drifter
      my $sql = qq{ SELECT row_id from sensor where platform_id = $platform_id and m_type_id = $m_type_id };
      $sth = $dbh->prepare( $sql );
      if( defined $sth )
      {
        if( $sth->execute( ) )
        {
          $sensor_id = $sth->fetchrow_array;              
        }
        else
        {
          my $strErr = $sth->errstr;        
          die( "ERROR: $strErr\nSQL: $sql\n");
        }
      }
      else
      {
        die( "ERROR: Failed to prepare SQL: $sql\n");
      }
    }

##################################

    if ($fields[8] ne '-NaN') 
    {
      #print "sensor_id:$sensor_id\n";
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
        #.',d_label_theta'
        .')'
        .' values ('
        .'now()'
        .",'$organization_name.$fields[0].drifter'"
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
        #.','.sprintf("%0.2f",-($fields[8])) # Direction for labels in MapServer
        .');';
      print SQL_FILE "\n";
    }
  }
}

$sth->finish();
$dbh->disconnect();

sub getOrganizationID #()
{
  my ( $dbh ) = @_;
  my $id;
  #Check to see if aoml is in the organization table. In the platform table, organization_id is a foreign key
  #so if we are adding a new drifter, we also need to make sure aoml exists in the org table. For a new
  #database, this will just have to be done once.
  my $sql = "SELECT row_id from organization  
             WHERE short_name = 'aoml'";
  $sth = $dbh->prepare( $sql );
  if( defined $sth )
  {
    if( $sth->execute( ) )
    {
      $id = $sth->fetchrow_array;
      #Doesn't exist, so let's add it
      if( !$id )
      {
        $sql = "INSERT INTO organization 
               (row_entry_date,row_update_date,short_name,active,url)
               VALUES('$rowEntryDate','$rowEntryDate','aoml',1,'http:\/\/www.aoml.noaa.gov')";
        $sth = $dbh->prepare( $sql );
        if( defined $sth )
        {
          if( $sth->execute( ) )
          {
            my $sql = "SELECT row_id from organization  
                       WHERE short_name = 'aoml'";
            $sth = $dbh->prepare( $sql );
            if( defined $sth )
            {
              if( $sth->execute( ) )
              {
                $id = $sth->fetchrow_array;
              }
              else
              {
                my $strErr = $sth->errstr;        
                die( "ERROR: $strErr\nSQL: $sql\n");
              }
            }
            else
            {
              die( "ERROR: Failed to prepare SQL: $sql\n");
            }                                                  
          }
        }
        else
        {
          die( "ERROR: Failed to prepare SQL: $sql\n");
        }                                                              
      }
    }
    else
    {
      my $strErr = $sth->errstr;        
      die( "ERROR: $strErr\nSQL: $sql\n");
    }
  }
  else
  {
    die( "ERROR: Failed to prepare SQL: $sql\n");
  }
  return( $id )
}
#$cmd = "/bin/sort -u $target_file > $target_file.sorted.sql";
#`$cmd`;
