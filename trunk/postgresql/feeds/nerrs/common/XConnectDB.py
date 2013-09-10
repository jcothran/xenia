import sys
import os
import datetime
import logging.config
import optparse
import ConfigParser
import pyodbc

class xConnectDB(object):
  def __init__(self, logger=True):
    self.dbCon = None
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)

  def connect(self, dsnString):
    try:
      self.dbCon = pyodbc.connect(dsnString)
      if(self.dbCon != None):
        return(True)
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(False)
  
  def disconnect(self):
    if(self.dbCon):
      if(self.logger):
        self.logger.info("Closing database connection.")
      self.dbCon.close()
            
  def getActiveStations(self):
    stationList = []
    sql = "SELECT STATION_ID FROM XC_SITES WHERE ENABLED='Y'"
    try:
      dbCursor = self.dbCon.cursor()
      dbCursor.execute(sql)
      rows = dbCursor.fetchall()
      for row in rows:
        stationList.append(row.STATION_ID)
      dbCursor.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(stationList)
  
  def getStationSensors(self, stationName):
    sql = """
          SELECT SENSORNAME,EQUATION,RIGHT_DIGIT,DESCRIPTION,MANUFACTURER,MODEL_NUMBER
          FROM XC_SITESENSORS WHERE STE_STATION_ID='%s' AND ENABLED='Y' ORDER BY STE_STATION_ID,SENSORNAME;
          """
    sql = sql % (stationName)
    try:
      dbCursor = self.dbCon.cursor()
      dbCursor.execute(sql)
      rows = dbCursor.fetchall()
      dbCursor.close()
      return(rows)
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(None)

  def getStationSensorCount(self, station, sensor, startDate, endDate):
    numRecords = None
    if(self.logger):
      self.logger.debug("%s sensor: %s count from: %s to: %s" % (station, sensor, startDate, endDate))
    sql = """
          SELECT COUNT(TIME_TAG) AS cnt FROM XC_DATA1 WHERE STATION_ID='%s' AND SENSORNAME='%s' AND
          (TIME_TAG >= #%s# AND TIME_TAG < #%s#);
          """
    try:
      sql = sql % (station, sensor, startDate, endDate)
      #if(self.logger):
      #  self.logger.debug("SQL: %s" % (sql))
      dbCursor = self.dbCon.cursor()
      dbCursor.execute(sql)
      row = dbCursor.fetchone()
      dbCursor.close()
      numRecords = row.cnt
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(numRecords)
  
  def getStationData(self, activeOnly=True):
    stations = None
    if(activeOnly):
      sql = "SELECT * FROM XC_SITES WHERE ENABLED='Y'"
    else:
      sql = "SELECT * FROM XC_SITES"
    try:
      dbCursor = self.dbCon.cursor()
      dbCursor.execute(sql)
      stations = dbCursor.fetchall()
      dbCursor.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(stations)
  
  def getTelemetryData(self, stationId, startDate, endDate):
    telemetryData = None
    try:
      sql = "SELECT SENSORNAME,TIME_TAG,ED_VALUE FROM XC_DATA1 WHERE STATION_ID='%s' AND (TIME_TAG >= #%s# AND TIME_TAG < #%s#) ORDER BY TIME_TAG ASC, SENSORNAME ASC" % (stationId, startDate, endDate)
      dbCursor = self.dbCon.cursor()
      dbCursor.execute(sql)
      telemetryData = dbCursor.fetchall()
      dbCursor.close()
    except Exception,e:
      if(self.logger):
        self.logger.exception(e)
    return(telemetryData)
  
def main():
  logger = None
  try:    
    """
    parser = optparse.OptionParser()  
    parser.add_option("-c", "--ConfigFile", dest="configFile",
                      help="Configuration file" )
    (options, args) = parser.parse_args()

    configFile = ConfigParser.RawConfigParser()
    configFile.read(options.configFile)

    logFile = configFile.get('logging', 'configfile')
    """
    uptimeDir = "D:\\scripts\\uptime"
    logFile = "XConnectDB.conf"
    logging.config.fileConfig(logFile)
    logger = logging.getLogger("xconnect_db_logger")
    logger.info('Log file opened')

    xcDB = xConnectDB()
    if(xcDB.connect('DSN=NERRS Telemetry;')):
      if(logger):
        logger.info("Connected to database.")
    else:      
      if(logger):
        logger.error("Unable to connect to DSN.")
      sys.exit(-1)
    stations = xcDB.getActiveStations()
    for station in stations:
      headerLine = ""
      dataLine = ""
      if(logger):
        logger.info("Processing station: %s" % (station))

      #If the file does not exist, we want to write a header line.  
      writeHeader = False      
      fileName = "%s\\SensorCount_%s.csv" % (uptimeDir, station)
      if(os.path.isfile(fileName) == False):
        writeHeader = True
        if(logger):
          logger.info("File: %s does not exist" % (fileName))
      try:
        if(logger):
          logger.info("Opening file: %s" % (fileName))
        outFile = open(fileName, 'a')
      except IOError, e:
        if(logger):
          logger.exception(e)
      else:          
        if(writeHeader):
          headerLine += 'Station,Start Date, End Date'
          
        endDate = datetime.datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        startDate = endDate - datetime.timedelta(days=1)

        dataLine += '%s,%s,%s' % (station, startDate.strftime("%Y-%m-%d %H:%M:%S"), endDate.strftime("%Y-%m-%d %H:%M:%S"))

        rows = xcDB.getStationSensors(station)
        for row in rows:
          if(len(dataLine)):
            dataLine += ","
            
          if(writeHeader):
            if(len(headerLine)):
              headerLine += ","
            headerLine += "%s(%s)" % (row.SENSORNAME, row.DESCRIPTION)

            
          numRecords = xcDB.getStationSensorCount(station,
                                     row.SENSORNAME,
                                     startDate.strftime("%Y-%m-%d %H:%M:%S"),
                                     endDate.strftime("%Y-%m-%d %H:%M:%S"))
          if(numRecords):
            dataLine += '%d' % (numRecords)
          else:
            dataLine += ''
        if(writeHeader):
          outFile.write(headerLine + "\n")
        outFile.write(dataLine + "\n")
        if(logger):
          logger.info("Closing output file.")
        outFile.close()

        #break
    xcDB.disconnect()
      
  except Exception,e:
    if(logger != None):
      logger.exception(e)
    else:
      import traceback
      traceback.print_exc()
  if(logger):
    logger.info('Log file closing.')

    


if __name__ == '__main__':
  main()
