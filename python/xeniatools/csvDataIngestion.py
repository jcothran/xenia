"""
Revisions:
Date: 2013-05-09
Function:
Revisions: We need to save the last entry date to the ini file. The real time database only has the last 2-3 weeks of data,
  if a site goes down any longer than that we can't query the database to find the date to start at so we can
  end up repreocessing data we don't need to.

Date: 2013-01-02
FUnction: xeniaCSVReader::next
Changes:  MAke sure we have a real float value before passing it to the converter.
"""
import datetime
import logging
import simplejson as json
import csv 
import Queue
import ConfigParser



from xeniatools.xeniaSQLAlchemy import  multi_obs 
from xeniatools.xenia import uomconversionFunctions
from xeniatools.DataIngestion import xeniaDataIngestion, dataSaveWorker


"""
class srcToXeniaDataMapping
"""
class csvSrcToXeniaDataMapping(object):
  def __init__(self, mappingJSONFile):
    self.mappings = None
    if(mappingJSONFile):
      jsonFile = open(mappingJSONFile, 'r')
      self.mappings = json.load(jsonFile)
      jsonFile.close()
      #We may have a header array for a csv file that has no header. If we do, let's save that for use in the reader. 
      if 'header' in self.mappings:
        self.rowFieldNames = self.mappings['header']
        del(self.mappings['header'])
        
      #If we have a defaults section, let's put it in it's on member.
      if 'defaults' in self.mappings:
        self.defaultVals = self.mappings['defaults']
        #Remove it from column mappings.
        del(self.mappings['defaults'])
        
        
  def xeniaNameSearch(self, standardName):   
    xeniaName = None
    for key in self.mappings:
      if 'standard_name' in self.mappings[key] and standardName == self.mappings[key]['standard_name']:
        return(self.mappings[key]['standard_name'])
      
    return(xeniaName)
  
  def getPlatformColumn(self):
    platformCol = self.xeniaNameSearch('platform_handle')
    return(platformCol)
  
  """
  Function: getPlatformDefaultHandle
  Purpose: For csv files that don't have the platform information, this returns what we define as the 
    platform handle in the json file.
  """
  def getPlatformDefaultHandle(self):
    defaultVal = None
    if 'platform' in self.defaultVals:
      if 'default_value' in self.defaultVals['platform']:
        defaultVal = self.defaultVals['platform']['default_value']           
    return(defaultVal)     
  
  """
  Function: getDefaultPlatformMetaData
  Purpose: For csv files that don't have the platform information, this returns what we define as the 
    platform metadata such as operator, platform type, url, ect. We use this if we have to add the platform to the 
    database.
  """
  def getDefaultPlatformMetaData(self):
    defaultMetaData = None
    if 'platform' in self.defaultVals:
      defaultMetaData = self.defaultVals['platform']
    return(defaultMetaData)

  """
  Function: getFixedLocation
  Purpose: Looks up the fixed location parameters in the mapping file and returns
    their index.
  """
  def getFixedLonLatColumn(self):
    fixed_longitude = self.xeniaNameSearch('fixed_longitude')
    fixed_latitude = self.xeniaNameSearch('fixed_latitude')
    return(fixed_longitude,fixed_latitude)

  def getDefaultFixedLonLat(self):
    defaultLon = None
    defaultLat = None
    if 'fixed_longitude' in self.defaultVals and 'fixed_latitude' in self.defaultVals:
      defaultLon = self.defaultVals['fixed_longitude']['default_value']
      defaultLat = self.defaultVals['fixed_latitude']['default_value']      
    return(defaultLon,defaultLat)

  def getDateColumn(self):
    m_date = None
    timezone = None
    dateFormat = None
    for key in self.mappings:
      if(self.mappings[key]['standard_name'] == 'm_date'):
        m_date = key
        if 'timezone' in self.mappings[key]:
          timezone = self.mappings[key]['timezone']
        if 'format' in self.mappings[key]:      
          dateFormat = self.mappings[key]['format']
        break
      
    return(m_date, dateFormat, timezone)
  
  def getColumnMapping(self, colName):
    if colName in self.mappings:
      return(self.mappings[colName])
    return(None)
  
class xeniaCSVReader(csv.DictReader):
  def __init__(self, fileObj, xeniaMappingFile, uomConverter, dialect='excel', logger=False, *args, **kwds):
    self.xeniaMapping = csvSrcToXeniaDataMapping(xeniaMappingFile)
    self.uomConverter = uomConverter;

    restkey = 'spillover'
    restval = None
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    
    headerFields = None
    if(hasattr(self.xeniaMapping, 'rowFieldNames')):
      headerFields = self.xeniaMapping.rowFieldNames
      
    csv.DictReader.__init__(self, fileObj, fieldnames=headerFields, restkey=restkey, restval=restval,
                 dialect=dialect, *args, **kwds)
  """
  Function: next
  Purpose: We override the next function from the base class to do our specific processing. THe assumption is a row represents 
    a time sample of a platform with one or more observations on the row. We return a single measurement row that is formatted
    towards xenia entry. The observations are in a list, key of 'multi_obs', while static platform data such as time sample, lat, lon
    are stored once in their respective fields.
  """
  def next(self):
    row = csv.DictReader.next(self)
    
    #Get the platform column. If we don't have one, we use the default value.
    platformCol  = self.xeniaMapping.getPlatformColumn()
    if(platformCol == None):
      platformHandle = self.xeniaMapping.getPlatformDefaultHandle();
    else:
      #THis will be the short name, we then need to look up the platform_handle
      platformHandle = row['platformCol']
      
    #Get the date entry as we need it for each observation.
    dateCol, dateFormat, timezone = self.xeniaMapping.getDateColumn()
    #Get the data once for use in each observation.
    dateVal = row[dateCol]
    if(dateVal.isalnum() == False):
      dateVal = "".join(i for i in dateVal if ord(i)<128)
    
    mDate = datetime.datetime.strptime(dateVal, dateFormat)

    #Get the longitude and latitude columns. If they don't exist, use the default values.
    lonCol,latCol = self.xeniaMapping.getFixedLonLatColumn()
    if(lonCol == None and latCol == None):
      lon,lat = self.xeniaMapping.getDefaultFixedLonLat()
    else:
      lon = row[lonCol]
      lat = row[latCol]

    dataRec = {}  
    dataRec['m_date'] = mDate
    dataRec['platform_handle'] = platformHandle
    dataRec['m_lon'] = lon
    dataRec['m_lat'] = lat
    dataRec['multi_obs'] = []  
    for col in row:
      mapping = self.xeniaMapping.getColumnMapping(col)
      if(mapping):      
        #Don't add a rec for the m_date as it is an attribute of the observations.
        if(mapping['standard_name'] != 'm_date'):
          obsRec = {}  
          obsRec['obs_standard_name'] = mapping['standard_name'] 
          #obsRec['column_uom'] = mapping['column_uom']
          obsRec['uom'] = mapping['uom']
          obsRec['s_order'] = mapping['s_order']
          #If the units of the source data are not what we want, convert the value.
          if(mapping['uom'] != mapping['column_uom']):
            #DWR 2013-01-02
            #MAke sure we have a real float value before passing it to the converter.
            try:
              dataVal = float(row[col])
            except ValueError,e:
              if(self.logger):
                self.logger.exception(e)
            else:
              val = self.uomConverter.measurementConvert(dataVal, mapping['column_uom'], mapping['uom'])
              if(val == None):
                if(self.logger):
                  self.logger.error("Unable to convert value. Obs: %s FromUOM: %s ToUOM: %s" % (mapping['standard_name'], mapping['column_uom'], mapping['uom']))
                continue
          else:
            val = row[col]
          obsRec['m_value'] = val
          dataRec['multi_obs'].append(obsRec)
      else:
        if(self.logger):
          self.logger.error("No mapping for column name: %s" %(col))            
   
    return(dataRec)
  
  
  
class csvDataIngestion(xeniaDataIngestion):
  def __init__(self, organizationID, configFile, logger=None):
    self.configFilename = configFile
    xeniaDataIngestion.__init__(self, organizationID, configFile, logger)

  def initialize(self, configFile=None):
    self.startFromLastDBEntry = False
    self.lastEntryDate = None
    #COnnect to the xenia database.
    if(self.connect()):
      #Get the required config file settings.
      try:        
        filePath = self.config.get('settings', 'uomconversionfile')
        self.uomConverter = uomconversionFunctions(filePath)
        
        self.csvFilepath = self.config.get(self.organizationId, 'csvFilepath')
        self.jsonMappingFile = self.config.get(self.organizationId, 'jsonconfig')
                
        self.dataQueue = Queue.Queue(0)
        dataSaver = dataSaveWorker(self.configFilename, self.dataQueue)
        dataSaver.start()        
      except ConfigParser.Error, e:  
        if(self.logger):
          self.logger.exception(e)
      else:
        #Get optional parameters.
        try:
          #If this is set, we query the ini for the last date/time of data we put into the database and 
          #add data that is from that date forward. Some csv datafiles append for a long time period so we
          #can ignore data we already have.
          #self.startFromLastDBEntry = self.config.getboolean(self.organizationId, 'processfromlatestdbrec')
          #DWR 2013-05-09
          #Use the ini file instead of the database since the platform can go down for a longer period that
          #the data we retain in the real time database. Only last couple of weeks in real time database.
          lastDate = self.config.get(self.organizationId, 'lastentrydate')
          if(len(lastDate)):
            self.lastEntryDate = datetime.datetime.strptime(lastDate, "%Y-%m-%dT%H:%M:%S")
            if(self.logger):
              self.logger.debug("Starting from date/time: %s" % (self.lastEntryDate))
          else:
            self.lastEntryDate = datetime.datetime.now()
            if(self.logger):
              self.logger.debug("lastentrydate does not exist, starting from current date/time: %s" % (self.lastEntryDate))
            
        except ConfigParser.Error, e:  
          if(self.logger):
            self.logger.debug("Optional parameter: %s: %s does not exist. Using default setting." % (e.section,e.option))
            
        return(True)        
        
    return(False)
  
  def processData(self):    
    self.csvDataFile = xeniaCSVReader(open(self.csvFilepath, 'r'), 
                             self.jsonMappingFile,
                             self.uomConverter)
    self.sensorMappings = {}
    #The date we use to time stamp the rows we add.
    self.rowDate = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    
    try:    
      lineCnt = 0      
      #DWR 2013-0509
      lastRecDate = None
      dataRecs = self.getData()      
      while(dataRecs):
        #if(self.logger):
        #  self.logger.debug("Line: %d m_date: %s" % (self.csvDataFile.line_num, dataRecs['m_date']))
        saveRec = True
        #DWR 2013-05-09
        #Use the self.lastEntryDate variable for the test.
        if(self.lastEntryDate):
          if(dataRecs['m_date'] < self.lastEntryDate):
            saveRec = False
            
        if(saveRec):
          #DWR 2013-05-09    
          #Save the date, so when we hit the last data record, we have it saved and can then save it to the file.
          lastRecDate = dataRecs['m_date']  
          self.saveData(dataRecs)
        dataRecs = self.getData()
        lineCnt += 1
        
    except StopIteration,e:
      if(self.logger):
        self.logger.info("End of file reached.")        
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        
    #DWR 2013-05-09
    #We need to save the last entry date to the ini file. The real time database only has the last 2-3 weeks of data,
    #if a site goes down any longer than that we can't query the database to find the date to start at so we can
    #end up repreocessing data we don't need to.
    if(lastRecDate):
      self.config.set(self.organizationId, lastRecDate.strftime("%Y-%m-%dT%H:%M:%S"))

    if(self.logger):
      self.logger.info("Processed %d lines in file." % (lineCnt))
    #Finished processing  
    self.cleanUp()
        
    return(None)
   
  def cleanUp(self):       
    if(self.logger):
      self.logger.info("Signalling worker queue to shut down.")
    #Adding the none record tells the worker thread to stop processing whenever it hits it.
    self.dataQueue.put(None)
    #join blocks until the queue is emptied.
    self.dataQueue.join()
    if(self.logger):
      self.logger.info("Worker queue shut down.")
    #Disconnect from the database.  
    self.disconnect()
    
  def checkPlatformAndSensorsExist(self, dataRec):
    platformId = self.xeniaDb.platformExists(dataRec['platform_handle'])
    if(platformId == None):
      #Get the platform meta data from the mapping.
      platformMetaData = self.csvDataFile.xeniaMapping.getDefaultPlatformMetaData()
      if(self.logger):
        self.logger.debug("No platform found for platform handle: %s. Adding." %(dataRec['platform_handle']))

      platformUrl = ""
      description = ""
      if 'platform_url' in platformMetaData:
        platformUrl = platformMetaData['platform_url']
      if 'description' in platformMetaData:
        description = platformMetaData['description']
                
      platformId = self.xeniaDb.newPlatform(rowEntryDate = self.rowDate,
                               platformHandle = dataRec['platform_handle'], 
                               fixedLongitude = dataRec['m_lon'], 
                               fixedLatitude = dataRec['m_lat'], 
                               active=1,
                               url = platformUrl,
                               description = description)
    #Now we have to add the sensors.
    if(platformId != None):
      try:
        for obs in dataRec['multi_obs']:
          if(self.logger):
            self.logger.debug("Sensor Exists check for %s(%s) sOrder: %d on platform: %s" % (obs['obs_standard_name'], obs['uom'], obs['s_order'], dataRec['platform_handle']))
          sensorId = self.xeniaDb.sensorExists(obs['obs_standard_name'], obs['uom'], dataRec['platform_handle'], obs['s_order'])
          if(sensorId == None):        
            sensorId = self.xeniaDb.newSensor(rowEntryDate = self.rowDate, 
                                              obsName = obs['obs_standard_name'], 
                                              uom = obs['uom'], 
                                              platformId = platformId, 
                                              active=1, 
                                              fixedZ=0, 
                                              sOrder = obs['s_order'],
                                              mTypeId=None, 
                                              addObsAndUOM=True)
          #Build the mapping to use when we insert the observations into the multi_obs table. instead of looking the 
          #m_type_id and sensor_id up each record, we build this mapping when the first row is read.  
          #Get the m_type_id as well.
          mTypeId = self.xeniaDb.mTypeExists(obs['obs_standard_name'], obs['uom'])
          self.sensorMappings[obs['obs_standard_name']] = {'m_type_id' : mTypeId, 'sensor_id' : sensorId}
            
      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
          
  def getData(self):
    dataRecs = self.csvDataFile.next()   
    #If this is the first row, let's make sure the observations and platform exist and build our mapping.
    if(len(self.sensorMappings) == 0 and len(dataRecs)):
      self.checkPlatformAndSensorsExist(dataRecs)      
    return(dataRecs)
  
  def saveData(self, recordList):
    for obs in recordList['multi_obs']:
      multiObsRec = multi_obs(row_entry_date=self.rowDate,
                              platform_handle=recordList['platform_handle'],
                              sensor_id=(self.sensorMappings[obs['obs_standard_name']]['sensor_id']),
                              m_type_id=(self.sensorMappings[obs['obs_standard_name']]['m_type_id']),
                              m_date=recordList['m_date'],
                              m_lon=recordList['m_lon'],
                              m_lat=recordList['m_lat'],
                              m_value=obs['m_value']
                              )
      self.dataQueue.put(multiObsRec)

    return
