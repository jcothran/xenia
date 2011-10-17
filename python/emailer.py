import os
import sys
import datetime
import optparse
import logging
import logging.config
import ConfigParser
from xeniatools.utils import smtpClass
import string

import mimetypes
from email import encoders
from email.message import Message
from email.mime.audio import MIMEAudio
from email.mime.base import MIMEBase
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText



if __name__ == '__main__':
  try:
    import psyco
    psyco.full()
  except Exception,e:
    print("psyco not available for accelerating script.")
    
    
  try:
    logger = None
    parser = optparse.OptionParser()  
    parser.add_option("-l", "--LogConfigFile", dest="logConf",
                      help="Config file to use for the logging." )
    parser.add_option("-t", "--TemplateFile", dest="templateFile",
                      help="" )
    parser.add_option("-s", "--Substitutions", dest="substitutions",
                      help="A Key:Value list to use against the subject and body." )
    
  
    (options, args) = parser.parse_args()
    
    if(options.logConf):
      logging.config.fileConfig(options.logConf)
      logger = logging.getLogger("emailer_logger")
      logger.info("Session started")
      logger.info("Command line parameters: %s" %(options))
    
    subsDict = {}
    if(options.substitutions):
      keyVals = options.substitutions.split(",")
      for keyVal in keyVals:
        parts = keyVal.split(":",1)
        subsDict[parts[0]] = parts[1]
        if(logger != None):
          logger.debug("Substitution Key: %s Value: %s" % (parts[0], parts[1]))
    
    emailServerDict = {}
    config = ConfigParser.RawConfigParser()
    config.read(options.templateFile)
    emailServer = config.items("EmailServer")
    for entry in emailServer:
      key = entry[0]
      emailServerDict[key] = entry[1]
    recipients = config.get("To", "Recipients")
    recipients = recipients.split(",")
    messageNfoDict = {}
    messageNfo = config.items("Email")
    for entry in messageNfo:
      key = entry[0]
      messageNfoDict[key] = entry[1]
    
    smtp = smtpClass(emailServerDict['server'], emailServerDict['from'], emailServerDict['pwd'])
    
    messageNfoDict['attachments'] = messageNfoDict['attachments'] % (subsDict)
    fileAttachemnts = messageNfoDict['attachments'].split(",")
    for filePath in fileAttachemnts:
      filePath = filePath.replace('"', '')
      if(logger != None):
        logger.debug("Attaching file: %s" %(filePath))
      smtp.attach(filePath)
      
      
    smtp.from_addr("%s@%s" % (emailServerDict['from'],emailServerDict['server']))
    if(logger != None):
      logger.debug("Recipients %s" %(recipients))
    smtp.rcpt_to(recipients)
    subject = messageNfoDict['subject'] % (subsDict)
    smtp.subject(subject)
    body =  messageNfoDict['body'] % (subsDict)
    smtp.message(body)
    smtp.send()      
    
    if(logger != None):
      logger.info("Session ended")
    

  except Exception,e:
    if(logger != None):
      logger.exception(e)
    else:
      import traceback
      print(traceback.print_exc(e))