import sys
from math import fabs 
import optparse
import logging
import logging.config
import time
import datetime
from pytz import timezone
import string
import pymysql
import poplib 
import email
from email import parser as emailParser
import decimal

from xeniatools.DataIngestion import *
from xeniatools.ioosDif import xeniaMappings
from xeniatools.xenia import uomconversionFunctions,statusFlags

from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor, collection_run, collection_type 


from sqlalchemy import Column, Integer
from sqlalchemy.orm import relationship
from sqlalchemy import ForeignKey
from sqlalchemy import func 
from sqlalchemy.sql.expression import or_, and_

#from pykml_factory.factory import nsmap
from pykml_factory.factory import KML_ElementMaker as KML
from pykml_factory.factory import GX_ElementMaker as GX
#from pykml_factory.parser import Schema
from lxml import etree
from shapely.geometry import LineString

class glider_multi_obs(multi_obs):
  collection_id   = Column(Integer, ForeignKey(collection_run.row_id))
  collection_id_2 = Column(Integer, ForeignKey(collection_run.row_id))
  
  #collection_run  = relationship("collection_run", order_by="collection.row_id", backref="gliders_multi_obs")


"""
Base = declarative_base()

class Missions(Base):
  __tablename__ = 'Missions'
  
  mission_id    = Column(INTEGER,primary_key=True)                     
  start_date    = Column(DATE)  
  end_date      = Column(DATE)  
  glider        = Column(VARCHAR(25))
  
  
class TableNames(Base):
  __tablename__ = 'TableNames'
  
  glider        = Column(CHAR(15), primary_key=True)                     
  sensor_name   = Column(CHAR(50), primary_key=True)                     
  table_name    = Column(CHAR(50))                     
  sensor_unit   = Column(CHAR(50))                    
  
  
class SensorTable(Base):
  __tablename__ = 'Table_'

  sensor_value = Column(DECIMAL(25,12), primary_key=True)    
  time         = Column(DECIMAL(15,5) , primary_key=True) 
  lat          = Column(DECIMAL(18,12))    
  gps_lat      = Column(DECIMAL(18,12))    
  inter_lat    = Column(DECIMAL(18,12))    
  lon          = Column(DECIMAL(18,12))    
  gps_lon      = Column(DECIMAL(18,12))    
  inter_lon    = Column(DECIMAL(18,12))    
  depth        = Column(DECIMAL(25,12))    
  inter_depth  = Column(DECIMAL(25,12))     
  
  
class webbGliderDB(object):
  def __init__(self, logger=None):
    self.dbEngine = None
    self.metadata = None
    self.session  = None
    self.logger   = logger
    
  def connect(self, databaseType, dbUser, dbPwd, dbHost, dbName, dbPort, printSQL = False):    
    try:

      pymysql_sa.make_default_mysql_dialect()
      
      #Connect to the database
      connectionString = "%s://%s:%s@%s/%s" %(databaseType, dbUser, dbPwd, dbHost, dbName)
         
      self.dbEngine = create_engine(connectionString, echo=printSQL)
      
      #metadata object is used to keep information such as datatypes for our table's columns.
      self.metadata = MetaData()
      self.metadata.bind = self.dbEngine
      
      Session = sessionmaker(bind=self.dbEngine)  
      self.session = Session()
      
      self.connection = self.dbEngine.connect()
      
      return(True)
    except exc.OperationalError, e:
      if(self.logger != None):
        self.logger.exception(e)
    return(False)
"""  

class gliderDataSaveWorker(threading.Thread):
  def __init__(self, configFile, dataQueue, commitEach=True, logger=True):
    self.__dataQueue = dataQueue
    self.configFilename = configFile
    self.loggerFlag = logger 
    self.commitEach = commitEach
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
    except Exception,e:
      if(logger):
        logger.exception(e)                
    else:
      recCount = 0
      #This is the data processing part of the thread. We'll loop here until a None record is posted then exit. 
      while processData:
        dataRec = self.__dataQueue.get()
        if(dataRec != None):
          try:
            db.session.add(dataRec)
  
            if(self.commitEach == False):
              if((recCount % 100) == 0):
                if(logger):
                  logger.debug("Committing records.")              
                db.session.commit()
            else:
              db.session.commit()
                
            if(logger):
              if((recCount % 10) == 0):
                logger.debug("Approximate record count in DB queue: %d" % (self.__dataQueue.qsize()))
            recCount += 1        
          #Trying to add record that already exists.
          except exc.IntegrityError, e:
            db.session.rollback()        
            if(logger):
              logger.debug(e.message)                          
          except Exception, e:
            db.session.rollback()        
            if(logger):
              logger.exception(e)
            #sys.exit(-1)
        else:
          try:
            db.session.commit()
          except Exception, e:
            db.session.rollback()        
            if(logger):
              logger.exception(e)
          if(logger):
            logger.info("%s thread exiting." % (self.getName()))
          processData = False
        self.__dataQueue.task_done()
        
      db.disconnect()  
  
  
class xeniaWebbMappings(xeniaMappings):
  def __init__(self, jsonFilepath=None):
    xeniaMappings.__init__(self,jsonFilepath)
  
  def getUOMCol(self):
    uom = None
    if "uom" in self.mappings:
      uom = self.mappings['uom']
    return(uom)
  
  def getGliderObservations(self):
    gliderObs = []
    if 'observation_columns' in self.mappings:
      gliderObs = self.mappings['observation_columns'].keys()
    return(gliderObs)
      
class webbGliders(xeniaDataIngestion):
  def __init__(self, organizationId, configFile, logger=False):
    xeniaDataIngestion.__init__(self, organizationId, configFile, logger)
    
    self.configFile = configFile
    self.dbWebbConn = None       

  def connect(self):
    xeniaDataIngestion.connect(self)
    try:
      #Remote glider database
      webbDBHost = self.config.get(self.organizationId , 'webbhost')
      webbDBUser = self.config.get(self.organizationId , 'webbuser')
      webbDBPwd = self.config.get(self.organizationId , 'webbpassword')
      webbDBName = self.config.get(self.organizationId , 'webbname')
      webbDBPort = int(self.config.get(self.organizationId , 'webbport'))
            
      mappingsJson = self.config.get(self.organizationId , 'jsonconfig')      
      uomFilepath = self.config.get('settings', 'uomconversionfile')

      #Are we processing historic data, or new data?
      self.processNewMissions = bool(int(self.config.get(self.organizationId, 'checkfornewmissions')))
            
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    else:                              
      try:
        self.mappings = xeniaWebbMappings(mappingsJson)
        #Get the units conversion XML file. Use it to translate the units into xenia uoms.
        self.uomConverter = uomconversionFunctions(uomFilepath)
        #Attempt to connect to the glider database
        self.dbWebbConn = pymysql.connect(host=webbDBHost, port=webbDBPort, user=webbDBUser, passwd=webbDBPwd, db=webbDBName)
        if(self.logger):
          self.logger.info("Successfully connected to Webb DB: %s @ %s", webbDBName, webbDBHost)
                    
        #Thread and queue for the worker thread that saves records to the database.
        self.dataQueue = Queue.Queue(0)
        self.dbSaver = gliderDataSaveWorker(self.configFile, self.dataQueue, False, True)
        self.dbSaver.start()
        
        return(True)
      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
                              
    return(False)
  
   
  def disconnect(self):
    xeniaDataIngestion.disconnect(self)
    if(self.dbSaver.isAlive()):
      if(self.logger):
        self.logger.info("Signalling worker queue to shut down.")
      #Adding the none record tells the worker thread to stop processing whenever it hits it.
      self.dataQueue.put(None)
      #join blocks until the queue is emptied.    
      self.dataQueue.join()
      if(self.logger):
        self.logger.info("Worker queue shut down.")
    else:
      if(self.logger):
        self.logger.debug("Worker thread is already dead.")
      
    try:
      if(self.dbWebbConn):
        self.dbWebbConn.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        
  def remoteKeepAlive(self):
    try:
      cur = self.dbWebbConn.cursor(pymysql.cursors.DictCursor)
      sql = "SELECT * FROM Missions LIMIT 1;"
      cur.execute(sql)
      gliderName = None
      cur.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)

  def processData(self):
    if(self.connect()): 
      checkForNewPlats = bool(int(self.config.get(self.organizationId , 'checkfornewplatforms'))) 
      if(checkForNewPlats):
        self.addGliders()                 
      self.getData()

  def addGliders(self):
    rowEntryDate = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    
    newPlatforms = []      
    #Get the organization ID.
    try:
      orgId = self.xeniaDb.session.query(organization.row_id).\
                  filter(organization.short_name == self.organizationId).\
                  one()
    #Organization not found, so we'll add it to the add list.
    except NoResultFound:              
      i=0
    #Get the list of gliders from the datasource.
    missions = self.getGliderMissions()
    gliderList = missions.keys()
    gliderObsList = self.getGliderAndObsList(gliderList)
    #Now let's check against the xenia database to see if they exist.
    for glider in gliderList:
      platformHandle = "%s.%s.glider" % (self.organizationId , glider)
      try:
        platformRec = self.xeniaDb.session.query(platform).\
                    filter(platform.platform_handle == platformHandle).\
                    one()
      #Platform not found, so we'll add it to the add list.
      except NoResultFound:
        if(self.logger):
          self.logger.info("Adding platform: %s" %(platformHandle))              
        platformRec = platform()
        platformRec.row_entry_date = rowEntryDate
        platformRec.organization_id = orgId[0]
        platformRec.active = 5
        platformRec.short_name = glider
        platformRec.platform_handle = platformHandle
        platformRec.desc = "Glider"
        #Lat and Lon are fixed to inisitution locale.
        platformRec.fixed_longitude = -95.67706
        platformRec.fixed_latitude = 37.0625
        #Now add the sensors:
        if glider in gliderObsList:
          obsList = gliderObsList[glider]
          sensorRecs = []            
          for obs in obsList:
            #Get the xenia observation name from the glider obs name.
            xeniaObs = self.mappings.getXeniaFromDifObs(obs['webb_name'])
            #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
            uom = self.uomConverter.getXeniaUOMName(obs['uom'])
            if(uom == None):
              uom = obs['uom']     
            if(xeniaObs and len(xeniaObs)):         
              #Determine if we have that measurement type.
              mType = self.xeniaDb.mTypeExists(xeniaObs[0], uom)
              if(mType):
                if(self.logger):
                  self.logger.info("Adding sensor: %s(%s)" %(xeniaObs[0], uom))              
                
                newSensor = sensor()
                newSensor.row_entry_date = rowEntryDate
                newSensor.active = platformRec.active
                newSensor.m_type_id = mType
                newSensor.s_order = 1
                newSensor.short_name = xeniaObs[0]
                sensorRecs.append(newSensor)
              else:
                if(self.logger):
                  self.logger.error("Webb Obs: %s(%s) Xenia: %s(%s) does not have an m_type." % (obs['webb_name'],obs['uom'],xeniaObs,uom))
            else:
              if(self.logger):
                self.logger.error("No xenia obs for Webb Obs: %s(%s)." % (obs['webb_name'],obs['uom']))
          platformRec.sensors = sensorRecs;
          try:
            self.xeniaDb.session.add(platformRec)              
            self.xeniaDb.session.commit()    
          #Trying to add record that already exists.
          except exc.IntegrityError, e:
            self.xeniaDb.session.rollback()        
            if(self.logger):
              self.logger.debug(e)                          
          except Exception, e:
            self.xeniaDb.session.rollback()        
            if(self.logger):
              self.logger.exception(e)          
      
    return
  
  def getData(self):
    try:
      self.rowEntryDate = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
      gliderMissions = self.getGliderMissions(self.processNewMissions)
      """
      #For now get one mission per glider.
      oneMission = {}
      for glider in gliderMissions:
        if glider == 'murphy':
          for mission in gliderMissions[glider]:
            #mission = gliderMissions[glider][0]
            if(mission['id'] == 51):
              if (glider in oneMission) == False:
                oneMission[glider] = mission
                break
      """
      gliderList = gliderMissions.keys()
      gliderList = self.getGliderAndObsList(gliderList)
      for glider in gliderList:
      #for glider in oneMission:        
        if(self.logger):
          self.logger.info("Processing glider: %s" %(glider))
        if glider in gliderList:
          obsList =  gliderList[glider]
          missions = gliderMissions[glider]
          #mission = oneMission[glider]     
          for mission in missions:
            if(self.logger):
              self.logger.info("Processing mission id: %d Start: %s End: %s" %(mission['id'], str(mission['start_date']), str(mission['end_date'])))
            #Initialize the route profile. As we process each mission, we'll update these, then update the collection
            #record
            self.minLat = None
            self.minLon = None
            self.maxLat = None
            self.maxLon = None
            self.minDepth = None
            self.maxDepth = None
            collectionRun = self.addCollectionEntry(glider, 
                                                    datetime.datetime.strptime(str(mission['start_date']), '%Y-%m-%d'), 
                                                    datetime.datetime.strptime(str(mission['end_date']), '%Y-%m-%d'), 
                                                    int(mission['id']), 
                                                    None)
            for obs in obsList:
              if(self.logger):
                self.logger.info("Processing obs: %s" %(obs['webb_name']))
              self.getObservations(glider, obs, mission, collectionRun)
              addLocationRecs = False
            collectionRun.min_lon  = self.minLon
            collectionRun.max_lon  = self.maxLon
            collectionRun.min_lat  = self.minLat
            collectionRun.max_lat  = self.maxLat
            collectionRun.min_z    = self.minDepth
            collectionRun.max_z    = self.maxDepth
            self.addCollectionEntry(glider, None, None, None, collectionRun)
    except Exception, e:
      if(self.logger):
        self.logger.exception(e)
        
    self.disconnect()              
    return
  
  def getCollectionEntry(self, glider, startDate, endDate):
    collectionRun = None
    try:       
      if(startDate and endDate):
        collectionRun = self.xeniaDb.session.query(collection_run).\
          filter(collection_run.short_name == glider).\
          filter(collection_run.min_date == startDate).\
          filter(collection_run.max_date == endDate).one()
      else:
        collectionRun = self.xeniaDb.session.query(collection_run).\
          filter(collection_run.short_name == glider).\
          filter(collection_run.min_date <= startDate).\
          filter(collection_run.max_date == None).\
          one()
        
      return(collectionRun)
    except NoResultFound:
      pass                              
    return(None)
      
  #def addCollectionEntry(self, glider, missionNfo, collectionRunRec=None):
  def addCollectionEntry(self, glider, startDate=None, endDate=None, missionId=None, collectionRunRec=None):
    #after we process the first observation to get the starting and ending lat/lons. 
    collectionId = None 
    #Add collection_run entry
    #startRun = datetime.datetime.strptime(str(missionNfo['start_date']), '%Y-%m-%d')
    #endRun = datetime.datetime.strptime(str(missionNfo['end_date']), '%Y-%m-%d')  
    if(collectionRunRec == None):
      collectionRun = self.getCollectionEntry(glider, startDate, endDate)
      #No Record found, so we'll add it.
      if(collectionRun == None):         
        collectionRun = collection_run()
        #Use the mission id from the database for our unique id.
        #collectionRun.row_id = int(missionNfo['id'])
        if(missionId != None):
          collectionRun.row_id = missionId
        collectionRun.row_entry_date = self.rowEntryDate
        collectionRun.row_update_date = self.rowEntryDate
        collectionRun.type_id = 0
        collectionRun.fixed_date = startDate
        collectionRun.min_date = startDate
        if(endDate != None):
          collectionRun.max_date = endDate
        #collectionRun.fixed_date = startRun.strftime("%Y-%m-%dT%H:%M:%S")
        #collectionRun.min_date = startRun.strftime("%Y-%m-%dT%H:%M:%S")
        #collectionRun.max_date = endRun.strftime("%Y-%m-%dT%H:%M:%S")
        collectionRun.short_name = "%s" % (glider)
    else:
      collectionRun = collectionRunRec
    try:
      self.xeniaDb.session.add(collectionRun)              
      self.xeniaDb.session.commit()    
    #Trying to add record that already exists.
    except exc.IntegrityError, e:
      self.xeniaDb.session.rollback()        
      if(self.logger):
        self.logger.debug(e)                          
    except Exception, e:
      self.xeniaDb.session.rollback()        
      if(self.logger):
        self.logger.exception(e)
    return(collectionRun)
  
  def getGliderMissions(self, currentMissions=False):
    gliderMissions = {}
    try:
      cur = self.dbWebbConn.cursor(pymysql.cursors.DictCursor)
      if(currentMissions):
        today = datetime.datetime.now()
        sql = "SELECT * FROM Missions WHERE end_date >= '%s' ORDER BY start_date;" % (today.strftime('%Y-%m-%d'))        
      else:
        sql = "SELECT * FROM Missions ORDER BY start_date;"
      cur.execute(sql)
      missionList = []
      gliderName = None
      for rec in cur.fetchall():
        if(rec['glider'] != gliderName):
          gliderName = rec['glider']
          if((gliderName in gliderMissions) == False):
            gliderMissions[gliderName] = []
        missionList = gliderMissions[gliderName]            
        mission = {}
        mission['start_date'] = rec['start_date'] 
        mission['end_date'] = rec['end_date']
        mission['id'] = rec['mission_id']
        missionList.append(mission) 
      cur.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    
    return(gliderMissions)
  def getGliderAndObsList(self, gliderList):
    gliders = {}
    #Get the list of glider obs we are interested in.
    gliderObsList = self.mappings.getGliderObservations()
    try:
      #Build the list of sensors we want to query the database for, we'll use these in the
      # "IN" sql statement.
      sensors = ','.join("'" + str(n) + "'" for n in gliderObsList)      
      for glider in gliderList:
        cur = self.dbWebbConn.cursor(pymysql.cursors.DictCursor)
        #This query only gets the sensors we are interested in for each glider.
        sql = "SELECT DISTINCT(sensor_name),glider,sensor_unit,table_name FROM TableNames WHERE glider = '%s' AND sensor_name IN(%s) ORDER BY sensor_name ASC, sensor_unit ASC;"\
        %(glider, sensors)
        cur.execute(sql)
        gliderName = None
        obsList = []
        uomField = self.mappings.getUOMCol()
        for rec in cur.fetchall():
          if(rec['glider'] != gliderName):
            if((rec['glider'] in gliders) == False):
              gliders[rec['glider']] = []
              gliderName = rec['glider'] 
          obsList = gliders[gliderName]            
          obs = {}
          obs['webb_name'] = rec['sensor_name']
          obs['uom'] = rec['sensor_unit']
          obs['table_name'] = rec['table_name']
          obsList.append(obs)
        cur.close()
      
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(gliders)    
  
  def getObservations(self, glider, obsNfo, missionNfo, collectionRun):
    recList = []
    sensorId = None
    mTypeId = None
    obsCount = 0
    platformHandle = "%s.%s.glider" % (self.organizationId, glider)   
    #Get the xenia observation name from the glider obs name.
    xeniaObs = self.mappings.getXeniaFromDifObs(obsNfo['webb_name'])
    if(xeniaObs and len(xeniaObs)):
      #The location data is a special case, we use the m_gps_lon data to create location records in the database. We can use these
      #for mapping out teh glider track. This data type uses m_value for the longitude and m_value_2 for the latitude.
      #There is actually a table for the m_gps_lat and m_gps_lon as well as the other lat/lon, inter_lat/inter_lon values.
      #For sanities sake I picked the m_gps_lon table for each glider to use to create the location record since it has the gps_lon
      #column as well. 
      if(xeniaObs[0] != 'location_epsg_4326'):     
        isLocationData = False
        #Get the xenia units. If we get None back, then we'll assume we're in the correct units.
        uom = self.uomConverter.getXeniaUOMName(obsNfo['uom'])
        if(uom == None):
          uom = obsNfo['uom']
      else: 
        uom = 'undefined'
        isLocationData = True
        
      sensorId = self.xeniaDb.sensorExists(xeniaObs[0], uom, platformHandle)
      mTypeId = self.xeniaDb.mTypeExists(xeniaObs[0], uom)
      
    if(sensorId and mTypeId):
      #If we are collecting current mission data. Let's look up what our last entry date was and ask for data
      #newer than that.
      lastDate = None
      if(self.processNewMissions):
        useCollectionDate = True
        try:        
          lastDate = self.xeniaDb.session.query(func.max(glider_multi_obs.m_date)).\
            filter(glider_multi_obs.collection_id == collectionRun.row_id).\
            filter(glider_multi_obs.platform_handle == platformHandle).\
            one()
          if(lastDate[0] != None):
            useCollectionDate = False 
        except NoResultFound, e:
          pass
      if(useCollectionDate == False):
        startEpoch = time.mktime(lastDate[0].timetuple())
        where = 'time > %f' % (startEpoch)
      else:
        #Query the glider database for the observation bounded by the mission start and end dates.
        #Glider database has a separate table for each observation.
        startEpoch = time.mktime(datetime.datetime.strptime(str(missionNfo['start_date']), '%Y-%m-%d').timetuple())
        endEpoch = time.mktime(datetime.datetime.strptime(str(missionNfo['end_date']), '%Y-%m-%d').timetuple())        
        where = 'time >= %f AND time < %f' % (startEpoch, endEpoch)
      try:
        cur = self.dbWebbConn.cursor(pymysql.cursors.DictCursor)
        sql = "SELECT * FROM %s WHERE %s ORDER BY time ASC;"\
         % (obsNfo['table_name'], where)
        cur.execute(sql)
      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
      else:
        curMeasDateTime = None
        for rec in cur:     
          addLocObservation = False
          try:                
            lat = self.convertToDecimalDegrees(float(rec['lat']))
            lon = self.convertToDecimalDegrees(float(rec['lon']))
            inter_lat = self.convertToDecimalDegrees(float(rec['inter_lat']))
            inter_lon = self.convertToDecimalDegrees(float(rec['inter_lon']))
            gps_lat = self.convertToDecimalDegrees(float(rec['gps_lat']))
            gps_lon = self.convertToDecimalDegrees(float(rec['gps_lon']))
          except ValueError,e:
            if(self.logger):
              self.logger.exception(e)
          else:
            checkMinMaxLocs = False
            dataRec = glider_multi_obs()             

            #self.convertToDecimalDegrees(                   
            if((lat >= -90.0 and lat <= 90.0) and (lon >= -180.0 and lon <= 180.0)):
              dataRec.m_lat = lat
              dataRec.m_lon = lon
            elif((inter_lat >= -90.0 and inter_lat <= 90.0) and (inter_lon >= -180.0 and inter_lon <= 180.0)):
              dataRec.m_lat = inter_lat
              dataRec.m_lon = inter_lon
              
            dataRec.row_entry_date = self.rowEntryDate
            try:  
              epochTime = float(rec['time'])
              measTime = datetime.datetime.fromtimestamp(epochTime)
            except ValueError,e:
              if(self.logger):
                self.logger.exception(e)                          
            else:
              dataRec.m_date = measTime
              dataRec.platform_handle = platformHandle
              dataRec.collection_id = collectionRun.row_id
              dataRec.m_type_id = mTypeId
              dataRec.sensor_id = sensorId
              
              if(isLocationData == False):
                try:
                  dataRec.m_value = float(rec['sensor_value'])
                except ValueError,e:
                  if(self.logger):
                    self.logger.exception(e)                          
              else:
                if((gps_lat >= -90.0 and gps_lat <= 90.0) and (gps_lon >= -180.0 and gps_lon <= 180.0)):              
                  dataRec.m_value = gps_lon
                  dataRec.m_value_2 = gps_lat
                    
              try:
                dataRec.m_z = float(rec['depth'])
              except ValueError,e:
                if(self.logger):
                  self.logger.exception(e)
                    
              #Check the max/min locations and depths.
              if(isLocationData):
                if(self.minLat == None or dataRec.m_lat < self.minLat):
                  self.minLat = dataRec.m_lat
                if(self.maxLat == None or dataRec.m_lat > self.maxLat):
                  self.maxLat = dataRec.m_lat
                if(self.minLon == None or dataRec.m_lon < self.minLon):
                  self.minLon = dataRec.m_lon
                if(self.maxLon == None or dataRec.m_lon > self.maxLon):
                  self.maxLon = dataRec.m_lon
              #If we have a valid depth value, check it against the min/maxes.    
              if(dataRec.m_z != -100000.0):
                if(self.minDepth == None or dataRec.m_z < self.minDepth):
                  self.minDepth = dataRec.m_z
                if(self.maxDepth == None or dataRec.m_z > self.maxDepth):
                  self.maxDepth = dataRec.m_z
                
              self.dataQueue.put(dataRec)
                          
            obsCount += 1
            #Every few hundred records, let's pause and let the queue empty.
            if((obsCount % 300) == 0):
              self.remoteKeepAlive()
              self.dataQueue.join()
              """                                            
              try:
                self.xeniaDb.session.add(dataRec)              
                self.xeniaDb.session.commit()
                if(self.logger):
                  self.logger.debug("Adding rec: Datetime: %s Lat: %f Lon: %f Value: %f Depth: %f"\
                                     %(dataRec.m_date, lat, lon, dataRec.m_value, dataRec.m_z))
                    
              #Trying to add record that already exists.
              except exc.IntegrityError, e:
                self.xeniaDb.session.rollback()        
                if(self.logger):
                  self.logger.debug(e)                          
              except Exception, e:
                self.xeniaDb.session.rollback()        
                if(self.logger):
                  self.logger.exception(e)
              """          
        cur.close()   
        if(self.logger):
          self.logger.debug("Approximate record count in DB queue: %d" % (self.dataQueue.qsize()))      
        
    else: 
      if(self.logger):
        msg = "Platform: %s missing sensor_id or m_type_id for Webb Sensor: %s(%s) " % (platformHandle, obsNfo['webb_name'], obsNfo['uom'])
        if(xeniaObs and len(xeniaObs)):
          msg += "Sensor: %s(%s) " % (xeniaObs[0], uom)
        self.logger.error(msg)
        
    if(self.logger):
      self.logger.debug("%s observations added: %d" % (obsNfo['webb_name'], obsCount))      

  def convertToDecimalDegrees(self, val):
    dd = None  
    dms = fabs(float(val))
    mins = dms % 100
    deg = int((dms - mins) / 100.0)
    #mins = round((mins / 60.0), 4)
    mins = mins / 60.0
    dd = deg + mins
    if(float(val) < 0):
      dd *= -1
    return(dd)
  
class webbGliderEmail(webbGliders):
  def __init__(self, organizationId, configFile, logger=False):
    webbGliders.__init__(self, organizationId, configFile, logger)
    
    self.pop3Obj = None

  def connect(self):
    if(xeniaDataIngestion.connect(self)):
      try:
        self.checkfornewplatforms = self.config.get(self.organizationId, 'checkfornewplatforms')
        emailUser = self.config.get(self.organizationId, 'emailUser')
        emailPwd = self.config.get(self.organizationId, 'emailPwd')
      except ConfigParser,e:
        if(self.logger):
          self.logger.exception(e)
      else:
        try:
          self.pop3Obj = poplib.POP3('inlet.geol.sc.edu')
          self.pop3Obj.user('glideremail')
          self.pop3Obj.pass_('dramage239')
          if(self.logger):
            self.logger.info("Successfully connected to email server.")
          
          self.rowEntryDate = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
              
          return(True)  
    
        except Exception,e:
          if(self.logger):
            self.logger.excetion(e)
          
    return(False)
  
  def disconnect(self):
    self.pop3Obj.quit()
  
  def processData(self):
    if(self.connect()): 
      msgList = self.getData()
      self.saveData(msgList)
      self.disconnect()
      
  def saveData(self, msgList):
    #The keys are the message Ids from the email server.
    msgIds = msgList.keys()
    msgIds.sort()
    #for msgKey in msgList:
    for msgKey in msgIds:
      msg = msgList[msgKey]
      if 'From' in msg:
        rcvdFrom = msg['From']
        if(rcvdFrom == 'root@expose.webbresearch.com' or rcvdFrom == 'root@neptune.meas.ncsu.edu'):
          if 'Subject' in msg:
            subject = msg['Subject']
            if(subject.find('Glider:') != -1):        
              body = msg.get_payload()
              #Parse the body of the email to get the latest glider track info. If we
              #successfully parse it, let's delete the email record from the server.
              if(self.parseBody(body)):
                #self.pop3Obj.dele(msgKey)
                i = 0
                
    return
  
  def parseBody(self, body):
    import re
    if(len(body)):
      #Example entry: Vehicle Name: salacia
      gliderName = re.findall('Vehicle Name:\s(.*)', body)
      if(len(gliderName)):
        if(self.logger):
          self.logger.info("Processing glider: %s" % (gliderName[0]))
        
        if(self.checkfornewplatforms):
          self.addPlatform(gliderName[0])
        #Example: Curr Time: Tue Mar 27 05:44:33 2012 MT:   58163
        #We trim it to be: Tue Mar 27 05:44:33 2012
        curTime = re.findall('Curr Time:\s(\w{3}\s\w{3}\s\d{1,2}\s\d{2}:\d{2}:\d{2}\s\d{4})\sMT:*', body)
        #Example: GPS Location:  3251.608 N -7829.149 E measured
        #We break it up into (latitude)(compass point) (longitude)(compass point)
        #Compass point seems redundant since the values appear signed.
        curLoc = re.findall('GPS Location:\s+([-+]?[0-9]*\.?[0-9]*)\s(\w{1})\s([-+]?[0-9]*\.?[0-9]*)\s(\w{1})', body)
        recCount = len(curLoc)
        
        platformHandle = "%s.%s.glider" % (self.organizationId, gliderName[0])        
        locMTypeId = self.xeniaDb.mTypeExists('location_epsg_4326', 'undefined')
        locSensorId = self.xeniaDb.sensorExists('location_epsg_4326', 'undefined', platformHandle, 1)
        
        i = 0
        while(i < recCount):
          if(len(curLoc[0]) == 4):            
            lat = self.convertToDecimalDegrees(curLoc[i][0])
            lon = self.convertToDecimalDegrees(curLoc[i][2])
            dataTime = datetime.datetime.strptime(curTime[i], '%a %b %d %H:%M:%S %Y')
            #Check to see if we have a collection entry. If not, we'll add one.
            collectionRun = self.getCollectionEntry(gliderName[0], dataTime, None)
            if(collectionRun == None):
              collectionRun = self.addCollectionEntry(gliderName[0], dataTime, None, None, None)
            
            obsRec = glider_multi_obs()
            obsRec.collection_id = collectionRun.row_id
            obsRec.row_entry_date = self.rowEntryDate
            obsRec.m_date = dataTime
            obsRec.m_type_id = locMTypeId
            obsRec.sensor_id = locSensorId
            obsRec.platform_handle = platformHandle
            obsRec.m_lat = lat
            obsRec.m_lon = lon
            obsRec.m_value = lon
            obsRec.m_value_2 = lat
            
            try:              
              self.xeniaDb.session.add(obsRec)
              self.xeniaDb.session.commit()
            #Trying to add record that already exists.
            except exc.IntegrityError, e:
              self.xeniaDb.session.rollback()
              if(self.logger != None):
                self.logger.exception(e)              
            except Exception,e:
              self.xeniaDb.session.rollback()
              if(self.logger):
                self.logger.exception(e)
            else:
              if(self.logger):
                self.logger.debug("Platform: %s Datetime: %s Lon: %f Lat: %f adding location record."\
                                   % (obsRec.platform_handle, obsRec.m_date, obsRec.m_lon, obsRec.m_lat))
              #Check to see if the location is a min or max
              updatedExtents = False
              if(lat < collectionRun.min_lat or collectionRun.min_lat == None):
                collectionRun.min_lat = lat
                updatedExtents = True
              if(lat > collectionRun.max_lat or collectionRun.max_lat == None):
                collectionRun.max_lat = lat
                updatedExtents = True
              if(lon < collectionRun.min_lon or collectionRun.min_lon == None):
                collectionRun.min_lon = lon
                updatedExtents = True
              if(lon > collectionRun.max_lon or collectionRun.max_lon == None):
                collectionRun.max_lon = lon
                updatedExtents = True               
              if(updatedExtents):
                self.addCollectionEntry(gliderName[0], None, None, None, collectionRun)
                                                           
          else:
            if(self.logger):
              self.logger.error("Current location: %s does not contain enough data for the latitude and longitude" % (curLoc[0]))
              return(False)
          i += 1
      else:
        if(self.logger):
          self.logger.error("Could not find the Vehicle Name identifier in the email address.")  
          return(False)
    return(True)
  
  def getData(self):
    emailList = [] 
    if(self.pop3Obj):
      #messages = [self.pop3Obj.retr(i) for i in range(1, len(self.pop3Obj.list()[1]) + 1)]
      #Make a dictionary of the messages, the key is the message number. We'll use this later when we want
      #to delete the message out of the queue.
      messages = {}
      for i in range(1, len(self.pop3Obj.list()[1]) + 1):
        resp, message, byteCnt = self.pop3Obj.retr(i) 
        messages[i] = message
      
      # Concat message pieces:
      #messages = ["\n".join(mssg[1]) for mssg in messages]
      for msgId in messages:
        messages[msgId] = "\n".join(messages[msgId])
        msg = messages[msgId]
        #Log out the message just in case.
        if(self.logger):
          self.logger.debug(msg)
        #Now build the Message object.
        messages[msgId] = emailParser.Parser().parsestr(msg)
      #Parse message intom an email object:
      #emailList = [emailParser.Parser().parsestr(mssg) for mssg in messages]      
            
    return(messages)
  
  
  def addPlatform(self, platformName):
    #Check to see if the platform exists.
    addPlatform = False
    try:
      platRec = self.xeniaDb.session.query(platform).\
        filter(platform.short_name == platformName).\
        one()
        
    #We didn't find the entry, so we add it along with a location_epsg_4326 sensor.       
    except NoResultFound, e:
      addPlatform = True
      if(self.logger != None):
        self.logger.debug("Platform: %s not found in database, adding" % (platformName))
        
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        
    if(addPlatform):
      #Get the organization Id. Need it to add a platform.
      try:
        orgRec = self.xeniaDb.session.query(organization).\
          filter(organization.short_name == self.organizationId).\
          one()
          
      #We didn't find the entry, so we add it along with a location_epsg_4326 sensor.       
      except NoResultFound, e:
        addPlatform = True
        if(self.logger != None):
          self.logger.debug("Organization: %s not found in database, cannot add platform" % (self.organizationId))
      
      else:
        platformRec = platform()
        platformRec.row_entry_date = self.rowEntryDate
        platformRec.organization_id = orgRec.row_id
        platformRec.short_name = platformName
        platformRec.platform_handle = '%s.%s.glider' % (self.organizationId, platformName)
        platformRec.active = statusFlags.DELAYED
        
        sensorRec = sensor()
        sensorRec.row_entry_date = self.rowEntryDate
        sensorRec.platform_id = platformRec.row_id
        sensorRec.m_type_id = self.xeniaDb.mTypeExists('location_epsg_4326', 'undefined')
        sensorRec.short_name = 'location_epsg_4326'
        sensorRec.active = statusFlags.DELAYED
        sensorRec.s_order = 1
        
        platformRec.sensors =[sensorRec]        
        try:
          self.xeniaDb.addRec(platformRec, True)
          #self.xeniaDb.addRec(sensorRec, True)
        except Exception,e:
          self.xeniaDb.session.rollback()
          if(self.logger):
            self.logger.exception(e)
      
class gliderOutput(dataProduct):

  def processData(self):
    if(xeniaDataIngestion.connect(self) != True):
      if(self.logger):
        self.logger.error("Unable to connect to xenia database, cannot continue.")
    else:
      self.getData()

  def getData(self):
    try:
      self.exportCurrentMissions = bool(int(self.config.get(self.organizationId + '_kml', 'outputcurrentmissionsonly')))
      gliders = self.config.get(self.organizationId, 'whitelist').split(',')
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
    else:
      try:
        if(self.exportCurrentMissions):
          #We're checking only current missions. The collection table may have the min_date filled out
          #but no max date, such as the NCSU processing where we get only the emails, or
          #the collection table could have the max_date filled out as well, like the usf where
          #they have a home brewed mission table we use that has start/end dates for the current mission.
          nowTime = datetime.datetime.now()
          collectionRuns = self.xeniaDb.session.query(platform,collection_run).\
            join((collection_run, collection_run.short_name == platform.short_name)).\
            filter(platform.short_name.in_(gliders)).\
            filter(or_(and_(collection_run.min_date <= nowTime,collection_run.max_date == None),and_(collection_run.min_date <= nowTime,collection_run.max_date > nowTime))).all()
        else:  
          runId = 55
          gliderName = self.xeniaDb.session.query(platform,collection_run).\
            join((collection_run, collection_run.short_name == platform.short_name)).\
            filter(collection_run.row_id == runId).one()

      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
          
      else:  
        for collectionRun in collectionRuns:
          sensorId = self.xeniaDb.sensorExists('location_epsg_4326', 'undefined', collectionRun[0].platform_handle)
          runId = collectionRun[1].row_id
          locRecs = self.xeniaDb.session.query(glider_multi_obs).\
            filter(glider_multi_obs.collection_id == runId).\
            filter(glider_multi_obs.sensor_id == sensorId).\
            order_by(glider_multi_obs.m_date).all()
  
          self.createGliderTrackKML(collectionRun[0], collectionRun[1], locRecs)
        
    
    """  
    for point in trackPts:
      altitude = locRec.m_z * -1
      lon = locRec.m_value
      lat = locRec.m_value_2
      if(lon == None or lat == None):
        lon = locRec.m_lon
        lat = locRec.m_lat
      # add a placemark for the feature
      recTime = locRec.m_date.strftime('%Y-%m-%dT%H:%M:%S')
      gliderTourDoc.Document.Folder.Folder.append(
        KML.Placemark(
          KML.description(
              "<h1>Time</h1><br/>%s" % (recTime)
          ),
          KML.Point(
            #KML.extrude(1),
            #KML.altitudeMode("relativeToGround"),
            KML.coordinates("%f,%f,0" % (
                    lon,lat
                )
            )
          ),
          KML.TimeStamp(KML.when(recTime)),
          KML.styleUrl("#multiTrack_n")            
          #id=locRec.row_id
        )
      )
      gxTrack.append(KML.when(recTime))
      gxTrack.append(GX.coord('%f %f 1' % (lon,lat)))
    """  
    #trackPlaceMark.append(gxTrack)
    #gliderTourDoc.Document.Folder.append(trackPlaceMark)

  def createGliderTrackKML(self, platformRec, collectionRun, dataRecs):\
  
    try:  
      #homeUrl = 'http://ooma.marine.usf.edu/CROW/'
      #dataAttributionPage = 'http://secoora.org/maps/datalinks#usfgliders'
      kmlSection = self.organizationId + '_kml'
      homeUrl = self.config.get(kmlSection, 'projecturl')
      dataAttributionPage = self.config.get(kmlSection, 'attributeurl')
      kmlFilepath = self.config.get(kmlSection, 'kmlfilepath')
      gliderIconUrl = self.config.get(kmlSection, 'gliderIconUrl')
    except ConfigParser,e:
      if(self.logger):
        self.logger.exception(e)
    else:
      #Check the collectionRun is None or see if the max_date is ahead of the current date. If it is, that means
      #the glider is currently underway.
      underway = False
      today = datetime.datetime.now()
      if(collectionRun.max_date == None or collectionRun.max_date > today):
        underway = True
         
      gliderTourDoc = KML.kml(
          KML.Document(
            KML.Folder(
              KML.name('Features'),
              id='features',
            ),
          )
        )
      gliderTourDoc.Document.Folder.append( KML.Style(
            KML.IconStyle(
              KML.scale(0.75),
              KML.Icon(
                #KML.href('http://ooma.marine.usf.edu/USFGliderIcon.png'),
                KML.href(gliderIconUrl),
              )            
            ),
            id='gliderIconStart'                                                           
          )
      )
      gliderTourDoc.Document.Folder.append( KML.Style(
            KML.IconStyle(
              KML.scale(1.0),
              KML.Icon(
                #KML.href('http://ooma.marine.usf.edu/USFGliderIcon.png'),
                KML.href(gliderIconUrl),
              )            
            ),
            id='gliderIcon'                                                           
          )
      )
      gliderTourDoc.Document.append( KML.Style(
            KML.LineStyle(
                          KML.color('7f00ffff'), 
                          KML.width(4)
                         ),
            id='yellowLineGreenPoly'                                                           
          )
      )
      
      gliderPathPm = KML.Placemark( 
                                   KML.name('%s Track' %(string.capwords(platformRec.short_name))),
                                   KML.styleUrl('#yellowLineGreenPoly')
                                  )
      #First run through, build our LineString, then we'll simplyfy it.
      linestringCoords = []      
      for locRec in dataRecs:
        lon = locRec.m_value
        lat = locRec.m_value_2
        if(lon != None and lat != None):
          linestringCoords.append((lon,lat))
        
      trackPts = LineString(linestringCoords)
      if(self.logger):
        self.logger.debug("Point count: %d" % (len(trackPts.coords)))
      if(self.exportCurrentMissions == False):
        trackPts = trackPts.simplify(0.01, False)
        if(self.logger):
          self.logger.debug("After simplify point count: %d" % (len(trackPts.coords)))
      
      linestring = ""
      recCnt = 0
      descTmplt = "<h1>%(glider_name)s Glider Track %(type)s</h1>\
      </br>\
      <ul>\
      <li><h2>Begin Date:</h2> %(start_date)s</li>\
      <li><h2>%(end_date_text)s Date:</h2> %(end_date)s</li>\
      <li><h2>Information:</h2> <a href='%(attribution)s' target='_blank'>Link</a></li>\
      <li><h2>Website:</h2> <a href='%(url)s' target='_blank'>Link</a></li>\
      </ul>"
      templateData = {}
      templateData['glider_name'] = string.capwords(platformRec.short_name)
      templateData['url'] = homeUrl
      templateData['attribution'] = dataAttributionPage
      templateData['start_date'] = collectionRun.min_date.strftime('%Y-%m-%d')
  
      #If we're underway, let's use a different label and the date/time from the last data record.
      if(underway):
        templateData['end_date_text'] = 'Last Update Date/Time'
        templateData['end_date'] = dataRecs[-1].m_date.strftime('%Y-%m-%dT%H:%M:%S')      
      else:
        templateData['end_date_text'] = 'End Date'
        templateData['end_date'] = collectionRun.max_date.strftime('%Y-%m-%d')
      
      
      for point in trackPts.coords:
        lon = point[0]
        lat = point[1]
        #Add a placemark to show a glider icon to denote start.
        if(recCnt == 0 or recCnt == (len(trackPts.coords)-1)):
          templateData['type'] = 'Start'
          gliderIcon = KML.styleUrl("#gliderIcon") 
          if(recCnt != 0):
            if(underway):            
              templateData['type'] = 'Last Report Location'            
            else:
              templateData['type'] = 'End'
          else:
            gliderIcon = KML.styleUrl("#gliderIconStart")             
            linestringDesc = descTmplt % (templateData)   
                    
          desc = descTmplt % (templateData)
          gliderTourDoc.Document.Folder.append(
            KML.Placemark(
              KML.description(desc),
              KML.Point(
                KML.coordinates("%f,%f,0" % (
                        lon,lat
                    )
                )
              ),
              gliderIcon           
            )
          )          
        if(len(linestring)):
          linestring += '\n'
        linestring += '%f,%f,0' % (lon,lat)
        recCnt += 1
      try:
        gliderPathPm.append(KML.description(linestringDesc))                                                    
        gliderPathPm.append(KML.LineString(
                                           KML.extrude(1),
                                           KML.tessellate(1),                                         
                                           KML.coordinates(linestring),
                                          )
                          )
        gliderTourDoc.Document.append(gliderPathPm)
        if(underway):
          kmlFileName = "%s/%s_gliderTrackCurrent.kml" % (kmlFilepath,platformRec.short_name)
        else:
          kmlFileName = "%s/gliderTrack_%s.kml" % (kmlFilepath,templateData['start_date'])
        kmlFile = open(kmlFileName, 'w')      
        kmlFile.writelines(etree.tostring(gliderTourDoc, pretty_print=True))
        if(self.logger):
          self.logger.info("Writing KML file: %s" % (kmlFileName))
        kmlFile.close()
      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
      return
    
  def buildKMLDesc(self):
    kmlDesc = None
    return(kmlDesc)
  
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
    
    if(len(logFile)):
      logging.config.fileConfig(logFile)
      logger = logging.getLogger("webb_glider_logger")
      logger.info('Log file opened.')
    

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
        processingObj = processingObjClass(orgId, options.configFile, True)
        processingObj.processData()
         
        outputObjName = configFile.get(orgId, 'outputprocessingobject')      
        if(outputObjName in globals()):
           outputObjClass = globals()[outputObjName]
           outputObj = outputObjClass(orgId, options.configFile, True)
           outputObj.processData()
        else:
          if(logger):
            logger.error("Output creation object: %s does not exist, skipping." %(outputObjName))   
         
      else:
        if(logger):
          logger.error("Processing object: %s does not exist, skipping." %(processingObjName))   
           
  
  except Exception, e:
    if(logger):
      logger.exception(e)
    else:
      print(e)
  if(logger):
    logger.info('Log file closing.')
  