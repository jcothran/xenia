#import time
from pysqlite2 import dbapi2 as sqlite3      
import psycopg2
import psycopg2.extras

class dbTypes:
  undefined = 0
  SQLite = 1
  PostGRES = 2

class obsData:
  def __init__(self):
    self.obsName    = None
    self.uom        = None
    self.m_type_id  = None
    self.m_value    = None
    self.sensor_id  = None
    self.s_order    = None

class xeniaDB:
    def __init__ ( self ):
      self.dbType = dbTypes.undefined
      self.lastErrorMsg = ''
    
    def getLastErrorMsg(self):
      msg = self.lastErrorMsg
      self.lastErrorMsg = ''
      return(msg)  
    
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
    
    #def updateMultiObsQC(self, date, platform, obsName, qc_flag, qc_level ):
    


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
    return('')
          