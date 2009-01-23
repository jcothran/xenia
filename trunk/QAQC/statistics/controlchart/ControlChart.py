import sys
from pysqlite2 import dbapi2 as sqlite

#import pg

class dbTypes:
  undefined = 0
  SQLite = 1
  PostGRES = 2

class xeniaDB:
    def __init__ ( self ):
      self.dbType = dbTypes.undefined
      
    def openXeniaSQLite(self, dbFilePath ):
      self.dbFilePath = dbFilePath
      self.dbType = dbTypes.SQLite
      try:
        self.DB = sqlite.connect( self.dbFilePath )       
      except Exception, E:
        print( 'ERROR: ' + str(E) )
        
    #def ConnectXeniaPostGRES(self, dbHost, dbName, dbUser, dbPasswd ):
    #  self.dbFilePath = dbFilePath
    #  try:
    #    self.DB = sqlite.connect( self.dbFilePath )       
    #  except Exception, E:
    #    print( 'ERROR: ' + str(E) )
    
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
        dbCursor = self.DB.cursor()
        dbCursor.execute( sql )
        for row in dbCursor:
          mType  = row[0]
        
      except Exception, E:
          print( 'ERROR: ' + str(E) )
      
      return( mType )

    def getDataForObs(self, obsName, platform, startDate, endDate, timeZoneShift):
      data = {}
      sql = ''
      try:
        mType = self.getMTypeFromObsName( obsName, platform, '' )
        if(self.dbType == dbTypes.SQLite):
          sql = "SELECT multi_obs.m_date,multi_obs.m_value        \
                        FROM multi_obs           \
                        WHERE                    \
                        multi_obs.m_type_id = %d                              AND   \
                        m_date >= strftime( '%%Y-%%m-%%dT%%H:00:00',datetime('%s','%d hours') )   AND  \
                        m_date < strftime( '%%Y-%%m-%%dT%%H:00:00', datetime('%s','%d hours') )     AND  \
                        platform_handle = '%s';" % ( mType, startDate, timeZoneShift, endDate, timeZoneShift, platform );                

        dbCursor = self.DB.cursor()
        dbCursor.execute( sql )
        for row in dbCursor:
          date = row[0]
          data[date] = row[1]
        
      except Exception, E:
          print( 'ERROR: ' + str(E) )
        
      return( data )
    
if __name__ == '__main__':
  try:    
    if( len( sys.argv ) < 2 ):
        print( 'Usage: ControlChart.py dbName\n' )
        sys.exit(0)
    dbFilePath = sys.argv[1]       
    db = xeniaDB();
    db.openXeniaSQLite( sys.argv[1] )
    
    data = db.getDataForObs( 'air_temperature', 'carocoops.CAP2.buoy', '2009-01-22T00:00:00', '2009-01-23T00:00:00', 0 )
    
    print( data )

  except Exception, E:
    print( 'ERROR: ' + str(E) )
    