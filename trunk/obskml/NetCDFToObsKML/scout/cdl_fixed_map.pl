#!/bin/perl

sub fixed_map () {
  
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
      # push all eastward_current's onto a stack
      elsif ($this_standard_name =~ /^eastward_current$/) {
        %this_eastward_current = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id_time => $this_var_dimid[0],
          dim_id_lon  => $this_var_dimid[1],
          dim_id_lat  => $this_var_dimid[2],
          height   => ''
        );
        push @eastward_current, {%this_eastward_current};
      }
      # push all northward_current's onto a stack
      elsif ($this_standard_name =~ /^northward_current$/) {
        %this_northward_current = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id_time => $this_var_dimid[0],
          dim_id_lon  => $this_var_dimid[1],
          dim_id_lat  => $this_var_dimid[2],
          height   => ''
        );
        push @northward_current, {%this_northward_current};
      }
      # push all eastward_wind's onto a stack
      elsif ($this_standard_name =~ /^eastward_wind$/) {
        %this_eastward_wind = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id_time => $this_var_dimid[0],
          dim_id_lon  => $this_var_dimid[1],
          dim_id_lat  => $this_var_dimid[2],
          height   => ''
        );
        push @eastward_wind, {%this_eastward_wind};
      }
      # push all northward_wind's onto a stack
      elsif ($this_standard_name =~ /^northward_wind$/) {
        %this_northward_wind = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id_time => $this_var_dimid[0],
          dim_id_lon  => $this_var_dimid[1],
          dim_id_lat  => $this_var_dimid[2],
          height   => ''
        );
        push @northward_wind, {%this_northward_wind};
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
  @longitude_values       = '';
  @latitude_values        = '';
  @height_value          = '';
  @lon_valid_range       = ();
  @lat_valid_range       = ();
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
  $varget = NetCDF::varget($ncid, $longitude_var{'var_id'}, (0), $longitude_dim{'dim_size'}, \@longitude_values);
  if ($varget < 0) {die "ABORT! Cannot get longitude values.\n";}
  $attget = NetCDF::attget($ncid, $longitude_var{'var_id'}, 'valid_range', \@lon_valid_range);
  
  # latitude (vector)
  $varget = NetCDF::varget($ncid, $latitude_var{'var_id'}, (0), $latitude_dim{'dim_size'}, \@latitude_values);
  if ($varget < 0) {die "ABORT! Cannot get latitude values.\n";}
  $attget = NetCDF::attget($ncid, $latitude_var{'var_id'}, 'valid_range', \@lat_valid_range);
  
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

  # eastward_current's
  @this_eastward_current_data = ();
  for $i (0..$#eastward_current) {
    # this variable's dimension better be (time,lon,lat)
    if ($eastward_current[$i]{'dim_id_time'} != $time_dim{'dim_id'}
        || $eastward_current[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
        || $eastward_current[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}) {
      die "ABORT!  $eastward_current[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_eastward_current_var_slice =
        ($time_dim{'dim_size'},$longitude_dim{'dim_size'},$latitude_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $eastward_current[$i]{'var_id'},
        \@zero_offset, \@this_eastward_current_var_slice, \@this_eastward_current_data);
      if ($varget < 0) {die "ABORT! Cannot get $eastward_current[$i]{'var_name'} data.\n";}
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
      my $attget = NetCDF::attget($ncid, $eastward_current[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $eastward_current[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $eastward_current[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $eastward_current[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $eastward_current[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $eastward_current[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $eastward_current[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $eastward_current[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $eastward_current[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $eastward_current[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($eastward_current[$i]{'height'} == '') {
        $eastward_current[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_eastward_current_data) {
        if ($this_eastward_current_data[$j] != $missing_value_value
            && $this_eastward_current_data[$j] != $Fill_value_value
            && $this_eastward_current_data[$j] != $missing_value_value
            && $this_eastward_current_data[$j] != $Fill_value_value) {
          push @{$eastward_current[$i]{'data'}}, $this_eastward_current_data[$j] * $this_slope + $this_intercept;
        }
        else {
          push @{$eastward_current[$i]{'data'}}, $this_eastward_current_data[$j];
        }
      }
    }
  }
  
  # northward_current's
  @this_northward_current_data = ();
  for $i (0..$#northward_current) {
    # this variable's dimension better be (time,lon,lat)
    if ($northward_current[$i]{'dim_id_time'} != $time_dim{'dim_id'}
        || $northward_current[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
        || $northward_current[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}) {
      die "ABORT!  $northward_current[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_northward_current_var_slice =
        ($time_dim{'dim_size'},$longitude_dim{'dim_size'},$latitude_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $northward_current[$i]{'var_id'},
        \@zero_offset, \@this_northward_current_var_slice, \@this_northward_current_data);
      if ($varget < 0) {die "ABORT! Cannot get $northward_current[$i]{'var_name'} data.\n";}
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
      my $attget = NetCDF::attget($ncid, $eastward_current[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $eastward_current[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $eastward_current[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $northward_current[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $northward_current[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $northward_current[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $northward_current[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $northward_current[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $northward_current[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $northward_current[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($northward_current[$i]{'height'} == '') {
        $northward_current[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_northward_current_data) {
        if ($this_northward_current_data[$j] != $missing_value_value
            && $this_northward_current_data[$j] != $Fill_value_value
            && $this_northward_current_data[$j] != $missing_value_value
            && $this_northward_current_data[$j] != $Fill_value_value) {
          push @{$northward_current[$i]{'data'}}, $this_northward_current_data[$j] * $this_slope + $this_intercept;
        }
        else {
          push @{$northward_current[$i]{'data'}}, $this_northward_current_data[$j];
        }
      }
    }
  }
  
  # eastward_wind's
  @this_eastward_wind_data = ();
  for $i (0..$#eastward_wind) {
    # this variable's dimension better be (time,lon,lat)
    if ($eastward_wind[$i]{'dim_id_time'} != $time_dim{'dim_id'}
        || $eastward_wind[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
        || $eastward_wind[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}) {
      die "ABORT!  $eastward_wind[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_eastward_wind_var_slice =
        ($time_dim{'dim_size'},$longitude_dim{'dim_size'},$latitude_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $eastward_wind[$i]{'var_id'},
        \@zero_offset, \@this_eastward_wind_var_slice, \@this_eastward_wind_data);
      if ($varget < 0) {die "ABORT! Cannot get $eastward_wind[$i]{'var_name'} data.\n";}
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
      my $attget = NetCDF::attget($ncid, $eastward_wind[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $eastward_wind[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $eastward_wind[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $eastward_wind[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $eastward_wind[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $eastward_wind[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $eastward_wind[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $eastward_wind[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $eastward_wind[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $eastward_wind[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($eastward_wind[$i]{'height'} == '') {
        $eastward_wind[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_eastward_wind_data) {
        if ($this_eastward_wind_data[$j] != $missing_value_value
            && $this_eastward_wind_data[$j] != $Fill_value_value
            && $this_eastward_wind_data[$j] != $missing_value_value
            && $this_eastward_wind_data[$j] != $Fill_value_value) {
          push @{$eastward_wind[$i]{'data'}}, $this_eastward_wind_data[$j] * $this_slope + $this_intercept;
        }
        else {
          push @{$eastward_wind[$i]{'data'}}, $this_eastward_wind_data[$j];
        }
      }
    }
  }
  
  # northward_wind's
  @this_northward_wind_data = ();
  for $i (0..$#northward_wind) {
    # this variable's dimension better be (time,lon,lat)
    if ($northward_wind[$i]{'dim_id_time'} != $time_dim{'dim_id'}
        || $northward_wind[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
        || $northward_wind[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}) {
      die "ABORT!  $northward_wind[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_northward_wind_var_slice =
        ($time_dim{'dim_size'},$longitude_dim{'dim_size'},$latitude_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $northward_wind[$i]{'var_id'},
        \@zero_offset, \@this_northward_wind_var_slice, \@this_northward_wind_data);
      if ($varget < 0) {die "ABORT! Cannot get $northward_wind[$i]{'var_name'} data.\n";}
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
      my $attget = NetCDF::attget($ncid, $eastward_wind[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $eastward_wind[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_units = UDUNITS::scan($units_value)
        || die "ABORT! Error with $eastward_wind[$i]{'var_name'} units.\n";
      my $dest_units = UDUNITS::scan('m s-1');
      $base_units->convert($dest_units,$this_slope,$this_intercept);
      
      # we need to loop through the attributes, so find out how many there are
      my $varinq = NetCDF::varinq($ncid, $northward_wind[$i]{'var_id'},
        \$name, \$nc_type, $ndims, \@dimids, \$natts);
      if ($varinq < 0) {die "ABORT! Cannot get $northward_wind[$i]{'var_name'} attributes.\n";}
      for my $k (0..$natts-1) {
        # find out about each attribute
        my $this_attname = '';
        my $attname = NetCDF::attname($ncid, $northward_wind[$i]{'var_id'}, $k, \$this_attname);
        if ($attname < 0) {die "ABORT! Cannot get $northward_wind[$i]{'var_name'} $k attribute.\n";}
        # is this a height?
        if ($this_attname eq $height_dim{'dim_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $northward_wind[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $northward_wind[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $northward_wind[$i]{'height'} = $attval;
        };
      }
      # if we didn't have an height attribute, assign the global one to this var
      if ($northward_wind[$i]{'height'} == '') {
        $northward_wind[$i]{'height'} = $height_value[0];
      }
      for my $j (0..$#this_northward_wind_data) {
        if ($this_northward_wind_data[$j] != $missing_value_value
            && $this_northward_wind_data[$j] != $Fill_value_value
            && $this_northward_wind_data[$j] != $missing_value_value
            && $this_northward_wind_data[$j] != $Fill_value_value) {
          push @{$northward_wind[$i]{'data'}}, $this_northward_wind_data[$j] * $this_slope + $this_intercept;
        }
        else {
          push @{$northward_wind[$i]{'data'}}, $this_northward_wind_data[$j];
        }
      }
    }
  }
  
  #
  # write data to file(s)

  # eastward_current
  if ($#eastward_current > -1) {
    open(CURRENT_SQLFILE,'>../sql/current_prod_'.$institution_code_value.'_'
      .$platform_code_value.'_'.$package_code_value
      .'_'.time.'_'.rand().'.sql');
    print CURRENT_SQLFILE "-- format_category      = $format_category_value\n";
    print CURRENT_SQLFILE "-- institution_code     = $institution_code_value\n";
    print CURRENT_SQLFILE "-- platform_code        = $platform_code_value\n";
    print CURRENT_SQLFILE "-- package_code         = $package_code_value\n";
    print CURRENT_SQLFILE "-- title                = $title_value\n";
    print CURRENT_SQLFILE "-- institution          = $institution_value\n";
    print CURRENT_SQLFILE "-- institution_url      = $institution_url_value\n";
    print CURRENT_SQLFILE "-- institution_dods_url = $institution_dods_url_value\n";
    print CURRENT_SQLFILE "-- source               = $source_value\n";
    print CURRENT_SQLFILE "-- references           = $references_value\n";
    print CURRENT_SQLFILE "-- contact              = $contact_value\n";
    print CURRENT_SQLFILE "-- missing_value        = $missing_value_value\n";
    print CURRENT_SQLFILE "-- _FillValue           = $Fill_value_value\n";
    for my $i (0..$#eastward_current) {
      # Yikes!  Assuming that current u/v counts are the same.
      for my $j (0..$#this_eastward_current_data) {
        # get indexes setup
        my $time_index = int ($j / ($latitude_dim{'dim_size'} * $longitude_dim{'dim_size'}));
        my $lon_index = int (($j - $time_index * $longitude_dim{'dim_size'} * $latitude_dim{'dim_size'}) / $latitude_dim{'dim_size'});
        my $lat_index = int ($j - $time_index * $longitude_dim{'dim_size'} * $latitude_dim{'dim_size'} - $lon_index * $latitude_dim{'dim_size'});

        # now for the vars . . .
      
        if ($eastward_current[$i]{'data'}[$j] != $missing_value_value
            && $eastward_current[$i]{'data'}[$j] != $Fill_value_value
            && $northward_current[$i]{'data'}[$j] != $missing_value_value
            && $northward_current[$i]{'data'}[$j] != $Fill_value_value) {
          print CURRENT_SQLFILE "INSERT INTO current_stage ("; 
          print CURRENT_SQLFILE "station_id,";
          print CURRENT_SQLFILE "time_stamp,"; 
          print CURRENT_SQLFILE "z,";
          print CURRENT_SQLFILE "positive,";
          print CURRENT_SQLFILE "eastward_current,";
          print CURRENT_SQLFILE "northward_current,";
          print CURRENT_SQLFILE "title,";
          print CURRENT_SQLFILE "institution,";
          print CURRENT_SQLFILE "institution_url,";
          print CURRENT_SQLFILE "institution_dods_url,";
          print CURRENT_SQLFILE "source,";
          print CURRENT_SQLFILE "refs,";
          print CURRENT_SQLFILE "contact,";
          print CURRENT_SQLFILE "the_geom";
          print CURRENT_SQLFILE ") "; 
          print CURRENT_SQLFILE "VALUES ("; 
          print CURRENT_SQLFILE   '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print CURRENT_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$time_index].'\'';
          if ($eastward_current[$i]{'height'} == $missing_value_value
            || $eastward_current[$i]{'height'} == $Fill_value_value) {
            print CURRENT_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$eastward_current[$i]{'height'});
            print CURRENT_SQLFILE ','.$this_val;
          }
          print CURRENT_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
          $this_val = sprintf("%.2f",$eastward_current[$i]{'data'}[$j]);
          print CURRENT_SQLFILE ','.$this_val;
          $this_val = sprintf("%.2f",$northward_current[$i]{'data'}[$j]);
          print CURRENT_SQLFILE ','.$this_val;
          print CURRENT_SQLFILE ','.'\''.$title_value.'\'';
          print CURRENT_SQLFILE ','.'\''.$institution_value.'\'';
          print CURRENT_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
          print CURRENT_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
          print CURRENT_SQLFILE ','.'\''.$source_value.'\'';
          print CURRENT_SQLFILE ','.'\''.$references_value.'\'';
          print CURRENT_SQLFILE ','.'\''.$contact_value.'\'';
          print CURRENT_SQLFILE ",GeometryFromText('POINT("; 
          print CURRENT_SQLFILE $longitude_values[$lon_index].' '.$latitude_values[$lat_index]; 
          print CURRENT_SQLFILE ")',-1));\n";
        }
      }
      print CURRENT_SQLFILE "\n";
    }
    close(CURRENT_SQLFILE);
  }
  
  # eastward_wind
  if ($#eastward_wind > -1) {
    open(WIND_SQLFILE,'>../sql_ak_grid_jpl/quickscat_wind_stage_'.$institution_code_value.'_'
      .$platform_code_value.'_'.$package_code_value
      .'_'.time.'_'.rand().'.sql');
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
    for my $i (0..$#eastward_wind) {
      # Yikes!  Assuming that wind u/v counts are the same.
      for my $j (0..$#this_eastward_wind_data) {
        # get indexes setup
        my $time_index = int ($j / ($latitude_dim{'dim_size'} * $longitude_dim{'dim_size'}));
        my $lon_index = int (($j - $time_index * $longitude_dim{'dim_size'} * $latitude_dim{'dim_size'}) / $latitude_dim{'dim_size'});
        my $lat_index = int ($j - $time_index * $longitude_dim{'dim_size'} * $latitude_dim{'dim_size'} - $lon_index * $latitude_dim{'dim_size'});

        # now for the vars . . .
      
        if ($eastward_wind[$i]{'data'}[$j] != $missing_value_value
            && $eastward_wind[$i]{'data'}[$j] != $Fill_value_value
            && $northward_wind[$i]{'data'}[$j] != $missing_value_value
            && $northward_wind[$i]{'data'}[$j] != $Fill_value_value) {
          print WIND_SQLFILE "INSERT INTO quickscat_wind_stage ("; 
          print WIND_SQLFILE "station_id,";
          print WIND_SQLFILE "time_stamp,"; 
#          print WIND_SQLFILE "orbit,";
          print WIND_SQLFILE "z,";
          print WIND_SQLFILE "positive,";
          print WIND_SQLFILE "wind_speed,";
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
          print WIND_SQLFILE ','.'timestamp without time zone \''.$time_formatted_values[$time_index].'\'';
          if ($eastward_wind[$i]{'height'} == $missing_value_value
            || $eastward_wind[$i]{'height'} == $Fill_value_value) {
            print WIND_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$eastward_wind[$i]{'height'});
            print WIND_SQLFILE ','.$this_val;
          }
          print WIND_SQLFILE ','.'\''.$height_var{'positive'}.'\'';          
          $this_east = $eastward_wind[$i]{'data'}[$j];
          $this_north = $northward_wind[$i]{'data'}[$j];          
          $this_speed = sqrt($this_east**2 + $this_north**2);
          $this_val = sprintf("%.2f",$this_speed);
          print WIND_SQLFILE ','.$this_val;
          $pi = 4.0*atan2(1,1);
          $this_theta_from = atan2(-$this_east,-$this_north) * (180.0/$pi);
          if ($this_theta_from < 0) {
            $this_theta_from += 360;
          }
          $this_val = sprintf("%.2f",$this_theta_from);
          print WIND_SQLFILE ','.$this_val;
          print WIND_SQLFILE ",''"; # can_be_normalilzed
          print WIND_SQLFILE ','.'\''.$title_value.'\'';
          print WIND_SQLFILE ','.'\''.$institution_value.'\'';
          print WIND_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=  _blank>'.$institution_url_value.'</a>'.'\'';
          print WIND_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=  _blank>'.$institution_dods_url_value.'</a>'.'\'';
          print WIND_SQLFILE ','.'\''.$source_value.'\'';
          print WIND_SQLFILE ','.'\''.$references_value.'\'';
          print WIND_SQLFILE ','.'\''.$contact_value.'\'';
          print WIND_SQLFILE ",GeometryFromText('POINT("; 
          if ($longitude_values[$lon_index] >= 0 && $longitude_values[$lon_index] <= 180) {
            $this_lon = $longitude_values[$lon_index];
          }
          else {
            $this_lon = -(360 - $longitude_values[$lon_index]);
          }
          print WIND_SQLFILE $this_lon.' '.$latitude_values[$lat_index]; 
          print WIND_SQLFILE ")',-1));\n";
        }
      }
      print WIND_SQLFILE "\n";
    }
    close(WIND_SQLFILE);
  }
}
