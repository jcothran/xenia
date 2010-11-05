import sys
import os
import optparse
import time
import traceback
from xeniatools.xenia import dbXenia
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict
from xeniatools.utils import smtpClass 

def createPlatformSensorFile(outFile, xeniaDb):
  try:
    print("Opening file: %s" %(outFile))
    outFile = open(outFile, "w")
    
    platformList = {}
    sql = "SELECT row_id,platform_handle FROM platform WHERE active=1 ORDER BY platform_handle ASC"
    dbCursor = xeniaDb.dbConnection.executeQuery( sql )        
    if(dbCursor != None):
      for platformRow in dbCursor:    
        print("Processing: %s(%d)" %(platformRow['platform_handle'], platformRow['row_id']))   
        #Get the sensor ids for the platform
        sql = "SELECT sensor.row_id,sensor.active, \
               obs_type.standard_name as obs_type_standard_name\
               FROM sensor\
                 LEFT JOIN m_type on sensor.m_type_id = m_type.row_id\
                 LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id\
                 LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id\
              WHERE sensor.platform_id=%d ORDER BY obs_type.standard_name ASC" %(platformRow['row_id'])
        sensorIdCursor = xeniaDb.dbConnection.executeQuery(sql)        
        outBuf = "%s,%d" %(platformRow['platform_handle'],platformRow['row_id'])
        if(sensorIdCursor != None):          
          for sensorIdRow in sensorIdCursor:
            if(len(outBuf)):
              outBuf += ","
            outBuf += "%s,%d,%d" %(sensorIdRow['obs_type_standard_name'],sensorIdRow['row_id'],sensorIdRow['active'])
          sensorIdCursor.close()
        else:
          print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
          
        outBuf += "\n"
        outFile.write(outBuf)
    dbCursor.close()
    outFile.close()
  except Exception, e:
    import sys
    import traceback
    print(traceback.print_exc())
        
def queryPlatformsForDeadObs(outFile, xeniaDb):
  try:
    print("Opening file: %s" %(outFile))
    outFile = open(outFile, "w")
      
    platformList = {}
    sql = "SELECT row_id,platform_handle FROM platform WHERE active=1 ORDER BY platform_handle ASC"
    dbCursor = xeniaDb.dbConnection.executeQuery( sql )        
    if(dbCursor != None):
      for platformRow in dbCursor:    
        print("Processing: %s(%d)" %(platformRow['platform_handle'], platformRow['row_id']))   
        #Get the sensor ids for the platform
        sql = "SELECT sensor.row_id, \
               obs_type.standard_name as obs_type_standard_name\
               FROM sensor\
                 LEFT JOIN m_type on sensor.m_type_id = m_type.row_id\
                 LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id\
                 LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id\
              WHERE platform_id=%d" %(platformRow['row_id'])
        sensorIdCursor = xeniaDb.dbConnection.executeQuery(sql)        
        outBuf = "" 
        if(dbCursor != None):
          for sensorIdRow in sensorIdCursor:
            #Get a listing of all sensor ids that haven't had data reported in the multi_obs table.
            sql = "SELECT COUNT(multi_obs.sensor_id) AS idcount\
                  FROM multi_obs\
                  WHERE multi_obs.sensor_id=%d AND platform_handle='%s'"\
                  %(sensorIdRow['row_id'], platformRow['platform_handle'])
            
            multiObsCursor = xeniaDb.dbConnection.executeQuery(sql)
            if(multiObsCursor != None):
              countRow = multiObsCursor.fetchone()
              if(int(countRow['idcount']) == 0):
                if(len(outBuf)):
                  outBuf += ","
                outBuf += "%s,%d" %(sensorIdRow['obs_type_standard_name'],sensorIdRow['row_id'])
            else:
              print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
          sensorIdCursor.close()    
          if(len(outBuf)):
            line = "%s,%d,%s\n" %(platformRow['platform_handle'],platformRow['row_id'], outBuf)        
            outFile.write(line)
            outFile.flush()
        else:
          print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
      dbCursor.close()
    outFile.close()        
  except Exception, e:
    import sys
    import traceback
    print(traceback.print_exc())

def initializeSensorTable(xeniaDb):
  sql = "UPDATE sensor SET active=0 WHERE active IS NULL;"
  dbCursor = xeniaDb.dbConnection.executeQuery(sql)
  if(dbCursor == None):
    print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  dbCursor.close()
  xeniaDb.dbConnection.commit()
  
  #Get all the DISTINCT sensor ids, then we'll mark them as active.
  sql = "SELECT DISTINCT(sensor_id) AS sensor_id FROM multi_obs;"
  dbCursor = xeniaDb.dbConnection.executeQuery(sql)
  if(dbCursor != None):
    for sensorIdRow in dbCursor:
      sql = "UPDATE sensor SET active=1 WHERE row_id=%d" %(sensorIdRow['sensor_id'])
      updateCursor = xeniaDb.dbConnection.executeQuery(sql)
      if(updateCursor == None):
        print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
      else:
        updateCursor.close()
    xeniaDb.dbConnection.commit()
  else:
    print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  
def checkSensorActivity(xeniaDb, hoursToLookback, emailList, outFilename, emailUser, emailPwd):
  
  try:
    print("Opening file: %s" %(outFilename))
    outFile = open(outFilename, "w")
    if(hoursToLookback != None):
      outFile.write("Sensor activity check for the past %d hours.\n" %(hoursToLookback))
    else:
      outFile.write("Sensor activity check for the entire record set in multi_obs.\n")
    platNfo = recursivedefaultdict()
    
    sql = "SELECT sensor.row_id AS row_id, sensor.active AS active, \
           obs_type.standard_name as obs_type_standard_name,\
           platform.platform_handle as platform_handle\
           FROM sensor\
             LEFT JOIN m_type on sensor.m_type_id = m_type.row_id\
             LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id\
             LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id\
             LEFT JOIN platform on sensor.platform_id = platform.row_id\
          WHERE platform.active=1 ORDER BY sensor.row_id ASC;"
    dbCursor = xeniaDb.dbConnection.executeQuery(sql)
    if(dbCursor != None):        
      for row in dbCursor:
        sensorId = row['row_id']
        platNfo[sensorId]['platform_handle'] = row['platform_handle']
        platNfo[sensorId]['obsName'] = row['obs_type_standard_name']
        platNfo[sensorId]['active'] = row['active']
      dbCursor.close()
    else:
      msg = "Error: %s" %(xeniaDb.dbConnection.getErrorInfo())
      print(msg)
      outFile.write(msg)
      sys.exit(-1)
    
    reActivatedPlatforms = {}
    where = ""
    if(hoursToLookback != None):
      where = "WHERE m_date >= now() - interval '%d hours'" %(hoursToLookback) 
    #Get all the DISTINCT sensor ids, then we'll mark them as active.
    sql = "SELECT DISTINCT(sensor_id) AS sensor_id,platform_handle,\
            obs_type.standard_name as obs_type_standard_name\
            FROM multi_obs\
             LEFT JOIN m_type on multi_obs.m_type_id = m_type.row_id\
             LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id\
             LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id %s;" %(where)
            
    dbCursor = xeniaDb.dbConnection.executeQuery(sql)
    if(dbCursor != None):
      for row in dbCursor:
        sensorId = row['sensor_id']
        if(platNfo.has_key(sensorId)):
          active = platNfo[sensorId]['active']
          if(active != 1):
            platform_handle = platNfo[sensorId]['platform_handle']
            obsName = platNfo[sensorId]['obsName']
            msg = 'Platform: %s Sensor: %s(%d) inactive sensor now reporting.'\
                   %(platform_handle,obsName,sensorId)
            print(msg)
            outFile.write("%s\n" %(msg))
          del platNfo[sensorId]
        else:
          platformHandle = row['platform_handle']
          print("Platform: %s Sensor ID: %d not present in current active platform/sensor list. Added to re-activate list." %(platformHandle,sensorId))
          if(reActivatedPlatforms.has_key(platformHandle) == False):
            reActivatedPlatforms[platformHandle] = []
          info = {}
          info['sensorId'] = sensorId
          info['obsName'] = row['obs_type_standard_name']
          reActivatedPlatforms[platformHandle].append(info)
      dbCursor.close()
      
      #If we had sensors come alive for platforms that were inactive, we re-activate the platforms and the sensors.
      if(len(reActivatedPlatforms)):
        print("Preparing to re-active Platforms and Sensors that have become active.")
        outFile.write("Reactivating Platforms and Sensors that have become active.\n")
        for platform in reActivatedPlatforms:
          sql = "UPDATE platform SET active=1 WHERE platform_handle='%s'" %(platform)
          dbCursor = xeniaDb.dbConnection.executeQuery(sql)
          if(dbCursor != None):
            
            msg = "Platform: %s" %(platform)
            print(msg + " set active to 1.")
            outFile.write("%s\n" %(msg))
            xeniaDb.dbConnection.commit()
            dbCursor.close()
            #sensorList = reActivatedPlatforms[platform]
            for info in reActivatedPlatforms[platform]:
              sql = "UPDATE sensor SET active=1 WHERE row_id=%d" %(info['sensorId'])
              dbCursor = xeniaDb.dbConnection.executeQuery(sql)
              if(dbCursor != None):
                msg = "Platform: %s Sensor: %s(%d)" %(platform, info['obsName'], info['sensorId'])
                print(msg + " set active to 1.")
                outFile.write("%s\n" %(msg))
                xeniaDb.dbConnection.commit()
                dbCursor.close()
              else:
                print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
          else:
            print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
                  
      if(len(platNfo)):
        outFile.write("The following details show platforms and sensors that are marked as active but did not report.\n")
        for sensorId in platNfo:
          msg = "Platform: %s Sensor: %s(%d)" %(platNfo[sensorId]['platform_handle'],platNfo[sensorId]['obsName'],sensorId)
          print(msg + " did not report observations.")
          outFile.write("%s\n" %(msg))
      outFile.close()
      smtp = smtpClass("inlet.geol.sc.edu", emailUser, emailPwd)
      smtp.subject('[secoora_auto_alert] Check Sensor Results')
      smtp.message('Attached is the latest run results for the sensorTableUtils script.')
      smtp.from_addr('dan@inlet.geol.sc.edu')
      smtp.rcpt_to(emailList)
      smtp.attach(outFilename)
      smtp.send()      
    else:
      print("Error: %s" %(xeniaDb.dbConnection.getErrorInfo()))
      sys.exit(-1)
      
  except Exception, e:
    import traceback
    print(traceback.print_exc())
    
if __name__ == '__main__':
  
  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
      
  parser = optparse.OptionParser()
  
  parser.add_option("-d", "--dbName", dest="dbName",
                    help="The name of the xenia database to connect to." )
  parser.add_option("-o", "--dbHost", dest="dbHost",
                    help="The xenia database host address to connect to." )
  parser.add_option("-u", "--dbUser", dest="dbUser",
                    help="The xenia database user name to connect with." )
  parser.add_option("-p", "--dbPwd", dest="dbPwd",
                    help="The xenia database password name to connect with." )
  parser.add_option("-b", "--Polygon", dest="polygon",
                    help="The polygon we want to use to select the platforms. Format is: long lat, long lat...."  )
  parser.add_option("-m", "--MissingObsOutfile", dest="missingObsOutfile",
                    help="The fully qualified file path where the data gets written.")
  parser.add_option("-l", "--ObsListOutfile", dest="obsListOutfile",
                    help="The fully qualified file path where the data gets written.")
  parser.add_option("-i", "--ResetSensorActive", dest="resetSensorActive", action= 'store_true',
                    help="")
  parser.add_option("-c", "--CheckSensorActivity", dest="checkSensorActivity", action= 'store_true',
                    help="")
  parser.add_option("-r", "--HoursToLookbak", dest="hoursToLookbak",
                    help="")
  parser.add_option("-e", "--EmailList", dest="emailList",
                    help="")
  parser.add_option("-a", "--SensorActivityFile", dest="sensorActivityFile",
                    help="Fully qualified path to a file that logs the results of the sensor activity test.")
  parser.add_option("-n", "--EmailUserName", dest="emailAcctUserName", 
                    help="The username for the SMTP account that will send the email.")
  parser.add_option("-w", "--EmailUserPwd", dest="emailAcctUserPwd", 
                    help="The password for the SMTP user account that will send the email.")
  

  (options, args) = parser.parse_args()
  
  xeniaDb = dbXenia()
  if( xeniaDb.connect(None, options.dbUser, options.dbPwd, options.dbHost, options.dbName) == False ):
    print("Unable to connect to the database: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  else:
    print("Sucessfully connected to DB: %s @ %s" % (options.dbName, options.dbHost))
  
  
  if(options.resetSensorActive):
    initializeSensorTable(xeniaDb)
    
  if(options.missingObsOutfile != None and len(options.missingObsOutfile)):
    queryPlatformsForDeadObs(options.missingObsOutfile, xeniaDb)
        
  if(options.obsListOutfile != None and len(options.obsListOutfile)):
    createPlatformSensorFile(options.obsListOutfile, xeniaDb)
  
  if(options.checkSensorActivity):
    lookbak = None
    if(options.hoursToLookbak != None):
      lookbak = int(options.hoursToLookbak)
    emailList = options.emailList.split(',')
    checkSensorActivity(xeniaDb, lookbak, emailList, options.sensorActivityFile, options.emailAcctUserName, options.emailAcctUserPwd)
  
        
