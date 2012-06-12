Ext.BLANK_IMAGE_URL = './resources/images/default/s.gif';


Ext.namespace('rcoosmapping');

GeoExt.Popup.prototype.getState = function()  { return null; }
Ext.override(Ext.data.Connection, {


	request : function(o){
        if(this.fireEvent("beforerequest", this, o) !== false){
            var p = o.params;

            if(typeof p == "function"){
                p = p.call(o.scope||window, o);
            }
            if(typeof p == "object"){
                p = Ext.urlEncode(p);
            }
            if(this.extraParams){
                var extras = Ext.urlEncode(this.extraParams);
                p = p ? (p + '&' + extras) : extras;
            }

            var url = o.url || this.url;
            if(typeof url == 'function'){
                url = url.call(o.scope||window, o);
            }

            if(o.form){
                var form = Ext.getDom(o.form);
                url = url || form.action;

                var enctype = form.getAttribute("enctype");
                if(o.isUpload || (enctype && enctype.toLowerCase() == 'multipart/form-data')){
                    return this.doFormUpload(o, p, url);
                }
                var f = Ext.lib.Ajax.serializeForm(form);
                p = p ? (p + '&' + f) : f;
            }

            var hs = o.headers;
            if(this.defaultHeaders){
                hs = Ext.apply(hs || {}, this.defaultHeaders);
                if(!o.headers){
                    o.headers = hs;
                }
            }

            var cb = {
                success: this.handleResponse,
                failure: this.handleFailure,
                scope: this,
                argument: {options: o},
                timeout : this.timeout
            };

            var method = o.method||this.method||(p ? "POST" : "GET");

            if(method == 'GET' && (this.disableCaching && o.disableCaching !== false) || o.disableCaching === true){
                url += (url.indexOf('?') != -1 ? '&' : '?') + '_dc=' + (new Date().getTime());
            }

            if(typeof o.autoAbort == 'boolean'){ // options gets top priority
                if(o.autoAbort){
                    this.abort();
                }
            }else if(this.autoAbort !== false){
                this.abort();
            }
            if((method == 'GET' && p) || o.xmlData || o.jsonData){
                url += (url.indexOf('?') != -1 ? '&' : '?') + p;
                p = '';
            }
            if (o.scriptTag) {
               this.transId = this.scriptRequest(method, url, cb, p, o);
            } else {
               this.transId = Ext.lib.Ajax.request(method, url, cb, p, o);
            }
            return this.transId;
        }else{
            Ext.callback(o.callback, o.scope, [o, null, null]);
            return null;
        }
    },
    
    scriptRequest : function(method, url, cb, data, options) {
        var transId = ++Ext.data.ScriptTagProxy.TRANS_ID;
        var trans = {
            id : transId,
            cb : options.callbackName || "stcCallback"+transId,
            scriptId : "stcScript"+transId,
            options : options
        };
        if(data !== undefined)
        {
          url += (url.indexOf("?") != -1 ? "&" : "?") + data + String.format("&{0}={1}", options.callbackParam || 'callback', trans.cb);
        }
        else
        {
          url += (url.indexOf("?") != -1 ? "" : "?") + String.format("&{0}={1}", options.callbackParam || 'callback', trans.cb);
        }
        var conn = this;
        window[trans.cb] = function(o){
            conn.handleScriptResponse(o, trans);
        };

//      Set up the timeout handler
        trans.timeoutId = this.handleScriptFailure.defer(cb.timeout, this, [trans]);

        var script = document.createElement("script");
        script.setAttribute("src", url);
        script.setAttribute("type", "text/javascript");
        script.setAttribute("id", trans.scriptId);
        document.getElementsByTagName("head")[0].appendChild(script);

        return trans;
    },

    handleScriptResponse : function(o, trans){
        this.transId = false;
        this.destroyScriptTrans(trans, true);
        var options = trans.options;
        
//      Attempt to parse a string parameter as XML.
        var doc;
        if (typeof o == 'string') {
            if (window.ActiveXObject) {
                //var doc = new ActiveXObject("Microsoft.XMLDOM");
                doc = new ActiveXObject("Microsoft.XMLDOM");
                doc.async = "false";
                doc.loadXML(o);
            } else {
                //var doc = new DOMParser().parseFromString(o,"text/xml");
                doc = new DOMParser().parseFromString(o,"text/xml");
            }
        }

//      Create the bogus XHR
        response = {
            responseObject: o,
            responseText: (typeof o == "object") ? Ext.util.JSON.encode(o) : String(o),
            responseXML: doc,
            argument: options.argument
        };
        this.fireEvent("requestcomplete", this, response, options);
        Ext.callback(options.success, options.scope, [response, options]);
        Ext.callback(options.callback, options.scope, [options, true, response]);
    },
    
    handleScriptFailure: function(trans) {
        this.trans = false;
        this.destroyScriptTrans(trans, false);
        var options = trans.options;
        response = {
        	argument:  options.argument
        };
        this.fireEvent("requestexception", this, response, options, new Error("Timeout"));
        Ext.callback(options.failure, options.scope, [response, options]);
        Ext.callback(options.callback, options.scope, [options, false, response]);
    },
    
    // private
    destroyScriptTrans : function(trans, isLoaded){
        document.getElementsByTagName("head")[0].removeChild(document.getElementById(trans.scriptId));
        clearTimeout(trans.timeoutId);
        if(isLoaded){
            window[trans.cb] = undefined;
            try{
                delete window[trans.cb];
            }catch(e){}
        }else{
            // if hasn't been loaded, wait for load to remove it to prevent script error
            window[trans.cb] = function(){
                window[trans.cb] = undefined;
                try{
                    delete window[trans.cb];
                }catch(e){}
            };
        }
    }
});



/*rcoosmapping.hfRadarObj  = Ext.extend(rcoosmapping.platformObj,
{
  wmsLayer : null,
  
  constructor: function(config) 
  {    
    rcoosmapping.hfRadarObj.superclass.constructor.call(this, config);
  },
  
    Function: initialize
    Purpose: Setups of the data to be displayed and queried on the map.
    Parameters: An object containing the following paramsters:    
      platforms - GeoJSON Object describing the platform.
      lookups - GeoJSON object used to lookup IDs of aspects platform metadata such as observation types. The use of the lookup table
        allows the overall size of the GeoJSON object to be reduced since we are not repeating strings over and over in the platform object. 
        They are described by an id that can then be looked up.
      layerName - The name of the layer.
      layerOptions - The options to be used on the layer.
      map - the initialized OpenLayers.Map object the layer and controls will be added to.
      layerZOrder - Integer intended to be used to enabled sorting layers for display.
      layerActive - Boolean that specifies if the layer selectFeature control is to initially be active.
  //initialize : function(platforms, lookups, layerName, layerOptions, map, layerZOrder, layerActive)
  initialize : function(configObject)
  {
    this.data = configObject.lookups;
    //this.createFeatures(configObject.platforms);
    this.createLayer(configObject.layerName, configObject.layerOptions, configObject.map, configObject.layerZOrder);
    this.createSelectFeature(configObject.map, this.layer, configObject.layerActive);
  }
});*/




rcoosmapping.secooraOLMap = Ext.extend(rcoosmapping.olMap,
{
  hfradarPlatforms : null,
  insituPlatforms : null,
  
  constructor: function(config) 
  {    
    rcoosmapping.secooraOLMap.superclass.constructor.call(this, config);
  },
  addLayers : function(configParams)
  {
    rcoosmapping.secooraOLMap.superclass.addLayers.call(this, configParams);
    var i;
    for(i = 0; i < this.olMap.layers.length; i++)
    {
      if(this.olMap.layers[i].name == "Real Time Observations")
      {
        this.insituPlatforms = this.olMap.layers[i];
      }
    }
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
            var layer = undefined;
            var layerConfig = layerParams.children[layerName];        
            if(layerConfig.type == "rcoosmapping.kmlLayer")
            {
              layerConfig.options.map = this.olMap;
              layer = new rcoosmapping.kmlLayer(layerName, layerConfig.options);
              layer.setGoogleAnalytics(this.googAnalytics);
            }
            else if(layerConfig.type == "rcoosmapping.kmlHurricaneTrackLayer")
            {
              layerConfig.options.map = this.olMap;
              layer = new rcoosmapping.kmlHurricaneTrackLayer(layerName, layerConfig.options);
              layer.setGoogleAnalytics(this.googAnalytics);
            }            
            if(layer != undefined)
            {
              this.olMap.addLayer(layer);
            }
          }
        }
      }
    }
  },

  getJsonData : function(jsonURL, scriptTag, callbackName, funcSuccess, funcFail, extraParams)
  {
    //var url = OpenLayers.ProxyHost + jsonURL;
    //Ext.Ajax.on('beforerequest', this.showSpinner, this);
    //Ext.Ajax.on('requestcomplete', this.hideSpinner, this);
    //Ext.Ajax.on('requestexception', this.hideSpinner, this);
    Ext.Ajax.request({
       url: jsonURL,
       scriptTag: scriptTag,
       callbackName: callbackName,
       success: funcSuccess,
       failure: funcFail,
       scope: this,
       extraParams: extraParams
    });  
  },
  ajaxQueryFail : function(response, options)
  {
    if(options.extraParams !== undefined && options.extraParams.errorMsg !== undefined)
    {
      alert(options.extraParams.errorMsg);      
    }
    else
    {
      alert("Failed to retrieve requested data.");      
    }
    return;    
  },
  queryJSONLayerSuccess : function(response, options) 
  {
    //
    var jsonObject = Ext.util.JSON.decode(response.responseText);
    var i = 0;
    //The json object is structured as follows:
    //A lookups object that acts as a lookup table for things like observation names, organization names ect. In the geoJson features we save
    //the integer IDs instead of strings to reduce the json object size.
    //Next is a layers object that describes each layer.
    //It's structure is:
    //layers
    //   -layer type
    //     -layer name
    //       -layeroptions
    //       -other layer specific objects
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
                this.insituPlatforms = new rcoosmapping.platformVectorLayer("Real Time Observations", { 
                                                platforms : features,
                                                lookups : this.lookupTable, 
                                                layerName : "Real Time Observations", 
                                                layerOptions : {
                                                   GROUP : "InSitu",
                                                   visibility:true,
                                                   QUERYABLE: true
                                                },
                                                map: this.olMap,
                                                layerZOrder : 1,
                                                layerActive : true,
                                                googAnalytics : this.googAnalytics
                                                });
                /*this.insituPlatforms.initialize({ 
                                                platforms : features,
                                                lookups : this.lookupTable, 
                                                layerName : "Real Time Observations", 
                                                layerOptions : {
                                                   GROUP : "InSitu",
                                                   visibility:true,
                                                   QUERYABLE: true
                                                },
                                                map: this.olMap,
                                                layerZOrder : 1,
                                                layerActive : true,
                                                googAnalytics : this.googAnalytics
                                                });*/
                this.addLayerToTreeNode(this.insituPlatforms);
                
              }
              /*else if(layerName == 'radar')
              {
                //Get the geoJson object describing the features/platforms.
                var features = jsonObject.layers[layerType][layerName].features;
                this.insituPlatforms = new rcoosmapping.platformObj();
                //(platforms, lookups, layerName, layerOptions, map, layerZOrder, layerActive)
                this.hfrPlatforms.initialize(features,
                                                this.lookupTable, 
                                                "Surface Currents", 
                                                {
                                                   GROUP : "In-Situ",
                                                   visibility:true,
                                                   QUERYABLE: true
                                                },
                                                this.olMap,
                                                1,
                                                true);
              }*/
            }
          }
        }
        this.createFilterPanel();
      }
      else
      {
        alert("Layers are not present in the JSON configuration object.");
        return;
      }
    }
    else
    {
        alert("Lookups are not present in the JSON configuration object.");
        return;
    }
    //this.populateLayerTree(this.olMap.layers);  
    //The following code refreshes the tree. Currently GeoExt relies on ExtJS v2.x and the setRootNode function
    //of the TreePanel(this.dataLayerTree) does not correctly refresh the tree.
    /*this.dataLayerTree.innerCt.update(''); 
    this.dataLayerTree.root.render();
    if(!this.dataLayerTree.rootVisible)
    {
      this.dataLayerTree.root.renderChildren();
    }*/      
  },   
  treeNodeCheckChange : function(node, checked)  
  {
    /*if(node.layer.name == "Surface Currents")
    {
      this.platforms.setFeatureTypeVisibility( 'radar', checked);
    }*/
    if(this.googAnalytics !== undefined && checked)
    {
      if(this.mapInited === true)
      {
        this.googAnalytics.trackEvent("Interactive Map Layers", "Click", node.layer.name);
      }
    }
    if(node.layer.name == "Real Time Observations" && checked == false)
    {
      var i = 0;
    }
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
        group: groupName,
        enableToggle: true,
        tooltip: 'Zoom to full extent of the map.',
        tooltipType: 'title'
    });

    this.toolbarItems.push(action);

    createSeparator(this.toolbarItems);

    action = new GeoExt.Action({
        control: new OpenLayers.Control.ZoomBox(
        ),
        toggleHandler : function(actionObj, checked) {
          if(this.insituPlatforms !== null)
          {
            if(checked)
            {
              this.insituPlatforms.enableToolTips(false);
            }
            else
            {
              this.insituPlatforms.enableToolTips(true);
            }
          }
          
        },
        //text: 'Zoom In',
        scope: this,        
        map: this.olMap,
        iconCls: 'zoomin',
        toggleGroup: groupName,
        enableToggle: true,
        tooltip: 'Zoom in: click in the olMap or use the left mouse button and drag to create a rectangle',
        tooltipType: 'title'
    });

    this.toolbarItems.push(action);

    //We use the activate/deactive events to enable/disable the tooltips on the platforms while the user tries to zoom in.
    action = new GeoExt.Action({
        control: new OpenLayers.Control.ZoomBox({
            out: true
        }),
        toggleHandler : function(actionObj, checked) {
          if(this.insituPlatforms !== null)
          {
            if(checked)
            {
              this.insituPlatforms.enableToolTips(false);
            }
            else
            {
              this.insituPlatforms.enableToolTips(true);
            }
          }          
        },
        scope: this,
        map: this.olMap,
        iconCls: 'zoomout',
        toggleGroup: groupName,
        enableToggle: true,
        tooltip: 'Zoom out: click in the olMap or use the left mouse button and drag to create a rectangle',
        tooltipType: 'title'
    });

    this.toolbarItems.push(action);

    //We use the activate/deactive events to enable/disable the tooltips on the platforms while the user tries to zoom out.
    action = new GeoExt.Action({
        control: new OpenLayers.Control.DragPan({
            isDefault: false
        }),
        map: this.olMap,
        iconCls: 'pan',
        toggleGroup: groupName,
        enableToggle: true,
        tooltip: 'Pan olMap: keep the left mouse button pressed and drag the olMap',
        tooltipType: 'title'
    });

    this.toolbarItems.push(action);

    createSeparator(this.toolbarItems);
       
    action = new Ext.Action({
        //control: new OpenLayers.Control.WMSGetFeatureInfo({
        //    isDefault: true
        //}),
        handler: function(){
              if(this.insituPlatforms !== null)
              {              
                this.focus();
              }
            },
        scope: this,
        //map: this.olMap,
        iconCls: 'info',
        toggleGroup: groupName,
        enableToggle: true,
        tooltip: 'For layers with querying ability, this issues a request for the data',
        tooltipType: 'title'
    });

    this.toolbarItems.push(action);

    createSeparator(this.toolbarItems);
    action = new Ext.Action({
        tooltip: 'General Map Help',
        handler: function()
        {
          window.open('./maphelp.html');
        },
        iconCls: 'help',
        scope: this,
        tooltip: 'Launch the help window',
        tooltipType: 'title'
    });
    this.toolbarItems.push(action);
  },
  init : function(dataServerIP,mapservIP,tilecacheIP,configParams) 
  {
  
    rcoosmapping.secooraOLMap.superclass.init.call(this, dataServerIP,mapservIP,tilecacheIP,configParams);
  }
});


rcoosmapping.app = function() {
  this.viewport;
  this.mapTabs;
  this.dataServerIP;
  this.mapservIP;
  this.tilecacheIP;
  this.googAnalytics;
  return {    
    processConfig : function(response, options)
    {

      var jsonObject = Ext.util.JSON.decode(response.responseText);

      this.googAnalytics = new googleAnalytics(jsonObject.googleAnalyticsKey);
      if(this.googAnalytics.getTracker() !== null)
      {
        //Track the page view
        this.googAnalytics.trackPageView();
      }

      var mapTabs = jsonObject.tabs;
      
      
      
      var len = mapTabs.length;
      var i;      
      var tabs = [];
      for(i = 0; i < len; i++)
      {        
        var tabOptions = mapTabs[i];
        var mapObj = new rcoosmapping.secooraOLMap();
        mapObj.setAnalytics(this.googAnalytics);
        tabOptions.googAnalytics = this.googAnalytics;
        tabOptions.proxyHost = jsonObject.serverSettings.proxyHost;
        mapObj.init(this.dataServerIP,this.mapservIP,this.tilecacheIP, tabOptions);
        mapObj.createPanel(tabOptions.name);
        tabs.push(mapObj);
        if(i == 0)
        {
          var point = rcoosmapping.utils.reprojectPoint(tabOptions.mapConfig.displayProjection,
                                                         tabOptions.mapConfig.projection, 
                                                         tabOptions.mapConfig.mapExtents.centerMapOn.lon,
                                                         tabOptions.mapConfig.mapExtents.centerMapOn.lat);
        
          mapObj.setCenter(point);          
        }
        mapObj.mapInitialized(true);          
        
      }
      this.mapTabs = new Ext.TabPanel({            
        region: 'center',
        activeTab: 0,
        deferredRender: false,
        items: tabs
      });
      this.viewport = new Ext.Viewport({
          cls: 'map-panel',
          layout:'border',
          items:[
            new Ext.BoxComponent({ // raw
                region: 'north',
                el: 'header',
                style: 'background-color: #FFFFFF;'
              }),             
            {
              region: 'center',
              layout: 'border',
              items: [this.mapTabs]
            }
          ]
      });
      

      this.mapTabs.on({
        tabchange: function(panel,tab)
        {
          //Run through the tabs and close any open popups.
          var i;
          for(i = 0; i < panel.items.length; i++)
          {
            var curTab = panel.items.get(i);
            curTab.clearPopup();
          }
        }
      });          
    },
    
    init: function(dataServerIP,mapservIP,tilecacheIP,jsonLayerCfgFile) {   
      //Create the googleAnalytics object. We use it to track page view as well as other events such as what layer the user choose or platform
      //the user clicks on.
      this.dataServerIP = dataServerIP;
      this.mapservIP = mapservIP;
      this.tilecacheIP = tilecacheIP;
      
      var url = jsonLayerCfgFile;
      Ext.Ajax.request({
         url: url,
         scriptTag: true,
         callbackName: "map_config_callback",
         success: this.processConfig,
         failure: function(response, options)
         {
            alert("Unable to retrieve the configuration data to setup the map. Cannot continue.");
            return;
         },
         scope: this
      });      
    }    
  }
}(); // end of app
