#!/bin/perl

sub moving_point () {
  
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
    if (substr($this_standard_name,length($this_standard_name)-1) eq chr(0)) {chop($this_standard_name);}
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
        if ($this_var_dims != 1) {die "ABORT! Longitude has incorrect number of dimensions.\n";}
        %longitude_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0]
        );
      }
      elsif ($this_standard_name =~ /^latitude$/) {
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
      # push all sea_surface_temperature's onto a stack
      elsif ($this_standard_name =~ /^sea_surface_temperature$/) {
        %this_sea_surface_temperature = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => ''
        );
        push @sea_surface_temperature, {%this_sea_surface_temperature};
      }
      # push all air_temperature's onto a stack
      elsif ($this_standard_name =~ /^air_temperature$/) {
        %this_air_temperature = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => ''
        );
        push @air_temperature, {%this_air_temperature};
      }
      # push all wind_speed's onto a stack
      elsif ($this_standard_name =~ /^wind_speed$/) {
        %this_wind_speed = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          can_be_normalized => ''
        );
        push @wind_speed, {%this_wind_speed};
      }
      # push all wind_gust's onto a stack
      elsif ($this_standard_name =~ /^wind_gust$/) {
        %this_wind_gust = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          can_be_normalized => ''
        );
        push @wind_gust, {%this_wind_gust};
      }
      # push all wind_from_direction's onto a stack
      elsif ($this_standard_name =~ /^wind_from_direction$/) {
        %this_wind_from_direction = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => '',
          can_be_normalized => ''
        );
        push @wind_from_direction, {%this_wind_from_direction};
      }
      # push all air_pressure's onto a stack
      elsif ($this_standard_name =~ /^air_pressure$/) {
        %this_air_pressure = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => ''
        );
        push @air_pressure, {%this_air_pressure};
      }
    }
      # push all salinity's onto a stack
      elsif ($this_standard_name =~ /^salinity$/) {
        %this_salinity = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          height   => ''
        );
        push @salinity, {%this_salinity};
      }
    }
  
  #
  # Required dimensions:  time, height
  # Find out names through the variables.
  # Abort if all are not found.
  
  if (length($time_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No time dimension ref. found via variable.\n";
  }
  if (length($height_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No height dimension ref. found via variable.\n";
  }
  if (length($err) > 0) {
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
  # height
  if ($height_var{'dim_id'} != $height_dim{'dim_id'}) {
    die "ABORT! Height variable does not have correct height dimension.\n";
  }
  
  #
  # Get the data of the required elements.
  
  @time_values           = '';
  @time_formatted_values = '';
  @longitude_values      = '';
  @latitude_values       = '';
  @height_value          = '';
  my $positive_value     = '';
  
  # time
  # get all the values
  my $units_value = '';
  my $varget = NetCDF::varget($ncid, $time_var{'var_id'}, (0), $time_dim{'dim_size'}, \@time_values);
  if ($varget < 0) {die "ABORT! Cannot get time values.\n";}
  # get the units
  my $attget = NetCDF::attget($ncid, $time_var{'var_id'}, 'units', \$units_value);
  if ($attget < 0) {die "ABORT! $time_var{'var_name'} has no units.\n";}
  if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
  my $base_time = UDUNITS::scan($units_value)
    || die "ABORT! Error with $time_var{'var_name'} units.\n";
  $base_time->istime()
    || die "ABORT! Invalid units for $time_var{'var_name'}.\n";
  
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
  }
  
  # longitude (vector)
  $varget = NetCDF::varget($ncid, $longitude_var{'var_id'}, (0), $time_dim{'dim_size'}, \@longitude_values);
  if ($varget < 0) {die "ABORT! Cannot get longitude values.\n";}
  
  # latitude (vector)
  $varget = NetCDF::varget($ncid, $latitude_var{'var_id'}, (0), $time_dim{'dim_size'}, \@latitude_values);
  if ($varget < 0) {die "ABORT! Cannot get latitude values.\n";}
  
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
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $sea_surface_temperature[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $sea_surface_temperature[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $sea_surface_temperature[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $sea_surface_temperature[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $sea_surface_temperature[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $sea_surface_temperature[$i]{'var_name'} $k attribute.\n";}
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
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $air_temperature[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $air_temperature[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $air_temperature[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $air_temperature[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $air_temperature[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $air_temperature[$i]{'var_name'} $k attribute.\n";}
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
        my $attname = NetCDF::attname($ncid, $wind_from_direction[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $wind_from_direction[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_from_direction[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_from_direction[$i]{'var_name'} $k attribute.\n";}
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
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $air_pressure[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $air_pressure[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $air_pressure[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $air_pressure[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $air_pressure[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $air_pressure[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $air_pressure[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($air_pressure[$i]{'height'} == '') {
        $air_pressure[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_air_pressure_data) {
        # target is milibars
        push @{$air_pressure[$i]{'data'}},
          ($this_air_pressure_data[$j] * $this_slope + $this_intercept) * 1000;
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
      if ($varinq < 0) {die "ABORT! Cannot get $salinity[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $salinity[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $salinity[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $salinity[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $salinity[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $salinity[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($salinity[$i]{'height'} == '') {
        $salinity[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_salinity_data) {
        # target is milibars
        push @{$salinity[$i]{'data'}}, $this_salinity_data[$j];
      }
    }
  }
  
  #
  # write data to file(s)

  # station_id
  open(STATION_ID_SQLFILE,'>>../sql_in_situ_station_id/in_situ_station_id_'.$institution_code_value.'_'
    .$platform_code_value.'_'.$package_code_value.'.sql');
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
  
  # sea_surface_temperature (sst)
  if ($#sea_surface_temperature > -1) {
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
    for my $i (0..$#sea_surface_temperature) {
      for my $j (0..$#this_sea_surface_temperature_data) {
        if ($sea_surface_temperature[$i]{'data'}[$j] != $missing_value_value
          && $sea_surface_temperature[$i]{'data'}[$j] != $Fill_value_value) {
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
          print SST_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
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
          print SST_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=_blank>'.$institution_url_value.'</a>'.'\'';
          print SST_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=_blank>'.$institution_dods_url_value.'</a>'.'\'';
          print SST_SQLFILE ','.'\''.$source_value.'\'';
          print SST_SQLFILE ','.'\''.$references_value.'\'';
          print SST_SQLFILE ','.'\''.$contact_value.'\'';
          print SST_SQLFILE ",GeometryFromText('POINT("; 
          print SST_SQLFILE $longitude_values[$j].' '.$latitude_values[$j];
          print SST_SQLFILE ")',-1));\n";
        }
      }
      print SST_SQLFILE "\n";
    }
    close(SST_SQLFILE);
  }
  
  # air_temperature
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#air_temperature > -1) {
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
        if ($air_temperature[$i]{'data'}[$j] != $missing_value_value
          && $air_temperature[$i]{'data'}[$j] != $Fill_value_value) {
          print AIR_TEMP_SQLFILE "INSERT INTO air_temperature_prod ("; 
          print AIR_TEMP_SQLFILE "station_id,";
          print AIR_TEMP_SQLFILE "time_stamp,"; 
          print AIR_TEMP_SQLFILE "z,";
          print AIR_TEMP_SQLFILE "positive,";
          print AIR_TEMP_SQLFILE "temperature_celcius,";
          print AIR_TEMP_SQLFILE "the_geom";
          print AIR_TEMP_SQLFILE ") "; 
          print AIR_TEMP_SQLFILE "VALUES ("; 
          print AIR_TEMP_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print AIR_TEMP_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
          if ($air_temperature[$i]{'height'} == $missing_value_value
            || $air_temperature[$i]{'height'} == $Fill_value_value) {
            print AIR_TEMP_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$air_temperature[$i]{'height'});
            print AIR_TEMP_SQLFILE ','.$this_val;
          }
          print AIR_TEMP_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
          $this_val = sprintf("%.2f",$air_temperature[$i]{'data'}[$j]);
          print AIR_TEMP_SQLFILE ','.$this_val;
          print AIR_TEMP_SQLFILE ",GeometryFromText('POINT("; 
          print AIR_TEMP_SQLFILE $longitude_values[$j].' '.$latitude_values[$j];
          print AIR_TEMP_SQLFILE ")',-1));\n";
        }
      }
      print AIR_TEMP_SQLFILE "\n";
    }
    close(AIR_TEMP_SQLFILE);
  }
  
  # wind_speed and wind_gust and wind_from_direction
  # Start w/ wind_speed and then look through the wind_from_direction to find its
  # pair by looking at the heights.  This index will also define the gust.
  # Assume that wind_speed controls everything (from_dir, gust, z, normalized) index-wise.
  if ($#wind_speed > -1) {
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
      while ($j <= $#wind_from_direction && $wind_from_direction[$j]{'height'} 
        != $wind_speed[$i]{'height'}) {
        $j++;
      }
      if ($j > $#wind_from_direction) {
        die "ABORT!  Could not find matching wind_from_direction for $wind_speed[$i]{'var_name'}.\n";
      }
      else {
        for my $k (0..$#this_wind_speed_data) {
          if ($wind_speed[$i]{'data'}[$k] != $missing_value_value
            && $wind_speed[$i]{'data'}[$k] != $Fill_value_value
            && $wind_from_direction[$j]{'data'}[$k] != $missing_value_value
            && $wind_from_direction[$j]{'data'}[$k] != $Fill_value_value) {
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
            print WIND_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
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
              || $wind_gust[$j]{'data'}[$k] == $Fill_value_value
              || $wind_gust[$j]{'data'}[$k] == '') {
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
            print WIND_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=_blank>'.$institution_url_value.'</a>'.'\'';
            print WIND_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=_blank>'.$institution_dods_url_value.'</a>'.'\'';
            print WIND_SQLFILE ','.'\''.$source_value.'\'';
            print WIND_SQLFILE ','.'\''.$references_value.'\'';
            print WIND_SQLFILE ','.'\''.$contact_value.'\'';
            print WIND_SQLFILE ",GeometryFromText('POINT("; 
            print WIND_SQLFILE $longitude_values[$k].' '.$latitude_values[$k];
            print WIND_SQLFILE ")',-1));\n";
          }
        }
      }
      print WIND_SQLFILE "\n";
    }
    close(WIND_SQLFILE);
  }
  
  # air_pressure
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#air_pressure > -1) {
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
        if ($air_pressure[$i]{'data'}[$j] != $missing_value_value
          && $air_pressure[$i]{'data'}[$j] != $Fill_value_value) {
          print AIR_PRESSURE_SQLFILE "INSERT INTO air_pressure_prod ("; 
          print AIR_PRESSURE_SQLFILE "station_id,";
          print AIR_PRESSURE_SQLFILE "time_stamp,"; 
          print AIR_PRESSURE_SQLFILE "z,";
          print AIR_PRESSURE_SQLFILE "positive,";
          print AIR_PRESSURE_SQLFILE "pressure,";
          print AIR_PRESSURE_SQLFILE "the_geom";
          print AIR_PRESSURE_SQLFILE ") "; 
          print AIR_PRESSURE_SQLFILE "VALUES ("; 
          print AIR_PRESSURE_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print AIR_PRESSURE_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
          if ($air_pressure[$i]{'height'} == $missing_value_value
            || $air_pressure[$i]{'height'} == $Fill_value_value) {
            print AIR_PRESSURE_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$air_pressure[$i]{'height'});
            print AIR_PRESSURE_SQLFILE ','.$this_val;
          }
          print AIR_PRESSURE_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
          $this_val = sprintf("%.2f",$air_pressure[$i]{'data'}[$j]);
          print AIR_PRESSURE_SQLFILE ','.$this_val;
          print AIR_PRESSURE_SQLFILE ",GeometryFromText('POINT("; 
          print AIR_PRESSURE_SQLFILE $longitude_values[$j].' '.$latitude_values[$j];
          print AIR_PRESSURE_SQLFILE ")',-1));\n";
        }
      }
      print AIR_PRESSURE_SQLFILE "\n";
    }
    close(AIR_PRESSURE_SQLFILE);
  }
  
  # salinity
  # Going to do this right this time.  Instead of populating each row w/ all
  # the metadata, use the station_id lookup, instead.
  if ($#salinity > -1) {
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
        if ($salinity[$i]{'data'}[$j] != $missing_value_value
          && $salinity[$i]{'data'}[$j] != $Fill_value_value) {
          print SALINITY_SQLFILE "INSERT INTO salinity_prod ("; 
          print SALINITY_SQLFILE "station_id,";
          print SALINITY_SQLFILE "time_stamp,"; 
          print SALINITY_SQLFILE "z,";
          print SALINITY_SQLFILE "positive,";
          print SALINITY_SQLFILE "salinity,";
          print SALINITY_SQLFILE "the_geom";
          print SALINITY_SQLFILE ") "; 
          print SALINITY_SQLFILE "VALUES ("; 
          print SALINITY_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print SALINITY_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$j].'\'';
          if ($salinity[$i]{'height'} == $missing_value_value
            || $salinity[$i]{'height'} == $Fill_value_value) {
            print SALINITY_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$salinity[$i]{'height'});
            print SALINITY_SQLFILE ','.$this_val;
          }
          print SALINITY_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
          $this_val = sprintf("%.2f",$salinity[$i]{'data'}[$j]);
          print SALINITY_SQLFILE ','.$this_val;
          print SALINITY_SQLFILE ",GeometryFromText('POINT("; 
          print SALINITY_SQLFILE $longitude_values[$j].' '.$latitude_values[$j];
          print SALINITY_SQLFILE ")',-1));\n";
        }
      }
      print SALINITY_SQLFILE "\n";
    }
    close(SALINITY_SQLFILE);
  }
}
