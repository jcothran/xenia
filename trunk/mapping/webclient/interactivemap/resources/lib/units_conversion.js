(function () {
    var table = {};

    window.unitConverter = function (value, unit) {
        this.value = value;
        if (unit) {
            this.currentUnit = unit;
        }
    };
    unitConverter.prototype.as = function (targetUnit) {
        this.targetUnit = targetUnit;
        return this;
    };
    unitConverter.prototype.is = function (currentUnit) {
        this.currentUnit = currentUnit;
        return this;
    };

    unitConverter.prototype.val = function () {
        var val;
        var target;
        var current;
        var flipMultiplier = false;
        var curUnit = escape(this.currentUnit);
        var tarUnit = escape(this.targetUnit);
        //Figure out if we are going from a base unit to a target or vice versa.
        if(table[this.targetUnit] != undefined)
        {
          current = table[tarUnit];
          target = current[curUnit];
          current = current[tarUnit];
        }
        else
        {
          current = table[curUnit];
          target = current[tarUnit];
          current = current[curUnit];
          flipMultiplier = true;
        }
        //if (target.base != current.base) {
        //    throw new Error('Incompatible units; cannot convert from "' + this.currentUnit + '" to "' + this.targetUnit + '"');
        //}
        if(target.conversionFunc == undefined)
        {
          if(flipMultiplier)
          {
            val =  this.value * (target.multiplier / current.multiplier);
          }
          else
          {
            val =  this.value * (current.multiplier / target.multiplier);
          }
        }
        else
        {
          var func = target.conversionFunc.replace('{value}', this.value);;
          val = eval(func);
        }        
        return(val);
    };
    unitConverter.prototype.toString = function () {
        return this.val() + ' ' + this.targetUnit;
    };
    unitConverter.prototype.debug = function () {
        return this.value + ' ' + this.currentUnit + ' is ' + this.val() + ' ' + this.targetUnit;
    };
    unitConverter.addUnit = function (baseUnit, actualUnit, multiplier) {
      var toUnits;
      if(table[baseUnit] == undefined)
      {
        table[baseUnit] = {};
      }
      toUnits = table[baseUnit];
      if(typeof(multiplier) == 'number')
      {
        toUnits[actualUnit] = {multiplier: multiplier};
      }
      else if(typeof(multiplier) == 'string')
      {
        toUnits[actualUnit] = {conversionFunc: multiplier };
      }
      table[baseUnit] = toUnits;
      /*(typeof(multiplier) == 'number')
      {
        table[actualUnit] = { base: baseUnit, actual: actualUnit, multiplier: multiplier };
      }
      else if(typeof(multiplier) == 'string')
      {
        table[actualUnit] = { base: baseUnit, actual: actualUnit, conversionFunc: multiplier };
      }*/
    };

    var prefixes = ['Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', 'h', 'da', '', 'd', 'c', 'm', 'u', 'n', 'p', 'f', 'a', 'z', 'y'];
    var factors = [24, 21, 18, 15, 12, 9, 6, 3, 2, 1, 0, -1, -2, -3, -6, -9, -12, -15, -18, -21, -24];
    // SI units only, that follow the mg/kg/dg/cg type of format
    var units = ['m'];

    for (var j = 0; j < units.length; j++) {
        var base = units[j];
        for (var i = 0; i < prefixes.length; i++) {
            unitConverter.addUnit(base, prefixes[i] + base, Math.pow(10, factors[i]));
        }
    }

    unitConverter.addUnit('celsius', 'celsius', 1);
    unitConverter.addUnit('celsius', 'fahrenheit', '{value}*9/5+32');
    
    unitConverter.addUnit('celsius', '%B0F', '{value}*9/5+32');
    //unitConverter.addUnit('celsius', '°F', '{value}*9/5+32');
    unitConverter.addUnit('mb', 'mb', 1);
    unitConverter.addUnit('mb', 'inches mercury', 0.0295);
    unitConverter.addUnit('m_s-1', 'm_s-1', 1);
    unitConverter.addUnit('m_s-1', 'cm_s-1', 0.01);
    unitConverter.addUnit('mm_s-1', 'mm_s-1', 0.1);
    unitConverter.addUnit('mm_s-1', 'cm_s-1', 0.1);
    unitConverter.addUnit('m_s-1', 'knots', 1.9438444925);
    unitConverter.addUnit('m_s-1', 'mph', 2.2369362921);
    unitConverter.addUnit('cm_s-1', 'mph', 0.022369362921);
    unitConverter.addUnit('mm', 'inch', 0.039);
    unitConverter.addUnit('m', 'ft', 3.28);


    window.$unitConversion = function (value, unit) {
        var unitConversion = new window.unitConverter(value, unit);
        return unitConversion;
    };
})();
