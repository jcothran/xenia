	######################################################################
	#   Last modified by Monisha Kanoth at Fri Apr 20 10:50:53 EDT 2007  #
	#  	Script that generates vector plots for adcps					 #
	#														             #
	######################################################################

#!/usr/bin/perl
use strict;
use diagnostics;
use DBI;
use XML::XPath;
use Getopt::Long;
use Time::Local;
use Math::Trig;

#use constant MICROSOFT_PLATFORM => 1;
	
	#perl adcp_vector_plot.pl --PlatformHandle "usf:C17:ADCP" --Date "2007-03-12 12:00:00" --ProcessId 10
	
	my %arguments;
	GetOptions(\%arguments,
	           "PlatformHandle=s",
	           "Date:s",
	           "ProcessId=i",
	           "size_x:f",
	           "size_y:f",
	           "title:s",
	           "RoundDepths:s",
             "TimeInterval:s" ); 
	my ($platform_handle,$date,$process_id);
	
	$platform_handle=$arguments{'PlatformHandle'};
	if (!defined $platform_handle)
	{
		die " No Platform Handle defined! \n";
	}	
	
	if( $arguments{'Date'} )
  { 
    $date=$arguments{'Date'};
  }			
	if( ! defined $arguments{'ProcessId'} )
	{
	  $process_id = 1;
	}
	else
	{	
	 $process_id=$arguments{'ProcessId'};
	}
	my $iRoundDepths = 0;
	if( defined( $arguments{'RoundDepths'} ))
	{
	  $iRoundDepths = $arguments{'RoundDepths'};
	}
	my $iTimeInterval = 24;
	if( defined( $arguments{'TimeInterval'} ))
	{
	  $iTimeInterval = $arguments{'TimeInterval'};
	}
  
	my $xp_env = XML::XPath->new(filename => 'plot_environment.xml');			
	my %env;
  $env{platform_handle}=$platform_handle;	
	$env{hostname} = $xp_env->findvalue('//DB/host');
	$env{db_name} = $xp_env->findvalue('//DB/db_name');
	$env{db_user} = $xp_env->findvalue('//DB/db_user');
	$env{db_passwd} = $xp_env->findvalue('//DB/db_passwd');
	
	$env{output_dir} = $xp_env->findvalue('//path/output_dir');	
	$env{no_img} = $xp_env->findvalue('//path/no_img');
	
  $env{log_dir} = $xp_env->findvalue('//path/log_dir');	
	my $iEnableLog = 0;
  my $LogFile;
	if( defined( $env{log_dir} ))
	{
    my $strLogFile = $env{log_dir} . "adcp_vector_plot.log";
	  $iEnableLog = 1;
    if( !open( $LogFile, ">$strLogFile" ) )
    {
      die( "ERROR: Unable to open log file: $strLogFile\n" );
    }
	}

  
	my $lc_platform_handle=lc($platform_handle);
	$lc_platform_handle=~s/:/_/g;
	
	#$env{time_interval} = $xp_env->findvalue('//platforms/'.$lc_platform_handle.'');
	$env{time_interval} = $iTimeInterval;
	
	if ($env{time_interval} eq '')
	{
	  $env{time_interval} =8;
  }	
	my $strFilename = $platform_handle;
	$strFilename =~ s/\./_/g;
  $strFilename .= '_graph.png';
	
	$env{data_file}=$env{output_dir}."adcp_data_file_$process_id.txt";	
	$env{data_file_1}=$env{output_dir}."adcp2_data_file_$process_id.txt";	
	#$env{img_path}=$env{output_dir}."graph_$process_id.png"; #path for graph
	$env{img_path}=$env{output_dir} . $strFilename; #path for graph
	$env{process_id}=$process_id;
	$env{graph_script}=$env{output_dir}."plot_graph_$process_id.script";			
	#print( "data_file: $env{data_file} data_file_1: $env{data_file_1} img_path: $env{img_path} process_id: $env{process_id} graph_script: $env{graph_script}\n" );
  
	if ($arguments{'size_x'}){ $env{size_x}=$arguments{'size_x'};}		
	if ($arguments{'size_y'}){ $env{size_y}=$arguments{'size_y'};}		
	if ($arguments{'title'}){ $env{title}=$arguments{'title'}; }	

  if( $iEnableLog )
  {
    print( $LogFile "platform_handle: $env{platform_handle}\nhostname: $env{hostname}\ndb_name: $env{db_name}\noutput_dir: $env{output_dir}\nno_img: $env{no_img}\n" );
    print( $LogFile "time_interval: $env{time_interval}\ndata_file: $env{data_file}\ndata_file_1: $env{data_file_1}\nimg_path: $env{img_path}\nprocess_id: $env{process_id}\ngraph_script: $env{graph_script}\nlog_dir: $env{log_dir}\n" );
	}
	my ($dbh,$sql,$sth,@row);		
	#$dbh = DBI->connect ( "dbi:Pg:dbname=$env{db_name};host=$env{hostname}", "$env{db_user}", "$env{db_passwd}");
  
  $dbh = DBI->connect("dbi:SQLite:dbname=$env{db_name}", "", "",
                      { RaiseError => 0, AutoCommit => 1 });
	if ( !defined $dbh )
  {
    die "Cannot connect to database!\n";
  }	
  
	#No date passed in arguments, so we'll go grab the latest.
	if (! defined $date)
  {
		$sql="SELECT m_date FROM multi_obs 
          WHERE platform_handle = '$platform_handle' 
          ORDER BY m_date DESC limit 1;";		
		
    if( $iEnableLog )
    {
      print( $LogFile "SQL latest date query: $sql\n" );
    }
		$sth = $dbh->prepare( $sql );
		if( defined $sth )
		{
  		if( $sth->execute() )
  		{
    		$date= $sth->fetchrow_array();
        if( $iEnableLog )
        {
          print( $LogFile "Date to process: $date\n" );
        }
        
    		if( ! defined $date )
    		{
          `cp $env{no_img} $env{img_path}`;   
          die "No rows returned \n";
    		}
  		}
  		else
  		{
  		  my $strErr = $sth->errstr;
  		  print( "ERROR::$strErr\n");
        if( $iEnableLog )
        {
          print( $LogFile "ERROR::$strErr\n" );
        }
  		}
		}
		else
		{
		  print( "ERROR::Unable to prepare SQL statement: $sql\n");
      if( $iEnableLog )
      {
        print( $LogFile "ERROR::Unable to prepare SQL statement: $sql\n" );
      }
		}	
	}	
=comment  
	#$env{time_interval}=12; 
	$sql="SELECT  max(abs(m_value)),max(abs(m_value_2)),max(m_z),min(m_z) 
        FROM multi_obs 
        WHERE (((multi_obs.platform_handle) LIKE '$platform_handle') AND
              (m_z<>-99999) AND 
              (m_value<>-99999) AND 
              (multi_obs.m_date <=timestamp '$date' AND 
              multi_obs.m_date>=(timestamp '$date' - interval '$env{time_interval} hours')));";
 
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	
	if ($sth->rows == 0){
		`cp $env{no_img} $env{img_path}`;		
		die "No rows returned \n";
	}	
		
	($env{max_east},$env{max_north},$env{max_z},$env{min_z})= $sth->fetchrow_array();	
=cut	
	#remove later
	
	
#	$sql="SELECT  sensor_type.type_name, sensor.s_order, multi_obs.m_date,multi_obs.m_z, multi_obs.m_value, multi_obs.m_value_2 
#        FROM sensor_type 
#        INNER JOIN (sensor INNER JOIN multi_obs ON sensor.row_id = multi_obs.sensor_id) 
#        ON sensor_type.row_id = sensor.type_id 
#        WHERE ( ( (multi_obs.platform_handle) ilike '%$platform_handle%') AND 
#              (multi_obs.m_z<>-99999) AND
#              (multi_obs.m_value<>-99999) AND
#              (multi_obs.m_value_2<>-99999)AND 
#              (multi_obs.m_date <=timestamp '$date' AND 
#              multi_obs.m_date>=(timestamp '$date' - interval '$env{time_interval} hours')));";
  my $strCurSpeedUOM;
  my $strCurDirUOM;
  my $iCurrentSpeedType = GetMTypeFromObsType( $dbh, 'current_speed', $platform_handle, \$strCurSpeedUOM );
  my $iCurrentDirType = GetMTypeFromObsType( $dbh, 'current_to_direction', $platform_handle, \$strCurDirUOM );
  
  #NOTE: UNION done because the query comes back MUCh faster than having one SELECT with a WHERE clause that had 
  # (multi_obs.m_type_id = $iCurrentSpeedType OR multi_obs.m_type_id = $iCurrentDirType )
  
  $sql="SELECT  multi_obs.m_type_id,sensor.s_order, multi_obs.m_date,multi_obs.m_z, multi_obs.m_value  
         FROM sensor, multi_obs        
         WHERE ( sensor.row_id = multi_obs.sensor_id                        AND
                multi_obs.m_type_id = $iCurrentSpeedType                    AND 
                ( (multi_obs.platform_handle) = '$platform_handle')         AND 
               (multi_obs.m_z<>-99999)                                      AND
               (multi_obs.m_value<>-99999)                                  AND               
               (multi_obs.m_date <= strftime('%Y-%m-%dT%H:00:00',datetime('$date'))                       AND 
               multi_obs.m_date>= strftime('%Y-%m-%dT%H:00:00',datetime('$date','-$env{time_interval} hours'))))
         
    UNION
         SELECT  multi_obs.m_type_id,sensor.s_order, multi_obs.m_date,multi_obs.m_z, multi_obs.m_value  
         FROM sensor, multi_obs        
         WHERE ( sensor.row_id = multi_obs.sensor_id                        AND
                multi_obs.m_type_id = $iCurrentDirType                      AND 
                ( (multi_obs.platform_handle) = '$platform_handle')         AND 
               (multi_obs.m_z<>-99999)                                      AND
               (multi_obs.m_value<>-99999)                                  AND               
               (multi_obs.m_date <= strftime('%Y-%m-%dT%H:00:00',datetime('$date'))                       AND 
               multi_obs.m_date>= strftime('%Y-%m-%dT%H:00:00',datetime('$date','-$env{time_interval} hours'))))
         ";
	
  $env{max_z} = 0;
  $env{min_z} = 0;   
  my %Hoh;
  my %BinDepths;
  $sth = $dbh->prepare( $sql );
  if( $iEnableLog )
  {
    print( $LogFile "SQL Data query: $sql\n" );
  }
  
  if( defined $sth )
  {
    if( $sth->execute() )
    {
	
    	#print "Sql: $sql \n";
    	
    	my ($sensor_type,$s_order,$m_date,$m_z,$m_value);
    	$sth -> bind_columns(undef,\$sensor_type,\$s_order,\$m_date,\$m_z,\$m_value);	   	
    	my $bin;
    	my $iRowCnt = 0;
    	while ( @row = $sth->fetchrow())
    	{
    	  
        $bin = $s_order;
        #Convert the m_s-1 to cm_s-1.
        if( ( $sensor_type == $iCurrentSpeedType ) && ( $strCurSpeedUOM eq 'm_s-1' ) )
        {
          $m_value *= 100.0;
        }
        $Hoh{$m_date}{$bin}{$sensor_type}{value} = $m_value;
        if( $iRoundDepths )
        {
          my $RoundedDepth = RoundTo( $m_z, 0.5, 1 );
          $Hoh{$m_date}{$bin}{depth} = $RoundedDepth;
        }
        else
        {
          $Hoh{$m_date}{$bin}{depth} = $m_z;          
        }
        #We don't have fixed depths for the bins, the depths vary according to tidal fluctuation. We create a bin
        #depth hash to store a depth per bin to use for plotting so each bin will get plotted on a line at its 
        #approximate depth.
        #if( ! defined $BinDepths{$bin}{depth} )
        #{
          #$BinDepths{$bin}{depth} = $RoundedDepth;
          #$BinDepths{$RoundedDepth} = $RoundedDepth;
        #}        
        if( abs( $env{max_z} ) < $Hoh{$m_date}{$bin}{depth} )
        {
          $env{max_z} = $Hoh{$m_date}{$bin}{depth};
        }
        if( abs( $env{min_z} ) > $Hoh{$m_date}{$bin}{depth} )
        {
          $env{min_z} = $Hoh{$m_date}{$bin}{depth};
        }
        $iRowCnt++;
    	}
      if( $iEnableLog )
      {
        print( $LogFile "Number of rows processed: $iRowCnt\n" );
      }
    }
    else
    {
      my $strErr = $sth->errstr;
      print( "ERROR::$strErr\n");
      if( $iEnableLog )
      {
        print( $LogFile "ERROR::$strErr\n" );
      }
    }
  }
  else
  {
    print( "ERROR::Unable to prepare SQL statement: $sql\n");
    if( $iEnableLog )
    {
      print( $LogFile "ERROR::Unable to prepare SQL statement\n" );
    }
  } 
  #The original xenia database that the original plot program ran against had the eastward and 
  #northward components. Since those can be computed from the current_speed and current_to_direciton
  #we do that here.
  $env{max_east} = 0;
  $env{max_north} = 0;
  for my $strDate ( sort (keys %Hoh) ) 
  {
    for my $iBin(sort (keys %{$Hoh{$strDate}})) 
    {
      my $iCurrentSpeed = ( $Hoh{$strDate}{$iBin}{$iCurrentSpeedType}{value} ); 
      my $iCurrentDir = $Hoh{$strDate}{$iBin}{$iCurrentDirType}{value};
      if( defined( $iCurrentSpeed ) and defined( $iCurrentDir ) )
      {
        $Hoh{$strDate}{$iBin}{mag} = $iCurrentSpeed;
        $Hoh{$strDate}{$iBin}{eastward} = sprintf("%.3f", $iCurrentSpeed * sin(deg2rad($iCurrentDir)));
        $Hoh{$strDate}{$iBin}{northward} = sprintf("%.3f",$iCurrentSpeed * cos(deg2rad($iCurrentDir)));
        #Determine the maximum east and north values to use to help scale the plot.
        if( abs( $Hoh{$strDate}{$iBin}{eastward} ) > abs( $env{max_east} ) )
        {
          $env{max_east} = $Hoh{$strDate}{$iBin}{eastward};         
        }
        if( abs( $Hoh{$strDate}{$iBin}{northward} ) > abs( $env{max_north} ) )
        {
          $env{max_north} = $Hoh{$strDate}{$iBin}{northward};         
        }
      }  
    }              
  }
  
	$sth->finish;
	$dbh->disconnect();		

	call_gnuplot(\%Hoh,\%env,$process_id, \%BinDepths);
	
  if( $iEnableLog )
  {
    print( $LogFile "Output File: $strFilename\n" );
  }
  print( $strFilename );
	
sub call_gnuplot{
  my ($Hoh_ref,$env_ref,$process_id,$refBinDepth)=@_;		
  my %Hoh=%$Hoh_ref;
  my %env=%$env_ref;		
  my %BinDepths = %$refBinDepth;
  
  open(OUTPUT_1,">$env{output_dir}adcp_data_file1_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file1_$process_id.txt $!";
  open(OUTPUT_2,">$env{output_dir}adcp_data_file2_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file2_$process_id.txt $!";
  open(OUTPUT_3,">$env{output_dir}adcp_data_file3_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file3_$process_id.txt $!";
  open(OUTPUT_4,">$env{output_dir}adcp_data_file4_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file4_$process_id.txt $!";
  open(OUTPUT_5,">$env{output_dir}adcp_data_file5_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file5_$process_id.txt $!";
  open(OUTPUT_6,">$env{output_dir}adcp_data_file6_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file6_$process_id.txt $!";
  open(OUTPUT_7,">$env{output_dir}adcp_data_file7_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file7_$process_id.txt $!";
  open(OUTPUT_8,">$env{output_dir}adcp_data_file8_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file8_$process_id.txt $!";
  open(OUTPUT_9,">$env{output_dir}adcp_data_file9_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file9_$process_id.txt $!";
  open(OUTPUT_10,">$env{output_dir}adcp_data_file10_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file10_$process_id.txt $!";
  open(OUTPUT_11,">$env{output_dir}adcp_data_file11_$process_id.txt") or die "Unable to open file: $env{output_dir}adcp_data_file11_$process_id.txt $!";		
  
  my $val;
  my $theta;
  my $degrees;
  my $magnitude;
  my $time=0;
  my $val3;
  my $time_diff;
  my ($sec,$min,$hours,$mday,$mon,$year);
  my $last;
  
  my ($eastward,$northward);
  my @time_array;
  my @time;
  
  my %time_hash;	
  
  #key1 = m_date, key2 = bin 
  my %depth_hash;	
  my $bDepthHashPrimed = 0;
  if( $iEnableLog )
  {
    print( $LogFile "Building plot files.\n" );
  }
  
  for my $key1 ( sort (keys %Hoh) ) 
  {
    $val=$key1;		
    $val =~ s/(.*?)\s(.*?)/$1-$2/;
    $val =~ s/T/-/;  #Get rid of the T notation between date and time.
    $val3=$val;
    $val3 =~ s/:/-/g;
          
    push(@time_array,$val);		
      for my $key2(sort (keys %{$Hoh{$key1}})) 
      {					
        ($year,$mon,$mday,$hours,$min,$sec)=split('-',$val3);
        $time = timelocal($sec,$min,$hours,$mday,($mon-1),$year);
        push(@time,$time);					
        
        if (!defined($time_diff)){
          $time_diff=0;
          $last=$time;
        }	
        else{
          $time_diff=($time-$last)/60;
        }	
        if( defined( $Hoh{$key1}{$key2}{eastward} ) && defined( $Hoh{$key1}{$key2}{northward} ) )
        {										
          $eastward=($Hoh{$key1}{$key2}{eastward}*60)/$env{max_east};
          $northward=($Hoh{$key1}{$key2}{northward}*1)/$env{max_north};											
          
          $depth_hash{$Hoh{$key1}{$key2}{depth}} = $Hoh{$key1}{$key2}{depth};
          
          my $strOutput = "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";  					
          #if( $iEnableLog )
          #{
          #  print( $LogFile "$strOutput\n" );
          #}
          
          #my $strOutput = "  $time_diff \t $BinDepths{$key2}{depth} \t $eastward \t $northward \t $val \n";
          if ($Hoh{$key1}{$key2}{mag}<=5.0){
            if( !print	OUTPUT_1 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }	
          elsif ($Hoh{$key1}{$key2}{mag}>5.0 && $Hoh{$key1}{$key2}{mag}<=10.0 ){
            if( !print	OUTPUT_2 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>10.0 && $Hoh{$key1}{$key2}{mag}<=15.0){
            if( !print	OUTPUT_3 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>15.0 && $Hoh{$key1}{$key2}{mag}<=20.0){
            if( !print	OUTPUT_4 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>20.0 && $Hoh{$key1}{$key2}{mag}<=25.0){
            if( !print	OUTPUT_5 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>25.0 && $Hoh{$key1}{$key2}{mag}<=30.0){
            if( !print	OUTPUT_6 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>30.0 && $Hoh{$key1}{$key2}{mag}<=35.0){
            if( !print	OUTPUT_7 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>35.0 && $Hoh{$key1}{$key2}{mag}<=40.0){
            if( !print	OUTPUT_8 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>40.0 && $Hoh{$key1}{$key2}{mag}<=45.0){
            if( !print	OUTPUT_9 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          elsif ($Hoh{$key1}{$key2}{mag}>45.0 && $Hoh{$key1}{$key2}{mag}<=50.0){
            if( !print	OUTPUT_10 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
          }
          #if ($Hoh{$key1}{$key2}{mag}>=0.5){
          #limiting the magnitude to 0.75 m/sec (75 cm/sec)
          elsif ($Hoh{$key1}{$key2}{mag}>=0.5 && $Hoh{$key1}{$key2}{mag}<=0.75){
            if( !print	OUTPUT_11 $strOutput )
            {
              if( $iEnableLog )
              {
                print( $LogFile "Failed to print: $strOutput to file.\n" );
              }
            }
            
          }
          else
          {
            print( "WARNING:: Magitude: $Hoh{$key1}{$key2}{mag} does not fall into any buckets!\n");
            if( $iEnableLog )
            {
              print( $LogFile "WARNING:: Magitude: $Hoh{$key1}{$key2}{mag} does not fall into any buckets!\n" );
            }
          }					  					
        }
        $env{last_time}=$time_diff;          
    }	
    #print OUTPUT "\n\n\n";
    
    $bDepthHashPrimed = 1;
  }		
  if( $iEnableLog )
  {
    print( $LogFile "Finished building plot files.\n" );
  }
  
  close OUTPUT_1;			
  close OUTPUT_2;			
  close OUTPUT_3;
  close OUTPUT_4;
  close OUTPUT_5;
  close OUTPUT_6;
  close OUTPUT_7;
  close OUTPUT_8;
  close OUTPUT_9;
  close OUTPUT_10;
  close OUTPUT_11;

  if( $iEnableLog )
  {
    print( $LogFile "Ouput plot files closed\n" );
  }
  
  my $t=$time[$#time]+3600;
  
  my ( $temp_sec, $temp_min, $temp_hour, $temp_day, $temp_month, $temp_year ) = localtime($t);
  #Month is 0-11.
  $temp_month = $temp_month + 1;
  $env{last_unixtime}=sprintf ("%04d-%02d-%02d-%02d:%02d:%02s ", $temp_year+1900, $temp_month, $temp_day,  $temp_hour, $temp_min, $temp_sec  );				
  push(@time_array, $env{last_unixtime});
  #print( "$env{last_unixtime}\n" );
  #$env{last_unixtime} = @time_array[-1];
  
  $t=$time[0]-3600;
  ( $temp_sec, $temp_min, $temp_hour, $temp_day, $temp_month, $temp_year ) = localtime($t);
  #Month is 0-11.
  $temp_month = $temp_month + 1;
  $env{first_unixtime}=sprintf ("%04d-%02d-%02d-%02d:%02d:%02s ", $temp_year+1900, $temp_month, $temp_day,  $temp_hour, $temp_min, $temp_sec  );			
  #print( "$env{first_unixtime}\n" );
  unshift(@time_array, $env{first_unixtime});		
  #$env{first_unixtime} = @time_array[0];

  #Build depth hash
#    for my $iDepth ( sort (keys %BinDepths) )
#    {     
    #$depth_hash{$BinDepths{$iBin}{depth}}=$BinDepths{$iBin}{depth};
#      $depth_hash{$BinDepths{$iDepth}}=$BinDepths{$iDepth};
#      print( "Depth Hash: $depth_hash{$BinDepths{$iDepth}}\n"); 
#    }    			
  require "adcp_gnuplot.lib";
  if( $iEnableLog )
  {
    print( $LogFile "Calling plot library.\n" );
  }
  
  my_graph(\%env,\@time_array,\%depth_hash);
    
  
  my ($i,$file);
#  for($i=1;$i<=11;$i++){
#    $file = $env{output_dir}."adcp_data_file".$i."_".$process_id.".txt";
#    if( $iEnableLog )
#    {
#      print( $LogFile "Removing bucket file: $file\n" );
#    }
#    `rm $file`;
#  }		
  #`rm $env{graph_script}`;
  my $file_size = -s $env{img_path};
  
  if ((!-e $env{img_path})||($file_size==0)){
    `cp $env{no_img} $env{img_path}`;
  }	
  
}	

sub GetMTypeFromObsType
{
  my ($dbh, $strObsName, $strPlatformHandle, $strUom, $iSOrder ) = @_;
  
  my $strSOrder = '';
  if( defined $iSOrder )
  {
    $strSOrder = "sensor.s_order = $iSOrder AND";
  }
  my $strSQL = "SELECT DISTINCT(sensor.m_type_id), uom_type.standard_name FROM m_type, m_scalar_type, obs_type, uom_type, sensor, platform
                WHERE  sensor.m_type_id = m_type.row_id AND
                m_scalar_type.row_id = m_type.m_scalar_type_id AND
                obs_type.row_id = m_scalar_type.obs_type_id AND
                uom_type.row_id = m_scalar_type.uom_type_id AND
                platform.row_id = sensor.platform_id AND
                $strSOrder
                obs_type.standard_name = '$strObsName' AND
                platform.platform_handle = '$strPlatformHandle';";
  my $iMType = -1;
  my $sth = $dbh->prepare( $strSQL );
  if( defined $sth )
  {
    if( $sth->execute() )
    {      
    	( $iMType, $$strUom ) = $sth->fetchrow_array();
    }
    else
    {
      my $strErr = $sth->errstr;
      print( "ERROR::$strErr\n");
    }
  }
  else
  {
    print( "ERROR::Unable to prepare SQL statement: $sql\n");
  } 
  $sth->finish();
  return( $iMType );
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
  
  my $tmp = int($tmpVal);
  
  $tmpVal = sprintf( "%d", ( $tmpVal - $tmp ) );
  
  my $nValue = $tmp + $tmpVal ;

  #Multiply by ceiling value to set RoundtoValue
  my $RoundToValue = $nValue * $Ceiling;
 
  return( $RoundToValue ); 
}
