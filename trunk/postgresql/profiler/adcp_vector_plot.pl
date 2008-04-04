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
	
	#perl adcp_vector_plot.pl --PlatformHandle "usf:C17:ADCP" --Date "2007-03-12 12:00:00" --ProcessId 10
	
	my %arguments;
	GetOptions(\%arguments,"PlatformHandle=s","Date:s","ProcessId=i","size_x:f","size_y:f","title:s"); 
	my ($platform_handle,$date,$process_id);
	
	$platform_handle=$arguments{'PlatformHandle'};
	if (!defined $platform_handle){
		die " No Platform Handle defined! \n";
	}	
	
	if ($arguments{'Date'}){ $date=$arguments{'Date'};}			
		
	$process_id=$arguments{'ProcessId'};
	
	my $xp_env = XML::XPath->new(filename => 'environment.xml');			
	my %env;
        $env{platform_handle}=$platform_handle;	
	$env{hostname} = $xp_env->findvalue('//DB/host');
	$env{db_name} = $xp_env->findvalue('//DB/db_name');
	$env{db_user} = $xp_env->findvalue('//DB/db_user');
	$env{db_passwd} = $xp_env->findvalue('//DB/db_passwd');
	
	$env{output_dir} = $xp_env->findvalue('//path/output_dir');	
	$env{no_img} = $xp_env->findvalue('//path/no_img');
	
	my $lc_platform_handle=lc($platform_handle);
	$lc_platform_handle=~s/:/_/g;
	$env{time_interval} = $xp_env->findvalue('//platforms/'.$lc_platform_handle.'');
	
	if ($env{time_interval} eq ''){$env{time_interval} =8; }	
	
	$env{data_file}=$env{output_dir}."adcp_data_file_$process_id.txt";	
	$env{data_file_1}=$env{output_dir}."adcp2_data_file_$process_id.txt";	
	$env{img_path}=$env{output_dir}."graph_$process_id.png"; #path for graph
	$env{process_id}=$process_id;
	$env{graph_script}=$env{output_dir}."plot_graph_$process_id.script";			
	
	if ($arguments{'size_x'}){ $env{size_x}=$arguments{'size_x'};}		
	if ($arguments{'size_y'}){ $env{size_y}=$arguments{'size_y'};}		
	if ($arguments{'title'}){ $env{title}=$arguments{'title'}; }	
	
	my ($dbh,$sql,$sth,@row);		
	$dbh = DBI->connect ( "dbi:Pg:dbname=$env{db_name};host=$env{hostname}", "$env{db_user}", "$env{db_passwd}");
	if ( !defined $dbh ) {die "Cannot connect to database!\n";}	
	
	if (! defined $date){
		$sql="SELECT m_date from multi_obs where platform_handle ilike '%$platform_handle%' order by m_date desc limit 1;";		
		
		$sth = $dbh->prepare( $sql );
		$sth->execute();
		
		if ($sth->rows == 0){
			`cp $env{no_img} $env{img_path}`;		
			die "No rows returned \n";
		}	
			
		$date= $sth->fetchrow_array();	
	}	
	#$env{time_interval}=12;
	$sql="SELECT  max(abs(m_value)),max(abs(m_value_2)),max(m_z),min(m_z) from multi_obs WHERE (((multi_obs.platform_handle)ilike '%$platform_handle%') AND
	 (m_z<>-99999) AND (m_value<>-99999) AND (multi_obs.m_date <=timestamp '$date' and multi_obs.m_date>=(timestamp '$date' - interval '$env{time_interval} hours')));";
 
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	
	if ($sth->rows == 0){
		`cp $env{no_img} $env{img_path}`;		
		die "No rows returned \n";
	}	
		
	($env{max_east},$env{max_north},$env{max_z},$env{min_z})= $sth->fetchrow_array();	
	
	#remove later
	
	
	$sql="SELECT  sensor_type.type_name, sensor.s_order, multi_obs.m_date,multi_obs.m_z, multi_obs.m_value, multi_obs.m_value_2 
		FROM sensor_type INNER JOIN (sensor INNER JOIN multi_obs ON sensor.row_id = multi_obs.sensor_id) ON 
		sensor_type.row_id = sensor.type_id WHERE ( ( (multi_obs.platform_handle) ilike '%$platform_handle%') AND (multi_obs.m_z<>-99999) AND(multi_obs.m_value<>-99999)
		AND(multi_obs.m_value_2<>-99999)AND (multi_obs.m_date <=timestamp '$date' and multi_obs.m_date>=(timestamp '$date' - interval '$env{time_interval} hours')));";
	
	$sth = $dbh->prepare( $sql );
	$sth->execute();
	
	#print "Sql: $sql \n";
	
	my ($sensor_type,$s_order,$m_date,$m_z,$m_value,$m_value_2);
	$sth -> bind_columns(undef,\$sensor_type,\$s_order,\$m_date,\$m_z,\$m_value,\$m_value_2);	
	
	my %Hoh;
	my $bin;
	
	if ($sth->rows == 0){ 
		`cp $env{no_img} $env{img_path}`;		
		die "No rows returned \n";
	}	
	
	while ( @row = $sth->fetchrow()){
		if (($sensor_type ne 'adcp_surface')&&($sensor_type ne 'adcp_bottom')&&($sensor_type ne 'depth_average')){
			#ASSUME EVERYTHING IS IN m/sec - if inserted using netcdf to xenia scripts
			$bin=$sensor_type.'_'.$s_order;
			$Hoh{$m_date}{$bin}{eastward}=$m_value;
			$Hoh{$m_date}{$bin}{northward}=$m_value_2;			
			
			$Hoh{$m_date}{$bin}{depth}=$m_z;
			$Hoh{$m_date}{$bin}{mag}=sprintf("%4f",sqrt(($m_value**2)+($m_value_2**2)));			
		}
	}	
	
	$sth->finish;
	$dbh->disconnect();		

	call_gnuplot(\%Hoh,\%env,$process_id);
	exit 0;
	
	sub call_gnuplot{
		my ($Hoh_ref,$env_ref,$process_id)=@_;		
		my %Hoh=%$Hoh_ref;
		my %env=%$env_ref;		

		open(OUTPUT_1,">$env{output_dir}adcp_data_file1_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_2,">$env{output_dir}adcp_data_file2_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_3,">$env{output_dir}adcp_data_file3_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_4,">$env{output_dir}adcp_data_file4_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_5,">$env{output_dir}adcp_data_file5_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_6,">$env{output_dir}adcp_data_file6_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_7,">$env{output_dir}adcp_data_file7_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_8,">$env{output_dir}adcp_data_file8_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_9,">$env{output_dir}adcp_data_file9_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_10,">$env{output_dir}adcp_data_file10_$process_id.txt") or die "Unable to open file: $!";
		open(OUTPUT_11,">$env{output_dir}adcp_data_file11_$process_id.txt") or die "Unable to open file: $!";		
		
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
		
		my %depth_hash;	
		for my $key1 ( sort (keys %Hoh) ) {
			$val=$key1;		
			$val =~ s/(.*?)\s(.*?)/$1-$2/;
			$val3=$val;
			$val3 =~ s/:/-/g;
						
			push(@time_array,$val);		
				for my $key2(sort (keys %{$Hoh{$key1}})) {					
					($year,$mon,$mday,$hours,$min,$sec)=split('-',$val3);
					$time = timelocal($sec,$min,$hours,$mday,$mon,$year);
					push(@time,$time);					
					
					if (!defined($time_diff)){
						$time_diff=0;
						$last=$time;
					}	
					else{
						$time_diff=($time-$last)/60;
					}	
										
					$eastward=($Hoh{$key1}{$key2}{eastward}*60)/$env{max_east};
					$northward=($Hoh{$key1}{$key2}{northward}*1)/$env{max_north};											
					
					$depth_hash{$Hoh{$key1}{$key2}{depth}}=$Hoh{$key1}{$key2}{depth}+0;	
					
					if ($Hoh{$key1}{$key2}{mag}<=0.05){
						print	OUTPUT_1 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}	
					if ($Hoh{$key1}{$key2}{mag}>0.05 && $Hoh{$key1}{$key2}{mag}<=0.1 ){
						print	OUTPUT_2 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					if ($Hoh{$key1}{$key2}{mag}>0.1 && $Hoh{$key1}{$key2}{mag}<=0.15){
						print	OUTPUT_3 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					if ($Hoh{$key1}{$key2}{mag}>0.15 && $Hoh{$key1}{$key2}{mag}<=0.2){
						print	OUTPUT_4 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";						
					}
				 	if ($Hoh{$key1}{$key2}{mag}>0.2 && $Hoh{$key1}{$key2}{mag}<=0.25){
				 		print	OUTPUT_5 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
				 	}
				 	if ($Hoh{$key1}{$key2}{mag}>0.25 && $Hoh{$key1}{$key2}{mag}<=0.3){
				 		print	OUTPUT_6 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
				 	}
					if ($Hoh{$key1}{$key2}{mag}>0.3 && $Hoh{$key1}{$key2}{mag}<=0.35){
						print	OUTPUT_7 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					if ($Hoh{$key1}{$key2}{mag}>0.35 && $Hoh{$key1}{$key2}{mag}<=0.4){
						print	OUTPUT_8 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					if ($Hoh{$key1}{$key2}{mag}>0.4 && $Hoh{$key1}{$key2}{mag}<=0.45){
						print	OUTPUT_9 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					if ($Hoh{$key1}{$key2}{mag}>0.45 && $Hoh{$key1}{$key2}{mag}<=0.5){
						print	OUTPUT_10 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					#if ($Hoh{$key1}{$key2}{mag}>=0.5){
					#limiting the magnitude to 0.75 m/sec (75 cm/sec)
					if ($Hoh{$key1}{$key2}{mag}>=0.5 && $Hoh{$key1}{$key2}{mag}<=0.75){
						print	OUTPUT_11 "  $time_diff \t $Hoh{$key1}{$key2}{depth} \t $eastward \t $northward \t $val \n";					
					}
					
					$env{last_time}=$time_diff;
			}	
			#print OUTPUT "\n\n\n";
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
		
		my $t=$time[$#time]+3600;
		
		my ( $temp_sec, $temp_min, $temp_hour, $temp_day, $temp_month, $temp_year ) = localtime($t);
		$env{last_unixtime}=sprintf ("%04d-%02d-%02d-%02d:%02d:%02s ", $temp_year+1900, $temp_month, $temp_day,  $temp_hour, $temp_min, $temp_sec  );				
		push(@time_array, $env{last_unixtime});
		$t=$time[0]-3600;
		( $temp_sec, $temp_min, $temp_hour, $temp_day, $temp_month, $temp_year ) = localtime($t);
		$env{first_unixtime}=sprintf ("%04d-%02d-%02d-%02d:%02d:%02s ", $temp_year+1900, $temp_month, $temp_day,  $temp_hour, $temp_min, $temp_sec  );			
		unshift(@time_array, $env{first_unixtime});		
			
		require "adcp_gnuplot.lib";
		my_graph(\%env,\@time_array,\%depth_hash);
			
		
		my ($i,$file);
		for($i=1;$i<=11;$i++){
			$file = $env{output_dir}."adcp_data_file".$i."_".$process_id.".txt";
			`rm $file`;
		}		
		#`rm $env{graph_script}`;
		my $file_size = -s $env{img_path};
		
		if ((!-e $env{img_path})||($file_size==0)){
			`cp $env{no_img} $env{img_path}`;
		}	
		
	}	
