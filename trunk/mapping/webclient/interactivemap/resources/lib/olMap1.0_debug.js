Ext.namespace('rcoosmapping');


GeoExt.Popup.prototype.getState = function()  { return null; }


/*------------------------------------------------------------------------------------------------------------------------------------*/
/*
Object: rcoosmapping.lookupTable
Purpose: This object is used to perform various lookups for platform metadata. In an effort to keep the metadata file small, we use integer IDs
 to define strings, such as observation names, units of measurements, ect.
*/
rcoosmapping.lookupTable = Ext.extend(Ext.data.Record,
{  
  obsTypes : null,
  uomTypes : null,
  organization : null,
  dataUrl : null,
  iconUrls : null,
  platformTypes : null,
  constructor: function(config) 
  {    
    if(config.data.lookups.obs_type !== undefined)
    {
      this.obsType = config.data.lookups.obs_type;
    }
    if(config.data.lookups.uom_type !== undefined)
    {
      this.uomTypes = config.data.lookups.uom_type;
    }
    if(config.data.lookups.organization !== undefined)
    {
      this.organization = config.data.lookups.organization;
    }
    if(config.data.lookups.data_url !== undefined)
    {
      this.dataUrl = config.data.lookups.data_url;
    }
    if(config.data.lookups.icon_urls !== undefined)
    {
      this.iconUrls = config.data.lookups.icon_urls;
    }
    if(config.data.lookups.type_list !== undefined)
    {
      this.platformTypes = config.data.lookups.type_list;
    }
    rcoosmapping.lookupTable.superclass.constructor.call(this, config);
  },
  getDisplayIconURL : function(iconID)
  {
    var url;
    if(this.iconUrls.icons[iconID] !== undefined)
    {
      url = this.iconUrls.icons[iconID];
    }
    return(url);    
  },
  getObsName : function(obsID)
  {
    var obsName;
    if(this.obsType[obsID] !== undefined)
    {
      obsName = this.obsType[obsID].standard_name;
    }
    return(obsName);
  },
  getObsDisplayName : function(obsID)
  {
    var obsName;
    if(this.obsType[obsID] !== undefined)
    {
      obsName = this.obsType[obsID].display;
    }
    return(obsName);
  },
  getObsID : function(obsName)
  {
    var obsId;
    for(var obsId in this.obsType)
    {
      if(this.obsType[obsId].display == obsName || this.obsType[obsId].standard_name == obsName)
      {
        return(obsId);
      }
    }
    return(undefined);
  },  
  getUOMName : function(uomID, useImperial)
  {
    var uomName;
    if(this.uomTypes[uomID] !== undefined)
    {
      if(useImperial)
      {
        uomName = this.uomTypes[uomID].imperial;
      }
      else
      {
        uomName = this.uomTypes[uomID].display;
      }
      if(uomName === undefined || uomName.length === 0) 
      {
        uomName = this.uomTypes[uomID].display;
      }
    }
    return(uomName);
  },
  getNativeUOMName : function(uomID)
  {
    var uomName;
    if(this.uomTypes[uomID] !== undefined)
    {
      //The standard name is the native units in the database for the uom.
      uomName = this.uomTypes[uomID].standard_name;
    }
    return(uomName);
  },
  getImperialUOMName : function(uom)
  {
    var uomName;
    for(var uomId in this.uomTypes)
    {
      if(this.uomTypes[uomId].standard_name == uom)
      {
        uomName = this.uomTypes[uomId].imperial;
        break;
      }
    }
    return(uomName);
  },
  getOrganizationName : function(orgId)
  {
    var orgName;
    if(this.organization[orgId] !== undefined)
    {
      orgName = this.organization[orgId].short_name;
    }
    return(orgName);
  },
  getOrganizationID : function(orgName)
  {
    for(var orgId in this.organization)
    {
      if(this.organization[orgId].short_name == orgName)
      {
        return(orgId);
      }
    }
    return(undefined);
  },
  getOrganizationURL : function(orgId)
  {
    var url;
    if(this.organization[orgId] !== undefined)
    {
      url = this.organization[orgId].url;
    }
    return(url);
  },
  getDataURL : function(urlId)
  {
    var url;
    if(this.dataUrl[urlId] !== undefined)
    {
      url = this.dataUrl[urlId].url;
    }
    return(url);    
  },
  getDataURLType : function(urlId)
  {
    var type;
    if(this.dataUrl[urlId] !== undefined)
    {
      type = this.dataUrl[urlId].type;
    }
    return(type);    
  },
  getDataURLTooltip : function(urlId)
  {
    var tip;
    if(this.dataUrl[urlId] !== undefined)
    {
      tip = this.dataUrl[urlId].tip;
    }
    return(tip);    
  },
  getPlatformTypeName : function(id)
  {
    var type;
    if(this.platformTypes[id] !== undefined)
    {
      type = this.platformTypes[id].type_name;
    }
    return(type);    
  }
});
/*------------------------------------------------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------------------------------------------*/

/*
  Object: rcoosmapping.observationsObj
  Purpose: This handles the GeoJSON observation files created for each platform. The JSON files contain the latest observation data
    for the platform.
*/
rcoosmapping.observationsObj = Ext.extend(Ext.data.JsonStore,
{
  lookupTable : null, 
  /*
    Function: constructor
    Purpose: Creates the object. The fields which detail the GeoJSON structure are defined here.
    Parameters:
      config - a configuration object. Required fields:
        data - this is the GeoJSON object we want this store to contain.
        
  */
  constructor: function(config) 
  {    
    if(config === undefined)
    {
      config = {};
    }
    config.autoDestroy = true;
    config.root = "features";
    config.idProperty = function(rec)
    {
      var key = rec.properties.obsType + ":" + rec.properties.sorder + ":" + rec.properties.uomType;
      return(key);
    };
    this.lookupTable = config.lookupTable;
    //Here we define the layout of the JSON object. A sample of a JSON record would be:
    /*
    {"type": "Feature",
            "geometry": {
                "type": "MultiPoint",
                "coordinates": [] 
            },
         "properties": {
            "obsType": "air_pressure",
            "uomType": "mb",
            "time": [],
            "value": []
        }}
    */
    config.fields =
    [
      {name : "type", mapping : "type"},
      {name : "geometryType", mapping : "geometry.type"}, 
      {name : "geometryCoords", mapping : "geometry.coordinates"},
      {name : "obsType", mapping : "properties.obsType"},
      {name : "uomType", mapping : "properties.uomType"},
      {name : "times", mapping : "properties.time"},
      {name : "values", mapping : "properties.value"},
      {name : "sorder", mapping : "properties.sorder"},
      {name : "qc_levels", mapping : "properties.qc_level"}
    ];
    rcoosmapping.observationsObj.superclass.constructor.call(this, config);
  },
  /*findRecord(obsName, uomType, sorder)
  {
    
  }*/
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
    //var ndx = this.find("obsType", obsName);
    //if(ndx != -1)
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
    //var ndx = this.find("obsType", obsName);
    //if(ndx != -1)
    //{
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
    //var ndx = this.find("obsType", obsName);
    //if(ndx != -1)
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
    //var ndx = this.find("obsType", obsName);
    //if(ndx != -1)
    //{
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
    //var ndx = this.find("obsType", obsName);
    //if(ndx != -1)
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
/*------------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------------*/

//rcoosmapping.timeSeriesGraph = Ext.extend(Ext.Panel, {
rcoosmapping.timeSeriesGraph = Ext.extend(Ext.ux.HighChart, {
  
  //hcGraph : null,
  //chartOptions : null,
  
  initComponent: function() {
    //this.listeners = {afterrender : this.afterrender};  
    rcoosmapping.timeSeriesGraph.superclass.initComponent.call(this);
  },
  /*initGraph : function(options)
  {
    if(this.body !== undefined)
    {
      options.chart.renderTo = this.body.dom;
      if(this.hcGraph !== null)
      {
        delete(this.hcGraph);
      }
      this.hcGraph = new Highcharts.Chart(options);
    }
    else
    {
      this.chartOptions = options;
    }
  },
  afterrender : function()
  {
    this.chartOptions.chartConfig.chart.renderTo = this.body.dom;
    if(this.hcGraph !== null)
    {
      delete(this.hcGraph);
    }
    this.hcGraph = new Highcharts.Chart(this.chartOptions.chartConfig);
  },*/
  
  addTimeSeries : function(obsName, uom, timeSeries, append, timePeriod)
  {
    if(this.chart === undefined)
    {
      this.chart = new Highcharts.Chart(this.chartConfig);
    }

    //this.hcGraph.setTitle(obsName + '(' + uom +')');
    //this.setTitle(obsName + '(' + uom +')');
    var categories = [];
    var i;
    for(i = 0; i < timeSeries.length; i++)
    {
      var time = timeSeries[i][0];
      var dataTime = time.replace(' ', 'T');
      dataTime = Date.parseDate(time, "c");          
      //Convert to local time.
      categories[i] = dataTime.format("Y-m-d<br/>H:i:s");
    }
    //this.chart.xAxis[0].options.tickInterval = Math.round(categories.length / 2);
    this.chart.xAxis[0].setCategories(categories);
    //this.hcGraph.xAxis[0].setCategories(categories);
    var series = [{
      type : 'line',
      name : obsName,
      data : timeSeries
    }];
    //this.hcGraph.addSeries(series, true);
    this.addSeries(series, true);
    //Now adjust the yAxis label.
    var axis = this.chart.yAxis[0];
    axis.options.title.text = obsName + '(' + uom +')';
    axis.axisTitle.destroy();
    axis.axisTitle = null;
    axis.hasRenderedTitle = false;      
    axis.redraw();
  }
});
/*------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------------------------------------*/

rcoosmapping.insitu = Ext.extend(Ext.Panel,
{  
  feature : null,         //This is the platform metadata.
  obsStore : null,        //This is the dataStore for the recent observations for this platform.
  selectControl : null,   //The OpenLayers.Control.SelectControl that handles the user selection of the feature that triggered this popup.
  googAnalytics : null,   //The google analytics tracking object.
  
  initComponent : function()
  {
    this.id = 'Observations';
    this.title = 'Observations';
    this.layout = 'border';
    var header = this.buildHeaderPanel(this.feature);
    var tbar = this.buildToolbar();
    this.bbar = [tbar];
    var dataPanel = new Ext.Panel({
        id : 'dataPanel',
        region : 'center',
        width : 500,
        height : 100,
        margins : '1 1 1 1',
        layout : 'border'
      });
    this.buildDataPanels(dataPanel, this.feature);
    this.items = [header,dataPanel];
    rcoosmapping.insitu.superclass.initComponent.call(this);
  },
  destroy : function()
  {
    if(this.obsStore !== null)
    {
      this.obsStore.removeAll();
    }
    /*if(this.feature !== null)
    {
    }*/
    var dataPanel = this.findById('dataPanel');
    if(dataPanel !== null)
    {
      var currentObs = dataPanel.findById('currentObs');      
      if(currentObs !== null)
      {
        currentObs.store.removeAll();
      }
    }
    //Unselect the feature so the user can immediately click on it again if they want to.
    //
    var vecFeature = this.feature.get('feature');
    this.selectControl.unselect(vecFeature);
  },
  buildToolbar : function()
  {
    var lookupTable = this.feature.get('lookupTable');   
    var links = this.feature.get("links");
    var tbar = [];
    var linkType;
    for(linkType in links)
    {
      tbar.push(
      {
        id: linkType,
        type: 'button',
        tooltip: lookupTable.getDataURLTooltip(links[linkType].urlId),
        tooltipType: 'title',
        icon: lookupTable.getDisplayIconURL(links[linkType].iconId),
        listeners:{
          click : function(buttonObj, eventObj)
          {
            var lookupTable = this.feature.get('lookupTable');   
            var links = this.feature.get("links");
            var url = lookupTable.getDataURL(links[buttonObj.id].urlId) + links[buttonObj.id].id;
            window.open(url);
            //If we have the google tracker, let's track which button the user has pushed along with the platform.
            if(this.googAnalytics !== null)
            {
              this.googAnalytics.trackEvent("Interactive Map Platforms", buttonObj.id, this.feature.get('staID'));
            }      
            
          },
          scope: this
        }
      });
    }
    return(tbar);
  },
  
  setObsData : function(obsData)
  {
    //Set the obsDataObj parameter in our feature store.
    //this.feature.beginEdit();
    //this.feature.set('obsDataObj', obsData);
    //this.feature.endEdit();
    //Check to see if we have a loading panel, if so let's get rid of it then add the
    //data panels.
    var dataAvailable = false;
    if(obsData !== undefined)
    {
      dataAvailable = true;

      if(this.obsStore !== null)
      {
        this.obsStore.removeAll();
      }
      var lookupTable = this.feature.get('lookupTable');   
      this.obsStore = new rcoosmapping.observationsObj({data: obsData, lookupTable : lookupTable});
      var dataPanel = this.findById('dataPanel');
      if(dataPanel !== null)
      {
        var currentObs = dataPanel.findById('currentObs');      
        if(currentObs !== null)
        {
          var dvStore = currentObs.getStore();
          dvStore.remove();
          
          var updateTime = null;
          var data = [];
          var platformObs = this.feature.get('staObs');
          if(platformObs.length)
          {
            var i;
            for(i = 0; i < platformObs.length; i++)
            {
              var obsNfo = platformObs[i];
              //Based on the obsservation ID, get it's string.
              var obsName = lookupTable.getObsName(obsNfo.Properties.obsTypeDesc);
              //Get the display name for the observation. This is the string used to present the information to the user.
              var obsDisplayName = lookupTable.getObsDisplayName(obsNfo.Properties.obsTypeDesc);
              if(obsDisplayName === undefined || (obsDisplayName.length === 0))
              {
                obsDisplayName = obsName;
              }
              var dbUomName = lookupTable.getNativeUOMName(obsNfo.Properties.uomID, true);
              var sorder = obsNfo.Properties.sorder;
              var key = obsName + ":" + sorder + ":" + dbUomName;
              //Look up the data value for the obsName.
              //var value = Number(obsStore.getLatestValue(obsName, true));
              var value = this.obsStore.getLatestValue(key, true);
              if(value !== undefined)
              {
                value = value.toFixed(2);
              }
              else
              {
                value = "";
              }
              var qcLevel = this.obsStore.getLatestQCLevel(key);
              //Get the imperial units to convert to.
              var uomName = lookupTable.getUOMName(obsNfo.Properties.uomID, true);
              var dataRec = Ext.data.Record.create([
                { name : 'obsName', mapping : 'obsName' }, 
                { name : 'obsDisplayName', mapping : 'obsDisplayName' }, 
                { name : 'value', mapping : 'value', type : 'float'}, 
                { name : 'uomName', mapping : 'uomName' },
                { name : 'dbUomName', mapping : 'dbUomName' },                
                { name : 'sorder', mapping : 'sorder' },
                { name : 'qcLevel', mapping : 'qcLevel'}
              ]);
              var obsRec = new dataRec(
              {
                obsName : obsName,
                obsDisplayName: obsDisplayName,
                value: value, 
                uomName: uomName,
                dbUomName: dbUomName,
                sorder: sorder,
                qcLevel: qcLevel
              });
              dvStore.add(obsRec);
              if(updateTime === null)
              {
                var time = this.obsStore.getLatestTime(key);            
                if(time !== undefined)
                {
                  updateTime = time.replace(' ', 'T');
                  updateTime = Date.parseDate(updateTime, "c");          
                  //Update the time panel.
                  var timePanel = dataPanel.findById('currentObsTime');
                  if(timePanel !== null)
                  {
                    //var timeData = {loading: false, time: updateTime};
                    timePanel.update({loading: false, time: updateTime});
                  }
                  var graphPanel = dataPanel.findById('obsGraphPanel');
                  if(graphPanel !== null)
                  {
                    var timeSeries = this.obsStore.getObsTimeSeries(key, true);
                    graphPanel.addTimeSeries(obsDisplayName,
                                             uomName,
                                             timeSeries,
                                             false);
                                             
                  }
                }
              }
            }
          }
          //No observation available for the platform.
          else
          {
            dataAvailable = false;
          }
          currentObs.selectRange(0, 0, false);
        }
      }
    }
    //Data was not available for the platform, so let's notate that in the time panel.
    if(dataAvailable === false)
    {
      var dataPanel = this.findById('dataPanel');
      if(dataPanel !== null)
      {
        //No observation available for the platform.
        //Update the time panel.
        var timePanel = dataPanel.findById('currentObsTime');
        if(timePanel !== null)
        {
          var timeData = {loading: false, time: null};
          timePanel.update(timeData);
        }
      }
    }
  },
  
  buildHeaderPanel : function(feature)
  {
    var tpl = new Ext.XTemplate('<div>',
        '<table width="100%" class="layoutAssistant"><tbody>',
        '<tr><td class="default"><p class="markerHead"><a target="_blank" href="{[values.get("staURL")]}">Station {[values.get("staID")]}</a></p></td></tr>',
        '</tbody></table>',
        '<div class="area markerVSpace"><table width="100%" class="layoutAssistant"><tbody>',
        '<tr><td class="default"><p class="region"><b>Location: </b>{[values.get("staDesc")]}</p></td><td style="padding-left: 8px;" class="default aright"><p class="latLon aright"><b>Lat:</b> {[values.get("lat")]} <b>Lon:</b> {[values.get("lon")]}</p></td></tr></tbody></table>',
        '<p class="provider"><b>Provider:</b> <a target="_blank" href="{[values.get("lookupTable").getOrganizationURL(values.get("orgName"))]}" class="iwa">{[values.get("lookupTable").getOrganizationName(values.get("orgName"))]}</a><b>Data Source:</b> {[values.get("lookupTable").getOrganizationName(values.get("orgName"))]}</p>',
        '<tpl if="this.checkStatus(values)"><table width="100%" class="layoutAssistant">',
        '<tbody><tr><td class="default"><p class="platformIssue"><b>Issue:</b> {[values.get("status")["begin_date"]]} {[values.get("status")["reason"]]}<p></td></tr></tbody></table></tpl>',
        '</div>',
        '</div>',
        {
          checkStatus : function(values)
          {
            var status = values.get("status");
            if(status === null)
            {
              return(false);
            }
            return(true);
          }
        });
    var headerPanel = {
      region : 'north',
      layout : 'fit',
      margins : '1 1 1 1',
      width : 500,
      height : 'auto',
      tpl : tpl,
      data : feature,
      listeners : {render : function(panel) {
          panel.tpl.overwrite(this.body, this.data);
        }
      }
    };
    return(headerPanel);
  },  
  /*
  Function: buildDataPanel
  Purpose: Builds the panel that will house the various methods to display the observation data: The center panel is the current observations,
    the north panel is the data time, the east panel is the graph created when a user clicks on an observation.
  Parameters:
    dataStore is an object containing the the various bits of data about the platform and current observations.
  Return:
    Ext.Panel object.
  */
  buildDataPanels : function(dataPanel, feature)
  {
    /*
    Build the Ext.DataView panel that shows the current observation values.
    */
    var obsTpl = null;
    var timeTpl = null;
    var obsView = null;
    if(dataPanel !== null)
    {
      obsTpl = new Ext.XTemplate(
      '<div class="markerMeasurements">',
      '<table class="layoutAssistant chart" align="left"><tbody>',
      '<tpl for=".">',
      '<tr class="chartButton thumb-wrap"><td class="chartButtonL"><b>{obsDisplayName}</b></td><td class="chartButtonM">{value}</td><td class="chartButtonR">{uomName}</td></tr>',
      '</tpl>',
      '</tbody></table>',
      '</div>');
      
      var obsListStore = new Ext.data.Store();
      var obsView = new Ext.DataView({
        id : 'currentObs',
        cls : 'area obs-panel-body',
        region : 'center',
        layout : 'fit',
      	emptyText : "Loading data",
        store : obsListStore,
        data: feature,
        width : 250,
        height : 200,
        margins : '1 1 1 1',
        tpl : obsTpl,
        autoScroll: true,
        singleSelect : true,
        overClass:'x-view-over',
        itemSelector:'tr.thumb-wrap',
        listeners : {
          click : this.obsClicked
        }
      });
      
      timeTpl = new Ext.XTemplate(
      '<div style="padding: 2px;" class="updateInfo">',
      '<table align="center" class="layoutAssistant"><tbody>',
      '<tr>',
      '<tpl if="values.loading"><td class="default vcenter"><div id="loading-mask"></div><div id="loading"><div class="loading-indicator"><b>Loading...</b></div></div></td></tpl>',
      '<tpl if="values.loading == false">',
      '<td class="default vcenter"><img width="18" height="18" border="0" src={[this.getDataAgeIcon(values.time)]} style="margin-right: 5px;"></td>',
      '<td class="default vcenter"><p style="padding: 0px;" class="updateInfo"><b><span class="updateInfo">Data Updated: </span></b><span class="updateInfo">{[this.getTimeString(values.time)]}</span></p></td></tr>',
      '</tbody></table>',
      '</tpl>',
      '</div>',
      {      
        /*
        Function: getDataAgeIcon
        Purpose: This is a template function that looks at the date/time of the observation data and determines which icon to use to indicate
          the data age.
        Parameter:
          dataTime is the Date() object representing the date/time of the data.
        Return:
          string to the icon to use.
        */
        getDataAgeIcon : function(dataTime)
        {          
          var iconPath = "./resources/images/data_age/";
          if(dataTime !== null)
          {
            var ct = new Date();  
            var diff = ct.getElapsed(dataTime);
            var hourMilliseconds = 3600000; //3600 seconds in 1 hour
            //time difference is an hour or less, then the data is fresh.
            if(diff <= hourMilliseconds)
            {
              iconPath += "icon_0-1.png";
            }
            else if((diff > hourMilliseconds) && (diff <= (2*hourMilliseconds)))
            {
              iconPath += "icon_1-2.png";
            }
            else if((diff > (2*hourMilliseconds)) && (diff < (3*hourMilliseconds)))
            {
              iconPath += "icon_2-3.png";
            }
            else if((diff > (3*hourMilliseconds)) && (diff < (4*hourMilliseconds)))
            {
              iconPath += "icon_3-4.png";
            }
            else if((diff > (4*hourMilliseconds)) && (diff < (12*hourMilliseconds)))
            {
              iconPath += "icon_10-11.png";
            }
            else
            {
              iconPath += "icon_12+.png";
            }
          }
          //For whatever reason we don't have a data time stamp.
          else
          {
            iconPath += "icon_no_data.png";
          }
          return(iconPath);          
        },
        /*
        Function: getTimeString
        Purpose: This is a template function that looks at the date/time object and returns the string we want the time displayed as.
        Parameter:
          dataTime is the Date() object representing the date/time of the data.
        Return:
          string for the time.
        */
        getTimeString : function(dataTime)
        {
          var timeString = "No Data Available";
          if(dataTime !== null)
          {
            timeString = dataTime.format("Y-m-d H:i:s");
          }
          return(timeString);
        }
      });
      var timePanel = new Ext.Panel({
        id : 'currentObsTime',
        bodyCssClass : 'area',
        region : 'north',
        layout : 'fit',
        margins : '1 1 1 1',
        width : 500,
        height : 25,
        html: '',
        tpl : timeTpl,
        //data : feature,
        listeners : {render : function(panel) {
          var data = null;
          if(this.data === undefined)
          {
            data = {loading : true};
          }
          panel.tpl.overwrite(this.body, data);
        }}             
      });
      
     
      var graphPanel = new rcoosmapping.timeSeriesGraph({
        id : 'obsGraphPanel',
        region : 'east',
        layout : 'fit',
        width : 250,
        height : 200,
        chartConfig: {
          chart: {
            defaultSeriesType: 'line',
            backgroundColor : '#FFFFFF', //'#E8ECEF',
            margin: [10, 30, 40, 60]
          },
          plotOptions: {
            line: {
              color: '#000000',
              lineWidth: 1,
              marker: {
                radius: 2
              }            
            }
          },
          title : {
            text : 'Observation Graph',
            style:
            {
              color : '#000000',
              fontSize: '11px'
            }
          },
          subtitle : {
            text : '',
            style:
            {
              color : '#000000',
              fontSize: '8px'
            }
          },
          
          tooltip: {
            formatter: function() {
                var time = this.point.name;            
                updateTime = time.replace(' ', 'T');
                updateTime = Date.parseDate(updateTime, "c"); 
                updateTime = updateTime.format("m-d H:i:s");
            
                var toolTip = "Date: " + updateTime + "<br>Value: " + this.y.toFixed(2);
                
                return toolTip;
            }
          },
          legend : {
            enabled : false
          },
          xAxis: [{
            //type: 'datetime',
            //startOnTick: true,
            endOnTick: true,
            maxPadding: 0.0,
            minPadding: 0.0,
            showLastLabel: true,
            labels: {
              //rotation: -90,
              align: 'center',
              style: {
                 font: '10px tahoma,arial,helvetica,sans-serif',
                 color : '#000000'
              },
              formatter: function() {
                if(this.isFirst || this.isLast)
                {
                  return(this.value);
                }
              }                 
            }
          }],
          yAxis: [{
            maxPadding: 0.0,
            minPadding: 0.0,
            title: {
                text: ' ',
                style: {
                   font: '10px tahoma,arial,helvetica,sans-serif',
                   color : '#000000'
                }
            },
            labels: {
              style: {
                 font: '10px tahoma,arial,helvetica,sans-serif',
                 color : '#000000'
              }
            }
          }]
        }
      });    
      dataPanel.add(timePanel);
      dataPanel.add(obsView);
      dataPanel.add(graphPanel);
    }
    return(dataPanel);    
  },
  /*
  Function: obsClicked
  Purpose: Click handler when the user clicks in the current obs data panel to select a new observation to graph.
  */
  obsClicked : function(dataView, index, node, eventObj)
  {
    //Get the root container of the dataView.
    var dataPanel = dataView.ownerCt;
    if(dataPanel !== null)
    {
      //Now let's get the parent of the dataPanel(dataView's parent). This is the base container.
      var parent = dataPanel.ownerCt;
      if(parent !== null)
      {
        //Get the record where the user clicked.
        var rec = dataView.store.getAt(index);
        if(rec !== null)
        {
          //Get the native observation name so we can then look up the data for that time series.
          var obsName = rec.get('obsName');
          var dbUomName = rec.get('dbUomName');
          var sorder = rec.get('sorder');
          //Get the graph panel so we can update it with the new data.
          var graphPanel = dataPanel.findById('obsGraphPanel');
          if(graphPanel !== null)
          {
            var key = obsName + ":" + sorder + ":" + dbUomName;
            var timeSeries = parent.obsStore.getObsTimeSeries(key, true);
            graphPanel.addTimeSeries(rec.get('obsDisplayName'),
                                     rec.get('uomName'),
                                     timeSeries,
                                     false);
                                     
          }          
        }
      }
    }
  }    
});
/*------------------------------------------------------------------------------------------------------------------------------------*/
rcoosmapping.popup = Ext.extend(GeoExt.Popup,
{     
  feature : null,
  selectControl : null,
  googAnalytics : null,
  
  initComponent : function()
  {
    this.listeners = {afterrender : this.afterrender};
    rcoosmapping.popup.superclass.initComponent.call(this);
  },
  /*
  Function: afterrender
  Purpose: Event fires after this window renders. We can then correctly size our tab to fit into the window.
  */
  afterrender : function()
  {
    var tabPanel = new Ext.TabPanel({
                      resizeTabs: true,
                      width: this.getInnerWidth(),
                      height: this.getInnerHeight(),
                      id: 'tabPanel',
                      activeTab: 0
                     });  
    this.add(tabPanel);
    var obsPanel = new rcoosmapping.insitu(
      {
        itemId : 'insituPanel',
        feature : this.feature,
        selectControl : this.selectControl,
        googAnalytics : this.googAnalytics
        //width: 500,
        //height: height
      });
    tabPanel.add(obsPanel);
  },
  /*
  Function: setObsData
  Purpose: We can launch this window initially with just the platform meta data and then wait for the Ajax call to return
   the observation data. This function takes the data then relays it to any tabs that a setObsData function defined.
  Parameters:
    obsData - A json object.
  Return:
    none
  */
  setObsData : function(obsData)
  {
    var tabPanel = this.findById('tabPanel');
    if(tabPanel !== null)
    {
      for(var i = 0; i < tabPanel.items.length; i++)
      {
        var tab = tabPanel.items.get(i);
        if(tab.setObsData !== undefined)
        {
          tab.setObsData(obsData);
        }
      }
    }
  }
  
});
/*------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------------------------------------*/
/*
*/
rcoosmapping.featureFilterPanel = Ext.extend(Ext.FormPanel, {
  layers : [],          //An array of vector layers to apply filtering to.
  lookupTable : null,
  initComponent : function()
  {
    this.listeners = {"checkboxgroupchange" : this.checkBoxChange};
    rcoosmapping.featureFilterPanel.superclass.initComponent.call(this);    
  },
  /*
  Function: addFilterGroup
  Purpose: Adds a new FieldSet with a check box group to this FormPanel.
  Parameters:
    items - Array of CheckBox objects to add.
    panelName - Used for the 'id' of the FieldSet and checkBoxGroup.
    title - String to use for the title of the FieldSet.
  */
  addFilterGroup : function(items, panelName, title)
  {
    //var cbGroup = new Ext.form.CheckboxGroup;
    var obsGroupPanel = new Ext.form.FieldSet({
      id: panelName + 'filterSet',
      title: title,
      autoHeight: true,
      autoWidth: true,
      layout: 'fit',
      collapsed: false,   // initially collapse the group
      collapsible: true,
      bubbleEvents: ['checkboxgroupchange'],
      listeners:
      {
        check : function(checkBoxObj, checkedFlag)
        {
          this.fireEvent("checkboxgroupchange", 
                          this.title,
                          checkBoxObj,
                          checkedFlag);
        }
      },     
      items: {
        id: panelName + 'FilterGroup',
        xtype: 'checkboxgroup',
        autoHeight: true,
        autoWidth: true,
        vertical: true,
        columns: 2,
        items: items,
        bubbleEvents: ['check']
      }
    });
    obsGroupPanel.addEvents("checkboxgroupchange");
    this.add(obsGroupPanel);
  },
  /*
  Function: checkBoxChange
  Purpose: The event handler for when the user checks/unchecks one of the check boxes in the panel. We can then 
    implement a Filter on the vector layers to show/hide the features.
  Parameters:
    thisCheckbox - checkboxgroup object that fired the event.
    checked - Array of CheckBoxes that are checked.
  */  
  checkBoxChange : function(groupName, checkBoxObj, checkedFlag)
  {
    //var checked = checked[0].checked;
    //Make sure we have the lookupTable, otherwise we can't continue.
    if(this.lookupTable !== null)
    {
      //User has clicked on a checkbox in the organizations group. Let's take the check box label text and 
      //lookup the ID which we can then use to create a filter.
      var id;
      var propertyName;
      var strategy = this.layers[0].strategies[0];      
      var overallFilter = strategy.filter;
      var compareFilter = null;
      if(groupName == 'Organizations')
      {                
        id = this.lookupTable.getOrganizationID(checkBoxObj.boxLabel);        
        propertyName = "orgName";
        //var filter = strategy.filter;
        compareFilter = overallFilter.filters[0];
      }
      else if(groupName == 'Observations')
      {
        id = this.lookupTable.getObsID(checkBoxObj.boxLabel);
        propertyName = 'staObs.Properties.obsTypeDesc';
        compareFilter = overallFilter.filters[1];
      }
      
      //Add a new filter.
      if(checkedFlag)
      {
        var filter = new OpenLayers.Filter.ComparisonEx({
            type: OpenLayers.Filter.Comparison.EQUAL_TO,
            property: propertyName,
            value: id
        });
        compareFilter.filters.push(filter);
        //if(strategy.filter.filters.length == 0)
        //{    
        //  strategy.filter.type = OpenLayers.Filter.Logical.OR;
        //}        
        //strategy.setFilter(strategy.filter);
      }
      //Remove the filter.
      else
      {
        for(var i = 0; i < compareFilter.filters.length; i++)
        {
          if(compareFilter.filters[i].value == id)
          {
            compareFilter.filters.splice(i, 1);
            break;
          }         
        }      
        /*for(var i = 0; i < strategy.filter.filters.length; i++)
        {
          if(strategy.filter.filters[i].value == id)
          {
            strategy.filter.filters.splice(i, 1);
            if(strategy.filter.filters.length == 0)
            {    
              strategy.filter.type = OpenLayers.Filter.Logical.AND;
            }
            strategy.setFilter(strategy.filter);
            break;
          }         
        }*/
      }
      if(overallFilter.filters[0].filters.length === 0 && overallFilter.filters[1].filters.length === 0)
      {
        overallFilter.type = OpenLayers.Filter.Logical.OR;
      }
      else
      {
        overallFilter.type = OpenLayers.Filter.Logical.AND;
      }

      
      if(overallFilter.filters[0].filters.length === 0)
      {
        overallFilter.filters[0].type = OpenLayers.Filter.Logical.AND;
      }
      else
      {
        overallFilter.filters[0].type = OpenLayers.Filter.Logical.OR;
      }
      if(overallFilter.filters[1].filters.length === 0)
      {
        overallFilter.filters[1].type = OpenLayers.Filter.Logical.AND;         
      }
      else
      {
        overallFilter.filters[1].type = OpenLayers.Filter.Logical.OR;         
      }
      strategy.setFilter(strategy.filter);
    }
  },  
  /*
  Function: addObservationGroup
  Purpose: Creates a new check box group for observations.
  Parameters:
    observationNames - Is an array of strings representing the observation names.
  Return:
    None
  */
  addObservationGroup : function(observationNames)
  {
    var obsList = [];
    for(var i = 0; i < observationNames.length; i++)
    {      
      obsList.push(
      {
        boxLabel: observationNames[i],
        checked: false,
        name: 'obs-cb-' + i,
        bubbleEvents: ['check']
      });      
    }
    this.addFilterGroup(obsList, 'obs', 'Observations');
  },
  /*
  Function: addProvidersGroup
  Purpose: Creates a new check box group for observations.
  Parameters:
    providers - Is an array of strings representing the data providers names.
  Return:
    None
  */
  addProvidersGroup : function(providers)
  {
    var items = [];
    for(var i = 0; i < providers.length; i++)
    {      
      items.push(
      {
        boxLabel: providers[i],
        checked: false,
        name: 'org-cb-' + i,
        bubbleEvents: ['check']
      });      
    }
    this.addFilterGroup(items, 'orgs', 'Organizations');  
  }
 
  
});
/*------------------------------------------------------------------------------------------------------------------------------------*/
rcoosmapping.platformInfoPanel = Ext.extend(Ext.FormPanel, {
  lookupTable : undefined,
  platforms : undefined,
  
  constructor : function(configObj)
  {
    if(configObj.lookupTable != undefined)
    {
      this.lookupTable = configObj.lookupTable;
    }
    if(configObj.platforms != undefined)
    {
      this.platforms = configObj.platforms;
    }
    rcoosmapping.platformInfoPanel.superclass.constructor.call(this, configObj);
    
  },
  createPlatformInfoPanel : function()
  {
    if(this.lookupTable != undefined)
    {      
      var key;
      var types = {};
      var icons = {};
      var cnt = this.platforms.getTotalCount();
      var i;
      for(i=0; i < cnt; i++)
      {
        var platformRec = this.platforms.getAt(i);
        var platTypeId = platformRec.get('staTypeId');
        var platTypeName = this.lookupTable.getPlatformTypeName(platTypeId);
        var items = [];
        if(platTypeName in types)
        {
          items = types[platTypeName];
        }
        else
        {
          types[platTypeName] = items;          
          icons[platTypeName] = this.lookupTable.getDisplayIconURL(platformRec.get('staTypeImage'));
        }
        var platform = platformRec.get('staID').split(".");
        items.push({
          fieldLabel: platform[0] + " " + platform[1],
          text: platform[0] + " " + platform[1]
        });      
      }
      for(key in types)
      {
        var items = types[key];
        var icon = icons[key];
        var title = '<img width="18" height="18" border="0" src="' + icon + '"></img>' + ' ' + key;
        this.addGroup(items, key, title);
      }
    }
  },
  /*
  Function: addFilterGroup
  Purpose: Adds a new FieldSet with a check box group to this FormPanel.
  Parameters:
    items - Array of CheckBox objects to add.
    panelName - Used for the 'id' of the FieldSet and checkBoxGroup.
    title - String to use for the title of the FieldSet.
  */
  addGroup : function(items, panelName, title)
  {
    var fieldSet = new Ext.form.FieldSet({
      id: panelName + 'PlatformSet',
      title: title,
      autoHeight: true,
      autoWidth: true,
      layout: 'fit',
      collapsed: false,   // initially collapse the group
      collapsible: true,
      items: {
        id: panelName + 'PlatformGroup',
        xtype: 'button',
        autoHeight: true,
        autoWidth: true,
        vertical: true,
        columns: 1,
        items: items
      }
    });
    this.add(fieldSet);
  }

});
/*------------------------------------------------------------------------------------------------------------------------------------*/

/*
rcoosmapping.data.PlatformRecord = GeoExt.data.FeatureRecord.create(fieldsArray)
{
}
*/
/*
  Object: rcoosmapping.platformObj
  Purpose: This class ecapsulates platform metadata with the layer to display on the map. Platforms are represented as Feature.Vector
  objects that are attached to a Layer.Vector display object.
*/
rcoosmapping.platformVectorLayer  = Ext.extend(OpenLayers.Layer.Vector,
{
  featureStore : null,
  lookupTable : null,     //The rcoosmapping.lookupTable Json object.
  selectControl : null,   //The Control.SelectFeature OpenLayers object that handles the user clicks.
  hoverControl : null,    //This control is used to detect when a user hovers over a platform. we change the cursor and do a tooltip.
  hoverTimeout : undefined,
  nfoPopup : null,        //The popup window that is created when a user clicks a platform.
  mapObj : null,          //The OpenLayers Map object the layer is attached to.
  googAnalytics : null,   //If provided, this is the object that interfaces to google anayltics. 
  featuresUrl : null,
  layerActive : null,
  parentPanel : null,
  //constructor: function(config) 
  constructor: function(name, configParams) 
  {    
    if(configParams.lookups !== undefined)
    {
      this.lookupTable = configParams.lookups;
    }
    this.mapObj = configParams.map;
    this.googAnalytics = configParams.googAnalytics;
    if(configParams.layerOptions.featuresUrl !== undefined)
    {
      this.featuresUrl = configParams.layerOptions.featuresUrl;
    }
    this.layerActive = configParams.layerOptions.active;
    this.parentPanel = configParams.parentPanel;
    
    //Create any filter strategies we might want for the layer.
    //configParams.layerOptions.options.strategies = this.createFilters();
    
    rcoosmapping.platformVectorLayer.superclass.constructor.call(this, name, configParams.layerOptions.options);
        
    if(configParams.platforms !== undefined)
    {
      //Create the feature store for the vector features.
      this.createFeatureStore(configParams.platforms);
      
      this.createSelectFeature(this.mapObj, this.layerActive);
    }
    if(this.mapObj !== undefined)
    {
      this.mapObj.addLayer(this);
    }    
  },
  createFilters : function()
  {
    //Create an empty filter strategy. We create the filters depending on the users choices in the filter
    //panel.
    var obsFilter = new OpenLayers.Filter.Logical({
      type: OpenLayers.Filter.Logical.OR,
      filters: []
    });     
    var orgsFilter = new OpenLayers.Filter.Logical({
      type: OpenLayers.Filter.Logical.OR,
      filters: []
    });     
    var overallFilter = new OpenLayers.Filter.Logical({
      type: OpenLayers.Filter.Logical.AND,
      filters: [obsFilter,orgsFilter]
    });     
    var filterStrategy = new OpenLayers.Strategy.Filter({filter: overallFilter});
    filterStrategy.setLayer(this);
    return([filterStrategy]);
  },  
  createFilterPanel : function()
  {
    var id = "westPanel-" + this.parentPanel.title;
    var westPanel = this.parentPanel.findById(id);
    if(westPanel !== null)
    {
      var filterPanel = new rcoosmapping.featureFilterPanel({
        id: 'filterPanel',
        title: 'Filters',
        border: false,
        header: true,
        draggable: false,
        autoScroll: true,
        overflow: 'auto',
        lookupTable: this.lookupTable,
        layers: [this]
      });
      //Add the observations.
      var items = [];
      //Add the organizations
      for(var org in this.lookupTable.organization)
      {
        items.push(this.lookupTable.organization[org].short_name);
      }
      filterPanel.addProvidersGroup(items);
      items = [];
      for(var obs in this.lookupTable.obsType)
      {
        items.push(this.lookupTable.obsType[obs].display);
      }
      filterPanel.addObservationGroup(items);
      //DWR 5/4/2011
      //Put the filter panel above the layer tree to make it more visible to the user.
      //westPanel.add(filterPanel);
      westPanel.insert(0, filterPanel);
      //westPanel.doLayout();
      
      var platformPanel = new rcoosmapping.platformInfoPanel({
        id: 'platformPanel',
        title: 'Platforms',
        border: false,
        header: true,
        draggable: false,
        autoScroll: true,
        overflow: 'auto',
        lookupTable: this.lookupTable,
        platforms: this.featureStore
      });
      platformPanel.createPlatformInfoPanel();
      westPanel.add(platformPanel);
      westPanel.doLayout();
    }
  },  
  getFeaturesData : function(jsonUrl)
  {
    //Use the url passed in with the configuration parameters as the default.
    url = this.featuresUrl;
    //The caller can use a different url if passed in.
    if(jsonUrl !== undefined)
    {
      url = jsonUrl;
    }
    Ext.Ajax.request({
      autoAbort: true,
      url: url,
      scope: this,
      scriptTag: true,
      callbackName: "json_callback",
      success: this.queryFeaturesSuccess,
      failure: function(response, options)
      {
        alert("Failed to retrieve the platform data, cannot display platforms.");
        return;
      }
     });
  
  },
  queryFeaturesSuccess : function(response, options)
  {
    var jsonObject = Ext.util.JSON.decode(response.responseText);
    if(jsonObject.lookups !== undefined)
    {
      var lookups = { 'lookups' : jsonObject['lookups'] };
      this.lookupTable = new rcoosmapping.lookupTable(
                              {
                                root: 'lookups',
                                data : lookups
                              });
      if(jsonObject.layers !== undefined)
      {
        var layerType;
        for(layerType in jsonObject['layers'])
        {
          if(layerType == 'vector')
          {
            var layerName;
            for(layerName in jsonObject.layers[layerType])
            {
              if(layerName == 'insitu')
              {
                //Get the geoJson object describing the features/platforms.
                var features = jsonObject.layers[layerType][layerName].features;
                this.createFeatureStore(features);
                this.createSelectFeature(this.mapObj, this.layerActive);
                var strategy = this.createFilters();                
                this.strategies = strategy;
                this.createFilterPanel();
              }
            }
          }
        }
      }    
    }
  },  
  createFeatureStore : function(platforms)
  {
    var features = this.createFeatures(platforms);
    this.featureStore = new GeoExt.data.FeatureStore({
        autoLoad : true,
        reader: new GeoExt.data.FeatureReader({}, [
            {name: 'orgName', type: 'integer'},
            {name: 'staDataFile', type: 'string'},
            {name: 'staID', type: 'string'},
            {name: 'staDesc', type: 'string'},
            {name: 'staTypeImage', type: 'integer'},
            {name: 'staTypeId', type: 'integer'},
            {name: 'staURL', type: 'string'},
            {name: 'lat', type: 'string'},
            {name: 'lon', type: 'string'},
            {name: 'status', defaultValue: null},
            {name: 'links'},
            {name: 'staObs'},
            {name: 'lookupTable'},
            {name: 'obsDataObj'}
            
        ]),
        data : features,
        layer: this,
        initDir: GeoExt.data.FeatureStore.STORE_TO_LAYER
    });    
  },
  /*
    Function: createFeatures
    Purpose: Given the GeoJSON metadata object, creates the a Feature.Vector object for each platform.
    Parameters:
      platforms - GeoJSON Object describing the platform.
    Return:
      An array of the individual vector objects.
  */
  createFeatures : function(platforms)
  {    
    var features = [];
    for(i = 0; i < platforms.length; i++)
    {      
      var platformObj = platforms[i];
      //Reproject the latlon.
      var projection = this.mapObj.projection.projCode;
      var displayProjection = projection;
      //if(this.mapObj.displayProjection !== undefined and this.mapObj.displayProjection.length)
      if(this.mapObj.displayProjection !== undefined)
      {
        displayProjection = this.mapObj.displayProjection.projCode;
      }
      var reprojectedPt = rcoosmapping.utils.reprojectPoint( this.mapObj.displayProjection, projection, 
                                                  platformObj.geometry.coordinates[0], 
                                                  platformObj.geometry.coordinates[1]);
      platformObj.properties.lookupTable = this.lookupTable;
      //Create the placeholder for the observation data object.
      platformObj.properties.obsDataObj = null;
      //Add the lat/lon coords into the attributes since we have to convert the geometry coords into the 900913 for display.
      platformObj.properties.lon = platformObj.geometry.coordinates[0];
      platformObj.properties.lat = platformObj.geometry.coordinates[1];
      //Change the geometry coords into the reprojected points to draw on the map.
      platformObj.geometry.coordinates[0] = reprojectedPt.lon;
      platformObj.geometry.coordinates[1] = reprojectedPt.lat;
       
      var geojson_format = new OpenLayers.Format.GeoJSON();          
      var feature = geojson_format.read(platformObj);
      
      if(feature.length)
      {
        var iconUrl = this.lookupTable.getDisplayIconURL(platformObj.properties.staTypeImage);  
        if(iconUrl !== undefined)
        {        
          feature[0].style = {
              externalGraphic: iconUrl,
              graphicWidth: 18,
              graphicHeight: 18,
              graphicZIndex: 1
            };
        }
        //this.features[i] = feature[0];
        features[i] = feature[0];
      }
    }
    return(features);
  },
  /*
    Function: createSelectFeature
    Purpose: Creates the OpenLayers Layer.Vector object to be displayed on the map.
    Parameters:
      map - the initialized OpenLayers.Map object the layer and controls will be added to.
      layer - The OpenLayers layer object the control will be attached to.
      active - Boolean specifing if the control should be active. NOTE: Only one SelectFeature control can be active
        at a time on a map. If more than one is active, the top most layer receives the notification.
    Return:
      Returns the SelectFeature control created.
  */
  //createSelectFeature : function(map, layer, active)
  createSelectFeature : function(map, active)
  {
    //Add the events for popups we are interested in.
    this.selectControl = new OpenLayers.Control.SelectFeature(this,
      {
        id: 'insituclick',
        onSelect: this.onFeatureSelect, 
        //onUnselect: this.onFeatureUnselect,
        parentObj: this,
        scope: this,
        toggle: true
      });    
    
    this.hoverControl = new OpenLayers.Control.SelectFeature(this,
      {
        id: 'insituhover',
        hover: true,
        highlightOnly: true,
        renderIntent: "temporary",
        scope: this,
        eventListeners: {
          beforefeaturehighlighted: function(event) { 
          },          
          featurehighlighted: function(event){
            //Change the cursor to one that points at the feature.
            var feature = event.feature;
            feature.style.cursor="pointer";
            if(this.toolTip !== undefined)
            {
              this.toolTip.destroy();
              this.toolTip = undefined;
            }
            //Get the station ID from the feature. We use this as our tooltip text.
            var staId = feature.attributes.staID;
            //This block of code gets the Lat/Lon of the feature, then converts that into viewport coordinates.
            //Finally, the mapBox gives us the offset of our mappanel so we can adjust our tooltip location. If we didn't do this
            //the tooltip would show up at the left hand side of the viewport. 
            var centerLonLat = feature.geometry.getBounds().getCenterLonLat();
            var centerPx = this.mapObj.getViewPortPxFromLonLat(centerLonLat);
            var mapBox = Ext.fly(this.mapObj.div).getBox(); 
            
            this.toolTip = new Ext.ToolTip({
              id: "ToolTip",
              html: staId,
              width: 'auto',
            	autoWidth: true,
              hideDelay: 5000
            });
            //Show our tooltip. The + 10 and - 15 on the x and y locations are used to give a slight offset for the tool tip so it is not
            //directly under the cursor.
            this.toolTip.showAt([centerPx.x + mapBox.x + 10, centerPx.y + mapBox.y - 15]);
            if(this.hoverTimeout !== undefined)
            {
              clearTimeout(this.hoverTimeout);
              this.hoverTimeout = undefined;
            }
            /*This is a hover timer. We don't make the json call if the user is just casually moving the mouse around.
            The cursor has to stop over the feature for the Timeout value before we make the call.*/
            this.hoverTimeout = setTimeout(
            function(scope, event)
            {            
              var dataUrl = scope.lookupTable.getDataURL(feature.attributes.staDataURL);
              var url = dataUrl + feature.attributes.staDataFile;
              Ext.Ajax.request({
                autoAbort: true,
                url: url,
                scope: this,
                scriptTag: true,
                callbackName: "json_callback",
                //We use the extraParams to pass along the vector feature the user clicked on into the AJAX callback.      
                extraParams:  
                {
                  feature: scope.featureStore.getRecordFromFeature(feature)
                },
                success: function(response, options)
                {
                  if(scope.toolTip !== null)
                  {
                    var jsonObject = null;
                    var obsObj = null;
                    if(response.responseText)
                    {
                      //Put an exception handler around the Ext.util.JSON.decode() call to handle the case of the ajax call returning, but without the JSON data,
                      //for example the server is returning a 404 response.
                      try
                      {
                        //Decode the observations JSON file.
                        jsonObject = Ext.util.JSON.decode(response.responseText);
                        //The GeoJSON object we get back from the server has parts we are not interested in. So we created an object
                        //with a field of "features" that points to the data we want to process. We add in the platform metadata as well
                        //that we then use to show on the popup window.
                        //var obsStore = new rcoosmapping.observationsObj({data: {features : jsonObject.properties.features}, lookupTable : scope.lookupTable});
                        var obsStore = new rcoosmapping.observationsObj({data: {features : jsonObject.features}, lookupTable : scope.lookupTable});
                        var updateTime = null;
                        var platformObs = options.extraParams.feature.get('staObs');
                        var staID = options.extraParams.feature.get('staID');
                        
                        var html = "<table><tbody><tr><td>" + staID + "</td></tr>";
                        var time;
                        var timeHtml = "";
                        var bodyHtml = "";
                        if(platformObs.length)
                        {
                          for(var i = 0; i < platformObs.length; i++)
                          {
                            var obsNfo = platformObs[i];
                            //Based on the obsservation ID, get it's string.
                            var obsName = scope.lookupTable.getObsName(obsNfo.Properties.obsTypeDesc);
                            //Get the display name for the observation. This is the string used to present the information to the user.
                            var obsDisplayName = scope.lookupTable.getObsDisplayName(obsNfo.Properties.obsTypeDesc);
                            if(obsDisplayName === undefined || (obsDisplayName.length === 0))
                            {
                              obsDisplayName = obsName;
                            }
                            var dbUomName = scope.lookupTable.getNativeUOMName(obsNfo.Properties.uomID, true);
                            var sorder = obsNfo.Properties.sorder;
                            var key = obsName + ":" + sorder + ":" + dbUomName;                          
                            //Look up the data value for the obsName.
                            //var value = Number(obsStore.getLatestValue(obsName, true));
                            var value = obsStore.getLatestValue(key, true);
                            if(value !== undefined)
                            {
                              value = value.toFixed(2);
                            }
                            else
                            {
                              value = "";
                            }
                            var qcLevel = obsStore.getLatestQCLevel(key);
                            //Get the imperial units to convert to.
                            var uomName = scope.lookupTable.getUOMName(obsNfo.Properties.uomID, true);
                            
                            //We get the latest time from the first observation. All the obs are time normalized.
                            if(time == undefined)
                            {
                              time = obsStore.getLatestTime(key);  
                              if(time !== undefined)
                              {
                                var update = time.replace(' ', 'T');
                                update = Date.parseDate(update, "c");          
                                update = update.format("Y-m-d H:i:s");                          
                                //html += "<tr><td>Data Time</td><td>" + updateTime + "</td><tr>";
                                timeHtml = "<tr><td>Data Time</td><td>" + update + "</td><tr>";
                              }
                            }
                            bodyHtml += "<tr><td>" + obsDisplayName + "</td><td>" + value + "</td><td>" + uomName + "</td></tr>";
                          }
                        }
                        html += timeHtml;
                        html += bodyHtml;
                        html += "</tbody></table>";
                        scope.toolTip.body.update(html);
                        scope.toolTip.syncSize();
                      }
                      catch(syntaxError)
                      {
                      }
                      
                      if(scope.googAnalytics !== undefined)
                      {
                        scope.googAnalytics.trackEvent("Interactive Map Platforms", "Hover", staID);
                      }                  
                    }
                  }
                }
              });            
            }, 
            500, this, event);


            
            /*var dataUrl = this.lookupTable.getDataURL(feature.attributes.staDataURL);
            //var url = OpenLayers.ProxyHost + dataUrl + feature.attributes.staDataFile;
            var url = dataUrl + feature.attributes.staDataFile;
            Ext.Ajax.request({
              autoAbort: true,
              url: url,
              scope: this,
              scriptTag: true,
              callbackName: "json_callback",
              //We use the extraParams to pass along the vector feature the user clicked on into the AJAX callback.      
              extraParams:  
              {
                feature: this.featureStore.getRecordFromFeature(feature)
              },
              success: function(response, options)
              {
                if(this.toolTip !== null)
                {
                  var jsonObject = null;
                  var obsObj = null;
                  if(response.responseText)
                  {
                    //Put an exception handler around the Ext.util.JSON.decode() call to handle the case of the ajax call returning, but without the JSON data,
                    //for example the server is returning a 404 response.
                    try
                    {
                      //Decode the observations JSON file.
                      jsonObject = Ext.util.JSON.decode(response.responseText);
                      //The GeoJSON object we get back from the server has parts we are not interested in. So we created an object
                      //with a field of "features" that points to the data we want to process. We add in the platform metadata as well
                      //that we then use to show on the popup window.
                      //var obsStore = new rcoosmapping.observationsObj({data: {features : jsonObject.properties.features}, lookupTable : this.lookupTable});
                      var obsStore = new rcoosmapping.observationsObj({data: {features : jsonObject.features}, lookupTable : this.lookupTable});
                      var updateTime = null;
                      var platformObs = options.extraParams.feature.get('staObs');
                      var staID = options.extraParams.feature.get('staID');
                      
                      var html = "<table><tbody><tr><td>" + staID + "</td></tr>";
                      var time;
                      var timeHtml = "";
                      var bodyHtml = "";
                      if(platformObs.length)
                      {
                        for(var i = 0; i < platformObs.length; i++)
                        {
                          var obsNfo = platformObs[i];
                          //Based on the obsservation ID, get it's string.
                          var obsName = this.lookupTable.getObsName(obsNfo.Properties.obsTypeDesc);
                          //Get the display name for the observation. This is the string used to present the information to the user.
                          var obsDisplayName = this.lookupTable.getObsDisplayName(obsNfo.Properties.obsTypeDesc);
                          if(obsDisplayName === undefined || (obsDisplayName.length === 0))
                          {
                            obsDisplayName = obsName;
                          }
                          var dbUomName = this.lookupTable.getNativeUOMName(obsNfo.Properties.uomID, true);
                          var sorder = obsNfo.Properties.sorder;
                          var key = obsName + ":" + sorder + ":" + dbUomName;                          
                          //Look up the data value for the obsName.
                          //var value = Number(obsStore.getLatestValue(obsName, true));
                          var value = obsStore.getLatestValue(key, true);
                          if(value !== undefined)
                          {
                            value = value.toFixed(2);
                          }
                          else
                          {
                            value = "";
                          }
                          var qcLevel = obsStore.getLatestQCLevel(key);
                          //Get the imperial units to convert to.
                          var uomName = this.lookupTable.getUOMName(obsNfo.Properties.uomID, true);
                          
                          //We get the latest time from the first observation. All the obs are time normalized.
                          if(time == undefined)
                          {
                            time = obsStore.getLatestTime(key);  
                            if(time !== undefined)
                            {
                              var update = time.replace(' ', 'T');
                              update = Date.parseDate(update, "c");          
                              update = update.format("Y-m-d H:i:s");                          
                              //html += "<tr><td>Data Time</td><td>" + updateTime + "</td><tr>";
                              timeHtml = "<tr><td>Data Time</td><td>" + update + "</td><tr>";
                            }
                          }
                          bodyHtml += "<tr><td>" + obsDisplayName + "</td><td>" + value + "</td><td>" + uomName + "</td></tr>";
                        }
                      }
                      html += timeHtml;
                      html += bodyHtml;
                      html += "</tbody></table>";
                      this.toolTip.body.update(html);
                      this.toolTip.syncSize();
                    }
                    catch(syntaxError)
                    {
                    }
                    
                    if(this.googAnalytics !== undefined)
                    {
                      this.googAnalytics.trackEvent("Interactive Map Platforms", "Hover", staID);
                    }                  
                  }
                }
              }
            });*/            
          },
          featureunhighlighted: function(event){
            if(this.hoverTimeout !== undefined)
            {
              clearTimeout(this.hoverTimeout);
              this.hoverTimeout = undefined;
            }
            //If there is a tooltip, we destroy it.
            if(this.toolTip !== undefined)
            {
              //this.toolTip.close();
              this.toolTip.destroy();
              this.toolTip = undefined;
            }
            //Change the cursor back to the normal one.
            var feature = event.feature;
            delete feature.style.cursor;
          },
          scope : this
        }        
      });    
    //We set the stopClick and stopDown to false so the hover control doesn't eat the click event. If we didn't do this, we'd lose the ability
    //to click on a feature and have our popup work.
    this.hoverControl.handlers["feature"].stopClick = false;
    this.hoverControl.handlers["feature"].stopDown = false;
    map.addControl(this.hoverControl);
    map.addControl(this.selectControl);
    if(active)
    {
      this.hoverControl.activate();
      this.selectControl.activate();
    }    
  },  
  
  /*
    Function: onFeatureSelect
    Purpose: The callback used when a feature in the active vector layer is clicked
    Parameters:
      feature - Is the Features.Vector object of the clicked item.
    Return:
  */
  onFeatureSelect : function(feature)
  {
    //this.parentObj.clearPopup();
    this.clearPopup();
    //var platformFeature = this.parentObj.featureStore.getRecordFromFeature(feature);
    var platformFeature = this.featureStore.getRecordFromFeature(feature);
    if(platformFeature !== undefined)
    {
      //Create our observation popup window.
      //this.parentObj.nfoPopup = new rcoosmapping.popup(
      this.nfoPopup = new rcoosmapping.popup(
      {
        id: 'FeaturePopup',
        //map: this.parentObj.mapObj,
        map: this.mapObj,
        title: "Feature Information",
        autoScroll: true,
        location: feature.geometry.getBounds().getCenterLonLat(),
        panIn: true,
        width: 500,
        height: 350,
        collapsible: true,
        anchored: true,
        feature: platformFeature,
        selectControl: this.selectControl,
        googAnalytics : this.googAnalytics
      });      
      //this.parentObj.nfoPopup.show();      
      this.nfoPopup.show(); 
      //We need to now go fetch the latest observation geoJson file for the platform the user clicked.
      //var dataUrl = this.parentObj.lookupTable.getDataURL(feature.attributes.staDataURL);
      var dataUrl = this.lookupTable.getDataURL(feature.attributes.staDataURL);
      //var url = OpenLayers.ProxyHost + dataUrl + feature.attributes.staDataFile;
      var url = dataUrl + feature.attributes.staDataFile;
      Ext.Ajax.request({
        autoAbort: true,
        url: url,
        scriptTag: true,
        callbackName: "json_callback",        
        scope: this,
        //We use the extraParams to pass along the vector feature the user clicked on into the AJAX callback.      
        extraParams:  
        {
          feature: platformFeature
        },
        success: function(response, options)
        {
          var jsonObject;
          var obsObj;
          var obsData;
          if(response.responseText)
          {
            //Put an exception handler around the Ext.util.JSON.decode() call to handle the case of the ajax call returning, but without the JSON data,
            //for example the server is returning a 404 response.
            try
            {
              //Decode the observations JSON file.
              jsonObject = Ext.util.JSON.decode(response.responseText);
              //The GeoJSON object we get back from the server has parts we are not interested in. So we created an object
              //with a field of "features" that points to the data we want to process. We add in the platform metadata as well
              //that we then use to show on the popup window.
              //var obsData = {features : jsonObject.properties.features};
              obsData = {features : jsonObject.features};
            }
            catch(syntaxError)
            {
              //Check the response text to see if we got a response that the json file we were looking for was not there.
              jsonObject = undefined;
              obsObj = undefined;              
            }
            //if(this.parentObj.nfoPopup !== null)
            if(this.nfoPopup !== null)
            {
              try
              {
                //this.parentObj.nfoPopup.setObsData(obsData);
                this.nfoPopup.setObsData(obsData);
              }
              catch(error)
              {
                if (console!==undefined)
                {
                  console.exception(error);
                }
              }
            }            
          }
        },
        failure: function(response, options)
        {
          try
          {
            //this.parentObj.nfoPopup.setObsData(null);
            this.nfoPopup.setObsData(undefined);
          }
          catch(error)
          {
            if (console!==undefined)
            {
              console.exception(error);
            }
          }
        }
      });
      if(this.googAnalytics !== undefined)
      {
        this.googAnalytics.trackEvent("Interactive Map Platforms", "Click", platformFeature.get('staID'));
      }      
    }
  },  
  /*
    Function: onFeatureUnselect
    Purpose: The callback used when a feature in the active vector layer is no longer selected.
    Parameters:
      feature - Is the Features.Vector object of the clicked item.
    Return:
  */
  onFeatureUnselect : function(feature)
  {
    var i = 0;
  },
  clearPopup : function() 
  {
    if(this.toolTip !== undefined)
    {
      this.toolTip.destroy();
      this.toolTip = undefined;
    }
    if(this.nfoPopup !== null) 
    {
      this.nfoPopup.close();
      this.nfoPopup = null;
    }
  },
  enableToolTips : function(flag)
  {
    if(flag)
    {
      if(this.hoverControl !== undefined)
      {
        this.hoverControl.activate();
        this.selectControl.activate();
        
      }
    }
    else
    {
      if(this.hoverControl !== undefined)
      {
        this.hoverControl.deactivate();
        this.selectControl.deactivate();
      }
    }
  }
  
  /*setFeatureTypeVisibility : function(type, visible)
  {
    for(var i = 0; i < this.features.length; i++)
    {
      var platformNfo = this.features[i].attributes;
      if(platformNfo.staTypeName == type)
      {
        if(visible)
        {
          var iconUrl = this.data.getDisplayIconURL(platformNfo.staTypeImage);  
          if(iconUrl !== undefined)
          {        
            platformNfo.style = 
            {
              externalGraphic: iconUrl,
              graphicWidth: 18,
              graphicHeight: 18
            };
          }
        }
        else
        {
          platformNfo.style = 
          { 
            display : "none"
          };
        }
      }
    }
  }*/
  
});
/*------------------------------------------------------------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------------------------------------------------------------*/

  /**
  Class: OpenLayers.Layer.WMSEx
  Extends the WMS base class to handle some new options.
  */
  OpenLayers.Layer.WMSEx = OpenLayers.Class(OpenLayers.Layer.WMS, {
    /**
     * Property: alwaysRefresh
     * {Boolean} If true, this forces the layer to request the tiles again.
      Uses mergeNewParams() to add a random number to the URL.
     */
    alwaysRefresh: false,
    randomNum: 0.0,
    
    
    /**
     * Constructor: OpenLayers.Layer.WMS
     * Create a new WMS layer object
     *
     * Example:
     * (code)
     * var wms = new OpenLayers.Layer.WMS("NASA Global Mosaic",
     *                                    "http://wms.jpl.nasa.gov/wms.cgi", 
     *                                    {layers: "modis,global_mosaic"});
     * (end)
     *
     * Parameters:
     * name - {String} A name for the layer
     * url - {String} Base url for the WMS
     *                (e.g. http://wms.jpl.nasa.gov/wms.cgi)
     * params - {Object} An object with key/value pairs representing the
     *                   GetMap query string parameters and parameter values.
     * options - {Ojbect} Hashtable of extra options to tag onto the layer
     */
    initialize: function(name, url, params, options) {
      this.alwaysRefresh = options.alwaysRefresh;
      this.eventListeners = {
        loadstart : this.loadStart
      };
      OpenLayers.Layer.WMS.prototype.initialize.apply(this,arguments);
    },
    /**
     * Method: loadStart
     * Event handler for the loadstart event which is fired whenever the layer begins to load.
     * We overload this function to test if we want to make sure we get the layer from the WMS server
     * and not the local cache. If we are pulling it down from the WMS server, we add a random number to the
     * Post parameters.
     *
     * Parameters:
     *  layerObject - {Object} A reference to layer.events.object.
     *  element - {DOMElement} A reference to layer.events.element.
     * Returns:
     */
    loadStart : function(layerObject, element)
    {
      if(this.alwaysRefresh)
      {
        this.mergeNewParams({'random' : Math.random()});      
      }
    }
    /**
     * Method: getURL
     * Inherits the base class function to add a call to mergeNewParams() if the 
     * alwaysRefresh flag is true.
     * Return a GetMap query string for this layer
     *
     * Parameters:
     * bounds - {<OpenLayers.Bounds>} A bounds representing the bbox for the
     *                                request.
     *
     * Returns:
     * {String} A string with the layer's url and parameters and also the
     *          passed-in bounds and appropriate tile size specified as 
     *          parameters.
     */
    /*getURL: function (bounds) {
        if(this.alwaysRefresh)
        {
          //this.mergeNewParams({'random' : this.randomNum});
          this.params['RANDOM'] = this.randomNum;
        }
        return OpenLayers.Layer.WMS.prototype.getURL.apply(this,arguments);
    }*/
    
  
  });
/*------------------------------------------------------------------------------------------------------------------------------------*/
/*
  Class: rcoosmapping.earthNCCharts
  Purpose: Overrides the OpenLayers.Layer.XYZ so we use the correct getURL to retrieve the Earth NC layer.
*/
rcoosmapping.earthNCCharts =  OpenLayers.Class(OpenLayers.Layer.XYZ, {
  constructor: function(name, url, options) 
  {
    rcoosmapping.earthNCCharts.superclass.constructor.call(this, name, configParams.layerOptions.options);
  },
  getURL : function(bounds) 
  {
    var res = this.map.getResolution();
    var z = this.map.getZoom() + this.map.baseLayer.minZoomLevel;
    var x = Math.round ((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));     
    var y = Math.round ((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
    var ymax = 1 << z;
    y = ymax - y - 1;
    

    var url = this.url;
    var s = '' + x + y + z;
    if (url instanceof Array)
    {
        url = this.selectUrl(s, url);
    }
    
    var path = OpenLayers.String.format(url, {'x': x, 'y': y, 'z': z});
    return(path);
  }

});

/*------------------------------------------------------------------------------------------------------------------------------------*/

/*Inherits from: 
 *  - <OpenLayers.Layer.XYZ>             
 */    
OpenLayers.Layer.ArcGISCache = OpenLayers.Class(OpenLayers.Layer.XYZ, {  

    /**
     * APIProperty: url
     * {String | Array} The base URL for the layer cache.  You can also
     *     provide a list of URL strings for the layer if your cache is
     *     available from multiple origins.  This must be set before the layer
     *     is drawn.
     */
    url: null,
    
   /**
    * APIProperty: tileOrigin
    * {<OpenLayers.LonLat>} The location of the tile origin for the cache.
    *     An ArcGIS cache has it's origin at the upper-left (lowest x value
    *     and highest y value of the coordinate system).  The units for the
    *     tile origin should be the same as the units for the cached data.
    */
    tileOrigin: null, 
   
   /**
    * APIProperty: tileSize
    * {<OpenLayers.Size>} This size of each tile. Defaults to 256 by 256 pixels.
    */
    tileSize: new OpenLayers.Size(256, 256),
    
   /**
    * APIProperty: useAGS
    * {Boolean} Indicates if we are going to be accessing the ArcGIS Server (AGS)
    *     cache via an AGS MapServer or directly through HTTP. When accessing via
    *     AGS the path structure uses a standard z/y/x structure. But AGS actually
    *     stores the tile images on disk using a hex based folder structure that looks
    *     like "http://example.com/mylayer/L00/R00000000/C00000000.png".  Learn more
    *     about this here:
    *     http://blogs.esri.com/Support/blogs/mappingcenter/archive/2010/08/20/Checking-Your-Local-Cache-Folders.aspx
    *     Defaults to true;
    */    
    useArcGISServer: true,

   /**
    * APIProperty: type
    * {String} Image type for the layer.  This becomes the filename extension
    *     in tile requests.  Default is "png" (generating a url like
    *     "http://example.com/mylayer/L00/R00000000/C00000000.png").
    */
    type: 'png',
    
    /**
    * APIProperty: useScales
    * {Boolean} Optional override to indicate that the layer should use 'scale' information
    *     returned from the server capabilities object instead of 'resolution' information.
    *     This can be important if your tile server uses an unusual DPI for the tiles.
    */
    useScales: false,
    
   /**
    * APIProperty: overrideDPI
    * {Boolean} Optional override to change the OpenLayers.DOTS_PER_INCH setting based 
    *     on the tile information in the server capabilities object.  This can be useful 
    *     if your server has a non-standard DPI setting on its tiles, and you're only using 
    *     tiles with that DPI.  This value is used while OpenLayers is calculating resolution
    *     using scales, and is not necessary if you have resolution information. (This is
    *     typically the case)  Regardless, this setting can be useful, but is dangerous
    *     because it will impact other layers while calculating resolution.  Only use this
    *     if you know what you are doing.  (See OpenLayers.Util.getResolutionFromScale)
    */
    overrideDPI: false,
    
   /**
    * Constructor: OpenLayers.Layer.ArcGISCache 
    * Creates a new instance of this class 
    * 
    * Parameters: 
    * name - {String} 
    * url - {String} 
    * options - {Object} extra layer options
    */ 
    initialize: function(name, url, options) { 
        OpenLayers.Layer.XYZ.prototype.initialize.apply(this, arguments);

        if (this.resolutions) {        
            this.serverResolutions = this.resolutions;
            this.maxExtent = this.getMaxExtentForResolution(this.resolutions[0]);
        }

        // this block steps through translating the values from the server layer JSON 
        // capabilities object into values that we can use.  This is also a helpful
        // reference when configuring this layer directly.
        if (this.layerInfo) {
            // alias the object
            var info = this.layerInfo;
            
            // build our extents
            var startingTileExtent = new OpenLayers.Bounds(
                info.fullExtent.xmin, 
                info.fullExtent.ymin, 
                info.fullExtent.xmax, 
                info.fullExtent.ymax  
            );

            // set our projection based on the given spatial reference.
            // esri uses slightly different IDs, so this may not be comprehensive
            this.projection = 'EPSG:' + info.spatialReference.wkid;
            this.sphericalMercator = (info.spatialReference.wkid == 102100);
            
            // convert esri units into openlayers units (basic feet or meters only)
            this.units = (info.units == "esriFeet") ? 'ft' : 'm';

            // optional extended section based on whether or not the server returned
            // specific tile information
            if (!!info.tileInfo) {            
                // either set the tiles based on rows/columns, or specific width/height
                this.tileSize = new OpenLayers.Size(
                    info.tileInfo.width || info.tileInfo.cols, 
                    info.tileInfo.height || info.tileInfo.rows
                );
                
                // this must be set when manually configuring this layer
                this.tileOrigin = new OpenLayers.LonLat(
                    info.tileInfo.origin.x, 
                    info.tileInfo.origin.y
                );

                var upperLeft = new OpenLayers.Geometry.Point(
                    startingTileExtent.left, 
                    startingTileExtent.top
                );
                
                var bottomRight = new OpenLayers.Geometry.Point(
                    startingTileExtent.right, 
                    startingTileExtent.bottom
                );            
                
                if (this.useScales) {
                    this.scales = [];
                } else {
                    this.resolutions = [];
                }
                
                this.lods = [];
                for(var key in info.tileInfo.lods) {
                    var lod = info.tileInfo.lods[key];
                    if (this.useScales) {
                        this.scales.push(lod.scale);
                    } else {
                        this.resolutions.push(lod.resolution);
                    }
                    
                    var start = this.getContainingTileCoords(upperLeft, lod.resolution);
                    lod.startTileCol = start.x;
                    lod.startTileRow = start.y;
                    
                    var end = this.getContainingTileCoords(bottomRight, lod.resolution);
                    lod.endTileCol = end.x;
                    lod.endTileRow = end.y;    
                    this.lods.push(lod);
                }

                this.maxExtent = this.calculateMaxExtentWithLOD(this.lods[0]);
                this.serverResolutions = this.resolutions;
                if (this.overrideDPI && info.tileInfo.dpi) {
                    // see comment above for 'overrideDPI'
                    OpenLayers.DOTS_PER_INCH = info.tileInfo.dpi;
                }
            } 
       }
    }, 

   /** 
    * Method: getContainingTileCoords
    * Calculates the x/y pixel corresponding to the position of the tile
    *     that contains the given point and for the for the given resolution.
    * 
    * Parameters:
    * point - {<OpenLayers.Geometry.Point>} 
    * res - {Float} The resolution for which to compute the extent.
    * 
    * Returns: 
    * {<OpenLayers.Pixel>} The x/y pixel corresponding to the position 
    * of the upper left tile for the given resolution.
    */
    getContainingTileCoords: function(point, res) {
        return new OpenLayers.Pixel(
           Math.max(Math.floor((point.x - this.tileOrigin.lon) / (this.tileSize.w * res)),0),
           Math.max(Math.floor((this.tileOrigin.lat - point.y) / (this.tileSize.h * res)),0)
        );
    },
    
   /** 
    * Method: calculateMaxExtentWithLOD
    * Given a Level of Detail object from the server, this function
    *     calculates the actual max extent
    * 
    * Parameters: 
    * lod - {Object} a Level of Detail Object from the server capabilities object 
            representing a particular zoom level
    * 
    * Returns: 
    * {<OpenLayers.Bounds>} The actual extent of the tiles for the given zoom level
    */
   calculateMaxExtentWithLOD: function(lod) {
        // the max extent we're provided with just overlaps some tiles
        // our real extent is the bounds of all the tiles we touch

        var numTileCols = (lod.endTileCol - lod.startTileCol) + 1;
        var numTileRows = (lod.endTileRow - lod.startTileRow) + 1;        

        var minX = this.tileOrigin.lon + (lod.startTileCol * this.tileSize.w * lod.resolution);
        var maxX = minX + (numTileCols * this.tileSize.w * lod.resolution);

        var maxY = this.tileOrigin.lat - (lod.startTileRow * this.tileSize.h * lod.resolution);
        var minY = maxY - (numTileRows * this.tileSize.h * lod.resolution);
        return new OpenLayers.Bounds(minX, minY, maxX, maxY);
   },
    
   /** 
    * Method: calculateMaxExtentWithExtent
    * Given a 'suggested' max extent from the server, this function uses
    *     information about the actual tile sizes to determine the actual
    *     extent of the layer.
    * 
    * Parameters: 
    * extent - {<OpenLayers.Bounds>} The 'suggested' extent for the layer
    * res - {Float} The resolution for which to compute the extent.
    * 
    * Returns: 
    * {<OpenLayers.Bounds>} The actual extent of the tiles for the given zoom level
    */
   calculateMaxExtentWithExtent: function(extent, res) {
        var upperLeft = new OpenLayers.Geometry.Point(extent.left, extent.top);
        var bottomRight = new OpenLayers.Geometry.Point(extent.right, extent.bottom);
        var start = this.getContainingTileCoords(upperLeft, res);
        var end = this.getContainingTileCoords(bottomRight, res);
        var lod = {
            resolution: res,
            startTileCol: start.x,
            startTileRow: start.y,
            endTileCol: end.x,
            endTileRow: end.y
        };
        return this.calculateMaxExtentWithLOD(lod);
   },
    
    /** 
    * Method: getUpperLeftTileCoord
    * Calculates the x/y pixel corresponding to the position 
    *     of the upper left tile for the given resolution.
    * 
    * Parameters: 
    * res - {Float} The resolution for which to compute the extent.
    * 
    * Returns: 
    * {<OpenLayers.Pixel>} The x/y pixel corresponding to the position 
    * of the upper left tile for the given resolution.
    */
    getUpperLeftTileCoord: function(res) {
        var upperLeft = new OpenLayers.Geometry.Point(
            this.maxExtent.left,
            this.maxExtent.top);
        return this.getContainingTileCoords(upperLeft, res);
    },

    /** 
    * Method: getLowerRightTileCoord
    * Calculates the x/y pixel corresponding to the position 
    *     of the lower right tile for the given resolution.
    *  
    * Parameters: 
    * res - {Float} The resolution for which to compute the extent.
    * 
    * Returns: 
    * {<OpenLayers.Pixel>} The x/y pixel corresponding to the position
    * of the lower right tile for the given resolution.
    */
    getLowerRightTileCoord: function(res) {
        var bottomRight = new OpenLayers.Geometry.Point(
            this.maxExtent.right,
            this.maxExtent.bottom);
        return this.getContainingTileCoords(bottomRight, res);
    },
    
   /** 
    * Method: getMaxExtentForResolution
    * Since the max extent of a set of tiles can change from zoom level
    *     to zoom level, we need to be able to calculate that max extent 
    *     for a given resolution.
    *
    * Parameters: 
    * res - {Float} The resolution for which to compute the extent.
    * 
    * Returns: 
    * {<OpenLayers.Bounds>} The extent for this resolution
    */ 
    getMaxExtentForResolution: function(res) {
        var start = this.getUpperLeftTileCoord(res);
        var end = this.getLowerRightTileCoord(res);

        var numTileCols = (end.x - start.x) + 1;
        var numTileRows = (end.y - start.y) + 1;

        var minX = this.tileOrigin.lon + (start.x * this.tileSize.w * res);
        var maxX = minX + (numTileCols * this.tileSize.w * res);
        
        var maxY = this.tileOrigin.lat - (start.y * this.tileSize.h * res);
        var minY = maxY - (numTileRows * this.tileSize.h * res);
        return new OpenLayers.Bounds(minX, minY, maxX, maxY);
    },
    
   /** 
    * APIMethod: clone 
    * Returns an exact clone of this OpenLayers.Layer.ArcGISCache
    * 
    * Parameters: 
    * [obj] - {Object} optional object to assign the cloned instance to.
    *  
    * Returns: 
    * {<OpenLayers.Layer.ArcGISCache>} clone of this instance 
    */ 
    clone: function (obj) { 
        if (obj == null) { 
            obj = new OpenLayers.Layer.ArcGISCache(this.name, this.url, this.options);
        }
        return OpenLayers.Layer.XYZ.prototype.clone.apply(this, [obj]);
    },

    /**
     * Method: getMaxExtent
     * Get this layer's maximum extent.
     *
     * Returns:
     * {OpenLayers.Bounds}
     */
    getMaxExtent: function() {
        var resolution = this.map.getResolution();
        return this.maxExtent = this.getMaxExtentForResolution(resolution);
    },

    /**
     * Method: getTileOrigin
     * Determine the origin for aligning the grid of tiles.  
     *     The origin will be derived from the layer's <maxExtent> property. 
     *
     * Returns:
     * {<OpenLayers.LonLat>} The tile origin.
     */
    getTileOrigin: function() {
        var extent = this.getMaxExtent();
        return new OpenLayers.LonLat(extent.left, extent.bottom);
    },

   /**
    * Method: getURL
    * Determine the URL for a tile given the tile bounds.  This is should support
    *     urls that access tiles through an ArcGIS Server MapServer or directly through
    *     the hex folder structure using HTTP.  Just be sure to set the useArcGISServer
    *     property appropriately!  This is basically the same as 
    *     'OpenLayers.Layer.TMS.getURL',  but with the addition of hex addressing,
    *     and tile rounding.
    *
    * Parameters:
    * bounds - {<OpenLayers.Bounds>}
    *
    * Returns:
    * {String} The URL for a tile based on given bounds.
    */
    getURL: function (bounds) {
        var res = this.getResolution(); 

        // tile center
        var originTileX = (this.tileOrigin.lon + (res * this.tileSize.w/2)); 
        var originTileY = (this.tileOrigin.lat - (res * this.tileSize.h/2));

        var center = bounds.getCenterLonLat();
        var point = { x: center.lon, y: center.lat };
        var x = (Math.round(Math.abs((center.lon - originTileX) / (res * this.tileSize.w)))); 
        var y = (Math.round(Math.abs((originTileY - center.lat) / (res * this.tileSize.h)))); 
        var z = this.map.getZoom();

        // this prevents us from getting pink tiles (non-existant tiles)
        if (this.lods) {        
            var lod = this.lods[this.map.getZoom()];
            z = lod.level;
            if ((x < lod.startTileCol || x > lod.endTileCol) 
                || (y < lod.startTileRow || y > lod.endTileRow)) {
                    return null;
            }
        }
        else {
            var start = this.getUpperLeftTileCoord(res);
            var end = this.getLowerRightTileCoord(res);
            if ((x < start.x || x >= end.x)
                || (y < start.y || y >= end.y)) {
                    return null;
            }        
        }

        // Construct the url string
        var url = this.url;
        var s = '' + x + y + z;

        if (url instanceof Array) {
            url = this.selectUrl(s, url);
        }

        // Accessing tiles through ArcGIS Server uses a different path
        // structure than direct access via the folder structure.
        if (this.useArcGISServer) {
            // AGS MapServers have pretty url access to tiles
            url = url + '/tile/${z}/${y}/${x}';
        } else {
            // The tile images are stored using hex values on disk.
            x = 'C' + this.zeroPad(x, 8, 16);
            y = 'R' + this.zeroPad(y, 8, 16);
            z = 'L' + this.zeroPad(z, 2, 16);
            url = url + '/${z}/${y}/${x}.' + this.type;
        }

        // Write the values into our formatted url
        url = OpenLayers.String.format(url, {'x': x, 'y': y, 'z': z});

        return url;
    },

    /**
     * Method: zeroPad
     * Create a zero padded string optionally with a radix for casting numbers.
     *
     * Parameters:
     * num - {Number} The number to be zero padded.
     * len - {Number} The length of the string to be returned.
     * radix - {Number} An integer between 2 and 36 specifying the base to use
     *     for representing numeric values.
     */
    zeroPad: function(num, len, radix) {
        var str = num.toString(radix || 10);
        while (str.length < len) {
            str = "0" + str;
        }
        return str;
    },

    CLASS_NAME: 'OpenLayers.Layer.ArcGISCache' 
}); 

/*------------------------------------------------------------------------------------------------------------------------------------*/
  
  rcoosmapping.utils =
  {
    reprojectPoint: function(fromProj, toProj, x, y)
    {
      var fromP = new OpenLayers.Projection(fromProj); 
      var toP   = new OpenLayers.Projection(toProj); 
      var point = new OpenLayers.LonLat(x,y);
      point.transform( fromP, toP );
      return(point);    
    }
  }


 
  GeoExt.tree.layerLoaderExtended = Ext.extend(GeoExt.tree.LayerLoader, {
    defaultGFILayer: '',
    
    /*
    Function:  createNode
    Purpose: For each layer we want to display in the layer tree, this function creates the tree node.
    The function also checks to see if the node is setup to have a radio button or opacity slider.
    Parameters:
      attr are the attributes.
    Return:
      The newly created LayerNode object.
    */
    
    createNode: function(attr) {

      this.baseAttrs.cls = 'layer-tree-node';
      //Does this node have a radio button?
      if(this.baseAttrs.radioGroup != undefined)
      {
        //Does the layer need the getFeatureInfo radio button?
        if(attr.layer.options.QUERYABLE != undefined && attr.layer.options.QUERYABLE == false)
        {
          //The layer doesn't need the radio button, so we get rid of that attribute.
          delete this.baseAttrs.radioGroup;
        }
      }
      //Does this node have a opacity slider?
      if(this.baseAttrs.slider != undefined)
      {
        //Does the layer need an opacity slider?
        if(attr.layer.options.opacitySlider != undefined && attr.layer.options.opacitySlider == false)
        {
          //The layer doesn't need the slider, so we get rid of that attribute.
          delete this.baseAttrs.slider;
        }
      }       
      var node = GeoExt.tree.layerLoaderExtended.superclass.createNode.apply(this, arguments);
      //If there is an attribution option on the layer, we'll use the string as a quick tip.
      /*if(node.layer.options.attribution != undefined)
      {
        node.setTooltip(node.layer.options.attribution, "Layer Info");
      }*/
      //For the layer we add the loading start/end/cancel events so we can modify the icons in the tree view to show a 
      //loading indicator when the layer starts loading. Then when the layer ends loading or gets canceled we revert back
      //to the original icon.
      node.layer.events.on({
          "loadstart": this.loadStart,
          scope: node
      }); 
      node.layer.events.on({
          "loadend": this.loadEnd,
          scope: node
      });     
      node.layer.events.on({
          "loadcancel": this.loadCancel,
          scope: node
      });     
      
      
      return node;
    },
    /*
    Function:  loadStart
    Purpose: Event handler for the layers loadstart event. The scope is the node that owns the layer.
    Parameters:
    Return:
    */
    loadStart : function(eventObj, domElement)
    {
      this.setIcon('./resources/images/default/grid/loading.gif');
      //this.setIconCls("loading-indicator");
    },
    /*
    Function:  loadEnd
    Purpose: Event handler for the layers loadEnd event. The scope is the node that owns the layer.
    Parameters:
    Return:
    */
    loadEnd : function(eventObj, domElement)
    {
      this.setIcon('./resources/images/default/tree/leaf.gif');
    },
    /*
    Function:  loadCancel
    Purpose: Event handler for the layers loadcancel event. The scope is the node that owns the layer.
    Parameters:
    Return:
    */
    loadCancel : function(eventObj, domElement)
    {
      this.setIcon('./resources/images/default/tree/leaf.gif');
    }
  });

  rcoosmapping.olMap = Ext.extend(Ext.Panel,
  {
    olMap         : undefined,
    dataLayerTree : undefined,
    tileCacheURL  : '',
    mapservURL    : '',
    mapFile       : '',
    ImageType     : 'image/png',
    TileCacheMod  : '',  //Modifier for our TileCache layers. For ie6 we use a specific layer to avoid the png transparency issue.
    nfoPopup      : undefined,
    layerStore      : undefined,
    initGFISelect   : false,
    helpWindow      : undefined,
    mapLegendURL  : '',
    googAnalytics : undefined,
    lookupTable : null,     //This is the lookup table from the platform JSON data record.
    insituPlatforms : null,         //
    mapInited : false,      //Flag that specifies if the init() function has completed.

    constructor: function(config) 
    {    
      this.toolbarItems = [];
      this.obsInfoControls = [];
      rcoosmapping.olMap.superclass.constructor.call(this, config);
    },
      
    createPanel : function(titleString) 
    {         
      this.layout = 'border';
      this.title = titleString;
      this.hideMode = 'offsets';
      this.autoScroll = true;
      this.draggable = false;
      this.add({
        id: 'westPanel-' + titleString,
        region: 'west',
        title: ' ',
        split: true,
        width: 200,
        minSize: 175,
        maxSize: 400,
        collapsible: true,
        margins: '0 0 0 5',
        layout: 'accordion',
        layoutConfig:{
            animate: true
        },
        items: [
          this.dataLayerTree
          ]
        });
      this.add({
        id: 'mapPanel-' + titleString,
        region: 'center',
        title: 'Map',
        layout: 'fit',
        frame: false,
        border: true,
        margins: '5 5 0 0',
        items: [{
          xtype: 'gx_mappanel',
          map: this.olMap,
          layers: this.layerStore,
          zoom: 13,
          border: false,
          tbar: this.toolbarItems,
          id: titleString + 'OLMap'
        }]
      });
      this.add({
      id: 'legendPanel-' + titleString,
      region: 'east',
      title: 'Map Legend',
      //split: true,
      width: 200,
      collapsible: true,
      margins: '0 0 0 5',
      //layout: 'accordion',
      autoScroll: true,
      items:[{
          bodyCssClass: 'east-panel-body',
          title: '',
          height: 'auto',
          autoLoad: {url:this.mapLegendURL,scripts:false},
          border: true,
          autoScroll: true
        }]                    
      });
    },    
    createToolbar : function(groupName)
    {
      var createSeparator = function(toolbarItems)
      { 
         toolbarItems.push(" ");
         toolbarItems.push("-");
         toolbarItems.push(" ");
      };

      action = new GeoExt.Action({
          control: new OpenLayers.Control.ZoomToMaxExtent(),
          map: this.olMap,
          iconCls: 'zoomfull',
          toggleGroup: groupName,
          tooltip: 'Zoom to full extent'
      });

      this.toolbarItems.push(action);

      createSeparator(this.toolbarItems);

      action = new GeoExt.Action({
          control: new OpenLayers.Control.ZoomBox(),
          tooltip: 'Zoom in: click in the olMap or use the left mouse button and drag to create a rectangle',
          map: this.olMap,
          iconCls: 'zoomin',
          toggleGroup: groupName
      });

      this.toolbarItems.push(action);

      action = new GeoExt.Action({
          control: new OpenLayers.Control.ZoomBox({
              out: true
          }),
          tooltip: 'Zoom out: click in the olMap or use the left mouse button and drag to create a rectangle',
          map: this.olMap,
          iconCls: 'zoomout',
          toggleGroup: groupName
      });

      this.toolbarItems.push(action);

      action = new GeoExt.Action({
          control: new OpenLayers.Control.DragPan({
              isDefault: false
          }),
          tooltip: 'Pan olMap: keep the left mouse button pressed and drag the olMap',
          map: this.olMap,
          iconCls: 'pan',
          toggleGroup: groupName
      });

      this.toolbarItems.push(action);

      createSeparator(this.toolbarItems);
         
      action = new GeoExt.Action({
          control: new OpenLayers.Control.WMSGetFeatureInfo({
              isDefault: true
          }),
          tooltip: 'For layers with querying ability, this issues a request for the data',
          map: this.olMap,
          iconCls: 'info',
          toggleGroup: groupName
      });

      this.toolbarItems.push(action);

      createSeparator(this.toolbarItems);
      action = new Ext.Action({
          tooltip: 'General Map Help',
          handler: function()
          {
            if(this.helpWindow != undefined)
            {
              this.helpWindow.close();
            }
            this.helpWindow = new Ext.Window({
              title: 'Help',
              autoScroll: true,
              height: 500,
              width: 'auto',
              autoLoad: {url:'./help.html',scripts:false},
              border: true
            });
            this.helpWindow.show();            
          },
          iconCls: 'help',
          toggleGroup: groupName,
          scope: this
      });
      this.toolbarItems.push(action);
    },
    createMap : function(mapOptions)
    {
    
      var browser = navigator.appName;
      var version = navigator.appVersion;
      var version1 = version.substring(22, 25);
      if (browser == "Microsoft Internet Explorer" && version1 == "6.0")
      {
        this.ImageType = 'image/png1';
        this.TileCacheMod = 'ie6';
      }         
      this.olMap = new OpenLayers.Map(mapOptions);
    },
    
    createLayer : function(layerType, name, url, params, options, creategetFeatureInfoClick) 
    {
      var layer = null
      if(layerType == "OpenLayers.Layer.WMS")
      { 
        var layer = new OpenLayers.Layer.WMS(name, url, params, options);
        if(creategetFeatureInfoClick)
        {
          this.obsInfoControls.push({
          click: new OpenLayers.Control.WMSGetFeatureInfo(
            {
              layers: [layer],
              queryVisible: true,
              maxFeatures: 1,
              vendorParams: {map: layer.params.MAP}
            })
          });
        }        
      }
      if(layerType == "OpenLayers.Layer.WMSEx")
      {
        layer = new OpenLayers.Layer.WMSEx(name, url, params, options);
        if(creategetFeatureInfoClick != undefined && creategetFeatureInfoClick)
        {
          this.obsInfoControls.push({
          click: new OpenLayers.Control.WMSGetFeatureInfo(
            {
              layers: [layer],
              queryVisible: true,
              maxFeatures: 1,
              vendorParams: {map: layer.params.MAP}
            })
          });
        }
      }      
      else if(layerType == "OpenLayers.Layer.Google")
      {
        layer = new OpenLayers.Layer.Google(name, options);
      }
      else if(layerType == "OpenLayers.Layer.XYZ")
      {
        layer = new OpenLayers.Layer.XYZ(name, url, options);
      }
      else if(layerType == "rcoosmapping.earthNCCharts")
      {
        layer = new rcoosmapping.earthNCCharts(name, url, options);
      }
      else if(layerType == "OpenLayers.Layer.Vector")
      {
        layer = new OpenLayers.Layer.Vector(name, options);
      }
      else if(layerType == "OpenLayers.Layer.ArcGISCache")
      {
        layer = new OpenLayers.Layer.ArcGISCache(name, url, options);
      }
      return(layer)
    },
    addWMSLayer : function(name, url, params, options, creategetFeatureInfoClick) 
    {
      var layer = new OpenLayers.Layer.WMS(name, url, params, options);
      this.olMap.addLayer(layer);
      if(creategetFeatureInfoClick)
      {
        this.obsInfoControls.push({
        click: new OpenLayers.Control.WMSGetFeatureInfo(
          {
            url: url,
            layers: [layer],
            queryVisible: true,
            maxFeatures: 1
            //vendorParams: {map: params.map}
          })
        });
      }
      return(layer);
    },    
    addGoogleLayer : function(name, options) 
    {
      var layer = new OpenLayers.Layer.Google(name, options)
      this.olMap.addLayer(layer);
      return(layer);
    },
    createLayers : function(configParams)
    {
      /*if(configParams !== undefined)
      {
        this.addLayersFromConfig(configParams);
      }*/
      this.addLayers(configParams);
      this.buildGFIControls();
      this.layerStore = new GeoExt.data.LayerStore({
        map: this.olMap,
        layers: this.olMap.layers,
        initDir: GeoExt.data.LayerStore.MAP_TO_STORE
      });      
    },
    addLayers : function(configParams)
    {
      if(configParams !== undefined)
      {
        var cfgLayers = configParams.layers;
        var len = cfgLayers.length;
        for(var i = 0; i < len; i++)
        {
          var layerParams = cfgLayers[i];
          for(var layerName in layerParams.children)
          {
            if(layerName !== undefined)
            {          
              var layerConfig = layerParams.children[layerName];
              var url;
              if(layerConfig.url !== undefined)
              {
                url = layerConfig.url;
              }
              var params;
              if(layerConfig.params !== undefined)
              {
                params = layerConfig.params;
              }
              var options;
              if(layerConfig.options !== undefined)
              {
                options = layerConfig.options;
              }
              //For the google layers, we have to translate the type parameter into the google object to use.
              if(layerConfig.type == "OpenLayers.Layer.Google")
              {
                if(options.type == "G_PHYSICAL_MAP")
                {
                  options.type = G_PHYSICAL_MAP;
                }
                else if(options.type == "G_HYBRID_MAP")
                {
                  options.type = G_HYBRID_MAP;
                }
              }
              var layer = this.createLayer(layerConfig.type, layerName, url, params, options, layerConfig.EnableGetFeatureInfo);
              if(layer !== null)
              {
                this.olMap.addLayer(layer);
              }
              else
              {
                if(layerConfig.type == "rcoosmapping.platformVectorLayer")
                {
                  layer = new rcoosmapping.platformVectorLayer(layerName, { 
                                                    layerOptions : layerConfig,
                                                    map: this.olMap,
                                                    googAnalytics : this.googAnalytics,
                                                    parentPanel: this
                                                    });
                                                    
                  layer.getFeaturesData();                                                
                }
              }
              if(layerConfig.zIndexDelta != undefined)
              {
                //var ndx = this.olMap.getLayerIndex(layer);
                this.olMap.raiseLayer(layer, layerConfig.zIndexDelta);
              }
              
            }
            
            //(layerType, name, url, params, options)
            //this.createLayer();
          }
        }
      }
    },
    createLayerTree : function(name)
    {
      // create our own layer node UI class, using the RadioButtonMixin
      var LayerNodeUI = Ext.extend(GeoExt.tree.LayerNodeUI, new GeoExt.tree.TreeNodeUIEventMixinExtended()); 
    
      var treeRoot = new Ext.tree.AsyncTreeNode({
                      expanded: true
                  });
      this.dataLayerTree = new Ext.tree.TreePanel({
          bodyCssClass: 'west-panel-body',
          title: name,
          border: false,
          header: true,
          draggable: false,
          autoScroll: true,
          loader: new Ext.tree.TreeLoader({
              // applyLoader has to be set to false to not interfer with loaders
              // of nodes further down the tree hierarchy
              applyLoader: false,
              uiProviders: 
              {
                "layernodeui": LayerNodeUI 
              }
          }),
          root:  treeRoot,       
          plugins: [ 
            new GeoExt.tree.RadioButtonPlugin({ 
                listeners: 
                { 
                  scope: this,
                  "radiochange": function(node) { 
                    //var olMap = node.layer.map;
                    var olMap = this.olMap;
                    var len = olMap.controls.length;
                    //Run through all the controls on the olMap, then for the layers associated with that control figure 
                    //out if it is the layer the user just enabled to do a getfeature query on. We enable the layer while
                    //disabling all other layer's getfeature info queries.
                    for(var i = 0; i < len; i++)
                    {
                      var control = olMap.controls[i];
                      if(control.layer != undefined)
                      {
                        if(node.layer.name == control.layer.name)
                        {
                          control.activate();
                        }
                        else
                        {
                          control.deactivate();
                        }
                      }
                      else if(control.layers != undefined)
                      {
                        var layerLen = control.layers.length;
                        for(var j = 0; j < layerLen; j++)
                        {
                          if(node.layer.name == control.layers[j].name)
                          {
                            control.activate();
                          }
                          else
                          {
                            control.deactivate();
                          }
                        }
                      }
                    }    
                  } 
                } 
            }),
            new GeoExt.tree.LayerOpacitySliderPlugin({
                listeners: { 
                    "opacityslide": function(node, value) 
                    { 
                    }                
                }
            }),
            new GeoExt.tree.LayerInfoPlugin({
                listeners: { 
                    "layerinfoclick": function(node, value) 
                    {
                      window.open(node.layer.attributionLink);
                    }                
                }
            })
            
          ],
          rootVisible: false,
          lines: false
      });    
    },    
    populateLayerTree : function(layers)
    {
      this.displayLayerInGroup = function(record)
      {
        var layer = record.get("layer");
        if(layer.displayInLayerSwitcher)
        {
          if(layer.options.GROUP == this.baseAttrs.group)
          {
            //Do we need a radio button to enable GetFeatureInfo requests?
            if(layer.options.QUERYABLE != undefined && layer.options.QUERYABLE)
            {
              this.baseAttrs.radioGroup = 'radioGroup';
              this.baseAttrs.uiProvider = "layernodeui";
            }
            //Does the layer need an opacity slider control?
            if(layer.options.opacitySlider != undefined && layer.options.opacitySlider)
            {
              this.baseAttrs.slider = "layeropacityslider";
              this.baseAttrs.uiProvider = "layernodeui";
            }
            if(layer.options.attributionLink != undefined && layer.options.attributionLink)
            {
              this.baseAttrs.layerinfo = "layerinfoclick";
              this.baseAttrs.uiProvider = "layernodeui";
            }
           
            return(true);
          }
        }
        return(false);                
      };
      this.displayInBaseLayer = function(record)
      {
        var layer = record.get("layer");
        if(layer.displayInLayerSwitcher)
        {
          if(layer.isBaseLayer)
          {
            return(true);
          }
        }
        return(false);                
      };

      this.buildTreeNodes = function(layers, name)
      {    
        emptyGroupName = "";
        var treeNodes = [];
        //Add the base layer container node since we know we'll have this.
        node = 
        {
          id: "Base Layer",
          cls: 'layer-tree-node',
          nodeType: "gx_baselayercontainer",
          expanded: true,
          loader: new GeoExt.tree.layerLoaderExtended(
            {
              baseAttrs: {},
              filter: this.displayInBaseLayer,
              store: this.layerStore
            }
          )
        };
        treeNodes.push(node);
        for(var i = 0; i < layers.length; i++)
        {        
          var layer = layers[i];
          // jump over layers, which should not be displayed 
          if (layer.displayInLayerSwitcher == false || layer.isBaseLayer) 
          {
              continue;
          }
          if( layer.options.GROUP == undefined )
          {
            layerGroup = emptyGroupName;
          }            

          var foundGrp = false;
          var Len = treeNodes.length;
          var ndx = -1;
          for(var j = 0; j < Len; j++)
          { 
            if( treeNodes[j].text == layer.options.GROUP )
            {
              foundGrp = true;
              break;
            }          
          }
          if(!foundGrp)
          {
            var node;
            node = 
            {
              id: layer.options.GROUP,
              cls: 'layer-tree-node',
              text: layer.options.GROUP,
              nodeType: "gx_layercontainer",
              expanded: true,
              
              loader: new GeoExt.tree.layerLoaderExtended(              
              {
                defaultGFILayer: "Real Time Observations",
                baseAttrs:
                {
                  group: layer.options.GROUP
                },
                filter: this.displayLayerInGroup,
                store: this.layerStore
              })
            };
            
            treeNodes.push(node);
          }
        }
        return(treeNodes);    
      };      
      
      var nodes = this.buildTreeNodes(layers, name);
      var treeRoot = new Ext.tree.AsyncTreeNode({
                      expanded: true,
                      children: nodes
                  });

      this.dataLayerTree.setRootNode(treeRoot);
      
      return(this.dataLayerTree);    
    },
    addLayerToTreeNode : function(layer)
    {
      if(layer.options != undefined && layer.options.GROUP != undefined)
      {
        var node = this.dataLayerTree.getNodeById(layer.options.GROUP);
        if(node == undefined)
        {
        }
        else
        {
        }
      }
    },
    setInitialGFINode : function(group, layerName)
    {
      //We want to set the Real Time Observations as the current GetFeatureInfo selection. We get the root node
      //then search for teh InSitu group that the layer is in, then search for the layer itself.
      var root = this.dataLayerTree.getRootNode();
      var inSitu = root.findChild('text', group);
      if(inSitu != null)
      {
        for(var i=0; i < inSitu.childNodes.length; i++)
        {
          if(inSitu.childNodes[i].text == layerName)
          {
            var ui = inSitu.childNodes[i].getUI();
            ui.node.attributes.radio.checked = true;
            break;
          }
        }
      }
    },
    
    launchInfoPopup : function(event,mapObj,ctCls)
    {
      this.clearPopup();
      var lonlat = mapObj.getLonLatFromPixel(event.xy);      
      
      //Add a div in where we will place the graph once the Ajax call below comes back with a geoJson object.
      //this.nfoPopup = new GeoExt.PopupTst(
      this.nfoPopup = new GeoExt.Popup(
        {
          id: 'FeaturePopup',
          map: mapObj,
          //map: mapPanel,
          title: "Feature Information",
          autoScroll: true,
          location: lonlat,
          html: event.text,
          width: 300,
          height: 'auto',
          collapsible: true,
          anchored: true,
          ctCls: ctCls
        }
      );

      this.nfoPopup.show();
    },
        
    obsInfoClick : function(event)
    {
      this.launchInfoPopup(event,this.olMap,'featurePopupBox');
    },
    
    clearPopup : function() 
    {
      if(this.nfoPopup !== undefined) 
      {
        this.nfoPopup.close();
        this.nfoPopup = undefined;
      }
    },
    
    buildGFIControls : function()
    {
      var len = this.obsInfoControls.length;
      for(var i = 0; i < len; i++) 
      { 
        var clickObj = this.obsInfoControls[i].click;
        clickObj.events.register("getfeatureinfo", this, this.obsInfoClick);
        this.olMap.addControl(clickObj); 
        clickObj.activate();
      }    
    },
    
    getJsonData : function(jsonURL, callbackFunc, errorFunc)
    {
      var url = OpenLayers.ProxyHost + jsonURL;
      Ext.Ajax.request({
         url: url,
         success: callbackFunc,
         failure: errorFunc,
         scope: this
      });    
    },
    configAjaxQuery : function(response, options)
    {
      var jsonObject = Ext.util.JSON.decode(response.responseText);
    },
    setLegendURL : function(url)
    {
      this.mapLegendURL = url;
    },
    setCenter : function(point, overridePermalink)
    {
      for(var ndx in this.olMap.controls)
      {
        var control = this.olMap.controls[ndx];
        if(control.CLASS_NAME == "OpenLayers.Control.ArgParser")
        {
          if(control.center == null || overridePermalink)
          {
            this.olMap.setCenter(point);
          }
          break;
        }
      }    
    },
    setAnalytics : function(googAnalytics)
    {
      this.googAnalytics = googAnalytics;
    },
    mapInitialized : function(inited)
    {
      this.mapInited = inited; 
    },    
    init : function(dataServerIP,mapservIP,tilecacheIP,configParams) 
    {
      this.dataServerIP  = dataServerIP;
      this.tileCacheURL  = 'http://' + tilecacheIP + '/tilecache/tilecache.py?';
      this.mapservURL    = 'http://' + mapservIP + '/cgi-bin/mapserv?';
      this.secooraMapFile= '/home/xeniaprod/mapping/secoora/SecooraObs.map';
      this.generalMapFile= '/home/xeniaprod/mapping/common/general.map'; 
      this.ImageType     = 'image/png';
      this.TileCacheMod  = '';  //Modifier for our TileCache layers. For ie6 we use a specific layer to avoid the png transparency issue.
      this.mapLegendURL  = 'legend.html';
    
      
      OpenLayers.ProxyHost= "http://rcoos.org/carolinasrcoosrev2/cgi-bin/AjaxProxy.php?url=";
      //OpenLayers.ProxyHost="http://secoora.org/AjaxProxy.php?url=";    
       
      var mapConfig = configParams.mapConfig;
          
      var melrLL = rcoosmapping.utils.reprojectPoint(mapConfig.displayProjection,mapConfig.projection, 
                                                      mapConfig.mapExtents.lowerLeft.lon, mapConfig.mapExtents.lowerLeft.lat);
      var melrUR = rcoosmapping.utils.reprojectPoint(mapConfig.displayProjection,mapConfig.projection, 
                                                      mapConfig.mapExtents.upperRight.lon, mapConfig.mapExtents.upperRight.lat);
      
      var mapOptions= {
                    maxExtent: new OpenLayers.Bounds(melrLL.lon,melrLL.lat, melrUR.lon,melrUR.lat),          
                    numZoomLevels: mapConfig.numZoomLevels,
                    maxResolution: mapConfig.maxResolution,
                    resolutions: mapConfig.resolutions,
                    projection: new OpenLayers.Projection(mapConfig.projection),
                    displayProjection: new OpenLayers.Projection(mapConfig.displayProjection),
                    units: mapConfig.units,           
                    controls: [
                               new OpenLayers.Control.Navigation({
                                zoomWheelEnabled: true,
                                autoActivate: true
                               }),
                               new OpenLayers.Control.MousePosition({numdigits:2}),                
                               new OpenLayers.Control.PanZoomBar(),
                               new OpenLayers.Control.Permalink('permalink'),                         
                               new OpenLayers.Control.ScaleLine()
                               ]
                  };
   

      this.createMap(mapOptions);
      this.olMap.id = configParams.layerTreeName;
      this.createToolbar(configParams.toolbarGroupName);
      this.createLayers(mapConfig);
      this.createLayerTree(configParams.layerTreeName);
      this.populateLayerTree(this.olMap.layers);
      
      this.dataLayerTree.addListener('checkchange', this.treeNodeCheckChange, this);
    }
});
