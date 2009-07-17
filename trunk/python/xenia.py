#import time
from pysqlite2 import dbapi2 as sqlite3      
import psycopg2
import psycopg2.extras
from lxml import etree
from collections import defaultdict  


class recursivedefaultdict(defaultdict):
    def __init__(self):
        self.default_factory = type(self) 

class dbTypes:
  undefined = 0
  SQLite = 1
  PostGRES = 2
"""
Class: qaqcTestFlags
Purpose: This is more of an enumeration class that details out the various quality flags.
"""    
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
  
  def decodeQCFlag(self, qcFlag):
    qcFlagList = []
    qcFlagList.append( 'Data available ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_DA]) ) )
    qcFlagList.append( 'Sensor Range ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_SR]) ) )
    qcFlagList.append( 'Gross Range ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_GR]) ) )
    qcFlagList.append( 'Climatological Range ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_CR]) ) )
    qcFlagList.append( 'Rate of Change ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_RC]) ) )
    qcFlagList.append( 'Nearest Neighbor ' + self.decodeQCFlagData( int(qcFlag[qaqcTestFlags.TQFLAG_NN]) ) )
    return( qcFlagList )

  def decodeQCFlagData(self, qcTestResult):
    if( qcTestResult == qaqcTestFlags.TEST_PASSED ):
      return( 'Test passed' )
    elif( qcTestResult == qaqcTestFlags.TEST_FAILED ):
      return( 'Test failed' )
    else:
      return( 'Test not performed' )

  def decodeQCLevel(self, qcLevel):
    if( qcLevel == qaqcTestFlags.NO_DATA ):
      return( 'No data' )
    elif( qcLevel == qaqcTestFlags.DATA_QUAL_NO_EVAL ):
      return( 'Data quality not evaluated' )
    elif( qcLevel == qaqcTestFlags.DATA_QUAL_BAD ):
      return( 'Data quality bad' )
    elif( qcLevel == qaqcTestFlags.DATA_QUAL_SUSPECT ):
      return( 'Data quality suspect' )
    elif( qcLevel == qaqcTestFlags.DATA_QUAL_GOOD ):
      return( 'Data quality good' )

    
class xeniaDB:
    def __init__ ( self ):
      self.dbType = dbTypes.undefined
      self.lastErrorMsg = ''
    
    def getLastErrorMsg(self):
      msg = self.lastErrorMsg
      self.lastErrorMsg = ''
      return(msg)  
     
    def connectDB(self, dbFilePath=None, user=None, passwd=None, host=None, dbName=None ):
      return(False)

    def openXeniaSQLite(self, dbFilePath ):
      self.dbFilePath = dbFilePath
      self.dbType = dbTypes.SQLite
      try:
        self.DB = sqlite3.connect( self.dbFilePath )
        #This enables the ability to manipulate rows with the column name instead of an index.
        self.DB.row_factory = sqlite3.Row
        return(True)
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      return(False)
      
    def openXeniaPostGres( self, host, dbName, user, passwd ):
      self.dbType = dbTypes.PostGRES
      try:
        self.DB = psycopg2.connect( "dbname='%s' user='%s' password='%s'" % ( dbName,user,passwd) )
        return(True)       
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      return(False)

    def executeQuery(self, sqlQuery):
      
      if( self.dbType == dbTypes.SQLite ):
        dbCursor = self.DB.cursor()
      
      elif( self.dbType == dbTypes.PostGRES ):
        dbCursor = self.DB.cursor(cursor_factory=psycopg2.extras.DictCursor)
        
      dbCursor.execute( sqlQuery )        
      return( dbCursor )
    
    def getMTypeFromObsName(self, obsName, platform, sOrder ):
      mType = -1
      sOrder = '';
      if( len( sOrder ) ):
        sOrder = "sensor.s_order = $iSOrder AND"
        
      sql = "SELECT DISTINCT(sensor.m_type_id) FROM m_type, m_scalar_type, obs_type, sensor, platform \
                WHERE  sensor.m_type_id = m_type.row_id AND                                           \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND                                    \
                obs_type.row_id = m_scalar_type.obs_type_id AND                                       \
                platform.row_id = sensor.platform_id AND                                              \
                %s                                                                            \
                obs_type.standard_name = '%s' AND                                                     \
                platform.platform_handle = '%s';" % (sOrder,obsName,platform )
      try:                               
        dbCursor = self.executeQuery( sql )
        for row in dbCursor:
          mType  = row[0]
        dbCursor.close()
      
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      
      return( mType )
    
    def getSensorID(self, obsName, platform, sOrder ):
      sensorID = -1
      sOrder = '';
      if( len( sOrder ) ):
        sOrder = "sensor.s_order = $iSOrder AND"
        
      sql = "SELECT sensor.row_id FROM m_type, m_scalar_type, obs_type, sensor, platform \
                WHERE  sensor.m_type_id = m_type.row_id AND                                           \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND                                    \
                obs_type.row_id = m_scalar_type.obs_type_id AND                                       \
                platform.row_id = sensor.platform_id AND                                              \
                %s                                                                            \
                obs_type.standard_name = '%s' AND                                                     \
                platform.platform_handle = '%s';" % (sOrder,obsName,platform )
      try:                               
        dbCursor = self.executeQuery( sql )
        row = dbCursor.fetchone()
        if( row != None ):
          sensorID  = int(row[0])
        dbCursor.close()
      
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      return( sensorID )
    
    def getDataForSensorID(self,sensorID, startDate, endDate, timeZoneShift):
      data = []
      if(self.dbType == dbTypes.SQLite):
        sql = "SELECT multi_obs.m_date,multi_obs.m_value        \
                      FROM multi_obs           \
                      WHERE                    \
                      multi_obs.sensor_id = %d                              AND   \
                      ( m_date >= strftime( '%%Y-%%m-%%dT%%H:00:00',datetime('%s','%d hours') )   AND  \
                      m_date < strftime( '%%Y-%%m-%%dT%%H:00:00', datetime('%s','%d hours') ) ) \
                      ORDER BY multi_obs.m_date ASC;" % ( sensorID, startDate, timeZoneShift, endDate, timeZoneShift );                
      try:                      
        dbCursor = self.executeQuery( sql )
        for row in dbCursor:
          data.append( (row[0],row[1]) )       
        dbCursor.close()
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      
      return( data )
      
    
    def getObservationDates(self, obsName, platform ):
      dates = []
      sensorID = self.getSensorID(obsName, platform, '')     
      if(sensorID != -1):
        sql = "SELECT DISTINCT(strftime( '%%Y-%%m-%%d', datetime(m_date))), m_type_id,platform_handle FROM multi_obs \
              WHERE multi_obs.sensor_id = %d \
              ORDER BY m_date ASC;" % ( sensorID )
      try:              
        dbCursor = self.executeQuery( sql )
        for row in dbCursor:
          dates.append( row[0] )
        dbCursor.close()
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
                     
      return( dates )
    
   
    def getObservationsForPlatform(self, platform):
      obsList = {}
      """
      SELECT platform.platform_handle,obs_type.standard_name,obs_type.row_id,sensor.platform_id FROM  platform 
                      LEFT JOIN sensor on sensor.platform_id = platform.row_id 
                      LEFT JOIN m_type on sensor.m_type_id= m_type.row_id
                     LEFT JOIN m_scalar_type on m_type.m_scalar_type_id=m_scalar_type.row_id
                     LEFT JOIN uom_type on m_scalar_type.uom_type_id=uom_type.row_id
                     LEFT JOIN obs_type on m_scalar_type.obs_type_id=obs_type.row_id
                    WHERE 
                      platform.platform_handle = 'carocoops.SUN2.buoy'       
      """
      sql = "SELECT obs_type.standard_name,obs_type.row_id,sensor.platform_id FROM obs_type, m_type, m_scalar_type, sensor, platform \
              WHERE \
                obs_type.row_id = m_scalar_type.obs_type_id AND \
                sensor.m_type_id = m_type.row_id AND             \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND \
                platform.platform_handle = '%s'" % platform;
      try:
        dbCursor = self.executeQuery( sql )
        row = dbCursor.fetchone()
        #for row in dbCursor:
        while( row != None ):
          obsList[ row['standard_name'] ] = row['row_id']  
          row = dbCursor.fetchone()
        dbCursor.close()
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      
      return( obsList )
    
    def getDataForObs(self, obsName, platform, startDate, endDate, timeZoneShift):
      data = {}
      #mType = self.getMTypeFromObsName( obsName, platform, '' )
      sensorID = self.getSensorID(obsName, platform, '')     
      if(sensorID != -1):
        data = self.getDataForSensorID( sensorID,startDate,endDate,timeZoneShift)        
      return( data)
 
    def getObsDataForPlatform(self, platform, lastNHours = None ):      
      
      #Do we want to query from a datetime of now back lastNHours?
      dateOffset = ''
      if( lastNHours != None ):
        if( self.dbType == dbTypes.SQLite ):
          dateOffset = "m_date > strftime('%%Y-%%m-%%dT%%H:%%M:%%S', 'now','-%d hours') AND" % (lastNHours)
        elif( self.dbType == dbTypes.PostGRES ):
          dateOffset = "m_date > ( now() - interval '%d hours' ) AND" % (lastNHours)
          
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
            WHERE %s multi_obs.platform_handle = '%s' AND qc_level IS NULL AND sensor.row_id IS NOT NULL\
            ORDER BY m_date DESC" \
            % (dateOffset,platform)
      try:
        dbCursor = self.executeQuery( sql )       
        return( dbCursor )
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
        
      return(None)
    
class __xeniaDB:
    """
    Function: __init__
    Purpose: Initializes the class
    Parameters: None
    Return: None
    """
    def __init__ ( self ):
      self.dbType = dbTypes.undefined
      self.lastErrorMsg = ''
      self.lastErrorCode = None
      self.DB = None
      
    """
    Function: getLastErrorMsg
    Purpose: Returns the last error message
    Parameters: None
    Return: String with the last error message.
    """
    def getLastErrorMsg(self):
      msg = self.lastErrorMsg
      self.lastErrorMsg = ''
      return(msg)  
     
    """
    Function: connect
    Purpose: Children classes should overload this function to provide the DB specific connection.
    Parameters: 
    Return: 
    """
    def connect(self, dbFilePath=None, user=None, passwd=None, host=None, dbName=None ):
      return(False)
   
    def getMTypeFromObsName(self, obsName, platform, sOrder ):
      mType = -1
      sOrder = '';
      if( len( sOrder ) ):
        sOrder = "sensor.s_order = $iSOrder AND"
        
      sql = "SELECT DISTINCT(sensor.m_type_id) FROM m_type, m_scalar_type, obs_type, sensor, platform \
                WHERE  sensor.m_type_id = m_type.row_id AND                                           \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND                                    \
                obs_type.row_id = m_scalar_type.obs_type_id AND                                       \
                platform.row_id = sensor.platform_id AND                                              \
                %s                                                                            \
                obs_type.standard_name = '%s' AND                                                     \
                platform.platform_handle = '%s';" % (sOrder,obsName,platform )
      try:                               
        dbCursor = self.executeQuery( sql )
        for row in dbCursor:
          mType  = row[0]
        dbCursor.close()
      
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      
      return( mType )
    
    def getSensorID(self, obsName, platform, sOrder ):
      sensorID = -1
      sOrder = '';
      if( len( sOrder ) ):
        sOrder = "sensor.s_order = $iSOrder AND"
        
      sql = "SELECT sensor.row_id FROM m_type, m_scalar_type, obs_type, sensor, platform \
                WHERE  sensor.m_type_id = m_type.row_id AND                                           \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND                                    \
                obs_type.row_id = m_scalar_type.obs_type_id AND                                       \
                platform.row_id = sensor.platform_id AND                                              \
                %s                                                                            \
                obs_type.standard_name = '%s' AND                                                     \
                platform.platform_handle = '%s';" % (sOrder,obsName,platform )
      try:                               
        dbCursor = self.executeQuery( sql )
        row = dbCursor.fetchone()
        if( row != None ):
          sensorID  = int(row[0])
        dbCursor.close()
      
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
      except Exception, E:
        self.lastErrorMsg = str(E)                     
      return( sensorID )
    
    def getDataForSensorID(self,sensorID, startDate, endDate, timeZoneShift):
      return(None)     
    def getObservationDates(self, obsName, platform ):
      return(None)       
    def getObservationsForPlatform(self, platform):
      return(None)      
    def getDataForObs(self, obsName, platform, startDate, endDate, timeZoneShift):
      return(None)
    def getObsDataForPlatform(self, platform, lastNHours = None ):                 
      return(None)

class xeniaSQLite(__xeniaDB):
  """
  Function: __init__
  Purpose: Initializes the class
  Parameters: None
  Return: None
  """
  def __init__(self):
    self.dbType = dbTypes.SQLite

  """
  Function: connect
  Purpose: Make a connection to the database
  Parameters: 
    dbFilePath is the path to the sqlite database to use.
    user not used
    passwd not used
    host not used
    dbName not used
  Return: 
    True if we successfully connected, otherwise false. Any error info
    is stored in  self.lastErrorMsg
  """
  def connect(self, dbFilePath=None, user=None, passwd=None, host=None, dbName=None ):
    self.dbFilePath = dbFilePath
    try:
      self.DB = sqlite3.connect( self.dbFilePath )
      #This enables the ability to manipulate rows with the column name instead of an index.
      self.DB.row_factory = sqlite3.Row
      return(True)
    except Exception, E:
      self.lastErrorMsg = str(E)                     
    return(False)

  """
  Function: executeQuery
  Purpose: Executes the sql statement passed in.
  Parameters: 
    sqlQuery is a string containing the query to execute.
  Return: 
    If successfull, a cursor is returned, otherwise None is returned.
  """
  def executeQuery(self, sqlQuery):   
    try:
      dbCursor = self.DB.cursor()
      dbCursor.execute( sqlQuery )        
      return( dbCursor )
    except sqlite3.Error, e:        
      self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sqlQuery        
    except Exception, E:
      self.lastErrorMsg = str(E)                     
    return(None)

  def getDataForSensorID(self,sensorID, startDate, endDate, timeZoneShift):
    data = []
    sql = "SELECT multi_obs.m_date,multi_obs.m_value        \
                  FROM multi_obs           \
                  WHERE                    \
                  multi_obs.sensor_id = %d                              AND   \
                  ( m_date >= strftime( '%%Y-%%m-%%dT%%H:00:00',datetime('%s','%d hours') )   AND  \
                  m_date < strftime( '%%Y-%%m-%%dT%%H:00:00', datetime('%s','%d hours') ) ) \
                  ORDER BY multi_obs.m_date ASC;" % ( sensorID, startDate, timeZoneShift, endDate, timeZoneShift );                
    try:                      
      dbCursor = self.executeQuery( sql )
      for row in dbCursor:
        data.append( (row[0],row[1]) )       
      dbCursor.close()
    except sqlite3.Error, e:        
      self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
    except Exception, E:
      self.lastErrorMsg = str(E)                     

  def getObsDataForPlatform(self, platform, lastNHours = None ):      
    
    #Do we want to query from a datetime of now back lastNHours?
    dateOffset = ''
    if( lastNHours != None ):
      dateOffset = "m_date > strftime('%%Y-%%m-%%dT%%H:%%M:%%S', 'now','-%d hours') AND" % (lastNHours)
        
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
          WHERE %s multi_obs.platform_handle = '%s' AND qc_level IS NULL AND sensor.row_id IS NOT NULL\
          ORDER BY m_date DESC" \
          % (dateOffset,platform)
    try:
      dbCursor = self.executeQuery( sql )       
      return( dbCursor )
    except sqlite3.Error, e:        
      self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sql        
    except Exception, E:
      self.lastErrorMsg = str(E)                           
    return(None)


class xeniaPostGres(__xeniaDB):
  """
  Function: __init__
  Purpose: Initializes the class
  Parameters: None
  Return: None
  """
  def __init__(self):
    self.dbType = dbTypes.PostGRES

  """
  Function: connect
  Purpose: Make a connection to the database
  Parameters: 
    dbFilePath is not used for a PostGres connection
    user is the user name to attempt to login with on the database.
    passwd the password for the user acccount on the database
    host is the address the host is located on. If locale, you still need to provide 127.0.0.1
    dbName is the databse name we want to connect to.
  
  Return: 
    True if we successfully connected, otherwise false. Any error info
    is stored in  self.lastErrorMsg
  """
  def connect(self, dbFilePath=None, user=None, passwd=None, host=None, dbName=None ):
    try:
      connstring = "dbname=%s user=%s host=%s password=%s" % ( dbName,user,host,passwd) 
      self.DB = psycopg2.connect( connstring )
      return(True)       
    except Exception, E:
      self.lastErrorMsg = str(E)                     
    return(False)

  """
  Function: executeQuery
  Purpose: Executes the sql statement passed in.
  Parameters: 
    sqlQuery is a string containing the query to execute.
  Return: 
    If successfull, a cursor is returned, otherwise None is returned.
  """
  def executeQuery(self, sqlQuery):
    dbCursor = None
    try:
      dbCursor = self.DB.cursor(cursor_factory=psycopg2.extras.DictCursor)     
      dbCursor.execute( sqlQuery )        
    except psycopg2.Error, E:
      self.lastErrorMsg = E.pgerror
      self.lastErrorCode = E.pgcode
    except Exception, E:
      self.lastErrorMsg = str(E)                     
    
    return( dbCursor )

  def getDataForSensorID(self,sensorID, startDate, endDate, timeZoneShift):
    data = []
    sql = "SELECT multi_obs.m_date,multi_obs.m_value        \
                  FROM multi_obs           \
                  WHERE                    \
                  multi_obs.sensor_id = %d                              AND   \
                  ( m_date >= strftime( '%%Y-%%m-%%dT%%H:00:00',datetime('%s','%d hours') )   AND  \
                  m_date < strftime( '%%Y-%%m-%%dT%%H:00:00', datetime('%s','%d hours') ) ) \
                  ORDER BY multi_obs.m_date ASC;" % ( sensorID, startDate, timeZoneShift, endDate, timeZoneShift );                
    try:                      
      dbCursor = self.executeQuery( sql )
      for row in dbCursor:
        data.append( (row[0],row[1]) )       
      dbCursor.close()
    except Exception, E:
      self.lastErrorMsg = str(E)                     

  def getObsDataForPlatform(self, platform, lastNHours = None ):      
    
    #Do we want to query from a datetime of now back lastNHours?
    dateOffset = ''
    if( lastNHours != None ):
      dateOffset = "m_date >  date_trunc('hour',( SELECT timezone('UTC', now()-interval '%d' ) ) ) AND" % (lastNHours)
        
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
          WHERE %s multi_obs.platform_handle = '%s' AND qc_level IS NULL AND sensor.row_id IS NOT NULL\
          ORDER BY m_date DESC" \
          % (dateOffset,platform)
    try:
      dbCursor = self.executeQuery( sql )       
      return( dbCursor )
    except Exception, E:
      self.lastErrorMsg = str(E)                     
      
    return(None)
            
"""
Class: uomconversionFunctions
Purpose: Uses a conversion XML file to look up a from units of measurement and to units of measurement conversion 
routine. If one is found, will evaluate the function and return the result. The XML file needs to be formated with 
valid python code.
"""
class uomconversionFunctions:
  
  """
  Function: __init__
  Purpose: Initializes the class
  Parameters: 
    xmlConversionFile is the full path to the XML file to use for the conversions.
  """
  def __init__(self, xmlConversionFile=None):
    self.xmlConversionFile = xmlConversionFile
    
  def setXMLConversionFile(self, xmlConversionFile):
    self.xmlConversionFile = xmlConversionFile
    
  """
  Function: measurementConvert
  Purpose: Attempts to find a conversion formula using the passed in fromUOM and toUOM variables.
  Parameters:
    value is the floating point number to try and convert.
    fromUOM is the units of measurement the value is currently in.
    toUOM is the units of measurement we want to value to be converted to.
  Return:
    If a conversion routine is found, then the converted value is returned, otherwise None is returned.
  """
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
  """
  Function: getConversionUnits
  Purpose: Given a unit of measurement in a differing measurement system and the desired measurement system, returns uom in the desired measurement system.
  Parameters:
    uom is the current unit of measurement we want to convert.
    uomSystem is the desired measurement system we want to conver the uom into.
  Return:
    if the uomSystem is found and the uom is in the uomSystem, returns the conversion uom
  """
  def getConversionUnits(self, uom, uomSystem):
    if( uomSystem == 'en' ):
      if( uom == 'm'):
        return('ft')
      elif( uom == 'm_s-1'):
        return('mph')
      elif( uom == 'celsius' ):
        return('fahrenheit')
      elif(uom == 'cm_s-1'):
        return('mph')
      elif(uom == 'mph'):
        return('knots')
    else:
      if( uom == 'ft'):
        return('m' )
      elif( uom == 'mph'):
        return('m_s-1')
      elif( uom == 'fahrenheit' ):
        return('celsius')
      elif(uom == 'mph'):
        return('cm_s-1')
      elif(uom == 'knots'):
        return('mph')
      
    return('')
