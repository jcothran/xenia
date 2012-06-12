Ext.namespace("rcoosmapping.data");

/*
rcoosmapping.data.threadsWMSXMLRec = Ext.data.Record.create([
  
]);
*/
rcoosmapping.data.GFIProxy = function(config){  
  Ext.apply(this, config);

  rcoosmapping.data.GFIProxy.superclass.constructor.call(this, config);
 
};

Ext.extend(rcoosmapping.data.GFIProxy, Ext.data.HttpProxy, {

  proxyUrl : undefined, 
  
  doRequest : function(action, rs, params, reader, callback, scope, options) {
      if (!url) {
          throw new Ext.data.Api.Error('invalid-url', url);
      }
      var dataUrl = encodeURIComponent(this.url);
      this.url = Ext.urlAppend(this.proxyUrl, dataUrl);
      
      var connection = this.getConnection();
      connection.url = this.url;
  }
  
});


rcoosmapping.data.threadsWMSXMLReader = function(meta, recordType){
    meta = meta || {};

    // backwards compat, convert idPath or id / success
    Ext.applyIf(meta, {
        idProperty: meta.idProperty || meta.idPath || meta.id,
        successProperty: meta.successProperty || meta.success
    });

    rcoosmapping.data.threadsWMSXMLReader.superclass.constructor.call(this, meta, recordType || meta.fields);
    
    if(meta.headerFields)
    {
      this.headerRecordType = Ext.data.Record.create(meta.headerFields);     
      this.headerExtractors = []
      for(var i = 0; i < meta.headerFields.length; i++)
      {
        this.headerExtractors.push(this.createAccessor(meta.headerFields[i].name));
      }
    }
};
/*
  ExtJS readers operate on arrays/lists of data, so  for this reader we setup the data fields 
  in the fields configuration since that is a series of data. In the thredds case the XML tag <FeatureInfo>.
  However since we want to use a similar record to represent data throught the project, we also want to get the 
  "header" data out of the XML which gives us the location, and possibly other data that is not in the <FeatureInfo> tags.
  We create another fields definition in the configuration labeled "headerFields" where we detail out what we're searching for
  there.
*/
Ext.extend(rcoosmapping.data.threadsWMSXMLReader, Ext.data.XmlReader, {
    headerExtractors : undefined,
    uom : undefined,
    
    read : function(response){
        var doc = response.responseXML;
        if(!doc) {
            throw {message: "XmlReader.read: XML Document not available"};
        }
        return this.readRecords(doc);
    },

    /**
     * Create a data block containing Ext.data.Records from an XML document.
     * @param {Object} doc A parsed XML document.
     * @return {Object} records A data block which is used by an {@link Ext.data.Store} as
     * a cache of Ext.data.Records.
     */
    readRecords : function(doc){
      //recs = rcoosmapping.data.threadsWMSXMLReader.superclass.readRecords.call(this, doc);
      /**
       * After any data loads/reads, the raw XML Document is available for further custom processing.
       * @type XMLDocument
       */
      this.xmlData = doc;

      var root    = doc.documentElement || doc,
          q       = Ext.DomQuery,
          totalRecords = 0,
          success = true;

      if(this.meta.totalProperty){
          totalRecords = this.getTotal(root, 0);
      }
      if(this.meta.successProperty){
          success = this.getSuccess(root);
      }
      //Call extract data with the return record flag set as false.
      //We want to create a return record similar to our obsJson records. We get
      //an array of the entries, then we can build the record.
      var records = this.extractData(q.select(this.meta.record, root), false); 
      //Build the geometryCoords based on the Lat/Lon in the XML.
      var geometryCoords = [];
      var times = [];
      var values = [];
      //We pick out the actual location from the "header" data in the XML here. 
      if(this.headerExtractors.length)
      {
        var headerValues = {};
        var headerFields       = this.headerRecordType.prototype.fields,
            headerFieldsItems  = headerFields.items,
            headerFieldsLen    = headerFields.length;
        
        for(var i =0; i < headerFieldsLen; i++)
        {
          var finder = headerFieldsItems[i];
          var val = this.headerExtractors[i](root);
          headerValues[finder.name] = finder.convert((val !== undefined) ? val : finder.defaultValue, root);
        }
        
        var keys = Object.keys(records);
        for(i = 0; i < keys.length; i++)
        {
          var key = keys[i];
          times.push(records[key].time);
          values.push(records[key].value);
          geometryCoords.push([parseFloat(headerValues['longitude'],10),parseFloat(headerValues['latitude'],10)]);
        }
      }
      var obsJson = {};
      obsJson['type'] = headerValues['type'];
      obsJson['geometryType'] = headerValues['geometryType'];
      obsJson['geometryCoords'] = geometryCoords;
      obsJson['obsType'] = headerValues['obsType'];
      obsJson['uomType'] = headerValues['uomType'];
      obsJson['times'] = times;
      obsJson['values'] = values;
      
      var obsRecord = new rcoosmapping.data.obsTimeSeriesRecord.create([      
        {name : "type", mapping : "type"},
        {name : "geometryType", mapping : "geometryType"}, 
        {name : "geometryCoords", mapping : "geometryCoords"},
        {name : "obsType", mapping : "obsType"},
        {name : "uomType", mapping : "uomType"},
        {name : "times", mapping : "times"},
        {name : "values", mapping : "values"},
        {name : "sorder", mapping : "sorder", defaultValue : 1},
        {name : "qc_levels", mapping : "qc_level"}
      ]);
      
      var timeSeriesRec = new obsRecord(
        {
          data: obsJson
        });
      
      return {
          success : success,
          records : timeSeriesRec,
          totalRecords : 1
      };
      
    },
    
    /*
    extractValues : function(data, items, len) {
      values = rcoosmapping.data.threadsWMSXMLReader.superclass.extractValues.call(this, data, items, len);
      var i = 0;
    }
    */
    

});