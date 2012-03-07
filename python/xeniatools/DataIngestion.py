import logging
import ConfigParser

import threading
import Queue

import shapely
from shapely.geometry import Polygon, Point

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from sqlalchemy import or_
from sqlalchemy.sql import column
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 




class dataSaveWorker(threading.Thread):
  def __init__(self, configFile, dataQueue, logger=True):
    self.__dataQueue = dataQueue
    self.configFilename = configFile
    self.loggerFlag = logger 
    threading.Thread.__init__(self, name="data_saver")

  #This is the worker thread that handles saving the records to the database.
  def run(self):
    if(self.loggerFlag):
      logger = logging.getLogger(type(self).__name__)
      logger.info("Starting %s thread." % (self.getName()))
    try:
      processData = True
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
        processData = False

        #sys.exit(-1)            
    except ConfigParser.Error, e:  
      if(logger):
        logger.exception(e)
    
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
          logger.info("%s thread exiting." % (self.getName()))
        processData = False
      self.__dataQueue.task_done()
      
    db.disconnect()  
              
              
class platformInventory:
  def __init__(self, organizationID, configurationFile, logger=True):
    self.organizationID = organizationID
    self.configurationFile = configurationFile    
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)
    
  def connectDB(self):
    try:
      config = ConfigParser.RawConfigParser()
      config.read(self.configurationFile)  
      dbUser = config.get('Database', 'user')
      dbPwd = config.get('Database', 'password')
      dbHost = config.get('Database', 'host')
      dbName = config.get('Database', 'name')
      dbConnType = config.get('Database', 'connectionstring')
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
      return(False)
    try:
      self.db = xeniaAlchemy(self.logger)      
      if(self.db.connectDB(dbConnType, dbUser, dbPwd, dbHost, dbName, False) == True):
        if(self.logger):
          self.logger.info("Succesfully connect to DB: %s at %s" %(dbName,dbHost))
          return(True)
      else:
        self.logger.error("Unable to connect to DB: %s at %s." %(dbName,dbHost))
    except Exception,e:
      self.logger.exception(e)
    return(False)
  
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
      #distColResult = "'%s'" % (stationPt.wkt)
      
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

    

    
