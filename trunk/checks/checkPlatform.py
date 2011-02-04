import os
import time
import optparse
import traceback
import logging
import logging.config
from xeniatools.xenia import dbXenia
from xeniatools.xenia import statusFlags
from xeniatools.utils import smtpClass 
from xeniatools.xmlConfigFile import xmlConfigFile




class platformStatus(object):
  def __init__(self,platformHandle,alertInterval):
    self.platformHandle = platformHandle
    self.alertInterval = alertInterval
    self.smtpServer = None
    self.emailUser = None
    self.emailPwd = None
    self.rcptList = None
  
  def testActivityStatus(self):
    return(False)
  
  def emailSettings(self,smtpServer,emailUser,emailPwd, rcptList):
    self.smtpServer = smtpServer
    self.emailUser = emailUser
    self.emailPwd = emailPwd
    self.rcptList = rcptList
  
  def sendAlertEmail(self, subject, msg):
    from xeniatools.utils import smtpClass
    
    smtp = smtpClass(self.smtpServer, self.emailUser, self.emailPwd)
    smtp.from_addr("%s@%s"%(self.emailUser,self.smtpServer))
    smtp.rcpt_to(self.rcptList)
    smtp.subject(subject)
    smtp.message(msg)
    smtp.send()      
    

  
  
  
  
class remoteseningStatus(platformStatus):
  def __init__(self, platformHandle, alertInterval, productType, dbConnection, loggerName='logger_root'):
    platformStatus.__init__(self,platformHandle,alertInterval)
    self.db = dbConnection
    self.productType = productType
    self.logger = None
    if(loggerName != None):
      self.logger = logging.getLogger(loggerName)
    
    
  def testActivityStatus(self):
    retVal = False
    if(self.logger != None):
      self.logger.info("Testing platform %s." %(self.platformHandle))
    
    curStatus = self.db.dbConnection.getCurrentPlatformStatus(self.platformHandle)
    #If don't get a status back, there is a problem, most likely the platform does not exist on the
    #platform table. We can't continue.
    if(curStatus == None):
      if(self.logger != None):
        self.logger.error("No status found for platform: %s, cannot continue." %(self.platformHandle))
        return(False)
    
    #Query the database for entries whose pass_timestamp are >= to the current GMT time - the
    #interval we alert. If nothing is available, we won't have a record and can assume something
    #has happened to the datafeed.
    sql = "SELECT row_entry_date,pass_timestamp FROM timestamp_lkp "\
          "LEFT JOIN product_type ON timestamp_lkp.product_id = product_type.row_id "\
          "WHERE pass_timestamp >= (timezone('GMT', now()) - interval '%d minutes') AND product_type.type_name='%s'"\
          "ORDER BY row_entry_date DESC;" %(self.alertInterval,self.productType)
          
    if(self.logger != None):
      self.logger.debug(sql)
    
    subject = ""
    msg = ""
    
    dbCursor = self.db.executeQuery(sql)
    if(dbCursor != None):
      row = dbCursor.fetchone()
      if(row != None):
        if(self.logger != None):
          self.logger.info("Most recent overpass datetime; %s" %(row['pass_timestamp']))
          #If the current platform status is not active, we need to now make it active.
          if(curStatus != statusFlags.ACTIVE):
            if(self.logger != None):
              self.logger.info("Updating status to %d from %d" %(int(statusFlags.ACTIVE),curStatus))
            if(self.db.dbConnection.setPlatformStatus(self.platformHandle, statusFlags.ACTIVE) == None):
              if(self.logger != None):
                self.logger.error(self.db.dbConnection.getErrorInfo())
              
            subject = "[secoora_auto_alert]RS Layer %s resumed reporting" %(self.platformHandle)
            msg = "%s passed test. Latest overpass: %s" % (self.platformHandle,row['pass_timestamp'])
            
          retVal = True
      else:
        if(self.logger != None):
          self.logger.info("No recent overpass found within interval.")

        if(curStatus != statusFlags.TECHNICAL_DIFFICULTY):
          if(self.logger != None):
            self.logger.debug("Updating status to %d from %d" %(int(statusFlags.TECHNICAL_DIFFICULTY),curStatus))
          if(self.db.dbConnection.setPlatformStatus(self.platformHandle, statusFlags.TECHNICAL_DIFFICULTY) == None):
            if(self.logger != None):
              self.logger.error(self.db.dbConnection.getErrorInfo())
            
        
        subject = "[secoora_auto_alert]RS Layer %s has not reported" %(self.platformHandle)
        msg = "%s failed test. No data found within the interval %.2f hours" % (self.platformHandle,(self.alertInterval/60.0))
        retVal = False
        
      if(len(msg)):
        if(self.logger != None):
          self.logger.info("Sending email.")
        self.sendAlertEmail(subject, msg)
        
    else:
      if(self.logger != None):
        self.logger.exception(self.db.dbConnection.getErrorInfo())  
    return(retVal) 
    
    
if __name__ == "__main__":

  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
  
  
  parser = optparse.OptionParser()
  parser.add_option("-c", "--ConfigFile", dest="xmlConfigFile",
                    help="Configuration file." )
  (options, args) = parser.parse_args()
  if(options.xmlConfigFile == None ):
    parser.print_usage()
    parser.print_help()
    sys.exit(-1)

  cfgFile = xmlConfigFile(options.xmlConfigFile)
  
  dbSettings = cfgFile.getDatabaseSettings()
  
  logFile = cfgFile.getEntry('//environment/logging/configFile')
  logging.config.fileConfig(logFile)

  xeniaDb = dbXenia()
  if( xeniaDb.connect(None, dbSettings['dbUser'], dbSettings['dbPwd'], dbSettings['dbHost'], dbSettings['dbName']) == False ):
    logging.error("Unable to connect to the database: %s" %(xeniaDb.dbConnection.getErrorInfo()))
    sys.exit(-1)
  else:
    logging.info("Sucessfully connected to DB: %s @ %s" % (dbSettings['dbName'], dbSettings['dbHost']))
  
  emailSettings = cfgFile.getEmailSettings()
  rsTestList = []
  platforms = cfgFile.getListHead("//environment/platforms")
  for child in cfgFile.getNextInList(platforms):
    handle = cfgFile.getEntry('handle',child)
    interval = cfgFile.getEntry('alertInterval',child)
    if(interval != None):
      interval = int(interval)
    productType = cfgFile.getEntry('productType',child)
    rsTest = remoteseningStatus(handle, interval, productType, xeniaDb)
    #smtpServer,emailUser,emailPwd, rcptList
    rsTest.emailSettings(emailSettings['server'],emailSettings['from'],emailSettings['pwd'],emailSettings['toList'])
    rsTestList.append(rsTest)
  
  for rsTest in rsTestList:
    rsTest.testActivityStatus()
  
  logging.info("Finished testing")
