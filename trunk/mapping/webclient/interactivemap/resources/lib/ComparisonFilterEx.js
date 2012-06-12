OpenLayers.Filter.ComparisonEx = OpenLayers.Class(OpenLayers.Filter.Comparison, {

  /** 
   * Constructor: OpenLayers.Filter.Comparison
   * Creates a comparison rule.
   *
   * Parameters:
   * options - {Object} An optional object with properties to set on the
   *           rule
   * 
   * Returns:
   * {<OpenLayers.Filter.Comparison>}
   */
  initialize: function(options) {
      OpenLayers.Filter.Comparison.prototype.initialize.apply(this, [options]);
  },

  /**
   * APIMethod: getAttribute
   * recursively calls itself to get the property. 
   * 
   * Parameters:
   * context - {Object} Context to use in evaluating the filter.  If a vector
   *     feature is provided, the feature.attributes will be used as context.
   * propertyHierarchy - An array of the hierarchy we are searching for. Externally when setting the 
   *  property value, the format is "Grandparent.parent.child".
   * gots is the array of property values found.
   * 
   * Returns:
   * {Boolean} The filter applies.
   */
  getAttribute : function(context, propertyHierarchy, gots)  
  {
    //r gots = [];
    var key = propertyHierarchy[0];
    if(typeOfEx(context[key]) == 'object')
    {
      var property = propertyHierarchy.slice(1, propertyHierarchy.length);
      this.getAttribute(context[key], property, gots); 
    }
    else if(typeOfEx(context[key]) == 'array')
    {
      var property = propertyHierarchy.slice(1, propertyHierarchy.length);
      for(var i = 0; i < context[key].length; i++)
      {
        this.getAttribute(context[key][i], property, gots);
      }
    }
    else
    {
      gots.push(context[key]);
    }
  },
  /**
   * APIMethod: evaluate
   * Evaluates this filter in a specific context.
   * 
   * Parameters:
   * context - {Object} Context to use in evaluating the filter.  If a vector
   *     feature is provided, the feature.attributes will be used as context.
   * 
   * Returns:
   * {Boolean} The filter applies.
   */
  evaluate: function(context) {
      if (context instanceof OpenLayers.Feature.Vector) {
          context = context.attributes;
      }
      var result = false;
      var propertyHierarchy = this.property.split('.');
      var gots = [];
      this.getAttribute(context, propertyHierarchy, gots);
      for(var i = 0; i < gots.length; i++)
      {
        var got = gots[i];
        switch(this.type) {
            case OpenLayers.Filter.Comparison.EQUAL_TO:
                var exp = this.value;
                if(!this.matchCase &&
                   typeof got == "string" && typeof exp == "string") {
                    result = (got.toUpperCase() == exp.toUpperCase());
                } else {
                    result = (got == exp);
                }
                break;
            case OpenLayers.Filter.Comparison.NOT_EQUAL_TO:
                var exp = this.value;
                if(!this.matchCase &&
                   typeof got == "string" && typeof exp == "string") {
                    result = (got.toUpperCase() != exp.toUpperCase());
                } else {
                    result = (got != exp);
                }
                break;
            case OpenLayers.Filter.Comparison.LESS_THAN:
                result = got < this.value;
                break;
            case OpenLayers.Filter.Comparison.GREATER_THAN:
                result = got > this.value;
                break;
            case OpenLayers.Filter.Comparison.LESS_THAN_OR_EQUAL_TO:
                result = got <= this.value;
                break;
            case OpenLayers.Filter.Comparison.GREATER_THAN_OR_EQUAL_TO:
                result = got >= this.value;
                break;
            case OpenLayers.Filter.Comparison.BETWEEN:
                result = (got >= this.lowerBoundary) &&
                    (got <= this.upperBoundary);
                break;
            case OpenLayers.Filter.Comparison.LIKE:
                var regexp = new RegExp(this.value, "gi");
                result = regexp.test(got);
                break;
        }
        if(result == true)
        {
          break;
        }
      }
      return result;
  }

});
