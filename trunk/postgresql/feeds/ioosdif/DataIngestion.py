import sys
import optparse
import logging
import logging.config
import ConfigParser
import urllib
import urllib2 
import datetime
import re
import csv
from lxml import etree    
from lxml import objectify
from pykml import kml

import threading
import Queue

import shapely
from shapely.geometry import Polygon, Point

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from sqlalchemy import or_
from sqlalchemy.sql import column
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 
from xeniatools.xenia import uomconversionFunctions

#from geoalchemy import *
class difError(Exception):
  def __init__(self, value):
      self.value = value
  def __str__(self):
      return repr(self.value)

class ioosDif(object):
  def __init__(self, sosUrl, logger=True):
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    self.sosUrl = sosUrl
  
  def doRequest(self, parameters):
    difRequest = None
    parameters['service'] = 'SOS'
    try:      
      params = urllib.urlencode(parameters)
      #create the url and the request
      req = urllib2.Request(self.sosUrl + '?' + params)
      #req = urllib2.Request(self.sosUrl,params)
      # Open the url
      connection = urllib2.urlopen(req)
      difRequest = connection.read()
      
    except urllib2.HTTPError, e:
      if(self.logger):
        self.logger.exception(e)
    except urllib2.URLError, e:
      if(self.logger):
        self.logger.exception(e)
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)

    return(difRequest)
  
  def getCapabilities(self):
    parameters = {}  
    parameters['request'] = 'GetCapabilities'
    capabilities = difCapabilities(self.doRequest(parameters))      
    return(capabilities)
  
  def describeSensor(self,  
                    procedure, 
                    version='1.0.0'):
    parameters = {}  
    parameters['request'] = 'DescribeSensor'
    parameters['outputformat']='text/xml;subtype="sensorML/1.0.0"'
    parameters['procedure'] = procedure
    parameters['version'] = version
    results = objectify.fromstring(self.doRequest(parameters))      
    return(results)
  
  def getObservation(self, 
                     offering, 
                     observedproperty,
                     responseformat,
                     eventtime=None,
                     featureofinterest=None,
                     version='1.0.0'):
    parameters = {}  
    parameters['request'] = 'GetObservation'
    parameters['offering'] = offering
    parameters['observedproperty'] = observedproperty
    parameters['responseformat'] = responseformat
    parameters['version'] = version
    if(eventtime):
      parameters['eventtime'] = eventtime
    if(featureofinterest):
      parameters['featureofinterest'] = featureofinterest
    return(self.doRequest(parameters))  

class difCapabilities():
  def __init__(self, xmlData, logger=True):
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    self.getCapRoot = objectify.fromstring(xmlData)
    
  def getStationId(self, stationProperty):
    id = None
    entryType = None
    if '{http://www.opengis.net/gml}id' in stationProperty.attrib:    
      id = stationProperty.attrib['{http://www.opengis.net/gml}id']
      #The station id is stored as 'station-xxxxx', we want to split it up and just get the station id(xxxxxx)
      #We want to ignore any tags that aren't station-xxxxx.      
      stationParts = re.findall("^(network|station)-(.{1,})", id)
      entryType = stationParts[0][0] 
      id = stationParts[0][1]                   
    return(id,entryType)
  
  def getFixedLonLat(self, stationProperty):
    lat = None
    lon = None
    lowerCorner = stationProperty['{http://www.opengis.net/gml}boundedBy'].Envelope.lowerCorner
    lowerCorner = lowerCorner.text.split(' ')
    try:        
      lat = float(lowerCorner[0])          
      lon = float(lowerCorner[1])
    except ValueError,e:
      lat = lon = None            
    return(lon,lat)
  
  def getStationDescription(self, stationProperty):
    desc = None
    desc = stationProperty['{http://www.opengis.net/gml}description'].text
    return(desc)      
  
  def getStationTimePeriod(self, stationProperty):
    timePeriod = None
    timePeriod = stationProperty.time['{http://www.opengis.net/gml}TimePeriod']
    return(timePeriod)
  
  def getStationObservations(self, stationProperty, dbObj, active, sourceToXeniaMap, uomConverter, rowEntryDate):
    sensorRecs = []
    sensors = ""
    for obsProperty in stationProperty.observedProperty:
      #The attribute is a url to the observation. We're not going to follow the url, we just want the
      #observation name so split the url up and get the last piece.
      obsType = obsProperty.attrib['{http://www.w3.org/1999/xlink}href'].split('/')[-1]
      #Use the obsType to get the xenia observation.
      xeniaObs = sourceToXeniaMap.getXeniaFromDifObs(obsType)
      if(xeniaObs != None and len(xeniaObs)):
        for xeniaOb in xeniaObs:
          sensors += "obsName: %s\n" % (xeniaOb)
          #Get the dif column name from the xenia observation name.
          difObs = sourceToXeniaMap.getDifColNameFromXenia(xeniaOb)
          if(difObs):
            obsParts = re.findall("^(\w*)\s\((.{1,})\)", difObs)
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = uomConverter.getXeniaUOMName(obsParts[0][1].lower())
            if(uom == None):
              uom = obsParts[0][1].lower()
            #Get the m_type_id for the sensor rec.
            mType = dbObj.mTypeExists(xeniaOb, uom)
            if(mType):
              newSensor = sensor()
              newSensor.row_entry_date = rowEntryDate
              newSensor.active = active
              newSensor.m_type_id = mType
              newSensor.s_order = 1
              newSensor.short_name = xeniaOb
              sensorRecs.append(newSensor)
              if(self.logger):
                self.logger.info("Found sensor: %s MType: %d SOrder: %d" % (newSensor.short_name,newSensor.m_type_id,newSensor.s_order))                          
            else:
              if(self.logger):
                self.logger.error("Unable to find the m_type for Obs: %s(%s)" % (xeniaOb, uom))
                sys.exit(-1)
          else:
            if(self.logger):
              self.logger.error("Could not find dif Observation for xenia: %s" %(xeniaOb))
      else: 
        if(self.logger):
          self.logger.error("GetCapabilities observedProperty: %s not found in xenia obs mapping." %(obsType))                      
    return(sensorRecs)

class difObservation(object):
  def __init__(self, logger=True):
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
     
  def getFixedLonLatValue(self, data):
    return(None,None)
  def getDateTime(self, data):
    return(None)
  def getDepth(self, data):
    return(None)
  def getDataValue(self, data):
    return(None)    
  def getTimeSeriesRow(self):
    return(None)
     
class difObservationCSV(difObservation, ioosDif):
  def __init__(self, sosUrl, xeniaMapping, uomConverter, logger=True):
    difObservation.__init__(self, logger)
    ioosDif.__init__(self, sosUrl, logger)
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    self.getObsData = None
    self.uomConverter = uomConverter
    self.xeniaToDifMapping = xeniaMapping
    self.lonCol,self.latCol = self.xeniaToDifMapping.getLonLatColumnNames()
    self.dateTimeCol = self.xeniaToDifMapping.getDatetimeColumnName()
        
  def getObservation(self, 
                     offering, 
                     observedproperty,
                     eventtime=None,
                     featureofinterest=None,
                     version='1.0.0'
                     ):
    
    data = ioosDif.getObservation(self, 
                                   offering, 
                                   observedproperty, 
                                   'text/csv', 
                                   eventtime, 
                                   featureofinterest, 
                                   version)
    #Check to see if we got a valid response or an exception.
    if(data.find("ExceptionReport") == -1):      
      self.depthCol = self.xeniaToDifMapping.getDepthColumnName(observedproperty)
      self.difObsMap = self.xeniaToDifMapping.getDifColumnsFromObs(observedproperty)
      self.lineNum = 0
      columnDefs = self.xeniaToDifMapping.getHeaderColumnNames(observedproperty)      
      splitData = data.split("\n")
      #We use the column header list from above to map the rows into key/value pairs.
      self.getObsData = csv.DictReader(splitData, columnDefs)
      self.header = self.getObsData.next()
      self.lineNum += 1
      return(True)
    else:
      raise(difError(data))

  def getFixedLonLatValue(self, dataRow):
    lon = None
    lat = None
    try:
      lon = float(dataRow[self.lonCol])
      lat = float(dataRow[self.latCol])   
    except ValueError,e:
      if(self.logger):
        self.logger.error("Lat or Lon is not a valid number.")
    return(lon,lat)
  
  def getDateTime(self,dataRow):
    return(dataRow[self.dateTimeCol])

  def getDepth(self, dataRow):
    depth = None
    try:
      if(self.depthCol):                
        depth = float(dataRow[self.depthCol])
    except ValueError,e:
      if(self.logger):
        self.logger.error("Depth %s is not a valid number." % (dataRow[self.depthCol]))
    return(depth)
  
  def getDataValue(self, dataColumn, dataRow):
    value = None
    try:                          
      value = float(dataRow[dataColumn])
    except ValueError,e:
      if(self.logger):
        self.logger.debug("m_value: %s is not a valid number." % (dataRow[dataColumn]))
    return(value)    
  
  def getTimeSeriesRow(self, xeniaDB, platformHandle, rowEntryDate):
    recList = []
    try:
      dataRow = self.getObsData.next()
      if(self.lineNum > 0):        
        for xeniaKey in self.difObsMap:
          xeniaOb = self.difObsMap[xeniaKey] 
          if(len(xeniaOb)):
            dataRec = multi_obs()             
            sOrder = 1
            #The units are encoded into the column name, for example:
            #sea_water_temperature (C)
            obsParts = re.findall("^(\w*)\s\((.{1,})\)", xeniaKey)
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = self.uomConverter.getXeniaUOMName(obsParts[0][1].lower())
            if(uom == None):
              uom = obsParts[0][1].lower()           
            dataRec.m_type_id = xeniaDB.mTypeExists(xeniaOb, uom)
            dataRec.sensor_id = xeniaDB.sensorExists(xeniaOb, uom, platformHandle, sOrder)
            if(dataRec.m_type_id and dataRec.sensor_id):
              dataRec.m_date = self.getDateTime(dataRow)
              dataRec.row_entry_date = rowEntryDate
              dataRec.platform_handle = platformHandle            
              dataRec.m_lon,dataRec.m_lat = self.getFixedLonLatValue(dataRow)    
              dataRec.m_value = self.getDataValue(xeniaKey, dataRow)
              dataRec.m_z = self.getDepth(dataRow)
              recList.append(dataRec)
            else:
              if(self.logger):
                self.logger.error("No m_type_id or sensor_id found for observation: %s" %(xeniaOb))
      self.lineNum += 1
    #No more rows to pull, so we return the empty list.
    except StopIteration:
      return(recList)      
    return(recList)


class xeniaMappings(object):
  def __init__(self, jsonFilepath=None):
    self.mappings = None
    if(jsonFilepath):
      import simplejson as json
      jsonFile = open(jsonFilepath, 'r')
      self.mappings = json.load(jsonFile)
              
  def configMapping(self, mappingData):
    return(None)
  
  def getLonLatColumnNames(self):
    latCol = None
    lonCol = None
    if "fixed_location" in self.mappings:
      latCol = self.mappings['fixed_location']['lat']
      lonCol = self.mappings['fixed_location']['lon']                
    return(lonCol,latCol)
  
  def getDatetimeColumnName(self):
    dateTimeCol = None
    if "datetime" in self.mappings:
      dateTimeCol = self.mappings['datetime']
    return(dateTimeCol)
  
  def getDepthColumnName(self, difObsName):
    depthCol = None
    if "depth" in self.mappings['observation_columns'][difObsName]:
      depthCol = self.mappings['observation_columns'][difObsName]['depth']
    return(depthCol)
  
  def getDifColumnsFromObs(self, difObsName):
    mapping = None
    if 'observation_columns' in self.mappings:
      if difObsName in self.mappings['observation_columns']:
        #The m_value_columns is a list of dictionaries structured: key = Column Name of the Dif observation, data = xenia obs name
        #We use a list to gaurantee the the order of the columns since the key also represents the column the data is stored in.
        mapping = {}
        for difCol in self.mappings['observation_columns'][difObsName]['m_value_columns']:
          key = difCol.keys()
          mapping[key[0]] = difCol[key[0]]
    return(mapping)
  
  def getXeniaFromDifObs(self, difObsName):
    xeniaObs = None
    if 'observation_columns' in self.mappings and difObsName in self.mappings['observation_columns']:
      xeniaObs = []
      for difCol in self.mappings['observation_columns'][difObsName]['m_value_columns']:
        keys = difCol.keys()
        xeniaOb = difCol[keys[0]] 
        if(len(xeniaOb)):
          xeniaObs.append(xeniaOb)
    return(xeniaObs)
  
  def getDifObsNameFromXenia(self, xeniaObs):
    if 'observation_columns' in self.mappings:
      for difObsMap in self.mappings['observation_columns']:
        #The m_value_columns is a list of dictionaries structured: key = Column Name of the Dif observation, data = xenia obs name
        #We use a list to gaurantee the the order of the columns since the key also represents the column the data is stored in.
        mapping = self.mappings['observation_columns'][difObsMap]['m_value_columns']
        for difObsRow in mapping:
          difColName = difObsRow.keys()
          if(xeniaObs == difObsRow[difColName[0]]):
            return(difObsMap)
    return(None)

  def getDifColNameFromXenia(self, xeniaObs):
    for difObsMap in self.mappings['observation_columns']:
      #The m_value_columns is a list of dictionaries structured: key = Column Name of the Dif observation, data = xenia obs name
      #We use a list to gaurantee the the order of the columns since the key also represents the column the data is stored in.
      mapping = self.mappings['observation_columns'][difObsMap]['m_value_columns']
      for difObsRow in mapping:
        key = difObsRow.keys()
        if(xeniaObs == difObsRow[key[0]]):
          return(key[0])
    return(None)
    
  def getHeaderColumnNames(self, difObsName):
    colNames = []
    colNames.append(self.mappings['platform_identifier'])
    colNames.append(self.mappings['sensor_identifier'])
    lon,lat = self.getLonLatColumnNames()
    colNames.append(lat)
    colNames.append(lon)
    colNames.append(self.getDatetimeColumnName())
    if 'depth' in self.mappings['observation_columns'][difObsName]: 
      colNames.append(self.mappings['observation_columns'][difObsName]['depth'])
    for difObsRow in self.mappings['observation_columns'][difObsName]['m_value_columns']:
      key = difObsRow.keys()
      colNames.append(key[0])
    
    return(colNames)

class dataSaveWorker(threading.Thread):
  def __init__(self, configFile, dataQueue, logger=True):
    self.__dataQueue = dataQueue
    self.configFilename = configFile
    self.loggerFlag = logger 
    threading.Thread.__init__(self)

  #This is the worker thread that handles saving the records to the database.
  def run(self):
    if(self.loggerFlag):
      logger = logging.getLogger(type(self).__name__)
      logger.info("Starting saver thread.")
    try:
      config = ConfigParser.RawConfigParser()
      configFile = open(self.configFilename, 'r')
      config.readfp(configFile)
  
      dbUser = config.get('Database', 'user')
      dbPwd = config.get('Database', 'password')
      dbHost = config.get('Database', 'host')
      dbName = config.get('Database', 'name')
      dbConnType = config.get('Database', 'connectionstring')
      
      configFile.close()
      db = xeniaAlchemy()      
      if(db.connectDB(dbConnType, dbUser, dbPwd, dbHost, dbName, False) == True):
        if(logger):
          logger.info("Succesfully connect to DB: %s at %s" %(dbName,dbHost))
      else:
        logger.error("Unable to connect to DB: %s at %s. Terminating script." %(dbName,dbHost))
        #sys.exit(-1)            
    except ConfigParser.Error, e:  
      if(logger):
        logger.exception(e)
    
    processData = True
    #This is the data processing part of the thread. We'll loop here until a None record is posted then exit. 
    while processData:
      dataRec = self.__dataQueue.get()
      if(dataRec != None):
        try:
          db.session.add(dataRec)              
          db.session.commit()
          if(logger):
            val = ""
	    if(dataRec.m_value != None):
              val = "%f" % (dataRec.m_value)
            logger.debug("Committing record Sensor: %d Datetime: %s Value: %s" %(dataRec.sensor_id, dataRec.m_date, val))

        #Trying to add record that already exists.
        except exc.IntegrityError, e:
          db.session.rollback()        
          #if(logger):
          #  logger.debug(e.message)                          
        except Exception, e:
          db.session.rollback()        
          if(logger):
            logger.exception(e)
          #sys.exit(-1)
      else:
        if(logger):
          logger.info("Database saver thread exiting")
        processData = False
      self.__dataQueue.task_done()

              
              
class platformInventory:
  def __init__(self, organizationID, configurationFile, logger=True):
    self.organizationID = organizationID    
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    try:
      self.config = ConfigParser.RawConfigParser()
      self.config.read(configurationFile)
  
      dbUser = self.config.get('Database', 'user')
      dbPwd = self.config.get('Database', 'password')
      dbHost = self.config.get('Database', 'host')
      dbName = self.config.get('Database', 'name')
      dbConnType = self.config.get('Database', 'connectionstring')
  
      self.db = xeniaAlchemy(self.logger)      
      if(self.db.connectDB(dbConnType, dbUser, dbPwd, dbHost, dbName, False) == True):
        if(self.logger):
          self.logger.info("Succesfully connect to DB: %s at %s" %(dbName,dbHost))
      else:
        self.logger.error("Unable to connect to DB: %s at %s. Terminating script." %(dbName,dbHost))
        sys.exit(-1)            
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)
    

  def getKnownPlatforms(self):
    return(None)

  def findNew(self):      
    return(None)
  
  def outputRecords(self, recs):
    return(None)
  
  def checkAvailableObs(self):
    return(None)
  
  def platformInInventory(self, inventoryRecs, bbox, testPlatformId, testPlatformLat, testPlatformLon, testPlatformMetadata=""):
    platformFound = False
    stationPt = shapely.wkt.loads('POINT(%s %s)' %(testPlatformLon,testPlatformLat))    
    for platRec in inventoryRecs:     
      lcShortName = platRec.short_name.lower()
      lcplatformId = testPlatformId.lower()
      if(lcShortName == lcplatformId):
        if(self.logger):
          self.logger.info("Platform: %s exists in the current xenia database." % (testPlatformId))
        platformFound = True  
    #The platform wasn't found based on its name, however it may exist and we've called it something else since 
    #the owner of the platform may be another entity. Let's do a secondary search to see if we find a platform at the same location.        
    if(platformFound != True):
      #ST_Dwithin params Geom 1, Geom 2, Distance in meters
      withinClause = "ST_DWithin(platform.the_geom, '%s', %4.2f)" % (stationPt.wkt, 0.03)
      distColResult = "'%s'" % (stationPt.wkt)
      
      distRecs = self.db.session.query(platform).\
        filter(withinClause).\
        all()
      if(len(distRecs)):
        platformFound = True  
        for nearRec in distRecs:
          if(self.logger):
            self.logger.info("Test station: %s(%s) is with 0.5 miles of %s, could be same platform" % (testPlatformId,testPlatformMetadata,nearRec.platform_handle))
    return(platformFound)
    
class dataIngestion(object):
  def __init__(self, configFile, logger=True):
    
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    self.config = ConfigParser.RawConfigParser()
    self.config.read(configFile)
  
  def processData(self):    
    recList = self.getData()
    self.saveData(recList)
    return(None)
    
  def getData(self):
    return([])
  
  def saveData(self, recordList):
    return

    
class xeniaFedsInventory(platformInventory):
  def __init__(self, organizationID, configurationFile, logger=True):    
    platformInventory.__init__(self, organizationID, configurationFile, logger)    
    try:
      url = self.config.get(self.organizationID, 'difurl')
      self.difObj = ioosDif(url, logger)
      self.difCap = None
          
      self.bbox = self.config.get('area', 'bbox')
      jsonConfig = self.config.get(self.organizationID, 'jsonconfig')
      self.xeniaDataMappings = xeniaMappings(jsonConfig)
      
      self.platformType = 'met';
      
      filePath = self.config.get('settings', 'uomconversionfile')
      self.uomConverter = uomconversionFunctions(filePath)

    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)

  def findNew(self):    
    newPlatforms = []
    platformsMissingObs = []
    """
    Create our geomtry Polygon object. This is the bounding box of the area we are interested in.
    We use this to test if the stations from the providers station list are within the area,
    If so, we then check if the station is in our database.
    """
    bboxPoly = "POLYGON((%s))" % (self.bbox)
    bboxPoly = shapely.wkt.loads(bboxPoly)
    
    rowEntryDate = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    #Get the records for the active stations of type self.organizationID
    try:
      
      #filter(platform.active < 3).\
      platformRecs = self.db.session.query(platform).\
                  join((organization,organization.row_id == platform.organization_id)).\
                  filter(organization.short_name == self.organizationID).\
                  all()
      count = len(platformRecs)        
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
          
    try:      
      self.difCap = self.difObj.getCapabilities()
      for station in self.difCap.getCapRoot.Contents.ObservationOfferingList.iterchildren():
        id,entryType = self.difCap.getStationId(station)
        if(id != None and (entryType != None and entryType == 'station')):
          try:
            lon,lat = self.difCap.getFixedLonLat(station)
            stationPt = shapely.wkt.loads('POINT(%s %s)' %(lon,lat))
            if(stationPt.within(bboxPoly)):
              if(self.logger):
                self.logger.debug("Station: %s Lon: %s Lat: %s in region" % (id,lat,lon))
              desc = self.difCap.getStationDescription(station)          
              foundPlatform = self.platformInInventory(platformRecs, bboxPoly, id, lat, lon, desc)
              if(foundPlatform == False):
                newRec = self.processNewPlatform(station, rowEntryDate, platformRecs)
                if(newRec):
                  newPlatforms.append(newRec)
              else:
                missingObsRec = self.checkAvailableObs(id, station, platformRecs, self.xeniaDataMappings, self.uomConverter)
                if(missingObsRec):
                  platformsMissingObs.append(missingObsRec)                                                  
          except Exception, e:  
            if(self.logger):
              self.logger.exception(e)
    #handle errors
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
    
    return(newPlatforms, platformsMissingObs)
        
  def outputRecords(self, newRecs, platsMissingObs):    
    newPlatformsKML = None
    kmlFilename = None
    placemarks = []
    platformsMissingObsPMs = []
    try:
      kmlFilename = self.config.get(self.organizationID, 'newplatformkml')
      newPlatformsKML = kml.KML()
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.debug("newplatformkml option does not exist, not creating new platforms kml file.")

    addnewplatformstodb = False
    try:
      addnewplatformstodb = bool(int(self.config.get(self.organizationID, 'addnewplatformstodb')))
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.debug("addnewplatformstodb option does not exist, not adding new platforms to db.")
            
    for newRec in newRecs:      
      #Are we adding new platforms/sensors to the database?      
      if(addnewplatformstodb):
        try:
          self.db.addPlatform(newRec, True)
        except Exception,e:
          if(self.logger):
            self.logger.exception(e)
            sys.exit(-1)  
            
      #Building a KML file?
      if(newPlatformsKML):
        sensors = ""
        for sensor in newRec.sensors:
          if(len(sensors)):
            sensors += "\n"
          sensors += sensor.short_name
        activeStatus = 'Inactive'
        if(newRec.active <= 3):
          activeStatus = "Active"
        pmDesc = "Active Status: %s\n\nDescription: %s\n\nSensors:\n\t%s" % (activeStatus, newRec.description, sensors)
        pm = newPlatformsKML.createPlacemark(newRec.platform_handle, newRec.fixed_latitude, newRec.fixed_longitude, pmDesc)
        placemarks.append(pm)
        
    if(newPlatformsKML):
      for rec in platsMissingObs:
        sensors = ""
        if(rec.sensors):
          for sensor in rec.sensors:
            if(len(sensors)):
              sensors += "\n"
            sensors += sensor.short_name
          activeStatus = 'Inactive'
          if(rec.active <= 3):
            activeStatus = "Active"
          pmDesc = "Active Status: %s\n\nDescription: %s\n\nSensors:\n\t%s" % (activeStatus, rec.description, sensors)
          pm = newPlatformsKML.createPlacemark(rec.platform_handle, rec.fixed_latitude, rec.fixed_longitude, pmDesc)
          platformsMissingObsPMs.append(pm)
        else:
          i = 0
    #Save the placemarks into the kmlfile.
    try:
      if(len(placemarks) and kmlFilename):
        newPlatsDoc = newPlatformsKML.createDocument("Platforms")
        
        newFolder = newPlatformsKML.createFolder("Potential New Platforms")
        for pm in placemarks:
          newFolder.appendChild(pm)
        newPlatsDoc.appendChild(newFolder)

        missingObsFlder = newPlatformsKML.createFolder("Platforms with missing observations")
        for pm in platformsMissingObsPMs:
          missingObsFlder.appendChild(pm)
        newPlatsDoc.appendChild(missingObsFlder)

        newPlatformsKML.appendChild(newPlatsDoc)

        kmlFile = open(kmlFilename, "w")
        kmlFile.writelines(newPlatformsKML.writepretty())
        kmlFile.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)  
        
    return(True)

  def checkAvailableObs(self, id, stationProperty, platformRecs, sourceToXeniaMap, uomConverter):
    try:
      missingObsRec = None
      for platRec in platformRecs:
        if(platRec.active < 3):     
          lcShortName = platRec.short_name.lower()
          lcplatformId = id.lower()          
          if(lcShortName == lcplatformId):
            if(lcShortName == '8651370'):
              i = 0
            stationObs = self.difCap.getStationObservations(stationProperty, self.db, platRec.active, sourceToXeniaMap, uomConverter, "")
            for obs in stationObs:              
              sOrder = 1
              for platObs in platRec.sensors:
                if(obs.m_type_id == platObs.m_type_id and 
                   obs.s_order == platObs.s_order):
                  #Observation exists, so remove it from the list.
                  stationObs.remove(obs)
                  break
            #If we have obs left in the list, we'll create a record and attach those obs.
            if(len(stationObs)):
              missingObsRec = platform()
              missingObsRec.short_name = platRec.short_name
              missingObsRec.platform_handle = platRec.platform_handle;
              missingObsRec.fixed_latitude = platRec.fixed_latitude
              missingObsRec.fixed_longitude = platRec.fixed_longitude
              missingObsRec.organization_id = platRec.organization_id
              missingObsRec.description = desc = platRec.description
              missingObsRec.sensors = stationObs
              
              for obs in stationObs:
                if(self.logger):
                  self.logger.debug("Platform: %s does not currently contain sensor: %s" %(platRec.platform_handle,obs.short_name))        
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
        
    return(missingObsRec)
  def processNewPlatform(self, stationProperty, rowEntryDate, platformRecs):
    newRec = None
    try:
      id,entryType = self.difCap.getStationId(stationProperty)
      
      platHandle = "%s.%s.%s" % (self.organizationID, id, self.platformType)
      desc = self.difCap.getStationDescription(stationProperty)          
      lon,lat = self.difCap.getFixedLonLat(stationProperty)
      if(self.logger):
        self.logger.info("New Platform found. Id: %s Lon: %s Lat: %s Desc: %s" % (id, lon, lat, desc))
      if(desc != 'Glider'):
        newRec = platform()
        newRec.short_name = id
        newRec.platform_handle = platHandle;
        newRec.row_entry_date = rowEntryDate
        newRec.fixed_latitude = lat
        newRec.fixed_longitude = lon
        newRec.organization_id = platformRecs[0].organization_id
        newRec.description = desc
        #If there is an end date, then the station is not online, so we'll mark our record as such.
        timePeriod = self.difCap.getStationTimePeriod(stationProperty)
        if(timePeriod.endPosition.text):
          newRec.active = 4
        #Otherwise we set the status to inactive for the time being.
        else:
          newRec.active = 3          
        if(newRec):
          newRec.sensors = self.difCap.getStationObservations(stationProperty, self.db, newRec.active, self.xeniaDataMappings, self.uomConverter, rowEntryDate)
      else:
        if(self.logger):
          self.logger.debug("Description field indicates a glider, not adding.")
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)    
    
    return(newRec)
  
class xeniaNOSInventory(xeniaFedsInventory):
  def __init__(self, organizationID, configurationFile, logger):
    xeniaFedsInventory.__init__(self, organizationID, configurationFile, logger)
    self.platformType = 'wl'
    

class fedsDataIngestion(dataIngestion):
  def __init__(self, organizationID, configFile, logger=None):
    dataIngestion.__init__(self, configFile, logger)
    self.configFilename = configFile
    self.organizationID = organizationID
    self.inventory = xeniaFedsInventory(self.organizationID, configFile, logger)
    try:
      filePath = self.config.get('settings', 'uomconversionfile')
      #Get the units conversion XML file. Use it to translate the NDBC units into xenia uoms.
      self.uomConverter = uomconversionFunctions(filePath)
      self.lastNHours = float(self.config.get(self.organizationID, 'lastnhours'))
      self.checkForNewPlatforms = bool(int(self.config.get(self.organizationID, 'checkfornewplatforms')))
      self.stationoffering = self.config.get(self.organizationID, 'stationoffering')      
      self.url = self.config.get(self.organizationID, 'difurl')
      #self.difObj = ioosDif(url)
      self.difGetObs = difObservationCSV(self.url, self.inventory.xeniaDataMappings, self.uomConverter, True)
                
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)   
    except ValueError, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)   
  
  def getData(self):
    #Date/time to use for the row_entry_date in the database. We use local time.
    rowEntryDate = datetime.datetime.today().strftime("%Y-%m-%dT%H:%M:%S")

    platformWhitelist = None    
    try:
      platformWhitelist = self.config.get(self.organizationID, 'whitelist')
      platformWhitelist = platformWhitelist.split(',')
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.info("whitelist option does not exist, using the organization name to get platform list.")
    
    #Build the list of platforms we're going to pull data for via the IOOS Dif.
    try:           
      if(platformWhitelist == None):
        platformRecs = self.inventory.db.session.query(platform).\
                    join((organization,organization.row_id == platform.organization_id)).\
                    filter(organization.short_name == self.inventory.organizationID).\
                    all()
      else:
        platformRecs = self.inventory.db.session.query(platform).\
                    join((organization,organization.row_id == platform.organization_id)).\
                    filter(organization.short_name == self.inventory.organizationID).\
                    filter(platform.short_name.in_(platformWhitelist)).\
                    all()
      endTime = datetime.datetime.utcnow()
      startTime = endTime - datetime.timedelta(hours=self.lastNHours)
      
      endTime = endTime.strftime("%Y-%m-%dT%H:%M:00Z")
      startTime = startTime.strftime("%Y-%m-%dT%H:%M:00Z")
      
      #This is the queue used to send database records for processing.
      self.dataQueue = Queue.Queue(0)
      dataSaver = dataSaveWorker(self.configFilename, self.dataQueue)
      dataSaver.start()
      
      for platRec in platformRecs:
        #First pass make a list of the NDBC observations the platform has. NDBC
        #has comprehensive observations of Winds, Waves, and Currents. We don't want to run
        #multiple web queries for the individual platform observations such as wind_speed and direction
        #since they are contained in the single NDBC query.   
        obsCategory = []
        for sensor in platRec.sensors:
          obsName = sensor.m_type.scalar_type.obs_type.standard_name
          difObs = self.inventory.xeniaDataMappings.getDifObsNameFromXenia(obsName)
          if(difObs in obsCategory) == False:
            obsCategory.append(difObs)
        if(self.logger):
           self.logger.info("Processing platform: %s" % (platRec.short_name))
        for ndbcObsCat in obsCategory:
          offeringString = "urn:ioos:station:%s:%s" % (self.stationoffering,platRec.short_name )
          """
          data = self.difObj.getObservation(
                     offering=offeringString, 
                     observedproperty=ndbcObsCat,
                     responseformat='text/csv',
                     eventtime=('%s/%s' % (startTime,endTime))
                    )
          """
          try:
            if(self.logger):
              self.logger.info("getObservation for: %s" %(ndbcObsCat))
            self.difGetObs.getObservation( offering=offeringString, 
                                           observedproperty=ndbcObsCat,
                                           eventtime=('%s/%s' % (startTime,endTime)))
            #Keep looping until no more rows are available.
            while True:
              recList = self.difGetObs.getTimeSeriesRow(self.inventory.db, platRec.platform_handle, rowEntryDate)          
              if(len(recList)):
                for dataRec in recList:
                  self.dataQueue.put(dataRec)
                #recList = self.parseReturnData(platRec, ndbcObsCat, data, rowEntryDate)
              else:
                break
          except difError,e:
            if(self.logger):
              self.logger.error(e)
      
        if(self.logger):
	  self.logger.debug("Approximate record count in DB queue: %d" % (self.dataQueue.qsize()))

      if(self.logger):
        self.logger.info("Signalling worker queue to shut down.")
      #Wait until all the records are processed.
      self.dataQueue.put(None)
      self.dataQueue.join()
      if(self.logger):
        self.logger.info("Worker queue shut down.")
      
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)
       
  def saveData(self, recordList):    
    try:
      self.inventory.db.session.add(dataRec)              
      self.inventory.db.session.commit()
    #Trying to add record that already exists.
    except exc.IntegrityError, e:
      self.inventory.db.session.rollback()        
      if(self.logger):
        self.logger.debug(e.message)                          
    except Exception, e:
      self.inventory.db.session.rollback()        
      if(self.logger):
        self.logger.exception(e)
      sys.exit(-1)
    return
  
  def processData(self):
    if(self.checkForNewPlatforms):
      newRecs, platsMissingObs = self.inventory.findNew()
      self.inventory.outputRecords(newRecs, platsMissingObs)      
    self.getData()
    
  """
  def parseReturnData(self, platformRec, difObs, data, rowEntryDate):
    recList = []
    try:
      #Get the columns the CSV file is going to contain. 
      columnDefs = self.inventory.xeniaDataMappings.getHeaderColumnNames(difObs)      
      splitData = data.split("\n")
      #We use the column header list from above to map the rows into key/value pairs.
      csvData = csv.DictReader(splitData, columnDefs)
      lineNum = 0
      #Get the column names for specific bits we are interested in, latitude, longitude, datetime, ect.
      lonCol,latCol = self.inventory.xeniaDataMappings.getLonLatColumnNames()
      dateTimeCol = self.inventory.xeniaDataMappings.getDatetimeColumnName()
      depthCol = self.inventory.xeniaDataMappings.getDepthColumnName(difObs)
      #Based on the dif Observation we are processing, we get a mapping of dif Columns to xenia observations.
      #We loop through the xenia observations getting the data and creating database records.
      difObsMap = self.inventory.xeniaDataMappings.getDifColumnsFromObs(difObs)
      for dataRow in csvData:   
        if(lineNum > 0):        
          for xeniaKey in difObsMap:
            dataRec = multi_obs()             
            sOrder = 1
            #The units are encoded into the column name, for example:
            #sea_water_temperature (C)
            obsParts = re.findall("^(\w*)\s\((.{1,})\)", xeniaKey)
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = self.uomConverter.getXeniaUOMName(obsParts[0][1].lower())
            if(uom == None):
              uom = obsParts[0][1].lower()           
            dataRec.m_type_id = self.inventory.db.mTypeExists(difObsMap[xeniaKey], uom)
            dataRec.sensor_id = self.inventory.db.sensorExists(difObsMap[xeniaKey], uom, platformRec.platform_handle, sOrder)
            if(dataRec.m_type_id and dataRec.sensor_id):
              dataRec.m_date = dataRow[dateTimeCol]
              dataRec.row_entry_date = rowEntryDate
              dataRec.platform_handle = platformRec.platform_handle            
              try:
                dataRec.m_lon = float(dataRow[lonCol])
                dataRec.m_lat = float(dataRow[latCol])   
              except ValueError,e:
                if(self.logger):
                  self.logger.debug("Lat or Lon is not a valid number.")
                dataRec.m_lon = platformRec.fixed_longitude
                dataRec.m_lat = platformRec.fixed_latitude
              try:                          
                dataRec.m_value = float(dataRow[xeniaKey])
              except ValueError,e:
                if(self.logger):
                  self.logger.debug("m_value is not a valid number.")
                dataRec.m_value = None
              try:
                if(depthCol):                
                  dataRec.m_z = float(dataRow[depthCol])
              except ValueError,e:
                if(self.logger):
                  self.logger.debug("Depth is not a valid number.")
                dataRec.m_z = None

              recList.append(dataRec)              
                
              if(self.logger):
                depth = '%s' %(dataRec.m_z) 
                self.logger.debug("Obs: %s(%d) DateTime: %s Value: %s Depth: %s" % (difObsMap[xeniaKey], dataRec.sensor_id, dataRec.m_date, dataRow[xeniaKey], depth))
            else:
              if(self.logger):
                self.logger.error("No m_type_id or sensor_id found for observation: %s" %(ndbcObsMap[xeniaKey]))        
        lineNum += 1
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.error("Column def: %s does not exist, cannot parse data." % (ndbcObsCat))        
    except Exception, e:        
      if(self.logger):
        self.logger.exception(e)
        
    return(recList)
   """


if __name__ == '__main__':
  
  logger = None
  try:    
    parser = optparse.OptionParser()  
    parser.add_option("-c", "--ConfigFile", dest="configFile",
                      help="Configuration file" )
    (options, args) = parser.parse_args()

    configFile = ConfigParser.RawConfigParser()
    configFile.read(options.configFile)

    logFile = configFile.get('logging', 'configfile')
    
    logging.config.fileConfig(logFile)
    logger = logging.getLogger("data_ingestion_logger")
    logger.info('Log file opened')
    
    #Get the list of organizations we want to process. These are the keys to the [APP] sections on the ini file we 
    #then use to pull specific processing directives from.
    orgList = configFile.get('processing', 'organizationlist')
    orgList = orgList.split(',')
    
    for orgId in orgList:
      if(logger):
        logger.info("Processing organization: %s." %(orgId))
      #Get the processing object.
      processingObjName = configFile.get(orgId, 'processingobject')      
      if(processingObjName in globals()):
         processingObjClass = globals()[processingObjName]
         processingObj = processingObjClass(orgId, options.configFile, logger)
         processingObj.processData()
      else:
        if(logger):
          logger.error("Processing object: %s does not exist, skipping." %(processingObjName))   
    


    logger.info('Log file closing.')

  except Exception, E:
    if(logger != None):
      logger.exception(E)
    else:
      import traceback
      traceback.print_exc()

    
