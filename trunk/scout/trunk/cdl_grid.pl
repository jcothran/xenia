#!/bin/perl

sub grid () {

  # 
  # Hopefully I'll be able to pull this precision from the source,
  # but we need something to normalize the data.

  my $lon_decimal_places = 2;
  my $lat_decimal_places = 3;
  
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
      if ($this_standard_name =~ /^longitude$/) {
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
      elsif ($this_standard_name =~ /^orbit$/) {
        %orbit_dim = (
          ref_var_name => $this_var_name,
          ref_var_id   => $i,
          dim_id       => '',
          dim_name     => '',
          dim_size     => ''
        );
        if ($this_var_dims != 1) {die "ABORT! orbit has incorrect number of dimensions.\n";}
        %orbit_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0]
        );
      }
      elsif ($this_standard_name =~ /^height$/) {
        if ($this_var_dims != 1) {die "ABORT! Height has incorrect number of dimensions.\n";}
        %height_var = (
          var_name => $this_var_name,
          var_id   => $i,
          dim_id   => $this_var_dimid[0],
          positive => ''
        );
      }
      # push all time's onto a stack
      elsif ($this_standard_name =~ /^time$/) {
        %this_time = (
          var_name   => $this_var_name,
          var_id     => $i,
          dim_id_orb => $this_var_dimid[0],
          height     => ''
        );
        push @time, {%this_time};
      }
      # push all wind_speed's onto a stack
      elsif ($this_standard_name =~ /^wind_speed$/) {
        %this_wind_speed = (
          var_name   => $this_var_name,
          var_id     => $i,
          dim_id_lon => $this_var_dimid[0],
          dim_id_lat => $this_var_dimid[1],
          dim_id_orb => $this_var_dimid[2],
          height     => '',
          can_be_normalized => ''
        );
        push @wind_speed, {%this_wind_speed};
      }
      # push all wind_from_direction's onto a stack
      elsif ($this_standard_name =~ /^wind_from_direction$/) {
        %this_wind_from_direction = (
          var_name   => $this_var_name,
          var_id     => $i,
          dim_id_lon => $this_var_dimid[0],
          dim_id_lat => $this_var_dimid[1],
          dim_id_orb => $this_var_dimid[2],
          height     => '',
          can_be_normalized => ''
        );
        push @wind_from_direction, {%this_wind_from_direction};
      }
    }
  }

  #
  # Required dimensions:  latitude, longitude, orbit
  # Find out names through the variables.
  # Abort if all are not found.
  
  if (length($latitude_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No latitude dimension ref. found via variable.\n";
  }
  if (length($longitude_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No longitude dimension ref. found via variable.\n";
  }
  if (length($orbit_dim{'ref_var_name'}) < 1) {
    $err .= "ABORT! No orbit dimension ref. found via variable.\n";
  }
  if (length($err) > 0) {
    die $err;
  }
  
  #
  # Get the dimensions and their sizes.
  
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
  #  print "longitude dim_name [$longitude_dim{'dim_name'}] dim_size [$longitude_dim{'dim_size'}]\n";
  }

  # orbit
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,$orbit_dim{'ref_var_name'});
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $orbit_dim{'dim_id'}   = $this_dim_id;
      $orbit_dim{'dim_name'} = $this_dim_name;
      $orbit_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting orbit dimension.\n";
    }
  #  print "orbit dim_name [$orbit_dim{'dim_name'}] dim_size [$orbit_dim{'dim_size'}]\n";
  }

  #
  # Check to make sure that the required variables have
  # the correct dimensions listed, e.g. latitude(latitude), longitude(longitude), etc.
  
  # latitude
  if ($latitude_var{'dim_id'} != $latitude_dim{'dim_id'}) {
    die "ABORT! latitude variable does not have correct latitude dimension.\n";
  }
  
  # longitude
  if ($longitude_var{'dim_id'} != $longitude_dim{'dim_id'}) {
    die "ABORT! longitude variable does not have correct longitude dimension.\n";
  }

  # orbit
  if ($orbit_var{'dim_id'} != $orbit_dim{'dim_id'}) {
    die "ABORT! orbit variable does not have correct orbit dimension.\n";
  }
    
  #
  # Get the data of the required elements.

  @longitude_values      = '';
  @latitude_values       = '';
  @orbit_values          = '';
  @height_value          = '';
  my $positive_value     = '';
  
  # longitude (vector)
  $varget = NetCDF::varget($ncid, $longitude_var{'var_id'}, (0), $longitude_dim{'dim_size'}, \@longitude_values);
  if ($varget < 0) {die "ABORT! Cannot get longitude values.\n";}
  
  # latitude (vector)
  $varget = NetCDF::varget($ncid, $latitude_var{'var_id'}, (0), $latitude_dim{'dim_size'}, \@latitude_values);
  if ($varget < 0) {die "ABORT! Cannot get latitude values.\n";}

  # orbit (vector)
  $varget = NetCDF::varget($ncid, $orbit_var{'var_id'}, (0), $orbit_dim{'dim_size'}, \@orbit_values);
  if ($varget < 0) {die "ABORT! Cannot get orbit values.\n";}

  # time's
  @this_time_data = ();
  @this_time_formatted_values = ();
  for $i (0..$#time) {
    # this variable's dimension better be (orbit)
    if ($time[$i]{'dim_id_orb'} != $orbit_dim{'dim_id'}) {
      die "ABORT!  $time[$i]{'var_name'} has wrong dimension.  Should be orbit.\n";
    }
    else {
      # get all the variable goodies
      @this_time_slice = $orbit_dim{'dim_size'};
      @zero_offset = (0);
      $varget = NetCDF::varget($ncid, $time[$i]{'var_id'},
        \@zero_offset, \@this_time_slice, \@this_time_data);
      if ($varget < 0) {die "ABORT! Cannot get $time[$i]{'var_name'} data.\n";}

      # get time units
      my $units_value = '';
      my $attget = NetCDF::attget($ncid, $time[$i]{'var_id'}, 'units', \$units_value);
      if ($attget < 0) {die "ABORT! $time[$i]{'var_name'} has no units.\n";}
      if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
      my $base_time = UDUNITS::scan($units_value)
        || die "ABORT! Error with $time[$i]{'var_name'} units.\n";
      $base_time->istime()
        || die "ABORT! Invalid units for $time[$i]{'var_name'}.\n";

      # format the time values for database insertion (no timezone right now)
      for my $i (0..$#this_time_data) {
        # convert the time value to new value based on the time units
        my $this_time_value = $base_time->valtocal($this_time_data[$i], 
          $base_year, $base_month, $base_day, $base_hour, $base_minute, $base_second) == 0
          || die "ABORT! Invalid units for $time_var{'var_name'}.\n";
        $this_time_formatted_values[$i] = $base_year.'-'
          .sprintf("%02d",$base_month).'-'
          .sprintf("%02d",$base_day).' '
          .sprintf("%02d",$base_hour).':'
          .sprintf("%02d",$base_minute).':'
          .sprintf("%02d",$base_second);
      }
    
      # add a NULL where missing value
      for my $j (0..$#this_time_formatted_values) {
        push @{$time[$i]{'data'}}, $this_time_formatted_values[$j];
      }
    }
  }

  # wind_speed's
  @this_wind_speed_data = ();
  for $i (0..$#wind_speed) {
    # this variable's dimensions better be (longitude, latitude, orbit)
    if ($wind_speed[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
      || $wind_speed[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}
      || $wind_speed[$i]{'dim_id_orb'} != $orbit_dim{'dim_id'}) {
      die "ABORT!  $wind_speed[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_wind_speed_slice = ($longitude_dim{'dim_size'},$latitude_dim{'dim_size'},$orbit_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $wind_speed[$i]{'var_id'},
        \@zero_offset, \@this_wind_speed_slice, \@this_wind_speed_data);
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
        if ($this_attname eq $height_var{'var_name'}) {
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
      # abort if we didn't have an height attribute
      if ($wind_speed[$i]{'height'} == '') {
        die "ABORT!  $wind_speed[$i]{'var_name'} has no height.\n";
      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_speed_data) {
        push @{$wind_speed[$i]{'data'}}, $this_wind_speed_data[$j];
      }
    }
  }
  
  # wind_from_direction's
  @this_wind_from_direction_data = ();
  for $i (0..$#wind_from_direction) {
    # this variable's dimensions better be (longitude, latitude, orbit)
    if ($wind_from_direction[$i]{'dim_id_lon'} != $longitude_dim{'dim_id'}
      || $wind_from_direction[$i]{'dim_id_lat'} != $latitude_dim{'dim_id'}
      || $wind_from_direction[$i]{'dim_id_orb'} != $orbit_dim{'dim_id'}) {
      die "ABORT!  $wind_from_direction[$i]{'var_name'} has wrong dimension triplet.\n";
    }
    else {
      # get all the variable goodies
      @this_wind_from_direction_slice = ($longitude_dim{'dim_size'},$latitude_dim{'dim_size'},$orbit_dim{'dim_size'});
      @zero_offset = (0,0,0);
      $varget = NetCDF::varget($ncid, $wind_from_direction[$i]{'var_id'},
        \@zero_offset, \@this_wind_from_direction_slice, \@this_wind_from_direction_data);
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
        if ($this_attname eq $height_var{'var_name'}) {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_from_direction[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_from_direction[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_from_direction[$i]{'height'} = $attval;
        }
        elsif ($this_attname eq 'can_be_normalized') {
          my $attval = '';
          my $attget = NetCDF::attget($ncid, $wind_from_direction[$i]{'var_id'}, $this_attname, \$attval);
          if ($attget < 0) {die "ABORT!  Cannot get $wind_from_direction[$i]{'var_name'} $k attribute.\n";}
          if (substr($attval,length($attval)-1) eq chr(0)) {chop($attval);}
          $wind_from_direction[$i]{'can_be_normalized'} = $attval;
        }
      }
      # abort if we didn't have an height attribute
      if ($wind_from_direction[$i]{'height'} == '') {
        die "ABORT!  $wind_from_direction[$i]{'var_name'} has no height.\n";
      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_from_direction_data) {
        push @{$wind_from_direction[$i]{'data'}}, $this_wind_from_direction_data[$j];
      }
    }
  }
  
  #
  # write data to file(s)
  
  # wind_speed and wind_from_direction
  # assume that wind_speed and wind_from_direction have an ordered, 1:1 relationship
  if ($#wind_speed > -1) {
    open(WIND_SQLFILE,'>../sql/quickscat_wind_stage_'.$institution_code_value.'_'
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
      for my $k (0..$#this_wind_speed_data) {
        my $lon_index = int ($k / ($latitude_dim{'dim_size'} * $orbit_dim{'dim_size'}));
        my $lat_index = int (($k - $lon_index * $latitude_dim{'dim_size'} * $orbit_dim{'dim_size'}) / $orbit_dim{'dim_size'});
        my $orb_index = int ($k - $lon_index * $latitude_dim{'dim_size'} * $orbit_dim{'dim_size'} - $lat_index * $orbit_dim{'dim_size'});
        if ($wind_speed[$i]{'data'}[$k] != $missing_value_value
          && $wind_speed[$i]{'data'}[$k] != $Fill_value_value
          && $wind_from_direction[$i]{'data'}[$k] != $missing_value_value
          && $wind_from_direction[$i]{'data'}[$k] != $Fill_value_value) {
          print WIND_SQLFILE "INSERT INTO quickscat_wind_stage ("; 
          print WIND_SQLFILE "station_id,";
          print WIND_SQLFILE "time_stamp,"; 
          print WIND_SQLFILE "orbit,";
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
          print WIND_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print WIND_SQLFILE ','.'timestamp without time zone \''.$time[$i]{'data'}[$orb_index].'\'';
          print WIND_SQLFILE ','.$orbit_values[$orb_index];
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
          $this_val = sprintf("%.2f",$wind_from_direction[$i]{'data'}[$k]);
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

          $this_longitude = $longitude_values[$lon_index];
          $this_longitude =~ /(-\d*).(\d{$lon_decimal_places})/;
          ($this_lon_left, $this_lon_right) = ($1, $2);
          $this_lon_R = $this_lon_right / 25.0;
          $this_lon_R = sprintf "%.0f", $this_lon_R;
          $this_lon_right = 25 * $this_lon_R;
          $this_longitude = $this_lon_left - (0.1**$lon_decimal_places) * $this_lon_right;

          $this_latitude = $latitude_values[$lat_index];
          $this_latitude =~ /(-\d*|\d*).(\d{$lat_decimal_places})/;
          ($this_lat_left, $this_lat_right) = ($1, $2);
          $this_lat_R = $this_lat_right / 25.0;
          $this_lat_R = sprintf "%.0f", $this_lat_R;
          $this_lat_right = 25 * $this_lat_R; 
          $this_latitude = "$this_lat_left.$this_lat_right";

          printf WIND_SQLFILE "$this_longitude $this_latitude";
          print WIND_SQLFILE ")',-1));\n";
        }
      }
      print WIND_SQLFILE "\n";
    }
    close(WIND_SQLFILE);
  }
}
