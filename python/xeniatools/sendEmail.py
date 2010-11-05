import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

class sendEmail(object):
  def __init__(self, server, fromAddy=None ):
    self.server = server
    if( fromAddy != NULL ):
      self.fromAddy = fromAddy
    self.contentType = 'text/plain';
  
  def setContentType(self, type ):
    self.contentType = type
    
  def sendEmailAlerts(self,emailMsg,toList):          

    message = ("MIME-Version: 1.0\r\nContent-type: %s; \
    charset=utf-8\r\nFrom: %s\r\nTo: %s\r\nSubject: Observation Alerts\r\n" %
    (self.contentType,self.fromAddy, ", ".join(toList))) + emailMsg        
    # Send the mail
    try:   
      server = smtplib.SMTP(self.fromAddy)
      server.sendmail(self.fromAddy, toList, message)
      server.quit()       
      self.logger.debug( "Sending alert email to: %s" % (TO) )
    except Exception, E:
      print( str(E) )
      sys.exit(-1)

