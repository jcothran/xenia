import sys
import array
from xenia import xeniaDB
from lxml import etree


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

class obsInfo:
  def __init__(self, obsName):
    self.obsName        = obsName
    self.uom            = None
    self.updateInterval = None
    self.sensorRangeLo  = None
    self.sensorRangeHi  = None
    self.grossRangeLo   = None
    self.grossRangeHi   = None
    self.climateRangeLo = None
    self.climateRangeHi = None
    
    
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
    self.lowerRange = None
    self.upperRange = None
    self.testType   = None
    self.observation = obsName
  
  def setRanges(self, lowerRange, upperRange, testType = None ):
    self.lowerRange = lowerRange
    self.upperRange = upperRange
    self.testType   = testType
    
    
  def rangeTest(self, value):
    if( self.lowerRange != None and self.upperRange != None ):
      if( value != None ):
        if( value < self.lowerRange or value > self.upperRange ):
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
  
  def runRangeTests(self, obsNfo, value):
    if(value != None):
      self.dataAvailable = qaqcTestFlags.TEST_PASSED
      if( obsNfo.sensorRangeLo != None and obsNfo.sensorRangeHi ):
        self.rangeCheck.setRanges( obsNfo.sensorRangeLo,obsNfo.sensorRangeHi )
        self.sensorRangeCheck = self.rangeCheck.rangeTest( value )
        #If we don't pass the sensor range check, do not run any other tests.
        if( self.sensorRangeCheck == qaqcTestFlags.TEST_PASSED ):        
          if( obsNfo.grossRangeLo != None and obsNfo.grossRangeHi ):
            self.rangeCheck.setRanges( obsNfo.grossRangeLo,obsNfo.grossRangeHi )
            self.grossRangeCheck = self.rangeCheck.rangeTest( value )
          if( obsNfo.climateRangeLo != None and obsNfo.climateRangeHi ):
            self.rangeCheck.setRanges( obsNfo.climateRangeLo,obsNfo.climateRangeLo )
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
              interval  = obs.xpath('UpdateInterval' )
              if( len(interval) ):
                obsSettings.updateInterval = int(interval[0].text)            
              hi  = obs.xpath('rangeHigh' )
              if( len(hi) ):
                obsSettings.sensorRangeHi = float(hi[0].text)            
              lo  = obs.xpath('rangeLow' )
              if( len(lo) ):
                obsSettings.sensorRangeLo = float(lo[0].text)             
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
      
  settings = loadSettings(  )
  platformInfoDict = settings.loadFromTestProfilesXML(sys.argv[1])
  db = xeniaDB()
  db.openXeniaSQLite( "C:\Program Files\sqlite-3_5_6\microwfs\microwfs.db" )
  
  sqlUpdateFile = open( "C:\Program Files\sqlite-3_5_6\microwfs\sql_qc_update.sql", "w" )
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
          #the qc_flag in the database is a string. We've defined a character array to represent each type of test, so
          #here we fill up the array with 0s to begin with, then per array ndx set the test results.
          qcFlag = array.array('c')
          fill = ''       
          fill = fill.zfill(qaqcTestFlags.TQFLAG_NN+1)   
          qcFlag.fromstring(fill)
          #m_value = None
          dataTests.runRangeTests(obsNfo, m_value)
          
          qcFlag[qaqcTestFlags.TQFLAG_DA] = ( "%d" % dataTests.dataAvailable )
          qcFlag[qaqcTestFlags.TQFLAG_SR] = ( "%d" % dataTests.sensorRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_GR] = ( "%d" % dataTests.grossRangeCheck )
          qcFlag[qaqcTestFlags.TQFLAG_CR] = ( "%d" % dataTests.climateRangeCheck )
          qcLevel = dataTests.calcQCLevel()
          sql = "UPDATE multi_obs SET \
                  qc_flag='%s',qc_level=%d WHERE \
                  m_date='%s' AND sensor_id=%d" \
                  %(qcFlag.tostring(), qcLevel, date, sensor_id)
          sqlUpdateFile.write(sql+"\n")
          #print( "%s Platform: %s obsName: %s value: %f TestFlag: %d" % (date, platformKey, obsName, m_value, retVal))
        else:
          print( "\n%s ERROR: No limit set for Platform: %s obsName: %s\n" % (date, platformKey,obsName) )
  sqlUpdateFile.close()        
