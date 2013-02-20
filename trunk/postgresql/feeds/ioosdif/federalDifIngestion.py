"""
Revisions
Date: 2013-02-20 DWR
Function: xeniaFedsInventory::findnew
Changes: Added check for configuration parameter 'newstationstoadd': THis allows a comma delimeted
list of stations to be added when 'addnewplatformstodb' and 'addnewplatformstodb' are set to 1
in the config file. The stations must be in the GetCapabilities query. 

Date: 2012-10-03 DWR
Function: fedsDataIngestion::getData
Changes: Added organizationWhitelist to allow organizations that are processed by the ndbc to also be queried. ALlows us to
use a handle that reflects the originating entity, not just NDBC.

Date: 2012-04-04
Function: difObservationCSV.getDataValue
Changes: Added general exception handler.
"""
import logging
import logging.config

import optparse
import csv
import re
import datetime

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from sqlalchemy import or_
from sqlalchemy.sql import column
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 
from xeniatools.xenia import uomconversionFunctions
from xeniatools.ioosDif import * 
from xeniatools.DataIngestion import * 
from pykml import kml

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
    if(self.logger):
      self.logger.debug("getObservation completed.")
    if(data != None):
      #Check to see if we got a valid response or an exception.
      if(data.find("ExceptionReport") == -1):      
        self.depthCol = self.xeniaToDifMapping.getDepthColumnName(observedproperty)
        self.difObsMap = self.xeniaToDifMapping.getDifColumnsFromObs(observedproperty)
        self.lineNum = 0
        #colDefs = self.xeniaToDifMapping.getHeaderColumnNames(observedproperty)      
        splitData = data.split("\n")
        #The first line contains the column headers. We use this to map them
        #into a dictionary as we read each row,
        self.csvHeader = splitData[0].replace('"', '')
        columnDefs = self.csvHeader.split(',')
        self.getObsData = csv.DictReader(splitData, columnDefs)
        self.header = self.getObsData.next()
        self.lineNum += 1
        return(True)
      else:
        if(self.logger):
          self.logger.error(data)
        #raise(difError(data))
    return(False)
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
    #DWR 2012-04-04
    #Add general exception handler. Could be a KeyError if dataColumn doesn't exist in the dataRow.
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(value)    
  
  def getTimeSeriesRow(self, xeniaDB, platformRec, rowEntryDate):
    recList = []
    #try:
    if(self.getObsData):
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
            
            mTypeId = self.xeniaToDifMapping.getMtypeFromXenia(xeniaOb) 
            for rec in platformRec.sensors:
              if(mTypeId == rec.m_type_id):
                dataRec.m_type_id = rec.m_type_id
                dataRec.sensor_id = rec.row_id
                break
            if(dataRec.m_type_id and dataRec.sensor_id):
              dataRec.m_date = self.getDateTime(dataRow)
              dataRec.row_entry_date = rowEntryDate
              dataRec.platform_handle = platformRec.platform_handle            
              dataRec.m_lon,dataRec.m_lat = self.getFixedLonLatValue(dataRow)    
              dataRec.m_value = self.getDataValue(xeniaKey, dataRow)
              if(dataRec.m_value == None and self.logger):
                self.logger.error("None data value returned.")                
              dataRec.m_z = self.getDepth(dataRow)
              recList.append(dataRec)
            else:
              if(self.logger):
                self.logger.error("No m_type_id or sensor_id found for observation: %s" %(xeniaOb))
        self.lineNum += 1
      #No more rows to pull, so we return the empty list.
      #except StopIteration:
      #  return(recList)      
    return(recList)



class xeniaFedsInventory(platformInventory):
  def __init__(self, organizationID, configurationFile, logger=True):    
    platformInventory.__init__(self, organizationID, configurationFile, logger)    
    try:
      self.config = ConfigParser.RawConfigParser()
      self.config.read(self.configurationFile)  
      
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
    #2013-02-20 DWR
    #Check to see if we have a list of stations we want to add. 
    stationAddList = None
    try:
      stationAddList = self.config.get(self.organizationID, 'newstationstoadd').split(',')          
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.debug("Config parameter: newstationstoadd not set, no specific stations will be added.")
    
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
            desc = self.difCap.getStationDescription(station)          
            if(self.logger):
              self.logger.debug("Checking station is in region: %s(%s)" % (id,desc))
            if(stationPt.within(bboxPoly)):
              if(self.logger):
                self.logger.debug("Station: %s Lon: %s Lat: %s in region" % (id,lat,lon))
              foundPlatform = self.platformInInventory(platformRecs, bboxPoly, id, lat, lon, desc)
              if(foundPlatform == False or (stationAddList and (id in stationAddList))):
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
    #2012-10-03 DWR
    #Removed the try/except and explicitly check to see if the parameters exist.
    #Added the organization whitelist.
    #If provided, this will only query the platforms in the whitelist.
    if(self.config.has_option(self.organizationID, 'whitelist')):
      platformWhitelist = self.config.get(self.organizationID, 'whitelist')
      if(self.logger):
        self.logger.info("Platform Whitelist: %s" % (platformWhitelist))
      platformWhitelist = platformWhitelist.split(',')
      
    #Some organizations use the federal backbone to aggregate their data. We want to 
    #make sure we keep their attribution.
    if(self.config.has_option(self.organizationID, 'organizationwhitelist')):
      organizationWhitelist = self.config.get(self.organizationID, 'organizationwhitelist')
      if(self.logger):
        self.logger.info("Organization Whitelist: %s" % (organizationWhitelist))
      
      #Add the organization this object is based on to the whitelist. This is just an easy
      #way to build the SQL in() list.
      organizationWhitelist = self.organizationID + ',' + organizationWhitelist
      organizationWhitelist = organizationWhitelist.split(',')
    
    #Build the list of platforms we're going to pull data for via the IOOS Dif.
    try:           
      if(platformWhitelist == None and organizationWhitelist == None):
        platformRecs = self.inventory.db.session.query(platform).\
                    join((organization,organization.row_id == platform.organization_id)).\
                    filter(organization.short_name == self.inventory.organizationID).\
                    all()
        if(self.logger):
          self.logger.debug("Org Id: %s returning: %d platforms." % (self.inventory.organizationID,len(platformRecs)))
      else:
        #2012-10-03 DWR
        #Broke up the query, to accomodate the platform and organization whitelist.
        platformRecs = self.inventory.db.session.query(platform).\
                    join((organization,organization.row_id == platform.organization_id))
        #Check for our whitelists, if they exists, add those filters to the query.
        if(platformWhitelist):
          platformRecs = platformRecs.filter(platform.short_name.in_(platformWhitelist))
        if(organizationWhitelist):
          platformRecs = platformRecs.filter(organization.short_name.in_(organizationWhitelist))
        else:
          platformRecs = platformRecs.filter(organization.short_name == self.inventory.organizationID)

        platformRecs.order_by(platform.row_id).all()
        """
        platformRecs = self.inventory.db.session.query(platform).\
                    join((organization,organization.row_id == platform.organization_id)).\
                    filter(organization.short_name == self.inventory.organizationID).\
                    filter(platform.short_name.in_(platformWhitelist)).\
                    all()
        """
      endTime = datetime.datetime.utcnow()
      startTime = endTime - datetime.timedelta(hours=self.lastNHours)
      
      endTime = endTime.strftime("%Y-%m-%dT%H:%M:00Z")
      startTime = startTime.strftime("%Y-%m-%dT%H:%M:00Z")
      
      #Build the mtype mapping
      self.inventory.xeniaDataMappings.buildMTypeMapping(self.inventory.db, self.uomConverter)
      #This is the queue used to send database records for processing.
      self.dataQueue = Queue.Queue(0)
      dataSaver = dataSaveWorker(self.configFilename, self.dataQueue)
      dataSaver.start()
      
      for platRec in platformRecs:
        #First pass make a list of the federal observations the platform has. NDBC/NOS
        #has comprehensive observations of Winds, Waves, and Currents. We don't want to run
        #multiple web queries for the individual platform observations such as wind_speed and direction
        #since they are contained in the single NDBC query.   
        if(self.logger):
           self.logger.info("Processing platform: %s" % (platRec.short_name))
        obsCategory = []
        for sensor in platRec.sensors:
          obsName = sensor.m_type.scalar_type.obs_type.standard_name
          difObs = self.inventory.xeniaDataMappings.getDifObsNameFromXenia(obsName)
          if(difObs in obsCategory) == False:
            obsCategory.append(difObs)
        for obsCat in obsCategory:
          offeringString = "urn:ioos:station:%s:%s" % (self.stationoffering,platRec.short_name )
          if(self.logger):
            self.logger.info("getObservation for: %s" %(obsCat))
          if(self.difGetObs.getObservation( offering=offeringString, 
                                         observedproperty=obsCat,
                                         eventtime=('%s/%s' % (startTime,endTime)))):
            try:
              #Keep looping until no more rows are available.
              getTimeSeriesRow = True
              if(self.logger):
                self.logger.debug("Processing time series data")                
              while getTimeSeriesRow:
                recList = self.difGetObs.getTimeSeriesRow(self.inventory.db, platRec, rowEntryDate)
                #self.saveData(recList)          
                for dataRec in recList:
                  self.dataQueue.put(dataRec)
            #StopIteration thrown whenever there are no more rows to process.
            except StopIteration:
              getTimeSeriesRow = False
              if(self.logger):
                self.logger.debug("Finished time series for %s" %(obsCat))
          else:
            if(self.logger):
              self.logger.error("No data or error returned in getObservation query.")

        if(self.logger):
          self.logger.debug("Approximate record count in DB queue: %d" % (self.dataQueue.qsize()))      
    
    except Exception, e:  
      if(self.logger):
        self.logger.exception(e)

    if(self.logger):
      self.logger.info("Signalling worker queue to shut down.")
    #Adding the none record tells the worker thread to stop processing whenever it hits it.
    self.dataQueue.put(None)
    #join blocks until the queue is emptied.
    self.dataQueue.join()
    if(self.logger):
      self.logger.info("Worker queue shut down.")
    
    self.inventory.db.disconnect()
       
  def saveData(self, recordList):    
    try:
      for dataRec in recordList:
        self.inventory.db.session.add(dataRec)              
        self.inventory.db.session.commit()
        if(self.logger):
          val = ""
          if(dataRec.m_value != None):
            val = "%f" % (dataRec.m_value)
          logger.debug("Committing record Sensor: %d Datetime: %s Value: %s" %(dataRec.sensor_id, dataRec.m_date, val))
        
    #Trying to add record that already exists.
    except exc.IntegrityError, e:
      self.inventory.db.session.rollback()        
      #if(self.logger):
      #  self.logger.debug(e.message)                          
    except Exception, e:
      self.inventory.db.session.rollback()        
      if(self.logger):
        self.logger.exception(e)
      sys.exit(-1)
    return
  
  def processData(self):
    #2012-10-03 DWR
    #Adding the logsql parameter.
    if(self.inventory.connectDB(logsql=False)):        
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
