import sys
import optparse

from xeniatools.rangeCheck import rangeTests

if __name__ == '__main__':
  try:
    import psyco
    psyco.full()
  except Exception, E:
    import traceback
    print( traceback.print_exc() )
    
  try:
    parser = optparse.OptionParser()
    
    parser.add_option("-c", "--XMLConfigFile", dest="xmlConfigFile",
                    help="The xml file containing the configuration information." )  
    parser.add_option("-n", "--LastNHours", dest="lastNHours",
                    help="The Last N Hours to query data for." )
    parser.add_option("-b", "--BeginDateTime", dest="beginDateTime",
                    help="The date to begin the data query for." )
    parser.add_option("-e", "--EndDateTime", dest="endDateTime",
                    help="The date to end the data query for." )
    parser.add_option("-s", "--SQLOutputFileName", dest="sqlOutputFileName",
                    help="Overrides the sql output file provided in the config file. This is the file the QAQC SQL UPDATE statements are saved." )
    parser.add_option("-q", "--IgnoreQAQCFlags", dest="ignoreQAQCFlags", action= 'store_true',
                    help="Flag allows us to restamp records that have already been quality controlled." )
    parser.add_option("-t", "--TestRun", dest="testRun", action= 'store_true',
                    help="Flag allows us to run the QAQC with no committing into the database." )

    
    (options, args) = parser.parse_args()
    if(((options.xmlConfigFile == None or len(options.xmlConfigFile) == 0)) or
       (options.lastNHours == None and options.beginDateTime == None and options.endDateTime == None)):
      parser.print_usage()
      parser.print_help()
      sys.exit(-1)
      
    qaqc = rangeTests(options.xmlConfigFile)
    if(options.ignoreQAQCFlags != None and options.ignoreQAQCFlags == True):
      qaqc.restampQAQCRecords(True)
    if(options.testRun != None and options.testRun == True):
      qaqc.testRun(options.testRun)
      
    if(options.lastNHours != None):
      qaqc.setLastNHours(int(options.lastNHours))
    else:
      qaqc.setDateRange(options.beginDateTime, options.endDateTime)

  except Exception, E:
    import traceback
    print( traceback.print_exc() )
    