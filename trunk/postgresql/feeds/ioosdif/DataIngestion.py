import sys
import optparse
import logging
import logging.config
import ConfigParser
import urllib
import urllib2 
import datetime
import re
from lxml import etree    
from lxml import objectify
from pykml import kml

import shapely
from shapely.geometry import Polygon, Point

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from sqlalchemy import or_
from sqlalchemy.sql import column
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 
from xeniatools.xenia import uomconversionFunctions

#from geoalchemy import *


class platformInventory:
  def __init__(self, configurationFile, logger=None):
    self.logger = logger
    
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
    

  def getKnownPlatforms(self):
    return(None)

  def findNew(self):      
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
    #the owner of the platform may be another entitiy. Let's do a secondary search to see if we find a platform at the same location.        
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
  def __init__(self, configFile, logger=None):
    self.logger = logger
    self.config = ConfigParser.RawConfigParser()
    self.config.read(configFile)
  
  def processData(self):
    return(None)
    
  def getData(self):
    return(None)
  
  def saveData(self):
    return(None)

class ndbcXeniaObsMappings(object):
  def __init__(self):
    self.ndbcToXeniaMap = {
      'air_pressure_at_sea_level' : {'air_pressure_at_sea_level (hPa)' : 'air_pressure'},
      'air_temperature' : {"air_temperature (C)" : 'air_temperature'},
      'sea_water_temperature' : {"sea_water_temperature (C)" : 'water_temperature'},
      'sea_water_salinity' : {"sea_water_salinity (psu)" : 'salinity'},
      'sea_water_electrical_conductivity' : {"sea_water_electrical_conductivity (mS/cm)" : 'water_conductivity'},
      'sea_floor_depth_below_sea_surface' : {"sea_floor_depth_below_sea_surface (m)" : 'depth' },      
      'currents' : { "direction_of_sea_water_velocity (degree)" : "current_to_direction",
                      "sea_water_speed (cm/s)" : "current_speed"},
      'winds' : {"wind_from_direction (degree)" : "wind_from_direction",
                  "wind_speed (m/s)" : "wind_speed",
                  "wind_speed_of_gust (m/s)" : "wind_gust"},
      'waves' : {"sea_surface_wave_significant_height (m)" : "significant_wave_height", 
                 "sea_surface_swell_wave_significant_height (m)" : "swell_height",
                 "sea_surface_wind_wave_significant_height (m)" : "wind_wave_height",
                 "sea_surface_wind_wave_period (s)" : "wind_wave_period",
                 "sea_surface_swell_wave_period (s)" : "dominant_wave_period",
                 "sea_surface_wave_mean_period (s)" : "average_wave_period",
                 "principal_wave_direction (degree)" : "principal_wave_direction", 
                 "sea_surface_wind_wave_to_direction (degree)" : "wind_wave_direction",
                 "sea_surface_swell_wave_to_direction (degree)" : "swell_wave_direction",
                 "sea_surface_wave_to_direction (degree)" : "significant_wave_to_direction",
                 "mean_wave_direction (degree)" : "mean_wave_direction_peak_period"}
      
    }
    
  def getNDBCObs(self, xeniaObs):   
    for ndbcObsMap in self.ndbcToXeniaMap:
      mapping = self.ndbcToXeniaMap[ndbcObsMap]
      for ndbcColKey in mapping:
        if(xeniaObs == mapping[ndbcColKey]):
          return(ndbcObsMap)
    return(None)
              
  def getNDBCColumnsFromNDBCObs(self, ndbcObs):
    for ndbcObsMap in self.ndbcToXeniaMap:
      if(ndbcObs == ndbcObsMap):
        mapping = self.ndbcToXeniaMap[ndbcObs]
        return(mapping)
    return(None)            
    
class xeniaNDBCInventory(platformInventory):
  def __init__(self, configurationFile, logger):
    platformInventory.__init__(self,configurationFile, logger)
    
    #This is the organization ID we use in the xenia structure, for example NDBC, NWS....
    self.organizationID = self.config.get('ndbc', 'organizationID')
    
    url = self.config.get('ndbc', 'difurl')
    self.difObj = ioosDif(url)
    
    self.bbox = self.config.get('area', 'bbox')
    self.ndbcToXeniaMap = {
      'air_pressure_at_sea_level' : {'air_pressure_at_sea_level (hPa)' : 'air_pressure'},
      'air_temperature' : {"air_temperature (C)" : 'air_temperature'},
      'sea_water_temperature' : {"sea_water_temperature (C)" : 'water_temperature'},
      'sea_water_salinity' : {"sea_water_salinity (psu)" : 'salinity'},
      'sea_water_electrical_conductivity' : {"sea_water_electrical_conductivity (mS/cm)" : 'water_conductivity'},
      'sea_floor_depth_below_sea_surface' : {"sea_floor_depth_below_sea_surface (m)" : 'depth' },      
      'currents' : { "direction_of_sea_water_velocity (degree)" : "current_to_direction",
                      "sea_water_speed (cm/s)" : "current_speed"},
      'winds' : {"wind_from_direction (degree)" : "wind_from_direction",
                  "wind_speed (m/s)" : "wind_speed",
                  "wind_speed_of_gust (m/s)" : "wind_gust"},
      'waves' : {"sea_surface_wave_significant_height (m)" : "significant_wave_height", 
                 "sea_surface_swell_wave_significant_height (m)" : "swell_height",
                 "sea_surface_wind_wave_significant_height (m)" : "wind_wave_height",
                 "sea_surface_wind_wave_period (s)" : "wind_wave_period",
                 "sea_surface_swell_wave_period (s)" : "dominant_wave_period",
                 "sea_surface_wave_mean_period (s)" : "average_wave_period",
                 "principal_wave_direction (degree)" : "principal_wave_direction", 
                 "sea_surface_wind_wave_to_direction (degree)" : "wind_wave_direction",
                 "sea_surface_swell_wave_to_direction (degree)" : "swell_wave_direction",
                 "sea_surface_wave_to_direction (degree)" : "significant_wave_to_direction",
                 "mean_wave_direction (degree)" : "mean_wave_direction_peak_period"}
      
    }
    
    
  def findNew(self):
    
    newPlatforms = []
    newPlatformsKML = None
    try:
      url = self.config.get('ndbc', 'newplatformkml')
      newPlatformsKML = kml.KML()    
      placemarks = []
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.debug("newplatformkml option does not exist, not creating new platforms kml file.")
    
    try:
      filePath = self.config.get('settings', 'uomconversionfile')
      uomConverter = uomconversionFunctions(filePath)
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)

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
      treeRoot = self.difObj.getCapabilities()
      for station in treeRoot.Contents.ObservationOfferingList.iterchildren():
        if '{http://www.opengis.net/gml}id' in station.attrib and (station.attrib['{http://www.opengis.net/gml}id'] != 'network-all'):
          #The is stored as 'station-xxxxx', we want to split it up and just get the station id(xxxxxx)
          id = station.attrib['{http://www.opengis.net/gml}id'].split('-')[1]
          lowerCorner = station['{http://www.opengis.net/gml}boundedBy'].Envelope.lowerCorner
          lowerCorner = lowerCorner.text.split(' ')
          lat = float(lowerCorner[0])          
          lon = float(lowerCorner[1])
          stationPt = shapely.wkt.loads('POINT(%s %s)' %(lon,lat))
          if(stationPt.within(bboxPoly)):
            if(self.logger):
              self.logger.debug("Station: %s Lon: %s Lat: %s in region" % (id,lat,lon))
            desc = station['{http://www.opengis.net/gml}description'].text          
            foundPlatform = self.platformInInventory(platformRecs, bboxPoly, id, lat, lon, desc)
            if(foundPlatform == False):
              
              #platInfo = self.difObj.describeSensor(station['{http://www.opengis.net/gml}name'].text)
              platHandle = "ndbc.%s.met" % (id)
              pm = None
              if(newPlatformsKML):
                pm = newPlatformsKML.createPlacemark(platHandle, lat, lon, desc)
                placemarks.append(pm)
              #SQL = "INSERT INTO platform (fixed_latitude,fixed_longitude,short_name,platform_handle,description) VALUES(%4.3f,%4.3f,'%s','%s','%s')"\
              # % (lat,lon,id,platHandle,desc)
              newRec = None
              if(desc != 'Glider'):
                newRec = platform()
                newRec.short_name = id
                newRec.platform_handle = platHandle;
                newRec.row_entry_date = rowEntryDate
                newRec.fixed_latitude = lat
                newRec.fixed_longitude = lon
                newRec.organization_id = platformRecs[0].organization_id
                newRec.description = desc
                newRec.active = 3
              sensors = ""
              sensorRecs = []
              for obsProperty in station.observedProperty:
                #The attribute is a url to the observation. We're not going to follow the url, we just want the
                #observation name so split the url up and get the last piece.
                obsType = obsProperty.attrib['{http://www.w3.org/1999/xlink}href'].split('/')[-1]
                #Use the obsType as a key into the mapping.
                if obsType in self.ndbcToXeniaMap:
                  xeniaObs = self.ndbcToXeniaMap[obsType]
                  for obsKey in xeniaObs:  
                    xeniaOb = xeniaObs[obsKey]
                    sensors += "obsName: %s\n" % (xeniaOb)
                    obsParts = re.findall("^(\w*)\s\((.{1,})\)", obsKey)
                    #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
                    uom = uomConverter.getXeniaUOMName(obsParts[0][1].lower())
                    if(uom == None):
                      uom = obsParts[0][1].lower()
                    #Get the m_type_id for the sensor rec.
                    mType = self.db.mTypeExists(xeniaOb, uom)
                    if(mType):
                      newSensor = sensor()
                      newSensor.row_entry_date = rowEntryDate
                      newSensor.active = 3
                      newSensor.m_type_id = mType
                      newSensor.s_order = 1
                      newSensor.short_name = xeniaOb
                      sensorRecs.append(newSensor)
                      if(self.logger):
                        self.logger.info("Adding sensor: %s MType: %d SOrder: %d" % (newSensor.short_name,newSensor.m_type_id,newSensor.s_order))
                    else:
                      if(self.logger):
                        self.logger.error("Unable to find the m_type for Obs: %s(%s)" % (xeniaOb, uom))
                        sys.exit(-1)

                else: 
                  if(self.logger):
                    self.logger.error("GetCapabilities observedProperty: %s not found in xenia obs mapping." %(obsType))
              
              if(newRec):
                newRec.sensors = sensorRecs
                platId = self.db.addPlatform(newRec, True)  
              
#              if(newPlatformsTXT):
#                newPlatformsTXT.write("%s\n" % (sensors))
              if(self.logger):
                self.logger.info("New Platform found. Id: %s Lon: %s Lat: %s Info: %s\n%s" % (id, lon, lat, desc, sensors))                
                  
                
    #handle errors
    except urllib2.HTTPError, e:
      if(self.logger):
        self.logger.exception(e)
    except urllib2.URLError, e:
      if(self.logger):
        self.logger.exception(e)
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
    
    #Query the currently active platforms in our database.
    #for newPlatform in newPlatforms:
    if(len(placemarks)):
      newPlatsDoc = newPlatformsKML.createDocument("Potential new platforms")
      for pm in placemarks:
        newPlatsDoc.appendChild(pm)
      newPlatformsKML.appendChild(newPlatsDoc)
      kmlFile = open("c:\\temp\\newPlatforms.kml", "w")
      kmlFile.writelines(newPlatformsKML.writepretty())
      kmlFile.close()
    if(newPlatformsTXT):
      newPlatformsTXT.close()
    return(newPlatforms)

class ioosDif(object):
  def __init__(self, sosUrl, logger=None):
    self.logger = logger
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
    results = objectify.fromstring(self.doRequest(parameters))      
    return(results)
  
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
    if(eventtime):
      parameters['eventtime'] = eventtime
    if(featureofinterest):
      parameters['featureofinterest'] = featureofinterest
    
    return(self.doRequest(parameters))  

  def getDifObsName(self, xeniaObsName):
    return(None)

"""  
class ndbcDif(ioosDif):
  def __init__(self, sosUrl, logger=None):
    ioosDif.__init__(sosUrl, logger)
    self.obsMap = {
    }
    
  def getDifObsName(self, xeniaObsName):
"""  
class ndbcDataIngestion(dataIngestion):
  def __init__(self, configFile, logger=None):
    dataIngestion.__init__(self, configFile, logger)
    try:
      self.newDataRecs = []
      
      url = self.config.get('ndbc', 'difurl')
      self.lastNHours = float(self.config.get('ndbc', 'lastnhours'))
      self.difObj = ioosDif(url)
      self.inventory = xeniaNDBCInventory(configFile, logger)
  
      #The observations available for NDBC platforms being served up through dif services.
      #We loop and request the data for each obs, the station might not have it.
      self.ndbcXeniaMap = ndbcXeniaObsMappings() 
  
      #Get the units conversion XML file. Use it to translate the NDBC units into xenia uoms.
      filePath = self.config.get('settings', 'uomconversionfile')
      self.uomConverter = uomconversionFunctions(filePath)
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
        sys.exit(-1)
    
  def processData(self):
    
    #Date/time to use for the row_entry_date in the database. We use local time.
    rowEntryDate = datetime.datetime.today().strftime("%Y-%m-%dT%H:%M:%S")

    platformWhitelist = None    
    try:
      platformWhitelist = self.config.get('ndbc', 'whitelist')
      platformWhitelist = platformWhitelist.split(',')
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.info("whitelist option does not exist, using the organization name to get platform list.")
    
    try:      
      #We ask for the data to be sent in a csv format, however observation like Current and Waves have complex
      #responses that aren't just a data point. We get the csv header from the ini file to figure out how to pick
      #apart the data.
      
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
      endTime = datetime.datetime.now()
      startTime = endTime - datetime.timedelta(hours=self.lastNHours)
      
      endTime = endTime.strftime("%Y-%m-%dT%H:%MZ")
      startTime = startTime.strftime("%Y-%m-%dT%H:%MZ")
      
      
      for platRec in platformRecs:
        #First pass make a list of the NDBC observations the platform has. NDBC
        #has comprehensive observations of Winds, Waves, and Currents. We don't want to run
        #multiple web queries for the individual platform observations such as wind_speed and direction
        #since they are contained in the single NDBC query.   
        obsCategory = []
        for sensor in platRec.sensors:
          obsName = sensor.m_type.scalar_type.obs_type.standard_name
          ndbcObs = self.ndbcXeniaMap.getNDBCObs(obsName)
          if(ndbcObs in obsCategory) == False:
            obsCategory.append(ndbcObs)
        if(self.logger):
           self.logger.debug("Processing platform; %s" % (platRec.short_name))
        for ndbcObsCat in obsCategory:
          data = self.difObj.getObservation(
                     offering='urn:ioos:station:wmo:%s' %(platRec.short_name), 
                     observedproperty=ndbcObsCat,
                     responseformat='text/csv',
                     eventtime=('%s/%s' % (startTime,endTime))
                    )
          if(data):
            dataRecs = self.parseReturnData(platRec, ndbcObsCat, data, rowEntryDate)
          else:
            if(self.logger):
              self.logger.debug("No data returned in getObservation query for platform: %s Time: %s - %s" %(platRec.short_name,startTime,endTime))
          
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)
    
  def parseReturnData(self, platformRec, ndbcObs, data, rowEntryDate):
    import csv
    dataRecs = []
    try:
      #Get the columns that are in the getObservation query. These columns are what we should expect in the CSV response from
      #the getObservations query. The columns are stored in the ini file and then used to create the column to data mapping.
      columnDefs = self.config.get('ndbc', ndbcObs)
      columnDefs = columnDefs.split(',')
    
      splitData = data.split("\n")
      csvData = csv.DictReader(splitData, columnDefs)
      lineNum = 0
      for dataRow in csvData:   
        dataRec = multi_obs() 
        if(lineNum > 0):        
          ndbcObsMap = self.ndbcXeniaMap.getNDBCColumnsFromNDBCObs(ndbcObs)
          for xeniaKey in ndbcObsMap:
            sOrder = 1
            dataRec.m_date = dataRow['date_time']
            dataRec.row_entry_date = rowEntryDate
            dataRec.platform_handle = platformRec.platform_handle
            try:
              dataRec.m_lon = float(dataRow['longitude (degree)'])
              dataRec.m_lat = float(dataRow['latitude (degree)'])                       
              dataRec.m_z = float(dataRow["depth (m)"])
            except ValueError,e:
              dataRec.m_z = None
              dataRec.m_lon = platformRec.fixed_longitude
              dataRec.m_lat = platformRec.fixed_latitude
                         
            #The units are encoded into the column name, for example:
            #sea_water_temperature (C)
            obsParts = re.findall("^(\w*)\s\((.{1,})\)", xeniaKey)
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = self.uomConverter.getXeniaUOMName(obsParts[0][1].lower())
            if(uom == None):
              uom = obsParts[0][1].lower()           
            dataRec.m_type_id = self.inventory.db.mTypeExists(ndbcObsMap[xeniaKey], uom)
            dataRec.sensor_id = self.inventory.db.sensorExists(ndbcObsMap[xeniaKey], uom, platformRec.platform_handle, sOrder)
            try: 
              dataRec.m_value = float(dataRow[xeniaKey])
            except ValueError,e:
              dataRec.m_value = None
            if(self.logger):
               self.logger.debug("Obs: %s(%d) DateTime: %s Value: %s Depth: %s" % (ndbcObsMap[xeniaKey], dataRec.sensor_id, dataRec.m_date, dataRow[xeniaKey], dataRow["depth (m)"]))
          dataRecs.append(dataRec)          
        lineNum += 1
      try:
        self.inventory.db.session.add_all(dataRecs)              
        self.inventory.db.session.commit()
      except exc.IntegrityError, e:
        self.inventory.db.session.rollback()
        if(self.logger != None):
          self.logger.debug(e)                      
      except Exception, e:
        self.inventory.db.session.rollback()        
        if(self.logger):
          self.logger.exception(e)
        sys.exit(-1)                                   

    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.error("Column def: %s does not exist, cannot parse data." % (ndbcObsCat))
        
    except Exception, e:        
      if(self.logger):
        self.logger.exception(e)
    return(dataRecs)
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
    
    #ndbcInv = xeniaNDBCInventory(options.configFile, logger)
    #ndbcInv.findNew()
    
    ndbcData = ndbcDataIngestion(options.configFile, logger)
    ndbcData.processData()
    


    logger.info('Log file closing.')

  except Exception, E:
    if(logger != None):
      logger.exception(E)
    else:
      import traceback
      traceback.print_exc()

    