import time
from pysqlite2 import dbapi2 as sqlite3
#from pgdb

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

      except Exception, E:
        print( 'ERROR: ' + str(E) )
        
    #def openXeniaPostGres( dbHost, dbName, dbUser, dbPasswd ):
    #  self.dbType = dbTypes.PostGRES
    #  try:
    #    self.DB = postgres.connect( dbname=dbHost, host=dbName, user=dbUser, password=dbPasswd )       
    #  except Exception, E:
    #    print( 'ERROR: ' + str(E) )
    
    def executeQuery(self, sqlQuery):
      dbCursor = self.DB.cursor()
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
      sql = "SELECT obs_type.standard_name,obs_type.row_id,sensor.platform_id FROM obs_type, m_type, m_scalar_type, sensor, platform \
              WHERE \
                obs_type.row_id = m_scalar_type.obs_type_id AND \
                sensor.m_type_id = m_type.row_id AND             \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND \
                platform.platform_handle = '%s'" % platform;
      try:
        dbCursor = self.executeQuery( sql )
        for row in dbCursor:
          obsList[ row[0] ] = row[1]  
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
      platformList = []
      
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
    
    #def updateMultiObsQC(self, date, platform, obsName, qc_flag, qc_level ):