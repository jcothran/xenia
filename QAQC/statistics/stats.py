import sys
import math

class stats(object):
  def __init__(self):
    self.items = []
    self.populationStdDev = None
    self.stdDev = None
    self.average = None
    self.total = None
    self.maxVal = None
    self.minVal = None
  
  def clearArray(self):
    del(self.items[:])
    
  def reset(self):
    self.clearArray()
    self.populationStdDev = None
    self.StdDev = None
    self.average = None
    self.total = None
    self.maxVal = None
    self.minVal = None

  def addValue(self, value):
    self.items.append(value)

  def getValueAtPercentile(self, percentile,linearInterpolate=False):
    value = None
    if(len(self.items)):
      percentile = percentile / 100.0
      value = -1.0
      tempList = self.items[0:len(self.items)]
      tempList.sort()
      if(linearInterpolate):
        #We have to subtract one to give us the array index since arrays are zero indexed.
        offset = (percentile * (len(tempList) + 1)) - 1
        #Determine if the offset is an integer, if not we need to interpolate between the two points.
        val = offset % 1
        #If the modulus does not result in 0, the percentile requested falls in between 2 entries.
        if(val != 0):
          lowOffset = int(math.floor(offset))
          hiOffset = int(math.ceil(offset))
          if((lowOffset < len(tempList) and lowOffset > 0 ) and 
              (hiOffset < len(tempList) and hiOffset > 0)):
            value = (tempList[lowOffset] + tempList[hiOffset]) / 2
          else:
            if(hiOffset > len(tempList)):
              value = tempList[-1]
            elif(lowOffset < 0):
              value = tempList[0]
        else:
          value = tempList[int(offset)]
      else:
          offset = int(round((percentile * (len(tempList) + 1)) - 1, 1))
          value = tempList[offset]
        
      del(tempList[:])     
    return(value)
  

  def doCalculations(self):
    self.total = None
    if(len(self.items)):
      self.total = 0.0
      for val in self.items:
        self.total += val
        if(self.maxVal == None or self.maxVal < val):
          self.maxVal = val
        if(self.minVal == None or self.minVal > val):
          self.minVal = val
      self.average = self.total / len(self.items)
      
      #Calculate standard deviation.
      deviationSum = 0.0
      for val in self.items:
        deviation = ((val - self.average) * (val - self.average))
        deviationSum += deviation
      if((len(self.items) - 1) > 0):
        self.stdDev = math.sqrt(deviationSum / (len(self.items) - 1)) 
      self.populationStdDev = math.sqrt(deviationSum / len(self.items))
      return(True)
    return(False)