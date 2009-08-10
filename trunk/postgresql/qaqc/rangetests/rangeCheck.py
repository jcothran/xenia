import sys
import array
import time
#from xenia import xeniaDB
#from xenia import xeniaSQLite
#from xenia import xeniaPostGres
#from xenia import qaqcTestFlags
#rom xenia import uomconversionFunctions
#from xenia import recursivedefaultdict

from xeniatools.xenia import xeniaSQLite
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import qaqcTestFlags
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict

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
                for i in range( 1,12 ):
                  obsSettings.climateRangeLimits[i] = limits
                  
              #Now add the observation to our platform info dictionary.
              platformNfo = platformInfoDict[platformHandle]
              platformNfo.addObsInfo(obsSettings)
        
      return( platformInfoDict )
    except Exception, e:
      print( 'ERROR: ' + str(e)  + ' Terminating script')
    
class platformResultsTable(object):
  def __init__(self):
    self.table = None
    self.platforms = recursivedefaultdict()
  
  def clear(self):
    self.platforms.clear()
    
  def createHTMLTable(self):
    htmlTable = ''
    try:
      platformKeys = self.platforms.keys()
      platformKeys.sort() 
      #for platformKey in self.platforms.keys():
      for platformKey in platformKeys:    
        if( len(htmlTable) ):
          htmlTable += "<br>"
        htmlTable += "<table border=\"1\">\n"
        #We want to sort the dates
        dateKeys = self.platforms[platformKey].keys()
        dateKeys.sort()
        writeHeader = True
        tableHeader = '<th>Platform</th><th>Date</th><th>Value Labels</th>'
        for dateKey in dateKeys: 
          valuesLabel = "Value</br>QC Flag</br>QC Level"
          tableRow = "<tr>\n<td>%s</td><td>%s</td><td NOWRAP>%s</td>\n" %( platformKey, dateKey, valuesLabel )
          obsKeys = self.platforms[platformKey][dateKey].keys()
          obsKeys.sort()
          for obsKey in obsKeys:
          #for obsKey in self.platforms[platformKey][dateKey]:
            if( writeHeader ):
              if( 'limits' in self.platforms[platformKey][dateKey][obsKey] != False ):
                obsNfo = self.platforms[platformKey][dateKey][obsKey]['limits']
                if( obsNfo != None ):
                  tableHeader += "<th>%s(%s)</th>" %( obsKey, ( ( obsNfo.uom != None ) and obsNfo.uom or '' ) )
                else:
                  tableHeader += "<th>%s()</th>" %( obsKey )
              else:
                tableHeader += "<th>%s()</th>" %( obsKey )
                
            qcLevel = self.platforms[platformKey][dateKey][obsKey]['qclevel']
  
            #The cell background colors are defined in the style sheet(http://carocoops.org/~dramage_prod/secoora/styles/main.css)
            bgColor = "qcDEFAULT"
            if( qcLevel == qaqcTestFlags.NO_DATA):
              bgColor = "qcMISSING"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_NO_EVAL):
              bgColor = "qcNOEVAL"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_BAD):
              bgColor = "qcFAIL"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_SUSPECT):
              bgColor = "qcSUSPECT"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_GOOD):
              bgColor = "qcPASS"
            if( qcLevel != qaqcTestFlags.NO_DATA ):
              tableRow += "<td id=\"%s\">%4.2f</br>%d</br>%s</td>\n" \
              % (bgColor,
                 ( self.platforms[platformKey][dateKey][obsKey]['value'] != None ) and self.platforms[platformKey][dateKey][obsKey]['value'] or -9999.0,
                 ( self.platforms[platformKey][dateKey][obsKey]['qclevel'] != None ) and self.platforms[platformKey][dateKey][obsKey]['qclevel'] or -9999.0,
                 ( self.platforms[platformKey][dateKey][obsKey]['qcflag'] != None ) and self.platforms[platformKey][dateKey][obsKey]['qcflag'] or -9999.0 )
            else:
              tableRow += "<td id=\"%s\">Data Missing</br>%d</br>000000</td></td>\n" % (bgColor,qaqcTestFlags.NO_DATA)
          tableRow += "</tr>\n"
          if( writeHeader ):
            htmlTable += tableHeader
            writeHeader = False          
          htmlTable += tableRow
        htmlTable += '</table>'
    except Exception, e:
        self.lastErrorMessage = str(e) + ' Terminating script.'

    if( len(htmlTable) == 0 ):
      htmlTable = None
    return( htmlTable )
        
  def addObsQC(self, platform, obsName, date, value, qcLevel, qcFlag, qcLimits=None ):
    self.platforms[platform][date][obsName]['value'] = value
    self.platforms[platform][date][obsName]['qclevel'] = qcLevel
    self.platforms[platform][date][obsName]['qcflag'] = qcFlag
    if( qcLimits != None ):
      self.platforms[platform][date][obsName]['limits'] = qcLimits
    
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
        xmlTag = time.strftime(xmlTag, time.gmtime())        
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
  
  #Are we writing out an HTML file showing the results of the range tests?
  htmlResultsFile = None
  xmlTag = xmlTree.xpath( '//environment/outputs/qcResultsTable/file' )
  if(len(xmlTag) ):    
    htmlResultsFile = open( xmlTag[0].text, 'w' )
    xmlTag = xmlTree.xpath( '//environment/outputs/qcResultsTable/styleSheet' )    
    if( len(xmlTag) ):  
      styleSheet = xmlTag[0].text
    if( styleSheet == None ):
      styleSheet = 'http://carocoops.org/~dramage_prod/styles/main.css'

    htmlResultsFile.write( "<html>\n" )
    htmlResultsFile.write( "<BODY id=\"RGB_BODY_BG\" >\n" )    
    htmlResultsFile.write( "<link href=\"%s\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n"  % ( styleSheet ) )
  
  #rangeCheck = obsRangeCheck( '' )
  htmlTable = platformResultsTable()
  try:
    for platformKey in platformInfoDict.keys():
      platformNfo = platformInfoDict[platformKey]
      startTime = 0;
      
      if( sys.platform == 'win32'):
        processingStart = time.clock()
      else:
        processingStart = time.time()            
      
      dbCursor = db.getObsDataForPlatform( platformKey, 168 )
      
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
      #for row in dbCursor:
      """
      if( sys.platform == 'win32'):
        startFetch = time.clock()
      else:
        startFetch = time.time()
      """
      row = dbCursor.fetchone()
      """
      if( sys.platform == 'win32'):
        endFetch = time.clock()
      else:
        endFetch = time.time()
      logger.debug( "%s row fetch time: %f(ms)" %(platformKey, (endFetch-startFetch)*1000.0 ) )
      """
      lastDate = None
      while( row != None ):
        """
        if( sys.platform == 'win32'):
          rowStart = time.clock()
        else:
          rowStart = time.time()
        """            
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
            if( htmlResultsFile != None ):
              #Prime the table with all the obs we should have.
              for name in platformNfo.obsList.keys():
                nfo = platformNfo.getObsInfo(name)
                htmlTable.addObsQC(platformKey, name, dateVal, None, qaqcTestFlags.NO_DATA, None, nfo)            
                #logger.debug( "platform: %s obsName: %s date: %s %s %s" \
                #       % (platformKey,name,dateVal,nfo.obsName,nfo.uom ) )          
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
          
          if( htmlResultsFile != None ):
            htmlTable.addObsQC(platformKey, obsName, dateVal, m_value, qcLevel, qcFlag.tostring(), obsNfo)
                              
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
      
    if( htmlResultsFile != None ):
      htmlResults = htmlTable.createHTMLTable()
      if( htmlResults != None ):
        htmlResultsFile.writelines( htmlResults )
        htmlResultsFile.write( '<br>' )
        htmlResultsFile.flush()
        htmlTable.clear()
        logger.info( "Creating HTML Results Table: %s" % ( htmlResultsFile.name ) )
      else:
        logger.info( "No results to create HTML Table."  )
          
    if( sys.platform == 'win32'):
      endProcess = time.clock()
    else:
      endProcess = time.time()

    if( logger != None ):
      logger.info( "Final stats-----------------------------------------------------------------------------" )
      logger.info( "%d rows processed in %f(ms)" %(totalRows,((endProcess-startProcess)*1000.0 )) )
      logger.info( "Total QAQC not good count: %d Total QAQC no limits count: %d" %(qcTotalFailCnt,qcTotalMissingLimitsCnt) )
      logger.info( "Closing log file." )
        
    sqlUpdateFile.close()      
    if( htmlResultsFile != None ):
      htmlResultsFile.write( "</BODY>\n" )    
      htmlResultsFile.write( "</html>\n" )    
      htmlResultsFile.close()  
      
  except IOError, e:
   if( logger != None ):
      logger.error( str(e) + ' Terminating script.' )
  except Exception, e:
   if( logger != None ):
      logger.error( str(e) + ' Terminating script.' )

