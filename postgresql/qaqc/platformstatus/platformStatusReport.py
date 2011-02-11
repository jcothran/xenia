import sys
import os
import optparse
import time
import traceback
import shutil
from xeniatools.xenia import dbXenia




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
  parser.add_option("-l", "--PlatformFile", dest="platformFile",
                    help="Optional comma delimited file list of platforms to run the report on.")
  parser.add_option("-f", "--ReportFile", dest="reportFile", 
                    help="Full filepath to the HTML file to be created.")
  (options, args) = parser.parse_args()

  overallReportFile = None
  recordsWritten = False
  try:
    #We want to open the file with .tmp appended to the end so we don't create an empty file for an external
    #process to mistake as a valid file with data. If we do put records in the file, we'll then rename the file.
    tmpFilename = options.reportFile + ".tmp";
    #Delete any existing file
    if(os.path.isfile(tmpFilename)):
      print("Removing temp file: %s" %(tmpFilename))
      os.remove(tmpFilename)
    print("Opening report file: %s" %(tmpFilename))
    overallReportFile = open(tmpFilename, "w")
    
  except Exception, E:
    print(traceback.print_exc())
    sys.exit(-1)
  
  xeniaDb = dbXenia()
  if( xeniaDb.connect(None, options.dbUser, options.dbPwd, options.dbHost, options.dbName) == False ):
    print("Unable to connect to the database: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  else:
    print("Sucessfully connected to DB: %s @ %s" % (options.dbName, options.dbHost))
  platformList = []
  platformWhere = ''
  if(options.platformFile != None and len(options.platformFile)):
    print("Opening platform list file: %s" %(options.platformFile))
    platformFile = open(options.platformFile, "r")
    
    platforms = ''
    for platform in platformFile:
      platform = platform.strip()
      if(len(platforms)):
        platforms += " OR "
      platforms += ("platform_handle='%s'" % (platform))
    platformWhere = "AND (%s)" % platforms
      
    print("Closing platform list file: %s" %(options.platformFile))
    platformFile.close()
    
  writeFile = False    
  sql = "SELECT row_id,platform_handle,active FROM platform WHERE (active != 1 AND active != 0) %s" % (platformWhere)
  dbCursor = xeniaDb.dbConnection.executeQuery(sql)
  if(dbCursor != None):
    platformWhere = ""
    for row in dbCursor:
      if(len(platformWhere)):
        platformWhere += " OR "
      platformWhere += "platform_handle='%s'" % (row['platform_handle'])
    platformWhere += "" 
    if(len(platformWhere)):
      platformWhere = "AND (%s)" % (platformWhere)
      writeFile = True
    if(writeFile):
      #overallReportFile.write("<table><tr><th>Issue Entry Data</th><th>Platform</th><th>Issue</th></tr>\n")
      #for row in dbCursor:
        #sql = "SELECT begin_date,reason FROM platform_status WHERE end_date IS NULL and platform_id=%d ORDER BY begin_date DESC;"\
        #  %(row['row_id'])
      sql = "SELECT begin_date,reason,platform_handle FROM platform_status "\
            "WHERE end_date IS NULL %s ORDER BY begin_date DESC;"\
            %(platformWhere)      
      statusCursor = xeniaDb.dbConnection.executeQuery(sql)
      if(statusCursor != None):
        for statusRow in statusCursor:
          #statusRow = statusCursor.fetchone()
          if(statusRow != None):
            recordsWritten = True
            reason = statusRow['reason']
            if(reason == None or len(reason) == 0):
              reason = "\"No data received from platform.\""
            else:
              reason = "\"%s\"" %(statusRow['reason'])
  
            overallReportFile.write("%s,%s,%s\n" %((statusRow["begin_date"], statusRow['platform_handle'],reason)))
        statusCursor.close()
      dbCursor.close()

  print("Closing report file: %s" %(options.platformFile))
  overallReportFile.close()
  try:
    if(recordsWritten):
      print("Copying tmp file %s to working file %s" %(tmpFilename, options.reportFile))
      shutil.copy(tmpFilename, options.reportFile)
    else:
      if(os.path.isfile(options.reportFile)):
        print("No current platforms found, deleting file %s" %(options.reportFile))    
        os.remove(options.reportFile)      
    print("Deleting tmp file %s" %(tmpFilename))
    os.remove(tmpFilename)      
  except Exception, E:
    print(traceback.format_exc())
     
