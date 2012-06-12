Ext.namespace('rcoosmapping');

rcoosmapping.graph = Ext.extend(Ext.ux.HighChart, {
  
  
  initComponent: function() {
    //this.listeners = {afterrender : this.afterrender};  
    rcoosmapping.graph.superclass.initComponent.call(this);
  },
  
  addTimeSeries : function(obsName, uom, timeSeries, seriesOptions, redraw)
  {
    if(this.chart === undefined)
    {
      this.chart = new Highcharts.Chart(this.chartConfig);
    }
    if(seriesOptions === undefined)
    {
      seriesOptions = {};
      seriesOptions.type = 'line';
      seriesOptions.name = obsName;
    }
    seriesOptions.data = timeSeries;
    //var series = [seriesOptions];
    this.addSeries([seriesOptions]);
  }
});

rcoosmapping.compareGraph = Ext.extend(Ext.Panel, {
  graphPanel : undefined,
  currentObs : undefined,
  chartParams : undefined,
  dataStore : undefined,
  constructor: function(config) 
  {    
  
    dataStore = new rcoosmapping.data.timeSeriesStore();
    this.listeners = {
                        afterrender : this.afterrender,
                        obsselected : this.obsselected
                      };    
    this.chartParams = {
      chart: {
        defaultSeriesType: 'line',
        backgroundColor : '#FFFFFF', //'#E8ECEF',
        margin: [10, 30, 40, 60]
      },
      plotOptions: {
        line: {
          //color: '#000000',
          lineWidth: 1,
          marker: {
            radius: 2
          }            
        }
      },
      title : {
        text : 'Comparison Graph',
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
        formatter: function() 
        {
          var dateVal = Date.parseDate(this.x.toString(), 'U');
          var dateOut = dateVal.format("m-d H:i:s");
          //updateTime = time.replace(' ', 'T');
          //updateTime = Date.parseDate(updateTime, "c"); 
          //updateTime = updateTime.format("m-d H:i:s");
        
          var toolTip = "Date: " + dateOut + "<br>Value: " + this.y.toFixed(2);
            
          return toolTip;
        }
      },
      legend : {
        enabled : true
      },        
      xAxis: [{
        //type: 'datetime',
        //startOnTick: true,
        endOnTick: true,
        maxPadding: 0.0,
        minPadding: 0.0,
        showLastLabel: true,
        type: 'datetime',
        /*dateTimeLabelFormats: { // don't display the dummy year
            month: '%e. %b',
            year: '%b'
        },*/
        labels: {
          //rotation: -90,
          align: 'center',
          style: {
             font: '10px tahoma,arial,helvetica,sans-serif',
             //color : '#000000'
          },
          formatter: function() {
            if(this.isFirst || this.isLast)
            {
              
               var dateVal = Date.parseDate(this.value.toString(), 'U');
               var dateOut = dateVal.format("Y-m-d<br/>H:i:s");
               return(dateOut);
              //return(this.value);
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
               //color : '#000000'
            }
        },
        labels: {
          style: {
             font: '10px tahoma,arial,helvetica,sans-serif',
             //color : '#000000'
          }
        }
      }]
    }
    rcoosmapping.compareGraph.superclass.constructor.call(this, config);
    /*this.on("obsselected", function(platformName, obsName, obsUOM, timeSeriesData)
      {
        this.addTimeSeries(platformName, obsName, obsUOM, timeSeriesData);
      },
      this
    );*/
    
  },
  chartConfig : function(chartParams)
  {
  },
  afterrender : function()
  {
    this.graphPanel = new rcoosmapping.graph({
      id : 'compareGraphPanel',
      //region : 'east',
      //layout : 'fit',
      width: this.getInnerWidth(),
      height: this.getInnerHeight(),   
      chartConfig : this.chartParams
    });
    this.add(this.graphPanel);
  },
  obsselected : function(platformName, obsName, obsUOM, timeSeriesData, rec)
  {
    var i = 0;
    //this.addTimeSeries(platformName, obsName, obsUOM, timeSeriesData);
    
  },
  addTimeSeries : function(platformName, obsName, obsUOM, timeSeriesData)
  {
    var redraw = true;
    var seriesOptions = {};
    seriesOptions.type = 'line';
    seriesOptions.name = platformName;
    if(this.graphPanel.chart === undefined)
    {
      this.graphPanel.chart = new Highcharts.Chart(this.chartConfig);
    }
    
    // if the observation is not the same as what is currently displayed, we want to redraw with the new data, removing the old.
    if(this.currentObs == undefined || this.currentObs === obsName)
    {
      if(this.currentObs == undefined)
      {
        this.graphPanel.chart.options.title.text  = obsName;
        
      }
      redraw = false;
    }
    else
    {
      var i;
      for(i = this.graphPanel.chart.series.length - 1; i >=0; i--)
      {
        this.graphPanel.chart.series[i].remove();
      }
      this.graphPanel.chart.options.title.text  =obsName;
    }
    this.currentObs = obsName;
    //When we are adding multiple series onto a graph, we need to make sure our X-axis doesn't get skewed due to one
    //time series having a higher sampling rate. We convert our time info into UTC.
    var epochDate = Date.parseDate('1970-01-01T00:00:00', 'c');
    var i;
    var categories = [];
    var timeseries = [];
    for(i = 0; i < timeSeriesData.length; i++)
    {
      //Make a copy since we need to modify the date. The data is a reference and by changing it here, we change it
      //at the originator as well.
      var time = timeSeriesData[i][0];
      var dataPt = timeSeriesData[i][1];
      timeseries.push([time,dataPt]);
      
      var time = timeseries[i][0];
      var dataTime = time.replace(' ', 'T');
      dataTime = Date.parseDate(time, "c");          
      //Convert to local time to display on xAxis.
      //categories[i] = dataTime.format("Y-m-d<br/>H:i:s");      
      //timeseries[i][0] = dataTime.getElapsed(epochDate);
      timeseries[i][0] = dataTime.format("U");
    }
    var xAxisNdx = this.graphPanel.chart.xAxis.length - 1;
    var yAxisNdx = this.graphPanel.chart.yAxis.length - 1;
    var yAxis = this.graphPanel.chart.yAxis[yAxisNdx];
    yAxis.options.title.text = obsName + '(' + obsUOM +')';
    //yAxis.axisTitle.element.textContent = obsName + '(' + obsUOM +')';
    yAxis.redraw();

    //this.graphPanel.chart.xAxis[xAxisNdx].setCategories(categories);
    this.graphPanel.addTimeSeries(obsName, obsUOM, timeseries, seriesOptions, redraw);
  }
 
});


