import sys
import array
import time
from xenia import xeniaDB
from lxml import etree

class uomconversionFunctions:
  def __init__(self, xmlConversionFile):
    self.xmlConversionFile = xmlConversionFile
  def measurementConvert(self, value, fromUOM, toUOM):
    xmlTree = etree.parse(self.xmlConversionFile)
    
    convertedVal = ''
    xmlTag = "//unit_conversion_list/unit_conversion[@id=\"%s_to_%s\"]/conversion_formula" % (fromUOM, toUOM)
    unitConversion = xmlTree.xpath(xmlTag)
    if( len(unitConversion) ):     
      conversionString = unitConversion[0].text
      conversionString = conversionString.replace( "var1", ("%f" % value) )
      convertedVal = float(eval( conversionString ))
      return(convertedVal)
    return(None)
    
class qaqcTestFlags:

  TQFLAG_DA = 0   #Data Availability               
  TQFLAG_SR = 1   #Sensor Range
  TQFLAG_GR = 2   #Gross Range
  TQFLAG_CR = 3   #Climatological Range
  TQFLAG_RC = 4  #Rate of Change
  TQFLAG_NN = 5  #Nearest Neighbor

  NO_TEST      = 0 # -1 in writeup Unable to perform the test  
  TEST_FAILED  = 1 # 0 in writeup The test failed.
  TEST_PASSED  = 2 #1 in writeup The test passed.
  
  
  NO_DATA           = -9 #the data field is missing a value
  DATA_QUAL_NO_EVAL = 0  #the data quality is not evaluated
  DATA_QUAL_BAD     = 1  #the data quality is bad
  DATA_QUAL_SUSPECT = 2  #the data quality is questionable or suspect
  DATA_QUAL_GOOD    = 3  #the data quality is good

class rangeLimits:
  def __init__(self):
    self.rangeLo = None
    self.rangeHi = None
    
class obsInfo:
  def __init__(self, obsName):
    self.obsName        = obsName
    self.uom            = None
    self.updateInterval = None
    self.sensorRangeLimits = rangeLimits()
    self.grossRangeLimits = rangeLimits()
    self.climateRangeLimits = {} 
    
    
class platformInfo:
  def __init__(self,platform):
    self.platformHandle = platform
    self.obsList = {}
  def addObsInfo(self, obsInfo):
    self.obsList[obsInfo.obsName] = obsInfo
    
  def getObsInfo(self, obsName):
    if( obsName in self.obsList != False ):
      return( self.obsList[obsName] )
    return( None )
  
class obsRangeCheck:
  def __init__(self, obsName ='' ):
    self.limits = rangeLimits()
    self.testType   = None
    self.observation = obsName
  
  def setRanges(self, lowerRange, upperRange, testType = None ):
    self.limits.rangeLo = lowerRange
    self.limits.rangeHi = upperRange
    self.testType       = testType
    
    
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

class qcTestSuite:
  def __init__(self):
    self.dataAvailable      = qaqcTestFlags.NO_TEST  
    self.grossRangeCheck    = qaqcTestFlags.NO_TEST  
    self.sensorRangeCheck   = qaqcTestFlags.NO_TEST  
    self.climateRangeCheck  = qaqcTestFlags.NO_TEST
    self.rateofchangeCheck  = qaqcTestFlags.NO_TEST
    self.nearneighborCheck  = qaqcTestFlags.NO_TEST
    self.rangeCheck         = obsRangeCheck()
    self.qcFlag             = qaqcTestFlags.DATA_QUAL_NO_EVAL
  
  def runRangeTests(self, obsNfo, value, month = 0):
    if(value != None):
      self.dataAvailable = qaqcTestFlags.TEST_PASSED
      if( obsNfo.sensorRangeLimits.rangeLo != None and obsNfo.sensorRangeLimits.rangeHi ):
        self.rangeCheck.setRanges( obsNfo.sensorRangeLimits.rangeLo,obsNfo.sensorRangeLimits.rangeHi )
        self.sensorRangeCheck = self.rangeCheck.rangeTest( value )
        #If we don't pass the sensor range check, do not run any other tests.
        if( self.sensorRangeCheck == qaqcTestFlags.TEST_PASSED ):    
          #Run the gross range checks if we have limits.    
          if( obsNfo.grossRangeLimits.rangeLo != None and obsNfo.grossRangeLimits.rangeHi != None ):
            self.rangeCheck.setRanges( obsNfo.grossRangeLimits.rangeLo,obsNfo.grossRangeLimits.rangeHi )
            self.grossRangeCheck = self.rangeCheck.rangeTest( value )
          #Run the climatalogical range checks if we have limits.    
          if( len(obsNfo.climateRangeLimits) and month != 0 ):
            limits = obsNfo.climateRangeLimits[month]
            self.rangeCheck.setRanges( limits.rangeLo,limits.rangeHi )
            self.climateRangeCheck = self.rangeCheck.rangeTest( value )
    else:
      self.dataAvailable      = qaqcTestFlags.TEST_FAILED  

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
class loadSettings:
    
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
    

if __name__ == '__main__':
  if( len(sys.argv) < 2 ):
    print( "Usage: rangeCheck.py xmlconfigfile")
    sys.exit(-1)    
  

  #Get the various settings we need from out xml config file.
  xmlTree = etree.parse(sys.argv[1])

  #Get the settings for how the qc Limits are stored so we know how to process them.
  settings = loadSettings()
  if(len(xmlTree.xpath( '//environment/qcLimits/fileType' ))):
    xmlTag = xmlTree.xpath( '//environment/qcLimits/fileType' )[0].text
    if( xmlTag == 'test_profiles' ):
      if( len(xmlTree.xpath( '//environment/qcLimits/file' )) ):
        xmlTag = xmlTree.xpath( '//environment/qcLimits/file' )[0].text
        platformInfoDict = settings.loadFromTestProfilesXML(xmlTag)
      else:
        print( "ERROR: No QC Limits provided." )
        sys.exit(-1)
  else:
    print( "ERROR: No QC Limits type specified." )
    sys.exit(-1)

  db = xeniaDB()
  if(len(xmlTree.xpath( '//environment/database/db/name' ))):
    xmlTag = xmlTree.xpath( '//environment/database/db/name' )[0].text
    db.openXeniaSQLite( xmlTag )
  else:
    print( "ERROR: No Xenia database provided." )
    sys.exit(-1)
  
  if(len(xmlTree.xpath( '//environment/database/sqlQCUpdateFile' ))):
    xmlTag = xmlTree.xpath( '//environment/database/sqlQCUpdateFile' )[0].text
    sqlUpdateFile = open( "C:\Program Files\sqlite-3_5_6\microwfs\sql_qc_update.sql", "w" )
  else:
    print( "ERROR: No SQL update filename provided." )
    sys.exit(-1)
    
  #rangeCheck = obsRangeCheck( '' )
  for platformKey in platformInfoDict.keys():
    platformNfo = platformInfoDict[platformKey]
    dbCursor = db.getObsDataForPlatform( platformKey, -12 )
    for row in dbCursor:
      dataTests = qcTestSuite()
      if( row['standard_name'] != None ):
        obsName   = row['standard_name']
        
        date = None
        if( row['m_date'] != None ):
          date = row['m_date']
          
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
        if( row['row_id'] != None ):
          sensor_id = int(row['row_id'])
          
        s_order = -1
        if( row['s_order'] != None ):
          s_order   = int(row['s_order'])

        obsNfo = platformNfo.getObsInfo(obsName)
        if( obsNfo != None ):
          #Check to see if the units of measurement for the limits is the same for the data, if not we'll get our conversion factor.
          if( uom != obsNfo.uom ):
            uomConvert = uomconversionFunctions("C:\Documents and Settings\dramage\workspace\QAQC-ControlChart\UnitsConversionPython.xml")
            convertedVal = uomConvert.measurementConvert( m_value, obsNfo.uom, uom)
            if(convertedVal != None ):
              m_value = convertedVal
          #the qc_flag in the database is a string. We've defined a character array to represent each type of test, so
          #here we fill up the array with 0s to begin with, then per array ndx set the test results.
          qcFlag = array.array('c')
          fill = ''       
          fill = fill.zfill(qaqcTestFlags.TQFLAG_NN+1)   
          qcFlag.fromstring(fill)
          #m_value = None
          month = int(time.strftime( "%m", time.strptime(date, "%Y-%m-%dT%H:%M:%S") ))
          dataTests.runRangeTests(obsNfo, m_value, month)
          
          #The qcFlag string is interpretted as follows. The leftmost byte is the first test, which is the data available test,
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
          if( qcLevel != qaqcTestFlags.DATA_QUAL_GOOD ):
            print( "%s Platform: %s obsName: %s value: %f qcFlag: %s qcLevel: %d" % (date, platformKey, obsName, m_value, qcFlag.tostring(), qcLevel))
          sql = "UPDATE multi_obs SET \
                  qc_flag='%s',qc_level=%d WHERE \
                  m_date='%s' AND sensor_id=%d" \
                  %(qcFlag.tostring(), qcLevel, date, sensor_id)
          sqlUpdateFile.write(sql+"\n")
          #print( "%s Platform: %s obsName: %s value: %f TestFlag: %d" % (date, platformKey, obsName, m_value, retVal))
        else:
          print( "\n%s ERROR: No limit set for Platform: %s obsName: %s\n" % (date, platformKey,obsName) )
  sqlUpdateFile.close()        
