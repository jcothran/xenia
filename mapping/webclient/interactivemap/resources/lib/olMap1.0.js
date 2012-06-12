  Ext.namespace('rcoosmapping');

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
  });
  
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

  GeoExt.Popup.prototype.getState = function()  { return null; }

 
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
    toolbarItems  : [],
    dataLayerTree : undefined,
    tileCacheURL  : '',
    mapservURL    : '',
    mapFile       : '',
    ImageType     : 'image/png',
    TileCacheMod  : '',  //Modifier for our TileCache layers. For ie6 we use a specific layer to avoid the png transparency issue.
    nfoPopup      : undefined,
    obsInfoControls : [],
    layerStore      : undefined,
    initGFISelect   : false,
    helpWindow      : undefined,
    mapLegendURL  : '',
    googAnalytics : undefined,
       
    createPanel : function(titleString) 
    {         
      this.layout = 'border';
      this.title = titleString;
      this.hideMode = 'offsets';
      this.autoScroll = true;
      this.draggable = false;
      this.add({
        id: 'westPanel',
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
        id: 'mapPanel',
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
      id: 'legendPanel',
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
    
    createLayer : function(layerType, name, url, params, options) 
    {
      var layer = null
      if(layerType == "OpenLayers.Layer.WMS")
      {
        var layer = new OpenLayers.Layer.WMS(name, url, params, options);
      }
      else if(layerType == "OpenLayers.Layer.Google")
      {
        layer = new OpenLayers.Layer.Google(name, options);
      }
      else if(layerType == "OpenLayers.Layer.XYZ")
      {
        layer = new OpenLayers.Layer.XYZ(name, options);
      }
      else if(layerType == "OpenLayers.Layer.Vector")
      {
        layer = new OpenLayers.Layer.Vector(name, options);
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
            layers: [layer],
            queryVisible: true,
            maxFeatures: 1,
            vendorParams: {map: this.secooraMapFile}
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
    
    addLayers : function()
    {
      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      //Base Layers
      //(layerType, name, url, params, options)
      var layer = this.createLayer( "Google",
                        "Google Terrain", 
                        null,
                        null,
                        { 
                          sphericalMercator: true,
                          type: G_PHYSICAL_MAP,
                          MIN_ZOOM_LEVEL: 6,
                          MAX_ZOOM_LEVEL: 15,
                          displayInLayerSwitcher: true,
                          GROUP : 'BaseMap'
                        });
      this.olMap.addLayer(layer);                                  
    },
    addLayersFromConfig : function(configParams)
    {
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
                  "radiochange": function(node) { 
                    var olMap = node.layer.map;
                    var len = olMap.controls.length;
                    //Run through all the controls on the olMap, then for the layers associated with that control figure 
                    //out if it is the layer the user just enabled to do a getfeature query on. We enable the layer while
                    //disabling all other layer's getfeature info queries.
                    for(var i = 0; i < len; i++)
                    {
                      var control = olMap.controls[i];
                      if(control.layers != undefined)
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
    getLayerIndexMinMaxForGroup : function(group)
    {
      var zNdxes = [];
      var min = -1;
      var max = -1;
      for(var i = 0; i < this.olMap.layers.length; i++)
      {
        var layer = this.olMap.layers[i];
        if(layer.options != undefined && layer.options.GROUP != undefined && layer.options.GROUP == group)
        {
          var val = this.olMap.getLayerIndex(layer);
          if(min == -1 || val < min)
          {
            min = val;
          }
          if(max == -1 || val > max)
          {
            max = val;
          }
        }
      }
      zNdxes.push(min);
      zNdxes.push(max);
      return(zNdxes);
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
      var lonlat = mapObj.getLonLatFromViewPortPx(event.xy);
      //Get the map panel.
      var panelTitle = this.title + 'OLMap';
      var mapPanel = this.findById(panelTitle);
      
      
      /*this.nfoPopup = new gfiPopup(
      {
        id: 'FeaturePopup',
        map: mapPanel,
        title: "Feature Information",
        autoScroll: true,
        lonlat: lonlat,
        html: event.text,
        width: 500,
        height: 300,
        collapsible: true,
        anchored: true,
        ctCls: ctCls      
      });*/
      
      
      //Add a div in where we will place the graph once the Ajax call below comes back with a geoJson object.
      //this.nfoPopup = new GeoExt.PopupTst(
      this.nfoPopup = new GeoExt.Popup(
        {
          id: 'FeaturePopup',
          //map: mapObj,
          map: mapPanel,
          title: "Feature Information",
          autoScroll: true,
          lonlat: lonlat,
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
      if(this.nfoPopup != null) 
      {
        this.nfoPopup.close();
        this.nfoPopup = null;
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
    init : function() 
    {
      //OpenLayers.ProxyHost="http://carolinasrcoos.org/cgi-bin/AjaxProxy.php?url=";
      OpenLayers.ProxyHost= "http://rcoos.org/carolinasrcoosrev2/cgi-bin/AjaxProxy.php?url=";
      this.tileCacheURL   = 'http://129.252.139.124/tilecache/tilecache.py?';
      this.mapservURL     = 'http://129.252.139.124/cgi-bin/mapserv?';
      this.secooraMapFile = '/home/xeniaprod/mapping/secoora/SecooraObs.map';
      this.generalMapFile = '/home/xeniaprod/mapping/common/general.map';
      this.ImageType      = 'image/png';      
    
      var melrLL = rcoosmapping.utils.reprojectPoint("EPSG:4326","EPSG:900913",-90.5,24.5);
      var melrUR = rcoosmapping.utils.reprojectPoint("EPSG:4326","EPSG:900913",-60.5,37.2);
      var relrLL = rcoosmapping.utils.reprojectPoint("EPSG:4326","EPSG:900913",-83.156,31.025);
      var relrUR = rcoosmapping.utils.reprojectPoint("EPSG:4326","EPSG:900913",-69.543,37.117);
      
      var mapOptions= {
                    maxExtent: new OpenLayers.Bounds(melrLL.lon,melrLL.lat, melrUR.lon,melrUR.lat),          
                    numZoomLevels: 9,
                    maxResolution: 2445.984904688,
                    resolutions: [2445.984904688,1222.992452344,611.496226172,305.748113086,152.874056543,76.437028271,38.218514136,19.109257068,9.554628534,4.777314267,2.388657133,1.194328567,0.59716428337097171575,0.298582142],
                    projection: new OpenLayers.Projection("EPSG:900913"),
                    displayProjection: new OpenLayers.Projection("EPSG:4326"),
                    units: "degrees",           
                    controls: [new OpenLayers.Control.MouseDefaults(),
                               new OpenLayers.Control.MousePosition({numdigits:2}),                
                               new OpenLayers.Control.PanZoomBar(),
                               new OpenLayers.Control.Permalink('permalink'),                         
                               new OpenLayers.Control.ScaleLine()
                               ]
                  };
      
                            
      this.createMap(mapOptions);
      this.createToolbar('rtmap');
      this.createLayerTree("Real Time Layers");     
      this.addLayers();            
      this.populateLayerTree(this.olMap.layers);     
      this.layerStore = new GeoExt.data.LayerStore({
        map: this.olMap,
        layers: this.olMap.layers,
        initDir: GeoExt.data.LayerStore.MAP_TO_STORE
      });
      
    }
    
  });
