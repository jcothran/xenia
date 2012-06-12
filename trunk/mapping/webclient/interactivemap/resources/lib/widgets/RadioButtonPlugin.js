/** 
 * Copyright (c) 2008-2009 The Open Source Geospatial Foundation 
 *  
 * Published under the BSD license. 
 * See http://svn.geoext.org/core/trunk/geoext/license.txt for the full text 
 * of the license. 
 */ 
 
Ext.namespace("GeoExt.tree"); 
	 
	GeoExt.tree.RadioButtonPlugin = Ext.extend(Ext.util.Observable, { 
	     
	    constructor: function(config) { 
	        Ext.apply(this.initialConfig, Ext.apply({}, config)); 
	        Ext.apply(this, config); 
	        this.addEvents("radiochange"); 
	        GeoExt.tree.RadioButtonPlugin.superclass.constructor.apply(this, arguments); 
	    }, 
	 
	    init: function(tree) { 
	        tree.on({ 
	            "rendernode": this.onRenderNode, 
	            "rawclicknode": this.onRawClickNode, 
	            scope: this 
	        }); 
	    }, 
	     
	    onRenderNode: function(node) { 
	        var a = node.attributes; 
	        if(a.radioGroup && !a.radio) { 
	            a.radio = Ext.DomHelper.insertBefore(node.ui.anchor, 
	                ['<input type="radio" class="gx-tree-radio" name="', 
	                a.radioGroup, '_radio"></input>'].join("")); 
	        } 
	    },
	     
	    onRawClickNode: function(node, e) { 
	        var el = e.getTarget('.gx-tree-radio', 1);  
	        if(el) { 
	            el.defaultChecked = el.checked; 
	            this.fireEvent("radiochange", node); 
	            return false; 
	        } 
	    } 
	 
	}); 
	 
	Ext.preg && Ext.preg("gx_radiobuttonplugin", GeoExt.tree.RadioButtonPlugin); 