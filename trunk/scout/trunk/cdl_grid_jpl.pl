#!/bin/perl

sub grid_jpl () {

  # some JPL exceptions
  $missing_value_value = 'nan';
  $Fill_value_value = 'nan';
  $institution_code_value = $institution_value;
  $institution_code_value =~ s/ /_/g;
  $platform_code_value = 'quikscat';
  $package_code_value = 'quikscat';


  # Assume this data is on a normal grid, and assume that the variable
  # names are fixed and agreed upon, i.e. no :standard_name attrs.

  #
  # Loop through variables
  
  my $this_var_name = '';
  my $this_var_type = '';
  my $this_var_dims = '';
  my @this_var_dimid = '';
  
  for ($i = 0; $i < $nvars; $i++) {
    my $varinq = NetCDF::varinq($ncid, $i, \$this_var_name, 
      \$this_var_type, \$this_var_dims, \@this_var_dimid, \$this_var_natts);
    if ($varinq < 0) {die "ABORT!  Cannot get to variables.\n";}
    if ($this_var_name =~ /^lon_range$/) {
      if ($this_var_dims != 1) {die "ABORT! lon_range has incorrect number of dimensions.\n";}
      %lon_range_var = (
        var_name => $this_var_name,
        var_id   => $i,
        dim_id   => $this_var_dimid[0]
      );
    }
    elsif ($this_var_name =~ /^lat_range$/) {
      if ($this_var_dims != 1) {die "ABORT! lat_range has incorrect number of dimensions.\n";}
      %lat_range_var = (
        var_name => $this_var_name,
        var_id   => $i,
        dim_id   => $this_var_dimid[0]
      );
    }
    elsif ($this_var_name =~ /^grid_spacing$/) {
      if ($this_var_dims != 1) {die "ABORT! grid_spacing has incorrect number of dimensions.\n";}
      %grid_spacing_var = (
        var_name => $this_var_name,
        var_id   => $i,
        dim_id   => $this_var_dimid[0]
      );
    }
    elsif ($this_var_name =~ /^grid_dimensions$/) {
      if ($this_var_dims != 1) {die "ABORT! grid_dimensions has incorrect number of dimensions.\n";}
      %grid_dimensions_var = (
        var_name => $this_var_name,
        var_id   => $i,
        dim_id   => $this_var_dimid[0]
      );
    }
    elsif ($this_var_name =~ /^epoch_time_range$/) {
      if ($this_var_dims != 1) {die "ABORT! epoch_time_range has incorrect number of dimensions.\n";}
      %epoch_time_range_var = (
        var_name => $this_var_name,
        var_id   => $i,
        dim_id   => $this_var_dimid[0]
      );
    }
    # push all wind_speed's onto a stack
    elsif ($this_var_name =~ /^wind_speed$/) {
      %this_wind_speed = (
        var_name     => $this_var_name,
        var_id       => $i,
        dim_id_npnts => $this_var_dimid[0],
        height       => '',
        can_be_normalized => ''
      );
      push @wind_speed, {%this_wind_speed};
    }
    # push all wind_from_direction's onto a stack
    elsif ($this_var_name =~ /^wind_direction$/) {
      %this_wind_from_direction = (
        var_name     => $this_var_name,
        var_id       => $i,
        dim_id_npnts => $this_var_dimid[0],
        height       => '',
        can_be_normalized => ''
      );
      push @wind_from_direction, {%this_wind_from_direction};
    }
  }

  #
  # Get the dimensions and their sizes.
  
  # side
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,'side');
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $side_dim{'dim_id'}   = $this_dim_id;
      $side_dim{'dim_name'} = $this_dim_name;
      $side_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting side dimension.\n";
    }
  #  print "side dim_name [$side_dim{'dim_name'}] dim_size [$side_dim{'dim_size'}]\n";
  }

  # npnts
  {
    my $this_dim_size = '';
    my $this_dim_name = '';
    my $this_dim_id = NetCDF::dimid($ncid,'npnts');
    my $diminq = NetCDF::diminq($ncid,$this_dim_id,\$this_dim_name,\$this_dim_size);
    if ($diminq >= 0) {
      $npnts_dim{'dim_id'}   = $this_dim_id;
      $npnts_dim{'dim_name'} = $this_dim_name;
      $npnts_dim{'dim_size'} = $this_dim_size;
    }
    else {
      die "ABORT! Error $diminq getting npnts dimension.\n";
    }
  #  print "npnts dim_name [$npnts_dim{'dim_name'}] dim_size [$npnts_dim{'dim_size'}]\n";
  }

  #
  # Check to make sure that the required variables have
  # the correct dimensions listed, e.g. latitude(latitude), longitude(longitude), etc.
  
  # lon_range
  if ($lon_range_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT! lon_range variable does not have correct side dimension.\n";
  }

  # lat_range
  if ($lat_range_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT! lat_range variable does not have correct side dimension.\n";
  }

  # grid_spacing
  if ($grid_spacing_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT! grid_spacing variable does not have correct side dimension.\n";
  }

  # grid_dimensions
  if ($grid_dimensions_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT! grid_dimensions variable does not have correct side dimension.\n";
  }

  # epoch_time_range
  if ($epoch_time_range_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT! epoch_time_range variable does not have correct side dimension.\n";
  }
      
  #
  # Get the data of the required elements.

  @lon_range_values        = '';
  @lat_range_values        = '';
  @grid_spacing_values     = '';
  @grid_dimensions_values  = '';
  @epoch_time_range_values = '';
  my $positive_value       = '';
  
  # lon_range (vector)
  $varget = NetCDF::varget($ncid, $lon_range_var{'var_id'}, (0), $side_dim{'dim_size'}, \@lon_range_values);
  if ($varget < 0) {die "ABORT! Cannot get lon_range values.\n";}

  # lat_range (vector)
  $varget = NetCDF::varget($ncid, $lat_range_var{'var_id'}, (0), $side_dim{'dim_size'}, \@lat_range_values);
  if ($varget < 0) {die "ABORT! Cannot get lat_range values.\n";}

  # grid_spacing (vector)
  $varget = NetCDF::varget($ncid, $grid_spacing_var{'var_id'}, (0), $side_dim{'dim_size'}, \@grid_spacing_values);
  if ($varget < 0) {die "ABORT! Cannot get grid_spacing values.\n";}

  # grid_dimensions (vector)
  $varget = NetCDF::varget($ncid, $grid_dimensions_var{'var_id'}, (0), $side_dim{'dim_size'}, \@grid_dimensions_values);
  if ($varget < 0) {die "ABORT! Cannot get grid_dimensions values.\n";}

  # epoch_time_range (vector)
  $varget = NetCDF::varget($ncid, $epoch_time_range_var{'var_id'}, (0), $side_dim{'dim_size'}, \@epoch_time_range_values);
  if ($varget < 0) {die "ABORT! Cannot get epoch_time_range values.\n";}  

  # time's
  @this_time_data = ();
  @this_time_formatted_value = '';
  # this variable's dimension better be (side)
  if ($epoch_time_range_var{'dim_id'} != $side_dim{'dim_id'}) {
    die "ABORT!  $epoch_time_range_var{'var_name'} has wrong dimension.  Should be side.\n";
  }
  else {
    # get all the variable goodies
    @this_time_slice = $side_dim{'dim_size'};
    @zero_offset = (0);
    $varget = NetCDF::varget($ncid, $epoch_time_range_var{'var_id'},
      \@zero_offset, \@this_time_slice, \@this_time_data);
    if ($varget < 0) {die "ABORT! Cannot get $epoch_time_range_var{'var_name'} data.\n";}

    # get time units
    my $units_value = '';
    my $attget = NetCDF::attget($ncid, $epoch_time_range_var{'var_id'}, 'units', \$units_value);
    if ($attget < 0) {die "ABORT! $epoch_time_range_var{'var_name'} has no units.\n";}
    if (substr($units_value,length($units_value)-1) eq chr(0)) {chop($units_value);}
    my $base_time = UDUNITS::scan('secs since 1970-1-1 (UTC)')
      || die "ABORT! Error with $epoch_time_range_var{'var_name'} units.\n";
    $base_time->istime()
      || die "ABORT! Invalid units for $epoch_time_range_var{'var_name'}.\n";

    # going to average the times for one time value
    $total_time = 0;
    for my $i (0..$#this_time_data) {
      $total_time += $this_time_data[$i];
    }
    $averaged_time = $total_time / ($#this_time_data+1);

    # convert the time value to new value based on the time units
    my $this_time_value = $base_time->valtocal($averaged_time, 
      $base_year, $base_month, $base_day, $base_hour, $base_minute, $base_second) == 0
      || die "ABORT! Invalid units for $time_var{'var_name'}.\n";

    # format the time values for database insertion (no timezone right now)
    $this_time_formatted_value = $base_year.'-'
      .sprintf("%02d",$base_month).'-'
      .sprintf("%02d",$base_day).' '
      .sprintf("%02d",$base_hour).':'
      .sprintf("%02d",$base_minute).':'
      .sprintf("%02d",$base_second);
  
    # this is overkill (since there is only 1 time) but in keeping w/ the rest of the CDL .pl
    push @{$epoch_time_range_var{'data'}}, $this_time_formatted_value;
  }

  # wind_speed's
  @this_wind_speed_data = ();
  for $i (0..$#wind_speed) {
    # this variable's dimensions better be (npnts)
    if ($wind_speed[$i]{'dim_id_npnts'} != $npnts_dim{'dim_id'}) {
      die "ABORT!  $wind_speed[$i]{'var_name'} has wrong dimension.\n";
    }
    else {
      # get all the variable goodies
      @this_wind_speed_slice = ($npnts_dim{'dim_size'});
      @zero_offset = (0);
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
# cpurvis temp fix
#      if ($wind_speed[$i]{'height'} == '') {
#        die "ABORT!  $wind_speed[$i]{'var_name'} has no height.\n";
#      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_speed_data) {
        push @{$wind_speed[$i]{'data'}}, $this_wind_speed_data[$j];
      }
    }
  }
  
  # wind_from_direction's
  @this_wind_from_direction_data = ();
  for $i (0..$#wind_from_direction) {
    # this variable's dimensions better be (npnts)
    if ($wind_from_direction[$i]{'dim_id_npnts'} != $npnts_dim{'dim_id'}) {
      die "ABORT!  $wind_from_direction[$i]{'var_name'} has wrong dimension.\n";
    }
    else {
      # get all the variable goodies
      @this_wind_from_direction_slice = ($npnts_dim{'dim_size'});
      @zero_offset = (0);
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
# cpurvis temp fix
#      if ($wind_from_direction[$i]{'height'} == '') {
#        die "ABORT!  $wind_from_direction[$i]{'var_name'} has no height.\n";
#      }
      # add a NULL where missing value
      for my $j (0..$#this_wind_from_direction_data) {
        $this_dir = $this_wind_from_direction_data[$j] - 180;
        if ($this_dir < 0) {
          $this_dir += 360;
        }
        elsif ($this_dir > 360) {
          $this_dir -= 360;
        }
        # push @{$wind_from_direction[$i]{'data'}}, (180.0 - $this_wind_from_direction_data[$j]);
        push @{$wind_from_direction[$i]{'data'}}, $this_dir;
      }
    }
  }
  
  #
  # write data to file(s)
 
  # wind_speed and wind_from_direction
  # assume that wind_speed and wind_from_direction have an ordered, 1:1 relationship
  if ($#wind_speed > -1) {
    # need time and rand as part of filename since PO.DAAC isn't using *latest convention
    open(WIND_SQLFILE,'>../sql_grid_jpl/quickscat_wind_stage_'.$institution_code_value.'_'
      .$platform_code_value.'_'.$package_code_value.'_'
      .time.'_'.rand()
      .'.sql');
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
    for my $wind_index (0..$#wind_speed) {
      $i = 0;
      $j = 0;
      for my $k (0..$#this_wind_speed_data) {
        if ($i == $grid_dimensions_values[0]) {
          $i = 0;
          $j++;
        }
        # $lon = $min_lon + $i * $grid_size_lon
        $longitude = $lon_range_values[0] + $i * $grid_spacing_values[0];
        # $lat = $max_lat - $j * $grid_size_lat
        $latitude  = $lat_range_values[1] - $j * $grid_spacing_values[1];
        if (!($wind_speed[$wind_index]{'data'}[$k] =~ /$missing_value_value/
          && $wind_speed[$wind_index]{'data'}[$k] =~ /$Fill_value_value/
          && $wind_from_direction[$wind_index]{'data'}[$k] =~ /$missing_value_value/
          && $wind_from_direction[$wind_index]{'data'}[$k] =~ /$Fill_value_value/)) {
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
          print WIND_SQLFILE '\''.$institution_code_value.'_'.$platform_code_value.'_'.$package_code_value.'\'';
          print WIND_SQLFILE ','.'timestamp without time zone \''.$epoch_time_range_var{'data'}[0].'\'';
#          print WIND_SQLFILE ',\'\'';
# temp fix cpurvis
$wind_speed[$wind_index]{'height'} = 15.0;
          if ($wind_speed[$wind_index]{'height'} == $missing_value_value
            || $wind_speed[$wind_index]{'height'} == $Fill_value_value) {
            print WIND_SQLFILE ','.'\'\'';
          }
          else {
            $this_val = sprintf("%.2f",$wind_speed[$wind_index]{'height'});
            print WIND_SQLFILE ','.$this_val;
          }
          print WIND_SQLFILE ','.'\''.$height_var{'positive'}.'\'';
          $this_val = sprintf("%.2f",$wind_speed[$wind_index]{'data'}[$k]);
          print WIND_SQLFILE ','.$this_val;
          $this_val = sprintf("%.2f",$wind_from_direction[$wind_index]{'data'}[$k]);
          print WIND_SQLFILE ','.$this_val;
          print WIND_SQLFILE ','.'\''.$wind_speed[$wind_index]{'can_be_normalized'}.'\'';
          print WIND_SQLFILE ','.'\''.$title_value.'\'';
          print WIND_SQLFILE ','.'\''.$institution_value.'\'';
          print WIND_SQLFILE ','.'\''.'<a href='.$institution_url_value.' target=_blank>'.$institution_url_value.'</a>'.'\'';
          print WIND_SQLFILE ','.'\''.'<a href='.$institution_dods_url_value.' target=_blank>'.$institution_dods_url_value.'</a>'.'\'';
          print WIND_SQLFILE ','.'\''.$source_value.'\'';
          print WIND_SQLFILE ','.'\''.$references_value.'\'';
          print WIND_SQLFILE ','.'\''.$contact_value.'\'';
          print WIND_SQLFILE ",GeometryFromText('POINT("; 
          print WIND_SQLFILE "$longitude $latitude";
          print WIND_SQLFILE ")',-1));\n";
        }
        $i++;
      }
      print WIND_SQLFILE "\n";
    }
    close(WIND_SQLFILE);
  }
}
