import sys
import optparse
import time
import re
sys.path.insert(0, "C:\\Documents and Settings\\dramage\\workspace\\QAQC-ControlChart") 
#from rangeCheck import platformResultsTable
from rangeCheck import loadSettings
from rangeCheck import rangeLimits
from xeniatools.xenia import xeniaPostGres,xeniaSQLite,dbTypes,recursivedefaultdict,qaqcTestFlags
from xeniatools.xmlConfigFile import xmlConfigFile

class googleChart(object):
  def __init__(self):
    #http://chart.apis.google.com/chart?
    #  chs=200x100&      //chart size   
    #  cht=lc&           //chart type
    #  chco=FFFFFF&      //chart color
    #  chf=bg,s,093771&  //background solid fill color
    # chls=2,1,0&       //Line styles
    # chg=0,50,1,0&     //Grid line widths
    # chts=FFFFFF,10&   //Titles color and width
    #  chxt=t,y,x&       //Axis types
    #  chxs=0,000000,10,0,t,000000|1,000000,10|2,000000,10&  //font size, color, and alignment for axis labels
    #  chds=1009.6,1013.3&  //Min/max allowable data ranges
    #  chxp=0,8,50,100|1,0,50,100|2,50& //Axis Label positions
    # chxl=0:|1:00a|7:00a|1:00p|1:|1009.6|mb|1013.3|2:|12+hr.+Air+pressure&  //Axis labels
    # chd=t:1010.0,1009.6,1009.7,1009.7,1010.0,1010.6,1011.3,1011.8,1012.5,1013.0,1013.2,1013.3,1013.2 //Chart data string

    self.initialURL = "http://chart.apis.google.com/chart?cht=lc&chco=FFFFFF&chf=bg,s,99b3cc&chls=2,1,0&chg=0,50,1,0&chts=FFFFFF,10&chxt=t,y,x&chxs=0,000000,10,0,lt,000000|1,000000,10|2,000000,10&chxp=0,8,50,100|1,0,50,100|2,50"
    self.dataPoints = [] #List of the data points we want to plot, the chd param.
    self.limitLines = [] #List of the limit lines we want to drawn. Also goes into the chd param.
    self.minVal     = None
    self.maxVal     = None
    self.axisLabels = ''
    self.axisConfig = ''
    self.graphHeight = 400
    self.graphWidth = 600
  
  def reset(self):
    del self.dataPoints[:]
    del self.limitLines[:]
    self.minVal     = None
    self.maxVal     = None
    self.axisLabels = ''
    self.axisConfig = ''
    self.graphHeight = 400
    self.graphWidth = 600
                                   
  def addDataPoints(self, dataList):
    self.dataPoints.append(dataList)
    
  def addLimitLines(self, limits):
    self.limitLines.append(limits)
  
  def setHeightWidth(self, height,width):
    self.graphHeight = height
    self.graphWidth = width
  
  def setAxisLabels(self,axisLabels):
    self.axisLabels = "&chxl=%s" %(axisLabels)
  def setAxisLabelConfig(self, config):
    self.axisConfig = "&chxt=%s" %(config)
        
  def setChartRange(self, min, max):
    self.chartRange = "&chds=%f,%f" % (min,max
                                       )       
  def buildURL(self):
    url = ''
    #First we go through and add all the data points.
    chd = ''
    pntCnt = 0
    for data in self.dataPoints:
      for point in data:
        if(len(chd)):
          chd += ','
        val = ("%4.2f" %(point))
        chd += val
        pntCnt += 1     
    #If we have limit lines we want to draw, let's put them in.
    for limits in self.limitLines:
      #For the limit lines we need to fabricate a val per data point to make our lines all the way
      #across the graph.
      lo = ''
      hi = ''
      for i in range(0,pntCnt):
        if(len(lo)):
          lo += ','
        lo += ("%4.2f" %(limits.rangeLo))
        if(len(hi)):
          hi += ','
        hi += ("%4.2f" %(limits.rangeHi))
      #The '|' character seperates the points in the data param
      if(len(lo)):
        chd += '|' + lo
      if(len(hi)):
        chd += '|' + hi
    chd = "&chd=t:%s" %(chd)
    
    #Set height/width param
    chs = "&chs=%dx%d" % (self.graphWidth,self.graphHeight)
    
    url = self.initialURL + chd + self.chartRange + chs + self.axisConfig + self.axisLabels
    return(url)                

  def simpleEncode(dataList,maxValue):
    simpleEncoding ='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    chartData = ['s:']
    for point in dataList:
      currentValue = point
      if(currentValue >= 0):
        chartData.push(simpleEncoding.charAt(Math.round((simpleEncoding.length-1) * currentValue / maxValue)))
      else:
        chartData.push('_')
    return chartData.join('')
  
          
class platformResultsTable(object):
  def __init__(self):
    self.table = None
    self.platforms = recursivedefaultdict()
    
  def clear(self):
    self.platforms.clear()
    
  def createHTMLTable(self):
    htmlTable = ''
    try:
      platformKeys = self.platforms.keys()
      platformKeys.sort() 
      #for platformKey in self.platforms.keys():
      for platformKey in platformKeys:    
        if( len(htmlTable) ):
          htmlTable += "<br>"
        htmlTable += "<table border=\"1\">\n"
        #We want to sort the dates
        dateKeys = self.platforms[platformKey].keys()
        dateKeys.sort()
        writeHeader = True
        tableHeader = '<th>Platform</th><th>Date</th><th>Value Labels</th>'
        for dateKey in dateKeys: 
          valuesLabel = "Value</br>QC Flag</br>QC Level"
          tableRow = "<tr>\n<td>%s</td><td>%s</td><td NOWRAP>%s</td>\n" %( platformKey, dateKey, valuesLabel )
          obsKeys = self.platforms[platformKey][dateKey].keys()
          obsKeys.sort()
          for obsKey in obsKeys:
          #for obsKey in self.platforms[platformKey][dateKey]:
            if( writeHeader ):
              if( 'limits' in self.platforms[platformKey][dateKey][obsKey] != False ):
                obsNfo = self.platforms[platformKey][dateKey][obsKey]['limits']
                if( obsNfo != None ):
                  tableHeader += "<th>%s(%s)</th>" %( obsKey, ( ( obsNfo.uom != None ) and obsNfo.uom or '' ) )
                else:
                  tableHeader += "<th>%s()</th>" %( obsKey )
              else:
                tableHeader += "<th>%s()</th>" %( obsKey )
                
            qcLevel = self.platforms[platformKey][dateKey][obsKey]['qclevel']
  
            #The cell background colors are defined in the style sheet(http://carocoops.org/~dramage_prod/secoora/styles/main.css)
            bgColor = "qcDEFAULT"
            if( qcLevel == qaqcTestFlags.NO_DATA):
              bgColor = "qcMISSING"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_NO_EVAL):
              bgColor = "qcNOEVAL"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_BAD):
              bgColor = "qcFAIL"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_SUSPECT):
              bgColor = "qcSUSPECT"
            elif( qcLevel == qaqcTestFlags.DATA_QUAL_GOOD):
              bgColor = "qcPASS"
            if( qcLevel != qaqcTestFlags.NO_DATA ):
              tableRow += "<td id=\"%s\">%4.2f</br>%d</br>%s</td>\n" \
              % (bgColor,
                 ( self.platforms[platformKey][dateKey][obsKey]['value'] != None ) and self.platforms[platformKey][dateKey][obsKey]['value'] or -9999.0,
                 ( self.platforms[platformKey][dateKey][obsKey]['qclevel'] != None ) and self.platforms[platformKey][dateKey][obsKey]['qclevel'] or -9999.0,
                 ( self.platforms[platformKey][dateKey][obsKey]['qcflag'] != None ) and self.platforms[platformKey][dateKey][obsKey]['qcflag'] or -9999.0 )
            else:
              tableRow += "<td id=\"%s\">Data Missing</br>%d</br>000000</td></td>\n" % (bgColor,qaqcTestFlags.NO_DATA)
          tableRow += "</tr>\n"
          if( writeHeader ):
            htmlTable += tableHeader
            writeHeader = False          
          htmlTable += tableRow
        htmlTable += '</table>'
    except Exception, e:
        self.lastErrorMessage = str(e) + ' Terminating script.'

    if( len(htmlTable) == 0 ):
      htmlTable = None
    return( htmlTable )
        
  def addObsQC(self, platform, obsName, date, value, qcLevel, qcFlag, qcLimits=None ):
    self.platforms[platform][date][obsName]['value'] = value
    self.platforms[platform][date][obsName]['qclevel'] = qcLevel
    self.platforms[platform][date][obsName]['qcflag'] = qcFlag
    if( qcLimits != None ):
      self.platforms[platform][date][obsName]['limits'] = qcLimits
    

class qaqcResultsPage(object):
  def __init__(self,htmlFilename,styleSheet):
    self.htmlFilename = htmlFilename
    self.platformResultsTable = platformResultsTable()
    self.platforms = recursivedefaultdict()
    try:
      self.htmlFile = open(self.htmlFilename, "w")
      self.htmlFile.write( "<html>\n" )
      self.htmlFile.write( "<BODY id=\"RGB_BODY_BG\" >\n" )    
      self.htmlFile.write( "<link href=\"%s\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n"  % ( styleSheet ) )
    except IOError, e:
      import sys
      import traceback
      
      info = sys.exc_info()        
      excNfo = traceback.extract_tb(info[2], 1)
      items = excNfo[0]
      lastErrorFile = items[0]    
      lastErrorLineNo = items[1]    
      lastErrorFunc = items[2]        
      print("%s Function: %s Line: %s File: %s" % (str(e), lastErrorFunc, lastErrorLineNo, lastErrorFile)) 
      sys.exit(- 1)

  def close(self):
    self.htmlFile.write( "</html>\n" )
    self.htmlFile.write( "</BODY>\n" )    
    self.htmlFile.close()
      
  def createHTMLTable(self):
    try:
      platformKeys = self.platforms['platform'].keys()
      platformKeys.sort() 
      for platformKey in platformKeys:    
        self.htmlFile.write("<br>")
        self.htmlFile.write("<table border=\"1\">\n")
        #We want to sort the dates
        dateKeys = self.platforms['platform'][platformKey]['date'].keys()
        dateKeys.sort(reverse=True)
        writeHeader = True
        tableHeader = '<th>Platform</th><th>Date</th><th>Value Labels</th>'
        for dateKey in dateKeys: 
          valuesLabel = "Value</br>QC Flag</br>QC Level"
          tableRow = "<tr>\n<td>%s</td><td>%s</td><td NOWRAP>%s</td>\n" %( platformKey, dateKey, valuesLabel )
          sOrderKeys = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'].keys()
          sOrderKeys.sort()
          for sOrderKey in sOrderKeys:
            obsKeys = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'].keys()
            obsKeys.sort()
            for obsKey in obsKeys:
              #print("Platform: %s Obs: %s sOrder: %s" %(platformKey,obsKey,sOrderKey))
              if( writeHeader ):
                
                obsName = obsKey
                if('chartLink' in self.platforms['platform'][platformKey]['sOrder'][sOrderKey]['obsName'][obsKey] != False):
                  obsName = "<A href=\"%s\">%s</A>" %(self.platforms['platform'][platformKey]['sOrder'][sOrderKey]['obsName'][obsKey]['chartLink'],obsKey)
                  
                if( 'limits' in self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'][obsKey] != False ):
                  obsNfo = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'][obsKey]['limits']
                  if( obsNfo != None ):
                    tableHeader += "<th>%s</br>%s</br>%s</th>" %( obsName, ( ( obsNfo.uom != None ) and obsNfo.uom or '' ), sOrderKey )
                  else:
                    tableHeader += "<th>%s()</th>" %( obsName )
                else:
                  tableHeader += "<th>%s()</th>" %( obsName )
                  
              qcLevel = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'][obsKey]['qclevel']
              qcFlag = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'][obsKey]['qcflag']
              value = self.platforms['platform'][platformKey]['date'][dateKey]['sOrder'][sOrderKey]['obsName'][obsKey]['value']
              #The cell background colors are defined in the style sheet(http://carocoops.org/~dramage_prod/secoora/styles/main.css)
              bgColor = "qcDEFAULT"
              if( qcLevel == qaqcTestFlags.NO_DATA):
                bgColor = "qcMISSING"
              elif( qcLevel == qaqcTestFlags.DATA_QUAL_NO_EVAL):
                bgColor = "qcNOEVAL"
              elif( qcLevel == qaqcTestFlags.DATA_QUAL_BAD):
                bgColor = "qcFAIL"
              elif( qcLevel == qaqcTestFlags.DATA_QUAL_SUSPECT):
                bgColor = "qcSUSPECT"
              elif( qcLevel == qaqcTestFlags.DATA_QUAL_GOOD):
                bgColor = "qcPASS"
              if( qcLevel != qaqcTestFlags.NO_DATA ):
                #DWR 2/2/2010
                #if value is None, set it to -9999. Before we had this operation as (value != None) and value or -9999.0.
                #When value was 0, this failed and we ended up with -9999 and not the valid value of 0.
                if( value == None ):
                  value = -9999.0
                tableRow += "<td id=\"%s\">%4.2f</br>%d</br>%s</td>\n" \
                % (bgColor,
                   value,
                   (( qcLevel != None ) and qcLevel or -9999.0),
                   (( qcFlag != None ) and qcFlag or -9999.0 ))
              else:
                tableRow += "<td id=\"%s\">Data Missing</br>%d</br>000000</td></td>\n" % (bgColor,qaqcTestFlags.NO_DATA)
          tableRow += "</tr>\n"
          if( writeHeader ):
            self.htmlFile.write(tableHeader)
            writeHeader = False          
          self.htmlFile.write(tableRow)
      self.htmlFile.write('</table>')
    except Exception, e:
        self.lastErrorMessage = str(e) + ' Terminating script.'
 
        
  def addObsQC(self, platform, obsName, date, value, qcLevel, qcFlag, sOrder, qcLimits=None):
    self.platforms['platform'][platform]['date'][date]['sOrder'][sOrder]['obsName'][obsName]['value'] = value
    self.platforms['platform'][platform]['date'][date]['sOrder'][sOrder]['obsName'][obsName]['qclevel'] = qcLevel
    self.platforms['platform'][platform]['date'][date]['sOrder'][sOrder]['obsName'][obsName]['qcflag'] = qcFlag
    if( qcLimits != None ):
      self.platforms['platform'][platform]['date'][date]['sOrder'][sOrder]['obsName'][obsName]['limits'] = qcLimits
      
  def addChartLink(self, platform, obsName, sOrder, chartUrl):
    self.platforms['platform'][platform]['sOrder'][sOrder]['obsName'][obsName]['chartLink'] = chartUrl
                    
class qaqcHTMLResults(object):
  def __init__(self, dbUser=None, dbName=None, dbHost=None, dbPwd=None, SQLiteDB=None, tablePerPlatform=False,chart=False):
    self.tablePerPlatform = tablePerPlatform    #Flag that specifies whether or not we create a seperate HTML page per platform. True, each platform gets a seperate page, False all results on 1.
    self.chart = chart  #Flag that specifies if we add a URL to a google chart for the observation.
    if(SQLiteDB == None):
      self.xeniaDB = xeniaPostGres()  #Database object.
      if( self.xeniaDB.connect( None, dbUser, dbPwd, dbHost, dbName ) ):
        print( "Successfully connected to Xenia DB: Name: %s at %s\n" % ( dbName, dbHost) )
      else:
        print( "Failed to connect to Xenia DB: Host: %s Name: %s User: %s(%s)\nError: %s"\
                %( dbHost, dbName, dbUser, dbPwd, self.xeniaDB.getErrorInfo() ) )      
        sys.exit(-1)
    else:
      self.xeniaDB = xeniaSQLite()  #Database object.
      if( self.xeniaDB.connect( SQLiteDB ) ):
        print( "Successfully connected to Xenia DB: Name: %s\n" % ( SQLiteDB) )
      else:
        print( "Failed to connect to Xenia DB: %s\nError: %s"\
                %( SQLiteDB, self.xeniaDB.getErrorInfo() ) )      
        sys.exit(-1)
      
    self.obsDataPoints = recursivedefaultdict() #Dictionary keyed on obs and sOrder for each data point. Used to collect the points to graph.
    

  def getsOrders(self,obsName,dateOffset):
    sOrders = []
    sql = "SELECT DISTINCT(s_order) FROM multi_obs \
          left join sensor on sensor.row_id=multi_obs.sensor_id \
          left join m_type on m_type.row_id=multi_obs.m_type_id \
          left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id \
          left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id \
          WHERE \
            %s \
            obs_type.standard_name = '%s' ORDER BY s_order ASC;" %(dateOffset,obsName)
    dbCursor = self.xeniaDB.executeQuery(sql)
    if(dbCursor != None):
      for row in dbCursor:                  
        sOrders.append(row['s_order'])
      dbCursor.close()
    else:
      sOrders = None
    return(sOrders)
     
  def processData(self, testProfilesXML, htmlFilePath, beginDateTime, endDateTime, lastNHours, styleSheetURL):
    platformQAQCSettings = loadSettings()
    platformInfoDict = platformQAQCSettings.loadFromTestProfilesXML(testProfilesXML)
    if(platformInfoDict == None):
      print("No settings loaded from file: %s" % (testProfilesXML))
      sys.exit(-1)
    
    if(self.tablePerPlatform==False):
      fileName = "%s/testresults.html" %(htmlFilePath)
      qaqcResults = qaqcResultsPage(fileName,styleSheetURL)
      
    platformKeys = platformInfoDict.keys()
    platformKeys.sort()
    for platformKey in platformKeys:
      if(self.tablePerPlatform==True):
        fileName = "%s/testresults-%s.html" %(htmlFilePath,platformKey)
        qaqcResults = qaqcResultsPage(fileName,styleSheetURL)
        
      lastDate =''
      platformNfo = platformInfoDict[platformKey]
      #Use N hours back from beginDateTime
      if(lastNHours):
        if(beginDateTime is None):    
          if(self.xeniaDB.dbType == dbTypes.PostGRES):      
            #Get calc the dateOffset from current time - lastNHours we want to query for.
            dateOffset = time.time() - (int(lastNHours) * 3600)
            dateOffset = "%s" % (time.strftime('%Y-%m-%dT%H:00:00', time.gmtime(dateOffset)))
            dateOffset = "m_date >= '%s' AND " %(dateOffset) 
            #dateOffset = "(m_date >= date_trunc('hour',timezone('UTC', now()-interval '%d hours' )) AND\
            #       m_date <= date_trunc('hour',timezone('UTC', now()))) AND "\
            #       % (int(lastNHours))
            
          else:
            dateOffset = "(m_date >= strftime('%%Y-%%m-%%dT%%H:00:00', 'now', '-%d hours') AND\
                   m_date <= strftime('%%Y-%%m-%%dT%%H:00:00', 'now')) AND "\
                   % (int(lastNHours))
             
      else:
        dateOffset = "(m_date >= '%s' AND m_date < '%s') AND " %(beginDateTime,endDateTime)
        
      sql= "SELECT m_date \
            ,multi_obs.platform_handle \
            ,obs_type.standard_name \
            ,uom_type.standard_name as uom \
            ,multi_obs.m_type_id \
            ,m_value \
            ,qc_flag \
            ,qc_level \
            ,sensor.row_id as sensor_id\
            ,sensor.s_order \
          FROM multi_obs \
            left join sensor on sensor.row_id=multi_obs.sensor_id \
            left join m_type on m_type.row_id=multi_obs.m_type_id \
            left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id \
            left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id \
            left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id \
            WHERE\
            %s sensor.row_id IS NOT NULL AND multi_obs.platform_handle = '%s'\
            ORDER BY m_date DESC,obs_type.standard_name ASC" \
            % (dateOffset,platformKey)       
      print("Querying platform: %s for date range: %s." %(platformKey,dateOffset))
      dbCursor = self.xeniaDB.executeQuery(sql)
      if(dbCursor != None):
        rowCnt = 0;
        for row in dbCursor:                  
          dateVal = None
          if( row['m_date'] != None ):
            dateVal = row['m_date']
            #Determine if we were given a datetime object. The psycopg2 connection returns that type, although
            #pysqlite returns just the string since it has no datetime concept.
            if( dateVal.__class__.__name__ == 'datetime' ):
              dateVal = dateVal.__str__()                        
                      
            print(row['standard_name'])
            if( lastDate == None or lastDate != dateVal ):
              #Prime the table with all the obs we should have.
              for name in platformNfo.obsList.keys():
                nfo = platformNfo.getObsInfo(name)
                qaqcResults.addObsQC(platformKey, name, dateVal, None, qaqcTestFlags.NO_DATA, None, nfo.sOrder, nfo)            
                #print( "Priming: %s date: %s sOrder: %s" %(name,dateVal,row['s_order']))
              lastDate = dateVal
            obsNfo = platformNfo.getObsInfo(row['standard_name'])
            #If we don't have a limit for an observation, don't add it to our list.
            if(obsNfo !=None):              
              #print("Adding: %s date: %s sOrder: %s" %(row['standard_name'],dateVal,row['s_order']))
              qaqcResults.addObsQC(platformKey, 
                                   row['standard_name'], 
                                   dateVal, 
                                   row['m_value'], 
                                   row['qc_level'], 
                                   row['qc_flag'], 
                                   row['s_order'], 
                                   obsNfo)
              #If we want to create a chart, we save off various pieces of info, like the data points
              #dates, ect to be able to contruct the chart.
              if(self.chart):
                #Don't have a data point list, so we create it and put it in the dictionary.
                if( (row['standard_name'] in self.obsDataPoints != False) and 
                    (row['s_order'] in self.obsDataPoints[row['standard_name']] != False)):
                  obsList = self.obsDataPoints[row['standard_name']][row['s_order']]['obs']
                  dateList = self.obsDataPoints[row['standard_name']][row['s_order']]['date']
                else:
                  obsList = []
                  dateList = []
                  self.obsDataPoints[row['standard_name']][row['s_order']]['obs'] = obsList    
                  self.obsDataPoints[row['standard_name']][row['s_order']]['date'] = dateList
                  self.obsDataPoints[row['standard_name']][row['s_order']]['limits'] = obsNfo.grossRangeLimits
                  self.obsDataPoints[row['standard_name']][row['s_order']]['uom'] = obsNfo.uom    
                obsList.append(row['m_value'])
                dateList.append(dateVal)                                            
            rowCnt += 1
        print( "Processed: %d rows" %(rowCnt))
      if(self.tablePerPlatform==True):
        if(self.chart):
          self.createChartUrl(platformKey,lastNHours,qaqcResults)
          self.resetChartDict()
        qaqcResults.createHTMLTable()
        qaqcResults.close()     

    if(self.tablePerPlatform==False):
      qaqcResults.createHTMLTable()
      qaqcResults.close()
      
  def resetChartDict(self):
    #We need to delete the lists in the dictionary then finally delete the dictionary.
    for obs in self.obsDataPoints:           
      for sOrder in self.obsDataPoints[obs]:
        if('obs' in self.obsDataPoints[obs][sOrder] != False):
          obsList = self.obsDataPoints[obs][sOrder]['obs']
          del obsList[:]
        if('date' in self.obsDataPoints[obs][sOrder] != False):   
          dateList = self.obsDataPoints[obs][sOrder]['date']
          del dateList[:]
    self.obsDataPoints.clear()           
  def createChartUrl(self, platform,lastNHours,qaqcResults):
    for obs in self.obsDataPoints:
      
      #Create the google chart object.
      chart = googleChart()
      chart.setHeightWidth(400, 600)
      chart.setAxisLabelConfig('t,y,x')
            
      for sOrder in self.obsDataPoints[obs]:
        obsList = self.obsDataPoints[obs][sOrder]['obs']
        limits = self.obsDataPoints[obs][sOrder]['limits']
        #Add a 10% buffer above the high limit and below the lo limit.
        if(limits.rangeHi > 0.0):
          max = limits.rangeHi + (limits.rangeHi * 0.10)
        else:
          max = 0.1
        if(limits.rangeLo > 0):
          min = limits.rangeLo - (limits.rangeLo * 0.10)
        else:
          min = -0.1
        chart.setChartRange(min,max)
        
        #Get min and max values for axis
        #length = len(obsList)
        #min = None
        #max = None
        #for val in obsList:
        #  if(min == None):
        #    min = val
        #    max = val
        #  if(min > val):
        #    min = val
        #  if(max < val):
        #    max = val
        chart.addDataPoints(obsList)
        #chart.addLimitLines(limits)
        dateList = self.obsDataPoints[obs][sOrder]['date']
        length = len(dateList)
        #We want to create some labels on the Y axis instead of just the min and max vals.
        #Get the distance between our hi and lo points.
        #val = abs(max - min)
        #Get our increment
        #i = val / 10.0
        #y = min
        #yAxisLabels = ''
        #while(y <= max):
        #  if(len(yAxisLabels)):
        #    yAxisLabels += '|'
        #  yAxisLabels += "%4.2f" %(y)   
        #  y += i
        
        #Build the axis labels using the google specified format.
        #axisLabels = "0:|%s|%s|%s|1:|%s|2:|%s+hr.+%s" % \
        axisLabels = "0:|%s|%s|%s|1:|%f|%s|%f|2:|%s+hr.+%s" % \
                    (dateList[0],dateList[int(length/2)],dateList[-1],
                     limits.rangeLo, self.obsDataPoints[obs][sOrder]['uom'], limits.rangeHi,
                     lastNHours, obs)
                     
        chart.setAxisLabels(axisLabels)
        url = chart.buildURL()
        qaqcResults.addChartLink(platform, obs, sOrder, url)
        
if __name__ == '__main__':
  
    parser = optparse.OptionParser()
    parser.add_option("-c", "--TestProfilesXML", dest="testProfilesXML",
                    help="The xml file containing the platform control information." )
    parser.add_option("-f", "--HTMLFilepath", dest="htmlFilepath",
                      help="The html file the tables will be output to.")
    parser.add_option("-s", "--StyleSheetURL", dest="styleSheetURL",
                      help="The URL for the style sheet to apply against the html file.")
    parser.add_option("-b", "--BeginDateTime", dest="beginDateTime",
                      help="The date/time that starts our query")
    parser.add_option("-n", "--LastNHours", dest="lastNHours",
                      help="Optional. The number of hours in the past to go back for the query. Applied against the BeginDateTime option.")
    parser.add_option("-e", "--EndDateTime", dest="endDateTime",
                      help="Optional. If the HoursOffset option is not supplied, this setting must be. It is the date/time to end the query.")
    parser.add_option( "-U", "--User", dest="dbUser",
                       help="User info for PostGres Xenia database")
    parser.add_option( "-d", "--Database", dest="dbName",
                       help="Database name for PostGres Xenia database")
    parser.add_option( "-o", "--Host", dest="dbHost",
                       help="Database host address for PostGres Xenia database")
    parser.add_option( "-W", "--Password", dest="dbPwd",
                       help="Database password for PostGres Xenia database")
    parser.add_option( "-t", "--FilePerPlatform", dest="filePerPlatform",action="store_true",default=False,
                       help="If set, this creates an HTML file per platform." )
    parser.add_option( "-g", "--CreateChart", dest="createChart",action="store_true",default=False,
                       help="If set, this creates a Google Chart link for each observation." )
    #DWR 1/29/2010
    #Added option to be able to use a sqlite xenia db
    parser.add_option("-q", "--SQLiteDB", dest="sqliteDB",
                      help="The SQLite database to run against" )
    
    (options, args) = parser.parse_args()
    if(options.testProfilesXML is None or
       options.htmlFilepath is None
      ):
      parser.print_usage()
      parser.print_help()
      sys.exit(-1)
    if(options.dbUser != None and options.dbName != None):
      results = qaqcHTMLResults(options.dbUser, options.dbName, options.dbHost, options.dbPwd, None,
                                options.filePerPlatform, options.createChart  )
    elif(options.sqliteDB != None):
      results = qaqcHTMLResults(None, None, None, None, options.sqliteDB,
                                options.filePerPlatform, options.createChart  )
    else:
      print("Unable to continue. No database connection information provided.")
      parser.print_usage()
      parser.print_help()
      sys.exit(-1)
    #Can provide options of 1 day, 2 days, etc. These options results in starting time being at N days in the past at 00:00:00 and the 
    #end time being at the current days's 00:00:00
    startDateTime = options.beginDateTime
    endDateTime = options.endDateTime    
    if(options.beginDateTime != None and options.beginDateTime.find('day') != -1):
      val = re.findall("(\d{1,2}) day",options.beginDateTime)
      if(len(val) == 0):
        print("Incorrect parameter: %s supplied for BeginDateTime parameter.\n" %(options.beginDateTime))
        sys.exit(-1)
      datetime = time.strftime( '%Y-%m-%dT00:00:00', time.gmtime() )
      endDateTime = time.mktime(time.strptime(datetime, '%Y-%m-%dT00:00:00'))
      #Start time goes back N days where N is the value in val[0]. Convert to seconds.
      startDateTime = endDateTime - (int(val[0]) * (60*60*24))
      endDateTime = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(endDateTime))
      startDateTime = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(startDateTime))
      
    results.processData(options.testProfilesXML, 
                        options.htmlFilepath, 
                        startDateTime, 
                        endDateTime, 
                        options.lastNHours, 
                        options.styleSheetURL)
