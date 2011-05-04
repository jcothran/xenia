import sys
import optparse

from xeniatools.xenia import dbXenia
from xeniatools.xenia import recursivedefaultdict
from xeniatools.xenia import dbTypes
from xeniatools.stats import stats

class xeniaStats(dbXenia):
  
  def getObsStatsForDate(self, platform, obsName, uom, sOrder, beginDate, endDate):
    obsStats = stats()
    sensorID = self.dbConnection.sensorExists(obsName, uom, platform, sOrder);
    if(sensorID != None and sensorID != -1):
      sql = "SELECT m_date,m_value FROM multi_obs WHERE (m_date >= '%s' AND m_date <= '%s') AND sensor_id=%d"\
            %(beginDate,endDate,sensorID)
      dbCursor = self.dbConnection.executeQuery(sql)
      if(dbCursor != None):
        for row in dbCursor:
          m_value = float(row['m_value'])
          obsStats.addValue(m_value)
        #Calculate the statistics.
        obsStats.doCalculations()
      dbCursor.close() 
    return(obsStats)  
  
  def computeMonthlyDataPoints(self, platformList, beginYear, endYear, QAQCFlags, outputFilePath,writeRawDataPoints):
    import calendar
    
    #If we want to use the qc_level to determine which data to include, let's build the SQL for this.
    #qaqcWHERE = ''
    #if(len(QAQCFlags)):
    #  for qcLevel in QAQCFlags:
    #    if(len(qaqcWHERE)):
    #      qaqcWHERE += 'OR '
    #    qaqcWHERE += "qc_level=%d " % (qcLevel)
    #  qaqcWHERE = "AND (%s)" %(qaqcWHERE)
    for platformHandle in platformList:
      #Get all the observations on the platform
      platformNfoCur = self.dbConnection.getPlatformInfo(platformHandle)
      #Platform doesn't seem to exist, so move on.
      if(platformNfoCur == None):
        continue
      platformNfo = platformNfoCur.fetchone()
      platformID = int(platformNfo['row_id'])
      platformNfoCur.close()
            
      sql= "SELECT\
            obs_type.standard_name \
            ,uom_type.standard_name as uom \
            ,sensor.row_id as sensor_id\
            ,sensor.m_type_id as m_type_id\
            ,sensor.s_order as s_order\
          FROM sensor \
            left join m_type on m_type.row_id=sensor.m_type_id \
            left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id \
            left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id \
            left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id \
            WHERE sensor.platform_id = %d ORDER BY obs_type.standard_name ASC"\
            %(platformID)
      
      sensorCur = self.dbConnection.executeQuery(sql)
      #No sensors available on the platform.
      if(sensorCur == None):
        continue
      sensorNfo = recursivedefaultdict()
      for row in sensorCur:       
        sensorNfo[row['standard_name']]['uom'] = row['uom']
        sensorNfo[row['standard_name']]['sensor_id'] = int(row['sensor_id'])
        sensorNfo[row['standard_name']]['m_type_id'] = int(row['m_type_id'])
        sensorNfo[row['standard_name']]['sorder'] = int(row['s_order'])
      sensorCur.close()
      
      outputFile = "%s/%s-yearly-stats-%s_%s.csv" %(outputFilePath,platformHandle,beginYear,endYear)
      statsFile = open(outputFile,'w')
      statsFile.write('Observation,StartDate,EndDate,Min,Max,Average,StdDev,90thPercentile,TotalRecordCount\n')
      rawDataPoints = None
      if(writeRawDataPoints):
        outputFile = "%s/%s-yearly-raw.csv" %(outputFilePath,platformHandle)
        rawDataPoints = open(outputFile, 'w')
      if(rawDataPoints != None):
        rawDataPoints.write('Observation,StartDate,EndDate,Data\n')
        
      yearList = []
      if(beginYear == None):
        # Get the distinct years
        if(self.dbConnection.dbType == dbTypes.PostGRES):
          sql = "SELECT DISTINCT(EXTRACT(YEAR FROM m_date)) as year FROM multi_obs WHERE platform_handle='%s'" %(platformHandle)
        else:
          sql = "SELECT DISTINCT(strftime('%%Y', m_date)) as year FROM multi_obs WHERE platform_handle='%s'" %(platformHandle)
        dbCursor = self.dbConnection.executeQuery(sql)
        if(dbCursor != None):
          for row in dbCursor:
            yearList.append(int(row['year']))
          dbCursor.close()
      else:
        for i in range(beginYear, endYear+1):
          yearList.append(i)
          
      #This is a dictionary we use to hold all the months of data for the years. We use it as a collection
      #of stats() objects so we can calculate some overall stats for each month over the years.
      #obsOverallMonthStats = recursivedefaultdict()
      print("Processing: %s" % (platformHandle))      
      for year in yearList:
        for obsName in sensorNfo:       
          uom = sensorNfo[obsName]['uom']
          sensorID = sensorNfo[obsName]['sensor_id']
          mTypeID = sensorNfo[obsName]['m_type_id']
          #sOrder = sensorNfo[obsName]['sorder']
          #Now for each month, we calc stats on the data.
          for month in range( 1,13 ):
            print("Obs: %s(%s) Year: %d Month: %d" %(obsName, uom, year, month))       
            monthStats = stats()
            dayCnt = calendar.monthrange(year, month)
            startDate = "%d-%02d-%02dT00:00:00" %(year,month,1)
            endDate = "%d-%02d-%2dT24:00:00" %(year,month,dayCnt[1])
            if(rawDataPoints != None):
              rawDataPoints.write("%s,%s,%s" %(obsName,startDate,endDate))

            
            #mTypeID = self.dbConnection.getMTypeFromObsName(obsName, uom, platformHandle, sOrder)
            #sql = "SELECT m_date,m_value FROM multi_obs WHERE (m_date >= '%s' AND m_date <= '%s')\
            #       AND sensor_id=%d %s;"\
            #      %(startDate,endDate,sensorID,qaqcWHERE)
            sql = "SELECT m_date,m_value,qc_level FROM multi_obs WHERE (m_date >= '%s' AND m_date <= '%s')\
                   AND sensor_id=%d;"\
                  %(startDate,endDate,sensorID)
            dbCursor = self.dbConnection.executeQuery(sql)
            if(dbCursor != None):
              for row in dbCursor:
                goodVal = False
                #Use all data.
                if(len(QAQCFlags) == 0):
                  goodVal = True                
                elif(row['qc_level'] != None):
                  for qaqcFlag in QAQCFlags:
                    if(qaqcFlag == row['qc_level']):
                      goodVal = True
                      break                
                if(goodVal):
                  m_value = row['m_value']
                  if(m_value != None):
                    m_value = float(m_value)
                    monthStats.addValue(m_value)
                    if(rawDataPoints != None):
                      rawDataPoints.write(",%f" %(m_value))
                
              monthStats.doCalculations()
              avg = monthStats.average
              if(avg == None):
                avg = -1.0
              stdDev = monthStats.stdDev
              if(stdDev == None):
                stdDev = -1.0
              popStdDev = monthStats.populationStdDev
              if(popStdDev == None):
                popStdDev = -1.0
                
              UpperPercentile = monthStats.getValueAtPercentile(90)
              if(UpperPercentile == None):
                UpperPercentile = -1.0
              min = monthStats.minVal
              if(min == None):
                min = -1.0
              max = monthStats.maxVal
              if(max == None):
                max = -1.0
                
              statsFile.write('%s,%s,%s,%f,%f,%f,%f,%f,%d\n'\
                              %(obsName,startDate,endDate,min,max,avg,stdDev,UpperPercentile,len(monthStats.items)))
              if(rawDataPoints != None):
                rawDataPoints.write("\n")
            else:
              i = 0
      statsFile.close()    
      if(rawDataPoints != None):
        rawDataPoints.close()
      
      
if __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-b", "--StartYear", dest="startYear",
                      help="The date/time that starts our query")
    parser.add_option("-e", "--EndYear", dest="endYear",
                      help="Optional. If the HoursOffset option is not supplied, this setting must be. It is the date/time to end the query.")
    parser.add_option( "-U", "--User", dest="dbUser",
                       help="User info for PostGres Xenia database")
    parser.add_option( "-d", "--Database", dest="dbName",
                       help="Database name for PostGres Xenia database")
    parser.add_option( "-o", "--Host", dest="dbHost",
                       help="Database host address for PostGres Xenia database")
    parser.add_option( "-W", "--Password", dest="dbPwd",
                       help="Database password for PostGres Xenia database")
    parser.add_option("-q", "--SQLiteDB", dest="sqliteDB",
                      help="The SQLite database to run against" )
    parser.add_option("-f", "--DestinationDir", dest="destDir",
                      help="The destination directory for the output files." )
    parser.add_option("-p", "--PlatformList", dest="platformList",
                      help="The list of platforms to create the stats for." )
    parser.add_option("-c", "--QAQCFlagsToUse", dest="qaqcFlags",
                      help="The quality control flags that must be set to use the data." )
    parser.add_option("-r", "--WriteRawDataPoints", dest="writeRawDataPoints", action= 'store_true',
                      help="Writes the monthly data points to a file." )
    
    
    (options, args) = parser.parse_args()

    db = xeniaStats()
    if(db.connect(options.sqliteDB, options.dbUser, options.dbPwd, options.dbHost, options.dbName)!=True):
      print("Unable to connect to database.")
      sys.exit(-1)
    
    platformList = []
    qaqcFlags = []
    if(options.platformList != None and len(options.platformList)):
      platformList = options.platformList.split(',')
    #No platform list provided, so we will use all the platforms.
    else:
      sql = "SELECT platform_handle FROM platform"
      dbCursor = db.dbConnection.executeQuery(sql)
      platformList = []
      if(dbCursor != None):
        for row in dbCursor:
          platformList.append(row['platform_handle'])
          
    if(options.qaqcFlags != None and len(options.qaqcFlags)):
      tempList = options.qaqcFlags.split(',')
      for flag in tempList:
        qaqcFlags.append(int(flag))
        
    db.computeMonthlyDataPoints(platformList, int(options.startYear), int(options.endYear), qaqcFlags, options.destDir, options.writeRawDataPoints)