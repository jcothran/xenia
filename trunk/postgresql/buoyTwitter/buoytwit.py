import twitter
import optparse
import sys
import re
from lxml import etree
#from xenia import xeniaPostGres
#from xenia import uomconversionFunctions
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xmlConfigFile import xmlConfigFile

def createFriends( configFile ):
  from xeniatools.xenia import recursivedefaultdict
  
  twitAccountList = recursivedefaultdict()
  #Grab all the account info out of the config file.
  twitList = configFile.getListHead( '//environment/twitterList' )
  for child in configFile.getNextInList(twitList):
    platform        = configFile.getEntry( 'handle',child )
    twitterAccount  = configFile.getEntry( 'twitterAccount',child )
    twitterPwd      = configFile.getEntry( 'twitterPwd',child )
    twitAccountList[platform]['account'] =  twitterAccount
    twitAccountList[platform]['password'] =  twitterPwd
  #Now let's loop and friend all the buoys to one another
  for platform in twitAccountList:
    try:
      account = twitAccountList[platform]['account']
      pwd = twitAccountList[platform]['password']
      client = twitter.Api(account, pwd)
      for friendPlatform in twitAccountList:
        try:
          if( friendPlatform != platform ):
            account = twitAccountList[friendPlatform]['account']
            user = client.CreateFriendship( account )
            print( "%s friended user: %s" %( platform, user.screen_name ) )
        except twitter.TwitterError,e:
          print("Twitter Error: %s" %(e.message))
          continue
        except Exception, E:
          print( "Error from twitter call: %s" % (str(E)) )
          continue
    except twitter.TwitterError,e:
      print("Twitter Error: %s" %(e.message))
      continue
    except Exception, E:
      print( "Error from twitter call: %s" % (str(E)) )
      continue

if __name__ == '__main__':

  parser = optparse.OptionParser()
  parser.add_option("-c", "--XMLConfigFile", dest="xmlConfigFile",
                    help="Configuration file." )
  parser.add_option("-f", "--CreateFriends", action= 'store_true', dest="createFriends",
                    help="Friend the other buoys in the xml Config file." )
  (options, args) = parser.parse_args()
  if( options.xmlConfigFile == None ):
    parser.print_usage()
    parser.print_help()
    sys.exit(-1)
  try:
    #Open the XML Config File for processing.  
    configFile = xmlConfigFile( options.xmlConfigFile )
    
    #Are we having the buoys friend each other?
    if( options.createFriends ):
      createFriends( configFile )
    #We are tweeting the buoy status.    
    else:
      #Get the various settings we need from out xml config file.
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
      
          dateOffset = "m_date >= date_trunc('hour',( SELECT timezone('UTC', now() - interval '6 hour') ) ) AND d_top_of_hour = 1 AND"
                  
          sql= "SELECT m_date \
                ,multi_obs.platform_handle \
                ,obs_type.standard_name \
                ,uom_type.standard_name as uom \
                ,multi_obs.m_type_id \
                ,m_value \
                ,qc_level \
                ,sensor.row_id as sensor_id\
                ,sensor.s_order \
                ,platform.description\
              FROM multi_obs \
                left join sensor on sensor.row_id=multi_obs.sensor_id \
                left join platform on platform.row_id=sensor.platform_id\
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
            desc = ''
            hasData = False
            latestDate = None
            for row in cursor:
              if( hasData == False):
                desc = row['description']
                desc = desc.replace("Nearshore", "")
                desc = desc.replace("Offshore", "")
                #Some description fields have the platform name as well as the geo location. We want
                #to split it up so we can just pick out the geo location.
                descParts = desc.split(',')
                #This should be platform name,city,state
                if(len(descParts) > 2):
                  desc = "%s,%s" % (descParts[1],descParts[2])
                #city,state
                elif(len(descParts) > 1):
                  desc = "%s,%s" % (descParts[0],descParts[1])
                else:
                  desc = ''
                tweet = "Buoy Offshore Weather "
                hasData = True

              if(latestDate == None):
                latestDate = row['m_date']
              #We only want the most current data. We need to retrieve the last 6 hours to make sure we catch
              #data that might occur on an odd interval.
              else:
                if(latestDate != row['m_date']):
                  break
                latestDate = row['m_date']
              processOb = False
              obsName = row['standard_name']
              if( obsName == 'air_temperature' ):
                obsName = 'Air Temperature'
                processOb = True
              elif( obsName == 'water_temperature' ):
                obsName = 'Water Temperature'
                processOb = True
              elif( obsName == 'wind_speed' ):
                obsName = 'Wind Speed'
                processOb = True
              elif( obsName == 'wind_from_direction' ):
                obsName = 'Wind Direction' 
                processOb = True
              
              if( processOb ):
                obsUOM = row['uom']
                value = row['m_value']
                uom = uomConverter.getConversionUnits( obsUOM, 'en' )
                displayUnits = uom 
                if( len(uom) > 0 ):
                  value = uomConverter.measurementConvert( value, obsUOM, uom )
                  displayUnits = uomConverter.getUnits(obsUOM, uom)
                  if(displayUnits  != None):
                    uom = displayUnits
                tweet += "%s %4.1f%s " % ( obsName, value, uom )
            
            if( len(tweet) ):
              if(len(desc)):
                tweet += desc
              try:
                print("%s attempting to tweet: %s(%d chars)" %( platform,tweet,len(tweet) ) )
                status = client.PostUpdate( tweet )
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
           