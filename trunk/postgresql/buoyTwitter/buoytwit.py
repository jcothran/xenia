import twitter
import optparse
import sys
from lxml import etree
#from xenia import xeniaPostGres
#from xenia import uomconversionFunctions
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import uomconversionFunctions

if __name__ == '__main__':

  parser = optparse.OptionParser()
  parser.add_option("-c", "--XMLConfigFile", dest="xmlConfigFile",
                    help="Configuration file." )
  (options, args) = parser.parse_args()
  if( options.xmlConfigFile == None ):
    parser.print_usage()
    parser.print_help()
    sys.exit(-1)
  try:  
    #Get the various settings we need from out xml config file.
    xmlTree = etree.parse(options.xmlConfigFile)
    dbName= xmlTree.xpath( '//environment/database/name' )
    user = xmlTree.xpath( '//environment/database/user' )
    pwd = xmlTree.xpath( '//environment/database/pwd' )
    host = xmlTree.xpath( '//environment/database/host' )
    if( len(host) and len(user) and len(pwd) and len(dbName)):
      dbName  = dbName[0].text
      host    = host[0].text
      user    = user[0].text
      pwd     = pwd[0].text
      db      = xeniaPostGres()
      if( db.connect( None, user, pwd, host, dbName ) == False ):
        print( "Unable to connect to PostGres." )
        sys.exit(-1)
      else:
        print( "Connect to PostGres: %s %s" % (host,dbName))         
    else:
      print( "Missing configuration info for PostGres setup." )
      sys.exit(-1)        
   
    #Get the conversion xml file
    convertFile = xmlTree.xpath( '//environment/unitsCoversion/file' )
    if( len(convertFile) ):
      uomConverter = uomconversionFunctions(convertFile[0].text)

    twitList = xmlTree.xpath( '//environment/twitterList')
    for child in twitList[0].getchildren():
      platform        = child.xpath( 'handle' ) 
      twitterAccount  = child.xpath( 'twitterAccount' )
      twitterPwd      = child.xpath( 'twitterPwd' )
      if( len(platform) and len(twitterAccount) and len(twitterPwd) ):
        platform        = platform[0].text
        twitterAccount  = twitterAccount[0].text
        twitterPwd      = twitterPwd[0].text
        #Connect to the Twitter api.
        try:
          client = twitter.Api(twitterAccount, twitterPwd)
        except twitter.TwitterError,e:
          print("Twitter Error: %s" %(e.message))
          continue
        except Exception, E:
          print( "Error from twitter.Api call: %s" % (str(E)) )
          continue
    
        dateOffset = "m_date >= date_trunc('hour',( SELECT timezone('UTC', now() - interval '1 hour') ) ) AND d_top_of_hour = 1 AND"
                
        sql= "SELECT m_date \
              ,multi_obs.platform_handle \
              ,obs_type.standard_name \
              ,uom_type.standard_name as uom \
              ,multi_obs.m_type_id \
              ,m_value \
              ,qc_level \
              ,sensor.row_id as sensor_id\
              ,sensor.s_order \
            FROM multi_obs \
              left join sensor on sensor.row_id=multi_obs.sensor_id \
              left join m_type on m_type.row_id=multi_obs.m_type_id \
              left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id \
              left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id \
              left join uom_type on uom_type.row_id=m_scalar_type.uom_type_id \
              WHERE %s multi_obs.platform_handle = '%s' AND sensor.row_id IS NOT NULL\
              ORDER BY m_date DESC;" \
              % (dateOffset,platform)
         
        cursor = db.executeQuery(sql)
        if( cursor != None ):
          tweet = ''
          hasData = False
          for row in cursor:
            if( hasData == False):
              tweet = "Offshore Weather "
              hasData = True
            processOb = False
            obsName = row['standard_name']
            if( obsName == 'air_temperature' ):
              obsName = 'AirTemp'
              processOb = True
            elif( obsName == 'water_temperature' ):
              obsName = 'WaterTemp'
              processOb = True
            elif( obsName == 'wind_speed' ):
              obsName = 'WindSpeed'
              processOb = True
            elif( obsName == 'wind_from_direction' ):
              obsName = 'WindDir' 
              processOb = True
            
            if( processOb ):
              obsUOM = row['uom']
              value = row['m_value']
              uom = uomConverter.getConversionUnits( obsUOM, 'en' )
              if( len(uom) > 0 ):
                value = uomConverter.measurementConvert( value, obsUOM, uom )              
              tweet += "%s %4.1f %s " % ( obsName, value, uom )
          
          if( len(tweet) ):
            try:
              status = client.PostUpdate( tweet )
              print( "%s Tweets: %s" %( platform,tweet ) )
            except twitter.TwitterError,e:
              print("Twitter Error: %s" %(e.message))
              continue
            except Exception, E:
              print( "Error from PostUpdate call: %s" % (str(E)) )
              continue
          else:
            print( "Nothing to tweet, no data returned for platform: %s." % (platform) )            
        else:
          print( "No data returned for platform: %s." % (platform) )
      else:
        print( "Missing setup information in \\\\environment\\twitterList" )
      
  except Exception, E:
    print( str(E) )
    sys.exit(-1) 

  sys.exit(0)
           