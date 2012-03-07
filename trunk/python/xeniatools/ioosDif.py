import sys
import re
import urllib
import urllib2
import socket 
import logging

from lxml import etree    
from lxml import objectify
from pykml import kml

from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, sensor 


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
      #Set the timeout so we don't hang on the urlopen calls.
      socket.setdefaulttimeout(30)
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
    except ValueError:
      lat = lon = None            
    return(lon,lat)
  
  def getStationDescription(self, stationProperty):
    desc = stationProperty['{http://www.opengis.net/gml}description'].text
    return(desc)      
  
  def getStationTimePeriod(self, stationProperty):
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
     
class xeniaMappings(object):
  def __init__(self, jsonFilepath=None):
    self.mappings = None
    if(jsonFilepath):
      import simplejson as json
      jsonFile = open(jsonFilepath, 'r')
      self.mappings = json.load(jsonFile)
              
  def configMapping(self, mappingData):
    return(None)
  
  def buildMTypeMapping(self, db, uomConverter):
    mTypeMap = {}
    if 'observation_columns' in self.mappings:
      for difOb in self.mappings['observation_columns']:
        for difCol in self.mappings['observation_columns'][difOb]['m_value_columns']:
          xeniaKey = difCol.keys()[0]
          xeniaOb = difCol[xeniaKey] 
          if(len(xeniaOb)):
            obsParts = re.findall("^(\w*)\s\((.{1,})\)", xeniaKey)
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = uomConverter.getXeniaUOMName(obsParts[0][1].lower())
            if(uom == None):
              uom = obsParts[0][1].lower()           
            mTypeMap[xeniaOb] = db.mTypeExists(xeniaOb, uom)
      self.mappings['mTypes'] = mTypeMap
    return
  
  def getMtypeFromXenia(self, xeniaObs):
    mTypeId = self.mappings['mTypes'][xeniaObs]
    return(mTypeId)
  
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
