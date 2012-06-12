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
      this.layout = 'anchor';
    }
    this.items = [];
    if(this.layerInfo)
    {
      this.items.push(this.addLayerInfo(this.layerInfo));
    }
		var secRow = this.buildSecondRow();
		if(secRow)
		{
			this.items.push(secRow);
		}
		
	/*
    if(this.opacityParams)
    {
      this.items.push(this.addOpacitySlider(this.opacityParams));
    }
    if(this.timeParams)
    {
      this.items.push(this.addDateTimePicker(this.timeParams));
    }
    */
    rcoosmapping.timeWidget.superclass.constructor.call(this, config);
    
    /*if(config.timeParams)
    {
      this.addDateTimePicker(config.timeParams);
    }*/
  },
  buildSecondRow : function()
  {
		var vPanel;
		if(this.opacityParams || this.timeParams)
		{
			var opacityBox;
			var timeBox; 
			var items = [];
			if(this.opacityParams)
			{
				opacityBox = this.addOpacitySlider(this.opacityParams);	
				items.push(opacityBox);			
			}
			if(this.timeParams)
			{
				timeBox = this.addDateTimePicker(this.timeParams);	
				items.push(timeBox);										
			}
			vPanel = new Ext.Container({
				id : 'dateopacitycontainer-' + this.title,
				pack : 'start',
				align : 'stretch',
				anchor : "100% 50%",
				layout : 'hbox',
				items : items
			});
		}
		return(vPanel);
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
      id : 'datetimefields-' + this.title,
      anchor : "50% 100%",
			flex : 1,
			height : 75,
			//width : 175,
			style : 'padding: 5px 2px 2px 2px',			
      layout : 'vbox',
      title : "Layer Time Adjustment",
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

    var sliderSet = new Ext.form.FieldSet({
      id : 'opacitysliders-' + this.title,
      anchor : "50% 100%",
			flex : 1,
			height : 75,
			//width : 175,
      //layout : 'vbox',      
			style : 'padding: 5px 2px 2px 2px',
      collapsed: false,   // initially collapse the group
      collapsible: false,
      title : "Layer Opacity",
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
    
    //this.add(sliderSet);
    return(sliderSet);
  },
  addLayerInfo : function(layerInfo)
  {
    var sliderSet = new Ext.form.FieldSet({
      id : 'layerinfo-' + this.title,
      anchor : "100% 50%",
			style : 'padding: 2px 2px 2px 2px',
			//padding : '1 1 1 1',
      layout : 'anchor',
      align : 'center',
      collapsed: false,   // initially collapse the group
      collapsible: false,
      title : "Layer Information",
      items : [
        {
          xtype : 'textarea',
          id : 'textCtrl-' + this.title,
          anchor : "100% 100%",
          //height : 'auto',
          //width : 100,
          readOnly : true,
          value : layerInfo.text,
          //flex : 1
        }
      ]
    });
    //this.add(sliderSet);
    return(sliderSet);
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
