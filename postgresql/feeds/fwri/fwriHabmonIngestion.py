import logging.config

import optparse

import urllib
import urllib2
import socket
import ConfigParser


from xeniatools.csvDataIngestion import csvDataIngestion


class fwriCSVDataIngestion(csvDataIngestion):
  def initialize(self, configFile=None):
    if(csvDataIngestion.initialize(self)):
      try:      
        #Get the url for the file.
        self.csvUrl = self.config.get(self.organizationId, 'csvUrl')
        return(True)
      except ConfigParser,e:
        if(self.logger):
          self.logger.exception(e)
    return(False)
  
  def processData(self):
    #Attempt to download the latest file.
    if(self.logger):
      self.logger.debug("Requesting page: %s" % (self.csvUrl))
    req = urllib2.Request(self.csvUrl)
    # Open the url
    #Set the timeout so we don't hang on the urlopen calls.
    socket.setdefaulttimeout(30)
    #Attempt to get the CSV file and write it locally.
    try:
      connection = urllib2.urlopen(req)
      csvFile = open(self.csvFilepath, 'w')          
      csvFile.write(connection.read())          
      csvFile.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
        self.logger.error("Cannot continue processing data. Shutting down.")
      self.cleanUp()
    else:
      csvDataIngestion.processData(self)      
      
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
 