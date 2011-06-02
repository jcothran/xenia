import sys
import os
import optparse
import time
import traceback
from xeniatools.xenia import dbXenia
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict
from xeniatools.xenia import statusFlags
from xeniatools.xmlConfigFile import xmlConfigFile
 





class platformMetaData(object):
  def __init__(self, dbUser, dbPwd, dbHost, dbName, uomFile, platformSettingsXMLFile):
    self.lastErrorMsg = ''
    self.xeniaDb = dbXenia()
    if( self.xeniaDb.connect(None, dbUser, dbPwd, dbHost, dbName) == False ):
      print("Unable to connect to the database: %s" %(self.xeniaDb.dbConnection.getErrorInfo()))
      sys.exit(-1)
    else:
      print("Sucessfully connected to DB: %s @ %s" % (dbName, dbHost))
    
    self.uomConverter = uomconversionFunctions(uomFile)
    self.settingsFile = xmlConfigFile(platformSettingsXMLFile)
    #Build the icon list. We use the id in the platform metadata then have a mapping from the id
    #to the string in our lookup table. in the iconMap variable we have a string associated with the id.    
    id = 0
    self.iconList = {}
    self.iconMap = {}
    iconsHead = self.settingsFile.getListHead('icons')
    for icon in self.settingsFile.getNextInList(iconsHead):
      url = self.settingsFile.getEntry('imageUrl',icon)
      if(url != None):
        self.iconList[id] = url
      typeList = self.settingsFile.getListHead('typeList', icon)
      for type in self.settingsFile.getNextInList(typeList):        
        type = type.text;
        #We create a basic mappping that uses the station types we have and associates the id from the iconList for the
        #image to use. We can override this base functionality in the platform settings xml file by supplying a <platform id="x.y.z"><icon>
        #config in the file.
        if(type != None):
          self.iconMap[type] = id
          
      id += 1
    #Get the base links for the various(twitter, georss, ...) webpages the platform has for displaying 
    #data.
    self.baseLinks = {}
    head = self.settingsFile.getListHead('//platformSettings/externalPages')
    id = 0
    for url in self.settingsFile.getNextInList(head):
      urlInfo = {}
      urlInfo['type'] = self.settingsFile.getEntry('name',url)
      urlInfo['url'] = self.settingsFile.getEntry('url',url)
      urlInfo['tip'] = self.settingsFile.getEntry('tooltip',url)
      self.baseLinks[id] = urlInfo
      id += 1
    """
    head = self.settingsFile.getListHead('urls')
    id = 0
    for url in self.settingsFile.getNextInList(head):
      urlInfo = {}
      urlInfo['type'] = url.tag
      urlInfo['url'] = url.text
      self.baseLinks[id] = urlInfo
      id += 1
    """  
  def setDataJsonUrl(self, dataURL):
    self.jsonDataUrl = dataURL
  
  def createLookup(self, tableName, lookupKeyName, columns):
    lookup = {}
    
    #columns is a list of columns we want from the database. The line below assings the 
    #variable cols to a string which is created by iterating through the columns list, separating
    #each column name with a ","  
    cols = ",".join(map(str,columns))
    sql = "SELECT %s FROM %s ORDER BY %s;" % (cols,tableName,lookupKeyName)
    
    dbCursor = self.xeniaDb.dbConnection.executeQuery( sql )        
    if(dbCursor != None):
      for row in dbCursor:
        table = {}
        for col in columns:
          #Don't add the lookupKeyName since the dictionary is keyed on it, it would just duplicate data.
          if(col != lookupKeyName):
            table[col] = row[col]
        lookup[row[lookupKeyName]] = table
      dbCursor.close()  
    else:
      print( self.xeniaDb.dbConnection.getErrorInfo() )
      sys.exit(-1)
    return(lookup)
  
  def createOrganizationLookup(self):
    return(self.createLookup('organization', 'row_id', ['row_id','short_name', 'url']))
  
  def createObsLookup(self):
    obsList = self.createLookup('obs_type', 'row_id', ['row_id', 'standard_name'])
    for obsId in obsList:
      displayLabel = self.uomConverter.getDisplayObservationName(obsList[obsId]['standard_name'])
      if(displayLabel == None):
        displayLabel = obsList[obsId]['standard_name']
      obsList[obsId]['display'] = displayLabel
    return(obsList)
    
  def createUOMLookup(self):
    uomList = self.createLookup('uom_type', 'row_id', ['row_id','standard_name','display'])
    for uomId in uomList:      
      imperialUOM = self.uomConverter.getConversionUnits( uomList[uomId]['standard_name'], 'en' )
      displayUOM = self.uomConverter.getUnits( uomList[uomId]['standard_name'], imperialUOM )
      if(displayUOM == None):
        displayUOM = uomList[uomId]['display']
      uomList[uomId]['imperial'] = displayUOM    
    return(uomList)
  
  def createIconLookup(self):
    iconLookup = {}
    iconLookup['icons'] = self.iconList
    return(iconLookup)
  
  def createURLLookup(self):
    #urlLookup = {}
    #urlLookup['jsonDataURL'] = self.jsonDataUrl    
    return(self.baseLinks)
  
  def buildLookupTables(self):
    lookups = {}
    
    lookup = {}  
        
    lookup = {}  
    lookups['data_url'] = self.createURLLookup()
    
    lookup = {}  
    lookups['icon_urls'] = self.createIconLookup()
    
    return(lookups)
  
  def getPlatformsInPolygon(self, polygon):
    
    platformMetadata = {}
    
    orgLookup = {}
    obsLookup = {}
    uomLookup = {}    
    #Create buckets for each platform type we want to group together.
    #Each type is a FeatureCollection, with the features being the platforms.
    platformTypes = {}
    platformTypes['radar'] = {}          
    platformTypes['insitu'] = {}            
    
    sql = "SELECT\
          platform.short_name,platform.platform_handle,platform.fixed_longitude,platform.fixed_latitude,platform.active,platform.url,\
          platform.description as platform_desc,\
          platform.organization_id AS organization_id,\
          platform_type.type_name AS platform_type,\
          organization.short_name as organization_short_name,\
          organization.url as organization_url\
          FROM platform\
          LEFT JOIN organization ON platform.organization_id = organization.row_id\
          LEFT JOIN platform_type ON platform.type_id = platform_type.row_id\
          WHERE\
            platform.active <3 AND\
            Contains( GeomFromText( \'POLYGON((%s))\'), GeomFromText( 'POINT(' || fixed_longitude || ' ' || fixed_latitude ||')' ) )\
          ORDER BY platform_handle ASC;"\
          %(polygon)
    dbCursor = self.xeniaDb.executeQuery( sql )        
    if(dbCursor != None):
      for row in dbCursor:
        #Get the platform handle and split it into organization, name, type parts.
        platformHandle = row['platform_handle'].split('.')
        
        feature = {}
        feature['type'] = 'Feature'
        geometry = {}
        geometry['type'] = 'Point'
        geometry['coordinates'] = [row['fixed_longitude'],row['fixed_latitude']]
        feature['geometry'] = geometry
        
        property = {}
        property['staID']       = row['platform_handle']
        property['staDesc']     = row['platform_desc']
        property['orgName']     = row['organization_id']
        property['staURL']      = row['url']
        property['staTypeName'] = platformHandle[2]
        
        icon = self.getPlatformIcon(row['platform_handle'], row['platform_type'])

        property['staTypeImage']= icon
        obsList = self.getObservationForPlatform(row['platform_handle'], obsLookup, uomLookup)
        property['staObs']=obsList
        #Build the various links to external data pages.
        self.getPlatformLinks(row['platform_handle'], property)
        
        #Check the active field to see if there is a status event we need to use.
        if(row['active'] != statusFlags.ACTIVE):
          status = self.xeniaDb.dbConnection.getPlatformStatus(row['platform_handle'])
          if(status != None):
            property['status'] = status
            
        feature['properties'] = property
               
        #Here we check to see if we have the FeatureCollection buckets for a station type. Currently we have radar and
        #insitu stations in the database.
        platformType = 'insitu'
        if(feature['properties']['staTypeName'] == 'radar'):
          platformType = 'radar'
        #Now let's get the features array of our FeatureCollection dictionary. If it doesn't exist, we add it.
        features = []
        if('type' in platformTypes[platformType] != False):
          features = platformTypes[platformType]['features']          
        #The type doesn't have a FeatureCollection dictionary yet, so we add it as well as the features array.
        else:
          platformTypes[platformType]['type'] = 'FeatureCollection' 
          platformTypes[platformType]['features'] = features 
          platformTypes[platformType]['layeroptions'] = ''

        features.append(feature)
        
        orgId = row['organization_id']
        if(len(orgLookup) == 0 or (orgLookup.has_key(orgId) == False)):
          table = {}
          table['short_name'] = row['organization_short_name'].upper()
          table['url'] = row['organization_url']

          orgLookup[orgId] = table
        
      #featureCollection['features'] = features      

    else:
      print( self.xeniaDb.dbConnection.getErrorInfo() )
      sys.exit(-1)
      
    #platformMetadata['platforms'] = platformTypes
    #platformMetadata['platforms'] = featureCollection
    return(platformTypes, obsLookup, uomLookup, orgLookup)
  
  def getPlatformIcon(self, platformHandle, platformType):
    iconId = None
    platformHandle = platformHandle.split('.')
    #Check to see if we have an override for the specific platform.
    tag = "//platformSettings/platforms/platform[@id=\"%s.%s.%s\"]/icon" %(platformHandle[0],platformHandle[1],platformHandle[2])
    icon = self.settingsFile.getEntry(tag)    
    if(icon != None):
      #Got an icon, now we need to find the integer ID for it.
      for id in self.iconList:
        if(self.iconList[id] == icon):
          iconId = id
          break
    else:
      #Check to see if we have wildcarded a group of platforms.
      tag = "//platformSettings/platforms/platform[@id=\"%s.*.%s\"]/icon" %(platformHandle[0], platformHandle[2])
      icon = self.settingsFile.getEntry(tag)    
      if(icon != None):
        #Got an icon, now we need to find the integer ID for it.
        for id in self.iconList:
          if(self.iconList[id] == icon):
            iconId = id
            break
    #Don't have a platform specific icon, so we use the platformType to determine which one to use.      
    if(iconId == None):
      iconId = self.iconMap['default']
      if(platformType != None):
        platformType = platformType.lower()
        if(platformType in self.iconMap != False):
          iconId = self.iconMap[platformType]
          
    return(iconId)
  
  def getPlatformLinks(self, platformHandle, property):
    links = {}
    for id in self.baseLinks:
      urlInfo = self.baseLinks[id]
      type = urlInfo['type'] 
      if(type== "jsonDataUrl"):
        #The URL path is supplied in the lookup table.
        property['staDataURL'] = id      
        #Json URL file name is constructed like: carocoops:cap2:buoy_data.json 
        jsonFilename =platformHandle.replace('.', ':').lower()
        jsonFilename = "%s_data.json" % (jsonFilename)
        property['staDataFile'] = jsonFilename
      else:
        nfo = {}
        nfo['urlId'] = id
        if(type == "Twitter"):
          tag = "//platformSettings/platforms/platform[@id=\"%s\"]/links/twitterId" %(platformHandle)
          nfo['id'] = self.settingsFile.getEntry(tag)
          #Not every platform has a twitter page, so we only want to add the ones that do.
          if(nfo['id'] != None):
            nfo['iconId'] = self.iconMap['twitter']
            links['twitter'] = nfo 
        elif(type == "Email Alerts"):
          nfo['id'] = platformHandle        
          nfo['iconId'] = self.iconMap['emailAlert']
          links['emailAlert'] = nfo 
        elif(type == "Data Query"):
          #id = platformHandle.split('.')
          nfo['id'] = platformHandle        
          nfo['iconId'] = self.iconMap['dataQuery']
          links['dataQuery'] = nfo 
        elif(type == "RSS Feed"):
          id = platformHandle.replace('.', '_')
          id = id.lower()
          id += "_GeoRSS_latest.xml"
          nfo['id'] = id        
          nfo['iconId'] = self.iconMap['geoRSS']
          links['geoRSS'] = nfo
    if(len(links)): 
      property['links'] = links
  def getObservationForPlatform(self, platform_handle, obsLookup, uomLookup):
    obsList = []
    
    sql = "SELECT sensor.row_id, \
          obs_type.row_id as obs_type_id,\
          obs_type.standard_name as obs_type_standard_name,\
          uom_type.row_id AS uom_id,\
          sensor.row_id as sensor_row_id,sensor.s_order as sensor_s_order,sensor.url as sensor_url,\
          m_type_display_order.row_id as m_type_display_order_row_id,\
          obs_type.standard_name as obs_type_standard_name,\
          uom_type.standard_name as uom_type_standard_name,\
          uom_type.display as uom_type_display_name\
          FROM sensor\
            LEFT JOIN platform on sensor.platform_id = platform.row_id\
            LEFT JOIN m_type on sensor.m_type_id = m_type.row_id\
            LEFT JOIN m_type_display_order on m_type_display_order.m_type_id=sensor.m_type_id\
            LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id\
            LEFT JOIN obs_type on obs_type.row_id = m_scalar_type.obs_type_id\
            LEFT JOIN uom_type on uom_type.row_id = m_scalar_type.uom_type_id\
          WHERE platform.platform_handle='%s' AND (sensor.active>=1 AND sensor.active <=3)\
          ORDER BY m_type_display_order.row_id ASC;"\
          %( platform_handle )    
    """
    sql = "SELECT obs_type.row_id as obs_type_id,"\
          "max(multi_obs.m_date),multi_obs.m_lat,multi_obs.m_lon,multi_obs.m_z,"\
          "uom_type.row_id AS uom_id,"\
          "sensor.row_id as sensor_row_id,sensor.s_order as sensor_s_order,sensor.url as sensor_url,"\
          "m_type_display_order.row_id as m_type_display_order_row_id,"\
          "obs_type.standard_name as obs_type_standard_name,"\
          "uom_type.standard_name as uom_type_standard_name, "\
          "uom_type.display as uom_type_display_name "\
          "FROM multi_obs "\
           "LEFT JOIN m_type on multi_obs.m_type_id = m_type.row_id "\
           "LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id "\
           "LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id "\
           "LEFT JOIN uom_type on uom_type.row_id = m_scalar_type.uom_type_id "\
           "LEFT JOIN sensor on sensor.row_id=multi_obs.sensor_id "\
           "LEFT JOIN m_type_display_order on m_type_display_order.m_type_id=multi_obs.m_type_id "\
           "WHERE "\
           "m_date >= timestamp 'now' + interval '-6 hours' AND "\
           "platform_handle = '%s' " \
           "GROUP BY obs_type.row_id,multi_obs.m_lat,multi_obs.m_lon,multi_obs.m_z,uom_type.row_id,sensor.row_id,sensor.s_order,sensor.url,m_type_display_order.row_id,obs_type.standard_name,uom_type.standard_name,uom_type.display "\
           "ORDER BY m_type_display_order.row_id ASC;" \
            %( platform_handle )    
    
    sql = "SELECT\
      ,m_date as m_date\
      ,obs_type.standard_name as obs_type_standard_name\
      ,obs_type.definition as obs_type_definition\
      ,uom_type.standard_name as uom_type_standard_name\
      ,m_lon\
      ,m_lat\
      ,m_z\
      ,sensor.row_id as sensor_row_id\
      ,sensor.s_order as sensor_s_order\
      ,sensor.url as sensor_url\
      ,m_type_display_order.row_id as m_type_display_order_row_id\
      from multi_obs\
      left join sensor on sensor.row_id=multi_obs.sensor_id\
      left join m_type on m_type.row_id=multi_obs.m_type_id\
      left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id\
      left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id\
      left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id\
      left join m_type_display_order on m_type_display_order.m_type_id=multi_obs.m_type_id\
      where\
        m_date>(now()-interval '12 hours') AND\
        platform_handle='%s';"\
        % (platform_handle)
    """        
    obsCursor = self.xeniaDb.dbConnection.executeQuery( sql )        
    print("Processing obs for: %s" %(platform_handle))
    if(obsCursor != None):
      features = []      
      for row in obsCursor:
        print("\t%s" % row['obs_type_standard_name'])
        feature = {}
        feature['type'] = 'feature'
        #geometry = {}
        #geometry['type'] = 'Point'
        #geometry['coordinates'] = [row['m_lon'],row['m_lat']]
        #feature['geometry'] = geometry
        property = {}        
        property['obsTypeDesc'] = row['obs_type_id']        
        property['uomID']       = row['uom_id']
        #property['obsZ']        = row['m_z']
        property['obsDisOrd']   = row['m_type_display_order_row_id']
        property['sorder']      = row['sensor_s_order']
        feature['Properties'] = property        
        obsList.append(feature)
        
        obsId = row['obs_type_id'] 
        if(len(obsLookup) == 0 or (obsLookup.has_key(obsId) == False)):
          table = {}
          table['standard_name'] = row['obs_type_standard_name']
          #obsLookup[obsId]['standard_name'] = row['obs_type_standard_name']
          displayLabel = self.uomConverter.getDisplayObservationName(row['obs_type_standard_name'])
          if(displayLabel == None):
            displayLabel = row['obs_type_standard_name']
          table['display'] = displayLabel            
          obsLookup[obsId] = table
          
        uomId = row['uom_id']
        if(len(uomLookup) == 0 or (uomLookup.has_key(uomId) == False)):
          table = {}
          table['standard_name'] = row['uom_type_standard_name']
          table['display'] = row['uom_type_display_name']
          #Check to see if we've defined a more appropriate UOM in the units conversion file.
          displayUOM = self.uomConverter.getUnits( row['uom_type_standard_name'], row['uom_type_standard_name'] )
          if(displayUOM != None and len(displayUOM)):
            table['display'] = displayUOM          
          #displayUOM = self.uomConverter.getConversionUnits( row['uom_type_standard_name'], 'en' )
          imperialUOM = self.uomConverter.getConversionUnits( row['uom_type_standard_name'], 'en' )
          if(imperialUOM == None or len(imperialUOM) == 0):
            table['imperial'] = ""
          else:
            displayUOM = self.uomConverter.getUnits( row['uom_type_standard_name'], imperialUOM )          
            if(displayUOM == None):
              displayUOM = ""
            table['imperial'] = displayUOM    

          uomLookup[uomId] = table
        
       
        
    else:
      print( self.xeniaDb.dbConnection.getErrorInfo() )
    return(obsList)
  
  def buildJsonFiles(self, polygon, jsonPlatformDataFilepath, useJSONCallbackFunc):
    import simplejson as json
      
    try:
      platformMetaData = recursivedefaultdict()
      
      print("Beginning vector layer JSON creation process.")
      #Create the lookup tables for the platform metadata. We do this to reduce the over geojson size. Basically this
      #imitates the relational structure in the database, instead of having strings repeated over and over we store the ids in the 
      #platform meta data, then we lookup in the lookup tables.
      platformMetaData['lookups'] = self.buildLookupTables()
      platformMetaData['layers'] = {}

      #Create the vector platform meta data
      vectorPlatformMetaData, obsList, uomList, orgList = self.getPlatformsInPolygon(polygon)      
      platformMetaData['lookups']['obs_type'] = obsList
      platformMetaData['lookups']['uom_type'] = uomList
      platformMetaData['lookups']['organization'] = orgList

      
      platformMetaData['layers']['vector'] = {} 
      platformMetaData['layers']['vector'] = vectorPlatformMetaData
                
      print("Opening JSON file: %s" %(jsonPlatformDataFilepath))
      jsonPlatformFile = open(jsonPlatformDataFilepath, "w")
      if(useJSONCallbackFunc != None and useJSONCallbackFunc):
        jsonData = 'json_callback(%s)' %(json.dumps(platformMetaData, sort_keys=True))
        jsonPlatformFile.write(jsonData)
      else:
        jsonPlatformFile.write(json.dumps(platformMetaData, sort_keys=True))
      jsonPlatformFile.close()
      print("Closed JSON file")
      print("Creation completed.")
        
    except Exception, e:
      import sys
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
  parser.add_option("-f", "--JsonPlatformFilepath", dest="jsonPlatformFile",
                    help="The output JSON file."  )
  parser.add_option("-l", "--JsonLookupTableFilepath", dest="jsonLookupFile",
                    help="The output JSON file."  )
  parser.add_option("-c", "--ConversionFile", dest="uomFile",
                    help="The XML file with the units conversion formulas."  )
  parser.add_option("-s", "--PlaformSettingsFile", dest="platformSettings",
                    help="This is the XML file that has various settings for platforms.")
  parser.add_option("-j", "--UseJSONCallbackFunc", dest="useJSONCallbackFunc", action='store_true',
                    help="Set this flag to wrap the JSON in a callback function.")
  (options, args) = parser.parse_args()
  
  platformMeta = platformMetaData(options.dbUser, options.dbPwd, options.dbHost, options.dbName, 
                                  options.uomFile,
                                  options.platformSettings)
  platformMeta.setDataJsonUrl("http://neptune.baruch.sc.edu/xenia/feeds/obsjson/all/latest_hours_24/simple")
  platformMeta.buildJsonFiles(options.polygon, options.jsonPlatformFile, options.useJSONCallbackFunc)
    