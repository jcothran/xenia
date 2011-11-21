#!/usr/bin/python

"""
Revisions
Author: DWR
Date: 2011-11-21
Function: handler
Changes: Added use of logging config file.
"""

from mod_python import apache
from mod_python import util


def handler(req):
  try:
    from xeniatools.emailAlertSystem import emailAlerts
    #from xeniatools.emailAlertSystem import GroupWriteRotatingFileHandler
    from xeniatools.xmlConfigFile import xmlConfigFile
    
    import os
    import stat
    import logging
    import logging.config
  
    
    configFile = '/home/xeniaprod/config/emailAlertsConfig.xml'
    
      
    req.log_error('handler')
    req.add_common_vars()
    
    req.content_type = 'text/plain;' 
    req.send_http_header()
      
    
    req.status = apache.HTTP_OK
    params = util.FieldStorage(req)
    
    configSettings = xmlConfigFile( configFile )
    #2011-11-21 DWR
    #Use python logging config file.
    #logFile = configSettings.getEntry("//environment/logging/logHandlerFilename")
    logFile = configSettings.getEntry("//environment/logging/configFileHandler")        
    logging.config.fileConfig(logFile)
    logger = logging.getLogger("emailalert_logger")
    
    """
    logFile = configSettings.getEntry("//environment/logging/modPythonHandlerFilename")
    backupCount = configSettings.getEntry("//environment/logging/backupCount")
    maxBytes = configSettings.getEntry("//environment/logging/maxBytes")
  
    logFileExists = True
    #If the log file does not exist, we want to make sure when we create it to give everyone write access to it.
    #if(os.path.isfile(logFile) != True):
    #  logFileExists = False
  
    logger = logging.getLogger("emailalert_logger")
    logger.setLevel(logging.DEBUG)
    # create formatter and add it to the handlers
    formatter = logging.Formatter("%(asctime)s,%(name)s,%(levelname)s,%(lineno)d,%(message)s")
    #Create the log rotation handler.
    #handler = logging.handlers.RotatingFileHandler( logFile, "a", maxBytes, backupCount )
    #handler = logging.handlers.GroupWriteRotatingFileHandler = GroupWriteRotatingFileHandler
    #handler = logging.handlers.GroupWriteRotatingFileHandler( logFile, "a", maxBytes, backupCount )
    #For now, seperate the web handler log file from the user log handler. The rollover doesn't seem to work
    #correctly.
    handler = logging.handlers.RotatingFileHandler( logFile, "a", maxBytes, backupCount )
  
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(formatter)    
    logger.addHandler(handler)
    """
      
    # add the handlers to the logger
    logger.info('Log file opened')
    
    operation = None
    if('operation' in params != False):
      operation = params['operation']
    if(operation != None):
      logger.debug( "Operation: %s" % (operation) )
      if(operation == 'add'):
        alertXML = None
        if('xml' in params != False):
          alertXML = params['xml']
          procAlerts = emailAlerts( configSettings )  
          logger.info( "Saving new email alert. Params: %s" % (alertXML) )
          if(procAlerts.saveXMLAlerts(alertXML)):
            output = "Successfully added email alert."
          else:
            output = "An error occured while adding the email alert. Please retry later."
          req.write(output)
        else:
          output = "Cannot complete request, there are missing parameters."      
          req.write(output)
          
      elif(operation == 'unsubscribe'):
        procAlerts = emailAlerts( configSettings )  
        logger.info( "Unsubscribing from email alert. Params: %s" % (params) )
        output = "Successfully unsubscribed from email alert."
        if( procAlerts.unsubscribeAlert(params)):
          output = "Successfully unsubscribed from email alert."
        else:
          output = "An error occured, unable to unsubscribe from the email alert"
        req.write(output)
      else:
        logger.error("Unknown operation parameter: %s" % (operation))
    else:
      output = "Cannot complete request, there are missing parameters."      
      req.write(output)
    logger.info('Closing log file.')
  
  except Exception,e:
    if(logger != None):
      logger.exception(e)
    else:
      print(e)
    req.write("An error has occured on the server, please try again later.")
  return apache.OK



