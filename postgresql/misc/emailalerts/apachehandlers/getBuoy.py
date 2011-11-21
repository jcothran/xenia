#!/usr/bin/python

_USE_HANDLER = True
if(_USE_HANDLER):
  from mod_python import apache
  from mod_python import util



def handler(req):
#if __name__ == '__main__':
    
  from xeniatools.xenia import dbXenia
  from xeniatools.xmlConfigFile import xmlConfigFile
  from xeniatools.xenia import qaqcTestFlags
  from xeniatools.xenia import uomconversionFunctions
  from xeniatools.emailAlertSystem import GroupWriteRotatingFileHandler
  
  from urllib2 import Request, urlopen, URLError, HTTPError
  import simplejson 
  import os
  import stat
  import logging
  import logging.handlers
  
  if(_USE_HANDLER):
    configFile = '/home/xeniaprod/config/mobileBuoyConfig.xml'
    req.log_error('handler')
    #req.add_common_vars()
    params = util.FieldStorage(req)
  else:
    #configFile = '/home/xeniaprod/config/mobileBuoyConfig.xml'
    configFile = 'C:\\Documents and Settings\\dramage\\workspace\\SVNSandbox\\carolinasrcoos\\trunk\\website\\mobileBuoyConfigDebug.xml'       
    params = {}
    params['radius'] = 'nearby'
    params['latitude'] = 33.65921
    params['longitude'] = -78.91754

  configSettings = xmlConfigFile( configFile )
  
  logFile = configSettings.getEntry("//environment/logging/logFilename")
  
  backupCount = configSettings.getEntry("//environment/logging/backupCount")
  maxBytes = configSettings.getEntry("//environment/logging/maxBytes")
  logFileExists = True
  #If the log file does not exist, we want to make sure when we create it to give everyone write access to it.
  if(os.path.isfile(logFile) != True):
    logFileExists = False

  logger = logging.getLogger("mobilebuoy_handler")
  logger.setLevel(logging.DEBUG)
  # create formatter and add it to the handlers
  formatter = logging.Formatter("%(asctime)s,%(name)s,%(levelname)s,%(lineno)d,%(message)s")
  #Create the log rotation handler.
  handler = logging.handlers.GroupWriteRotatingFileHandler = GroupWriteRotatingFileHandler
  handler = logging.handlers.GroupWriteRotatingFileHandler( logFile, "a", maxBytes, backupCount )
  handler.setLevel(logging.DEBUG)
  handler.setFormatter(formatter)    
  logger.addHandler(handler)
  if(logFileExists != True):
    currMode = os.stat(logFile).st_mode
    #Since the email alert module can be used by web service as well as from command line, we want to change
    #the file permissions to give everyone access to it. Probably would be better to use group permissions
    #only, but for now we grant all.
    os.chmod(logFile, currMode | (stat.S_IXUSR|stat.S_IWGRP|stat.S_IXGRP|stat.S_IROTH|stat.S_IWOTH|stat.S_IXOTH))
    
  # add the handlers to the logger
  logger.info('Log file opened')
  
  try:
    convertFile = configSettings.getEntry( '//environment/unitsCoversion/file' )
    uomConverter = None
    if( convertFile != None ):
      uomConverter = uomconversionFunctions(convertFile)
  
    dbSettings = configSettings.getDatabaseSettings()  
    dbCon = dbXenia()
    if(dbCon.connect(None, dbSettings['dbUser'], dbSettings['dbPwd'], dbSettings['dbHost'], dbSettings['dbName']) != True):
      logger.error("Unable to open database connection. Cannot continue.")
      req.content_type = 'text/plain;' 
      output = "Unable to lookup buoys. Please try again later."
      req.write(output)
      req.status = apache.HTTP_OK
    else:
      logger.info("Opened database connection.")
      radius = params['radius']
      lat = float(params['latitude'])
      lon = float(params['longitude'])
      if(radius == 'nearby'):      
        radius = 40.0
      else:
        radius = float(radius)
  
      logger.debug("Radius: %s Latitude: %f Longitude: %f" % (radius,lat,lon))
      sql = "SELECT platform_handle,\
                    fixed_longitude,fixed_latitude,\
                    Distance( GeomFromText('POINT(' || fixed_longitude || ' ' || fixed_latitude ||')'), GeomFromText('POINT(%f %f)')) * 60 as distancenm FROM platform\
                    WHERE active = 1 AND\
                    Distance( GeomFromText('POINT(' || fixed_longitude || ' ' || fixed_latitude ||')'), GeomFromText('POINT(%f %f)')) * 60 < %f\
                    ORDER BY distancenm ASC;" %(lon, lat, lon, lat, radius)
                            
      dbCursor = dbCon.dbConnection.executeQuery(sql)
      if(dbCursor != None):
        logger.debug("Platform query: %s" %(sql))
        jsonDict = {}
        platforms = []
        rowCnt = 0
        for row in dbCursor:
          platform = {}
          platform['platform_handle'] = row['platform_handle']
          platform['latitude']        = row['fixed_latitude']
          platform['longitude']       = row['fixed_longitude']
          distance = float(row['distancenm'])
          platform['distance']        = ("%4.3f" % (distance))
          platform['distanceUnits']   = 'NM'
          platforms.append(platform)
          rowCnt += 1          
        dbCursor.close()
        if(rowCnt == 0):
          platform = {}
          platform['platform_handle'] = "No platforms found"
          platform['latitude']        = ""
          platform['longitude']       = ""
          platform['distance']        = "0"
          platform['distanceUnits']   = "NM"
          platforms.append(platform)
          
        #Now let's get the latest met data.
        jsonBaseURL = configSettings.getEntry('//environment/jsonFiles/baseURL')
        for platform in platforms:
          fullURL = "%s%s_data.json" % (jsonBaseURL, (platform['platform_handle'].replace('.',':')).lower())
          logger.debug("Processing json file: %s" %(fullURL))
          urlReq = Request(fullURL)
          try:
            result = simplejson.load(urlopen(urlReq))
          except HTTPError, e:
            logger.debug("%s Code: %d" %(e.filename,e.code))
            continue
          
          latestObs = []
          features = (result['properties'])['features']
          for feature in features:   
            obs = {}
            properties = feature['properties']
            obsName = properties['obsType']
            #Check to see if we have an abbreviated name to use.
            abbrName = uomConverter.getAbbreviatedObservationName(obsName)    
            if(abbrName != None):
              obsName = abbrName
            else:
              obsName = obsName.replace('_', ' ')
            obs['name'] = obsName              
            obs['time'] = properties['time'][-1]  
            obs['uom'] =  properties['uomType']            
            obs['value'] = float((properties['value'])[-1])
            uom = uomConverter.getConversionUnits( obs['uom'], 'en' )
            if( len(uom) > 0 ):
              obs['value'] = uomConverter.measurementConvert( obs['value'], obs['uom'], uom )
              displayUnits = uomConverter.getUnits(obs['uom'], uom)
              if(displayUnits  != None):
                obs['uom'] = displayUnits            
            latestObs.append(obs)
            
          platform['latest_obs'] = latestObs
          
        if(len(platforms)):
          jsonDict['platform_list'] = platforms
          jsonData = simplejson.dumps(jsonDict) 
  
          if(_USE_HANDLER):
            req.content_type = 'application/json;' 
            req.set_content_length(len(jsonData))
            logger.debug("Json: %s" %(jsonData))
            req.write(jsonData)
            req.status = apache.HTTP_OK
          else:
            print(jsonData)       
      else:
        logger.critcal("%s" %(dbCon.dbConnection.getErrorInfo()))
    logger.info("Closing log file.")
    
  except Exception, e:
    import traceback
    logger.critical("Exception occured:", exc_info=1)