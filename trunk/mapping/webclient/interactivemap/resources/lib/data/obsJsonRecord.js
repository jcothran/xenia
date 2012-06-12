Ext.namespace("rcoosmapping.data");

/** api: constructor
 *  .. class:: obsJsonRecord
 *  
 *      A record that represents an obsJSON data feed. This record
 *      will always have at least the following fields:
 *
      type
      geometryType
      geometryCoords
      obsType
      uomType
      times
      values
      sorder
      qc_levels
 */
rcoosmapping.data.obsJsonRecord = Ext.data.Record.create([
    {name : "platformId",  mapping  : "stationId"},
    {name : "collectionType", mapping : "type"},
    {name : "features", mapping : "features"}
    /*
    {name : "platformCollectionType", mapping : "features.type"},
    {name : "geometryType", mapping : "features.geometry.type"}, 
    {name : "geometryCoords", mapping : "features.geometry.coordinates"},
    {name : "obsType", mapping : "features.properties.obsType"},
    {name : "uomType", mapping : "features.properties.uomType"},
    {name : "times", mapping : "features.properties.time"},
    {name : "values", mapping : "features.properties.value"},
    {name : "sorder", mapping : "features.properties.sorder"},
    {name : "qc_levels", mapping : "features.properties.qc_level"}
    */
]);




/** api: classmethod[create]
 *  :param o: ``Array`` Field definition as in ``Ext.data.Record.create``. Can
 *      be omitted if no additional fields are required.
 *  :return: ``Function`` A specialized :class:`rcoosmapping.data.obsJsonRecord`
 *      constructor.
 *  
 *  Creates a constructor for a :class:`rcoosmapping.data.obsJsonRecord`, optionally
 *  with additional fields.
 */
rcoosmapping.data.obsJsonRecord.create = function(o) {
    var f = Ext.extend(rcoosmapping.data.obsJsonRecord, {});
    var p = f.prototype;

    p.fields = new Ext.util.MixedCollection(false, function(field) {
        return field.name;
    });

    rcoosmapping.data.obsJsonRecord.prototype.fields.each(function(f) {
        p.fields.add(f);
    });

    if(o) {
        for(var i = 0, len = o.length; i < len; i++){
            p.fields.add(new Ext.data.Field(o[i]));
        }
    }

    f.getField = function(name) {
        return p.fields.get(name);
    };

    return f;
};

/*
  Function: getValues
  Purpose: For the given observation type, returns an array of the observation values.
  Parameters:
    obsName - A string representing the observation we want to lookup.
  Return:
    Array of the values if found, otherwise returns undefined.
*/
rcoosmapping.data.obsJsonRecord.prototype.getValues = function(convertToImperial)
{
  var values;    
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
  return(values);
};
/*
  Function: getLatestValue
  Purpose: For the given observation type, returns the latest observation value.
  Parameters:
    obsName - A string representing the observation we want to lookup.
  Return:
    The latest values if found, otherwise returns undefined.
*/
rcoosmapping.data.obsJsonRecord.prototype.getLatestValue = function(convertToImperial)
{
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
  return(value);
};

rcoosmapping.data.obsJsonRecord.prototype.getLatestQCLevel = function()
{
  var qcLevel;
  //var rec = this.getAt(ndx);
  var qcLevels = rec.get("qc_levels");
  if(qcLevels !== null)
  {
    qcLevel = Number(qcLevels[qcLevels.length-1]);
  }
  return(qcLevel);
};

rcoosmapping.data.obsJsonRecord.prototype.getQCLevels = function()
{
  var qcLevels;
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
  return(qcLevels);
};
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
rcoosmapping.data.obsJsonRecord.prototype.convertValue = function(value, srcUOM, destUOM)
{
  //Look up the data value for the obsName.
  //Convert the value from its metric value to imperial.
  var convertedVal = window.$unitConversion(value, srcUOM).as(destUOM).val();
  return(convertedVal);
};
/*
  Function: getTimes
  Purpose: For the given observation type, returns an array of the observation times.
  Parameters:
    obsName - A string representing the observation we want to lookup.
  Return:
    Array of the times if found, otherwise returns undefined.
*/
rcoosmapping.data.obsJsonRecord.prototype.getTimes = function()
{
  times = rec.get("times");
  return(times);
};
/*
  Function: getLatestValue
  Purpose: For the given observation type, returns the latest observation time.
  Parameters:
    obsName - A string representing the observation we want to lookup.
  Return:
    The latest time if found, otherwise returns undefined.
*/  
rcoosmapping.data.obsJsonRecord.prototype.getLatestTime = function()
{
  var times = this.getTimes();
  if(times !== undefined)
  {
    return(times[times.length-1]);
  }
  return(undefined);
};
/**/
rcoosmapping.data.obsJsonRecord.prototype.getObsTimeSeries = function(convertToImperial)
{
  var timeSeries = [];
  var times = this.getTimes();
  var values = this.getValues(convertToImperial);
  if(times !== undefined && values !== undefined)
  {
    var i;
    for(i = 0; i < times.length; i++)
    {
      timeSeries[i] = [times[i],Number(values[i])];
    }
  }
  return(timeSeries);
};


/*------------------------------------------------------------------------------------------------------------------*/
rcoosmapping.data.obsTimeSeriesRecord = Ext.data.Record.create([
    {name : "obsName", mapping : "features.properties.obsType"},
    {name : "uom", mapping : "features.properties.uomType"},
    {name : "times", mapping : "features.properties.time"},
    {name : "values", mapping : "features.properties.value"},
    {name : "sorder", mapping : "features.properties.sorder"},
    {name : "qc_levels", mapping : "features.properties.qc_level"}
]);
/** api: classmethod[create]
 *  :param o: ``Array`` Field definition as in ``rcoosmapping.data.obsTimeSeriesRecord.create``. Can
 *      be omitted if no additional fields are required.
 *  :return: ``Function`` A specialized :class:`rcoosmapping.data.obsTimeSeriesRecord`
 *      constructor.
 *  
 *  Creates a constructor for a :class:`rcoosmapping.data.obsTimeSeriesRecord`, optionally
 *  with additional fields.
 */
rcoosmapping.data.obsTimeSeriesRecord.create = function(o) {
    var f = Ext.extend(rcoosmapping.data.obsTimeSeriesRecord, {});
    var p = f.prototype;

    p.fields = new Ext.util.MixedCollection(false, function(field) {
        return field.name;
    });

    rcoosmapping.data.obsTimeSeriesRecord.prototype.fields.each(function(f) {
        p.fields.add(f);
    });

    if(o) {
        for(var i = 0, len = o.length; i < len; i++){
            p.fields.add(new Ext.data.Field(o[i]));
        }
    }

    f.getField = function(name) {
        return p.fields.get(name);
    };

    return f;
};
