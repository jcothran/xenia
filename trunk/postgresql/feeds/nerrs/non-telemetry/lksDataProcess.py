import sys
import os
sys.path.insert(0, '../common')
import codecs
import logging.config
import optparse
import ConfigParser
import requests
import csv
import simplejson as json
from datetime import datetime
import pytz as timezone

from dataIngestion import dataIngestion
#from xeniatools.DataIngestion import dataIngestion

import pdb

def unicode_csv_reader(unicode_csv_data, fieldnames, dialect=csv.excel, **kwargs):
    # csv.py doesn't do Unicode; encode temporarily as UTF-8:
    csv_reader = csv.reader(utf_8_encoder(unicode_csv_data),
                            dialect=dialect, **kwargs)
    for row in csv_reader:
        # decode UTF-8 back to Unicode, cell by cell:
        uniRows = [unicode(cell, 'utf-8') for cell in row] 
        d =  dict(zip(fieldnames, uniRows))
        yield d
         

def utf_8_encoder(unicode_csv_data):
    for line in unicode_csv_data:
        yield line.encode('utf-8')
              
class lksDataIngestion(dataIngestion):
  def __init__(self, station, configFile, logger=True):
    self.station = station
    self.configFilename = configFile
    dataIngestion.__init__(self, configFile, logger)

  def initialize(self):
    try:
      
      #Get the mapping configuration to go from input to output.          
      jsonFile = open(self.config.get(self.station, 'columnmappingfile'), 'r')
      self.mappings = json.load(jsonFile)
      jsonFile.close()
      
      #Get the data columns names.  
      fieldNames = self.config.get(self.station, 'incolumns').split(',')        
      #Open the input data file, use the DictReader to use in conjunction with the mapping below so
      #we can map the input data to the output data format.
      #self.srcData = open(self.getStationData(), "r")
      self.srcData = codecs.open(self.getRemoteData(), mode = 'r', encoding="utf-8", errors='replace')

      self.csvSrcFile = unicode_csv_reader(self.srcData, fieldNames)
      
      self.localTimezone = self.config.get(self.station, 'timezone')
      #Get the last time we processed. We use this to skip over the data we've already processed. Date/time is stored
      #as UTC, however inbound data is in the local timezone. We make our self.lastTimeProcessed timezone aware here.
      utcTZ = timezone.timezone('UTC') 
      self.lastTimeProcessed = utcTZ.localize(datetime.strptime(self.config.get(self.station,'lasttimeprocd'), "%Y-%m-%dT%H:%M:%S"))
      if(self.logger):
        self.logger.debug("Station: %s last record processed: %s" % (self.station, self.lastTimeProcessed))

    except (IOError,ConfigParser.Error,json.JSONDecodeError) as e:  
      if(self.logger):
        self.logger.exception(e)
      return(False)
    return(True)
  
  def cleanUp(self):
    if(self.logger):
      self.logger.debug("Station: %s clean up." % (self.station))
    if(self.srcData):
      self.srcData.close()
    if(self.outFile):
      self.outFile.close()
    
  def getRemoteData(self):
    tmpFilePath = None
    try:
      stationFileUrl = self.config.get(self.station, 'csvfileurl')
      if(self.logger):
        self.logger.debug("Station: %s Querying CSV at: %s" % (self.station, stationFileUrl))

      #Make the HTTP request for the file.
      req = requests.get(stationFileUrl)      
      #Save the returned data to a tmp file.
      tmpFilePath = self.config.get(self.station, 'tmpfile')
      #Open the temp file.
      #stationDataFile = open(tmpFilePath, "w")
      stationDataFile = codecs.open(tmpFilePath, mode="w", encoding="utf-8", errors='replace')
      #Write the return data from the HTTP request.
      #if(self.logger):
      #  self.logger.debug("%s" % (req.text))
      stationDataFile.write(req.text)
      stationDataFile.close()
      if(self.logger):
        self.logger.debug("Station: %s CSV written to: %s" % (self.station, tmpFilePath))
      
    except (IOError,ConfigParser.Error,requests.ConnectionError, requests.HTTPError, requests.Timeout) as e:  
      if(self.logger):
        self.logger.exception(e)
                       
    return(tmpFilePath)
  
  def processData(self):
    if(self.logger):
      self.logger.info("Station: %s begin processing data." % (self.station))
    
    if(self.initialize()):
      self.readData()
    self.cleanUp()   

    if(self.logger):
      self.logger.info("Station: %s finished processing data." % (self.station))
    
  def readData(self):
    try:
      outFilePath = self.config.get(self.station, 'outfile')
      writeHeader = True
      if(os.path.isfile(outFilePath)):
          if(self.logger):
            self.logger.debug("Station: %s write header" % (self.station))
          writeHeader = False
      outColumns = self.config.get(self.station, 'outcolumns')
    except ConfigParser.Error, e:
      if(self.logger):
        self.logger.exception(e)
    else:        
      try:
        self.outFile = codecs.open(outFilePath, mode='a', encoding="utf-8", errors='replace')
        if(self.logger):
          self.logger.info("Station: %s outfile: %s" % (self.station, outFilePath))
          
        if(writeHeader):
          self.outFile.write(outColumns)
          self.outFile.write('\r\n')
        #Use the list as the keys to the mapping.
        outColumns = outColumns.split(',')
      except (IOError) as e:  
        if(self.logger):
          self.logger.exception(e)
      else:
        try:
          lastRecDate = None
          rowCnt = 0
          #Use the local timezone to make the datetime object below timezone aware.
          cstTZ = timezone.timezone(self.localTimezone) 
          for row in self.csvSrcFile:
            #First 4 rows are header info, skip over them
            if(rowCnt > 4):
              outRow = []
              #There is no timezone info in the incoming data, I set it in the ini file. So we need
              #to make this datetime object timezone aware so we can do the comparison below.
              dateTime = cstTZ.localize(datetime.strptime(row['Date/Time'], '%m/%d/%Y %I:%M:%S %p'))
              #Convert to UTC
              utcDate = dateTime.astimezone(timezone.timezone('UTC'))
              
              #We only want to process the records that are newer than the last processing run.
              if(utcDate > self.lastTimeProcessed):
                
                if(self.logger):
                  self.logger.debug("Station: %s processing line: %d Date/Time(local): %s (utc) :%s" % (self.station, rowCnt, dateTime, utcDate))
                lastRecDate = utcDate
                #Loops through the output columns, we use these as the key to get the input data column that 
                #corresponds with the output column. 
                for col in outColumns:
                  if(col == 'Date'):
                    outRow.append(utcDate.strftime('%m/%d/%Y'))
                  elif(col == 'Time'):
                    outRow.append(utcDate.strftime('%H:%M:%S'))
                  elif(col == 'SWMPStation'):
                    outRow.append(self.station)
                  else:
                    if(self.mappings[col] in row):
                      val = row[self.mappings[col]]
                      outRow.append(val)
                    else:
                      outRow.append('')
                self.outFile.write(",".join(outRow))
                self.outFile.write('\r\n')
            rowCnt += 1 
        except (IOError,Exception) as e:  
          if(self.logger):
            self.logger.exception(e)

        if(lastRecDate):
          if(self.logger):
            self.logger.info("Last record date(UTC): %s" % (lastRecDate.strftime("%Y-%m-%dT%H:%M:%S")))
          self.config.set(self.station, 'lasttimeprocd', lastRecDate.strftime("%Y-%m-%dT%H:%M:%S"))
          #You have to re-write the config file to save any changes.
          try:
            with open(self.configFilename, 'w') as configfile:
              self.config.write(configfile)
          except Exception,e:
            if(self.logger):
              self.logger.exception(e)
          
                
      

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
    stationList = configFile.get('processing', 'stationlist').split(',')
    
    for station in stationList:
      if(logger):
        logger.info("Processing")
      #Get the processing object.
      processingObjName = configFile.get(station, 'processingobject')      
      if(processingObjName in globals()):
         processingObjClass = globals()[processingObjName]
         processingObj = processingObjClass(station, options.configFile, logger)
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
  

if __name__ == '__main__':
  main()
