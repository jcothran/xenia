from xenia import xeniaSQLite
from xenia import xeniaPostGres
#from xeniastuff import sendEmail
import optparse
import sys

if __name__ == '__main__':

  parser = optparse.OptionParser()
  parser.add_option("-f", "--sqlFile", dest="sqlFile",
                    help="SQL file to run against the database" )
  parser.add_option("-s", "--SQLiteDB", dest="sqliteDB",
                    help="The SQLite database to run against" )
  parser.add_option("-u", "--User", dest="user",
                    help="The username for a PostGres db." )
  parser.add_option("-p", "--Passwd", dest="password",
                    help="The password for a PostGres db." )
  parser.add_option("-d", "--DBName", dest="dbName",
                    help="The database name for a PostGres db." )
  parser.add_option("-c", "--CommitEach", dest="commitEach",type="int",default=0,
                    help="If set to 1, will issue a commit after each SQL statement." )
  (options, args) = parser.parse_args()
  
  db = None
  if( options.sqlFile == None ):
    print( "ERROR: No SQL file given" )
    sys.exit(-1)
  print( "Processing SQL file: %s" % ( options.sqlFile ) )
  if( options.sqliteDB != None and len(options.sqliteDB) ):
    db = xeniaSQLite()
    if( db.connect( options.sqliteDB ) == False ):
      print( "ERROR: Failed to open SQLite file: %s Message: %s" %(options.sqliteDB,db.lastErrorMsg) )
      sys.exit(-1)
    else:
      print( "Connected to SQLite file: %s" % ( options.sqliteDB ) )
  else:
    if( options.dbName != None and options.user != None and options.password != None ):
      db = xeniaPostGres()
      if( db.connect( None, options.user, options.password, None, options.dbName ) == False ):
        print( "ERROR: Failed to connect to PostGres DB. DBName: %s User: %s Pwd: %s Message: %s" %(options.dbName, options.user, options.password, db.lastErrorMsg) )
        sys.exit(-1)
      else:
        print( "Connected to PostGres DBName: %s User: %s" % (options.dbName, options.user) )
    else:
      print( "ERROR: Missing required connection info." )
  try:
    sqlFile = open( options.sqlFile, 'r' )
  except Exception, E:
    print( "ERROR Opening file: %s Error: %s" %( options.sqlFile,str(E) ) )
    sys.exit(-1)   
  
  try:
    line = sqlFile.readline()
    linesProcessed = 0
    while( len(line) ):
      if( line != '' ):
        success = 0
        retryCnt = 0
        #Loops executing
        while( success == 0 ):        
          try:      
            dbCursor = db.DB.cursor()
            dbCursor.execute( line )
            if( options.commitEach ):
              db.DB.commit()
            success = 1
            if( retryCnt ):
              print( "Retried: %d times due to database lock." %(retryCnt) )            
          except Exception, E:
            print( "ERROR: %s SQL: %s LineNum: %d" %( str(E),line,linesProcessed ) )
            #Was the database locked, if so we can retry.
            if( str(E).find('lock') != -1 ):
                success = 0
                retryCnt += 1
                continue
            else:
              sys.exit(-1)
      else:
        print( "Skipping blank line at row: %d" % ( linesProcessed ) )
      linesProcessed += 1     
      line = sqlFile.readline()
    db.DB.commit()
    print( "Processed: %d lines" %(linesProcessed))
  except Exception, E:
    print( "ERROR: %s" %( str(E) ) )
  
  