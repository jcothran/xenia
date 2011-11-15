"""
Revisions
Author: DWR
Date: 2011-11-15
Functions: emailAlerts.createEmailMsg and emailAlerts.createEmailMsg
Changes: Replaced the database observation and units of measure names with more display friendly version from
the units conversion file.

Function: __main__
Changes: Added use of logging config file.
"""
import sys
import os
import stat
import time 
import optparse
from collections import defaultdict  
from pysqlite2 import dbapi2 as sqlite3
from lxml import etree

from xeniatools.xenia import xeniaSQLite
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import dbTypes
from xeniatools.xmlConfigFile import xmlConfigFile

import logging
import logging.config
import logging.handlers

class GroupWriteRotatingFileHandler(logging.handlers.RotatingFileHandler):
  def __init__(self, filename, mode='a', maxBytes=0, backupCount=0, encoding=None):
    logging.handlers.RotatingFileHandler.__init__(self, filename,mode, maxBytes, backupCount, encoding)
    if(os.path.isfile(self.baseFilename) != True):
      currMode = os.stat(self.baseFilename).st_mode
      #Since the email alert module can be used by web service as well as from command line, we want to change
      #the file permissions to give everyone access to it. Probably would be better to use group permissions
      #only, but for now we grant all.
      os.chmod(self.baseFilename, currMode | (stat.S_IXUSR|stat.S_IWGRP|stat.S_IXGRP|stat.S_IROTH|stat.S_IWOTH|stat.S_IXOTH))

  def doRollover(self):
      """
      Override base class method to make the new log file group writable.
      """
      # Rotate the file first.
      logging.handlers.RotatingFileHandler.doRollover(self)

      currMode = os.stat(self.baseFilename).st_mode
      #Since the email alert module can be used by web service as well as from command line, we want to change
      #the file permissions to give everyone access to it. Probably would be better to use group permissions
      #only, but for now we grant all.
      os.chmod(self.baseFilename, currMode | (stat.S_IXUSR|stat.S_IWGRP|stat.S_IXGRP|stat.S_IROTH|stat.S_IWOTH|stat.S_IXOTH))

class recursivedefaultdict(defaultdict):
    def __init__(self):
        self.default_factory = type(self) 
        
class emailAlert:
  def __init__(self):
    self.email        = None
    self.platform     = None
    self.id           = None
    self.limit        = None
    self.operator     = None
    self.uom          = None
    self.alertInterval = 14400
    self.grpID        = None
    self.obsValue     = None

class alertsDB:
  def __init__(self,filePath):
    self.dbFilePath = filePath
    self.DB = None
    self.logger = logging.getLogger("emailalert_logger.alertsDB")
    self.logger.info("creating an instance of alertsDB")
    self.lastErrorMsg = ''
    self.lastErrorFile = ''
    self.lastErrorLineNo = ''
    self.lastErrorFunc = ''
    
  def connectDB(self):
    try:
      self.DB = sqlite3.connect( self.dbFilePath )
      #This enables the ability to manipulate rows with the column name instead of an index.
      self.DB.row_factory = sqlite3.Row
      return(True )
    except Exception, E:
      self.procTraceback()      
      print( str(E) )
      return(False)

  def procTraceback(self):
    import sys
    import traceback
    
    info = sys.exc_info()        
    excNfo = traceback.extract_tb(info[2],1)
    items = excNfo[0]
    self.lastErrorFile = items[0]    
    self.lastErrorLineNo = items[1]    
    self.lastErrorFunc = items[2]    
    
  def executeQuery(self, sqlQuery):   
    try:
      dbCursor = self.DB.cursor()
      dbCursor.execute( sqlQuery )        
      return( dbCursor )
    except sqlite3.Error, e:        
      self.procTraceback()
      self.lastErrorMsg = "Msg: %s Function: %s Line: %s File: %s SQL: %s" %(e.args[0],self.lastErrorFunc,self.lastErrorLineNo,self.lastErrorFile,sqlQuery)        
    except Exception, E:
      self.procTraceback()
      self.lastErrorMsg = "Msg: %s Function: %s Line: %s File: %s SQL: %s" %(str(E),self.lastErrorFunc,self.lastErrorLineNo,self.lastErrorFile,sqlQuery)        
    return(None)
  
  def alertExists(self, emailAlert):
    sql = "SELECT id FROM alerts WHERE obs_type_id=%d AND email='%s' AND platform_handle='%s' AND operator_id=%d"\
           % (emailAlert.id,emailAlert.email,emailAlert.platform, emailAlert.operator)
    self.logger.debug("alertExists: %s"%(sql))
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      row = dbCursor.fetchone()
      if(row != None):
        return(True)
    #An error occured.
    else:
      return(None)
    return(False)
    
  def addAlert(self, emailAlert ):
    #Add the alert.              
    if( emailAlert.grpID != None ):
      sql = "INSERT INTO alerts \
              (email,obs_type_id,alert_val,alert_units,email_interval,platform_handle,last_email_time,alert_group,operator_id) \
              VALUES('%s',%d,%f,'%s',%d,'%s',0,%d,%d);" %\
              ( emailAlert.email, emailAlert.id, emailAlert.limit, emailAlert.uom, emailAlert.alertInterval, emailAlert.platform, emailAlert.grpID, emailAlert.operator)
    else:
      #Check to see if a similar alert exists, if it does we just update it.
      if(self.alertExists(emailAlert) == True):
        sql = "UPDATE alerts SET alert_val=%f,email_interval=%d,last_email_time=0 WHERE obs_type_id=%d AND email='%s' AND platform_handle='%s'"\
                %(emailAlert.limit, emailAlert.alertInterval, emailAlert.id, emailAlert.email, emailAlert.platform)
      else:      
        sql = "INSERT INTO alerts \
                (email,obs_type_id,alert_val,alert_units,email_interval,platform_handle,last_email_time,operator_id) \
                VALUES('%s',%d,%f,'%s',%d,'%s',0,%d);" %\
                ( emailAlert.email, emailAlert.id, emailAlert.limit, emailAlert.uom, emailAlert.alertInterval, emailAlert.platform, emailAlert.operator )
      
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      dbCursor.close()        
      self.logger.debug( sql )
      return(True)
    return( False )
  
  def updateAlertLastEmailTime(self, emailAlert, utcSeconds):
    whereClause = ''
    #If we have a grpID, we can use it to update the records since grpID's are unique/
    if( emailAlert.grpID != None ):
      whereClause = "alert_group = %d" % (emailAlert.grpID)
    #No grpID, so we are updating a stand alone alert.
    else:
      whereClause = "email='%s' AND platform_handle='%s' AND obs_type_id = %d AND alert_group IS NULL" % ( emailAlert.email, emailAlert.platform, emailAlert.id )
      
    sql = "UPDATE alerts \
                  SET last_email_time=%d\
                  WHERE %s;" \
                  %( utcSeconds, whereClause )
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      self.DB.commit()
      dbCursor.close()        
      self.logger.debug( sql )
      return( True )
    return( False )
  
  def getNextGroupID(self):
    grpID = -1
    sql = "SELECT max(alert_group) as alert_group FROM alerts;"
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      row = dbCursor.fetchone()
      grpID = 0
      if( row['alert_group'] != None ):
        grpID = int(row['alert_group'])
        grpID += 1
      dbCursor.close()        
      return( grpID )                
    return( -1 )

  def checkForAlertsEvent(self, utcSeconds):
    sql = "SELECT alerts.email,alerts.platform_handle,alerts.obs_type_id,alerts.alert_val,alerts.alert_units,alerts.email_interval,alerts.last_email_time,alerts.alert_group,operation_types.operator\
            FROM alerts \
            LEFT JOIN operation_types ON operation_types.id = alerts.operator_id\
            WHERE %d > last_email_time + email_interval;" \
            %( utcSeconds ) 
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      return( dbCursor )
    return( None )
  
  def unsubscribe(self,email,platform,obsID,grpID):
    whereClause = ''
    if( grpID != None ):
      whereClause = "alert_group=%d" %( grpID )
    else:
      whereClause = "platform_handle='%s' AND obs_type_id=%s" % ( platform, obsID )          
    sql = "DELETE FROM alerts \
              WHERE email='%s' AND %s" % ( email, whereClause )
    dbCursor = self.executeQuery( sql )  
    if(dbCursor != None):      
      self.DB.commit()
      dbCursor.close()
      return(True)
    #An error occured.
    else:
      return(None)
    return( False )
    
  def getOperations(self):
    #Get the id for the comparison operation.
    operations = {}
    sql = "SELECT * FROM operation_types"
    dbCursor = self.executeQuery(sql)
    if(dbCursor != None):
      for row in dbCursor:
        operations[row['operator']] = row['id']
      dbCursor.close()
    return(operations)
class emailMsg:
  def __init__(self):
    self.plaformID    = ''
    self.url          = ''    
    self.alertObsList = ''
    self.obsList      = ''
    self.unsubscribe  = ''

class emailAlerts:
  
  def __init__(self, configSettings):
    
    alertsDBFile = configSettings.getEntry("//environment/database/alertsDB/name")   
    xeniaDBSettings = configSettings.getDatabaseSettings()
    conversionXMLFile = configSettings.getEntry("//environment/unitsConversion/file")
    
    self.unsubURL = configSettings.getEntry("//environment/unsubscribeURL")
    self.georssURL = configSettings.getEntry("//environment/geoRSSURL")
    self.surveyURL = configSettings.getEntry("//environment/surveyURL")
    
    self.uomConverter = uomconversionFunctions( conversionXMLFile )        
    self.logger = logging.getLogger("emailalert_logger.alertsDB")
    self.logger.info("creating an instance of emailAlerts")
    
    self.alertsDB = alertsDB( alertsDBFile )
    if( self.alertsDB.connectDB() == False ):
      self.logger.error( "Unable to connect to Alerts DB: %s" % ( alertsDBFile ) )
      sys.exit(-1)
    else:
      self.logger.debug( "Connected to Alerts DB: %s" % ( alertsDBFile ) )

    if( xeniaDBSettings['type'] == 'SQLite' ):     
      self.obsDB = xeniaSQLite()
      if( self.obsDB.connect( xeniaDBSettings['dbName'] ) == False ):
        self.logger.error( "Unable to connect to xenia DB: %s Error: %s" % ( xeniaDBSettings['dbName'], self.obsDB.lastErrorMsg ) )
        sys.exit(-1)
      else:
        self.logger.debug( "Connected to xenia DB: %s" % ( xeniaDBSettings['dbName'] ) )
    else:
      self.obsDB = xeniaPostGres()
      if( self.obsDB.connect( None, 
                      xeniaDBSettings['dbUser'],
                      xeniaDBSettings['dbPwd'],
                      xeniaDBSettings['dbHost'],
                      xeniaDBSettings['dbName']
                     ) == False ):
        self.logger.error( "Unable to connect to xeniaDB: %s Host: %s User: %s\nError: %s" % (xeniaDBSettings['dbName'], xeniaDBSettings['dbHost'], xeniaDBSettings['dbUser'] ,self.obsDB.lastErrorMsg) )
        sys.exit(-1)
      else:
        self.logger.debug( "Connected to Host: %s Name: %s User: %s", xeniaDBSettings['dbHost'],xeniaDBSettings['dbName'],xeniaDBSettings['dbUser']  )
    
  def saveXMLAlerts(self, xmlDoc):
    import urllib

    try:
      #Get the various test operations. They are stored in a dictionary
      #with the id keyed on the operation.
      operations = self.alertsDB.getOperations()
      
      xmlTree = etree.fromstring(xmlDoc)
      platformID = xmlTree.xpath( '//response/platform' )
      if( len( platformID ) ):
        platformID = platformID[0].text       
      email = xmlTree.xpath('email')
      if(len(email)):
        email = email[0].text
      alerts =  xmlTree.xpath( '//response/alerts' )
      alertChain = []
      alertAdded = False
      for alert in alerts[0].getchildren():

        rule = emailAlert()
       
        rule.platform = platformID
        rule.email = email 
        tag = alert.xpath('id')
        if(len(tag)):
          rule.id = int(tag[0].text)
          
        tag = alert.xpath('limit')
        if(len(tag)):
          rule.limit = float(tag[0].text)
          
        tag = alert.xpath('uom')
        if(len(tag)):
          rule.uom = tag[0].text
        
        tag = alert.xpath('operator')
        if(len(tag)):
          operator = tag[0].text
          self.logger.debug("Operator: %s" %(operator))
          #The xml string is encoded on the client(javascript escape()), so we need to unquote it
          #to be able to process.
          operator = urllib.unquote(operator)
          operator = operator.replace("\'", "")
          operator = operator.replace("\\", "")
          if(operator in operations != False):
            rule.operator = operations[operator]
          else:
            self.logger.error( "Operator: %s is invalid. Alert %s will not be saved." %(operator,xmlDoc) )
            return(False)            
        #Make the default operator ">"
        else:
          rule.operator = operations[">"]
          
        tag = alert.xpath('alertInterval')
        if(len(tag)):
          rule.alertInterval = int(tag[0].text)
  
        cond = alert.xpath('cond')
        if(len(cond)):
          cond = cond[0].text
        #If the condition is 'AND', then we need to match it up with the next alert in the list, otherwise it is a standalone alert.
        if( cond == 'AND' ):
          alertChain.append( rule )
        else:
          #Check to see if we had any "AND"ed tests.
          if( len( alertChain ) ):
            #Add the rule we just processed since it is the last one in the group
            alertChain.append( rule )
            grpID = self.alertsDB.getNextGroupID()
            for i in range(0, len( alertChain )):
              alertChain[i].grpID = grpID
              if( self.alertsDB.addAlert( alertChain[i] ) ):
                alertAdded = True
              else:
                self.logger.error( "Unable to add alert. %s" %(self.alertsDB.lastErrorMsg) )
            alertChain = []

          #No ANDed limits, this is a stand alone limit.
          else:
            if( self.alertsDB.addAlert( rule ) ):
              alertAdded = True
            else:
              self.logger.error( "Unable to add alert. %s" %(self.alertsDB.lastErrorMsg) )
          #Commit 
          self.alertsDB.DB.commit()
          if( alertAdded ):
            self.logger.info( "Alert added." )
            return(True);

    except Exception, E:
      self.logger.error( str(E) )
      #print( str(E) )
    return(False)
    
  def checkForAlerts(self):
    emailAlertGroups = recursivedefaultdict()
    
    utcSecs = time.time()
    #Query the alertsDB to see if any alerts are ready to be tested again.
    dbCursor = self.alertsDB.checkForAlertsEvent( utcSecs )
    if( dbCursor != None ):      
      #We use a multidimensional dictionary to store the alerts by email address and then by group id.
      for row in dbCursor:
        groupList = []
        
        alert = emailAlert()
        #email,platform_handle,obs_type_id,alert_val,alert_units,email_interval,last_email_time,alert_group
        alert.email        = row['email']
        alert.platform     = row['platform_handle']
        alert.id           = row['obs_type_id']
        alert.limit        = row['alert_val']
        alert.uom          = row['alert_units']
        alert.alertInterval = row['email_interval']
        alert.grpID        = row['alert_group']
        alert.operator     = row['operator']
        #We have alerts that are standalone, or we have alerts that are to be grouped as an "AND", if we have an alert.grpID
        #we have a set of "AND" conditions wo we want to keep them together.
        id = 'single';
        if( alert.grpID != None ):
          id = alert.grpID
        #This alert is part of an "AND" group, so we save it in a list containing the other pieces.
        #If we don't have the email addy for the alert already in our dictionary, we add it and then add the group list.
        if( (id in emailAlertGroups[alert.email][alert.platform]) == False ):
          emailAlertGroups[alert.email][alert.platform][id] = groupList
        else:
          groupList = emailAlertGroups[alert.email][alert.platform][id]               
        #Add the alert into its list.
        groupList.append( alert )
        
      dbCursor.close()
    return( emailAlertGroups )
  
  def processAlerts(self):
  
    #Partial URL for the unsubscribe link. We'll need to also add either the platform handle and obs id for a standalone
    #alert, or add the group id for a combo alert.
    try:
      self.emailMsgs = defaultdict(dict)
      emailAlertGroups = self.checkForAlerts()    
      for email in emailAlertGroups:
        self.logger.debug("Processing alert for: %s" % (email))
        for platform in emailAlertGroups[email]:
          for group in emailAlertGroups[email][platform]:
            list = emailAlertGroups[email][platform][group]
            #Build up the 'AND' conditions
            sendAlert = True
            #msg = emailMsg()
            obsAlertMsg = '' 
            if( len( list ) == 0 ):
              self.logger.debug( "No email alerts in list." ) 
              continue;
            for emailAlert in list:
              if( self.obsDB.dbType == dbTypes.SQLite ):                                         
                whereConditions = "m_date > strftime( '%%Y-%%m-%%dT%%H:%%M:%%S', datetime('now',\"-%d seconds\") ) AND multi_obs.m_type_id = %d AND platform_handle = '%s'" \
                                  %( emailAlert.alertInterval, emailAlert.id, platform )
                sql = "SELECT obs_type.standard_name, max(multi_obs.m_date) AS date,uom_type.standard_name AS uom, multi_obs.m_value, multi_obs.m_type_id FROM multi_obs \
                       LEFT JOIN  m_type on multi_obs.m_type_id = m_type.row_id \
                       LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id \
                      LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id \
                      LEFT JOIN  uom_type on uom_type.row_id = m_scalar_type.uom_type_id \
                       WHERE %s \
                      GROUP BY obs_type.standard_name,multi_obs.m_value,uom_type.standard_name,multi_obs.m_type_id \
                      ORDER BY date DESC;" \
                      %( whereConditions )
              else:
                #Inner query to determine the max date which will be the most current update. PostGres forces
                #the GROUP BY to contain each column in the SELECT. Since we are getting the m_value for each row
                #the rows become unique and we can't use the GROUP BY in the fashion we used it above to pair down 
                #the data to just the most recent data.
                innerMaxDateSelect ="m_date = (SELECT max(multi_obs.m_date) FROM multi_obs  WHERE m_date >  (now() - interval '%d seconds') AT TIME ZONE 'UTC' AND platform_handle = '%s')"\
                                    % (emailAlert.alertInterval,platform)
                whereConditions = "%s AND multi_obs.m_type_id = %d AND platform_handle = '%s'" \
                                  %( innerMaxDateSelect, emailAlert.id, platform )
                sql = "SELECT obs_type.standard_name, multi_obs.m_date,uom_type.standard_name AS uom, multi_obs.m_value, multi_obs.m_type_id FROM multi_obs \
                       LEFT JOIN  m_type on multi_obs.m_type_id = m_type.row_id \
                       LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id \
                       LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id \
                       LEFT JOIN  uom_type on uom_type.row_id = m_scalar_type.uom_type_id \
                       WHERE %s \
                      ORDER BY obs_type.standard_name ASC;" \
                      %( whereConditions )
                

              dbCursor = self.obsDB.executeQuery( sql )
              self.logger.debug( "SQL: %s" %(sql) )
              if( dbCursor != None ):
                row = dbCursor.fetchone()
                if( row != None ):
                  #Convert the native uom into imperial.      
                  uom = self.uomConverter.getConversionUnits( row['uom'], 'en' )
                  if( len( uom ) == 0 ):
                    uom = row['uom']
                    self.logger.debug( "uom: %s" %(uom) )
                  val = float(row['m_value'])
                  if( len(uom) > 0 ):
                    val = self.uomConverter.measurementConvert( val, row['uom'], uom )              
                  if( val == None ):
                    val = float(row['m_value'])
                  #self.logger.debug( "val: %s Limits: %f" %(val,emailAlert.limit) )
                  #If the value does not exceed the limit, break out of the loop since we have failed one part of the
                  #combo and need not continue.
                  testCase = "%4.1f %s %4.1f" %(val, emailAlert.operator, emailAlert.limit)
                  sendAlert = eval(testCase, {}, {})
                  self.logger.debug("Testing function: %s" %(testCase))
                  #if( val <= emailAlert.limit ):
                  if(sendAlert == False):
                    #sendAlert = False
                    break
                  else:
                    #DWR 2011-11-15
                    #Use the display names to clean up the email.
                    displayLabel = self.uomConverter.getDisplayObservationName(row['standard_name'])
                    if(displayLabel == None):
                      displayLabel = row['standard_name']
                    #DWR 2011-11-15
                    #Use the display unit of measurement to clean up the email.
                    imperialUOM = self.uomConverter.getConversionUnits( row['uom'], 'en' )
                    if(imperialUOM == None or len(imperialUOM) == 0):
                      displayUOM = row['uom']
                    else:
                      displayUOM = self.uomConverter.getUnits( row['uom'], imperialUOM )          
                      if(displayUOM == None):
                        displayUOM = imperialUOM              
                    
                    obsAlertMsg += "<li><b>Observation:</b> %s: %4.1f %s(Limit(%s): %4.1f %s)</li>" % ( displayLabel,val,displayUOM,emailAlert.operator, emailAlert.limit,uom)
                    self.logger.debug( "Alert: <li><b>Observation:</b> %s: %4.1f %s(Limit: %4.1f %s)</li>" % ( displayLabel,val,displayUOM,emailAlert.limit,uom) ) 
                    #If the group is marked as single, this means it is a standalone alert.                   
                    if( group == 'single' ):
                      sendAlert = False
                      self.createEmailMsg(email, emailAlert, platform, obsAlertMsg)                      
                else:
                  #if( group != 'single' ):
                  sendAlert = False                  
                  self.logger.debug( "No row returned from last query." ) 
              else:
                if( len( self.obsDB.lastErrorMsg ) ):
                  self.logger.error( self.obsDB.lastErrorMsg )
                  self.obsDB.lastErrorMsg = ''
                else:
                  self.logger.debug( "dbCursor is None from last query" )
                sendAlert = False
                #if( group != 'single' ):
                #  sendAlert = False
                break
            if(sendAlert):
              self.createEmailMsg(email, emailAlert, platform, obsAlertMsg, list)
              
      #If we have any msgs in our email dict, then let's send them out.
      if( len( self.emailMsgs ) ):
        self.sendEmailAlerts( self.emailMsgs )
      #Empty the email dict.
      self.emailMsgs.clear()     

    except Exception, E:
      self.logger.error( str(E) )
      sys.exit(-1)

  def createEmailMsg(self, emailAddy, emailAlert, platform, obsAlertMsg, list=None):
    #Update the email time.
    utcSecs = time.time()
    self.alertsDB.updateAlertLastEmailTime(emailAlert,utcSecs)

            
    msg = emailMsg()
    msg.alertObsList = obsAlertMsg;
    #Build the unsubscribe link.
    msg.unsubscribe = self.unsubURL
    #Add the operation type
    msg.unsubscribe += 'operation=unsubscribe'
    #Replace the email tag placeholder with the email addy.
    msg.unsubscribe += "&EMAIL=%s" % (emailAddy)
    #Now figure out if the email alert was for a group of conditions, or a single.
    if( emailAlert.grpID != None ):
      msg.unsubscribe += '&GRPID=%d' % (emailAlert.grpID)
    else:
      msg.unsubscribe += '&PLATFORM=%s&OBSID=%d' % (emailAlert.platform,emailAlert.id)
      
    #If we got an alert, let's query and get the other measurements that weren't part of the alert test.
    ignoreIDs = ''
    if(list != None):
      for emailAlert in list:
        if( len(ignoreIDs) ):
          ignoreIDs += " AND "                
        ignoreIDs += "multi_obs.m_type_id <> %d" % ( emailAlert.id )
    else:
      ignoreIDs += "multi_obs.m_type_id <> %d" % ( emailAlert.id )
        
    if( self.obsDB.dbType == dbTypes.SQLite ):                                         
      whereConditions = "m_date > strftime( '%%Y-%%m-%%dT%%H:%%M:%%S', datetime('now',\"-%d seconds\") ) AND (%s) AND platform_handle = '%s'" \
                        %( emailAlert.alertInterval, ignoreIDs, platform )
      sql = "SELECT multi_obs.m_value, obs_type.standard_name, uom_type.standard_name AS uom, max(multi_obs.m_date) AS date,multi_obs.m_type_id FROM multi_obs \
             LEFT JOIN  m_type on multi_obs.m_type_id = m_type.row_id \
             LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id \
            LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id \
            LEFT JOIN  uom_type on uom_type.row_id = m_scalar_type.uom_type_id \
             WHERE %s \
            GROUP BY obs_type.standard_name,uom_type.standard_name,multi_obs.m_type_id,multi_obs.m_value \
            ORDER BY date DESC, obs_type.standard_name ASC;" \
            %( whereConditions )
    else:
      #Inner query to determine the max date which will be the most current update. PostGres forces
      #the GROUP BY to contain each column in the SELECT. Since we are getting the m_value for each row
      #the rows become unique and we can't use the GROUP BY in the fashion we used it above to pair down 
      #the data to just the most recent data.
      innerMaxDateSelect ="m_date = (SELECT max(multi_obs.m_date) FROM multi_obs  WHERE m_date >  (now() - interval '%d seconds') AT TIME ZONE 'UTC' AND platform_handle = '%s')"\
                          % (emailAlert.alertInterval,platform)
      whereConditions = "%s AND (%s) AND platform_handle = '%s'" \
                        %( innerMaxDateSelect, ignoreIDs, platform )
      sql = "SELECT obs_type.standard_name, multi_obs.m_date,uom_type.standard_name AS uom, multi_obs.m_value, multi_obs.m_type_id FROM multi_obs \
             LEFT JOIN  m_type on multi_obs.m_type_id = m_type.row_id \
             LEFT JOIN m_scalar_type on m_scalar_type.row_id = m_type.m_scalar_type_id \
             LEFT JOIN obs_type on  obs_type.row_id = m_scalar_type.obs_type_id \
             LEFT JOIN  uom_type on uom_type.row_id = m_scalar_type.uom_type_id \
             WHERE %s \
            ORDER BY obs_type.standard_name ASC;" \
            %( whereConditions )                                                                                
    dbCursor = self.obsDB.executeQuery( sql )
    if( dbCursor != None ):
      for row in dbCursor:
        uom = self.uomConverter.getConversionUnits( row['uom'], 'en' )
        if( len( uom ) == 0 ):
          uom = row['uom']
        val = self.uomConverter.measurementConvert( float(row['m_value']), row['uom'], uom )              
        if( val == None ):
          val = float(row['m_value'])

        #DWR 2011-11-15
        #Use the display names to clean up the email.
        displayLabel = self.uomConverter.getDisplayObservationName(row['standard_name'])
        if(displayLabel == None):
          displayLabel = row['standard_name']
        #DWR 2011-11-15
        #Use the display unit of measurement to clean up the email.
        imperialUOM = self.uomConverter.getConversionUnits( row['uom'], 'en' )
        if(imperialUOM == None or len(imperialUOM) == 0):
          displayUOM = row['uom']
        else:
          displayUOM = self.uomConverter.getUnits( row['uom'], imperialUOM )          
          if(displayUOM == None):
            displayUOM = imperialUOM              
                  
        msg.obsList += "<li>%s: %4.1f %s</li>" % ( displayLabel, val, displayUOM )
        self.logger.debug( "<li>%s: %4.1f %s</li>" % ( displayLabel, val, displayUOM ) )
                          
    #Get platform URL
    sql = "SELECT url\
         FROM platform\
         WHERE platform_handle='%s';"\
         %(platform)
    dbCursor = self.obsDB.executeQuery( sql )
    if( dbCursor != None ):
      row = dbCursor.fetchone()
      if(row != None):
        msg.url = row['url']
        self.logger.debug( "Url: %s" %(msg.url) )
    else:
      #Check to see if the query returned nothing because an error occured.
      if( len( self.obsDB.lastErrorMsg ) ):
        self.logger.error( self.obsDB.lastErrorMsg )
        self.obsDB.lastErrorMsg = ''

    #Alert triggered for this group so let's save the info off.
    emailList = []
    if( ( emailAlert.platform in self.emailMsgs[emailAddy] ) == False ):
      self.emailMsgs[emailAddy][emailAlert.platform] = emailList
    #Email already exists, so let's use it. 
    else:
      emailList = self.emailMsgs[emailAddy][emailAlert.platform]
    emailList.append( msg )
        
    return(msg)                
    
  def sendEmailAlerts(self,emailMsgs):
    import smtplib
    from email.MIMEMultipart import MIMEMultipart
    from email.MIMEText import MIMEText
  
    DISCLAIMER = "DISCLAIMER: Data to be used at your own risk. These realtime data are considered provisional. This data should not be used for life saving efforts."; 
    GEORSSURL = self.georssURL
    SURVEYURL  = self.surveyURL
    
    for email in emailMsgs:
      SERVER = "inlet.geol.sc.edu"  
      FROM = "dan@inlet.geol.sc.edu"
      TO = [email] # must be a list     
      BODY=''      
        
      for platform in emailMsgs[email]:
        GEORSS = platform.lower()
        GEORSS = GEORSS.replace( '.','_')
        GEORSS = GEORSSURL + GEORSS + '_GeoRSS_latest.xml';
  
        emailList = emailMsgs[email][platform]      
        for emailMsg in emailList:
          BODY += "<hr/><table width=\"75%%\">\
                          <tr>\
                          <td>Platform Alert: <a href=\"%s\">%s</a>\
                          <p>You have requested notification for measurements exceeding your predefined limits.</p>\
                          <ul>\
                          %s\
                          </ul>\
                          <ul><ul>\
                          <li><b>Other observations on the same platform</b></li>\
                          %s\
                          </ul></ul>\
                          <ul>\
                          <li>Platform RSS feed, click <a href=\"%s\"> here </a></li>\
                          <li>Unsubscribe to this alert, click <a href=\"%s\"> here </a></li>\
                          <li>Please fill out our feedback page and let us know your who/what/wheres and how we can improve the information to better serve you. <a href = \"%s\">Survey</a></li>\
                          </ul>\
                          </td>\
                          </tr>\
                          <tr>\
                          <td>\
                          <p>%s</p>\
                          </td>\
                          </tr>\
                          </table>\
                          <br/>"\
                          %( emailMsg.url, platform, emailMsg.alertObsList, emailMsg.obsList, GEORSS, emailMsg.unsubscribe, SURVEYURL, DISCLAIMER )
  
      message = ("MIME-Version: 1.0\r\nContent-type: text/html; \
      charset=utf-8\r\nFrom: %s\r\nTo: %s\r\nSubject: Observation Alerts\r\n" %
      (FROM, ", ".join(TO))) + BODY        
      # Send the mail
      try:   
        server = smtplib.SMTP(SERVER)
        server.sendmail(FROM, TO, message)
        server.quit()       
        self.logger.debug( "Sending alert email to: %s" % (TO) )
      except Exception, E:
        self.logger.error( str(E) )
        sys.exit(-1)
  def unsubscribeAlert(self, paramDict):
    #paramList = unsubscribeParams.split(',')
    #paramDict = {}
    #for param in unsubscribeParams:
    #  params = param.split("=")
    #  paramDict[params[0]]=params[1]
    
    email = None
    if( ( 'EMAIL' in paramDict ) == True ):
      email = paramDict['EMAIL']
    else:
      self.logger.error("No EMAIL parameter in the unsubscribe, cannot continue.")
      return( False )
    grpID = None
    platform = None
    obsID = None
    if( ( 'GRPID' in paramDict ) == True ):
      grpID = int(paramDict['GRPID'])
      self.logger.debug( "Unsubscribing: %s from email alert. grpID: %d" % (email,grpID) )
    else:
      platform = paramDict['PLATFORM']
      obsID = int(paramDict['OBSID'])
      self.logger.debug( "Unsubscribing: %s from email alert. Platform: %s obsID: %d" % (email,platform,obsID) )


    return( self.alertsDB.unsubscribe(email, platform, obsID, grpID) )
        
if __name__ == '__main__':
  logger = None
  try:
    parser = optparse.OptionParser()
    parser.add_option("-c", "--XMLConfigFile", dest="xmlConfigFile",
                      help="XML Configuration file." )   
    parser.add_option("-x", "--XML", dest="xml",
                      help="XML Alerts message to parse" )
    parser.add_option("-s", "--SaveAlert", dest="saveAlert",
                      help="The XML message containing the new alert to parse.",
                      action="store_true" )
    parser.add_option("-u", "--Unsubscribe", dest="unsubscribeAlert",
                      help="Flag that specifies we are unsubscribing from an alert",
                      action="store_true" )
    parser.add_option("-p", "--UnsubscribeParams", dest="unsubscribeParams",
                      help="Parameters for the unsubscribe request" )
    parser.add_option("-a", "--CheckAlerts", dest="checkAlerts",
                      help="Flag that specifies we are checking for alerts",
                      action="store_true" )
  
    (options, args) = parser.parse_args()
  
    configSettings = xmlConfigFile( options.xmlConfigFile )
    
    #2011-11-15 DWR
    #Use python logging config file.
    #logFile = configSettings.getEntry("//environment/logging/logFilename")
    logFile = configSettings.getEntry("//environment/logging/configFile")        
    logging.config.fileConfig(logFile)
    logger = logging.getLogger("emailalert_logger")

    """
    backupCount = configSettings.getEntry("//environment/logging/backupCount")
    maxBytes = configSettings.getEntry("//environment/logging/maxBytes")
    logFileExists = True
    #If the log file does not exist, we want to make sure when we create it to give everyone write access to it.
    if(os.path.isfile(logFile) != True):
      logFileExists = False
    logger = logging.getLogger("emailalert_logger")
    logger.setLevel(logging.DEBUG)
    # create formatter and add it to the handlers
    formatter = logging.Formatter("%(asctime)s,%(name)s,%(levelname)s,%(lineno)d,%(message)s")
    #Create the log rotation handler.
    #handler = logging.handlers.RotatingFileHandler( logFile, "a", maxBytes, backupCount )
    handler = logging.handlers.GroupWriteRotatingFileHandler = GroupWriteRotatingFileHandler
    handler = logging.handlers.GroupWriteRotatingFileHandler( logFile, "a", maxBytes, backupCount )
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(formatter)    
    logger.addHandler(handler)
    if(logFileExists != True):
      currMode = os.stat(logFile).st_mode
      #Since the email alert module can be used by web service as well as from command line, we want to change
      #the file permissions to give everyone access to it. Probably would be better to use group permissions
      #only, but for now we grant all.
      os.chmod(logFile, currMode | (stat.S_IXUSR|stat.S_IWGRP|stat.S_IXGRP|stat.S_IROTH|stat.S_IWOTH|stat.S_IXOTH))
      
    # add the handlers to the logger
    """
    logger.info('Log file opened')
    
    procAlerts = emailAlerts( configSettings )
    
    retVal = -1
    if( options.saveAlert ):
      logger.info( "Saving new email alert. Params: %s" % (options.xml) )
      procAlerts.saveXMLAlerts(options.xml)
    elif( options.checkAlerts ):   
      logger.info( "Checking email alerts." )
      procAlerts.processAlerts()
    elif( options.unsubscribeAlert):
      logger.info( "Unsubscribing from email alert. Params: %s" %( options.unsubscribeParams ) )
      if( procAlerts.unsubscribeAlert(options.unsubscribeParams) ):
        retVal  = 1
      else:
        retVal = 0
     
    logger.info('Closing log file.')
    #handler.close()
    
    sys.exit(retVal)

  except Exception, E:
    import sys
    import traceback

    info = sys.exc_info()        
    excNfo = traceback.extract_tb(info[2],1)
    items = excNfo[0]
    errMsg = 'ERROR: %s File: %s Line: %s Function: %s' % (str(E),items[0],items[1],items[2]) 
    if( logger != None ):
      logger.error( errMsg )
    print( errMsg )
    sys.exit(-1)
  
