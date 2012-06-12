Ext.namespace("rcoosmapping.data");



rcoosmapping.data.obsJsonReader = function(meta, recordType) {
  meta = meta || {};
  if(!(recordType instanceof Function)) {
      recordType = rcoosmapping.data.obsJsonRecord.create(
          recordType || meta.fields || {});
  }
  rcoosmapping.data.obsJsonReader.superclass.constructor.call(
      this, meta, recordType);
  
};


Ext.extend(rcoosmapping.data.obsJsonReader, Ext.data.JsonReader, {

  /** private: method[read]
   *  :param response: ``OpenLayers.Protocol.Response``
   *  :return: ``Object`` An object with two properties. The value of the
   *      ``records`` property is the array of records corresponding to
   *      the features. The value of the ``totalRecords" property is the
   *      number of records in the array.
   *      
   *  This method is only used by a DataProxy which has retrieved data.
   */
  read: function(response) {
      return this.readRecords(response);
  },

  /** api: method[readRecords]
   *  :param obsJson: obsJSON object containing time series data for a platform.
   *
   *  :return: ``Object``  An object with ``records`` and ``totalRecords``
   *      properties.
   *  
   *  Create a data block containing :class:`rcoosmapping.data.obsJsonRecord`
   *  objects from an array of features.
   */
  readRecords : function(obsJson) {
    var platformObsData = [obsJson]
    var recsObj = rcoosmapping.data.obsJsonReader.superclass.readRecords.call(this, platformObsData);
    return(recsObj);
  }
});