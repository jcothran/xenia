import sys
from pysqlite2 import dbapi2 as sqlite3

#import pg

class dbTypes:
  undefined = 0
  SQLite = 1
  PostGRES = 2

class xeniaDB:
    def __init__ ( self ):
      self.dbType = dbTypes.undefined
      self.lastErrorMsg = ''
      
    def openXeniaSQLite(self, dbFilePath ):
      self.dbFilePath = dbFilePath
      self.dbType = dbTypes.SQLite
      try:
        self.DB = sqlite3.connect( self.dbFilePath )       
      except Exception, E:
        print( 'ERROR: ' + str(E) )
        
    #def ConnectXeniaPostGRES(self, dbHost, dbName, dbUser, dbPasswd ):
    #  self.dbFilePath = dbFilePath
    #  try:
    #    self.DB = sqlite.connect( self.dbFilePath )       
    #  except Exception, E:
    #    print( 'ERROR: ' + str(E) )
    
    def executeQuery(self, sqlQuery):
      retVal = 0
      dbCursor = self.DB.cursor()
      try:
        dbCursor.execute( sqlQuery )
        retVal = 1
        
      except sqlite3.Error, e:        
        self.lastErrorMsg = 'SQL ERROR: ' + e.args[0] + ' SQL: ' + sqlQuery        
      except Exception, E:
        self.lastErrorMsg = str(E)
      
      return( retVal,dbCursor )
    
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
      retVal,dbCursor = self.executeQuery( sql )
      if(retVal):
        for row in dbCursor:
          mType  = row[0]
        dbCursor.close()
               
      return( retVal,mType )
    
    def getDataForObs(self,obsMType, platform, startDate, endDate, timeZoneShift):
      data = {}
      sql = ''
      if(self.dbType == dbTypes.SQLite):
        sql = "SELECT multi_obs.m_date,multi_obs.m_value        \
                      FROM multi_obs           \
                      WHERE                    \
                      multi_obs.m_type_id = %d                              AND   \
                      m_date >= strftime( '%%Y-%%m-%%dT%%H:00:00',datetime('%s','%d hours') )   AND  \
                      m_date < strftime( '%%Y-%%m-%%dT%%H:00:00', datetime('%s','%d hours') )     AND  \
                      platform_handle = '%s';" % ( obsMType, startDate, timeZoneShift, endDate, timeZoneShift, platform );                

      retVal,dbCursor = self.executeQuery( sql )
      if(retVal):
        for row in dbCursor:
          date = row[0]
          data[date] = row[1]       
        dbCursor.close()
      
      return( retVal,data )
      
    def getDataForObs(self, obsName, platform, startDate, endDate, timeZoneShift):
      data = {}
      retVal,mType = self.getMTypeFromObsName( obsName, platform, '' )
      
      if(retVal):
        retVal,data = getDataForObs( mType,platform,startDate,endDate,endDate, timeZoneShift)
        dbCursor.close()
        
      return( retVal,data)
    
    def getObservationDates(self, obsName, platform ):
      sql = ''
      dates = []
      retVal,mType = self.getMTypeFromObsName( obsName, platform, '' )
      if(retVal):
        sql = "SELECT DISTINCT(strftime( '%%Y-%%m-%%d', datetime(m_date))), m_type_id,platform_handle FROM multi_obs \
              WHERE multi_obs.m_type_id = %d AND platform_handle = '%s' \
              ORDER BY m_date ASC;" % ( mType, platform )
        retVal,dbCursor = self.executeQuery( sql )
        if(retVal):
          for row in dbCursor:
            dates.append( row[0] )
        dbCursor.close()
                     
      return( retVal,dates )
    
    def getObservationsForPlatform(self, platform):
      sql = ''
      obsList = {}
      sql = "SELECT obs_type.standard_name,obs_type.row_id,sensor.platform_id FROM obs_type, m_type, m_scalar_type, sensor, platform \
              WHERE \
                obs_type.row_id = m_scalar_type.obs_type_id AND \
                sensor.m_type_id = m_type.row_id AND             \
                m_scalar_type.row_id = m_type.m_scalar_type_id AND \
                platform.platform_handle = '%s'" % platform;
                
      retVal, dbCursor = self.executeQuery( sql )
      if(retVal):                 
        for row in dbCursor:
          obsList[ row[0] ] = row[1]
  
        dbCursor.close()
      return( retVal,obsList )
        
if __name__ == '__main__':
  try:    
    if( len( sys.argv ) < 2 ):
        print( 'Usage: ControlChart.py dbName\n' )
        sys.exit(0)
    dbFilePath = sys.argv[1]       
    db = xeniaDB();
    db.openXeniaSQLite( sys.argv[1] )
    retVal,obsList = db.getObservationsForPlatform( 'carocoops.CAP2.buoy' )
    if( retVal ):
      retVal,dates = db.getObservationDates( 'air_temperature', 'carocoops.CAP2.buoy' )
      retVal,data = db.getDataForObs( 'air_temperature', 'carocoops.CAP2.buoy', '2009-01-22T00:00:00', '2009-01-23T00:00:00', 0 )
    else:
      print( db.lastErrorMsg )
      
    print( data )

  except Exception, E:
    print( 'ERROR: ' + str(E) )
    