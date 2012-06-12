/*-----------------------------------------------------------------------------------------------------------------------------*/
function typeOfEx(value) {
    var s = typeof value;
    if (s === 'object') {
        if (value) {
            if (typeof value.length === 'number' &&
                    !(value.propertyIsEnumerable('length')) &&
                    typeof value.splice === 'function') {
                s = 'array';
            }
        } else {
            s = 'null';
        }
    }
    return s;
}


/*-----------------------------------------------------------------------------------------------------------------------------*/
/*
  Base.js, version 1.1a
  Copyright 2006-2010, Dean Edwards
  License: http://www.opensource.org/licenses/mit-license.php
*/

var Base = function() {
  // dummy
};

Base.extend = function(_instance, _static) { // subclass
  var extend = Base.prototype.extend;
  
  // build the prototype
  Base._prototyping = true;
  var proto = new this;
  extend.call(proto, _instance);
  proto.base = function() {
    // call this method from any other method to invoke that method's ancestor
  };
  delete Base._prototyping;
  
  // create the wrapper for the constructor function
  //var constructor = proto.constructor.valueOf(); //-dean
  var constructor = proto.constructor;
  var klass = proto.constructor = function() {
    if (!Base._prototyping) {
      if (this._constructing || this.constructor == klass) { // instantiation
        this._constructing = true;
        constructor.apply(this, arguments);
        delete this._constructing;
      } else if (arguments[0] != null) { // casting
        return (arguments[0].extend || extend).call(arguments[0], proto);
      }
    }
  };
  
  // build the class interface
  klass.ancestor = this;
  klass.extend = this.extend;
  klass.forEach = this.forEach;
  klass.implement = this.implement;
  klass.prototype = proto;
  klass.toString = this.toString;
  klass.valueOf = function(type) {
    //return (type == "object") ? klass : constructor; //-dean
    return (type == "object") ? klass : constructor.valueOf();
  };
  extend.call(klass, _static);
  // class initialisation
  if (typeof klass.init == "function") klass.init();
  return klass;
};

Base.prototype = {  
  extend: function(source, value) {
    if (arguments.length > 1) { // extending with a name/value pair
      var ancestor = this[source];
      if (ancestor && (typeof value == "function") && // overriding a method?
        // the valueOf() comparison is to avoid circular references
        (!ancestor.valueOf || ancestor.valueOf() != value.valueOf()) &&
        /\bbase\b/.test(value)) {
        // get the underlying method
        var method = value.valueOf();
        // override
        value = function() {
          var previous = this.base || Base.prototype.base;
          this.base = ancestor;
          var returnValue = method.apply(this, arguments);
          this.base = previous;
          return returnValue;
        };
        // point to the underlying method
        value.valueOf = function(type) {
          return (type == "object") ? value : method;
        };
        value.toString = Base.toString;
      }
      this[source] = value;
    } else if (source) { // extending with an object literal
      var extend = Base.prototype.extend;
      // if this object has a customised extend method then use it
      if (!Base._prototyping && typeof this != "function") {
        extend = this.extend || extend;
      }
      var proto = {toSource: null};
      // do the "toString" and other methods manually
      var hidden = ["constructor", "toString", "valueOf"];
      // if we are prototyping then include the constructor
      var i = Base._prototyping ? 0 : 1;
      while (key = hidden[i++]) {
        if (source[key] != proto[key]) {
          extend.call(this, key, source[key]);

        }
      }
      // copy each of the source object's properties to this object
      for (var key in source) {
        if (!proto[key]) extend.call(this, key, source[key]);
      }
    }
    return this;
  }
};

// initialise
Base = Base.extend({
  constructor: function() {
    this.extend(arguments[0]);
  }
}, {
  ancestor: Object,
  version: "1.1",
  
  forEach: function(object, block, context) {
    for (var key in object) {
      if (this.prototype[key] === undefined) {
        block.call(context, object[key], key, object);
      }
    }
  },
    
  implement: function() {
    for (var i = 0; i < arguments.length; i++) {
      if (typeof arguments[i] == "function") {
        // if it's a function, call it
        arguments[i](this.prototype);
      } else {
        // add the interface using the extend method
        this.prototype.extend(arguments[i]);
      }
    }
    return this;
  },
  
  toString: function() {
    return String(this.valueOf());
  }
});



googleAnalytics = Base.extend({
  trackerId : "",
  tracker : null,
  //_gaq : [],
  
  constructor: function(trackerID) {
    this.trackerId = trackerID;    
    //this._gaq.push(['_setAccount', trackerID]);
    //this._gaq.push(['_trackPageview']);  
  },
  /*
  addGAScript : function()
  {
    var ga = document.createElement('script'); 
    ga.type = 'text/javascript'; 
    ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; 
    s.parentNode.insertBefore(ga, s);  
  },
  */
  getTracker : function()
  {
    try
    {
      if(this.trackerId.length)
      {
        this.tracker = _gat._getTracker(this.trackerId);   
        return(this.tracker);
      }
    }
    catch(err)
    {
      if (window.console !== undefined)
      {
        if(window.console.exception)
        {
          window.console.exception(err);
        }
      }
    }
    return(null);
  },
  trackEvent : function(category, action, userString, userInt)
  {
    try
    {
      this.tracker._trackEvent(category, action, userString, userInt);
      return(true);
    }
    catch(err)
    {
      if (console!==undefined  && console.exception)
      {
        console.exception(err);
      }
    }
    return(false);
  },
  recordOutboundLink : function(link, category, action) 
  {
    this.trackEvent(category, action);
    setTimeout('document.location = "' + link.href + '"', 100)
  },
  trackPageView : function()
  {
    try
    {
      this.tracker._trackPageview();
      this.tracker._setVar("<? echo $var_uservar ?>");
    }
    catch(err)
    {
      if (console!==undefined && console.exception)
      {
        console.exception(err);
      }
    }
    
  }
});
/*-----------------------------------------------------------------------------------------------------------------------------*/

function getClosestDateToHourInterval(curDate, updateInterval)
{
  var hour = parseInt(curDate.format('H'),10);
  var offset = hour % updateInterval;

  var closestDate = curDate;
  if(offset !== 0)
  {
    var offstAdjust = 0;    
    var epoch = curDate.format('U');
    var x = Math.round(updateInterval / 2);
    if(offset >= x)
    {
      offstAdjust = updateInterval - offset;
    }
    else
    {
      offstAdjust = offset * -1;
    }
    epoch += (offstAdjust * 60 * 60);
    closestDate = new Date(epoch * 1000);      
  }  
  return(closestDate);
};

function convertToGMT(dateObj)
{
  //We want to convert it to GMT.
  var offsetToGMT = dateObj.getGMTOffset(true);
  offsetToGMT = offsetToGMT.split(':');
  offsetToGMT[0] = parseInt(offsetToGMT[0],10);
  offsetToGMT[1] = parseInt(offsetToGMT[1],10);
  if(offsetToGMT[0] < 1)
  {
    offsetToGMT[0] *= -1;
  }
  //NOTE: even though I've adjusted to GMT, the Date object shows the timezone as the local time zone.
  //I think the way around this is to convert, then parse the date with the string 'Y-m-d'.... and force the 
  //GMT offset to 0 there.
  var tmp = dateObj.add(Date.HOUR, offsetToGMT[0]).add(Date.MINUTE, offsetToGMT[1]);
  var dateTime = tmp.format("Y-m-d H:i:s \\G\\M\\T");
  var GMTDateTime = Date.parseDate(dateTime, "Y-m-d H:i:s T");
  
  return(GMTDateTime);
  
};

function convertToLocalTZ(dateObj)
{
  //We want to convert it to our local TZ.
  var offsetToGMT = dateObj.getGMTOffset(true);
  offsetToGMT = offsetToGMT.split(':');
  offsetToGMT[0] = parseInt(offsetToGMT[0],10);
  offsetToGMT[1] = parseInt(offsetToGMT[1],10);
  if(offsetToGMT[0] < 1)
  {
    offsetToGMT[1] *= -1;
  }
  var localDateTime = dateObj.add(Date.HOUR, offsetToGMT[0]).add(Date.MINUTE, offsetToGMT[1]);
  
  return(localDateTime);
}

