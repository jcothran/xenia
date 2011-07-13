########################################################################
#Revisions
#Date: 7/13/2011
#Function: __init__
#Changes: Added ini parameter //environment/debug/writeCSVDebugDataFile to allow a debug csv 
# to be appended to for tracking down a data gap issue.
#Date: 5/2/2011
#Function: createCSV
#Changes: Added date test to ignore any observations whose date is older than 2 days.
########################################################################
import os
import sys
import time
import datetime
#sys.path.append("C:\\Documents and Settings\\dramage\\workspace\\PythonTest")
from getYSIData import ysiDataCollection
from xeniatools.xmlConfigFile import xmlConfigFile

class nerrsYSIData(ysiDataCollection):
  def __init__(self, xmlConfigFilename):
    ysiDataCollection.__init__(self,xmlConfigFilename)
    configSettings = xmlConfigFile(xmlConfigFilename)
    #DWR 7/13/2011
    #Added flag to write an appending data file per station to keep track of all the data we pull down.
    self.writeCSVDebugDataFile = configSettings.getEntry("//environment/debug/writeCSVDebugDataFile")
    if(self.writeCSVDebugDataFile != None):
      self.writeCSVDebugDataFile = float(self.writeCSVDebugDataFile)
    else:
      self.writeCSVDebugDataFile = 0
      
  def formDBDate(self, date):
    try:      
      datetime = time.strptime(date, "%m/%d/%Y %I:%M %p")
      #PUt back in GMT conversion as per Jay.
      #As per Jay's instruction, we leave the date/time in local time zone.
      datetime = time.mktime(datetime)
      #Time is in CST since station is in MS, so we add an hour to make it EST.
      datetime += (60*60)
      #We are assuming the date is not in UTC, so we convert it.
      datetime = time.gmtime(datetime)
      dbDateTime = time.strftime("%Y-%m-%dT%H:%M", datetime)
      return(dbDateTime)
    
    except Exception, e:
      import sys
      import traceback
      
      info = sys.exc_info()        
      excNfo = traceback.extract_tb(info[2], 1)
      items = excNfo[0]
      lastErrorFile = items[0]    
      lastErrorLineNo = items[1]    
      lastErrorFunc = items[2]        
      print("%s Function: %s Line: %s File: %s" % (str(e), lastErrorFunc, lastErrorLineNo, lastErrorFile)) 
      sys.exit(- 1)
    
  def createCSV(self, siteName, csvFilename, obsHash):
    print( "Site: %s CSV file: %s" %(siteName,csvFilename))    
    try:
      swmpStation = ''
      if(siteName == 'nerrs_bayoucumbest_wq'):
        swmpStation = "gndbcwq"
      elif(siteName == 'nerrs_bayouheron_wq'):
        swmpStation = "gndbhwq"
      elif(siteName == 'nerrs_pointeauxchene_wq'):
        swmpStation = "gndpcwq"
      elif(siteName == 'nerrs_bangslake_wq'):
        swmpStation = "gndblwq"
        
      csvFile = open(csvFilename, "w")
      debugCSVFile = None
      if(self.writeCSVDebugDataFile):
        debugCSVFile = open(csvFilename + ".debug", "a")
        
      #Write the header line
      csvFile.write("Date,Time,Temp,SpCond,Sal,DO_pct,DO_mgl,Depth,pH,Turb,BVolt,SWMPStation\n")
      
      if(debugCSVFile != None):
        debugCSVFile.write("Date,Time,Temp,SpCond,Sal,DO_pct,DO_mgl,Depth,pH,Turb,BVolt,SWMPStation\n")
      
      #Now let's run through the hash to build the CSV file.    
      platformKeys = obsHash['platform'].keys()
      for platform in platformKeys:       
        dateKeys = obsHash['platform'][platform]['date'].keys()
        #We want to sort the dates
        #dateKeys.sort(reverse=True)
        dateKeys.sort()
        for dateKey in dateKeys:      
          #Make nerrs specific date/time
          dateTime = datetime.datetime.strptime(dateKey,"%Y-%m-%dT%H:%M")
          dateDiff = datetime.datetime.now() - dateTime 
          if(dateDiff.days > 2):
            print("Date: %s is older than 2 days, skipping." %(dateKey))
            continue         
          dateTime = time.strptime(dateKey,"%Y-%m-%dT%H:%M")
          date = time.strftime("%m/%d/%Y", dateTime)
          timeVal = time.strftime("%H:%M:00", dateTime)
          waterTemp = -1
          water_conductivity = -1
          salinity = -1
          oxygen_concentration_percent = -1 
          oxygen_concentration_mgL = -1 
          depth = -1
          ph = -1
          turbidity = -1
          battery_voltage = -1
          obsKeys = obsHash['platform'][platform]['date'][dateKey]['obsuom'].keys()
          obsKeys.sort()
          for obsKey in obsKeys:
            obsUOM = obsKey.split('.')
            obsName = obsUOM[0]
            uom = ''
            if(len(obsUOM)>1):
              uom = obsUOM[1]
              
            #Now we pull out the observations in the specific nerrs order.
            if( 'water_temperature' == obsName ):
              waterTemp = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
              
            elif( 'water_conductivity' == obsName ):
              water_conductivity = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
             
            elif( 'salinity' == obsName ):
              salinity = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
            
            elif( 'oxygen_concentration' == obsName and 'percent' == uom):
              oxygen_concentration_percent = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']

            elif( 'oxygen_concentration' == obsName and 'mg_L-1' == uom):
              oxygen_concentration_mgL = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
            
            elif( 'depth' == obsName ):
              depth = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
            
            elif( 'ph' == obsName ):
              ph = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
            
            elif( 'turbidity' == obsName ):
              turbidity = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
            
            elif( 'battery_voltage' == obsName ):
              battery_voltage = obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']['0']['sorder']['1']['value']
              
          #Date,Time,Temp,SpCond,Sal,DO_pct,DO_mgl,Depth,pH,Turb,BVolt,SWMPStation
          csvFile.write("%s,"  #date
                         "%s," #timeVal
                         "%.2f," #waterTemp
                         "%.2f," #water_conductivity
                         "%.2f," #salinity
                         "%.2f," #oxygen_concentration_percent
                         "%.2f," #oxygen_concentration_mgL
                         "%.2f," #depth
                         "%.2f," #ph
                         "%.2f," #turbidity
                         "%.2f," #battery_voltage
                         "%s\n"#swmpStation
                        %(date,timeVal,waterTemp,water_conductivity,salinity,oxygen_concentration_percent,oxygen_concentration_mgL,depth,ph,turbidity,battery_voltage,swmpStation))
          if(debugCSVFile != None):
            debugCSVFile.write("%s,"  #date
                         "%s," #timeVal
                         "%.2f," #waterTemp
                         "%.2f," #water_conductivity
                         "%.2f," #salinity
                         "%.2f," #oxygen_concentration_percent
                         "%.2f," #oxygen_concentration_mgL
                         "%.2f," #depth
                         "%.2f," #ph
                         "%.2f," #turbidity
                         "%.2f," #battery_voltage
                         "%s\n"#swmpStation
                        %(date,timeVal,waterTemp,water_conductivity,salinity,oxygen_concentration_percent,oxygen_concentration_mgL,depth,ph,turbidity,battery_voltage,swmpStation))    
      csvFile.close()
      if(debugCSVFile != None):
        debugCSVFile.close()
    except Exception, e:
      import sys
      import traceback
      
      info = sys.exc_info()        
      excNfo = traceback.extract_tb(info[2], 1)
      items = excNfo[0]
      lastErrorFile = items[0]    
      lastErrorLineNo = items[1]    
      lastErrorFunc = items[2]        
      print("%s Function: %s Line: %s File: %s" % (str(e), lastErrorFunc, lastErrorLineNo, lastErrorFile)) 
      sys.exit(- 1)

if __name__ == '__main__':
  try:
    ysiConvert = nerrsYSIData(sys.argv[1])    
    ysiConvert.processSites()
  except Exception, e:
    import sys
    import traceback
    traceback.print_exc()
    sys.exit(- 1)
