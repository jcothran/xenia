import sys
import time
sys.path.append("C:\\Documents and Settings\\dramage\\workspace\\PythonTest")
from getYSIData import ysiDataCollection

class nerrsYSIData(ysiDataCollection):
  def __init__(self, xmlConfiFile):
    ysiDataCollection.__init__(self,xmlConfiFile)
    
  def createCSV(self, siteName, csvFilename, obsHash):
    print( "Creating CSV file for: %s" %(siteName))    
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
      #Write the header line
      csvFile.write("Date,Time,Temp,SpCond,Sal,DO_pct,DO_mgl,Depth,pH,Turb,BVolt,GOESID,SWMPStation\n")
      
      #Now let's run through the hash to build the CSV file.    
      platformKeys = obsHash['platform'].keys()
      for platform in platformKeys:       
        dateKeys = obsHash['platform'][platform]['date'].keys()
        #We want to sort the dates
        dateKeys.sort()
        for dateKey in dateKeys:      
          #Make nerrs specific date/time
          dateTime = time.strptime(dateKey,"%Y-%m-%d %H:%M:%S")
          date = time.strftime("%m/%d/%Y", dateTime)
          timeVal = time.strftime("%H:%M", dateTime)
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
            
            elif( 'oxygen_concentration' == obsName and '%' == uom):
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
              
          #Date,Time,Temp,SpCond,Sal,DO_pct,DO_mgl,Depth,pH,Turb,BVolt,GOESID,SWMPStation
          csvFile.write("%s,"  #date
                         "%s," #timeVal
                         "%f," #waterTemp
                         "%f," #water_conductivity
                         "%f," #salinity
                         "%f," #oxygen_concentration_percent
                         "%f," #oxygen_concentration_mgL
                         "%f," #depth
                         "%f," #ph
                         "%f," #turbidity
                         "%f," #battery_voltage
                         ","   
                         "%s\n"#swmpStation
                        %(date,timeVal,waterTemp,water_conductivity,salinity,oxygen_concentration_percent,oxygen_concentration_mgL,depth,ph,turbidity,battery_voltage,swmpStation))    
      csvFile.close()
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
    
    info = sys.exc_info()        
    excNfo = traceback.extract_tb(info[2], 1)
    items = excNfo[0]
    lastErrorFile = items[0]    
    lastErrorLineNo = items[1]    
    lastErrorFunc = items[2]        
    print("%s Function: %s Line: %s File: %s" % (str(e), lastErrorFunc, lastErrorLineNo, lastErrorFile)) 
    sys.exit(- 1)
