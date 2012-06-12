Ext.namespace('rcoosmapping.data');

rcoosmapping.data.ScriptTagProxy = function(config){
  Ext.apply(this, config);

  rcoosmapping.data.ScriptTagProxy.superclass.constructor.call(this, config);

  this.head = document.getElementsByTagName("head")[0];
  
};

Ext.extend(rcoosmapping.data.ScriptTagProxy, Ext.data.ScriptTagProxy, {

  callbackFuncName : undefined, //If the json files are already wrapped in a callback function, pass the name of the function in this
                                //constructor config and it will be used. Otherwise a random function name is chosen and the hosting server
                                //will have to create the function to wrap the json in.
  
  doRequest : function(action, rs, params, reader, callback, scope, arg) {
      var p = Ext.urlEncode(Ext.apply(params, this.extraParams));

      var url = this.buildUrl(action, rs);
      if (!url) {
          throw new Ext.data.Api.Error('invalid-url', url);
      }
      url = Ext.urlAppend(url, p);

      if(this.nocache){
          url = Ext.urlAppend(url, '_dc=' + (new Date().getTime()));
      }
      var transId = ++Ext.data.ScriptTagProxy.TRANS_ID;
      var trans = {
          id : transId,
          action: action,
          cb : this.callbackFuncName === undefined ? "stcCallback"+transId : this.callbackFuncName,
          scriptId : "stcScript"+transId,
          params : params,
          arg : arg,
          url : url,
          callback : callback,
          scope : scope,
          reader : reader
      };
      window[trans.cb] = this.createCallback(action, rs, trans);
      url += String.format("&{0}={1}", this.callbackParam, trans.cb);
      if(this.autoAbort !== false){
          this.abort();
      }

      trans.timeoutId = this.handleFailure.defer(this.timeout, this, [trans]);

      var script = document.createElement("script");
      script.setAttribute("src", url);
      script.setAttribute("type", "text/javascript");
      script.setAttribute("id", trans.scriptId);
      this.head.appendChild(script);

      this.trans = trans;
  },
  
});