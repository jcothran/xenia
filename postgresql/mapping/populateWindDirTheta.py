import sys
import os
import optparse
import ConfigParser
import time
import traceback
from xeniatools.xenia import dbXenia
from xeniatools.xmlConfigFile import xmlConfigFile



if __name__ == '__main__':
  
  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
      
  parser = optparse.OptionParser()
  parser.add_option("-c", "--dbConfigFile", dest="dbConfigFile",
                  help="The ini file containing the configuration information." )  
  parser.add_option("-p", "--PreviousHours", dest="previousHours",
                  help="Number of hours in the past to query and re-stamp." )  
  (options, args) = parser.parse_args()
  if(options.dbConfigFile == None ):
    parser.print_usage()
    parser.print_help()
    sys.exit(-1)

  cfgFile = ConfigParser.ConfigParser()
  cfgFile.read(options.dbConfigFile)
  dbName = 'xenia'
  dbHost = cfgFile.get(dbName, 'host')
  dbUser = cfgFile.get(dbName, 'username')
  dbPwd = cfgFile.get(dbName, 'password')
  
  xeniaDb = dbXenia()
  if( xeniaDb.connect(None, dbUser, dbPwd, dbHost, dbName) == False ):
    print("Unable to connect to the database: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  else:
    print("Sucessfully connected to DB: %s @ %s" % (dbName, dbHost))
  
 
  obsWindDir= xeniaDb.dbConnection.obsTypeExists('wind_from_direction')
  obsWindSpeed= xeniaDb.dbConnection.obsTypeExists('wind_speed')
  
  rowsUpdated = 0
  sql = "SELECT m_date,m_value,platform_handle FROM multi_obs "\
        "WHERE m_date >= now() - interval '%d hours' AND m_type_id=%d AND d_top_of_hour=1 "\
        "ORDER BY m_date ASC"\
        %(int(options.previousHours), obsWindDir)
  windDir = xeniaDb.executeQuery(sql)
  if(windDir != None):
    for windDirRow in windDir:     
      val = windDirRow['m_value']
      print("Platform: %s" %(windDirRow['platform_handle']))
      #For MapServer?? directional font libraries, the direction is negative of the 
      #true direction(degrees from North), so 90 (degrees) becomes -90 for display purposes.
      val = val * -1
      sql = "UPDATE multi_obs SET d_label_theta=%d WHERE m_date='%s' AND m_type_id=%d AND platform_handle='%s';"\
            %(val,windDirRow['m_date'],obsWindSpeed,windDirRow['platform_handle'])
      windSpdCursor = xeniaDb.executeQuery(sql)
      if(windSpdCursor == None):
        print("Error updating Wind Speed. Error: %s SQL: %s" %(xeniaDb.dbConnection.getErrorInfo(), sql))
      else:
        rowsUpdated += 1
        windSpdCursor.close()
    if(xeniaDb.dbConnection.commit() == False):
      print("Commit Error. Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    