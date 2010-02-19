import sys
import array
import time
import optparse

from xeniatools.xenia import dbXenia
from xeniatools.xenia import xeniaSQLite
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import dbTypes
from xeniatools.xenia import qaqcTestFlags
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict
from xeniatools.xmlConfigFile import xmlConfigFile

from lxml import etree
import logging
import logging.handlers



"""
Class: rangeLimits
Purpose: Simple structure containing a hi and lo range.
"""
class rangeLimits:
  def __init__(self):
    self.rangeLo = None
    self.rangeHi = None

"""
Class: obsInfo
Purpose: Container for the various limits(sensor,gross,climate) for the given observation type.
"""    
class obsInfo:
  def __init__(self, obsName):
    self.obsName        = obsName           #Observation these limits are for.
    self.sensorID       = None              #Correllary to the Xenia sensor ID(not m_type)
    self.uom            = None              #units of measurement for the observation.
    self.updateInterval = None              #The rate at which the sensor updates.
    self.sOrder         = 1                 #The sensor order.
    self.sensorRangeLimits = rangeLimits()  #The limits for the sensor range.
    self.grossRangeLimits = rangeLimits()   #The limits for the gross range.
    self.climateRangeLimits = {}            #A dictionary keyed from 1-12 representing the climate ranges for the month.
    
"""
Class: platformInfo
Purpose: This class encapsulates the limits for each sensor on a platform.     
"""
class platformInfo:
  """
  Function: __init__
  Purpose: Initializes the class. 
  Paramters: 
    platform is the platform name this class is used for.
  """
  def __init__(self,platform):
    self.platformHandle = platform      #Platform name
    self.obsList = {}                   #Dictionary keyed on the observation names that contains obsInfo objects for each observation on the platform.
  """
  Function:addObsInfo
  Purpose: Add a new obsInfo class into this classes obsList dictionary
  Parameters: 
    obsNfo is an obsInfo class to store into the dictionary
  """  
  def addObsInfo(self, obsNfo):
    self.obsList[obsNfo.obsName] = obsNfo
    
  """
  Function: getObsInfo
  Purpose: For the given obsName, this routine looks to see if it exists in the dictionary, and if so returns it.
  Parameters: 
    obsName is the observation name we are looking up.
  Return: 
    obsInfo class for the obsName, if none found returns None.
  """  
  def getObsInfo(self, obsName):
    if( obsName in self.obsList != False ):
      return( self.obsList[obsName] )
    return( None )

"""
Class: obsRangeCheck
Purpose: Implements the range checks for an observation as defined in the Seacoos netCDF document.
"""  
class obsRangeCheck:
  
  """
  Function: __init__
  Purpose: Initializes the class. 
  Paramters: 
    obsName is the observation this class is used for. Default value is ''
  """
  def __init__(self, obsName ='' ):
    self.limits = rangeLimits()       #rangeLimits object to contain the limits
    self.testType   = None            #Test type(qaqcTestFlags) this objects limits are used for.
    self.observation = obsName        #The observation name this classes checks are for.
  
  """
  Function: setRanges
  Purpose: Sets the upper and lower range for the test. 
  Paramters: 
    limits is the rangeLimits object containing the limits to use.
    testType is the type(qaqcTestFlags) of test the limits are used for, default is None.
  """
  def setRanges(self, limits, testType = None ):
    self.limits.rangeLo = limits.rangeLo
    self.limits.rangeHi = limits.rangeHi
    self.testType       = testType
    
    
  """
  Function: rangeTest
  Purpose: performs the range test. Checks are done to verify limits were provided as well as a valid value. 
  Paramters: 
    value is the data we are range checking.
  Return:
    If the test is sucessful, qaqcTestFlags.TEST_PASSED is returned. 
    if the test fails, qaqcTestFlags.TEST_FAILED is returned.
    if no limits or no value was provided, qaqcTestFlags.NO_TEST is returned.
  """
  def rangeTest(self, value):
    if( self.limits.rangeLo != None and self.limits.rangeHi != None ):
      if( value != None ):
        if( value < self.limits.rangeLo or value > self.limits.rangeHi ):
          return( qaqcTestFlags.TEST_FAILED )
        return( qaqcTestFlags.TEST_PASSED )      
      else:
        return( qaqcTestFlags.NO_TEST )      
    return( qaqcTestFlags.NO_TEST )
  
  def getTestType(self):
    return(self.testType)

"""
Class: qcTestSuite
Purpose: Implements the range tests and qcFlag determination detailed in the Seacoos netCDF documentation.
"""
class qcTestSuite:
  def __init__(self):
    #Values for each of these flags can be: Values can be qaqcTestFlags.NO_TEST, qaqcTestFlags.TEST_FAILED, qaqcTestFlags.TEST_PASSED
    self.dataAvailable      = qaqcTestFlags.NO_TEST   #Flag specifing the validity of whether data is available. 1st test performed
    self.sensorRangeCheck   = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the sensor range check. 2nd test performed
    self.grossRangeCheck    = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the gross range check. 3rd test performed
    self.climateRangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the climate range check. 4th test performed
    self.rateofchangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the rate of change check.
    self.nearneighborCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the nearest neighbor check.
    self.rangeCheck         = obsRangeCheck()         #obsRangeCheck object used to do the limits tests.
    self.qcFlag             = qaqcTestFlags.DATA_QUAL_NO_EVAL #The aggregate quality flag as specified by the Seacoos netCDF doc.
                                                              #Values can be qaqcTestFlags.NO_DATA,qaqcTestFlags.DATA_QUAL_NO_EVAL,
                                                              #qaqcTestFlags.DATA_QUAL_BAD, qaqcTestFlags.DATA_QUAL_SUSPECT, qaqcTestFlags.DATA_QUAL_GOOD

  """
  Function: runRangeTests
  Purpose: Runs each of the limits tests, starting with the sensor range test. Each must pass to be able to move on to the next one.
  As the tests are run, this function is also setting the flags specifing the outcome of each test. These flags are later used in the
  qclevel calculation.
  Parameters:
    obsNfo is the obsInfo object used.
    value is the floating point value we are testing.
    month is the numeric representation of the month to use for the climate range tests.
  Return:
    qaqcTestFlags.TEST_PASSED is the tests were passed, otherwise qaqcTestFlags.TEST_FAILED.
  """
  def runRangeTests(self, obsNfo, value, month = 0):
    #Do we have a valid value?
    if(value != None):     
      self.dataAvailable = qaqcTestFlags.TEST_PASSED
      #Did we get a valid obsNfo that we need for the limits?
      if( obsNfo != None ):
        if( obsNfo.sensorRangeLimits.rangeLo != None and obsNfo.sensorRangeLimits.rangeHi != None ):
          self.rangeCheck.setRanges( obsNfo.sensorRangeLimits )
          self.sensorRangeCheck = self.rangeCheck.rangeTest( value )
          #If we don't pass the sensor range check, do not run any other tests.
          if( self.sensorRangeCheck == qaqcTestFlags.TEST_PASSED ):    
            #Run the gross range checks if we have limits.    
            if( obsNfo.grossRangeLimits.rangeLo != None and obsNfo.grossRangeLimits.rangeHi != None ):
              self.rangeCheck.setRanges( obsNfo.grossRangeLimits )
              self.grossRangeCheck = self.rangeCheck.rangeTest( value )
            #Run the climatalogical range checks if we have limits.    
            if( len(obsNfo.climateRangeLimits) and month != 0 ):
              limits = obsNfo.climateRangeLimits[month]
              self.rangeCheck.setRanges( limits )
              self.climateRangeCheck = self.rangeCheck.rangeTest( value )
    else:
      self.dataAvailable      = qaqcTestFlags.TEST_FAILED  

  """
  Function: calcQCLevel
  Purpose: Calculates the aggregate data quality flag. This determination depends on the value of each of the limit test flags.
  Parameters:
  Return:
    qaqcTestFlags.DATA_QUAL_GOOD if all the range tests were completed successfully. 
  """
  def calcQCLevel(self):
    if( self.dataAvailable == qaqcTestFlags.NO_TEST or self.sensorRangeCheck == qaqcTestFlags.NO_TEST ):
      self.qcFlag = qaqcTestFlags.DATA_QUAL_NO_EVAL
    #Was there any data available?
    elif( self.dataAvailable == qaqcTestFlags.TEST_FAILED ):
      self.qcFlag = qaqcTestFlags.NO_DATA
    else:
      #Did the sensor range test fail?
      if( self.sensorRangeCheck == qaqcTestFlags.TEST_FAILED ):
        self.qcFlag = qaqcTestFlags.DATA_QUAL_BAD
      else:
        #Were tests performed for range, climate and rate of change?
        if( (self.grossRangeCheck == qaqcTestFlags.NO_TEST) and
            (self.climateRangeCheck == qaqcTestFlags.NO_TEST) and
            (self.rateofchangeCheck == qaqcTestFlags.NO_TEST) ):
          self.qcFlag = qaqcTestFlags.DATA_QUAL_NO_EVAL
        #Did the tests performed for range or climate or rate of change fail?
        elif( (self.grossRangeCheck == qaqcTestFlags.TEST_FAILED) or
               (self.climateRangeCheck == qaqcTestFlags.TEST_FAILED) or
               (self.rateofchangeCheck == qaqcTestFlags.TEST_FAILED) ):
          self.qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
        #
        elif( ( (self.grossRangeCheck == qaqcTestFlags.NO_TEST) and (self.climateRangeCheck == qaqcTestFlags.NO_TEST) ) or
              ( (self.grossRangeCheck == qaqcTestFlags.NO_TEST) and (self.rateofchangeCheck == qaqcTestFlags.NO_TEST) ) or
              ( (self.climateRangeCheck == qaqcTestFlags.NO_TEST) and (self.rateofchangeCheck == qaqcTestFlags.NO_TEST) ) ):  
          self.qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
        #
        elif( ( (self.grossRangeCheck == qaqcTestFlags.TEST_PASSED) and (self.climateRangeCheck == qaqcTestFlags.TEST_PASSED) ) or
              ( (self.grossRangeCheck == qaqcTestFlags.TEST_PASSED) and (self.rateofchangeCheck == qaqcTestFlags.TEST_PASSED) ) or
              ( (self.climateRangeCheck == qaqcTestFlags.TEST_PASSED) and (self.rateofchangeCheck == qaqcTestFlags.TEST_PASSED) ) ):  
          self.qcFlag = qaqcTestFlags.DATA_QUAL_GOOD
        else:
          self.qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
            
    return( self.qcFlag )
"""
Class: loadSettings
Purpose: Depending on the routine used, loads the limits to be used. This class will be expanded to use the database or the sensor inventory
  xml file. 
"""  
class loadSettings:
  """
  Function: loadFromTestProfilesXML
  Purpose: Loads the limits from the test_profiles.xml file passed in with xmlConfigFile
  Parameters: 
    xmlConfigFile is the full path to the test_profiles file to use.
  """  
  def loadFromTestProfilesXML(self, xmlConfigFile):  
    platformInfoDict = {}
    try:
      monthList = {'Jan': 1, 'Feb': 2, 'Mar': 3, "Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12 }
      xmlTree = etree.parse(xmlConfigFile)
      testProfileList = xmlTree.xpath( '//testProfileList')
      for testProfile in testProfileList[0].getchildren():
        #See if the test profile has an ID.
        id = testProfile.xpath( 'id' )
        if( len(id) ):
          id = id[0].text
        #Determine which platforms are in this testProfile
        platformList = testProfile.xpath('platformList')
        for platform in platformList[0].getchildren():          
          platformHandle = platform.text
          platformInfoDict[platformHandle] = platformInfo(platformHandle)
          
          #Now loop through and get all the observations.
          obsList = testProfile.xpath('obsList')
          for obs in obsList[0].getchildren():             
            obsHandle  = obs.xpath('obsHandle' )
            if( len(obsHandle) ):             
              obsHandle = obsHandle[0].text
                            
              #The handle is in the form of observationname.units of meaure: "wind_speed.m_s-1" for example               
              parts = obsHandle.split('.')
              obsSettings = obsInfo(parts[0])
              obsSettings.uom = parts[1]

              #DWR v1253
              #Added sorder since if we do have multiples of the same obs on a platform, we need to distinguish them.
              sOrder = obs.xpath('sOrder')
              #Set the sOrder if we have one.
              if(len(sOrder)):
                obsSettings.sOrder = int(sOrder[0].text)
                          
              #Rate at which the sensor updates.              
              interval  = obs.xpath('UpdateInterval' )
              if( len(interval) ):
                obsSettings.updateInterval = int(interval[0].text)            
              #Ranges
              hi  = obs.xpath('rangeHigh' )
              if( len(hi) ):
                obsSettings.sensorRangeLimits.rangeHi = float(hi[0].text)            
              lo  = obs.xpath('rangeLow' )
              if( len(lo) ):
                obsSettings.sensorRangeLimits.rangeLo = float(lo[0].text)        
              grossHi  = obs.xpath('grossRangeHigh' )
              if( len(grossHi) ):
                obsSettings.grossRangeLimits.rangeHi = float(hi[0].text)            
              grossLo  = obs.xpath('grossRangeLow' )
              if( len(grossLo) ):
                obsSettings.grossRangeLimits.rangeLo = float(lo[0].text)        
              
              #Check to see if we have a climate range, if not, we just use the grossRange.
              climateList = obs.xpath('climatologicalRangeList')
              if( len(climateList ) ):
                for climateRange in climateList[0].getchildren():             
                  limits = rangeLimits()
                  startMonth  = climateRange.xpath('startMonth' )
                  if( len(startMonth) ):
                    startMonth = startMonth[0].text
                  endMonth  = climateRange.xpath('endMonth' )
                  if( len(endMonth) ):
                    endMonth = endMonth[0].text
                  rangeHi  = climateRange.xpath('rangeHigh' )
                  if( len(rangeHi) ):
                    limits.rangeHi = float(rangeHi[0].text)
                  rangeLo  = climateRange.xpath('rangeLow' )
                  if( len(rangeLo) ):
                    limits.rangeLo = float(rangeLo[0].text)
                  #Since the climate range entries can span multiple months, for ease of use we want to have a 
                  #bucket per month so we need to check the start and end dates to see if we need to break them up.
                  #Also to take note, the limits are stored in a dictionary keyed by the month number, so we normally 
                  #start at 1 and not 0. 
                  strtNum = monthList[startMonth]
                  endNum = monthList[endMonth]
                  #If we have an interval between the start and end greater than one, we've got a range of months covered.
                  if( (endNum - strtNum) > 1 ):
                    i = strtNum
                    #Loop adding limits for each month in the range.
                    while( i < endNum ):
                      obsSettings.climateRangeLimits[i] = limits
                      i += 1
                  else:
                    obsSettings.climateRangeLimits[strtNum] = limits
              #No climate range given, so we default to the grossRange.
              else:
                limits = rangeLimits()
                limits.rangeHi = obsSettings.grossRangeLimits.rangeHi
                limits.rangeLo = obsSettings.grossRangeLimits.rangeLo
                for i in range( 1,13 ):
                  obsSettings.climateRangeLimits[i] = limits
                  
              #Now add the observation to our platform info dictionary.
              platformNfo = platformInfoDict[platformHandle]
              platformNfo.addObsInfo(obsSettings)
        
      return( platformInfoDict )
    except Exception, e:
      print( 'ERROR: ' + str(e)  + ' Terminating script')

class rangeTests(object):
  def __init__(self, xmlConfigFilename):
    self.cfgFile = xmlConfigFile(xmlConfigFilename)
    logFile = ''
    self.logger = None
    logFile = self.cfgFile.getEntry('//environment/logging/logDir')
    if(logFile != None):
      streamHandler = False
      tag = self.cfgFile.getEntry('//environment/logging/streamhandler')
      if(tag != None):
        streamHandler = True
  
      tag = self.cfgFile.getEntry('//environment/logging/maxBytes')
      if(tag != None):
        maxBytes = int(tag)
      else:
        print( 'ERROR: //environment/logging/maxBytes not defined in config file. Using 1000000' )
        maxBytes = 1000000
  
      tag = self.cfgFile.getEntry('//environment/logging/backupCount')
      if(tag != None):
        backupCount = int(tag)
      else:
        print( 'ERROR: //environment/logging/backupCount not defined in config file. Using 5' )
        backupCount = 5
        
      self.logger = logging.getLogger("qaqc_logger")
      self.logger.setLevel(logging.DEBUG)
      # create formatter and add it to the handlers
      formatter = logging.Formatter("%(asctime)s,%(levelname)s,%(lineno)d,%(message)s")
      handler = logging.handlers.RotatingFileHandler( logFile, "a", maxBytes, backupCount )
      handler.setLevel(logging.DEBUG)
      handler.setFormatter(formatter)    
      self.logger.addHandler(handler)
      
      #Do we want to create a stream handler to put the message out to stdout?
      if(streamHandler):
        logSh = logging.StreamHandler()
        logSh.setLevel(logging.DEBUG)
        logSh.setFormatter(formatter)
        self.logger.addHandler(logSh)
      self.logger.info('Log file opened.')
    
    #Get the settings for how the qc Limits are stored so we know how to process them.
    settings = loadSettings()
    type = self.cfgFile.getEntry('//environment/qcLimits/fileType')
    if(type != None):
      if( type == 'test_profiles' ):
        tag = self.cfgFile.getEntry('//environment/qcLimits/file')
        if(tag != None):
          self.platformInfoDict = settings.loadFromTestProfilesXML(tag)
          if(self.logger != None):
            self.logger.info("Limits type file: %s File: %s" % (type,tag) )
          else:
            print("Limits type file: %s File: %s" % (type,tag))
        else:
          if(self.logger != None):
            self.logger.error("No QC Limits provided.")
          else:
            print("No QC Limits provided.")
          sys.exit(-1)
    else:
      if(self.logger != None):
        self.logger.error("No QC Limits type provided.")
      else:
        print("No QC Limits type provided.")      
      sys.exit(-1)
      
    self.db = None
    dbSettings = self.cfgFile.getDatabaseSettings()
    if(dbSettings['type'] != None):
      self.db = dbXenia()      
      #Are we connecting to a SQLite database?
      if(dbSettings['type'] == 'sqlite'):
        if(dbSettings['dbName']):
          if(self.db.connect(dbSettings['dbName']) == False):
            if(self.logger != None):
              self.logger.error("Unable to connect to SQLite database.")
            else:
              print("Unable to connect to SQLite database.")              
            sys.exit(-1)
          if(self.logger != None):           
            self.logger.info("Database type: %s File: %s" % (dbSettings['type'],dbSettings['dbName']) )
          else:
            print("Database type: %s File: %s" % (dbSettings['type'],dbSettings['dbName']) )            
       #PostGres db?
      elif(dbSettings['type'] == 'postgres'):
        if(len(dbSettings['dbName']) and len(dbSettings['dbUser']) and len(dbSettings['dbPwd'])):
          if(self.db.connect( None, dbSettings['dbUser'], dbSettings['dbPwd'], dbSettings['dbHost'], dbSettings['dbName'] ) == False):
            if(self.logger != None):
              self.logger.error( "Unable to connect to PostGres. host: %s UDBName: %s user: %s pwd: %s ErrorMsg: %s" % (host,name,user,pwd,db.lastErrorMsg) )
            else:
              print( "Unable to connect to PostGres. host: %s UDBName: %s user: %s pwd: %s ErrorMsg: %s" % (host,name,user,pwd,db.lastErrorMsg) )
            sys.exit(-1)
        else:
          if(self.logger != None):
            self.logger.error( "Missing configuration info for PostGres setup." )
          else:
            print( "Missing configuration info for PostGres setup." )            
          sys.exit(-1)        
    else:
      if(self.logger != None):
        logger.error( "No database type provided." )
      else:
        print( "No database type provided." )
      sys.exit(-1)
    
    self.sqlUpdateFile = self.cfgFile.getEntry( '//environment/database/sqlQCUpdateFile' )
    if(tag != None):
      if(self.logger != None):
        self.logger.info( "SQL QC Update file: %s" % (self.sqlUpdateFile))
      else: 
        print( "SQL QC Update file: %s" % (self.sqlUpdateFile))
    else:
      if(self.logger != None):
        self.logger.error("No SQL update filename.")
      else:
        print("No SQL update filename.")        
      
    #Get conversion xml file
    self.uomConvertFile = self.cfgFile.getEntry('//environment/unitsCoversion/file')
    if(self.uomConvertFile != None):
      if(self.logger != None):
        self.logger.info("Units conversion file: %s" % (self.uomConvertFile) )
      else:
        print("Units conversion file: %s" % (self.uomConvertFile) )
    else:
      if(self.logger != None):
        self.logger.debug("No units conversion file specified in config file." % (self.uomConvertFile) )
      else:
        print("No units conversion file specified in config file." % (self.uomConvertFile) )
  
    self.lastNHours = None
    self.startDate  = None
    self.endDate    = None
    self.ignoreQAQCFlags = False
    self.totalRows  = 0
    self.qcTotalFailCnt = 0
    self.qcTotalMissingLimitsCnt = 0
    
  
  def setLastNHours(self, lastNHours):
    self.lastNHours = lastNHours
    self.queryRecords(lastNHours, None, None, self.ignoreQAQCFlags)
  
  def setDateRange(self, startDate, endDate):
    self.startDate = startDate
    self.endDate = endDate
    self.queryRecords(None, self.startDate, self.endDate, self.ignoreQAQCFlags)
    
  def setQCSQLFile(self, sqlFileName):
    self.sqlUpdateFile = sqlFileName
  
  def restampQAQCRecords(self, restampQAQC):
    self.ignoreQAQCFlags = restampQAQC
    if(self.logger != None and restampQAQC):
      self.logger.debug("Restamping QAQC Flags.")
         
  def performTests(self, platformNfo, dbCursor, sqlUpdateFile):
    try:

      qcFailCnt = 0
      qcMissingLimitsCnt = 0   
      rowCnt = 0
      row = dbCursor.fetchone()
      lastDate = None
      while( row != None ):
        dataTests = qcTestSuite()
        rowCnt += 1
        if( row['standard_name'] != None ):
          obsName   = row['standard_name']
          
          dateVal = None
          if( row['m_date'] != None ):
            dateVal = row['m_date']
            #Determine if we were given a datetime object. The psycopg2 connection returns that type, although
            #pysqlite returns just the string since it has no datetime concept.
            if( dateVal.__class__.__name__ == 'datetime' ):
              dateVal = dateVal.__str__()
                        
          uom = None
          if( row['uom'] != None ):
            uom = row['uom']
          
          m_type_id = -1    
          if( row['m_type_id'] != None ):
            m_type_id = int(row['m_type_id'])
            
          m_value = None
          if( row['m_value'] != None ):
            m_value   = float(row['m_value'])
  
          sensor_id = -1
          if( row['sensor_id'] != None ):
            sensor_id = int(row['sensor_id'])
            
          s_order = -1
          if( row['s_order'] != None ):
            s_order   = int(row['s_order'])
          
          if( lastDate == None or lastDate != dateVal ):
            lastDate = dateVal
            
          obsNfo = platformNfo.getObsInfo(obsName)
          #the qc_flag in the database is a string. We've defined a character array to represent each type of test, so
          #here we fill up the array with 0s to begin with, then per array ndx set the test results.
          qcFlag = array.array('c')
          fill = ''       
          fill = fill.zfill(qaqcTestFlags.TQFLAG_NN+1)   
          qcFlag.fromstring(fill)
  
          qcLevel = qaqcTestFlags.DATA_QUAL_NO_EVAL
          if( obsNfo != None ):
            if( obsNfo.sensorID == None ):
              obsNfo.sensorID = sensor_id            
            #Check to see if the units of measurement for the limits is the same for the data, if not we'll get our conversion factor.
            if( uom != obsNfo.uom and m_value != None ):
              uomConvert = uomconversionFunctions(self.uomConvertFile)
              convertedVal = uomConvert.measurementConvert( m_value, obsNfo.uom, uom)
              if(convertedVal != None ):
                m_value = convertedVal
          else:
            qcMissingLimitsCnt += 1
            if( self.logger != None ):
              self.logger.error( "%s No limit set for obsName: %s" % (dateVal, obsName) )
              
          #Get the numeric representation of the month(1...12)
          dateformat = "%Y-%m-%dT%H:%M:%S"
          if( dateVal.find("T") == -1 ):
            dateformat = "%Y-%m-%d %H:%M:%S"
            
          month = int(time.strftime( "%m", time.strptime(dateVal, dateformat) ))
          dataTests.runRangeTests(obsNfo, m_value, month)
          
          #The qcFlag string is interpreted as follows. The leftmost byte is the first test, which is the data available test,
          #each preceeding byte is another test of lesser importance. We store the values in a string which is to always contain
          #the same number of bytes for consistency. Some examples:
          #"000000" would represent no tests were done
          #"200000" represents the data available test was done and passed(0 = no test, 1 = failed, 2 = passed)
          #"220000" data available, sensor range tests performed.
          qcFlag[qaqcTestFlags.TQFLAG_DA] = ( "%d" % dataTests.dataAvailable )
          qcFlag[qaqcTestFlags.TQFLAG_SR] = ( "%d" % dataTests.sensorRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_GR] = ( "%d" % dataTests.grossRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_CR] = ( "%d" % dataTests.climateRangeCheck )
          qcLevel = dataTests.calcQCLevel()
                                        
          if( qcLevel == qaqcTestFlags.DATA_QUAL_BAD and self.logger != None ):
            self.logger.debug( "QCTest Failed: Date %s obsName: %s value: %f(%s) qcFlag: %s qcLevel: %d" % (dateVal, obsName, ( m_value != None ) and m_value or -9999.0, ( uom != None ) and uom or '', qcFlag.tostring(), qcLevel) )
            qcFailCnt += 1
  
          sql = "UPDATE multi_obs SET \
                  qc_flag='%s',qc_level=%d WHERE \
                  m_date='%s' AND sensor_id=%d" \
                  %(qcFlag.tostring(), qcLevel, dateVal, sensor_id)
          sqlUpdateFile.write(sql+"\n")
          row = dbCursor.fetchone()
      if(self.logger != None):                
        self.logger.debug( "End processing rows" )
        
      #Keep a running count of the total number of rows processed.    
      self.totalRows += rowCnt
      self.qcTotalFailCnt += qcFailCnt
      self.qcTotalMissingLimitsCnt += qcMissingLimitsCnt
      if(self.logger != None):
        self.logger.info( "QAQC suspect or bad count: %d QAQC no limits count: %d" %(qcFailCnt,qcMissingLimitsCnt) )
      return(rowCnt)
    
    except Exception, e:
      import traceback     
      errMsg = "ERROR Terminating script." 
      if( self.logger != None ):
        self.logger.error(errMsg, exc_info=1)
      else:
        print( traceback.print_exc() )
        
    return(0)

  def queryRecords(self, lastNHours=None, beginDate=None, endDate=None, ignoreQCedRecords=False):
    try:
      sqlUpdateFile = open(self.sqlUpdateFile, "w")
      totalprocTime = processingEnd = processingStart = 0
      for platformKey in self.platformInfoDict.keys():
        
        if( sys.platform == 'win32'):
           processingStart = time.clock()
        else:
           processingStart = time.time()
           
        if(self.logger != None):
          self.logger.debug( "Start processing platform: %s" % (platformKey) )
        
        platformNfo = self.platformInfoDict[platformKey]
        startTime = 0;
                                        
        dbCursor = None
        if( lastNHours != None ):
          if(self.db.dbConnection.dbType == dbTypes.SQLite):
            dateOffset = "m_date > strftime('%%Y-%%m-%%dT%%H:%%M:%%S', 'now','-%d hours') AND" % (lastNHours)
          else:
            dateOffset = "m_date >  date_trunc('hour',( SELECT timezone('UTC', now()-interval '%d hours' ) ) ) AND" % (lastNHours)
          if(self.logger != None):
            self.logger.debug( "Processing Last: %d hours." % (lastNHours) )
        elif(beginDate != None and endDate != None):
          dateOffset = "(m_date >= '%s' AND m_date < '%s') AND" % (beginDate,endDate)
        else:
          if(self.logger != None):
            self.logger.error("No time period specified for database query. Cannot continue.")
          else:
            print("No time period specified for database query. Cannot continue.")
          sys.exit(-1)
        
        qcSQL = ''
        if(ignoreQCedRecords == False):
           qcSQL = "AND qc_level IS NULL"

        sql= "SELECT m_date \
              ,multi_obs.platform_handle \
              ,obs_type.standard_name \
              ,uom_type.standard_name as uom \
              ,multi_obs.m_type_id \
              ,m_value \
              ,qc_level \
              ,sensor.row_id as sensor_id\
              ,sensor.s_order \
            FROM multi_obs \
              left join sensor on sensor.row_id=multi_obs.sensor_id \
              left join m_type on m_type.row_id=multi_obs.m_type_id \
              left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id \
              left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id \
              left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id \
              WHERE %s multi_obs.platform_handle = '%s' %s AND sensor.row_id IS NOT NULL\
              ORDER BY m_date DESC" \
              % (dateOffset, platformKey, qcSQL)
        if(self.logger != None):
          self.logger.debug(sql)       
        dbCursor = self.db.dbConnection.executeQuery(sql)       
        rowCnt = self.performTests(platformNfo, dbCursor, sqlUpdateFile)
        dbCursor.close()
        
        if( sys.platform == 'win32'):
          processingEnd = time.clock()
        else:
          processingEnd = time.time()
        totalprocTime += (processingEnd-processingStart)
        
        if(self.logger != None):
          self.logger.debug( "%d rows in time: %f(ms)" %(rowCnt, ((processingEnd-processingStart)*1000.0 )) )
          self.logger.debug( "End processing platform: %s" % (platformKey) )
          
      if(self.logger != None):
        self.logger.debug("QAQC Proc'd: %d rows in time: %f(ms)" %(self.totalRows, totalprocTime * 1000.0 ))
        self.logger.debug("End QAQC processing")
    except Exception, e:
      import traceback     
      errMsg = "ERROR Terminating script." 
      if( self.logger != None ):
        self.logger.error(errMsg, exc_info=1)
      else:
        print( traceback.print_exc() )
    except IOError, e:
      import traceback      
      errMsg = "ERROR Terminating script." 
      if( self.logger != None ):
        self.logger.error(errMsg, exc_info=1)
      else:
        print( traceback.print_exc() )
    
if __name__ == '__main__':
  if( len(sys.argv) < 2 ):
    print( "Usage: rangeCheck.py xmlconfigfile")
    sys.exit(-1)    
    
  totalRows = 0
  qcTotalFailCnt = 0
  qcTotalMissingLimitsCnt = 0
  if( sys.platform == 'win32'):
    startProcess = time.clock()
  else:
    startProcess = time.time()
  

  #Get the various settings we need from out xml config file.
  xmlTree = etree.parse(sys.argv[1])

  #Setup the log file
  logFile = ''
  logger = None
  if(len(xmlTree.xpath( '//environment/logging/logDir' ))):
    logFile = xmlTree.xpath( '//environment/logging/logDir' )[0].text
    
    streamHandler = False
    if( xmlTree.xpath( '//environment/logging/streamhandler') ):
      tag = int(xmlTree.xpath( '//environment/logging/streamhandler')[0].text)
      if( tag ):
        streamHandler = True

    tag = xmlTree.xpath( '//environment/logging/maxBytes' )
    if(len(tag)):
      maxBytes = int(tag[0].text)
    else:
      print( 'ERROR: //environment/logging/maxBytes not defined in config file. Using 1000000' )
      maxBytes = 1000000

    tag = xmlTree.xpath( '//environment/logging/backupCount' )
    if(len(tag)):
      backupCount = int(tag[0].text)
    else:
      print( 'ERROR: //environment/logging/backupCount not defined in config file. Using 5' )
      backupCount = 5
      
    logger = logging.getLogger("qaqc_logger")
    logger.setLevel(logging.DEBUG)
    # create file handler which logs even debug messages
    #logFh = logging.FileHandler(logFile)
    #logFh.setLevel(logging.DEBUG)
    # create formatter and add it to the handlers
    formatter = logging.Formatter("%(asctime)s,%(levelname)s,%(lineno)d,%(message)s")
    #logFh.setFormatter(formatter)
    #logger.addHandler(logFh)
    handler = logging.handlers.RotatingFileHandler( logFile, "a", maxBytes, backupCount )
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(formatter)    
    logger.addHandler(handler)
    
    #Do we want to create a stream handler to put the message out to stdout?
    if(streamHandler):
      logSh = logging.StreamHandler()
      logSh.setLevel(logging.DEBUG)
      logSh.setFormatter(formatter)
      logger.addHandler(logSh)
    logger.info('Log file opened.')
  
  #Get the settings for how the qc Limits are stored so we know how to process them.
  settings = loadSettings()
  if(len(xmlTree.xpath( '//environment/qcLimits/fileType' ))):
    type = xmlTree.xpath( '//environment/qcLimits/fileType' )[0].text
    if( type == 'test_profiles' ):
      if( len(xmlTree.xpath( '//environment/qcLimits/file' )) ):
        xmlTag = xmlTree.xpath( '//environment/qcLimits/file' )[0].text
        platformInfoDict = settings.loadFromTestProfilesXML(xmlTag)
        if( logger != None ):
          logger.info("Limits type file: %s File: %s" % (type,xmlTag) )
      else:
        if( logger != None ):
          logger.error( "No QC Limits provided." )
        sys.exit(-1)
  else:
    if( logger != None ):
      logger.error( "No QC Limits type provided." )
    sys.exit(-1)
    
  #tstDB = None
  #db = xeniaDB()
  db = None
  if(len(xmlTree.xpath( '//environment/database/db/type' ))):
    type = xmlTree.xpath( '//environment/database/db/type' )[0].text
    #Are we connecting to a SQLite database?
    if( type == 'sqlite' ):
      if(len(xmlTree.xpath( '//environment/database/db/name' ))):
        xmlTag = xmlTree.xpath( '//environment/database/db/name' )[0].text
        #xmlTag = time.strftime(xmlTag, time.gmtime())        
        #db.openXeniaSQLite( xmlTag )
        db = xeniaSQLite()
        if( db.connect( xmlTag ) == False ):
          if( logger != None ):
            logger.error( "Unable to connect to SQLite database." )
            sys.exit(-1)
        if( logger != None ):
          logger.info("Database type: %s File: %s" % (type,xmlTag) )
      else:
        if( logger != None ):
          logger.error( "No Xenia database provided." )
        sys.exit(-1)
     #PostGres db?
    elif( type == 'postgres' ):
      name = xmlTree.xpath( '//environment/database/db/name' )
      user = xmlTree.xpath( '//environment/database/db/user' )
      pwd = xmlTree.xpath( '//environment/database/db/pwd' )
      host = xmlTree.xpath( '//environment/database/db/host' )
      if( len(name) and len(user) and len(pwd) ):
        name = name[0].text
        user = user[0].text
        pwd = pwd[0].text
        host = host[0].text
        db = xeniaPostGres()
        #if( db.openXeniaPostGres( None, name, user, pwd ) == False ):
        if( db.connect( None, user, pwd, host, name ) == False ):
          if( logger != None ):
            logger.error( "Unable to connect to PostGres. host: %s UDBName: %s user: %s pwd: %s ErrorMsg: %s" % (host,name,user,pwd,db.lastErrorMsg) )
            sys.exit(-1)
      else:
        if( logger != None ):
          logger.error( "Missing configuration info for PostGres setup." )
        sys.exit(-1)        
  else:
    logger.error( "No database type provided." )
    sys.exit(-1)
    
  if(len(xmlTree.xpath( '//environment/database/sqlQCUpdateFile' ))):
    xmlTag = xmlTree.xpath( '//environment/database/sqlQCUpdateFile' )[0].text
    sqlUpdateFile = open( xmlTag, "w" )
    if( logger != None ):
      logger.info( "SQL QC Update file: %s" % (xmlTag)) 
  else:
    if( logger != None ):
      logger.error( "No SQL update filename." )
    sys.exit(-1)
  #Get conversion xml file
  uomConvertFile = None
  if(len(xmlTree.xpath( '//environment/unitsCoversion/file' ))):
    uomConvertFile = xmlTree.xpath( '//environment/unitsCoversion/file' )[0].text      
    if( logger != None ):
      logger.info("Units conversion file: %s" % (uomConvertFile) )
  else:
    if( logger != None ):
      logger.debug("No units conversion file specified in config file." % (uomConvertFile) )

  #DWR 1/29/2010 
  #Added pastNHours into the config file to allow changes to how far back in the data we query.      
  lastNHours = xmlTree.xpath('//environment/qcLimits/lastNHours')
  if(len(lastNHours)):
    lastNHours = int(lastNHours[0].text)      
    if( logger != None ):
      logger.info("Getting data for last: %d hours" % (lastNHours) )
    #A value of -1 means we want to query all the past data.
    if(lastNHours == -1):
      lastNHours = None
  else:
    if( logger != None ):
      logger.debug("lastNHours not specified in config file. Using 168." )
      lastNHours = 168
  
  #rangeCheck = obsRangeCheck( '' )
  try:
    for platformKey in platformInfoDict.keys():
      platformNfo = platformInfoDict[platformKey]
      startTime = 0;
      
      if( sys.platform == 'win32'):
        processingStart = time.clock()
      else:
        processingStart = time.time()            
      
      logger.debug( "Processing platform: %s" % (platformKey) )
      dbCursor = db.getObsDataForPlatform( platformKey, lastNHours )
      
      if( dbCursor == None ):
        length = len(db.lastErrorMsg) 
        if( len(db.lastErrorMsg) ):
          if( logger != None ):
            logger.error( "%s" % (db.lastErrorMsg) )
            db.lastErrorMsg = ''
        else:
          if( logger != None ):
            logger.debug( "No data retrieved from query for platform: %s" % (platformKey) )
        continue          
      qcFailCnt = 0
      qcMissingLimitsCnt = 0   
      rowCnt = 0
      row = dbCursor.fetchone()
      lastDate = None
      while( row != None ):
        dataTests = qcTestSuite()
        rowCnt += 1
        if( row['standard_name'] != None ):
          obsName   = row['standard_name']
          
          dateVal = None
          if( row['m_date'] != None ):
            dateVal = row['m_date']
            #Determine if we were given a datetime object. The psycopg2 connection returns that type, although
            #pysqlite returns just the string since it has no datetime concept.
            if( dateVal.__class__.__name__ == 'datetime' ):
              dateVal = dateVal.__str__()
                        
          uom = None
          if( row['uom'] != None ):
            uom = row['uom']
          
          m_type_id = -1    
          if( row['m_type_id'] != None ):
            m_type_id = int(row['m_type_id'])
            
          m_value = None
          if( row['m_value'] != None ):
            m_value   = float(row['m_value'])

          sensor_id = -1
          if( row['sensor_id'] != None ):
            sensor_id = int(row['sensor_id'])
            
          s_order = -1
          if( row['s_order'] != None ):
            s_order   = int(row['s_order'])
          
          if( lastDate == None or lastDate != dateVal ):
            lastDate = dateVal
            
          obsNfo = platformNfo.getObsInfo(obsName)
          #the qc_flag in the database is a string. We've defined a character array to represent each type of test, so
          #here we fill up the array with 0s to begin with, then per array ndx set the test results.
          qcFlag = array.array('c')
          fill = ''       
          fill = fill.zfill(qaqcTestFlags.TQFLAG_NN+1)   
          qcFlag.fromstring(fill)

          qcLevel = qaqcTestFlags.DATA_QUAL_NO_EVAL
          if( obsNfo != None ):
            if( obsNfo.sensorID == None ):
              obsNfo.sensorID = sensor_id            
            #Check to see if the units of measurement for the limits is the same for the data, if not we'll get our conversion factor.
            if( uom != obsNfo.uom and m_value != None ):
              uomConvert = uomconversionFunctions(uomConvertFile)
              convertedVal = uomConvert.measurementConvert( m_value, obsNfo.uom, uom)
              if(convertedVal != None ):
                m_value = convertedVal
          else:
            qcMissingLimitsCnt += 1
            if( logger != None ):
              logger.error( "%s No limit set for Platform: %s obsName: %s" % (dateVal, platformKey,obsName) )
              
          #Get the numeric representation of the month(1...12)
          dateformat = "%Y-%m-%dT%H:%M:%S"
          if( dateVal.find("T") == -1 ):
            dateformat = "%Y-%m-%d %H:%M:%S"
            
          month = int(time.strftime( "%m", time.strptime(dateVal, dateformat) ))
          dataTests.runRangeTests(obsNfo, m_value, month)
          
          #The qcFlag string is interpreted as follows. The leftmost byte is the first test, which is the data available test,
          #each preceeding byte is another test of lesser importance. We store the values in a string which is to always contain
          #the same number of bytes for consistency. Some examples:
          #"000000" would represent no tests were done
          #"200000" represents the data available test was done and passed(0 = no test, 1 = failed, 2 = passed)
          #"220000" data available, sensor range tests performed.
          qcFlag[qaqcTestFlags.TQFLAG_DA] = ( "%d" % dataTests.dataAvailable )
          qcFlag[qaqcTestFlags.TQFLAG_SR] = ( "%d" % dataTests.sensorRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_GR] = ( "%d" % dataTests.grossRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_CR] = ( "%d" % dataTests.climateRangeCheck )
          qcLevel = dataTests.calcQCLevel()
                                        
          if( qcLevel != qaqcTestFlags.DATA_QUAL_GOOD and logger != None ):
            logger.debug( "QCTest Failed: Date %s Platform: %s obsName: %s value: %f(%s) qcFlag: %s qcLevel: %d" % (dateVal, platformKey, obsName, ( m_value != None ) and m_value or -9999.0, ( uom != None ) and uom or '', qcFlag.tostring(), qcLevel) )
            qcFailCnt += 1
  
          sql = "UPDATE multi_obs SET \
                  qc_flag='%s',qc_level=%d WHERE \
                  m_date='%s' AND sensor_id=%d" \
                  %(qcFlag.tostring(), qcLevel, dateVal, sensor_id)
          sqlUpdateFile.write(sql+"\n")
          row = dbCursor.fetchone()
                      
      logger.debug( "End processing rows" )
      #Keep a running count of the total number of rows processed.    
      totalRows += rowCnt
      qcTotalFailCnt += qcFailCnt
      qcTotalMissingLimitsCnt += qcMissingLimitsCnt
      
      if( sys.platform == 'win32'):
        processingEnd = time.clock()
      else:
        processingEnd = time.time()
      if( logger != None ):
        logger.info( "Platform stats-----------------------------------------------------------------------------" )
        logger.info( "%s getObsDataForPlatform QAQC Proc'd: %d rows in time: %f(ms)" %(platformKey, rowCnt, ((processingEnd-processingStart)*1000.0 )) )
        logger.info( "%s QAQC suspect or bad count: %d QAQC no limits count: %d" %(platformKey,qcFailCnt,qcMissingLimitsCnt) )
                
    if( sys.platform == 'win32'):
      endProcess = time.clock()
    else:
      endProcess = time.time()

    if( logger != None ):
      logger.info( "Final stats=============================================================================" )
      logger.info( "%d rows processed in %f(ms)" %(totalRows,((endProcess-startProcess)*1000.0 )) )
      logger.info( "Total QAQC not good count: %d Total QAQC no limits count: %d" %(qcTotalFailCnt,qcTotalMissingLimitsCnt) )
      logger.info( "Closing log file." )
        
    sqlUpdateFile.close()      

      
  except IOError, e:
    import traceback
    
    errMsg = "ERROR Terminating script." 
    if( logger != None ):
      logger.error(errMsg, exc_info=1)
    else:
      print( traceback.print_exc() )

  except Exception, e:
    import traceback
   
    errMsg = "ERROR Terminating script." 
    if( logger != None ):
      logger.error(errMsg, exc_info=1)
    else:
      print( traceback.print_exc() )



