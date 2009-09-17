#!/usr/bin/perl

package ObsUtils;

use strict;

#use lib '/usr2/home/scscout/local/Geo-WeatherNWS-1.03/blib/lib';
#use lib '/usr2/home/scscout/local/SOAP-Lite-0.69/lib';

# The earliest timestamp we'll accept.  Assume all.
my $min_time = 0;
if (defined $ARGV[1]) {
  $min_time = time() - 60 * 60 * $ARGV[1];
}

# If debugging requested print messages to STDERR.
my $debug;
if (grep /debug/, @ARGV) {
  $debug = 1;
}

# These units are assumed for all keys.
# wind_speed                    | m s-1 
# wind_gust                     | m s-1 
# wind_from_direction           | degrees_true
# air_pressure                  | mb 
# air_temperature               | celsius 
# water_temperature             | celsius 
# water_conductivity            | siemens 
# water_pressure                | mb 
# water_salinity                | ppt 
# chl_concentration             | psu 
# current_speed                 | cm s-1 
# current_to_direction          | degrees_true
# significant_wave_height       | m 
# dominant_wave_period          | s 
# significant_wave_to_direction | degrees_true
# sea_surface_temperature       | celsius 
# sea_bottom_temperature        | celsius 
# sea_surface_eastward_current  | cm s-1 
# sea_surface_northward_current | cm s-1 
# relative_humidity             | percent 
# water_level                   | m 
# bottom_water_salinity         | ppt 
# surface_water_salinity        | ppt 
# bottom_chlorophyll            | ug L-1 
# surface_chlorophyll           | ug L-1 
# salinity                      | ppt 

# A single timestamp to glue everything together.
my $now_time = time();
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($now_time);

################################################################################
# Brains to go get NWS observations.  And return the results as a hash.
################################################################################

sub get_nws_obs {
  #my @stations = @_;
  my( @stations, %local_setup ) = @_;
  my %latest_obs;

  use Geo::WeatherNWS;
  use HTTP::Date;

  # See this page for general Geo::WeatherNWS instructions as well as to see
  # what fields are available beyond what we're grabbing here.
  # http://search.cpan.org/~mslagle/Geo-WeatherNWS-1.03/WeatherNWS.pm

  # Need confirmation?  This module uses the data pulled from a template simlar to
  # http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=KCHS
  # Or a more pleasant one for you might be
  # http://weather.noaa.gov/weather/current/KNBC.html
  
  # The full date is not available from NOS data!  Only the day of month and hh:mi.
  # I'm a little concerned how this works if the script is being run right at 00:01Z
  # of a new month, but the target data is still in the previous month.  The only
  # way I can think to avoid this is to make sure that the dates aren't in the future.
  # This means that we might miss out getting super fresh data when a month changes.
  # But the obs will catch back up on a subsequent refresh.
  # So we'll assume the current month and year.

  my $rpt = Geo::WeatherNWS::new();
  $rpt->setservername('tgftp.nws.noaa.gov');
  
  my $nwsOutFile;
  my $outfilename = "/home/xeniaprod/scripts/postgresql/feeds/federal/nws/$year-$mon-$mday-$hour-$min-$sec.csv";
  open( $nwsOutFile, ">$outfilename");

  foreach my $s (@stations) {
    (my $system_station_id,my $provider_station_id) = split(/\|/,$s);
    $rpt->getreport($provider_station_id);
    if ($debug)
    {
      print STDERR "NWS $system_station_id\n";
      #print "NWS $system_station_id\n";
      #print( "\n" );
      #while ( my ($key, $value) = each(%$rpt) ) 
      #{
      #  print "$key: $value,";
      #}
      #print( "\n" );
    }
    my $date = sprintf "%4d%02d%02dT%02d%02dZ",$year+1900,$mon+1,$rpt->{day},substr($rpt->{time},0,2),substr($rpt->{time},2,2);
    my %d = (
       wind_speed          => $rpt->{windspeedkts} * 0.514444444
      ,wind_from_direction => $rpt->{winddir}
      ,wind_gust           => $rpt->{windgustkts} * 0.514444444
      ,air_temperature     => $rpt->{temperature_c}
      ,air_pressure        => $rpt->{pressure_mb}
    );
    print( $nwsOutFile "$system_station_id,$date," . $rpt->{windspeedkts}  * 0.514444444 . ",$rpt->{winddir}," . $rpt->{windgustkts} * 0.514444444 . ",$rpt->{temperature_c},$rpt->{pressure_mb}\n");
    #print( "$rpt->{windspeedkts} $rpt->{winddir} $rpt->{temperature_c} $rpt->{pressure_mb}\n" );

    #print $rpt->{pressure_mb};
    # Add this to the hash if the timestamp isn't in the future.
    if (str2time($date) <= $now_time && str2time($date) >= $min_time) {
      $latest_obs{$system_station_id}{$date} = \%d;
    }
  }
  close($nwsOutFile);
  return \%latest_obs;
}

#################################################################################
# Brains to go get NDBC observations.  And return the results as a hash.
#################################################################################

sub get_ndbc_obs {

  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new((timeout => 100));

  # For NDBC obs, loop through all the target buoys whose files may be:
  # .txt, .spec, and .ocean.

  my $url_base = 'http://ndbc.noaa.gov/data/realtime2/';

  my @stations = @_;
  my %latest_obs;

  foreach my $s (@stations) {
    my $ndbc_station   = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NDBC $system_station\n";}

    # get the page
    my $response = $ua->get($url_base.$ndbc_station.'.txt');

    # die if we timeout, but keep going if we 404
    if (!$response->is_success && !($response->status_line =~ /404/)) {
      die $response->status_line.' : '.$url_base.$ndbc_station.'.txt';
    }

    my @data = split(/\n/,$response->content);
    
    if ($data[0] =~ /^#YY/) {
      # The latest obs are always the 1st line after the header line.
      my (
         $yyyy
        ,$mm
        ,$dd
        ,$hh
        ,$mi
        ,$wd
        ,$wspd
        ,$gst
        ,$wvht
        ,$dpd
        ,$apd
        ,$mdw
        ,$baro
        ,$atmp
        ,$wtmp
        ,$dewp
        ,$vis
        ,$ptdy
        ,$tide
      ) = split(/ +/,$data[2]);
      my $date = sprintf "%4d%02d%02dT%02d%02dZ",$yyyy,$mm,$dd,$hh,$mi;
      my %d = (
         wind_speed              => $wspd
        ,wind_from_direction     => $wd
        ,wind_gust               => $gst
        ,air_temperature         => $atmp
        ,air_pressure            => $baro
        ,significant_wave_height => $wvht
        ,sea_surface_temperature => $wtmp
      );

 
 
      # Add this to the hash.
      if (str2time($date) >= $min_time) {
        $latest_obs{$system_station}{$date} = \%d;
      }
    }

    # Move onto more ocean data.
    $response = $ua->get($url_base.$ndbc_station.'.ocean');

    # die if we timeout, but keep going if we 404
    if (!$response->is_success && !($response->status_line =~ /404/)) {
      die $response->status_line.' : '.$url_base.$ndbc_station.'.ocean';
    }

    @data = split(/\n/,$response->content);
    
    if ($data[0] =~ /^#YY/) {
      # The latest obs are always the 1st line after the header line.
      my (
         $yyyy
        ,$mm
        ,$dd
        ,$hh
        ,$mi
        ,$depth
        ,$otmp
        ,$cond
        ,$sal
        ,$oxygen_percent
        ,$oxygen_ppm
        ,$clcon
        ,$turb
        ,$ph
        ,$eh
      ) = split(/ +/,$data[2]);
 
      # Don't add it, if it's not deep enough.
      if ($depth >= 5) {
        my $date = sprintf "%4d%02d%02dT%02d%02dZ",$yyyy,$mm,$dd,$hh,$mi;
        my %d = (
           sea_bottom_temperature => $otmp
          ,salinity               => $sal
        );
  
        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}) {
          $latest_obs{$system_station}{$date}{sea_bottom_temperature} = $d{sea_bottom_temperature};
          $latest_obs{$system_station}{$date}{salinity}               = $d{salinity};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }

    # Move onto current data.
    $response = $ua->get($url_base.$ndbc_station.'.adcp');

    # die if we timeout, but keep going if we 404
    if (!$response->is_success && !($response->status_line =~ /404/)) {
      die $response->status_line.' : '.$url_base.$ndbc_station.'.adcp';
    }

    @data = split(/\n/,$response->content);

    if ($data[0] =~ /^#YY/) {
      # The latest obs are always the 1st line after the header line.  But since there
      # are so many columns (bins), pull out only the date stuff + 1st 3 cols.
      my @cols = split(/ +/,$data[2]);
 
      my $date = sprintf "%4d%02d%02dT%02d%02dZ",$cols[0],$cols[1],$cols[2],$cols[3],$cols[4]; 
      my %d = (
         current_to_direction => $cols[6]
        ,current_speed        => $cols[7]
      );
  
      # It's likely that a record already exists in the system hash.  So simply append to it . . .
      if (exists $latest_obs{$system_station}) {
         #print "station $system_station current_speed ".$d{current_speed}."\n";
        $latest_obs{$system_station}{$date}{current_to_direction} = $d{current_to_direction};
        $latest_obs{$system_station}{$date}{current_speed}        = $d{current_speed};
      }
      # . . . otherwise, add it to the hash.
      else {
        if (str2time($date) >= $min_time) {
          $latest_obs{$system_station}{$date} = \%d;
        }
      }
    }
  }

  # Finally, do some NDBC cleaning up since they use 'MM' as placeholders and this mucks up conversions.
  foreach my $system_station (keys %latest_obs) {
    my %o = %{$latest_obs{$system_station}};
    foreach my $date (keys %o) {
      my %d = %{$latest_obs{$system_station}{$date}};
      while (my ($k,$v) = each %d) {
        if ($v eq 'MM') {
          delete $latest_obs{$system_station}{$date}{$k};
        }
      }
    }
  }

  return \%latest_obs;
}

#################################################################################
# Brains to go get USGS observations.  And return the results as a hash.
#################################################################################

sub get_usgs_obs {

  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new((timeout => 100));

  my @stations = @_;
  my %latest_obs;

  # Everything is gotten by one AWFUL URL.  The stations are comma delimited.
  # But create a hash so we can get back to the system names from usgs names.
  my $comma_stations;
  my %usgs_to_system;
  foreach my $s (@stations) {
    $comma_stations .= ','.substr($s,index($s,'|')+1);
    $usgs_to_system{substr($s,index($s,'|')+1)} = substr($s,0,index($s,'|'));
  }
  $comma_stations = substr($comma_stations,1);

  my $url = 'http://waterdata.usgs.gov/nwis/current?index_pmcode_STATION_NM=1&index_pmcode_DATETIME=2&index_pmcode_72019=&index_pmcode_70227=&index_pmcode_72020=&index_pmcode_99020=&index_pmcode_00062=&index_pmcode_50051=&index_pmcode_00059=&index_pmcode_99065=&index_pmcode_30207=&index_pmcode_00065=&index_pmcode_62611=&index_pmcode_62615=&index_pmcode_62614=&index_pmcode_MEAN=&index_pmcode_MEDIAN=&index_pmcode_00064=&index_pmcode_72022=&index_pmcode_72036=&index_pmcode_00054=&index_pmcode_00072=&index_pmcode_00055=&index_pmcode_63160=&index_pmcode_63158=&index_pmcode_00060=&index_pmcode_72137=&index_pmcode_50042=&index_pmcode_99060=&index_pmcode_00067=&index_pmcode_62620=&index_pmcode_62619=&index_pmcode_81904=&index_pmcode_61055=&index_pmcode_63518=&index_pmcode_00625=&index_pmcode_00608=&index_pmcode_99123=&index_pmcode_71845=&index_pmcode_00915=&index_pmcode_99220=&index_pmcode_50060=&index_pmcode_32209=&index_pmcode_32210=&index_pmcode_32234=&index_pmcode_62361=&index_pmcode_00301=&index_pmcode_00300=&index_pmcode_72106=&index_pmcode_00925=&index_pmcode_71850=&index_pmcode_00618=&index_pmcode_00620=&index_pmcode_00631=&index_pmcode_00630=&index_pmcode_00680=&index_pmcode_00090=&index_pmcode_70301=&index_pmcode_07084=&index_pmcode_00096=&index_pmcode_00480=&index_pmcode_90860=&index_pmcode_00931=&index_pmcode_90856=&index_pmcode_00930=&index_pmcode_81203=&index_pmcode_00095=&index_pmcode_00402=&index_pmcode_80154=&index_pmcode_99409=&index_pmcode_80155=&index_pmcode_00010=3&index_pmcode_00011=&index_pmcode_00047=&index_pmcode_00048=&index_pmcode_63680=&index_pmcode_00076=&index_pmcode_61028=&index_pmcode_63682=&index_pmcode_63684=&index_pmcode_99111=&index_pmcode_71994=&index_pmcode_00400=&index_pmcode_00025=&index_pmcode_75969=&index_pmcode_62607=&index_pmcode_62603=&index_pmcode_00030=&index_pmcode_72124=&index_pmcode_62609=&index_pmcode_99988=&index_pmcode_00193=&index_pmcode_00117=&index_pmcode_46529=&index_pmcode_99772=&index_pmcode_00045=&index_pmcode_00052=&index_pmcode_99986=&index_pmcode_99987=&index_pmcode_46515=&index_pmcode_46516=&index_pmcode_00020=&index_pmcode_00021=&index_pmcode_62608=&index_pmcode_00036=&index_pmcode_61729=&index_pmcode_61727=&index_pmcode_61728=&index_pmcode_82127=&index_pmcode_62625=&index_pmcode_00035=&index_pmcode_50624=&index_pmcode_00042=&index_pmcode_72001=&index_pmcode_81903=&index_pmcode_72135=&index_pmcode_50050=&index_pmcode_45585=&index_pmcode_45592=&index_pmcode_45591=&index_pmcode_72150=&index_pmcode_00053=&index_pmcode_98232=&index_pmcode_99234=&index_pmcode_95202=&index_pmcode_50294=&index_pmcode_99233=&index_pmcode_99236=&index_pmcode_62968=&index_pmcode_74207=&index_pmcode_00063=&index_pmcode_70968=&index_pmcode_00003=&index_pmcode_62969=&index_pmcode_62967=&index_pmcode_72147=&index_pmcode_72148=&index_pmcode_30215=&index_pmcode_82300=&index_pmcode_62846=&index_pmcode_99235=&index_pmcode_81027=&index_pmcode_50011=&index_pmcode_81026=&index_pmcode_99900=&index_pmcode_99901=&index_pmcode_99902=&index_pmcode_99903=&index_pmcode_99904=&index_pmcode_99905=&index_pmcode_99906=&index_pmcode_99907=&index_pmcode_99908=&index_pmcode_99909=&index_pmcode_99910=&index_pmcode_99911=&index_pmcode_99912=&index_pmcode_99913=&index_pmcode_99914=&index_pmcode_99915=&index_pmcode_99916=&index_pmcode_99968=&index_pmcode_70969=&index_pmcode_72115=&index_pmcode_72113=&index_pmcode_72112=&index_pmcode_72111=&index_pmcode_72117=&index_pmcode_82292=&index_pmcode_72114=&index_pmcode_99969=&index_pmcode_99970=&index_pmcode_99971=&index_pmcode_72116=&index_pmcode_30214=&index_pmcode_45587=&index_pmcode_61035=&sort_key=site_no&group_key=NONE&sitefile_output_format=html_table&column_name=agency_cd&column_name=site_no&column_name=station_nm&sort_key_2=site_no&html_table_group_key=NONE&format=rdb&rdb_compression=value&list_of_search_criteria=realtime_parameter_selection';

  # get the page
  my $response = $ua->get($url);

  # die if we timeout, but keep going if we 404
  if (!$response->is_success && !($response->status_line =~ /404/)) {
    die $response->status_line.' : '.$url;
  }

  my @d = sort split(/\n/,$response->content);

  foreach my $l (@d) {
    if ($l =~ /^USGS/) {
      my (
         $usgs
        ,$id
        ,$descr
        ,$depth
        ,$obs_type
        ,$date
        ,$wtmp
      ) = split(/\t/,$l);

      # Get the date in the right format.
      $date = substr($date,0,rindex($date,':'));
      $date =~ s/-//g;
      $date =~ s/://g;
      $date =~ s/ /T/g;
      $date .= 'Z';

      # USGS data come in as EST!!!  So convert to UTC.
      (my $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(str2time($date) + 60*60*5);
      $date = sprintf "%4d%02d%02dT%02d%02dZ",$year+1900,$mon+1,$mday,$hour,$min;

      my %d = (
        sea_surface_temperature => $wtmp
      );

      # We only want the 1st appearance of a temperature record for a site.  So ignore this reading
      # if one is already in the hash.

      if (!exists $latest_obs{$usgs_to_system{$id}}) {
        if ($debug) {print STDERR "USGS $usgs_to_system{$id}\n";}
        if (str2time($date) >= $min_time) {
          $latest_obs{$usgs_to_system{$id}}{$date} = \%d;
        }
      }
    }
  }
  return \%latest_obs;
}

##########################################################################################
# Brains to go get CO-OPS / NOS observations.  And return the results as a hash.
##########################################################################################

sub get_nos_obs {
  use SOAP::Lite;

  my @stations = @_;
  my %latest_obs;

  # Get a time that's 30m ago.
  my ($sec_p,$min_p,$hour_p,$mday_p,$mon_p,$year_p,$wday_p,$yday_p,$isdst_p) = gmtime(time() - 3600 );

  # COOPS time format: 'YYYYMMDD HH:MM' 
  my $end_time = sprintf "%4d%02d%02d %02d:00",$year+1900,$mon+1,$mday,$hour;
  my $now_time = sprintf "%4d%02d%02d %02d:00",$year_p+1900,$mon_p+1,$mday_p,$hour_p;

  #my $now_time="20081101 01:00";
  #my $end_time="20081130 23:59";
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (water level)\n";}
                                                                                
    # Get water level first
    #my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/services/WaterLevelRawSixMin?wsdl')->want_som(1);
    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/waterlevelrawsixmin/wsdl/WaterLevelRawSixMin.wsdl')->want_som(1);
    my $response = $service->getWaterLevelRawSixMin($station_id, $now_time, $end_time, 'MLLW', 0, 0);
                                                                                
    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
          water_level_in_mllw => $v->{WL}
        );
                                                                                
        # Add it to the hash.
        $latest_obs{$system_station}{$date} = \%d;
      }
    }
  }


  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (water level)\n";}

    # Get water level first
    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/waterlevelrawsixmin/wsdl/WaterLevelRawSixMin.wsdl')->want_som(1);
    my $response = $service->getWaterLevelRawSixMin($station_id, $now_time, $end_time, 'MSL', 0, 0);

    if(!$response->fault()) { 
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
          water_level_in_msl => $v->{WL}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{water_level_in_msl} = $d{water_level_in_msl};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }

      }
    }
  }

  # Move onto the wind data.
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (wind)\n";}

    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/wind/wsdl/Wind.wsdl')->want_som(1);
    my $response = $service->getWind($station_id, $now_time, $end_time, 0);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
           wind_speed          => $v->{WS}
          ,wind_from_direction => $v->{WD}
          ,wind_gust           => $v->{WG}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{wind_speed}          = $d{wind_speed};
          $latest_obs{$system_station}{$date}{wind_from_direction} = $d{wind_from_direction};
          $latest_obs{$system_station}{$date}{wind_gust}           = $d{wind_gust};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }
  } 
  
  # Move onto the air temp data.
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (air temp)\n";}

    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/airtemperature/wsdl/AirTemperature.wsdl')->want_som(1);
    my $response = $service->getAirTemperature($station_id, $now_time, $end_time, 0);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
           air_temperature => $v->{AT}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{air_temperature} = $d{air_temperature};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }
  } 
  
  # Move onto the water temp data.
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (water temp)\n";}

    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/watertemperature/wsdl/WaterTemperature.wsdl')->want_som(1);
    my $response = $service->getWaterTemperature($station_id, $now_time, $end_time, 0);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
           sea_surface_temperature => $v->{WT}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{sea_surface_temperature} = $d{sea_surface_temperature};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }
  } 
  
  # Move onto the pressure data.
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (pressure)\n";}

    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/barometricpressure/wsdl/BarometricPressure.wsdl')->want_som(1);
    my $response = $service->getBarometricPressure($station_id, $now_time, $end_time, 0);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
           air_pressure => $v->{BP}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{air_pressure} = $d{air_pressure};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }
  } 
  
  # Move onto the currents data.
  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (currents)\n";}

    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/currents/wsdl/Currents.wsdl')->want_som(1);
    my $response = $service->getCurrents($station_id, $now_time, $end_time);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:|-/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[0],$dt[1],$dt[2],$dt[3],$dt[4];
        my %d = (
           current_speed        => $v->{CS}
          ,current_to_direction => $v->{CD}
        );

        # It's likely that a record already exists in the system hash.  So simply append to it . . .
        if (exists $latest_obs{$system_station}{$date}) {
          $latest_obs{$system_station}{$date}{current_speed}        = $d{current_speed};
          $latest_obs{$system_station}{$date}{current_to_direction} = $d{current_to_direction};
        }
        # . . . otherwise, add it to the hash.
        else {
          if (str2time($date) >= $min_time) {
            $latest_obs{$system_station}{$date} = \%d;
          }
        }
      }
    }
  } 
  return \%latest_obs;
}


##########################################################################################
# Brains to go get CO-OPS / NOS tide predictions.  And return the results as a hash.
##########################################################################################

sub get_nos_prediction_obs {
  use SOAP::Lite;

  my @stations = @_;
  my %latest_obs;

  # start at 0Z today; COOPS time format: 'YYYYMMDD HH:MM'
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
  my $start_time = sprintf "%4d%02d%02d %02d:00",$year+1900,$mon+1,$mday,0;

  # end 3d from 0Z today
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time() + 2 * 24 * 60 * 60);
  my $end_time = sprintf "%4d%02d%02d %02d:00",$year+1900,$mon+1,$mday,0;

  foreach my $s (@stations) {
    my $station_id = substr($s,index($s,'|')+1);
    my $system_station = substr($s,0,index($s,'|'));
    if ($debug) {print STDERR "NOS $system_station (water level predictions)\n";}

    # Get water level first
    my $service = SOAP::Lite->service('http://opendap.co-ops.nos.noaa.gov/axis/webservices/predictions/wsdl/Predictions.wsdl')->want_som(1);
    my $response = $service->getPredictions($station_id, $start_time, $end_time,1, 0, 0, 6);

    if(!$response->fault()) {
      # Get all the obs.
      foreach my $v ($response->valueof('//data/item')) {
        # Get the date in the right format.
        my @dt = split(/\/| |\:/,$v->{timeStamp});
        my $date = sprintf "%04d%02d%02dT%02d%02dZ",$dt[2],$dt[0],$dt[1],$dt[3],$dt[4];
        
        my %d = (
          predicated_water_level_in_msl => $v->{pred}
        );

        # Add it to the hash.
        $latest_obs{$system_station}{$date} = \%d;
      }
    }
  }
  return \%latest_obs;
}


################################################################################
# Brains to go get SEACOOS observations.  And return the results as a hash.
################################################################################

sub get_seacoos_obs {

  # This will loop through the 'latest' obs and only return ONE obs
  # per location per data type.  So if it pulls back multiple obs for
  # one location per data type, you're not guaranteed to get the latest.
  # So it makes sense to do this at frequent intervals so that you only
  # d/l the latest.

#  use SeacoosNetcdf;
  
  my @stations = @_;
  my %latest_obs;
  
  # Fetch all the SEACOOS obs.
  my %o = %{&SeacoosNetcdf::get_latest_obs};

  #my @stations=("cormp.OCP1.buoy","cormp.ILM2.buoy");

  foreach my $s (@stations) {
    
    if (defined $o{$s}) {
  #    print "I am here";   
      if ($debug) {print STDERR "SEACOOS $s\n";}
      my $date = $o{$s}{time}.'Z';
      delete $o{$s}{time};
     
      $latest_obs{$s}{$date} = $o{$s};
    }
    #else { print "I am not in\n";}
  }
  return \%latest_obs;
}

1;
