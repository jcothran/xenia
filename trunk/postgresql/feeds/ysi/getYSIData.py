import sys
import StringIO
import re
import time
import urllib
import urllib2
from urllib2 import Request, urlopen, URLError, HTTPError
from lxml import etree
from xeniatools.xmlConfigFile import xmlConfigFile
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict
from pykml import kml

"""
Class: ysiParameters
Purpose: This class defines the basic parameters needed when querying a YSI site. From scraping their
website, each customer page has a javascript function: ViewParameterHistory( intNodeID, intAVIID, intParameterID, sAlternateName, intChanIdx )
This class encapsulates the parameters of that function to then build the customer specific url to get
to a data page to scrape.
"""
class ysiParameters:
  def __init__(self):
    self.customerID   = None
    self.nodeID   = None
    self.aviID    = None
    self.paramID  = None
    self.altName  = None
    self.chanNDX  = None
    self.siteName = None

"""
Class: ysiObsSettings
"""
class ysiObsSettings(object):
  """
  Function:__init__(self, dataQueryURL, paramScrapeURL=None, dataParamConfigFile=None)
  Purpose: Initializes the class. 
  Parameters: 
    dataQueryURL this is the url used to go to the individual observation pages for a customer to
      scrape the data from. 
      This is an example url: "http://www.ysieconet.com/public/WebUI/ParameterHistory.aspx?hidCustomerID=%d&amp;hidParameterID=%d&amp;hidNodeID=%d&amp;hidAVIID=%d&amp;hidChanID=%d"
      Note the parameters use printf substitutions.
    paramScrapeURL, is an optional parameter. If this is provided, the class will use the url to scrape for
      the javascript function "ViewParameterHistory" to then pull the parameters used for the dataQueryURL.
    dataParamConfigFile optional xml config file used if the paramScrapeURL is not provided. This is an xml file
      which details out the parameters needed for the dataQueryURL. This is a sample XML entry:
    <parameters>
      <parameter>
          <customerID>131</customerID>
          <nodeID>270</nodeID>
          <aviID>2211</aviID>
          <paramID>2</paramID>
          <altName>Surface Temp. [F]</altName>
          <chanNDX>0</chanNDX>
      </parameter>
    </parameters>      
  """
  def __init__(self, dataQueryURL, paramScrapeURL=None, dataParamConfigFile=None):
    self.dataQueryURL   = dataQueryURL    # The url used to attempt to scrape the observation data.
    self.paramScrapeURL = paramScrapeURL  # The url, if provided, to attempt to get the paramters need for the dataQueryURL url.
    self.paramList      = []              # A list of ysiParameters objects, representing the individual observations.
    self.xmlConfigFilename = dataParamConfigFile # If provided in lieu of the paramScrapeURL url which spells out each observation 
                                                 # parameter needed for the dataQueryURL url.

  def procTraceback(self):
    import traceback
    
    info = sys.exc_info()        
    excNfo = traceback.extract_tb(info[2], 1)
    items = excNfo[0]
    self.lastErrorFile = items[0]    
    self.lastErrorLineNo = items[1]    
    self.lastErrorFunc = items[2]    
  """
  Function: initList
  Purpose: Initializes the list of observations a given customer site has. This is driven either from the 
    xml configuration file, or from directly scraping a page looking for the ViewParameterHistory function.
    The self.paramList list is populated with all the entries.
  Parameters:
    None
  Return:
    None
  """
  def initList(self):
    #If we have a configuration file that spells out the parameters.
    if(self.xmlConfigFilename != None):
      paramList = xmlConfigSettings.getListHead("//parameters")
      for child in xmlConfigSettings.getNextInList(paramList):
        param = ysiParameters()
        param.customerID= int(xmlConfigSettings.getEntry( 'customerID', child ))
        param.nodeID   = int(xmlConfigSettings.getEntry( 'nodeID', child ))
        param.aviID    = int(xmlConfigSettings.getEntry( 'aviID', child ))
        param.paramID  = int(xmlConfigSettings.getEntry( 'paramID', child ))
        param.altName  = xmlConfigSettings.getEntry( 'altName', child )
        param.chanNDX  = int(xmlConfigSettings.getEntry( 'chanNDX', child ))
        self.paramList.append(param)  
    #We are going to scrape the various parameters from the web page directly to build our obs list.    
    elif(self.paramScrapeURL != None):
      self.scrapeObsInfo(self.paramScrapeURL)
  
  """
  Function: scrapeObsInfo
  Purpose: Scours the given url for the ViewParameterHistory function to disassemble it to get the parameters
    needed. The function should be of the form: ViewParameterHistory( intNodeID, intAVIID, intParameterID, sAlternateName, intChanIdx )
  Parameters:
    url is the url to scrape.
  Return:
    True if successful, otherwise False.
  """
  def scrapeObsInfo(self, url):
    custID = re.findall("hidCustomerID=\d{1,3}",url)
    if( len(custID) ):
      customerID = custID[0]
      customerID = customerID.replace("hidCustomerID=", "")
      customerID = int(customerID)
    else:
      return(False) 
    request = urllib2.Request(url)
    response = urllib2.urlopen(request)
    data = response.read()
    #At the top of the HTML file, there is a text field that tells us what site we are looking at:
    #"You are here: NERRS / Grand Bay NERRS / S.W.A.M.P. / Crooked Bayou Uplink" This regexp
    #parses the page looking for it.
    loc = re.findall("<b>(You are here<\/b>.*)(<\/span>)", data)
    location = None
    if(len(loc)):
      location = loc[0][0].split("/")
      location = location[-1]
    #We are looking for the javascript calls that match this:
    #ViewParameterHistory(551,2210,6,'SpCond [mS/cm]',0)
    list = re.findall('ViewParameterHistory\(.*?\)', data)    
    #Now let's loop through, pull apart the function parameters and build out settings list.
    for func in list:
      #Check to see if we have the function declaration, if so we skip that one.
      if( func.find('intNodeID') == -1 ):
        #let's get rid of everything but the bits we are interested in.
        params = func.replace("ViewParameterHistory", "")
        params = params.replace("(", "")
        params = params.replace(")", "")
        parmList = params.split(",")
        #Now let's build the settings list.
        #ViewParameterHistory( intNodeID, intAVIID, intParameterID, sAlternateName, intChanIdx )
        param = ysiParameters()
        param.siteName  = location
        param.customerID= customerID 
        param.nodeID    = int(parmList[0])
        param.aviID     = int(parmList[1])
        param.paramID   = int(parmList[2])
        param.altName   = parmList[3]
        param.altName   = param.altName.replace("'", "")
        param.chanNDX   = int(parmList[4])
        self.paramList.append(param)              
    return(True)
  """
  Function: getObservationsForParameter
  Purpose: For the given ysiParameters object, this function uses the self.dataQueryURL url to scrape the
    screen to get the data. The key to this working is a table with an id of "dgParamHistory" which 
    contains the table of the last N entries. The table has 2 columns, Local Time and Value.
  Parameters:
    ysiParam is the ysiParameters object used to populate the data query URL.
  Returns:
    A list populated with the data scraped from the page.
  """
  def getObservationsForParameter(self,ysiParam):
    obsList = []
    #hidCustomerID=%d&hidParameterID=%d&hidNodeID=%d&hidAVIID=%d&hidChanID=%d"
    url = ( self.dataQueryURL % (ysiParam.customerID,ysiParam.paramID,ysiParam.nodeID,ysiParam.aviID,ysiParam.chanNDX))
    request = urllib2.Request(url)
    response = urllib2.urlopen(request)
    data = response.read()
    #Break the HTML page apart using the 'table' string as the matching word. We
    #end up with a list of table entries.
    splitData=data.split('table')
    #Now we search for the string"dgParamHistory" since that seems to be in the table
    #that contains the parameter data we are interested in.
    for row in splitData:
      if( row.find('dgParamHistory') > 0 ):
        splitData = "<table%stable>" %(row)
        splitData = splitData.replace("&nbsp;", "")
        break
    html = StringIO.StringIO(splitData)
    tableHead = xmlConfigFile(html)
    rowList = tableHead.getListHead("//table")
    #We want to clean up the date/time text so we use regexp to retrieve just that.
    date = re.compile('(\d\d\/\d\d\/\d\d\d\d\s\d\d\:\d\d\s(AM|PM))')
    val = re.compile('\s')
    row = 0
    for child in tableHead.getNextInList(rowList):
      tag = child.xpath( 'td' )
      #First row is the header, so skip it.
      if(row > 0):
        if(len(tag) >=2):
          col1 = date.findall(tag[0].text)
          col2 = val.sub('', tag[1].text)
          #Create date/time, value tuple.
          obsList.append([col1[0][0],col2])
      row += 1
    return(obsList)
  """
  Function: getAllObservations
  Purpose: Loops through the self.paramList list of ysiParameters attempting to go to the data url and 
    scrape the observation data.
  Parameters:
    None
  Returns:
    A dictionary keyed by the ysi observation name for all the observations scraped.
  """
  def getAllObservations(self):
    obsDict = {}
    for param in self.paramList:
      obsList = self.getObservationsForParameter(param)
      obsDict[param.altName] = obsList
    return(obsDict)
  
class ysiDataCollection(object):
  """
  Function: __init__
  Purpose: Initializes the object using the xmlConfigFilename object. The following is an example entry
   describing a YSI customer and the various parameters we need to successfully scrape the observation data. 
   <environment>
    <ysiSettingsList>
      <ysiSetting>
        <name>nerrs_bangslake_wq</name>
        <geoLoc>30.3571,-88.4629</geoLoc>
        <platformURL>http://www.ysieconet.com/public/WebUI/Default.aspx?hidCustomerID=74</platformURL>
        <paramScrapeURL>http://www.ysieconet.com/public/WebUI/DataPlotsDetails.aspx?hidNodeID=550&amp;hidCustomerID=74</paramScrapeURL>
        <dataQueryURL>http://www.ysieconet.com/public/WebUI/ParameterHistory.aspx?hidCustomerID=%d&amp;hidParameterID=%d&amp;hidNodeID=%d&amp;hidAVIID=%d&amp;hidChanID=%d</dataQueryURL>
        
        <outputs>
          <output>
            <type>csv</type>
            <filename>BangsLake.csv</filename>
          </output>
        </outputs>
      </ysiSetting>      
   </environment>
  """
  def __init__(self, xmlConfigFilename):
    configSettings = xmlConfigFile(xmlConfigFilename)
    self.siteSettings = recursivedefaultdict() # Hash of various parameters for each customer site to process.
    paramList = configSettings.getListHead("//environment/ysiSettingsList")
    for child in configSettings.getNextInList(paramList):
      siteName = configSettings.getEntry("name",child)
      geoLoc   = configSettings.getEntry("geoLoc",child)
      self.siteSettings[siteName]['latitude']      = 0.0
      self.siteSettings[siteName]['longitude']     = 0.0
      if(geoLoc != None):
        latLong  = geoLoc.split(',')
        self.siteSettings[siteName]['latitude']      = latLong[0]
        self.siteSettings[siteName]['longitude']     = latLong[1]
        
      self.siteSettings[siteName]['url']           = configSettings.getEntry("platformURL",child)  
      self.siteSettings[siteName]['ysiconfigfile'] = configSettings.getEntry("ysiParamFile",child)  
      self.siteSettings[siteName]['outputtype']    = configSettings.getEntry("outputs/output/type",child)
      self.siteSettings[siteName]['outputfilename']= configSettings.getEntry("outputs/output/filename",child)
      self.siteSettings[siteName]['paramScrapeURL']= configSettings.getEntry("paramScrapeURL",child)
      self.siteSettings[siteName]['dataQueryURL']  = configSettings.getEntry("dataQueryURL",child)
    self.unitsConversionFile = configSettings.getEntry("//environment/unitsConversion/file")
  
  """
  Function: processSites
  Purpose: Processes the various customer entries in the self.siteSettings dictionary.
  Parameters: 
    None
  Returns:  
    None 
  """
  def processSites(self):
    for siteName in self.siteSettings:
      print("Processing site: %s" %(siteName))
      obsHash = self.getRemoteData(siteName, self.siteSettings[siteName])
      if(self.siteSettings[siteName]['outputtype'] == 'kml'):
        self.createKML( siteName, 
                        self.siteSettings[siteName]['outputfilename'],
                        obsHash
                      )
      elif(self.siteSettings[siteName]['outputtype'] == 'csv'):
        self.createCSV(siteName, 
                        self.siteSettings[siteName]['outputfilename'],
                        obsHash
                      )        
  
  """
  Function: getRemoteData
  Purpose: Using the dataQueryURL entry in the siteSetting hash, this function attempts to pull the webpage storing the 
    individual observations for the customer and scrap the observation data.
  Parameters:
    siteName is the customer site being processed.
    siteSetting is a hash containing the parameters used to process that site.
  Returns:
    A hash of the observations. This hash is keyed as follows:
        obsHash[siteName][date][obs][elev][sOrder]['value'] 
        obsHash[siteName][date][obs][elev][sOrder]['uom'] 
    
  """
  def getRemoteData(self, siteName, siteSetting):    
    print("Getting remote data for: %s" %(siteName))
    uomConvert = uomconversionFunctions(self.unitsConversionFile)
    if(siteSetting['ysiconfigfile'] != None):     
      ysi = ysiObsSettings(siteSetting['dataQueryURL'], None, siteSetting['ysiconfigfile'])
    elif(siteSetting['paramScrapeURL'] != None):
      ysi = ysiObsSettings(siteSetting['dataQueryURL'], siteSetting['paramScrapeURL'], None)
      
    ysi.initList()
    obsDict = ysi.getAllObservations()    
    obsHash = recursivedefaultdict()     
    obsHash['platform'][siteName]['url'] = siteSetting['url']
    obsHash['platform'][siteName]['latitude'] = siteSetting['latitude']
    obsHash['platform'][siteName]['longitude'] = siteSetting['longitude']
    for param in obsDict:
      #The ysi observation name has the name and units all in one string. This function
      #converts the obs name into our data dictionary name, and breaks out the units as well.
      (obs,fromUOM,sOrder) = self.convertToXeniaObsAndUOM(param)
      #Didn't have a match, so we'll use the source.
      if(len(obs) == 0):
        parts = param.split('[')
        obs = parts[0]
        fromUOM = parts[1]
        fromUOM = fromUOM.replace("]", "")
        sOrder = "1"
      elev = "0"
      dataTuple = obsDict[param]
      #Now see if we need to convert into different units.
      toUOM = uomConvert.getConversionUnits(fromUOM, 'metric')
      for entry in dataTuple:
        date = entry[0]
        date = self.formDBDate(date)
        value = float(entry[1])
        if(toUOM != None and len(toUOM)):
          convertedVal = uomConvert.measurementConvert(value, fromUOM, toUOM)
          if(convertedVal != None ):
            value = convertedVal
        else:
          toUOM = fromUOM
        #Build the obs hash.
        obsUOM = "%s.%s" %(obs,toUOM)
        obsHash['platform'][siteName]['date'][date]['obsuom'][obsUOM]['elev'][elev]['sorder'][sOrder]['value'] = value
        #obsHash[siteName][date][obs][elev][sOrder]['uom'] = toUOM
        
    return(obsHash)
  """
  Function: createCSV
  Purpose: Creates a CSV file for the data provided in the obsHash hash.
  Parameters:
    siteName is the platform we are processing.
    csvFilename is the name of the CSV file to create.
    obsHash is a hash with all the measurement data.
  """
  def createCSV(self, siteName, csvFilename, obsHash):
    print( "Creating CSV file for: %s" %(siteName))    
    try:
      csvFile = open(csvFilename, "w")
      #Write the header line
      csvFile.write("platform_handle,observation_type.unit_of_measure,time,latitude,longitude,depth,measurement_value,data_url,operator_url,platform_url\n")
      
      #Now let's run through the hash to build the CSV file.    
      platformKeys = obsHash['platform'].keys()
      for platform in platformKeys:
        latitude    = obsHash['platform'][platform]['latitude']
        longitude   = obsHash['platform'][platform]['longitude']
        platformUrl = obsHash['platform'][platform]['url']
        
        dateKeys = obsHash['platform'][platform]['date'].keys()
        #We want to sort the dates
        dateKeys.sort()
        for dateKey in dateKeys:       
          #Sort the observation names.
          obsKeys = obsHash['platform'][platform]['date'][date]['obsuom'].keys()
          obsKeys.sort()
          for obsKey in obsKeys:
            for elev in obsHash['platform'][platform]['date'][date]['obsuom'][obsKey]:
              for sorder in obsHash['platform'][platform]['date'][date]['obsuom'][obsKey]['elev'][elev]:
                value = (obsHash['platform'][platform]['date'][date]['obsuom'][obsKey]['elev'][elev]['value'])
                obsUOM = obsKey.split('.')
                obsName = obsUOM[0]
                uom = ''
                if(len(obsUOM) > 1):
                  uom = obsUOM[1]       
                obsElev = "%s" %(elev)
                csvFile.write("%s,%s.%s,%s,%f,%f,%d,%f,%s,%s,%s\n"\
                              %(platform,obsName,uom,dateKey,latitude,longitude,0,value,"","",platformUrl))    
      csvFile.close()
    except Exception, e:
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
      
  """
  Function: createKML
  Purpose: Creates an obsKML file for the data provided in the obsHash hash.
  Parameters:
    siteName is the platform we are processing.
    kmlFilename is the name of the obsKML file to create.
    obsHash is a hash with all the measurement data.
  """
  def createKML(self, siteName, kmlFilename, obsHash):
    print( "Creating KML file for: %s" %(siteName))
    try:    
      #Create kml document.
      ysiKML = kml.KML()
      doc = ysiKML.createDocument(siteName)
              
      #Now let's run through the hash to build the KML file.    
      platformKeys = obsHash['platform'].keys()
      for platform in platformKeys:
        latitude    = float(obsHash['platform'][platform]['latitude'])
        longitude   = float(obsHash['platform'][platform]['longitude'])
        platformUrl = obsHash['platform'][platform]['url']
        
        dateKeys = obsHash['platform'][platform]['date'].keys()
        #We want to sort the dates
        dateKeys.sort()
        for dateKey in dateKeys:       
          desc = ""
          pmTag = ysiKML.createPlacemark( siteName, latitude, longitude, desc, None, None, None, None, None, True, None, dateKey)
                
          metadataTag = ysiKML.xml.createElement("Metadata")    
                
          obslistTag = ysiKML.xml.createElement("obsList")
          
          urlTag = ysiKML.xml.createElement("platformUrl")
          urlTag.appendChild(ysiKML.xml.createTextNode(platformUrl))
          obslistTag.appendChild(urlTag)
              
          #Sort the observation names.
          obsKeys = obsHash['platform'][platform]['date'][dateKey]['obsuom'].keys()
          obsKeys.sort()
          for obsKey in obsKeys:
            for elev in obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev']:
              for sorder in obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev'][elev]['sorder']:
                value = ("%f" % (obsHash['platform'][platform]['date'][dateKey]['obsuom'][obsKey]['elev'][elev]['sorder'][sorder]['value']))       
                obsUOM = obsKey.split('.')
                obsName = obsUOM[0]
                uom = ''
                if(len(obsUOM) > 1):
                  uom = obsUOM[1]       
                obsElev = "%s" %(elev)
                obsTag = self.addObsToKML(ysiKML, obsName, uom, value, sorder, obsElev)    
                obslistTag.appendChild(obsTag)
          metadataTag.appendChild(obslistTag)
          pmTag.appendChild(metadataTag)
          doc.appendChild(pmTag)
  
      ysiKML.root.appendChild(doc)
  
      kmlFile = open(kmlFilename, "w")
      kmlFile.writelines(ysiKML.writepretty())
      kmlFile.close()
    except Exception, e:
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
          
  def addObsToKML(self, kmlObject, obsName, uom, obsValue, sOrder, obsElev):
    obs = kmlObject.xml.createElement("obs")
    obsType = kmlObject.xml.createElement("obsType")
    obsType.appendChild(kmlObject.xml.createTextNode(obsName))
    obs.appendChild(obsType)
    
    value = kmlObject.xml.createElement("value")
    value.appendChild(kmlObject.xml.createTextNode(obsValue))
    obs.appendChild(value)

    uomType = kmlObject.xml.createElement("uomType")
    uomType.appendChild(kmlObject.xml.createTextNode(uom))
    obs.appendChild(uomType)

    elev = kmlObject.xml.createElement("elev")
    elev.appendChild(kmlObject.xml.createTextNode(obsElev))
    obs.appendChild(elev)

    sorder = kmlObject.xml.createElement("sorder")
    sorder.appendChild(kmlObject.xml.createTextNode(sOrder))
    obs.appendChild(sorder)
    
    return(obs)

  """
  Function: formDBDate
  Purpose: Takes the YSI formated date and converts it into a database friendly ISO date.
  Parameters:
    date is the YSI date to convert.
  Returns:
    The database date string.
  """
  def formDBDate(self, date):
    try:

      datetime = time.strptime(date, "%m/%d/%Y %H:%M %p")
      dbDateTime = time.strftime("%Y-%m-%d %H:%M:00", datetime)
      return(dbDateTime)
    
    except Exception, e:
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
    
  """
  Function: convertToXeniaObsAndUOM
  Purpose: For the given ysi observation name, this function will attempt to convert it into a Xenia data dictionary version.
  Parameters:
    ysiObsName is the string representing the YSI observation name.
  Returns:
    obs representing the xenia data dictionary name, or an empty string if none found.
    uom represents the xenia unit of measurement, or an empty string if none found.
    sOrder is the sensor order, or an empty string if none found.
  """
  def convertToXeniaObsAndUOM(self, ysiObsName):
    obs = ''
    uom = ''
    sOrder = ''
    if( ysiObsName == 'Surface Temp. [F]' ):     
      obs = "water_temperature"
      uom = "fahrenheit"
      sOrder = "1"
    elif( ysiObsName == 'Salinity [ppt]' ):
      obs = "salinity"
      uom = "ppt"
      sOrder = "1"
    elif( ysiObsName == 'Surface Salinity [ppt]' ):
      obs = "salinity"
      uom = "ppt"
      sOrder = "1"
    elif( ysiObsName == 'Surface DO [%]' ):
      obs = "oxygen_concentration"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'Bottom Temp. [F]' ):
      obs = "oxygen_concentration"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'Bottom Salinity [ppt]' ):
      obs = "oxygen_concentration"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'DO% [%]' ):
      obs = "oxygen_concentration"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'Bottom DO [%]' ):
      obs = "oxygen_concentration"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'Surface DO Conc [mg/L]' ):
      obs = "oxygen_concentration"
      uom = "mg_L-1"
      sOrder = "1"
    elif( ysiObsName == 'DO Conc [mg/L]' ):
      obs = "oxygen_concentration"
      uom = "mg_L-1"
      sOrder = "1"
    elif( ysiObsName == 'Bottom DO Conc [mg/L]' ):
      obs = "oxygen_concentration"
      uom = "mg_L-1"
      sOrder = "2"
    elif( ysiObsName == 'BP [inHg]' ):
      obs = "air_pressure"
      uom = "inches_mercury"
      sOrder = "1"
    elif( ysiObsName == 'RH [%]' ):
      obs = "relative_humidity"
      uom = "percent"
      sOrder = "1"
    elif( ysiObsName == 'Air Temp [F]' ):
      obs = "air_temperature"
      uom = "fahrenheit"
      sOrder = "1"
    elif( ysiObsName == 'Temp [C]'):
      obs = "water_temperature"
      uom = "celsius"
      sOrder = "1"
    elif( ysiObsName == 'SpCond [mS/cm]'):
      obs = "water_conductivity"
      uom = "mS_cm-1"
      sOrder = "1"      
    elif( ysiObsName == 'Wind Speed [mph]' ):
      obs = "wind_speed"
      uom = "mph"
      sOrder = "1"
    elif( ysiObsName == 'Rainfall [in]' ):
      obs = "precipitation"
      uom = "inches"
      sOrder = "1"
    elif( ysiObsName == 'Wind Direction []' ):
      obs = "wind_from_direction"
      uom = "degrees_true"
      sOrder = "1"
    elif( ysiObsName == 'pH [ ]' ):
      obs = "ph"
      uom = ""
      sOrder = "1"
    elif( ysiObsName == 'Depth [m]' ):
      obs = "depth"
      uom = "m"
      sOrder = "1"
    elif( ysiObsName == 'Turbidity+ [NTU]' ):
      obs = "turbidity"
      uom = "ntu"
      sOrder = "1"
    elif( ysiObsName == 'Battery [V]' ):
      obs = "battery_voltage"
      uom = "V"
      sOrder = "1"
    return(obs,uom,sOrder)


if __name__ == '__main__':
  try:
    ysiConvert = ysiDataCollection(sys.argv[1])
    ysiConvert.processSites()
  except Exception, e:
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
