sub fixed_profiler() 
{
  # top timestamp
  $this_station_id_top_ts = $_[0];
  my $FileCreationOptions = $_[1];
  my $strObsKMLFilePath = $_[2];
  my $iLastNTimeStamps  = $_[3];
  
  print( "fixed_profiler::args: this_station_id_top_ts: $this_station_id_top_ts FileCreationOptions: $FileCreationOptions strObsKMLFilePath: $strObsKMLFilePath iLastNTimeStamps: $iLastNTimeStamps\n");
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
  
  my @KMLTimeStamp;
  
  #
  # Loop through variables looking for standard_name's  
  my $j = 0;

  #Variable stacks.
  my( @time, @z, @longitude, @latitude, @bins, @vars );
  my( $strZName, $strBinsName );
  my $iTimeCnt            = 0;
  #Some netcdf files only have current and speed, or only eastward and northward_current. We keep track of what the current
  #file has so we can calculate the other if it is missing.
  my $bHasCurrentAndSpeed = 0;
  my $bHasEastNorth       = 0;
  for ($i = 0; $i < $nvars; $i++) 
  {
    my $this_var_name;
    my $this_var_type;
    my $this_var_dims;
    my @this_var_dimid = ();
    my $this_var_natts;
    my $this_standard_name = '';
    my $varinq = NetCDF::varinq($ncid, 
                                $i, 
                                \$this_var_name, 
                                \$this_var_type, 
                                \$this_var_dims, 
                                \@this_var_dimid, 
                                \$this_var_natts);
    if ($varinq < 0) 
    {
      die "ABORT!  Cannot get to variables.\n";
    }
    my $attget = NetCDF::attget($ncid, $i, 'standard_name', \$this_standard_name);
    if (substr($this_standard_name,length($this_standard_name)-1) eq chr(0))   
    {
      chop($this_standard_name);
    }
    if ($attget >= 0) 
    {
      if( $this_var_dims <= 0 ) 
      {
        die( "ABORT! $this_standard_name has no dimensions.\n" );
      }
      my $refArrayVarData;
      print( "this_var_name: $this_var_name this_standard_name: $this_standard_name\n" );
      
      my %VariableHash;
      SetupVariableInfo( $this_standard_name, 
                          $this_var_name, 
                          \%VariableHash, 
                          $i, 
                          $this_var_dims, 
                          \@this_var_dimid, 
                          $this_var_natts, 
                          $ncid,
                          $XMLControlFile );
                          
      GetData( $this_standard_name, 
                $this_var_name, 
                \%VariableHash, 
                $ncid );
      
      #Save the slot for the time.
      if( $this_standard_name =~ /^time$/) 
      {
        push( @time, {%VariableHash} );
        
        my %TimeRef = %{$time[0]};
        $iTimeCnt = %TimeRef->{'var_name'}{$this_var_name}{'dim_name'}{'time'}{'dim_size'};
        my $strUnits = %TimeRef->{'var_name'}{$this_var_name}{'units'};
        #Verify time is in correct units.
        my $base_time = UDUNITS::scan($strUnits);
        $base_time->istime()
          || die "ABORT! Invalid units for $this_var_name.\n";
        
        my( $base_year,$base_month,$base_day,$base_hour,$base_minute,$base_second);
        my @Data = %TimeRef->{'var_name'}{$this_var_name}{'data'};
        my $iDataSize = @{$Data[0]};
        if( $iTimeCnt != $iDataSize )
        {
          die( "ABORT! Time Dimension: $iTimeCnt does not match the data count: $iDataSize!\n");
        }
        #COnvert the utc time into the format we use for the database and KML files.
        my $iNdx = 0;
        foreach my $Date (@{$Data[0]})
        {
          my $this_time_value = $base_time->valtocal($Date, 
                                                      $base_year,
                                                      $base_month, 
                                                      $base_day, 
                                                      $base_hour,
                                                      $base_minute,
                                                      $base_second) == 0
          || die "ABORT! Invalid units for $this_var_name.\n";
           #KML tag <TimeStamp><when> requires the date to be formatted in a YYYY-MM-DDThh:mm:ss format
           @KMLTimeStamp[$iNdx++] = $base_year.'-'
          .sprintf("%02d",$base_month).'-'
          .sprintf("%02d",$base_day).'T'
          .sprintf("%02d",$base_hour).':'
          .sprintf("%02d",$base_minute).':'
          .sprintf("%02d",$base_second);

        }
        my $x = 0;                  
      }
      elsif ($this_standard_name =~ /^latitude$/) 
      {
        push( @latitude, {%VariableHash} );
      }
      elsif ($this_standard_name =~ /^longitude$/) 
      {
        push( @longitude, {%VariableHash} );
      }
      elsif ($this_standard_name =~ /^z$/ || $this_standard_name =~ /^height$/ ) 
      {
        $strZName = $this_standard_name;
        push( @z, {%VariableHash} );
      }
      elsif ($this_standard_name =~ /^bin_depth$/) 
      {
        $strBinsName = $this_standard_name;
        push( @bins, {%VariableHash} );
      }
      else
      {
        #For current_speed,current_to_direction, eastward/northward_current, we want to use a specific processing function.
        if( $this_standard_name =~ 'current_speed'    || $this_standard_name =~ 'current_to_direction' ) 
        {
          %VariableHash->{'var_name'}{$this_standard_name}{'process_function'} = \&ProcessADCPVar;
          $bHasCurrentAndSpeed = 1; 
        }
        elsif( $this_standard_name =~ 'eastward_current' || $this_standard_name =~ 'northward_current' ) 
        {
          %VariableHash->{'var_name'}{$this_standard_name}{'process_function'} = \&ProcessADCPVar;
          $bHasEastNorth = 1;
        }

        push( @vars, {%VariableHash} );
      }
    }    
  }

  #From the bins and z, build an SOrder hash.
  my $Bins = @bins[0];
  my $BinData = $Bins->{'var_name'}{$strBinsName}{'data'};
  my $BinCnt = @$BinData;
  #We did not have a bin_depth variable, so lets look to see if there is a bins dimension we can use.
  #If not, we have to assume for the current info that each entry is valid data and not a slot representing
  #either the surface/bottom/average.
  if( !defined @bins[0] )
  {
    my $ID = NetCDF::dimid( $ncid, 'nbins');
    if( $ID != -1 )
    {
      my $DimName = '';
      my $DimSize;
      my $diminq = NetCDF::diminq($ncid,$ID,\$DimName,\$DimSize);    
      if ($diminq >= 0) 
      {
        $BinCnt = $DimSize;
      }
    }
  }
  my $Z = $z[0];

  my $ZData = $Z->{'var_name'}{$strZName}{'data'};
  
   
  my $iStartingNdx = 0;
  if( $iLastNTimeStamps > 0 )
  {
    #If we have more entries in the time_values array, let's set the starting index at the spot in the array which   
    #will get us to the first of the N time stamps.
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

  
  # write data to file(s)
  if( $bWriteobsKMLFile )
  {     
    my $LatHash = $latitude[0];
    my $LonHash = $longitude[0];
    #For profiler Lat and Lon are constant since it is a fixed instrument.
    my( $LatVal, $LonVal );
    GetLatLong( $LatHash, $LonHash, 0, \$LatVal, \$LonVal );
    my $iVarCnt = @vars;
    
    #TIme is always the outer loop. Each measurement is taken at a specific time. 
    my $iTimeNdx = $iStartingNdx;
    for( ; $iTimeNdx < $iTimeCnt; $iTimeNdx++ )
    {
      $strTimeVal = @KMLTimeStamp[$iTimeNdx];
      for( my $iVar = 0; $iVar < $iVarCnt; $iVar++ )
      {
        my $iZNdx = 0;
        my $refVarData = $vars[$iVar];
        foreach my $strVarName ( sort keys %{$refVarData->{'var_name'}} )
        {
          print( "Var: $strVarName\n" );
          if( defined $refVarData->{'var_name'}{$strVarName}{'process_function'} )
          {
            my $ProcFunc = $refVarData->{'var_name'}{$strVarName}{'process_function'};
            &$ProcFunc( $strPlatformID, 
                              $strVarName, 
                              $refVarData, 
                              $strTimeVal,
                              $iTimeNdx, 
                              $LatVal, 
                              $LonVal, 
                              $ZData, 
                              $BinCnt,
                              $bHasCurrentAndSpeed,
                              $bHasEastNorth,
                              \%ObsHash,
                              \@vars );
          }
          else
          {
            ProcessVariable( $strPlatformID, 
                              $strVarName, 
                              $refVarData, 
                              $strTimeVal, 
                              $iTimeNdx,
                              $LatVal, 
                              $LonVal, 
                              $ZData, 
                              \%ObsHash );
          }
        }
      }
    }
    my $iCnt = keys( %ObsHash );
    print( "Cnt: $iCnt\n" );
    if( $iCnt )
    {
      #Moved KMLAddPlatformHashEntry to after we process all the data so we can see if we actually had any data. I correctly implemented the time check
      #to verify the data is no older than 2 weeks.
      #Implemented code to write the obsKML files. 
      obsKMLSubRoutines::KMLAddPlatformHashEntry( $strPlatformID, 
                                                  $institution_url_value, 
                                                  $LatVal, 
                                                  $LonVal, 
                                                  $rObsHash );
      
      my $strXMLPath; 
      my @aSrcFileParts = split( /\//, $net_cdf_file );
      my $strSrcFileName = @aSrcFileParts[-1];
      #Break the filename and extension apart.
      my $iPos = rindex( $strSrcFileName, '.' );
      my $strFileName = $strSrcFileName;
      if( $iPos != -1 )
      {
        $strFileName = substr( $strSrcFileName, 0, $iPos );
      }
      #Use the source netcdf filename.
      #Add the $strDate which gives us a unique file name. Some providers don't uniquely name the netcdf files, so to prevent overwritting of my
      #kml, I add the time.
      $strXMLPath = "$strObsKMLFilePath/$strFileName.kml";
      print( "XMLFilePath: $strXMLPath\n" );
      obsKMLSubRoutines::BuildKMLFile( \%ObsHash, $strXMLPath );
    }
  } 
  
}
#######################################################################################################################
# SetupDimensionInfo
#######################################################################################################################
sub SetupVariableInfo#( $strStandardName, $strVarName, $refVarHash, $iVarId, $iDimCnt, @DimIds, $iNumAtts, $NCDFID )
{
  my( $strStandardName, 
      $strVarName, 
      $refVarHash, 
      $iVarId, 
      $iDimCnt, 
      $DimIds, 
      $iNumAtts, 
      $NCDFID, 
      $XMLControlFile ) = @_;

  $refVarHash->{'var_name'}{$strStandardName}{'var_id'} = $iVarId;    
  
  #Loop through the attributes and save them off.
  for my $k (0..$iNumAtts-1) 
  {
    #Get the attributes name.
    my $strAttName = '';
    my $attname = NetCDF::attname( $NCDFID, 
                                   $iVarId, 
                                   $k, 
                                   \$strAttName);
    #Get the data type of the attribute.                                   
    my $DataType = '';
    my $Len = 0;                                   
    NetCDF::attinq( $NCDFID,
                    $iVarId,
                    $strAttName,
                    \$DataType,
                    \$Len );
    #NOTE::Find out the Perl constant values for the NetCDF data types!!!!!
    if( $DataType != 6 )
    {
      #Get the attributes value.
      my $AttVal = '';                                  
      my $attget = NetCDF::attget($NCDFID, 
                                  $iVarId, 
                                  $strAttName, 
                                  \$AttVal);
      if ($attget < 0)
      {
        die "ABORT!  Cannot get $strVarName $strAttName($k) attribute.\n";
      }
      if(substr($AttVal,length($AttVal)-1) eq chr(0))
      {
        chop($AttVal);
      }
      $refVarHash->{'var_name'}{$strStandardName}{$strAttName} = $AttVal;                                   
    }
    #This data type seems to be used when the attribute is valid_range. It appears to want to store it in an array.
    else
    {
      #Get the attributes value.
      my @AttVal;
      my $attget = NetCDF::attget($NCDFID, 
                                  $iVarId, 
                                  $strAttName, 
                                  \@AttVal);
      if ($attget < 0)
      {
        die "ABORT!  Cannot get $strVarName $strAttName($k) attribute.\n";
      }
      $refVarHash->{'var_name'}{$strStandardName}{$strAttName} = @AttVal;                                   
    }
  }  
  #Validate the units.
  my $strUnits = $refVarHash->{'var_name'}{$strStandardName}{'units'};
  if( length( $strUnits ) )
  {
    if( substr($strUnits,length($strUnits)-1) eq chr(0))
    {
      chop($strUnits);
    }
    my $BaseUnits = UDUNITS::scan($strUnits)
        || die "ABORT! Error with $strVarName units.\n"; 
    if( defined( $XMLControlFile ) )
    {
      #Massage the units into the strings we like to see for the Xenia schema.
      my $strConvUnits = obsKMLSubRoutines::UnitsStringConversion( $strUnits, $XMLControlFile );        
      #String was not found, so we leave it as is and clean it.
      if( length( $strConvUnits ) == 0 )
      {
        #Make sure we don't have any unprintable characters.            
        $strConvUnits = obsKMLSubRoutines::CleanString( $strUnits );                 
      }
      $refVarHash->{'var_name'}{$strStandardName}{'units'} = $strConvUnits; 
    }
  }
  else
  {
    die( "ABORT! $strVarName has no units.\n" );
  }
     
  #Setup the dimension information for the variable.  
  my $i;
  for( $i = 0; $i < $iDimCnt; $i++ )
  {
    my $DimSize = '';
    my $DimName = ''; 
    my $iVarDimId = @$DimIds[$i];
    my $diminq = NetCDF::diminq($NCDFID,$iVarDimId,\$DimName,\$DimSize);
  
#    print( "strVarName: $strVarName iVarId: $iVarId, diminq: $diminq, DimName: $DimName, DimSize: $DimSize\n" );
    if ($diminq >= 0) 
    {
      $refVarHash->{'var_name'}{$strStandardName}{'dim_name'}{$DimName}{'dim_id'}   = $iVarDimId;
      $refVarHash->{'var_name'}{$strStandardName}{'dim_name'}{$DimName}{'dim_size'} = $DimSize;
    }
    else
    {
      die( "ABORT! Dimension information for: $strVarName not found. Error Code: $diminq\n" );
    }
  }
}
#######################################################################################################################
# GetData
#######################################################################################################################
sub GetData #( $strStandardName, $strVarName, \%DimensionHash, $ncid )
{
  my( $strStandardName, $strVarName, $refVarHash, $NCDFID ) = @_;
  my @DataVals;
  my @Index;
  my @ArraySize;
  my $iNumDims = 0;
  #We may have a multi dimensional variable, so we loop to determine each dimension size.
  my $i = 0;
  for my $iDim ( sort keys %{$refVarHash->{'var_name'}{$strStandardName}{'dim_name'}})
  {
    #For multi-dimensional variables, we need to have the starting indices as well as the array sizes.
    #For example, current_speed is sized by time and z. We have 50 times and 18 z's our starting index to read
    #all the data in at once is (0,0) and the array size would be (50,18). We can also read the data in chunks(next rev)
    #by keeping track of the starting index. So each time we read a chunk the x index [x][y] would increase by one.
    @Index[$i] = 0;
    @ArraySize[$i] = $refVarHash->{'var_name'}{$strStandardName}{'dim_name'}{$iDim}{'dim_size'};
    $i++;
  }
    
  my $varget = NetCDF::varget($NCDFID, 
                              $refVarHash->{'var_name'}{$strStandardName}{'var_id'}, 
                              \@Index, 
                              \@ArraySize,
                              \@DataVals);
   $refVarHash->{'var_name'}{$strStandardName}{'data'} = [@DataVals];
   my $i = 0;                              
  
}

#######################################################################################################################
# GetLatLong
#######################################################################################################################
sub GetLatLong #( $LatHash, $LonHash, $DataNdx, /$LatVal, /$LonVal )
{
  my( $LatHash, $LonHash, $DataNdx, $LatVal, $LonVal ) = @_; 
  
  #There is only one variable in this hash, however to keep from hardcoding variable names, we treat
  #it as if there could be others.
  foreach my $strVarName ( sort keys %{$LatHash->{'var_name'}} )
  {
    my @LatData = $LatHash->{'var_name'}{$strVarName}{'data'};
    #Get the data from the slot $DataNdx.
    $$LatVal = @{$LatData[0]}[$DataNdx];
  }
  foreach my $strVarName ( sort keys %{$LonHash->{'var_name'}} )
  {
    my @LonData = $LonHash->{'var_name'}{$strVarName}{'data'};
    $$LonVal = @{$LonData[0]}[$DataNdx];
  }
  return;
}
#######################################################################################################################
# ProcessVariable
#######################################################################################################################
sub ProcessVariable #()
{
  my( $strPlatformID, $strVarName, $refVarData, $strTimeVal, $iTimeNdx, $LatVal, $LonVal, $ZData, $rObsHash ) = @_;
  #For fixed ADCP we have dimensions of time and z. Time is fixed per measurement, and the z count
  #tells us how man data points we need to read for a given time.
  my $iDataNdx = $iTimeNdx;
  my $iZDimCnt = 0;
  my $iDataCnt = 0;
  my $TimeVal = '';
  my $iZVal = 0;
  foreach my $strDimName ( sort keys %{$refVarData->{'var_name'}{$strVarName}{'dim_name'}} )
  {
    #If the dimension is time, let's get the time data for the current slot.
    #WE get the converted time data instead of using the UTC that is in the time field in the netcdf file.
    if( $strDimName =~ 'time' )
    { 
      $TimeVal = $strTimeVal;
    }
    elsif( $strDimName =~ 'z' )
    {
      $iZDimCnt = $refVarData->{'var_name'}{$strVarName}{'dim_name'}{$strDimName}{'dim_size'};
    }            
  }
  #Calc the data index if the variable has a Z dim. For instance we have a variable with a Z dim size of
  #19. First pass $iTimeNdx = 0 and Z dim = 19, so our array offset in the data is iTimeNdx * Z DimSize = 0;
  #Next time through iTimeNdx = 1 so 1 * 19 = 19, we will pull data starting at slot 19 for the data variable.
  #If we have a Z dimension for the variable, we need to adjust our array index.        
  if( $iZDimCnt )
  {
    $iDataNdx *= $iZDimCnt;
    $iDataCnt = $iZDimCnt;
  }
  #No Z/height dimension, so we only have point data.
  else
  {
    $iDataCnt = 1;
  }
  
  my @Data = $refVarData->{'var_name'}{$strVarName}{'data'};          
  my $iStartNdx = $iDataNdx;
  my $iNdx;          
  for( $iNdx = 0; $iNdx < $iDataCnt; $iNdx++ )
  {
    my $Val = @{$Data[0]}[$iStartNdx];    
    if( $iZDimCnt )
    {
      $iZVal = @$ZData[$iNdx];
    }
    else
    {
      $iZVal = @$ZData[0];
    }
    if( $strVarName eq 'water_depth' )
    {
      $iZVal = $Val;
    }
    elsif( $strVarName eq 'water_level' )
    {
      $iZVal = 0;
    }
    my $iSOrder = $iNdx + 1;
    
    OutputData( $strPlatformID,
                $strVarName, 
                $Val,
                $refVarData->{'var_name'}{$strVarName}{'units'},
                $iSOrder,
                $iZVal,               
                $TimeVal, 
                $LatVal, 
                $LonVal,
                $rObsHash );
    $iStartNdx++;
  }      
}
#######################################################################################################################
# OutputData
#######################################################################################################################
sub OutputData #( $strPlatformID, $strVarName, $Val, $strUnits, $SOrder, $Elev, $TimeVal, $LatVal, $LonVal, $rObsHash );
{
  my( $strPlatformID, $strVarName, $Val, $strUnits, $SOrder, $Elev, $TimeVal, $LatVal, $LonVal, $rObsHash ) = @_;
  obsKMLSubRoutines::KMLAddObsToHash( $strVarName, 
                                    $TimeVal,
                                    $Val,
                                    $SOrder,
                                    $strPlatformID,
                                    $Elev,
                                    $strUnits,
                                    $rObsHash );
}

#######################################################################################################################
# ProcessADCPVar
#######################################################################################################################
sub ProcessADCPVar
{
  my( $strPlatformID, 
      $strVarName, 
      $refVarData, 
      $strTimeVal,
      $iTimeNdx, 
      $LatVal, 
      $LonVal, 
      $ZData, 
      $BinCnt,  
      $bHasCurrentAndSpeed, 
      $bHasEastNorth,
      $rObsHash,
      $vars ) = @_;

  my $iDataNdx = $iTimeNdx; #We may only want to print the last N times for the measurements, so we need to take
                            #that into account when calculating the index to access the data array for a given var.
  my $iZDimCnt = 0;
  my $iDataCnt = 0;
  my $TimeVal = '';
  my $iZVal = 0;
  my $iPositiveUp = 0;
  #Is the Z increasing(bottom to surface) or decreasing(surface to bottom)?
  if( @$ZData[0] < @$ZData[-1] )
  {
    $iPositiveUp = 1;
  }
  foreach my $strDimName ( sort keys %{$refVarData->{'var_name'}{$strVarName}{'dim_name'}} )
  {
    #If the dimension is time, let's get the time data for the current slot.
    #WE get the converted time data instead of using the UTC that is in the time field in the netcdf file.
    if( $strDimName =~ 'time' )
    { 
      $TimeVal = $strTimeVal;
    }
    elsif( $strDimName =~ 'z' )
    {
      $iZDimCnt = $refVarData->{'var_name'}{$strVarName}{'dim_name'}{$strDimName}{'dim_size'};
    }            
  }
  #Calc the data index if the variable has a Z dim. For instance we have a variable with a Z dim size of
  #19. First pass $iTimeNdx = 0 and Z dim = 19, so our array offset in the data is iTimeNdx * Z DimSize = 0;
  #Next time through iTimeNdx = 1 so 1 * 19 = 19, we will pull data starting at slot 19 for the data variable.
  #If we have a Z dimension for the variable, we need to adjust our array index.        
  if( $iZDimCnt )
  {
    $iDataNdx *= $iZDimCnt; #This is the starting index into the array.
    $iDataCnt = $iZDimCnt;  #This is the number of data points we pull out of the data array.
    
    #Some ADCP files will have more data than just the bins, usually the last couple of slots will be repeated data representing
    #the bottom current, top current and average current. For now we are going to ignore those. So we will check the bin count
    #and only pull the number of bins we have.    
    if( defined( $BinCnt ) && $iZDimCnt > $BinCnt )
    {
      $iDataCnt = $BinCnt;
    }    
  }
  else
  {
    die( "ABORT::Z dimension not found for $strVarName.\n" );
  }
  my @Data       = $refVarData->{'var_name'}{$strVarName}{'data'};          
  if( defined( @Data ) )
  {
    my @CalcData;
      #If we are on one of the force/magnitude variables and we don't have the vector components, we calculate them
    if( $strVarName eq 'current_speed' && $bHasEastNorth == 0 )          
    {
      my $iVarCnt = @$vars;
      for( my $iVar = 0; $iVar < $iVarCnt; $iVar++ )
      {
        my $VarData = @$vars[$iVar];
        foreach my $strVar ( sort keys %{$VarData->{'var_name'}} )
        {
          if( $strVar eq 'current_to_direction' )
          {
            @CalcData = $VarData->{'var_name'}{'current_to_direction'}{'data'};
            last;
          }
        }
      }  
    }
    elsif( $strVarName eq 'eastward_current' && $bHasCurrentAndSpeed == 0 )
    {
      my $iVarCnt = @$vars;
      for( my $iVar = 0; $iVar < $iVarCnt; $iVar++ )
      {
        my $VarData = @$vars[$iVar];
        foreach my $strVar ( sort keys %{$VarData->{'var_name'}} )
        {
          if( $strVar eq 'northward_current' )
          {
            @CalcData = $VarData->{'var_name'}{'northward_current'}{'data'};
            last;
          }
        }
      }
    }
    my $iStartNdx = $iDataNdx;
    my $iNdx;          
    for( $iNdx = 0; $iNdx < $iDataCnt; $iNdx++ )
    {
      my $Val = @{$Data[0]}[$iStartNdx];
      if( $Val == $Fill_value_value || $Val == $missing_value_value )
      { 
        $Val = 'NULL';
      }
      else
      {
        $Val = sprintf("%.3f", $Val );
      }
      if( $iZDimCnt )
      {
        $iZVal = @$ZData[$iNdx];
      }
      else
      {
        $iZVal = @$ZData[0];
      }
      my $iSOrder = $iNdx + 1;
      if( $iPositiveUp )
      {
        $iSOrder = $iDataCnt - $iNdx;
      }
      OutputData( $strPlatformID,
                  $strVarName, 
                  $Val,
                  $refVarData->{'var_name'}{$strVarName}{'units'},
                  $iSOrder,
                  $iZVal,               
                  $TimeVal, 
                  $LatVal, 
                  $LonVal,
                  $rObsHash );
                  
      #Calculate the Speed/Direction?
      if( ( $bHasCurrentAndSpeed == 0 ) && 
          ( @CalcData ) )
      {
        my @MagDir;
        @MagDir[0] = 'NULL';
        @MagDir[1] = 'NULL';
        if( $Val != 'NULL' )
        {
          my $NorthVal = @{$CalcData[0]}[$iStartNdx];        
          @MagDir = GetMagAndDir( $Val, $NorthVal, 1 );
        }    
        #Write the current speed.
        OutputData( $strPlatformID,
                    'current_speed', 
                    @MagDir[0],
                    $refVarData->{'var_name'}{$strVarName}{'units'},
                    $iSOrder,
                    $iZVal,               
                    $TimeVal, 
                    $LatVal, 
                    $LonVal,
                    $rObsHash );
        #Write the current direction.
        OutputData( $strPlatformID,
                    'current_to_direction', 
                    @MagDir[1],
                    'degrees_true',
                    $iSOrder,
                    $iZVal,               
                    $TimeVal, 
                    $LatVal, 
                    $LonVal,
                    $rObsHash );
      }
      #Calculate the east/north components?
      elsif(( $bHasEastNorth == 0 ) && 
            ( @CalcData ) )
      {
        my( $EastCurrent, $NorthCurrent ) = 'NULL';
                
        if( $Val != 'NULL' )
        {
          my $DirVal = @{$CalcData[0]}[$iStartNdx];
          CalcVectorComponents( $Val, $DirVal, \$EastCurrent, \$NorthCurrent );
        }
        OutputData( $strPlatformID,
                    $strVarName, 
                    $EastCurrent,
                    $refVarData->{'var_name'}{$strVarName}{'units'},
                    $iSOrder,
                    $iZVal,               
                    $TimeVal, 
                    $LatVal, 
                    $LonVal,
                    $rObsHash );
        OutputData( $strPlatformID,
                    $strVarName, 
                    $NorthCurrent,
                    $refVarData->{'var_name'}{$strVarName}{'units'},
                    $iSOrder,
                    $iZVal,               
                    $TimeVal, 
                    $LatVal, 
                    $LonVal,
                    $rObsHash );
      }                  
      $iStartNdx++;
    }  
  }
  else
  {
    print( "ERROR::No data for var: $strVarName.\n" );
  }    
}
#######################################################################################################################
# CalcVectorComponents
#######################################################################################################################
sub CalcVectorComponents
{
  my( $Magnitude, $Direction, $EastComponent, $NorthComponent ) = @_;
  $$EastComponent = $Magnitude * sin( deg2rad($Direction) );
  $$NorthComponent = $Magnitude * sin( deg2rad($Direction) );  
}
#######################################################################################################################
# get_mag_and_dir
#######################################################################################################################
sub GetMagAndDir {

my ($x, $y, $scale) = @_;
my ($mag,$angle);

$mag = sprintf("%.2f",$scale*sqrt($x*$x+$y*$y));
#print "$mag\n";

$angle = atan2($y,$x);
$angle = sprintf("%.2f",180/3.1416*$angle);
$angle = 90 - $angle;
#only return positive degrees
if ($angle < 0) 
{ 
  $angle = 360 + $angle; 
}

my @result = ($mag, $angle);

return (@result);

}
