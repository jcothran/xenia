#Revisions
#Rev: 1.1.1.0
#Fixed up passing unitialized values for north/east current and mag/dir. Symptom was values being reported as 0 when really they were missing.

sub fixed_point() {


  # top timestamp
  $this_station_id_top_ts = $_[0];
  #DWR 4/7/2008
  my $FileCreationOptions = $_[1];
  my $strObsKMLFilePath = $_[2];
  #DWR v1.1.0.0 6/2/2008
  my $iLastNTimeStamps  = $_[3];
  
  print( "fixed_point::args: this_station_id_top_ts: $this_station_id_top_ts FileCreationOptions: $FileCreationOptions strObsKMLFilePath: $strObsKMLFilePath iLastNTimeStamps: $iLastNTimeStamps\n");
  my $bWriteSQLFiles = 1;
  my $bWriteobsKMLFile = 0;
  if( $FileCreationOptions == WRITEKMLONLY )
  {
   $bWriteSQLFiles = 0;
   $bWriteobsKMLFile = 1;
  }
  elsif( $FileCreationOptions == WRITEBOTH )
  {
   $bWriteobsKMLFile = 1;   
  }
  
  #DWR 4/5/2008
  #The XML file that has our obsKML units conversion. WE use it here to convert the units string names from the netcdf
  #file into the strings we use in the obsKML and then in our database.
  my $strUnitsXMLFilename;
  $strUnitsXMLFilename = './UnitsConversion.xml';
  my $XMLControlFile = XML::LibXML->new->parse_file("$strUnitsXMLFilename");
  
  my %ObsHash;
  my $rObsHash = \%ObsHash;
  my $strPlatformID = $institution_code_value.'.'.$platform_code_value.'.'.$package_code_value;
  
  #
  # Loop through variables looking for standard_name's
  
  my $this_var_name = '';
  my $this_var_type = '';
  my $this_var_dims = '';
  my @this_var_dimid = '';
  my $this_var_natts = '';
  my $this_standard_name = '';
  my $j = 0;
  
  for ($i = 0; $i < $nvars; $i++) {
    my $varinq = NetCDF::varinq($ncid, $i, \$this_var_name, 
      \$this_var_type, \$this_var_dims, \@this_var_dimid, \$this_var_natts);
    if ($varinq < 0) {die "ABORT!  Cannot get to variables.\n";}
    my $attget = NetCDF::attget($ncid, $i, 'standard_name', \$this_standard_name);
    if (substr($this_standard_name,length($this_standard_name)-1) eq chr(0))   {chop($this_standard_name);}
    if ($attget >= 0) {
      if ($this_standard_name =~ /^time$/) {
        %time_dim = (
          ref_var_name => $this_var_name,
          ref_var_id   => $i,
          dim_id       => '',
          dim_name     => '',
          dim_size     => ''
        );
        if ($this_var_dims != 1) {die "ABORT! Time has incorrect number of dimensions.\n";}
        %time_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0]
        );
      }
      elsif ($this_standard_name =~ /^longitude$/) {
        %longitude_dim = (
          ref_var_name => $this_var_name,
          ref_var_id   => $i,
          dim_id       => '',
          dim_name     => '',
          dim_size     => ''
        );
        if ($this_var_dims != 1) {die "ABORT! Longitude has incorrect number of dimensions.\n";}
        %longitude_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0]
        );
      }
      elsif ($this_standard_name =~ /^latitude$/) {
        %latitude_dim = (
          ref_var_name => $this_var_name,
          ref_var_id   => $i,
          dim_id       => '',
          dim_name     => '',
          dim_size     => ''
        );
        if ($this_var_dims != 1) {die "ABORT! Latitude has incorrect number of dimensions.\n";}
        %latitude_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0]
        );
      }
      elsif ($this_standard_name =~ /^height$/) {
        %height_dim = (
          ref_var_name => $this_var_name,
          ref_var_id   => $i,
          dim_id       => '',
          dim_name     => '',
          dim_size     => ''
        );
        if ($this_var_dims != 1) {die "ABORT! Height has incorrect number of dimensions.\n";}
        %height_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          positive => ''
        );
      }
      # push all water_level's onto a stack
      elsif ($this_standard_name =~ /^water_level$/) {
        %this_water_level = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          reference         => '',
          reference_to_mllw => '',
          reference_to_msl  => '',
          reference_to_navd88  => '',
          units => ''       #DWR 4/5/2008
        );
        push @water_level, {%this_water_level};
      }
      # push all sea_surface_temperature's onto a stack
      elsif ($this_standard_name =~ /^sea_surface_temperature$/) {
        %this_sea_surface_temperature = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units => ''       #DWR 4/5/2008
        );
        push @sea_surface_temperature, {%this_sea_surface_temperature};
      }
      # push all bottom_water_temp's onto a stack
      elsif ($this_standard_name =~ /^sea_bottom_temperature$/) {
        %this_sea_bottom_temperature = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       #DWR 4/5/2008
        );
        push @sea_bottom_temperature, {%this_sea_bottom_temperature};
      }
      # push all air_temperature's onto a stack
      elsif ($this_standard_name =~ /^air_temperature$/) {
        %this_air_temperature = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       #DWR 4/5/2008
        );
        push @air_temperature, {%this_air_temperature};
      }
      # push all wind_speed's onto a stack
      elsif ($this_standard_name =~ /^wind_speed$/) {
        %this_wind_speed = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          can_be_normalized => '',
          units             => ''       #DWR 4/5/2008
        );
        push @wind_speed, {%this_wind_speed};
      }
      # push all wind_gust's onto a stack
      elsif ($this_standard_name =~ /^wind_gust$/) {
        %this_wind_gust = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          can_be_normalized => '',
          units             => ''       #DWR 4/5/2008
        );
        push @wind_gust, {%this_wind_gust};
      }
      # push all wind_from_direction's onto a stack
      elsif ($this_standard_name =~ /^wind_from_direction$/) {
        %this_wind_from_direction = (
          var_name => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          can_be_normalized => '',
          units             => ''       #DWR 4/5/2008
          
        );
        push @wind_from_direction, {%this_wind_from_direction};
      }
      # push all air_pressure's onto a stack
      elsif ($this_standard_name =~ /^air_pressure$/) {
        %this_air_pressure = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       #DWR 4/5/2008
        );
        push @air_pressure, {%this_air_pressure};
      }
      # push all salinity's onto a stack
      elsif ($this_standard_name =~ /^salinity$/) {
        %this_salinity = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       #DWR 4/5/2008
        );
        push @salinity, {%this_salinity};
      }
      # push all sea_surface_eastward_current's onto a stack
      elsif ($this_standard_name =~ /^sea_surface_eastward_current$/) {
        %this_sea_surface_eastward_current = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          units             => ''       #DWR 4/5/2008
        );
        push @sea_surface_eastward_current, {%this_sea_surface_eastward_current};
      }
      # push all sea_surface_northward_current's onto a stack
      elsif ($this_standard_name =~ /^sea_surface_northward_current$/) {
        %this_sea_surface_northward_current = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          units             => ''       #DWR 4/5/2008
        );
        push @sea_surface_northward_current, {%this_sea_surface_northward_current};
      }
      # push all significant_wave_height's onto a stack
      elsif ($this_standard_name =~ /^significant_wave_height$/) {
        %this_significant_wave_height = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          units             => ''       #DWR 4/5/2008
        );
        push @significant_wave_height, {%this_significant_wave_height};
      }
      # push all dominant_wave_period's onto a stack
      elsif ($this_standard_name =~ /^dominant_wave_period$/) {
        %this_dominant_wave_period = (
          var_name          => $this_var_name,
          var_id            => $i,
          dim_id            => $this_var_dimid[0],
          height            => '',
          units             => ''       #DWR 4/5/2008
        );
        push @dominant_wave_period, {%this_dominant_wave_period};
      }
      #DWR 5/25/2010
      # push all relative_humidity's onto a stack
      elsif ($this_standard_name =~ /^relative_humidity$/) {
        %this_relative_humidity = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       
        );
        push @relative_humidity, {%this_relative_humidity};
      }
      #DWR 5/25/2010
      # push all relative_humidity's onto a stack
      elsif ($this_standard_name =~ /^chl_concentration$/) {
        %this_chl_concentration = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          units    => ''       
        );
        push @chl_concentration, {%this_chl_concentration};
      }
      
    }
  }
  
  #
  # Required dimensions:  time, longitude, latitude, height
  # Find out names through the variables.
  # Abort if all are not found.
  
  if (length($time_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No time dimension ref. found via variable.\n";
  }
  if (length($longitude_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No longitude dimension ref. found via variable.\n";
  }
  if (length($latitude_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No latitude dimension ref. found via variable.\n";
  }
  if (length($height_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No height dimension ref. found via variable.\n";
  } 
  if (length $err > 0) {
    die $err;
  }

  #
  # Get the dimensions and their sizes.
  
  # time
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,$time_dim{'ref_var_name'});
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $time_dim{'dim_id'}   = $this_dim_id;
      $time_dim{'dim_name'} = $this_dim_name;
      $time_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting time dimension.\n";
    }
  #  print "time dim_name [$time_dim{'dim_name'}] dim_size [$time_dim{'dim_size'}]\n";
  }
  
  # longitude
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,$longitude_dim{'ref_var_name'});
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $longitude_dim{'dim_id'}   = $this_dim_id;
      $longitude_dim{'dim_name'} = $this_dim_name;
      $longitude_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting longitude dimension.\n";
    }
  #  print "longitude dim_name [$longitude_dim{'dim_name'}] dim_size [$longitude_dim{'dim_size'}]  \n";
  }
  
  # latitude
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,$latitude_dim{'ref_var_name'});
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $latitude_dim{'dim_id'}   = $this_dim_id;
      $latitude_dim{'dim_name'} = $this_dim_name;
      $latitude_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting latitude dimension.\n";
    }
  #  print "latitude dim_name [$latitude_dim{'dim_name'}] dim_size [$latitude_dim{'dim_size'}]\n";
  }
  
  # height
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,$height_dim{'ref_var_name'});
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $height_dim{'dim_id'}   = $this_dim_id;
      $height_dim{'dim_name'} = $this_dim_name;
      $height_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting height dimension.\n";
    }
  #  print "height dim_name [$height_dim{'dim_name'}] dim_size [$height_dim{'dim_size'}]\n";
  }
  
  #
  # Check to make sure that the required variables have
  # the correct dimensions listed, e.g. time(time), longitude(longitude), etc.
  
  # time
  if ($time_var{'dim_id'} != $time_dim{'dim_id'}) {
    die "ABORT! Time variable does not have correct time dimension.\n";
  }
  # longitude
  if ($longitude_var{'dim_id'} != $longitude_dim{'dim_id'}) {
    die "ABORT! Longitude variable does not have correct longitude dimension.\n";
  }
  # latitude
  if ($latitude_var{'dim_id'} != $latitude_dim{'dim_id'}) {
    die "ABORT! Latitude variable does not have correct latitude dimension.\n";
  }
  # height
  if ($height_var{'dim_id'} != $height_dim{'dim_id'}) {
    die "ABORT! Height variable does not have correct height dimension.\n";
  }
 
  #
  # Get the data of the required elements.
  @time_values           = '';
  @time_formatted_values = '';
  @longitude_value       = '';
  @latitude_value        = '';
  @height_value          = '';
  my $positive_value     = '';
  
  # time
  # get all the values
  my $units_value = '';
  my $varget = NetCDF::varget($ncid, $time_var{'var_id'}, (0), $time_dim{'dim_size'},   \@time_values);
  if ($varget < 0) {die "ABORT! Cannot get time values.\n";}
  #DWR v1.1.0.0
  #If we using the last N times, let's populate the array.
   my $iStartingNdx = 0;
  if( $iLastNTimeStamps > 0 )
  {
    #If we have more entries in the time_values array, let's set the starting index at the spot in the array which   
    #will get us to the first of the N time stamps.
    my $iTimeCnt = @time_values;
    print( "iTimeCnt: $iTimeCnt iLastNTimeStamps: $iLastNTimeStamps\n" );
    if( $iTimeCnt > $iLastNTimeStamps )
    {
      $iStartingNdx = $iTimeCnt - $iLastNTimeStamps;
      if( USE_DEBUG_PRINTS )
      {
        print( "fixed_point()::Printing Last: $iLastNTimeStamps out of $iTimeCnt entries. Starting Index: $iStartingNdx. $ncid\n" );
      }
    }
   elsif( $iLastNTimeStamps > $iTimeCnt )
   {
    print( "fixed_point()::iLastNTimeStamps: $iLastNTimeStamps is greater than total number of times in file. Resetting to iLastNTimeStamps to $iTimeCnt\n" );
    $iLastNTimeStamps = $iTimeCnt;
   }
  }
  # get the units
  my $attget = NetCDF::attget($ncid, $time_var{'var_id'}, 'units', \$units_value);
  if ($attget < 0) {die "ABORT! $time_var{'var_name'} has no units.\n";}
  if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
  my $base_time = UDUNITS::scan($units_value)
    || die "ABORT! Error with $time_var{'var_name'} units.\n";
  $base_time->istime()
    || die "ABORT! Invalid units for $time_var{'var_name'}.\n";
  
  my @KMLTimeStamp;
  # format the time values for database insertion (no timezone right now)
  for my $i (0..$#time_values) {
    # convert the time value to new value based on the time units
    my $this_time_value = $base_time->valtocal($time_values[$i], 
      $base_year, $base_month, $base_day, $base_hour, $base_minute, $base_second) == 0
      || die "ABORT! Invalid units for $time_var{'var_name'}.\n";
    $time_formatted_values[$i] = $base_year.'-'
      .sprintf("%02d",$base_month).'-'
      .sprintf("%02d",$base_day).' '
      .sprintf("%02d",$base_hour).':'
      .sprintf("%02d",$base_minute).':'
      .sprintf("%02d",$base_second);
     #DWR 4/16/2008
     #KML tag <TimeStamp><when> requires the date to be formatted in a YYYY-MM-DDThh:mm:ss format
     $KMLTimeStamp[$i] = $base_year.'-'
      .sprintf("%02d",$base_month).'-'
      .sprintf("%02d",$base_day).'T'
      .sprintf("%02d",$base_hour).':'
      .sprintf("%02d",$base_minute).':'
      .sprintf("%02d",$base_second);

  }
  
  # longitude (scalar)
  $varget = NetCDF::varget($ncid, $longitude_var{'var_id'}, (0), (1), \@longitude_value);
  if ($varget < 0) {die "ABORT! Cannot get longitude value.\n";}
  
  # latitude (scalar)
  $varget = NetCDF::varget($ncid, $latitude_var{'var_id'}, (0), (1), \@latitude_value);
  if ($varget < 0) {die "ABORT! Cannot get latitude value.\n";}
  
  # height
  #   if count(height) == 1 then this is for all variables
  #   Otherwise, we can ignore the z values passed as parameters and need
  #   to look at each variable's attributes
  if ($height_dim{'dim_size'} == 1) {
    $varget = NetCDF::varget($ncid, $height_var{'var_id'}, (0), (1), \@height_value);
    if ($varget < 0) {die "ABORT! Cannot get height value.\n";}
  }
  # get the positive attribute
  $attget = NetCDF::attget($ncid, $height_var{'var_id'}, 'positive', \$positive_value);
  if (substr($positive_value,length($positive_value)-1) eq chr(0)) {chop($positive_value);}
  $height_var{'positive'} = $positive_value;

  # water_level's
  @this_water_level_data = '';
  for $i (0..$#water_level) {
    # this variable's dimension better be time
    if ($water_level[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $water_level[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $water_level[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_water_level_data);
      if ($varget < 0) {die "ABORT! Cannot get $water_level[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';

      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $water_level[$i]{'var_name'} has no units.\n";
      }
      $water_level[$i]{'units'} = $units_value;
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $water_level[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $water_level[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $water_level[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $water_level[$i]{'height'} = $attval;
        }
        elsif ($this_attname =~ /^reference$/) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $water_level[$i]{'reference'} = $attval;
        }
        elsif ($this_attname =~ /^reference_to_MLLW$/) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $water_level[$i]{'reference_to_mllw'} = $attval;
        }
        elsif ($this_attname =~ /^reference_to_MSL$/) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $water_level[$i]{'reference_to_msl'} = $attval;
        }
        elsif ($this_attname =~ /^reference_to_NAVD88$/) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $water_level[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $water_level[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $water_level[$i]{'reference_to_navd88'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($water_level[$i]{'height'} == '') {
        $water_level[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_water_level_data) {
        push @{$water_level[$i]{'data'}}, $this_water_level_data[$j];
      }
    }
  }
  
  # sea_surface_temperature's
  @this_sea_surface_temperature_data = '';
  for $i (0..$#sea_surface_temperature) {
    # this variable's dimension better be time
    if ($sea_surface_temperature[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $sea_surface_temperature[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $sea_surface_temperature[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_sea_surface_temperature_data);
      if ($varget < 0) {die "ABORT! Cannot get $sea_surface_temperature[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';

      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $sea_surface_temperature[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $sea_surface_temperature[$i]{'var_name'} has no units.\n";
      }
      $sea_surface_temperature[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $sea_surface_temperature[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $sea_surface_temperature[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $sea_surface_temperature[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $sea_surface_temperature[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $sea_surface_temperature[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $sea_surface_temperature[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $sea_surface_temperature[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($sea_surface_temperature[$i]{'height'} == '') {
        $sea_surface_temperature[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_sea_surface_temperature_data) {
        push @{$sea_surface_temperature[$i]{'data'}}, $this_sea_surface_temperature_data[$j];
      }
    }
  }

  # sea_bottom_temperature's
  @this_sea_bottom_temperature_data = '';
  for $i (0..$#sea_bottom_temperature) {
    # this variable's dimension better be time
    if ($sea_bottom_temperature[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $sea_bottom_temperature[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $sea_bottom_temperature[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_sea_bottom_temperature_data);
      if ($varget < 0) {die "ABORT! Cannot get $sea_bottom_temperature[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';

      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $sea_bottom_temperature[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $sea_bottom_temperature[$i]{'var_name'} has no units.\n";
      }
      $sea_bottom_temperature[$i]{'units'} = $units_value;

      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $sea_bottom_temperature[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $sea_bottom_temperature[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $sea_bottom_temperature[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $sea_bottom_temperature[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $sea_bottom_temperature[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $sea_bottom_temperature[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $sea_bottom_temperature[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($sea_bottom_temperature[$i]{'height'} == '') {
        $sea_bottom_temperature[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_sea_bottom_temperature_data) {
        push @{$sea_bottom_temperature[$i]{'data'}}, $this_sea_bottom_temperature_data[$j];
      }
    }
  }

  # air_temperature's
  @this_air_temperature_data = '';
  for $i (0..$#air_temperature) {
    # this variable's dimension better be time
    if ($air_temperature[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $air_temperature[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $air_temperature[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_air_temperature_data);
      if ($varget < 0) {die "ABORT! Cannot get $air_temperature[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $air_temperature[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $air_temperature[$i]{'var_name'} has no units.\n";
      }
      $air_temperature[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $air_temperature[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $air_temperature[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $air_temperature[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $air_temperature[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $air_temperature[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $air_temperature[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $air_temperature[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($air_temperature[$i]{'height'} == '') {
        $air_temperature[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_air_temperature_data) {
        push @{$air_temperature[$i]{'data'}}, $this_air_temperature_data[$j];
      }
    }
  }

  # wind_speed's
  @this_wind_speed_data = '';
  for $i (0..$#wind_speed) {
    # this variable's dimension better be time
    if ($wind_speed[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $wind_speed[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $wind_speed[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_wind_speed_data);
      if ($varget < 0) {die "ABORT! Cannot get $wind_speed[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';

      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $wind_speed[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $wind_speed[$i]{'var_name'} has no units.\n";
      }
      $wind_speed[$i]{'units'} = $units_value;
      
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $wind_speed[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $wind_speed[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $wind_speed[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $wind_speed[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_speed[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_speed[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_speed[$i]{'height'} = $attval;
        }
        elsif ($this_attname eq 'can_be_normalized') {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_speed[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_speed[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_speed[$i]{'can_be_normalized'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($wind_speed[$i]{'height'} == '') {
        $wind_speed[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_speed_data) {
        push @{$wind_speed[$i]{'data'}}, $this_wind_speed_data[$j];
      }
    }
  }
  
  # wind_gust's
  @this_wind_gust_data = '';
  for $i (0..$#wind_gust) {
    # this variable's dimension better be time
    if ($wind_gust[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $wind_gust[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $wind_gust[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_wind_gust_data);
      if ($varget < 0) {die "ABORT! Cannot get $wind_gust[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $wind_gust[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $wind_gust[$i]{'var_name'} has no units.\n";
      }
      $wind_gust[$i]{'units'} = $units_value;

      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $wind_gust[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $wind_gust[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $wind_gust[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $wind_gust[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_gust[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_gust[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_gust[$i]{'height'} = $attval;
        }
        elsif ($this_attname eq 'can_be_normalized') {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_gust[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_gust[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_gust[$i]{'can_be_normalized'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($wind_gust[$i]{'height'} == '') {
        $wind_gust[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_gust_data) {
        push @{$wind_gust[$i]{'data'}}, $this_wind_gust_data[$j];
        #print( "$this_wind_gust_data $j: $this_wind_gust_data[$j] wind_gust $i: $wind_gust[$i]{'data'} \n" );
      }
    }
  }
  
  # wind_from_direction's
  @this_wind_from_direction_data = '';
  for $i (0..$#wind_from_direction) {
    # this variable's dimension better be time
    if ($wind_from_direction[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $wind_from_direction[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
     
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $wind_from_direction[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $wind_from_direction[$i]{'var_name'} has no units.\n";
      }
      $wind_from_direction[$i]{'units'} = $units_value;
     
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $wind_from_direction[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_wind_from_direction_data);
      if ($varget < 0) {die "ABORT! Cannot get $wind_from_direction[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $wind_from_direction[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $wind_from_direction[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $wind_from_direction[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $wind_from_direction[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_from_direction[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_from_direction[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_from_direction[$i]{'height'} = $attval;
        }
        elsif ($this_attname eq 'can_be_normalized') {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_speed[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_speed[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_from_direction[$i]{'can_be_normalized'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($wind_from_direction[$i]{'height'} == '') {
        $wind_from_direction[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_from_direction_data) {
        push @{$wind_from_direction[$i]{'data'}}, $this_wind_from_direction_data[$j];
      }
    }
  }
  
  # air_pressure's
  @this_air_pressure_data = '';
  for $i (0..$#air_pressure) {
    # this variable's dimension better be time
    if ($air_pressure[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $air_pressure[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
         
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $air_pressure[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_air_pressure_data);
      if ($varget < 0) {die "ABORT! Cannot get $air_pressure[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # check for units
      my $units_value    = '';
      my $this_slope     = '';
      my $this_intercept = '';
      my $attget = NetCDF::attget($ncid, $air_pressure[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $air_pressure[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $air_pressure[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('bar');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      
      #DWR 4/5/2008
      #DWR v1.1.1.0
      #Hardcode millibras string since the conversion below on the data is hardcoded and does not come from UDUNITS.
      $air_pressure[$i]{'units'} = "millibar";
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $air_pressure[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $air_pressure[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $air_pressure[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $air_pressure[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $air_pressure[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $air_pressure[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $air_pressure[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($air_pressure[$i]{'height'} == '') {
        $air_pressure[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_air_pressure_data) {
        # target is millibars
	#cancel out conversion operation if missing value
	#also canceling conversion if air_pressure > 900
	#print "$this_air_pressure_data[$j]\n";
	if ($this_air_pressure_data[$j] == $missing_value_value || $this_air_pressure_data[$j] == $Fill_value_value || $this_air_pressure_data[$j] > 900) 
	{ 
	  $this_slope = 1; $this_intercept = 0;
	} else
	{ 
	  $this_slope = 1000; $this_intercept = 0;
	} 
print STATION_ID_SQLFILE "-- this_air_pressure_data[j]=".$this_air_pressure_data[$j]." missing_value_value=".$missing_value_value." Fill_value_value=".$Fill_value_value."\n";
        push @{$air_pressure[$i]{'data'}},
          ($this_air_pressure_data[$j] * $this_slope + $this_intercept);
	#print "$this_air_pressure_data[$j] * $this_slope + $this_intercept)\n";
	#$test_val = ($this_air_pressure_data[$j] * $this_slope + $this_intercept);
	#print "$test_val\n";
      }
    }
  }
  
  # salinity's
  @this_salinity_data = '';
  for $i (0..$#salinity) {
    # this variable's dimension better be time
    if ($salinity[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $salinity[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
     
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $salinity[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $salinity[$i]{'var_name'} has no units.\n";
      }
      $salinity[$i]{'units'} = $units_value;
     
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $salinity[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_salinity_data);
      if ($varget < 0) {die "ABORT! Cannot get $salinity[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $salinity[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $salinity[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $salinity[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $salinity[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $salinity[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $salinity[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $salinity[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($salinity[$i]{'height'} == '') {
        $salinity[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_salinity_data) {
        push @{$salinity[$i]{'data'}}, $this_salinity_data[$j];
      }
    }
  }
  
  # sea_surface_eastward_current's
  @this_sea_surface_eastward_current_data = '';
  for $i (0..$#sea_surface_eastward_current) {
    # this variable's dimension better be time
    if ($sea_surface_eastward_current[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $sea_surface_eastward_current[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {             
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $sea_surface_eastward_current[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_sea_surface_eastward_current_data);

      if ($varget < 0) {die "ABORT! Cannot get $sea_surface_eastward_current[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # check for units
      my $units_value    = '';
      my $this_slope     = '';
      my $this_intercept = '';
      my $attget = NetCDF::attget($ncid, $sea_surface_eastward_current[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $sea_surface_eastward_current[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $sea_surface_eastward_current[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);

      #DWR 4/5/2008
      $sea_surface_eastward_current[$i]{'units'} = 'm_s-1';

      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $sea_surface_eastward_current[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $sea_surface_eastward_current[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $sea_surface_eastward_current[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $sea_surface_eastward_current[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $sea_surface_eastward_current[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $sea_surface_eastward_current[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $sea_surface_eastward_current[$i]{'height'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($sea_surface_eastward_current[$i]{'height'} == '') {
        $sea_surface_eastward_current[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_sea_surface_eastward_current_data) {
    	#cancel out conversion operation if missing value
    	if ($this_sea_surface_eastward_current_data[$j] == $missing_value_value || $this_sea_surface_eastward_current_data[$j] == $Fill_value_value) { $this_slope = 1; $this_intercept = 0; }
        push @{$sea_surface_eastward_current[$i]{'data'}},
          ($this_sea_surface_eastward_current_data[$j] * $this_slope + $this_intercept);
      }
    }
  }
  
  # sea_surface_northward_current's
  @this_sea_surface_northward_current_data = '';
  for $i (0..$#sea_surface_northward_current) {
    # this variable's dimension better be time
    if ($sea_surface_northward_current[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $sea_surface_northward_current[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
         
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $sea_surface_northward_current[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_sea_surface_northward_current_data);
      if ($varget < 0) {die "ABORT! Cannot get $sea_surface_northward_current[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # check for units
      my $units_value    = '';
      my $this_slope     = '';
      my $this_intercept = '';
      my $attget = NetCDF::attget($ncid, $sea_surface_northward_current[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $sea_surface_northward_current[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $sea_surface_northward_current[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      #DWR 4/5/2008
      $sea_surface_northward_current[$i]{'units'} = 'm_s-1';
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $sea_surface_northward_current[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $sea_surface_northward_current[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $sea_surface_northward_current[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $sea_surface_northward_current[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $sea_surface_northward_current[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $sea_surface_northward_current[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $sea_surface_northward_current[$i]{'height'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($sea_surface_northward_current[$i]{'height'} == '') {
        $sea_surface_northward_current[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_sea_surface_northward_current_data) {
	#cancel out conversion operation if missing value
	if ($this_sea_surface_northward_current_data[$j] == $missing_value_value || $this_sea_surface_northward_current_data[$j] == $Fill_value_value) { $this_slope = 1; $this_intercept = 0; }
        push @{$sea_surface_northward_current[$i]{'data'}},
          ($this_sea_surface_northward_current_data[$j] * $this_slope + $this_intercept);
      }
    }
  }
  
  # significant_wave_height's
  @this_significant_wave_height_data = '';
  for $i (0..$#significant_wave_height) {
    # this variable's dimension better be time
    if ($significant_wave_height[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $significant_wave_height[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
          
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $significant_wave_height[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_significant_wave_height_data);
      if ($varget < 0) {die "ABORT! Cannot get $significant_wave_height[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # check for units
      my $units_value    = '';
      my $this_slope     = '';
      my $this_intercept = '';
      my $attget = NetCDF::attget($ncid, $significant_wave_height[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $significant_wave_height[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $significant_wave_height[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      #DWR 4/5/2008
      $significant_wave_height[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $significant_wave_height[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $significant_wave_height[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $significant_wave_height[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $significant_wave_height[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $significant_wave_height[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $significant_wave_height[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $significant_wave_height[$i]{'height'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if (length $significant_wave_height[$i]{'height'} <= 0) {
        $significant_wave_height[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_significant_wave_height_data) {
	#cancel out conversion operation if missing value
	if ($this_significant_wave_height_data[$j] == $missing_value_value || $this_significant_wave_height_data[$j] == $Fill_value_value) { $this_slope = 1; $this_intercept = 0; }
        push @{$significant_wave_height[$i]{'data'}},
          ($this_significant_wave_height_data[$j] * $this_slope + $this_intercept);
      }
    }
  }
  
  # dominant_wave_period's
  @this_dominant_wave_period_data = '';
  for $i (0..$#dominant_wave_period) {
    # this variable's dimension better be time
    if ($dominant_wave_period[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $dominant_wave_period[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
          
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $dominant_wave_period[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_dominant_wave_period_data);
      if ($varget < 0) {die "ABORT! Cannot get $dominant_wave_period[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      # check for units
      my $units_value    = '';
      my $this_slope     = '';
      my $this_intercept = '';
      my $attget = NetCDF::attget($ncid, $dominant_wave_period[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $dominant_wave_period[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $dominant_wave_period[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('second');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      #DWR 4/5/2008
      $dominant_wave_period[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $dominant_wave_period[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $dominant_wave_period[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $dominant_wave_period[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $dominant_wave_period[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $dominant_wave_period[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $dominant_wave_period[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $dominant_wave_period[$i]{'height'} = $attval;
        }
      }
      # if we didn't have an height attribute, assign the global one to this var
      if (length $dominant_wave_period[$i]{'height'} <= 0) {
        $dominant_wave_period[$i]{'height'} = $height_value[0];
      }
      # add a NULL where missing value
      for my $j (0..$#this_dominant_wave_period_data) {
	#cancel out conversion operation if missing value
	if ($this_dominant_wave_period_data[$j] == $missing_value_value || $this_dominant_wave_period_data[$j] == $Fill_value_value) { $this_slope = 1; $this_intercept = 0; }
        push @{$dominant_wave_period[$i]{'data'}},
          ($this_dominant_wave_period_data[$j] * $this_slope + $this_intercept);
      }
    }
  }
  
  #DWR 5/25/1010
  # relative_humidity's
  @this_relative_humidity_data = '';
  for $i (0..$#relative_humidity) {
    # this variable's dimension better be time
    if ($relative_humidity[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $relative_humidity[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $relative_humidity[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_relative_humidity_data);
      if ($varget < 0) {die "ABORT! Cannot get $relative_humidity[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $relative_humidity[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $relative_humidity[$i]{'var_name'} has no units.\n";
      }
      $relative_humidity[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $relative_humidity[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $relative_humidity[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $relative_humidity[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $relative_humidity[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $relative_humidity[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $relative_humidity[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $relative_humidity[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($relative_humidity[$i]{'height'} == '') {
        $relative_humidity[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_relative_humidity_data) {
        push @{$relative_humidity[$i]{'data'}}, $this_relative_humidity_data[$j];
      }
    }
  }
  #DWR 5/25/1010
  # chl_concentration's
  @this_chl_concentration_data = '';
  for $i (0..$#chl_concentration) {
    # this variable's dimension better be time
    if ($chl_concentration[$i]{'dim_id'} != $time_dim{'dim_id'}) {
      die "ABORT!  $chl_concentration[$i]{'var_name'} has wrong time dimension.\n";
    }
    else {
      # get all the variable goodies
      $varget = NetCDF::varget($ncid, $chl_concentration[$i]{'var_id'},
        (0), $time_dim{'dim_size'}, \@this_chl_concentration_data);
      if ($varget < 0) {die "ABORT! Cannot get $chl_concentration[$i]{'var_name'} data.\n";}
      # get all the attributes for this variable
      my $name    = '';
      my $nc_type = '';
      my $ndims   = '';
      my @dimids  = '';
      my $natts   = '';
      
      #DWR 4/5/2008
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $chl_concentration[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) 
      {
       die "ABORT! $chl_concentration[$i]{'var_name'} has no units.\n";
      }
      $chl_concentration[$i]{'units'} = $units_value;
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $chl_concentration[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $chl_concentration[$i]{'var_name'}   attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $chl_concentration[$i]{'var_id'}, $k,   \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $chl_concentration[$i]{'var_name'} $k   attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $chl_concentration[$i]{'var_id'}, $this_attname,   \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $chl_concentration[$i]{'var_name'} $k   attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $chl_concentration[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($chl_concentration[$i]{'height'} == '') {
        $chl_concentration[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_chl_concentration_data) {
        push @{$chl_concentration[$i]{'data'}}, $this_chl_concentration_data[$j];
      }
    }
  }
  
  
  #
  # write data to file(s)

  # station_id
  $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
  # 6/15/05 < changed to <= in next line by payne; when timestamp file doesn't exist (station has never been reported)
  # $this_station_id_top_ts has an empty value, which wasn't properly triggering the code to run,
  # so new stations weren't being created.
  if ($this_station_id_top_ts <= 0) {
    if( $bWriteSQLFiles )
    {
      open(STATION_ID_SQLFILE,'>>../sql_in_situ_station_id/in_situ_station_id_'.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'.sql');
      print STATION_ID_SQLFILE "-- format_category      = $format_category_value\n";
      print STATION_ID_SQLFILE "-- institution_code     = $institution_code_value\n";
      print STATION_ID_SQLFILE "-- platform_code        = $platform_code_value\n";
      print STATION_ID_SQLFILE "-- package_code         = $package_code_value\n";
      print STATION_ID_SQLFILE "-- title                = $title_value\n";
      print STATION_ID_SQLFILE "-- institution          = $institution_value\n";
      print STATION_ID_SQLFILE "-- institution_url      = $institution_url_value\n";
      print STATION_ID_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print STATION_ID_SQLFILE "-- source               = $source_value\n";
      print STATION_ID_SQLFILE "-- references           = $references_value\n";
      print STATION_ID_SQLFILE "-- contact              = $contact_value\n";
      print STATION_ID_SQLFILE "-- missing_value        = $missing_value_value\n";
      print STATION_ID_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      print STATION_ID_SQLFILE "INSERT INTO in_situ_station_id ("; 
      print STATION_ID_SQLFILE "station_id,";
      print STATION_ID_SQLFILE "title,";
      print STATION_ID_SQLFILE "institution,";
      print STATION_ID_SQLFILE "institution_url,";
      print STATION_ID_SQLFILE "institution_dods_url,";
      print STATION_ID_SQLFILE "source,";
      print STATION_ID_SQLFILE "refs,";
      print STATION_ID_SQLFILE "contact";
      print STATION_ID_SQLFILE ") "; 
      print STATION_ID_SQLFILE "VALUES (";
      print STATION_ID_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
      print STATION_ID_SQLFILE ','.'\''.$title_value.'\'';
      print STATION_ID_SQLFILE ','.'\''.$institution_value.'\'';
      print STATION_ID_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
      print STATION_ID_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
      print STATION_ID_SQLFILE ','.'\''.$source_value.'\'';
      print STATION_ID_SQLFILE ','.'\''.$references_value.'\'';
      print STATION_ID_SQLFILE ','.'\''.$contact_value.'\'';
      print STATION_ID_SQLFILE ");\n";
      close(STATION_ID_SQLFILE);
    }
  }
   
  # water_level (water_level)
  if ($#water_level > -1)
  {
    if( $bWriteSQLFiles )
    {
      open(WATER_LEVEL_SQLFILE,'>>../sql/water_level_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print WATER_LEVEL_SQLFILE "-- format_category      = $format_category_value\n";
      print WATER_LEVEL_SQLFILE "-- institution_code     = $institution_code_value\n";
      print WATER_LEVEL_SQLFILE "-- platform_code        = $platform_code_value\n";
      print WATER_LEVEL_SQLFILE "-- package_code         = $package_code_value\n";
      print WATER_LEVEL_SQLFILE "-- title                = $title_value\n";
      print WATER_LEVEL_SQLFILE "-- institution          = $institution_value\n";
      print WATER_LEVEL_SQLFILE "-- institution_url      = $institution_url_value\n";
      print WATER_LEVEL_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print WATER_LEVEL_SQLFILE "-- source               = $source_value\n";
      print WATER_LEVEL_SQLFILE "-- references           = $references_value\n";
      print WATER_LEVEL_SQLFILE "-- contact              = $contact_value\n";
      print WATER_LEVEL_SQLFILE "-- missing_value        = $missing_value_value\n";
      print WATER_LEVEL_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#water_level) {
        for my $j (0..$#this_water_level_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));

          if ($water_level[$i]{'data'}[$j] != $missing_value_value
            && $water_level[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print WATER_LEVEL_SQLFILE "INSERT INTO water_level_prod ("; 
            print WATER_LEVEL_SQLFILE "station_id,";
            print WATER_LEVEL_SQLFILE "time_stamp,"; 
            print WATER_LEVEL_SQLFILE "z,";
            print WATER_LEVEL_SQLFILE "positive,";
            print WATER_LEVEL_SQLFILE "water_level,";
            print WATER_LEVEL_SQLFILE "reference,";
            print WATER_LEVEL_SQLFILE "reference_to_mllw,";
            print WATER_LEVEL_SQLFILE "reference_to_msl,";
            print WATER_LEVEL_SQLFILE "reference_to_navd88,";
            print WATER_LEVEL_SQLFILE "title,";
            print WATER_LEVEL_SQLFILE "institution,";
            print WATER_LEVEL_SQLFILE "institution_url,";
            print WATER_LEVEL_SQLFILE "institution_dods_url,";
            print WATER_LEVEL_SQLFILE "source,";
            print WATER_LEVEL_SQLFILE "refs,";
            print WATER_LEVEL_SQLFILE "contact,";
            print WATER_LEVEL_SQLFILE "the_geom";
            print WATER_LEVEL_SQLFILE ") "; 
            print WATER_LEVEL_SQLFILE "VALUES ("; 
            print WATER_LEVEL_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print WATER_LEVEL_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($water_level[$i]{'height'} == $missing_value_value
              || $water_level[$i]{'height'} == $Fill_value_value) {
              print WATER_LEVEL_SQLFILE ','.'\'\'';
            }
            else {
              $this_val = sprintf("%.2f",$water_level[$i]{'height'});
              print WATER_LEVEL_SQLFILE ','.$this_val;
            }
            print WATER_LEVEL_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$water_level[$i]{'data'}[$j]);
            print WATER_LEVEL_SQLFILE ','.$this_val;
            print WATER_LEVEL_SQLFILE ','.'\''.$water_level[$i]{'reference'}.'\'';
            
            
            if (length $water_level[$i]{'reference_to_mllw'} > 0) {
              $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_mllw'});
            }
            else {
              $this_val = 'NULL';
            }

            print WATER_LEVEL_SQLFILE ','.$this_val;
            if (length $water_level[$i]{'reference_to_msl'} > 0) {
              $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_msl'});
            }
            else {
              $this_val = 'NULL';
            }

            print WATER_LEVEL_SQLFILE ','.$this_val;
            if (length $water_level[$i]{'reference_to_navd88'} > 0) {
              $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_navd88'});
            }
            else {
              $this_val = 'NULL';
            }

            print WATER_LEVEL_SQLFILE ','.$this_val;
            print WATER_LEVEL_SQLFILE ','.'\''.$title_value.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.$institution_value.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.$source_value.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.$references_value.'\'';
            print WATER_LEVEL_SQLFILE ','.'\''.$contact_value.'\'';
            print WATER_LEVEL_SQLFILE ",GeometryFromText('POINT("; 
            print WATER_LEVEL_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print WATER_LEVEL_SQLFILE ")',-1));\n";
          }
        }
        
        print WATER_LEVEL_SQLFILE "\n";
      }
      close(WATER_LEVEL_SQLFILE);
    }
    if( $bWriteobsKMLFile )
    {       
      my $MLLWDataVal = 'NULL';
      my $MSLDataVal  = 'NULL';
      my $NavD88DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#water_level) 
      {
        for my $j ($iStartingNdx..$#this_water_level_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#this_water_level_data) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {
            if ($water_level[$i]{'data'}[$j] != $missing_value_value
              && $water_level[$i]{'data'}[$j] != $Fill_value_value
              && $this_station_id_top_ts < $this_time_stamp_sec
              ) 
              {
      
                #DWR 4/3/2008
                if ($water_level[$i]{'height'} != $missing_value_value
                  && $water_level[$i]{'height'} != $Fill_value_value) 
                {
                  $this_val = sprintf("%.2f",$water_level[$i]{'height'});
                  $Height = $this_val;
                }
                $this_val = sprintf("%.2f",$water_level[$i]{'data'}[$j]);
                
                $DataVal = $this_val;
                
                if (length $water_level[$i]{'reference_to_mllw'} > 0) {
                  $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_mllw'});
                }
                else {
                  $this_val = 'NULL';
                }
                $MLLWDataVal = $DataVal + $this_val;
=comment
                if (length $water_level[$i]{'reference_to_msl'} > 0) {
                  $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_msl'});
                }
                else {
                  $this_val = 'NULL';
                }
                $MSLDataVal = $this_val;

                if (length $water_level[$i]{'reference_to_navd88'} > 0) {
                  $this_val = sprintf("%.2f",$water_level[$i]{'reference_to_navd88'});
                }
                else {
                  $this_val = 'NULL';
                }
                #DWR 4/5/2008
                $NavD88DataVal = $this_val;
=cut                
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'water_level', 
                                              $KMLTimeStamp[$j],
                                              $MLLWDataVal,
                                              1,
                                              $strPlatformID,
                                              $Height,
                                              'm(MLLW)',
                                              $rObsHash );
=comment
            obsKMLSubRoutines::KMLAddObsToHash( 'water_level', 
                                              $KMLTimeStamp[$j],
                                              $MSLDataVal,
                                              2,
                                              $strPlatformID,
                                              $Height,
                                              'm(MSL)',
                                              $rObsHash );
            obsKMLSubRoutines::KMLAddObsToHash( 'water_level', 
                                              $KMLTimeStamp[$j],
                                              $NavD88DataVal,
                                              3,
                                              $strPlatformID,
                                              $Height,
                                              'm(NAVD88)',
                                              $rObsHash );
=cut                                              
          }                                                      
        }
      }            
    }
  }
  # sea_surface_temperature (sst)
  if ($#sea_surface_temperature > -1) {
    if( $bWriteSQLFiles )
    {
      open(SST_SQLFILE,'>>../sql/sst_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print SST_SQLFILE "-- format_category      = $format_category_value\n";
      print SST_SQLFILE "-- institution_code     = $institution_code_value\n";
      print SST_SQLFILE "-- platform_code        = $platform_code_value\n";
      print SST_SQLFILE "-- package_code         = $package_code_value\n";
      print SST_SQLFILE "-- title                = $title_value\n";
      print SST_SQLFILE "-- institution          = $institution_value\n";
      print SST_SQLFILE "-- institution_url      = $institution_url_value\n";
      print SST_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print SST_SQLFILE "-- source               = $source_value\n";
      print SST_SQLFILE "-- references           = $references_value\n";
      print SST_SQLFILE "-- contact              = $contact_value\n";
      print SST_SQLFILE "-- missing_value        = $missing_value_value\n";
      print SST_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#sea_surface_temperature) {
        for my $j (0..$#this_sea_surface_temperature_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
        
          if ($sea_surface_temperature[$i]{'data'}[$j] != $missing_value_value
            && $sea_surface_temperature[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print SST_SQLFILE "INSERT INTO sst_prod ("; 
            print SST_SQLFILE "station_id,";
            print SST_SQLFILE "time_stamp,"; 
            print SST_SQLFILE "z,";
            print SST_SQLFILE "positive,";
            print SST_SQLFILE "temperature_celcius,";
            print SST_SQLFILE "title,";
            print SST_SQLFILE "institution,";
            print SST_SQLFILE "institution_url,";
            print SST_SQLFILE "institution_dods_url,";
            print SST_SQLFILE "source,";
            print SST_SQLFILE "refs,";
            print SST_SQLFILE "contact,";
            print SST_SQLFILE "the_geom";
            print SST_SQLFILE ") "; 
            print SST_SQLFILE "VALUES ("; 
            print SST_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print SST_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($sea_surface_temperature[$i]{'height'} == $missing_value_value
              || $sea_surface_temperature[$i]{'height'} == $Fill_value_value) {
              print SST_SQLFILE ','.'\'\'';
            }
            else {
              $this_val = sprintf("%.2f",$sea_surface_temperature[$i]{'height'});
              print SST_SQLFILE ','.$this_val;
            }

            print SST_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$sea_surface_temperature[$i]{'data'}[$j]);
            
            
            print SST_SQLFILE ','.$this_val;
            print SST_SQLFILE ','.'\''.$title_value.'\'';
            print SST_SQLFILE ','.'\''.$institution_value.'\'';
            print SST_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
            print SST_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
            print SST_SQLFILE ','.'\''.$source_value.'\'';
            print SST_SQLFILE ','.'\''.$references_value.'\'';
            print SST_SQLFILE ','.'\''.$contact_value.'\'';
            print SST_SQLFILE ",GeometryFromText('POINT("; 
            print SST_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print SST_SQLFILE ")',-1));\n";
          }
          
        }
        print SST_SQLFILE "\n";
      }
      close(SST_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      
      for my $i (0..$#sea_surface_temperature) 
      {
        for my $j ($iStartingNdx..$#this_sea_surface_temperature_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#this_sea_surface_temperature_data) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {        
            if ($sea_surface_temperature[$i]{'data'}[$j] != $missing_value_value
                && $sea_surface_temperature[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
               ) 
            {

              if ($sea_surface_temperature[$i]{'height'} != $missing_value_value
                && $sea_surface_temperature[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$sea_surface_temperature[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$sea_surface_temperature[$i]{'data'}[$j]);
                        
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $sea_surface_temperature[$i]{'units'}, $XMLControlFile );
            if( length( $strUnits ) == 0 )
            {
              #DWR v1.1.0.0
              #Make sure we don't have any unprintable characters.            
              $strUnits = obsKMLSubRoutines::CleanString( $sea_surface_temperature[$i]{'units'} );  
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'water_temperature', 
                                              $KMLTimeStamp[$j],
                                              $DataVal,
                                              1,
                                              $strPlatformID,
                                              $Height,
                                              $strUnits,
                                              $rObsHash );
          }                                              
        }
      }                                            
    }
  }
  # sea_bottom_temperature (sbt)
  if ($#sea_bottom_temperature > -1) {
    if( $bWriteSQLFiles )
    {
      open(SBT_SQLFILE,'>>../sql/bottom_water_temp_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print SBT_SQLFILE "-- format_category      = $format_category_value\n";
      print SBT_SQLFILE "-- institution_code     = $institution_code_value\n";
      print SBT_SQLFILE "-- platform_code        = $platform_code_value\n";
      print SBT_SQLFILE "-- package_code         = $package_code_value\n";
      print SBT_SQLFILE "-- title                = $title_value\n";
      print SBT_SQLFILE "-- institution          = $institution_value\n";
      print SBT_SQLFILE "-- institution_url      = $institution_url_value\n";
      print SBT_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print SBT_SQLFILE "-- source               = $source_value\n";
      print SBT_SQLFILE "-- references           = $references_value\n";
      print SBT_SQLFILE "-- contact              = $contact_value\n";
      print SBT_SQLFILE "-- missing_value        = $missing_value_value\n";
      print SBT_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      
      for my $i (0..$#sea_bottom_temperature) {
        for my $j (0..$#this_sea_bottom_temperature_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
        
          if ($sea_bottom_temperature[$i]{'data'}[$j] != $missing_value_value
            && $sea_bottom_temperature[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print SBT_SQLFILE "INSERT INTO bottom_water_temp_prod ("; 
            print SBT_SQLFILE "station_id,";
            print SBT_SQLFILE "time_stamp,"; 
            print SBT_SQLFILE "z,";
            print SBT_SQLFILE "positive,";
            print SBT_SQLFILE "temperature_celcius,";
            print SBT_SQLFILE "title,";
            print SBT_SQLFILE "institution,";
            print SBT_SQLFILE "institution_url,";
            print SBT_SQLFILE "institution_dods_url,";
            print SBT_SQLFILE "source,";
            print SBT_SQLFILE "refs,";
            print SBT_SQLFILE "contact,";
            print SBT_SQLFILE "the_geom";
            print SBT_SQLFILE ") "; 
            print SBT_SQLFILE "VALUES ("; 
            print SBT_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print SBT_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($sea_bottom_temperature[$i]{'height'} == $missing_value_value
              || $sea_bottom_temperature[$i]{'height'} == $Fill_value_value) {
              print SBT_SQLFILE ','.'\'\'';
            }
            else {
              $this_val = sprintf("%.2f",$sea_bottom_temperature[$i]{'height'});
              print SBT_SQLFILE ','.$this_val;
            }

            print SBT_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$sea_bottom_temperature[$i]{'data'}[$j]);
            
            
            print SBT_SQLFILE ','.$this_val;
            print SBT_SQLFILE ','.'\''.$title_value.'\'';
            print SBT_SQLFILE ','.'\''.$institution_value.'\'';
            print SBT_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
            print SBT_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
            print SBT_SQLFILE ','.'\''.$source_value.'\'';
            print SBT_SQLFILE ','.'\''.$references_value.'\'';
            print SBT_SQLFILE ','.'\''.$contact_value.'\'';
            print SBT_SQLFILE ",GeometryFromText('POINT("; 
            print SBT_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print SBT_SQLFILE ")',-1));\n";
          }

        }
        print SBT_SQLFILE "\n";
      }
      close(SBT_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#sea_bottom_temperature) 
      {
        for my $j ($iStartingNdx..$#sea_bottom_temperature)       #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#sea_bottom_temperature) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));       
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {
            if ($sea_bottom_temperature[$i]{'data'}[$j] != $missing_value_value
                && $sea_bottom_temperature[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
               ) 
            {

              if ($sea_bottom_temperature[$i]{'height'} != $missing_value_value
                && $sea_bottom_temperature[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$sea_bottom_temperature[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$sea_bottom_temperature[$i]{'data'}[$j]);
                        
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $sea_bottom_temperature[$i]{'units'}, $XMLControlFile );        
            if( length( $strUnits ) == 0 )
            {
              #DWR v1.1.0.0
              #Make sure we don't have any unprintable characters.            
              $strUnits = obsKMLSubRoutines::CleanString( $sea_bottom_temperature[$i]{'units'} );  
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'water_temperature', 
                                              $KMLTimeStamp[$j],
                                              $DataVal,
                                              2,
                                              $strPlatformID,
                                              $Height,
                                              $strUnits,
                                              $rObsHash );
          }                                              
        }
      }                                            
    }    
  }
  
  # air_temperature
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#air_temperature > -1) {
    #DWR 4/5/2008 
    if( $bWriteSQLFiles )
    {
      open(AIR_TEMP_SQLFILE,'>>../sql/air_temperature_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print AIR_TEMP_SQLFILE "-- format_category      = $format_category_value\n";
      print AIR_TEMP_SQLFILE "-- institution_code     = $institution_code_value\n";
      print AIR_TEMP_SQLFILE "-- platform_code        = $platform_code_value\n";
      print AIR_TEMP_SQLFILE "-- package_code         = $package_code_value\n";
      print AIR_TEMP_SQLFILE "-- title                = $title_value\n";
      print AIR_TEMP_SQLFILE "-- institution          = $institution_value\n";
      print AIR_TEMP_SQLFILE "-- institution_url      = $institution_url_value\n";
      print AIR_TEMP_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print AIR_TEMP_SQLFILE "-- source               = $source_value\n";
      print AIR_TEMP_SQLFILE "-- references           = $references_value\n";
      print AIR_TEMP_SQLFILE "-- contact              = $contact_value\n";
      print AIR_TEMP_SQLFILE "-- missing_value        = $missing_value_value\n";
      print AIR_TEMP_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#air_temperature) {
        for my $j (0..$#this_air_temperature_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));

          my $DataValue = 'NULL';
          my $Height    = '';
          if ($air_temperature[$i]{'data'}[$j] != $missing_value_value
            && $air_temperature[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print AIR_TEMP_SQLFILE "INSERT INTO air_temperature_prod ("; 
            print AIR_TEMP_SQLFILE "station_id,";
            print AIR_TEMP_SQLFILE "time_stamp,"; 
            print AIR_TEMP_SQLFILE "z,";
            print AIR_TEMP_SQLFILE "positive,";
            print AIR_TEMP_SQLFILE "temperature_celcius,";
            print AIR_TEMP_SQLFILE "the_geom";
            print AIR_TEMP_SQLFILE ") "; 
            print AIR_TEMP_SQLFILE "VALUES ("; 
            print AIR_TEMP_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print AIR_TEMP_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($air_temperature[$i]{'height'} == $missing_value_value
              || $air_temperature[$i]{'height'} == $Fill_value_value) {
              print AIR_TEMP_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$air_temperature[$i]{'height'});
              print AIR_TEMP_SQLFILE ','.$this_val;              
            }
            print AIR_TEMP_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$air_temperature[$i]{'data'}[$j]);
            print AIR_TEMP_SQLFILE ','.$this_val;
            print AIR_TEMP_SQLFILE ",GeometryFromText('POINT("; 
            print AIR_TEMP_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print AIR_TEMP_SQLFILE ")',-1));\n";
                       
          }
        }
        print AIR_TEMP_SQLFILE "\n";
      }
      close(AIR_TEMP_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#air_temperature) 
      {
        for my $j ($iStartingNdx..$#this_air_temperature_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#air_temperature) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {        
            if ($air_temperature[$i]{'data'}[$j] != $missing_value_value
                && $air_temperature[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
            {

              if ($air_temperature[$i]{'height'} != $missing_value_value
                && $air_temperature[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$air_temperature[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$air_temperature[$i]{'data'}[$j]);
                        
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $air_temperature[$i]{'units'}, $XMLControlFile );        
            if( length( $strUnits ) == 0 )
            {
              #DWR v1.1.0.0
              #Make sure we don't have any unprintable characters.            
              $strUnits = obsKMLSubRoutines::CleanString( $air_temperature[$i]{'units'} );  
             
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'air_temperature', 
                                              $KMLTimeStamp[$j],
                                              $DataVal,
                                              1,
                                              $strPlatformID,
                                              $Height,
                                              $strUnits,
                                              $rObsHash );
          }                                                
        }
      }                                            
    }        
  }
 

  # wind_speed and wind_gust and wind_from_direction
  # Start w/ wind_speed and then look through the wind_from_direction to find its
  # pair by looking at the heights.  This index will also define the gust.
  # Assume that wind_speed controls everything (from_dir, gust, z, normalized) index-wise.
  if ($#wind_speed > -1) {
    #dwr 4/5/2008
    if( $bWriteSQLFiles )
    {
      open(WIND_SQLFILE,'>>../sql/wind_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print WIND_SQLFILE "-- format_category      = $format_category_value\n";
      print WIND_SQLFILE "-- institution_code     = $institution_code_value\n";
      print WIND_SQLFILE "-- platform_code        = $platform_code_value\n";
      print WIND_SQLFILE "-- package_code         = $package_code_value\n";
      print WIND_SQLFILE "-- title                = $title_value\n";
      print WIND_SQLFILE "-- institution          = $institution_value\n";
      print WIND_SQLFILE "-- institution_url      = $institution_url_value\n";
      print WIND_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print WIND_SQLFILE "-- source               = $source_value\n";
      print WIND_SQLFILE "-- references           = $references_value\n";
      print WIND_SQLFILE "-- contact              = $contact_value\n";
      print WIND_SQLFILE "-- missing_value        = $missing_value_value\n";
      print WIND_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#wind_speed) {
        my $j = 0;
        while ($j <= $#wind_from_direction
          && $wind_from_direction[$j]{'height'} != $wind_speed[$i]{'height'}) {
          $j++;
        }
        if ($j > $#wind_from_direction) {
          die "ABORT!  Could not find matching wind_from_direction for $wind_speed[$i]  {'var_name'}.\n";
        }
        else {
          for my $k (0..$#this_wind_speed_data) {
            $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
            $this_time_stamp = $time_formatted_values[$k];
            $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
            
            if ($wind_speed[$i]{'data'}[$k] != $missing_value_value
              && $wind_speed[$i]{'data'}[$k] != $Fill_value_value
              && $wind_from_direction[$j]{'data'}[$k] != $missing_value_value
              && $wind_from_direction[$j]{'data'}[$k] != $Fill_value_value
              && $this_station_id_top_ts < $this_time_stamp_sec
              && $this_time_stamp_sec > $oldest_ok_timestamp) {
              print WIND_SQLFILE "INSERT INTO wind_prod ("; 
              print WIND_SQLFILE "station_id,";
              print WIND_SQLFILE "time_stamp,"; 
              print WIND_SQLFILE "z,";
              print WIND_SQLFILE "positive,";
              print WIND_SQLFILE "wind_speed,";
              print WIND_SQLFILE "wind_gust,";
              print WIND_SQLFILE "wind_from_direction,";
              print WIND_SQLFILE "can_be_normalized,";
              print WIND_SQLFILE "title,";
              print WIND_SQLFILE "institution,";
              print WIND_SQLFILE "institution_url,";
              print WIND_SQLFILE "institution_dods_url,";
              print WIND_SQLFILE "source,";
              print WIND_SQLFILE "refs,";
              print WIND_SQLFILE "contact,";
              print WIND_SQLFILE "the_geom";
              print WIND_SQLFILE ") "; 
              print WIND_SQLFILE "VALUES ("; 
              print WIND_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
              print WIND_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$k].'\'';
              if ($wind_speed[$i]{'height'} == $missing_value_value
                || $wind_speed[$i]{'height'} == $Fill_value_value) {
                print WIND_SQLFILE ','.'\'\'';
              }
              else {
                $this_val = sprintf("%.2f",$wind_speed[$i]{'height'});
                print WIND_SQLFILE ','.$this_val;
              }

              print WIND_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
              $this_val = sprintf("%.2f",$wind_speed[$i]{'data'}[$k]);
              print WIND_SQLFILE ','.$this_val;


              if ($wind_gust[$j]{'data'}[$k] == $missing_value_value
                || $wind_gust[$j]{'data'}[$k] == $Fill_value_value )
                #|| $wind_gust[$j]{'data'}[$k] == '') DWR v1.1.2.0
              {
                print WIND_SQLFILE ',NULL';
              }
              else {
                $this_val = sprintf("%.2f",$wind_gust[$j]{'data'}[$k]);
                print WIND_SQLFILE ','.$this_val;
              }
              
              $this_val = sprintf("%.2f",$wind_from_direction[$j]{'data'}[$k]);
              
              print WIND_SQLFILE ','.$this_val;
              print WIND_SQLFILE ','.'\''.$wind_speed[$i]{'can_be_normalized'}.'\'';
              print WIND_SQLFILE ','.'\''.$title_value.'\'';
              print WIND_SQLFILE ','.'\''.$institution_value.'\'';
              print WIND_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
              print WIND_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
              print WIND_SQLFILE ','.'\''.$source_value.'\'';
              print WIND_SQLFILE ','.'\''.$references_value.'\'';
              print WIND_SQLFILE ','.'\''.$contact_value.'\'';
              print WIND_SQLFILE ",GeometryFromText('POINT("; 
              print WIND_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
              print WIND_SQLFILE ")',-1));\n";
                            
            }
          }
        }
        print WIND_SQLFILE "\n";
      }
      close(WIND_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      for my $i (0..$#wind_speed) 
      {
        my $j = 0;
        while ($j <= $#wind_from_direction
          && $wind_from_direction[$j]{'height'} != $wind_speed[$i]{'height'}) 
        {
          $j++;
        }
        if ($j > $#wind_from_direction) 
        {
          die "ABORT!  Could not find matching wind_from_direction for $wind_speed[$i]  {'var_name'}.\n";
        }
        else 
        {
          for my $k ($iStartingNdx..$#this_wind_speed_data) 
          #for my $k (0..$#this_wind_speed_data) 
          {
            $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
            $this_time_stamp = $time_formatted_values[$k];
            $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
            
            my $WindSpdDataVal = 'NULL';
            my $WindDirDataVal = 'NULL';
            my $WindGstDataVal = 'NULL';
            my $Height = '';
            if( $this_time_stamp_sec > $oldest_ok_timestamp )
            {           
              if ($wind_speed[$i]{'data'}[$k] != $missing_value_value
                && $wind_speed[$i]{'data'}[$k] != $Fill_value_value
                && $wind_from_direction[$j]{'data'}[$k] != $missing_value_value
                && $wind_from_direction[$j]{'data'}[$k] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
                {
                  if ($wind_speed[$i]{'height'} != $missing_value_value
                    && $wind_speed[$i]{'height'} != $Fill_value_value) 
                  {
                    $Height = sprintf("%.2f",$wind_speed[$i]{'height'});
                  }

                  $this_val = sprintf("%.2f",$wind_speed[$i]{'data'}[$k]);
                  if( length( $this_val ) > 0 )
                  {
                    $WindSpdDataVal = $this_val;
                  }

                  if ($wind_gust[$j]{'data'}[$k] != $missing_value_value
                      && $wind_gust[$j]{'data'}[$k] != $Fill_value_value )
                      #&& $wind_gust[$j]{'data'}[$k] != '') DWR v1.1.2.0
                  {
                    $WindGstDataVal = sprintf("%.2f",$wind_gust[$j]{'data'}[$k]);
                  }
                  
                  $this_val = sprintf("%.2f",$wind_from_direction[$j]{'data'}[$k]);
                  #DWR 4/5/2008
                  if( length( $this_val ) > 0 )
                  {
                    $WindDirDataVal = $this_val;
                  }              
                }
                my $strUnits;
                $strUnits = obsKMLSubRoutines::UnitsStringConversion( $wind_speed[$i]{'units'}, $XMLControlFile );        
                if( length( $strUnits ) == 0 )
                {
                  #DWR v1.1.0.0
                  #Make sure we don't have any unprintable characters.            
                  $strUnits = obsKMLSubRoutines::CleanString( $wind_speed[$i]{'units'} );  
                 
                }
                
                obsKMLSubRoutines::KMLAddObsToHash( 'wind_speed', 
                                                    $KMLTimeStamp[$k],
                                                    $WindSpdDataVal,
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    $strUnits,
                                                    $rObsHash );
                $strUnits = '';
                $strUnits = obsKMLSubRoutines::UnitsStringConversion( $wind_from_direction[$i]{'units'}, $XMLControlFile );        
                if( length( $strUnits ) == 0 )
                {
                  #DWR v1.1.0.0
                  #Make sure we don't have any unprintable characters.            
                  $strUnits = obsKMLSubRoutines::CleanString( $wind_from_direction[$i]{'units'} );                
                }
                obsKMLSubRoutines::KMLAddObsToHash( 'wind_from_direction', 
                                                    $KMLTimeStamp[$k],
                                                    $WindDirDataVal,
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    $strUnits,
                                                    $rObsHash );
                $strUnits = '';
                $strUnits = obsKMLSubRoutines::UnitsStringConversion( $wind_gust[$i]{'units'}, $XMLControlFile );        
                if( length( $strUnits ) == 0 )
                {
                  #DWR v1.1.0.0
                  #Make sure we don't have any unprintable characters.            
                  $strUnits = obsKMLSubRoutines::CleanString( $wind_gust[$i]{'units'} );                 
                }
                obsKMLSubRoutines::KMLAddObsToHash( 'wind_gust', 
                                                    $KMLTimeStamp[$k],
                                                    $WindGstDataVal,
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    $strUnits,
                                                    $rObsHash );
            }                                                    
          }
        }
      }                                            
    }            
  }
  
  # air_pressure
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#air_pressure > -1) {
    if( $bWriteSQLFiles )
    {
      open(AIR_PRESSURE_SQLFILE,'>>../sql/air_pressure_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print AIR_PRESSURE_SQLFILE "-- format_category      = $format_category_value\n";
      print AIR_PRESSURE_SQLFILE "-- institution_code     = $institution_code_value\n";
      print AIR_PRESSURE_SQLFILE "-- platform_code        = $platform_code_value\n";
      print AIR_PRESSURE_SQLFILE "-- package_code         = $package_code_value\n";
      print AIR_PRESSURE_SQLFILE "-- title                = $title_value\n";
      print AIR_PRESSURE_SQLFILE "-- institution          = $institution_value\n";
      print AIR_PRESSURE_SQLFILE "-- institution_url      = $institution_url_value\n";
      print AIR_PRESSURE_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print AIR_PRESSURE_SQLFILE "-- source               = $source_value\n";
      print AIR_PRESSURE_SQLFILE "-- references           = $references_value\n";
      print AIR_PRESSURE_SQLFILE "-- contact              = $contact_value\n";
      print AIR_PRESSURE_SQLFILE "-- missing_value        = $missing_value_value\n";
      print AIR_PRESSURE_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#air_pressure) {
        for my $j (0..$#this_air_pressure_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          if ($air_pressure[$i]{'data'}[$j] != $missing_value_value
            && $air_pressure[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print AIR_PRESSURE_SQLFILE "INSERT INTO air_pressure_prod ("; 
            print AIR_PRESSURE_SQLFILE "station_id,";
            print AIR_PRESSURE_SQLFILE "time_stamp,"; 
            print AIR_PRESSURE_SQLFILE "z,";
            print AIR_PRESSURE_SQLFILE "positive,";
            print AIR_PRESSURE_SQLFILE "pressure,";
            print AIR_PRESSURE_SQLFILE "the_geom";
            print AIR_PRESSURE_SQLFILE ") "; 
            print AIR_PRESSURE_SQLFILE "VALUES ("; 
            print AIR_PRESSURE_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print AIR_PRESSURE_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($air_pressure[$i]{'height'} == $missing_value_value
              || $air_pressure[$i]{'height'} == $Fill_value_value) {
              print AIR_PRESSURE_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$air_pressure[$i]{'height'});
              print AIR_PRESSURE_SQLFILE ','.$this_val;
            }
            
            print AIR_PRESSURE_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$air_pressure[$i]{'data'}[$j]);
            
            print AIR_PRESSURE_SQLFILE ','.$this_val;
            print AIR_PRESSURE_SQLFILE ",GeometryFromText('POINT("; 
            print AIR_PRESSURE_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print AIR_PRESSURE_SQLFILE ")',-1));\n";
          }
          
        }
        print AIR_PRESSURE_SQLFILE "\n";
      }
      close(AIR_PRESSURE_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#air_pressure) 
      {
        for my $j ($iStartingNdx..$#this_air_pressure_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#this_air_pressure_data) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          my $DataVal = 'NULL';
          my $Height = '';
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {          
            if ($air_pressure[$i]{'data'}[$j] != $missing_value_value
              && $air_pressure[$i]{'data'}[$j] != $Fill_value_value
              && $this_station_id_top_ts < $this_time_stamp_sec
              ) {
              if ($air_pressure[$i]{'height'} != $missing_value_value
                && $air_pressure[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$air_pressure[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$air_pressure[$i]{'data'}[$j]);
            }           
            #DWR 4/3/2008
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $air_pressure[$i]{'units'}, $XMLControlFile ); 
            if( length( $strUnits ) == 0 )
            {
             #DWR v1.1.0.0
             #Make sure we don't have any unprintable characters.            
             $strUnits = obsKMLSubRoutines::CleanString( $air_pressure[$i]{'units'} );            
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'air_pressure', 
                                                $KMLTimeStamp[$j],
                                                $DataVal,
                                                1,
                                                $strPlatformID,
                                                $Height,
                                                $strUnits,
                                                $rObsHash );
          }                                                
        }
      }                                            
    }        
  }
  
  # salinity
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#salinity > -1) {
    if( $bWriteSQLFiles )
    {
      open(SALINITY_SQLFILE,'>>../sql/salinity_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print SALINITY_SQLFILE "-- format_category      = $format_category_value\n";
      print SALINITY_SQLFILE "-- institution_code     = $institution_code_value\n";
      print SALINITY_SQLFILE "-- platform_code        = $platform_code_value\n";
      print SALINITY_SQLFILE "-- package_code         = $package_code_value\n";
      print SALINITY_SQLFILE "-- title                = $title_value\n";
      print SALINITY_SQLFILE "-- institution          = $institution_value\n";
      print SALINITY_SQLFILE "-- institution_url      = $institution_url_value\n";
      print SALINITY_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print SALINITY_SQLFILE "-- source               = $source_value\n";
      print SALINITY_SQLFILE "-- references           = $references_value\n";
      print SALINITY_SQLFILE "-- contact              = $contact_value\n";
      print SALINITY_SQLFILE "-- missing_value        = $missing_value_value\n";
      print SALINITY_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#salinity) {
        for my $j (0..$#this_salinity_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          #print "debug: $salinity[$i]{'data'}[$k]\n";            
          if ($salinity[$i]{'data'}[$j] != $missing_value_value
            && $salinity[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print SALINITY_SQLFILE "INSERT INTO salinity_prod ("; 
            print SALINITY_SQLFILE "station_id,";
            print SALINITY_SQLFILE "time_stamp,"; 
            print SALINITY_SQLFILE "z,";
            print SALINITY_SQLFILE "positive,";
            print SALINITY_SQLFILE "salinity,";
            print SALINITY_SQLFILE "the_geom";
            print SALINITY_SQLFILE ") "; 
            print SALINITY_SQLFILE "VALUES ("; 
            print SALINITY_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print SALINITY_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($salinity[$i]{'height'} == $missing_value_value
              || $salinity[$i]{'height'} == $Fill_value_value) {
              print SALINITY_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$salinity[$i]{'height'});
              print SALINITY_SQLFILE ','.$this_val;
            }
            
            print SALINITY_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            $this_val = sprintf("%.2f",$salinity[$i]{'data'}[$j]);
            
            print SALINITY_SQLFILE ','.$this_val;
            print SALINITY_SQLFILE ",GeometryFromText('POINT("; 
            print SALINITY_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print SALINITY_SQLFILE ")',-1));\n";
          }          
        }
        print SALINITY_SQLFILE "\n";
      }
      close(SALINITY_SQLFILE);
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#salinity) 
      {
        for my $j ($iStartingNdx..$#this_salinity_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#this_salinity_data) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          my $DataVal = 'NULL';
          my $Height = '';
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {         
            if ($salinity[$i]{'data'}[$j] != $missing_value_value
                && $salinity[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
            {
              if ($salinity[$i]{'height'} != $missing_value_value
                && $salinity[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$salinity[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$salinity[$i]{'data'}[$j]);
            }           
            my $strUnits;
            #DWR v1.1.1.0
            #Added UnitsStringConversionfucntion.
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $salinity[$i]{'units'}, $XMLControlFile ); 
            
            if( lc( $salinity[$i]{'units'} ) eq 'ppt' )
            {
              $strUnits =  'psu';        
            }
            if( length( $strUnits ) == 0 )
            {
             #DWR v1.1.0.0
             #Make sure we don't have any unprintable characters.            
             $strUnits = obsKMLSubRoutines::CleanString( $salinity[$i]{'units'} );            
            }
            
            obsKMLSubRoutines::KMLAddObsToHash( 'salinity', 
                                                $KMLTimeStamp[$j],
                                                $DataVal,
                                                1,
                                                $strPlatformID,
                                                $Height,
                                                $strUnits,
                                                $rObsHash );
          }                                                
        }
      }                                            
    }            
  }
  
    # sea_surface_eastward_current and sea_surface_northward_current
    # Start w/ sea_surface_eastward_current and then look through the sea_surface_northward_current
    # to find its pair by looking at the heights.  (This is overkill for sea_surface_currents.
    # Assume that sea_surface_eastward_current controls everything index-wise.
    if ($#sea_surface_eastward_current > -1) 
    {
      if( $bWriteSQLFiles )
      {
        open(CURRENT_IN_SITU_SQLFILE,'>>../sql/current_in_situ_prod_'.$institution_code_value.'_'
          .$platform_code_value.'_'.$package_code_value.'.sql');
        print CURRENT_IN_SITU_SQLFILE "-- format_category      = $format_category_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- institution_code     = $institution_code_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- platform_code        = $platform_code_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- package_code         = $package_code_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- title                = $title_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- institution          = $institution_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- institution_url      = $institution_url_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- source               = $source_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- references           = $references_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- contact              = $contact_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- missing_value        = $missing_value_value\n";
        print CURRENT_IN_SITU_SQLFILE "-- _FillValue           = $Fill_value_value\n";
        for my $i (0..$#sea_surface_eastward_current) {
          my $j = 0;
          while ($j <= $#sea_surface_northward_current
            && $sea_surface_northward_current[$j]{'height'} != $sea_surface_eastward_current[$i]{'height'}) {
            $j++;
          }
          if ($j > $#sea_surface_northward_current) {
            die "ABORT!  Could not find matching sea_surface_northward_current for $sea_surface_eastward_current[$i]  {'var_name'}.\n";
          }
          else {
            for my $k (0..$#this_sea_surface_eastward_current_data) {
              $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
              $this_time_stamp = $time_formatted_values[$k];
              $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
                          
        #print "debug: $sea_surface_eastward_current[$i]{'data'}[$k]\n";            
              if ($sea_surface_eastward_current[$i]{'data'}[$k] != $missing_value_value
                && $sea_surface_eastward_current[$i]{'data'}[$k] != $Fill_value_value
                && $sea_surface_northward_current[$j]{'data'}[$k] != $missing_value_value
                && $sea_surface_northward_current[$j]{'data'}[$k] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                && $this_time_stamp_sec > $oldest_ok_timestamp) {
                print CURRENT_IN_SITU_SQLFILE "INSERT INTO current_in_situ_prod ("; 
                print CURRENT_IN_SITU_SQLFILE "station_id,";
                print CURRENT_IN_SITU_SQLFILE "time_stamp,"; 
                print CURRENT_IN_SITU_SQLFILE "z,";
                print CURRENT_IN_SITU_SQLFILE "positive,";
                print CURRENT_IN_SITU_SQLFILE "eastward_current,";
                print CURRENT_IN_SITU_SQLFILE "northward_current,";
                print CURRENT_IN_SITU_SQLFILE "surface_or_bottom,";
                print CURRENT_IN_SITU_SQLFILE "the_geom";
                print CURRENT_IN_SITU_SQLFILE ") "; 
                print CURRENT_IN_SITU_SQLFILE "VALUES ("; 
                print CURRENT_IN_SITU_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
                print CURRENT_IN_SITU_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$k].'\'';
                if ($sea_surface_eastward_current[$i]{'height'} == $missing_value_value
                  || $sea_surface_eastward_current[$i]{'height'} == $Fill_value_value) {
                  print CURRENT_IN_SITU_SQLFILE ','.'\'\'';
                }
                else {
                  $this_val = sprintf("%.2f",$sea_surface_eastward_current[$i]{'height'});
                  print CURRENT_IN_SITU_SQLFILE ','.$this_val;
                  
                }
                print CURRENT_IN_SITU_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
                $this_val = sprintf("%.2f",$sea_surface_eastward_current[$i]{'data'}[$k]);
                
                print CURRENT_IN_SITU_SQLFILE ','.$this_val;
                $this_val = sprintf("%.2f",$sea_surface_northward_current[$j]{'data'}[$k]);

                print CURRENT_IN_SITU_SQLFILE ','.$this_val;
                print CURRENT_IN_SITU_SQLFILE ','.'\'surface\'';
                print CURRENT_IN_SITU_SQLFILE ",GeometryFromText('POINT("; 
                print CURRENT_IN_SITU_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
                print CURRENT_IN_SITU_SQLFILE ")',-1));\n";
              }
              
            }
          }
          print CURRENT_IN_SITU_SQLFILE "\n";
        }
        close(CURRENT_IN_SITU_SQLFILE);
      }
      #DWR 4/5/2008
      if( $bWriteobsKMLFile )
      {
        for my $i (0..$#sea_surface_eastward_current) 
        {
          my $j = 0;
          while ($j <= $#sea_surface_northward_current
                && $sea_surface_northward_current[$j]{'height'} != $sea_surface_eastward_current[$i]{'height'}) 
          {
            $j++;
          }
          if ($j > $#sea_surface_northward_current) 
          {
            die "ABORT!  Could not find matching sea_surface_northward_current for $sea_surface_eastward_current[$i]  {'var_name'}.\n";
          }
          else 
          {
            
            for my $k ($iStartingNdx..$#this_sea_surface_eastward_current_data)  #DWR v1.1.0.0
            #for my $k (0..$#this_sea_surface_eastward_current_data) 
            {
              $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
              $this_time_stamp = $time_formatted_values[$k];
              $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
              
              my $ECurrentDataVal = 'NULL';
              my $NCurrentDataVal = 'NULL';
              my @VectorDataVal;
              my $Height = '';     
              my $strUnits;
              $strUnits = obsKMLSubRoutines::UnitsStringConversion( $sea_surface_eastward_current[$i]{'units'}, $XMLControlFile );        
              if( length( $strUnits ) == 0 )
              {
                #DWR v1.1.0.0
                #Make sure we don't have any unprintable characters.            
                $strUnits = obsKMLSubRoutines::CleanString( $sea_surface_eastward_current[$i]{'units'} );                 
              }

              if( $this_time_stamp_sec > $oldest_ok_timestamp )
              {             
                if ($sea_surface_eastward_current[$i]{'data'}[$k] != $missing_value_value
                    && $sea_surface_eastward_current[$i]{'data'}[$k] != $Fill_value_value
                    && $sea_surface_northward_current[$j]{'data'}[$k] != $missing_value_value
                    && $sea_surface_northward_current[$j]{'data'}[$k] != $Fill_value_value
                    && $this_station_id_top_ts < $this_time_stamp_sec
                    ) 
                {
                  if ($sea_surface_eastward_current[$i]{'height'} != $missing_value_value
                      && $sea_surface_eastward_current[$i]{'height'} != $Fill_value_value) 
                  {
                    $Height = sprintf("%.2f",$sea_surface_eastward_current[$i]{'height'});                
                  } 
                  $ECurrentDataVal = sprintf("%.2f",$sea_surface_eastward_current[$i]{'data'}[$k]);
                  
                  $NCurrentDataVal = sprintf("%.2f",$sea_surface_northward_current[$j]{'data'}[$k]);
                  @VectorDataVal = get_mag_and_dir( $ECurrentDataVal, $NCurrentDataVal, 1 );
                }
                #DWR v1.1.1.0
                #Initialize the array elements with NULL so if the data is either missing we correctly put the missing data flag.
                my $mag = 'NULL';
                my $dir = 'NULL';
                my $len = @VectorDataVal;
                if( $len == 2 )
                {
                  $mag = @VectorDataVal[0] * 100.0;#Convert to cm_s-1
                  $dir = @VectorDataVal[1];
                }
                obsKMLSubRoutines::KMLAddObsToHash( 'current_to_direction', 
                                                    $KMLTimeStamp[$k],
                                                    $dir,
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    'degrees_true',
                                                    $rObsHash );


                obsKMLSubRoutines::KMLAddObsToHash( 'current_speed', 
                                                    $KMLTimeStamp[$k],
                                                    $mag, 
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    'cm_s-1',
                                                    $rObsHash );
                $strUnits = 'cm_s-1';
                #$strUnits = obsKMLSubRoutines::UnitsStringConversion( $sea_surface_northward_current[$i]{'units'}, $XMLControlFile );        
                #if( length( $strUnits ) == 0 )
                #{
                  #DWR v1.1.0.0
                  #Make sure we don't have any unprintable characters.            
                #  $strUnits = obsKMLSubRoutines::CleanString( $sea_surface_northward_current[$i]{'units'} );                 
                #}
                #DWR v1.1.1.0
                #Fixed bug where data was missing, so $NCurrentDataVal would be NULL, but multiplying it by 100.0 would result in 0 so it appeared
                #to be a real observation
                if( $NCurrentDataVal != 'NULL' )
                {
                  $NCurrentDataVal * 100.0; #DWR convert to cm_s-1
                }
                obsKMLSubRoutines::KMLAddObsToHash( 'northward_current', 
                                                    $KMLTimeStamp[$k],
                                                    $NCurrentDataVal, #DWR convert to cm_s-1
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    $strUnits,
                                                    $rObsHash );
                #$strUnits = $sea_surface_eastward_current[$i]{'units'};
                #$strUnits = obsKMLSubRoutines::UnitsStringConversion( $sea_surface_eastward_current[$i]{'units'}, $XMLControlFile );        
                #if( length( $strUnits ) == 0 )
                #{
                  #Make sure we don't have any unprintable characters.            
                #  $strUnits = obsKMLSubRoutines::CleanString( $sea_surface_eastward_current[$i]{'units'} );                 
                #}
                #DWR v1.1.1.0
                #Fixed bug where data was missing, so $NCurrentDataVal would be NULL, but multiplying it by 100.0 would result in 0 so it appeared
                #to be a real observation
                if( $ECurrentDataVal != 'NULL' )
                {
                  $ECurrentDataVal * 100.0; #DWR convert to cm_s-1
                }
                
                obsKMLSubRoutines::KMLAddObsToHash( 'eastward_current', 
                                                    $KMLTimeStamp[$k],
                                                    $ECurrentDataVal, #DWR convert to cm_s-1
                                                    1,
                                                    $strPlatformID,
                                                    $Height,
                                                    $strUnits,
                                                    $rObsHash );
            }                                                    
          }
        }                                            
      }                  
    }
  }
  
  # significant_wave_height and dominant_wave_period (assume they come as pairs --
  # wave_height calls the shots over period
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#significant_wave_height > -1) {
    if( $bWriteSQLFiles )
    {
      open(WAVE_SQLFILE,'>>../sql/wave_in_situ_prod_'.$institution_code_value.'_'
        .$platform_code_value.'_'.$package_code_value.'.sql');
      print WAVE_SQLFILE "-- format_category      = $format_category_value\n";
      print WAVE_SQLFILE "-- institution_code     = $institution_code_value\n";
      print WAVE_SQLFILE "-- platform_code        = $platform_code_value\n";
      print WAVE_SQLFILE "-- package_code         = $package_code_value\n";
      print WAVE_SQLFILE "-- title                = $title_value\n";
      print WAVE_SQLFILE "-- institution          = $institution_value\n";
      print WAVE_SQLFILE "-- institution_url      = $institution_url_value\n";
      print WAVE_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
      print WAVE_SQLFILE "-- source               = $source_value\n";
      print WAVE_SQLFILE "-- references           = $references_value\n";
      print WAVE_SQLFILE "-- contact              = $contact_value\n";
      print WAVE_SQLFILE "-- missing_value        = $missing_value_value\n";
      print WAVE_SQLFILE "-- _FillValue           = $Fill_value_value\n";
      for my $i (0..$#significant_wave_height) {
        for my $j (0..$#this_significant_wave_height_data) {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          my $DomWaveDataVal = 'NULL';
          my $SigWaveHgtDataVal = 'NULL';
          my $Height = '';
          
          if ($significant_wave_height[$i]{'data'}[$j] != $missing_value_value
            && $significant_wave_height[$i]{'data'}[$j] != $Fill_value_value
            && $this_station_id_top_ts < $this_time_stamp_sec
            && $this_time_stamp_sec > $oldest_ok_timestamp) {
            print WAVE_SQLFILE "INSERT INTO wave_in_situ_prod ("; 
            print WAVE_SQLFILE "station_id,";
            print WAVE_SQLFILE "time_stamp,"; 
            print WAVE_SQLFILE "z,";
            print WAVE_SQLFILE "positive,";
            print WAVE_SQLFILE "significant_wave_height,";
            print WAVE_SQLFILE "dominant_wave_period,";
            print WAVE_SQLFILE "the_geom";
            print WAVE_SQLFILE ") "; 
            print WAVE_SQLFILE "VALUES ("; 
            print WAVE_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
            print WAVE_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
            if ($significant_wave_height[$i]{'height'} == $missing_value_value
              || $significant_wave_height[$i]{'height'} == $Fill_value_value) {
              print WAVE_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$significant_wave_height[$i]{'height'});
              print WAVE_SQLFILE ','.$this_val;

              #DWR 4/5/2008
              $Height = $this_val;
            }
            print WAVE_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
            if ($significant_wave_height[$i]{'data'}[$j] == $missing_value_value
              || $significant_wave_height[$i]{'data'}[$j] == $Fill_value_value )
              #|| $significant_wave_height[$i]{'data'}[$j] == '') DWR v1.1.2.0
            {
              print WAVE_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$significant_wave_height[$i]{'data'}[$j]);
              print WAVE_SQLFILE ','.$this_val;
              #DWR 4/5/2008
              $SigWaveHgtDataVal = $this_val;
            }
            if ($dominant_wave_period[$i]{'data'}[$j] == $missing_value_value
              || $dominant_wave_period[$i]{'data'}[$j] == $Fill_value_value )
              #|| $dominant_wave_period[$i]{'data'}[$j] == '') DWR v1.1.2.0
            {
              print WAVE_SQLFILE ',NULL';
            }
            else {
              $this_val = sprintf("%.2f",$dominant_wave_period[$i]{'data'}[$j]);
              print WAVE_SQLFILE ','.$this_val;
              #DWR 4/5/2008
              $DomWaveDataVal = $this_val;
            }
            print WAVE_SQLFILE ",GeometryFromText('POINT("; 
            print WAVE_SQLFILE $longitude_value[0].' '.$latitude_value[0]; 
            print WAVE_SQLFILE ")',-1));\n";
          }
        }
        print WAVE_SQLFILE "\n";
        close(WAVE_SQLFILE);
      }
    }
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      for my $i (0..$#significant_wave_height) 
      {
        for my $j ($iStartingNdx..$#this_significant_wave_height_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#this_significant_wave_height_data) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          
          my $DomWaveDataVal = 'NULL';
          my $SigWaveHgtDataVal = 'NULL';
          my $Height = '';
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {          
            if ($significant_wave_height[$i]{'data'}[$j] != $missing_value_value
                && $significant_wave_height[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
            {
              if ($significant_wave_height[$i]{'height'} != $missing_value_value
                  && $significant_wave_height[$i]{'height'} != $Fill_value_value)
              {
                $Height = sprintf("%.2f",$significant_wave_height[$i]{'height'});
              }
              if ($significant_wave_height[$i]{'data'}[$j] != $missing_value_value
                  && $significant_wave_height[$i]{'data'}[$j] != $Fill_value_value )
                  #&& $significant_wave_height[$i]{'data'}[$j] != '')  DWR v1.1.2.0
              {
                $SigWaveHgtDataVal = sprintf("%.2f",$significant_wave_height[$i]{'data'}[$j]);
              }
              if ($dominant_wave_period[$i]{'data'}[$j] != $missing_value_value
                && $dominant_wave_period[$i]{'data'}[$j] != $Fill_value_value )
                #&& $dominant_wave_period[$i]{'data'}[$j] != '') DWR v1.1.2.0
              {
                $DomWaveDataVal = sprintf("%.2f",$dominant_wave_period[$i]{'data'}[$j]);
              }
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $dominant_wave_period[$i]{'units'}, $XMLControlFile );      
            if( length( $strUnits ) == 0 )
            {
               $strUnits = obsKMLSubRoutines::CleanString( $dominant_wave_period[$i]{'units'} );
            }
              
            obsKMLSubRoutines::KMLAddObsToHash( 'dominant_wave_period', 
                                                $KMLTimeStamp[$j],
                                                $DomWaveDataVal,
                                                1,
                                                $strPlatformID,
                                                $Height,
                                                $strUnits,
                                                $rObsHash );
            $strUnits = '';
            $strUnits = obsKMLSubRoutines::CleanString( obsKMLSubRoutines::UnitsStringConversion( $significant_wave_height[$i]{'units'}, $XMLControlFile ) );
            if( length( $strUnits ) == 0 )
            {
               $strUnits = $significant_wave_height[$i]{'units'};
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'significant_wave_height', 
                                                $KMLTimeStamp[$j],
                                                $SigWaveHgtDataVal,
                                                1,
                                                $strPlatformID,
                                                $Height,
                                                $strUnits,
                                                $rObsHash );
          }                                                  
        }        
      }
    }                    
  }
  
  #DWR 5/25/2010
  # relative_humidity
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#relative_humidity > -1) {
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#relative_humidity) 
      {
        for my $j ($iStartingNdx..$#this_relative_humidity_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#relative_humidity) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {        
            if ($relative_humidity[$i]{'data'}[$j] != $missing_value_value
                && $relative_humidity[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
            {

              if ($relative_humidity[$i]{'height'} != $missing_value_value
                && $relative_humidity[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$relative_humidity[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$relative_humidity[$i]{'data'}[$j]);
                        
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $relative_humidity[$i]{'units'}, $XMLControlFile );        
            if( length( $strUnits ) == 0 )
            {
              #DWR v1.1.0.0
              #Make sure we don't have any unprintable characters.            
              $strUnits = obsKMLSubRoutines::CleanString( $relative_humidity[$i]{'units'} );  
             
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'relative_humidity', 
                                              $KMLTimeStamp[$j],
                                              $DataVal,
                                              1,
                                              $strPlatformID,
                                              $Height,
                                              $strUnits,
                                              $rObsHash );
          }                                                
        }
      }                                            
    }        
  }
  #DWR 5/25/2010
  # relative_humidity
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#chl_concentration > -1) {
    #DWR 4/5/2008
    if( $bWriteobsKMLFile )
    {
      my $DataVal = 'NULL';
      my $Height = '';
      for my $i (0..$#chl_concentration) 
      {
        for my $j ($iStartingNdx..$#this_chl_concentration_data) #DWR v1.1.0.0 Starting index now set to $iStartingNdx
        #for my $j (0..$#chl_concentration) 
        {
          $this_station_id = $institution_code_value.'_'.$platform_code_value.'_'.$package_code_value;
          $this_time_stamp = $time_formatted_values[$j];
          $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
          if( $this_time_stamp_sec > $oldest_ok_timestamp )
          {        
            if ($chl_concentration[$i]{'data'}[$j] != $missing_value_value
                && $chl_concentration[$i]{'data'}[$j] != $Fill_value_value
                && $this_station_id_top_ts < $this_time_stamp_sec
                ) 
            {

              if ($chl_concentration[$i]{'height'} != $missing_value_value
                && $chl_concentration[$i]{'height'} != $Fill_value_value) 
              {
                $Height = sprintf("%.2f",$chl_concentration[$i]{'height'});
              }
              $DataVal = sprintf("%.2f",$chl_concentration[$i]{'data'}[$j]);
                        
            }
            my $strUnits;
            $strUnits = obsKMLSubRoutines::UnitsStringConversion( $chl_concentration[$i]{'units'}, $XMLControlFile );        
            if( length( $strUnits ) == 0 )
            {
              #DWR v1.1.0.0
              #Make sure we don't have any unprintable characters.            
              $strUnits = obsKMLSubRoutines::CleanString( $chl_concentration[$i]{'units'} );  
             
            }
            obsKMLSubRoutines::KMLAddObsToHash( 'chl_concentration', 
                                              $KMLTimeStamp[$j],
                                              $DataVal,
                                              1,
                                              $strPlatformID,
                                              $Height,
                                              $strUnits,
                                              $rObsHash );
          }                                                
        }
      }                                            
    }        
  }
  
  
  
  #DWR 4/5/2008
  if( $bWriteobsKMLFile )
  {
    my $iCnt = keys( %ObsHash );
    print( "Cnt: $iCnt\n" );
    if( $iCnt )
    {
      #DWR v1.1.0.0
      #Moved KMLAddPlatformHashEntry to after we process all the data so we can see if we actually had any data. I correctly implemented the time check
      #to verify the data is no older than 2 weeks.
      #Implemented code to write the obsKML files. 
      obsKMLSubRoutines::KMLAddPlatformHashEntry( $strPlatformID, $institution_url_value, $latitude_value[0], $longitude_value[0], $rObsHash );
      
      my $strXMLPath; 
      #my $strDate = `date  +%H%M%S`;
      #chomp( $strDate );      
      my @aSrcFileParts = split( /\//, $net_cdf_file );
      my $strSrcFileName = @aSrcFileParts[-1];
      #Break the filename and extension apart.
      #print( "$strSrcFileName\n" );
      my $iPos = rindex( $strSrcFileName, '.' );
      my $strFileName = $strSrcFileName;
      if( $iPos != -1 )
      {
        $strFileName = substr( $strSrcFileName, 0, $iPos );
      }
      #print( "$strFileName\n" );
      
      #$strXMLPath = "$strObsKMLFilePath/$this_station_id";
      #DWR v1.1.1.0
      #Use the source netcdf filename.
      #Add the $strDate which gives us a unique file name. Some providers don't uniquely name the netcdf files, so to prevent overwritting of my
      #kml, I add the time.
      $strXMLPath = "$strObsKMLFilePath/$strFileName.kml";
      #$strXMLPath = $strXMLPath . '_latest.kml';
      print( "XMLFilePath: $strXMLPath\n" );
      obsKMLSubRoutines::BuildKMLFile( \%ObsHash, $strXMLPath );
    }
    else
    {
      #DWR v1.1.0.0
      #Check to see if the last entry is older than our $oldest_ok_timestamp, if so let's log a message.
      my $this_time_stamp = $time_formatted_values[-1];
      my $this_time_stamp_sec = timelocal(substr($this_time_stamp,17,2),substr($this_time_stamp,14,2),substr($this_time_stamp,11,2),substr($this_time_stamp,8,2),(substr($this_time_stamp,5,2)-1),substr($this_time_stamp,0,4));
      
      print( "fixed_point::Time Lag: Last Data Point Time:$this_time_stamp ($this_time_stamp_sec secs) Oldest allowed time: $oldest_ok_timestamp secs.\n" );     
    }
  }
}

sub get_mag_and_dir {

my ($x, $y, $scale) = @_;
my ($mag,$angle);

$mag = sprintf("%.2f",$scale*sqrt($x*$x+$y*$y));
#print "$mag\n";

$angle = atan2($y,$x);
$angle = sprintf("%.1f",180/3.1416*$angle);
$angle = 90 - $angle;
#only return positive degrees
if ($angle < 0) 
{ 
  $angle = 360 + $angle; 
}

my @result = ($mag, $angle);

return (@result);

}
