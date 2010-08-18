import sys
import os
import optparse
import time
import traceback
from pysqlite2 import dbapi2 as sqlite3      
from xeniatools.xenia import dbXenia
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict

class dbDisplayLatestObs(object):
  def __init__(self, dbFilepath):
    try:
      self.lastErrorMsg = ''
      self.dbFilepath = dbFilepath
      #Since the operation can take some time, we create a temporary database, then once it is populated, we copy it over the working database.
      self.tmpDBFilepath = dbFilepath + 'inproc'
      #The latest obs db doesn't exist, so we need to create the table once we create the file.
      createTable = False
      if(os.path.exists(self.tmpDBFilepath) == False):
        createTable = True
      self.db = sqlite3.connect( self.tmpDBFilepath )
      if(self.tableExists('html_content') == False):
        createTable = True
        
      #This enables the ability to manipulate rows with the column name instead of an index.
      self.db.row_factory = sqlite3.Row
      if(createTable):
        print("Creating html_content table.")
        if(self.createObsTable() == False):
          return
      else:
        print("html_content table exists, clearing contents and vacuuming.")
       
        #Delete any entries in the table.
        sql = "DELETE FROM html_content"
        dbCur = self.executeQuery(sql)
        if(dbCur != None):
          self.db.commit()
          #Now vacuum the database
          sql = "VACUUM;"
          dbCur = self.executeQuery(sql)
        else:
          print(self.lastErrorMsg)
      
      return
    except Exception, E:
      self.lastErrorMsg = traceback.format_exc()
      print(self.lastErrorMsg)                      
    return
  
  def copyToWorkingDB(self):
    import shutil
    try:
      print("Copying temp db: %s to working db: %s" %(self.tmpDBFilepath, self.dbFilepath))
      shutil.copy(self.tmpDBFilepath, self.dbFilepath)
      
    except Exception, E:
      self.lastErrorMsg = traceback.format_exc()
      
  def executeQuery(self, sqlQuery):   
    try:
      dbCursor = self.db.cursor()
      dbCursor.execute( sqlQuery )        
      return( dbCursor )
    except sqlite3.Error, e:
      self.lastErrorMsg = traceback.format_exc()         
    except Exception, E:
      self.lastErrorMsg = traceback.format_exc()
    return(None)
  
  def tableExists(self, tableName):
    sql = "SELECT name FROM sqlite_master WHERE name = '%s'" %(tableName)
    dbCur = self.executeQuery(sql)
    if(dbCur != None):
      return(True)
    return(False)
    
  def createObsTable(self):
    sql = "CREATE TABLE html_content (\
          ogc_fid integer PRIMARY KEY,\
          insert_date text,\
          obs_date text,\
          wkt_geometry text,\
          organization text,\
          html text,\
          platform_handle text)"
    dbCur = self.executeQuery(sql)
    if(dbCur != None):
      return(True)
    return(False)
  
  def addRowToObsTable(self, insert_date, obs_date, latitude, longitude, organization, html, platform ):
    sql = "INSERT INTO html_content(insert_date,obs_date,wkt_geometry,organization,html,platform_handle)\
           values ('%s','%s','POINT(%f %f)','%s','%s', '%s');"\
           %(insert_date, obs_date, longitude, latitude, organization, html, platform)
    dbCur = self.executeQuery(sql)
    if(dbCur != None):
      return(True)
    return(False)
           
  def buildContent(self, xeniaDb, uomConverter, boundingBox):
    
    try:
      GEORSSPATH = 'http://129.252.37.90/xenia/feeds/georss/';
      DATAQUERYPAGEPATH = 'http://carolinasrcoos.org/queryStation.php?station=';
      ADCPGRAPHURL = 'http://carocoops.org/~dramage_prod/cgi-bin/rcoos/ADCPGraph.php?PLATFORMID=<ID>&INTERVAL=<INTERVAL>';
      TWITTERURL = 'http://twitter.com/';

      sql = "SELECT to_char(timezone('UTC', m_date), 'YYYY-MM-DD HH24:MI:SS') AS local_date \
      ,m_date as m_date\
      ,multi_obs.platform_handle  as multi_obs_platform_handle\
      ,obs_type.standard_name as obs_type_standard_name\
      ,uom_type.standard_name as uom_type_standard_name\
      ,multi_obs.m_type_id as multi_obs_m_type_id\
      ,m_lon\
      ,m_lat\
      ,m_z\
      ,m_value\
      ,qc_level\
      ,sensor.row_id as sensor_row_id\
      ,sensor.s_order as sensor_s_order\
      ,sensor.url as sensor_url\
      ,platform.url as platform_url\
      ,platform.description as platform_description\
      ,organization.short_name as organization_short_name\
      ,organization.url as organization_url\
      ,m_type_display_order.row_id as m_type_display_order_row_id\
      ,extract(epoch from m_date)\
      from multi_obs\
      left join sensor on sensor.row_id=multi_obs.sensor_id\
      left join m_type on m_type.row_id=multi_obs.m_type_id\
      left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id\
      left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id\
      left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id\
      left join platform on platform.row_id=sensor.platform_id\
      left join organization on organization.row_id=platform.organization_id\
      left join m_type_display_order on m_type_display_order.m_type_id=multi_obs.m_type_id\
      where\
        m_date>(now()-interval '12 hours') AND\
       Contains( GeomFromText( \'POLYGON((%s))\'), GeomFromText( 'POINT(' || fixed_longitude || ' ' || fixed_latitude ||')' ) )\
      union\
      select\
            null as local_date,\
            null as m_date,\
            platform.platform_handle as multi_obs_platform_handle ,\
            null as obs_type_standard_name,\
            null as uom_type_standard_name,\
            null as multi_obs_m_type_id,\
            platform.fixed_longitude,\
            platform.fixed_latitude,\
            null as m_z,\
            null as m_value ,\
            null as qc_level,\
            null as row_id,\
            null as s_order,\
            null as sensor_url,\
            platform.url as platform_url ,\
            platform.description as platform_description,\
            organization.short_name as organization_short_name,\
            organization.url as organization_url,\
            null as m_type_display_order_row_id,\
            null as epoch\
            from platform\
      left join organization on organization.row_id=platform.organization_id\
       where platform.active=1 AND\
       Contains( GeomFromText( \'POLYGON((%s))\'), GeomFromText( 'POINT(' || fixed_longitude || ' ' || fixed_latitude ||')' ) )\
        order by multi_obs_platform_handle,m_type_display_order_row_id,sensor_s_order,m_date desc;"\
        % (boundingBox,boundingBox)
      
      #print(sql)
      latestObs = recursivedefaultdict()
      latestDate = None
      currentPlatform = None
      dbCursor = xeniaDb.dbConnection.executeQuery( sql )    
      if(dbCursor != None):          
        for obsRow in dbCursor:
          
          #print("Organization: %s platform: %s" %(obsRow['organization_short_name'], obsRow['multi_obs_platform_handle']))
          if(currentPlatform == None):
            currentPlatform = obsRow['multi_obs_platform_handle']
            
          if(latestDate == None):
            latestDate = str(obsRow['m_date'])          
          else:
            if(obsRow['m_date'] != None):
              #We only want the most current obs.
              if(latestDate != str(obsRow['m_date']) and currentPlatform == obsRow['multi_obs_platform_handle']):
                continue
                
          currentPlatform = obsRow['multi_obs_platform_handle']
          latestDate = str(obsRow['m_date'])
          if(obsRow['m_type_display_order_row_id'] != None):
            #latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['m_type_id'] = obsRow['multi_obs_m_type_id']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['obs_name'] = obsRow['obs_type_standard_name']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['uom'] = obsRow['uom_type_standard_name']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['m_value'] = obsRow['m_value']
            #latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['m_z'] = obsRow['m_z']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['qc_level'] = obsRow['qc_level']
            #latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['sensor_url'] = obsRow['sensor_url']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['sensor_id'] = obsRow['sensor_row_id']          
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['local_date'] = obsRow['local_date']
            latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['obs_list'][obsRow['m_type_display_order_row_id']]['m_date'] = latestDate
          #assuming all observations are basically the same lat/lon as platform
          latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['m_lat'] = obsRow['m_lat']
          latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['m_lon'] = obsRow['m_lon']
          latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['url'] = obsRow['platform_url']
          latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']]['platform_desc'] = obsRow['platform_description']
          #latestObs[obsRow['organization_short_name']]['platform_list'][obsRow['multi_obs_platform_handle']][status] = $platform_status
          latestObs[obsRow['organization_short_name']]['name'] = obsRow['organization_short_name']
          latestObs[obsRow['organization_short_name']]['url'] = obsRow['organization_url']
      else:
        print( xeniaDb.dbConnection.getErrorInfo() )
        sys.exit(-1)
                                                                                                  
      dbCursor.close()
      operatorKeys = latestObs.keys()
      operatorKeys.sort()
      platformCnt = 0
      operatorCnt = 0
      insertDate = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
      for operator in operatorKeys:
        for platform in latestObs[operator]['platform_list']:
          print("Processing platform: %s" %(platform))
          htmlContent = ''        
          contentHeader = ''
          platformContent = ''
          latestDate = None
          
          platformParts = platform.split('.')    
          lcPlatform = platformParts[1].lower()
          operator = platformParts[0]
          links ='<a href=%s%s_%s_%s_GeoRSS_latest.xml target=new title="RSS Feed"><img src="images/rss_small.jpg"/></a>'\
                  %(GEORSSPATH, platformParts[0], lcPlatform, platformParts[2]);     
          if( lcPlatform == 'cap2' or lcPlatform == 'sun2' or lcPlatform == 'frp2' or
              lcPlatform == 'ocp1' or lcPlatform == 'ilm2' or lcPlatform == 'ilm3' ):
            links += '<a href=%s%sRCOOS target=new title="Twitter Feed"><img src="images/twitter.png"/></a>'\
             %(TWITTERURL,lcPlatform)
          links += '<a href=%s%s target=new title="Data Query"><img src="images/data_query.png"/></a>'\
                    %(DATAQUERYPAGEPATH, lcPlatform.upper());
          desc = latestObs[operator]['platform_list'][platform]['platform_desc']
          #No description in the database, so we'll make one based on the operator and platform
          if(len(desc) == 0):
            desc = "%s %s" % (operator, platformParts[1])
          contentHeader = "<div id=\"popupobscontent\" class=\"popupobscontent\"><hr/><a href=\"%s\" target=new onclick=\"\">%s</a><p id=\"popupobsloc\" class=\"popupobsloc\">Latitude: %4.3f Longitude: %4.3f</p><p id=\"popupobslinks\" class=\"popupobslinks\">%s</p>"\
                          %(latestObs[operator]['url'], 
                            desc,
                            latestObs[operator]['platform_list'][platform]['m_lat'],
                            latestObs[operator]['platform_list'][platform]['m_lon'],
                            links )
          
          displayOrderKeys = latestObs[operator]['platform_list'][platform]['obs_list'].keys()
          displayOrderKeys.sort()    
          
          for displayOrder in displayOrderKeys:    
            if(latestDate == None):
              if(latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['m_date'] != None):
                #latestDate = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['m_date']                     
                latestDate = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['local_date']
                localDatetime = time.strptime(latestDate, '%Y-%m-%d %H:%M:%S')                
                obsLocalEpochSecs = time.mktime(localDatetime)
                
                datetimeLabel = "<span id=\"popupobsstatus\" class=\"popupobsstatusold\">No data available within the past 6 hours</span>"
                localNow = time.mktime(time.localtime())
                if((localNow - obsLocalEpochSecs) > 21600):
                  datetimeLabel = "<span id=\"popupobsstatus\" class=\"popupobsstatusold\">No data available within the past 6 hours</span>"         
                else:
                  tz = 'EST'
                  if(time.daylight == 1):
                    tz = 'EDT'
                  day = time.strftime("%m/%d", localDatetime)
                  datetimeLabel = time.strftime("Surface conditions as of %I:%M %p", localDatetime)
                  datetimeLabel = "%s %s on %s" %(datetimeLabel, tz, day)
                  if((localNow - obsLocalEpochSecs) > 7200): 
                    datetimeLabel += "<br><span class=\"popupobsstatusstale\">Note: This report is more than 2 hours old</span>"
                  
                platformContent = "<div id=\"popupobs\" class=\"popupobs\"><table class=\"popupobsdata\"><caption>%s</caption>"\
                                % (datetimeLabel)
                               
            
            if(latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['m_value'] != None):
              obsUOM = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['uom']
              value = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['m_value']
              #Get the label we want to use for the observation
              obsLabel = uomConverter.getDisplayObservationName(latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['obs_name'])
              if(obsLabel == None):
                obsLabel = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['obs_name']
              #Get the units we want to convert the data to. This is also used as the label for the units in the text display.
              displayUOM = uomConverter.getConversionUnits( obsUOM, 'en' )
              if(len(displayUOM) == 0):
                displayUOM = obsUOM            
              value = uomConverter.measurementConvert( value, obsUOM, displayUOM )
                
              googURL = self.buildGoogleChartLink(xeniaDb, 
                                                  platform, 
                                                  obsLabel, 
                                                  latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['sensor_id'],
                                                  obsUOM, 
                                                  displayUOM, 
                                                  latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['m_date'], 
                                                  uomConverter)
              
              measureLabel = "%s %s" %(str(value), displayUOM);
              qcLevel = latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['qc_level']
              #Add a bad or suspect label if the quality control flag is set to 1 or 2.
              if(qcLevel == 1):
                measureLabel += "(bad)"
              elif(qcLevel == 2):
                measureLabel += "(suspect)"
              
              platformContent += "<tr %s><td scope=\"row\">%s</td><td>%s</td></tr>"\
                             %(googURL, obsLabel, measureLabel)
                            
          #Finished platform, increment our count.
          platformCnt += 1      
          #Check to see if we had any platform content, if not let's just tag it with nothing available before adding the entry into the
          #database.
          if(len(platformContent) == 0):
            platformContent = "<tr><td>No data available</td></tr>"
            print("Platform has no data, possible inactive station: %s" %(platform))
    
          htmlContent = "%s%s</table><div id=\"popupobsgraph\"></div>" %(contentHeader,platformContent)                          
          
          dbCur = self.addRowToObsTable(insertDate, 
                                        latestObs[operator]['platform_list'][platform]['obs_list'][displayOrder]['local_date'],                                        
                                        latestObs[operator]['platform_list'][platform]['m_lat'], 
                                        latestObs[operator]['platform_list'][platform]['m_lon'],
                                        operator, 
                                        htmlContent, 
                                        platform)
          if(dbCur == None):
            print(xeniaDb.dbConnection.getErrorInfo())
          """                  
          sql = "INSERT INTO html_content(wkt_geometry,organization,html,platform_handle)\
                 values ('POINT(%f %f)','%s','%s', '%s');"\
                 %(latestObs[operator]['platform_list'][platform]['m_lon'], latestObs[operator]['platform_list'][platform]['m_lat'], 
                   operator, 
                   htmlContent, 
                   platform)
          #print("Saving content.\n %s" %(sql))
          
          dbCur = self.executeQuery(sql)
          if(dbCur != None):
            self.db.commit()
          else:
            print(xeniaDb.dbConnection.getErrorInfo())
          """
        operatorCnt += 1
                    
      self.db.commit()
      print("Processed %d operators and %d platforms." %(operatorCnt, platformCnt))
      self.copyToWorkingDB()
    except Exception, E:
      print(traceback.format_exc())
              
    return
  def buildGoogleChartLink(self, xeniaDB, platformHandle, obsName, sensorID, obsUOM, convertedUOM, datetime, uomConverter):
    googleURL = "http://chart.apis.google.com/chart?cht=lc&chco=FFFFFF&chf=bg,s,99b3cc&chls=2,1,0&chg=0,50,1,0&chts=FFFFFF,10&chxt=t,y,x&chxs=0,000000,10,0,lt,000000|1,000000,10|2,000000,10&chxp=0,8,50,100|1,0,50,100|2,50"                  

    #Query the DB and get the last 24 hours of data to use for the google chart.
    #We format the date in a 12 hour time, shifting the time to relate to our locale timezone.
    sql = "SELECT to_char(timezone('UTC', m_date), 'HH12:MI:SS AM') AS date, m_value\
           FROM multi_obs\
           WHERE sensor_id=%d AND\
           (qc_level is null or qc_level!=1) AND\
           m_date >= timestamp '%s' - interval '24 hours'\
           ORDER BY m_date ASC;"\
           %(sensorID, datetime)
    dbCursor = xeniaDB.dbConnection.executeQuery(sql)
    if(dbCursor != None):
      chd    = "";
      minVal = None;
      maxVal = None;
      dates  = [];
      for row in dbCursor:
        date = row['date']
        dates.append(date)
        
        if(len(chd)):
         chd += ',';
         
        val = uomConverter.measurementConvert(row['m_value'], obsUOM, convertedUOM)
        if(val == None):
          val = row['m_value']
        chd += ("%4.2f" %(val))
        if(minVal == None):
          minVal = val
          maxVal = val
        else:
          if(val < minVal):
            minVal = val
          if(val > maxVal):
            maxVal = val

      onClick = "";
      if(len(chd)):
        platformParts = platformHandle.split('.')
        shortName = '';
        
        if(len(platformParts) >= 2):
          shortName = platformParts[1]
          
        #Set the min/max value ranges for the chart.
        chds= "chds=%f,%f" % (minVal,maxVal);        
        #Set the axis labels.
        midPt = int(len(dates)/2)             
        chxl="chxl=0:|%s|%s|%s|1:|%4.2f|%s|%4.2f|2:|24+hr.+%s"\
              %(dates[0], dates[midPt], dates[-1], minVal, convertedUOM, maxVal, obsName)
        googURL = googleURL
      
        #Add the datapoints 
        googURL += "&chd=t:%s&%s&%s" %(chd,chds,chxl) 
        googURL = "onClick=\"javascript:carolinasrcoos.app.googleChart(''%s'',''%s'');\""\
                  %(shortName, googURL)
        return(googURL)

if __name__ == '__main__':
  
  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
      
  parser = optparse.OptionParser()
  parser.add_option("-f", "--ObsTableDB", dest="obsTableDB",
                    help="The SQLite DB to use for storing the current obs." )
  
  parser.add_option("-d", "--dbName", dest="dbName",
                    help="The name of the xenia database to connect to." )
  parser.add_option("-o", "--dbHost", dest="dbHost",
                    help="The xenia database host address to connect to." )
  parser.add_option("-u", "--dbUser", dest="dbUser",
                    help="The xenia database user name to connect with." )
  parser.add_option("-p", "--dbPwd", dest="dbPwd",
                    help="The xenia database password name to connect with." )
  parser.add_option("-b", "--BoundingBox", dest="bbox",
                    help="The bounding box we want to use to select the platforms. Format is: long lat, long lat...."  )
  parser.add_option("-c", "--ConversionFile", dest="uomFile",
                    help="The XML file with the units conversion formulas."  )

  (options, args) = parser.parse_args()
  
  
  
  xeniaDb = dbXenia()
  #(self, dbFilePath=None, user=None, passwd=None, host=None, dbName=None )
  if( xeniaDb.connect(None, options.dbUser, options.dbPwd, options.dbHost, options.dbName) == False ):
    print("Unable to connect to the database: %s" %(xeniaDb.getErrorInfo()))
    sys.exit(-1)
  
  obsDb = dbDisplayLatestObs(options.obsTableDB)
   
  uomConverter = uomconversionFunctions(options.uomFile)
  
  obsDb.buildContent(xeniaDb, uomConverter, options.bbox)
  

