Ext.namespace("rcoosmapping");


rcoosmapping.timeWidget = Ext.extend(Ext.Window, {
  layerInfo : undefined,
  initDateTime : undefined,
  timeParams : undefined,
  opacityParams : undefined,
  layer : undefined,
  
  constructor: function(config)
  {
    Ext.apply(this, config);
    if(config.layout === undefined)
    {
      this.layout = 'border';
    }
    var tabItems = [];
    if(this.layerInfo)
    {
      tabItems.push(this.addLayerInfo(this.layerInfo));
    }
/*
    var secRow = this.buildSecondRow();
    if(secRow)
    {
      tabItems.push(secRow);
    }
*/
    if(this.opacityParams)
    {
      tabItems.push(this.addOpacitySlider(this.opacityParams));
    }
    if(this.timeParams)
    {
      tabItems.push(this.addDateTimePicker(this.timeParams));
    }
    
    var tabPanel = new Ext.TabPanel({
      id : 'timewidgettab-' + this.title,
      items : tabItems,
      activeTab : 0,
			region : 'center'
    });
    this.items = [];
    this.items.push(tabPanel); 
    
   rcoosmapping.timeWidget.superclass.constructor.call(this, config);
    
  },
  
  addDateTimePicker : function(timeParams)
  {
    //This is the container object that will house the date selector and spinner control.
    /*var dateContainer = new Ext.Container({
      id : 'datecontainer-' + this.title,
      width : 150,
      height : 30,
      layout : 'hbox',
      region : 'center'
    });
    var dateSpinner = new Ext.ux.Spinner({
    });*/
    
    var ct;
    if(this.initDateTime)
    {
      ct = this.initDateTime;  
    }
    else
    {
      ct = new Date();
    }
    
    //Configure the datePicker object. We want to only allow the selection of the days available depending on the settings of the 
    //forecastHoursCount and hindcastHoursCount. We'll work in epoch since it makes date conversion much easier.
    var minDate = ct.add(Date.HOUR, -1 * timeParams.hindcastHoursCount);
    var maxDate = ct.add(Date.HOUR, timeParams.forecastHoursCount);
    var curTime = ct;
    if(timeParams.hourlyUpdateInterval)
    {
      minDate = getClosestDateToHourInterval(minDate, timeParams.hourlyUpdateInterval);
      maxDate = getClosestDateToHourInterval(maxDate, timeParams.hourlyUpdateInterval);
      curTime = getClosestDateToHourInterval(curTime, timeParams.hourlyUpdateInterval);
    }

    var dateTimeSet = new Ext.form.FieldSet({
      title : 'Time',
      id : 'datetimefields-' + this.title,
      height : 75,
      style : 'padding: 5px 2px 2px 2px',     
      layout : 'vbox',
      tabTip : "Allows the user to visualize different dates and times for the layer data.",
      collapsed: false,   // initially collapse the group
      collapsible: false,
      
      items : [
        {
          xtype : 'datefield',
          id : 'datepicker-' + this.title,
          width : 'auto',
          height : 30,
          format : 'Y-m-d',
          value : ct,
          minValue : minDate,
          maxValue : maxDate,
          listeners : { 
            scope : this,
            "afterrender" : function(thisObj)
            {
              thisObj.inited = true;
            },
            "valid" : function(thisObj) 
            {
              if(thisObj.inited)
              {
                if(this.layer)
                {
                  var dateTime = thisObj.value;
                  var timeCtrl = this.findById('timePickerCtrl-' + this.title);
                  if(timeCtrl)
                  {
                    dateTime += (' ' + timeCtrl.value);
                  }
                  dateReq = Date.parseDate(dateTime, "Y-m-d H:i:s");                                    
                  //Verify the function exists in the layer object.                  
                  if(this.layer.setTimeOffset)
                  {
                    this.layer.setTimeOffset(dateReq, true);
                  }
                }
              }
            }
          }
          //plugins : dateSpinner
        },
        {
          xtype : 'timefield',
          id : 'timePickerCtrl-' + this.title,
          region : 'south',
          width  : 100,
          height : 30,
          format : 'H:i:s',
          minValue : '00:00',
          maxValue : '23:00',
          value : curTime,
          increment : timeParams.hourlyUpdateInterval * 60,
          listeners : { 
            scope : this,
            "afterrender" : function(thisObj)
            {
              thisObj.inited = true;
            },
            "valid" : function(thisObj) 
            {
              if(thisObj.inited)
              {
                if(this.layer)
                {
                  var dateReq;
                  var dateTime;
                  var dateCtrl = this.findById('datepicker-' + this.title);
                  if(dateCtrl)
                  {
                    dateTime = dateCtrl.value;
                  }
                  dateTime += (' ' + thisObj.value);
                  dateReq = Date.parseDate(dateTime, "Y-m-d H:i:s");                                    
                  //Verify the function exists in the layer object.                  
                  if(this.layer.setTimeOffset)
                  {
                    this.layer.setTimeOffset(dateReq, true);
                  }                
                }
              }
            }
          }
        }
      ]
    });
    //this.add(dateTimeSet);
    return(dateTimeSet);
  },
  addOpacitySlider :function(opacityParams)
  {
    //This is needed to get the thumb on the slider to the correct initial point. The base code
    //for the Ext.slider calls innerEl.getWidth() which does not work since at this point the slider
    //isn't rendered. 
    
    Ext.override(Ext.slider.SingleSlider, {
      getRatio : function(){
          var w = this.innerEl.getComputedWidth();
          var v = this.maxValue - this.minValue;
          return v == 0 ? w : (w/v);
      }
    });    
		var opacitySlider = new Ext.slider.SingleSlider({
			title : 'Opacity',
			id : 'opacitysliderCtrl-' + this.title,
			align : 'center',
		  width: 150,
		  height : 20,
		  minValue: 0,
		  maxValue: 100,
		  value: opacityParams.initOpacity ? opacityParams.initOpacity : 100,
		  aggressive: true,
		  plugins: new GeoExt.LayerOpacitySliderTip(),
		  listeners : {
		    scope : this,
		    "change" : function(slider, newValue) {
		      if(this.layer)
		      { 
		        this.layer.setOpacity(newValue/100.0);
		      }
		    }
		  }
		});  
		/*
    var opacitySlider = new Ext.Container({
			title : 'Opacity',
			id : 'opacitysliders-' + this.title,      
			items : [{
				xtype : 'slider',
	      id : 'opacitysliderCtrl-' + this.title,
	      width: 150,
	      height : 20,
	      minValue: 0,
	      maxValue: 100,
	      value: opacityParams.initOpacity ? opacityParams.initOpacity : 100,
	      aggressive: true,
	      plugins: new GeoExt.LayerOpacitySliderTip(),
	      listeners : {
	        scope : this,
	        "change" : function(slider, newValue) {
	          if(this.layer)
	          { 
	            this.layer.setOpacity(newValue/100.0);
	          }
	        }
	      }
			}]
		});
		*/
/*
    var sliderSet = new Ext.form.FieldSet({
      title : 'Opacity',
      id : 'opacitysliders-' + this.title,
      //anchor : "50% 100%",
      //flex : 1,
      height : 75,
      //width : 175,
      //layout : 'vbox',      
      style : 'padding: 5px 2px 2px 2px',
      collapsed: false,   // initially collapse the group
      collapsible: false,
      tabTip : "Allows the user to adjust the opacity of the layer.",
      items : [
        {
          xtype : 'slider',
          align : 'left',
          id : 'opacitysliderCtrl-' + this.title,
          width: 150,
          height : 20,
          minValue: 0,
          maxValue: 100,
          value: opacityParams.initOpacity ? opacityParams.initOpacity : 100,
          aggressive: true,
          plugins: new GeoExt.LayerOpacitySliderTip(),
          listeners : {
            scope : this,
            "change" : function(slider, newValue) {
              if(this.layer)
              { 
                this.layer.setOpacity(newValue/100.0);
              }
            }
          }
        }      
      ]
    });
*/    
    //this.add(sliderSet);
    return(opacitySlider);
  },
  addLayerInfo : function(layerInfo)
  {
    var nfoTmplt = new Ext.XTemplate(
      '<div class="layerinfo"><p>{text}</p></div>',
      '<div class="layerinfolink"><p>More information <a href="{infoUrl}" target="_blank"> here</a></p></div>'
    );
		var layerInfo = new Ext.Container({
			title : "Information",
      id : 'textCtrl-' + this.title,
      tpl : nfoTmplt,
      data : this.layerInfo,
			layout : 'fit'      
			
		})
/*
    var sliderSet = new Ext.form.FieldSet({
      title : "Information",
      id : 'layerinfo-' + this.title,
      //anchor : "100% 50%",
      style : 'padding: 2px 2px 2px 2px',
      layout : 'anchor',
      align : 'center',
      collapsed: false,   // initially collapse the group
      collapsible: false,
      items : [
        {
          xtype : 'container',
          id : 'textCtrl-' + this.title,
          anchor : "100% 100%",
          tpl : nfoTmplt,
          data : this.layerInfo
        }
      ]
    });
*/
    return(layerInfo);
  }
  /*  
  afterrender : function()
  {
      
    if(this.layerInfo)
    {
      //this.add(this.addLayerInfo(this.layerInfo));
    }
    if(this.opacityParams)
    {
      this.add(this.addOpacitySlider(this.opacityParams));
    }
    if(this.timeParams)
    {
      this.add(this.addDateTimePicker(this.timeParams));
    }
    
  }
  */

});
