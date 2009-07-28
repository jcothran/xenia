import twitter
import optparse
import sys
from lxml import etree
#from xenia import xeniaPostGres
#from xenia import uomconversionFunctions
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xmlConfigFile import xmlConfigFile

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
    configFile = xmlConfigFile( options.xmlConfigFile )
    dbSettings = configFile.getDatabaseSettings()
    if( dbSettings['dbHost'] != None and
        dbSettings['dbName'] != None and
        dbSettings['dbUser'] != None and
        dbSettings['dbPwd'] != None ):
      db      = xeniaPostGres()
      if( db.connect( None, dbSettings['dbUser'], dbSettings['dbPwd'], dbSettings['dbHost'], dbSettings['dbName'] ) == False ):
        print( "Unable to connect to PostGres." )
        sys.exit(-1)
      else:
        print( "Connect to PostGres: %s %s" % (dbSettings['dbHost'],dbSettings['dbName']))         
    else:
      print( "Missing configuration info for PostGres setup." )
      sys.exit(-1)        
   
    #Get the conversion xml file
    convertFile = configFile.getEntry( '//environment/unitsCoversion/file' )
    if( convertFile != None ):
      uomConverter = uomconversionFunctions(convertFile)
    else:
      print( "Unable to find XML conversion file given in the configuration file.")

    twitList = configFile.getListHead( '//environment/twitterList' )
    for child in configFile.getNextInList(twitList):
      platform        = configFile.getEntry( 'handle',child ) 
      twitterAccount  = configFile.getEntry( 'twitterAccount',child )
      twitterPwd      = configFile.getEntry( 'twitterPwd',child )
      if( platform != None and 
          twitterAccount != None and 
          twitterPwd != None ):
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
           