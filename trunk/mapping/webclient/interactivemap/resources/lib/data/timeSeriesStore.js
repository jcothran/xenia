Ext.namespace("rcoosmapping.data");


rcoosmapping.data.timeSeriesStore = Ext.extend(Ext.data.Store, {
  lookupTable : undefined,
  constructor: function(config){
      Ext.apply(this, config);

      /*
      var readerObj;
      if(config.dataType == "obsJSON")
      {
        readerObj = new rcoosmapping.data.obsJsonReader(config);
      }
      */
      rcoosmapping.data.timeSeriesStore.superclass.constructor.call(this, config);
  },
  /*
    Function: getValues
    Purpose: For the given observation type, returns an array of the observation values.
    Parameters:
      obsName - A string representing the observation we want to lookup.
    Return:
      Array of the values if found, otherwise returns undefined.
  */
  getValues : function(obsName, convertToImperial)
  {
    var values;
    var rec = this.getById(obsName);
    if(rec !== undefined)
    {
      //var rec = this.getAt(ndx);
      
      values = rec.get("values");
      var i;
      for(i=0; i < values.length; i++)
      {
        if(values[i].length)
        {
          values[i] = Number(values[i]);
          if(convertToImperial)
          {
            var srcUOM = rec.get("uomType");
            //Get the imperial units to convert to.
            var destUOM = this.lookupTable.getImperialUOMName(srcUOM);
            if(destUOM !== undefined && destUOM.length)
            {              
              var convertedVal = this.convertValue(values[i], srcUOM, destUOM);
              //The array is a string initially. To keep things consistent, we convert the imperial
              //value to a string to store back in the array.
              if(convertedVal)
              {
                //values[i] = convertedVal.toString();
                values[i] = convertedVal;
              }
            }
          }
        }
      }
    }
    return(values);
  },
  /*
    Function: getLatestValue
    Purpose: For the given observation type, returns the latest observation value.
    Parameters:
      obsName - A string representing the observation we want to lookup.
    Return:
      The latest values if found, otherwise returns undefined.
  */
  getLatestValue : function(obsName, convertToImperial)
  {
    var value;
    var rec = this.getById(obsName);
    if(rec !== undefined)
    {    
      //var rec = this.getAt(ndx);
      values = rec.get("values");
      value = Number(values[values.length-1]);
      if(convertToImperial)
      {
        //Get the native uom.
        var srcUOM = rec.get("uomType");
        //Get the imperial units to convert to.
        var destUOM = this.lookupTable.getImperialUOMName(srcUOM);
        if(destUOM !== undefined && destUOM.length)
        {
          var convertedVal = this.convertValue(value, srcUOM, destUOM);
          if(convertedVal)
          {
            //value = convertedVal.toString();
            value = convertedVal;
          }
        }
      }
    }
    return(value);
  },
  getLatestQCLevel : function(obsName)
  {
    var qcLevel;
    var rec = this.getById(obsName);
    if(rec !== undefined)    
    {
      //var rec = this.getAt(ndx);
      var qcLevels = rec.get("qc_levels");
      if(qcLevels !== null)
      {
        qcLevel = Number(qcLevels[qcLevels.length-1]);
      }
    }
    return(qcLevel);
  },
  getQCLevels : function(obsName)
  {
    var qcLevels;
    var rec = this.getById(obsName);
    if(rec !== undefined)    
    {    
      //var rec = this.getAt(ndx);
      qcLevels = rec.get("qc_levels");
      if(qcLevels !== null)
      {
        //Convert the levels to numeric values.
        var i;
        for(i=0; i < qcLevels.length; i++)
        {
          qcLevels[i] = Number(qcLevels[i]);
        }
      }
    }
    return(qcLevels);
  },
  /*
  Function: convertValue
  Purpose: For the given value, converts it from the source units to the destination units.
  Parameters:
    value - Number representing to convert.
    srcUOM - string of the units the value is in.
    destUOM - string of the units to convert to.
   Return:
    Number of the converted value.
  */
  convertValue : function(value, srcUOM, destUOM)
  {
    //Look up the data value for the obsName.
    //Convert the value from its metric value to imperial.
    var convertedVal = window.$unitConversion(value, srcUOM).as(destUOM).val();
    return(convertedVal);
  },
  /*
    Function: getTimes
    Purpose: For the given observation type, returns an array of the observation times.
    Parameters:
      obsName - A string representing the observation we want to lookup.
    Return:
      Array of the times if found, otherwise returns undefined.
  */
  getTimes : function(obsName)
  {
    var times;
    var rec = this.getById(obsName);
    if(rec !== undefined)   
    {
      //var rec = this.getAt(ndx);
      times = rec.get("times");
    }
    return(times);
  },
  /*
    Function: getLatestValue
    Purpose: For the given observation type, returns the latest observation time.
    Parameters:
      obsName - A string representing the observation we want to lookup.
    Return:
      The latest time if found, otherwise returns undefined.
  */  
  getLatestTime : function(obsName)
  {
    var times = this.getTimes(obsName);
    if(times !== undefined)
    {
      return(times[times.length-1]);
    }
    return(undefined);
  },
  /**/
  getObsTimeSeries : function(obsName, convertToImperial)
  {
    var timeSeries = [];
    var times = this.getTimes(obsName);
    var values = this.getValues(obsName, convertToImperial);
    if(times !== undefined && values !== undefined)
    {
      var i;
      for(i = 0; i < times.length; i++)
      {
        timeSeries[i] = [times[i],Number(values[i])];
      }
    }
    return(timeSeries);
  }    
});