"""
Revisions
Date: 2013-12-17
Function: processData
Changes: Added the ability to specify specific csvReader object.
"""

import logging.config

import optparse

import urllib
import urllib2
import socket
import Queue
import ConfigParser
from datetime import datetime

from xeniatools.DataIngestion import xeniaDataIngestion, dataSaveWorker
from xeniatools.csvDataIngestion import csvDataIngestion, xeniaCSVReader


class fwriCSVReader(xeniaCSVReader):
  #def __init__(self, fileObj, xeniaMappingFile, uomConverter, dialect='excel', logger=False, *args, **kwds):
  #  xeniaCSVReader.__init__(self, fileObj, xeniaMappingFile, uomConverter, dialect, logger, args, kwds)

  def getPlatformData(self, row):
    dataRec = {}
    #Get the platform column. If we don't have one, we use the default value.
    platformCol  = self.xeniaMapping.getPlatformColumn()
    if(platformCol == None):
      platformHandle = self.xeniaMapping.getPlatformDefaultHandle();
    else:
      #THis will be the short name, we then need to look up the platform_handle
      platformHandle = row['platformCol']

    dataRec['platform_handle'] = platformHandle

    #Get the date entry as we need it for each observation.
    dateCol, dateFormat, timezone = self.xeniaMapping.getDateColumn()
    #Get the data once for use in each observation.
    dateVal = row[dateCol]
    if(dateVal.isalnum() == False):
      dateVal = "".join(i for i in dateVal if ord(i)<128)
    try:
      dataRec['m_date'] = datetime.strptime(dateVal, dateFormat)
    except Exception,e:
      if(self.logger):
        self.logger(e)

    #Check to see if there is GPS in the data, if so we'll use it, otherwise we'll use the default.
    dataRec['m_lat'] = dataRec['m_lon'] = None
    if('GpsLatDeg' in row):
      #lat/lon are in degree and minutes column, combine the 2.
      try:
        dataRec['m_lat'] = float(row['GpsLatDeg']) + float(row['GpsLatMin']) / 60.0
        dataRec['m_lon'] = float(row['GpsLonDeg']) + float(row['GpsLonMin']) / 60.0
      except (ValueError,Exception) as e:
        if(self.logger):
          self.logger.error("Lat or Lon value is not a float: LatDeg: %s LatMin: %s LonDeg: %s LonMin: %s" %\
                            (row['GpsLatDeg'], row['GpsLatMin'], row['GpsLonDeg'], row['GpsLonMin']))
    else:
      #Get the longitude and latitude columns. If they don't exist, use the default values.
      lonCol,latCol = self.xeniaMapping.getFixedLonLatColumn()
      if(lonCol == None and latCol == None):
        dataRec['m_lon'], dataRec['m_lat'] = self.xeniaMapping.getDefaultFixedLonLat()


    return(dataRec)


class fwriCSVDataIngestion(xeniaDataIngestion):
  def __init__(self, organizationID, configFile, logger=None):
    self.configFilename = configFile
    xeniaDataIngestion.__init__(self, organizationID, configFile, logger)
  
  def initialize(self, configFile=None):
    try:        
      self.platformList = self.config.get(self.organizationId, 'whitelist').split(',')                    
      return(True)        
    except ConfigParser.Error, e:  
      if(self.logger):
        self.logger.exception(e)
    return(False)
  
  def processData(self):
    #Get the platforms to process for the organization.
    for platformName in self.platformList:
      if(self.logger):
        self.logger.info("Processing platform: %s" % (platformName))
      #DWR 2013-12-17
      #Get the specific csvReader object to use.
      csvReaderObj = None
      try:
        csvReaderName = self.config.get(platformName, 'csvReader')
      except ConfigParser.Error, e:
        if(self.logger):
          self.logger.error("Platform: %s Could not find csvReader ini parameter." % (platformName))
      else:
        if(csvReaderName in globals()):
          csvReaderObj = globals()[csvReaderName]
        else:
          if(self.logger):
            self.logger.error("Platform: %s Could not find csvReader: %s" % (platformName, csvReaderName))

      #Attempt to download the latest file.
      useLogger = False
      if(self.logger):
        useLogger = True
      processObj = csvDataIngestion(platformName, self.configFilename, useLogger)
      if(processObj.initialize(csvReader = csvReaderObj)):
        csvUrl = self.config.get(platformName, 'csvURL')
        if(self.logger):
          self.logger.debug("Requesting page: %s" % (csvUrl))
        req = urllib2.Request(csvUrl)
        # Open the url
        #Set the timeout so we don't hang on the urlopen calls.
        socket.setdefaulttimeout(30)
        #Attempt to get the CSV file and write it locally.
        try:
          connection = urllib2.urlopen(req)
          csvFile = open(processObj.csvFilepath, 'w')          
          csvFile.write(connection.read())          
          csvFile.close()
          
          processObj.processData()
        except Exception,e:
          if(self.logger):
            self.logger.exception(e)
            self.logger.error("Cannot continue processing data. Shutting down.")
      self.cleanUp()
      
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
        try:
          processingObj = processingObjClass(orgId, options.configFile, logger)
          if(processingObj.initialize()):
            processingObj.processData()
        except Exception,e:
          if(logger):
            logger.exception(e)
      else:
        if(logger):
          logger.error("Processing object: %s does not exist, skipping." %(processingObjName))   
        

  except Exception, E:
    if(logger != None):
      logger.exception(E)
    else:
      import traceback
      traceback.print_exc()
  
  if(logger):
    logger.info('Log file closing.')
    
    
  

if __name__ == '__main__':
  main()
 