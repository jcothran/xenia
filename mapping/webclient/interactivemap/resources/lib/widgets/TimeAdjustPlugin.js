/**
* Copyright (c) 2008-2010 The Open Source Geospatial Foundation
* 
* Published under the BSD license.
* See http://svn.geoext.org/core/trunk/geoext/license.txt for the full text
* of the license.
*/

Ext.namespace("GeoExt.tree");

/** api: (define)
*  module = GeoExt.tree
*  class = TimeAdjustPlugin
*/

GeoExt.tree.TimeAdjustPlugin = Ext.extend(Ext.util.Observable, { 
          
    constructor: function(config) { 
        Ext.apply(this.initialConfig, Ext.apply({}, config)); 
        Ext.apply(this, config); 
        this.addEvents("timeadjustclick"); 
        GeoExt.tree.TimeAdjustPlugin.superclass.constructor.apply(this, arguments); 
    }, 
 
    init: function(tree) { 
        tree.on({ 
            "rendernode": this.onRenderNode, 
            "rawlayertimeadjustclick": this.onRawLayerTimeAdjustClick, 
            scope: this 
        }); 
    }, 
     
    onRenderNode: function(node) { 
        var a = node.attributes; 
        var layer = node.layer;
        //The layer must have timeadjust defined to add the control to the node.
        if(a.timeadjust)  { 
          var buf = [
                  /*'<span class="x-tree-node-indent">', this.indentMarkup, "</span>",*/
                  '<input type="button" class="gx-time-adjust" src="./resources/images/default/s.gif" alt=""></input>'
                ];
                       
          //Ext.DomHelper.overwrite(node.ui.iconNode, 
          //    buf.join("")); 
          //Ext.DomHelper.insertBefore(node.ui.anchor, 
          //    buf.join("")); 

        }
    }, 
    onRawLayerTimeAdjustClick: function(node, e)
    {
      var el = e.getTarget('.gx-time-adjust', 1);  
      //If the element exists, then we process the click event, otherwise do nothing.
      // A return of false will stop any other onClick handlers on the node from getting the click event.
      if(el) { 
        this.fireEvent("timeadjustclick", node);
        return(false);
      }
      return(true);
    }
 
}); 
 
Ext.preg && Ext.preg("gx_timeadjustplugin", GeoExt.tree.TimeAdjustPlugin); 
