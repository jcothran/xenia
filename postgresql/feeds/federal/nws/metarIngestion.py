import logging.config

import optparse
import Queue
import ConfigParser
from datetime import datetime, timedelta
import time

#from xeniatools.xenia import uomconversionFunctions
from xeniatools.DataIngestion import xeniaDataIngestion, dataSaveWorker
from xeniatools.ioosDif import xeniaMappings
from xeniatools.xeniaSQLAlchemy import multi_obs, organization, platform 
from xeniatools.xenia import uomconversionFunctions

import simplejson as json
from pymetar import *

class metarMapping(dict):
  def __init__(self, useLog=True):
    self.logger = None
    if(useLog):
      self.logger = logging.getLogger(__name__)
      
  def initialize(self,mappingFile):
    try:
      fileObj = open(mappingFile, 'r')
      dict.__init__(self, json.load(fileObj))
      fileObj.close()
      return(True)      
    except IOError,e:
      if(self.logger):
        self.logger.exception(e)
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        
    return(False)
              
class metarIngestion(xeniaDataIngestion):
  def __init__(self, organizationID, configFile, logger=None):
    self.configFilename = configFile
    xeniaDataIngestion.__init__(self, organizationID, configFile, logger)
  
  def initialize(self, configFile=None):
    if(self.connect()):
      self.platformRecs = None
      self.metarFetcher = None
      #The date we use to time stamp the rows we add.
      self.rowEntryDate = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")            
      try:        
        #GEt the url to use for fetching the stations.
        metarUrl = self.config.get(self.organizationId, 'metarurl')
        #The METAR to xenia mapping file.
        mappingFile = self.config.get(self.organizationId, 'jsonconfig')
        #Units converion file.
        uomFilePath = self.config.get('settings', 'uomconversionfile')        
      except ConfigParser.Error, e:  
        if(self.logger):
          self.logger.exception(e)      
      else:
        #Create our fetcher object.               
        self.metarFetcher = ReportFetcher(baseurl=metarUrl)
        #Units Converter
        self.uomConverter = uomconversionFunctions(uomFilePath)
        #Build the mapping file that allows us to pick apart the METAR data fields and convert them to xenia fields.
        self.xeniaMapping = xeniaMappings(mappingFile)
        self.xeniaMapping.buildMTypeMapping(self.xeniaDb, self.uomConverter)
        
        #Let's get a list of the platforms we want to retrieve the data for.
        try:      
          self.platformRecs = self.xeniaDb.session.query(platform).\
                      join((organization,organization.row_id == platform.organization_id)).\
                      filter(organization.short_name == self.organizationId).\
                      filter(platform.active > 0).\
                      order_by(platform.short_name).\
                      all()
          if(self.logger):
            self.logger.info("Organization: %s returned: %d platforms to query for data." % (self.organizationId, len(self.platformRecs)))

          #Fire up the saver thread.      
          self.dataQueue = Queue.Queue(0)
          dataSaver = dataSaveWorker(self.configFilename, self.dataQueue)
          dataSaver.start()        
            
          return(True)
        except Exception, e:  
          if(self.logger):
            self.logger.exception(e)
                        
    return(False)
  
  def getData(self, platRec):
    dataRecs= []
    try:
      if(self.logger):
        self.logger.info("Platform: %s retrieving data." % (platRec.short_name))        
      metarData = self.metarFetcher.FetchReport(StationCode=platRec.short_name)
      if(self.logger):
        self.logger.info("Platform: %s data received." % (platRec.short_name))        
    except NetworkException,e:
      if(self.logger):
        if(e.message.code == 404):
          self.logger.error("Platform: %s was not found, may no longer exist." % (platRec.short_name))
        else:
          self.logger.exception(e)          
    else:      
      try:
        weatherRec = ReportParser().ParseReport(metarData)      
        #Get location info for the data.
        lonAttr, latAttr = self.xeniaMapping.getLonLatColumnNames()
        dateAttr = self.xeniaMapping.getDatetimeColumnName()

        lat = getattr(weatherRec,latAttr)
        if(lat == None):
          if(self.logger):
            self.logger.debug("Platform: %s latitude is missing, using db record." % (platRec.short_name))
          lat = platRec.fixed_latitude
        lon = getattr(weatherRec,lonAttr)
        if(lon == None):
          if(self.logger):
            self.logger.debug("Platform: %s longitude is missing, using db record." % (platRec.short_name))
          lon = platRec.fixed_longitude
        #Date of observation
        recDate = getattr(weatherRec, dateAttr)
      except AttributeError,e:
        if(self.logger):
          self.logger.exception(e)
      except Exception,e:
        if(self.logger):
          self.logger.exception(e)
      else:      
        #We have to have a valid location and date attribute to continue processing the METAR data.
        try:  
          if(recDate != None): 
            mDate = datetime.strptime(recDate, '%Y.%m.%d %H%M %Z')
            #Check to see if the data is older than 24 hours, if so log a message and skip it.            
            if(mDate > datetime.now() - timedelta(hours=24)):
              for metarObsKey in self.xeniaMapping.mappings['observation_columns']:
                #metarObsUom = self.xeniaMapping.getObsUomFromObs(metarObsKey)[0]
                xeniaObs = self.xeniaMapping.getXeniaFromDifObs(metarObsKey)[0]        
                mTypeId = self.xeniaMapping.getMtypeFromXenia(xeniaObs)
                if(self.logger):
                  self.logger.debug("Platform: %s processing xenia obs: %s(%d) metar obs: %s" % (platRec.short_name, xeniaObs, mTypeId, metarObsKey))
                try:
                  recVal = getattr(weatherRec,metarObsKey)
                  #Make sure we have a real float value before trying to save it to db.
                  val = float(recVal)              
                except AttributeError,e:
                  if(self.logger):
                    self.logger("Platform: %s attribute: %s does not exist" % (platRec.short_name, metarObsKey))
                except ValueError,e:
                  if(self.logger):
                    self.logger.exception(e)                
                except Exception,e:
                  if(self.logger):
                    self.logger.error("Platform: %s Obs: %s value error val: %s" % (platRec.short_name, xeniaObs, recVal))
                else:
                  #Use the m_type_id of the observation to find the sensor record and then the sensor_id.
                  sensorId = None
                  for rec in platRec.sensors:
                    if(mTypeId == rec.m_type_id):
                      sensorId = rec.row_id
                      break
                  if(sensorId):  
                    multiObsRec = multi_obs(row_entry_date=self.rowEntryDate,
                                            m_date=mDate,
                                            platform_handle=platRec.platform_handle,
                                            sensor_id=sensorId,
                                            m_type_id=mTypeId,
                                            m_lon=lon,
                                            m_lat=lat,
                                            m_value=val
                                            )
                    dataRecs.append(multiObsRec)
                  else:
                    if(self.logger):
                      self.logger.error("Platform: %s Xenia obs: %s is not present on platform: %s" % (platRec.short_name, xeniaObs,platRec.short_name))
            else:
              if(self.logger):
                self.logger.error("Platform: %s data is older than 24 hours: %s" % (platRec.short_name, mDate))                
          else:
            if(self.logger):
              self.logger.error("Platform: %s date value is null, not adding record." % (platRec.short_name))
                                
        except Exception,e:
          if(self.logger):
            self.logger.exception(e)
    try:
      if(self.logger):
        self.logger.info("Platform: %s finished processing." % (platRec.short_name))
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
      
      
    return(dataRecs)
  
  def saveData(self, dataRecs):
    for rec in dataRecs:      
      self.dataQueue.put(rec)
  
  def processData(self):
    #We want to keep track of how long the platform processing takes.
    startClock = time.time()
    if(self.initialize()):
      for platRec in self.platformRecs:        
        dataRecords = self.getData(platRec)
        #self.saveData(dataRecords)
    #Finished processing  
    self.cleanUp()
    #We want to keep track of how long the platform processing takes.
    stopClock = time.time()
    if(self.logger):
      self.logger.info("Processed: %d platforms in %f seconds." %(len(self.platformRecs), (stopClock-startClock)))
    

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

def main():
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
    logger = logging.getLogger("metar_ingestion_logger")
    logger.info('Log file opened')
    try:
      #Get the list of organizations we want to process. These are the keys to the [APP] sections on the ini file we 
      #then use to pull specific processing directives from.
      orgList = configFile.get('processing', 'organizationlist')
      orgList = orgList.split(',')
    except ConfigParser.Error, e:  
      if(logger):
        logger.exception(e)      
    else:
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
    
  except Exception, e:  
    if(logger):
      logger.exception(e)
  

if __name__ == '__main__':
  main()
