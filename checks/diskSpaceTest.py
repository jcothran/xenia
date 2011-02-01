import os
import optparse
from xeniatools.utils import smtpClass


if __name__ == '__main__':
  
  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
      
  parser = optparse.OptionParser()
  
  parser.add_option("-c", "--CheckList", dest="checkList",
                    help="Tuple list of directory and alert percentage." )
  parser.add_option("-e", "--EmailList", dest="emailList",
                    help="Comma separated list of alert recipients.")
  parser.add_option("-s", "--SMTPServer", dest="smtpServer",
                    help="Email server to use to send email alert.")
  parser.add_option("-f", "--From", dest="emailUser",
                    help="The user account the email is sent from.")
  parser.add_option("-p", "--Pwd", dest="emailPwd",
                    help="The email user account password.")
  parser.add_option("-n", "--MachineIdentifier", dest="machineIdentifier",
                    help="String used to ID the machine the alert message is from.")
  parser.add_option("-a", "--SendAnyResult", dest="sendAnyResult",action= 'store_true', 
                    help="If set, this will send an email for any test result, not just one that does not pass percentage test.")
  
  (options, args) = parser.parse_args()
  toList = []
  if(options.emailList == None or len(options.emailList) == 0):
    print("No email addresses provided to send an alert to.")
  else:
    toList = options.emailList.split(',')

  sendEmail = False    
  if(options.sendAnyResult):
    sendEmail = True
    
  subject = "[secoora_auto_alert]Free Disk Space "
  smtp = smtpClass(options.smtpServer, options.emailUser, options.emailPwd)
  smtp.from_addr("%s@%s"%(options.emailUser,options.smtpServer))
  
  dirList = options.checkList.split(',')
  msg = ""
  testFail = False
  for entry in dirList:
    parts = entry.split(';')
    print("Testing directory: \"%s\", test percentage: %d" %(parts[0],int(parts[1])))
    stats = os.statvfs(parts[0])
    freespace = (stats.f_bavail * stats.f_frsize) / 1024
    totaldiskspace = (stats.f_blocks * stats.f_frsize) / 1024
    percentFree = (freespace / float(totaldiskspace)) * 100.0
    if(len(msg)):
      msg += "\n\n"
    if(percentFree < int(parts[1])):
      msg += "Machine: %s\nALERT Free Space test failed.\nDirectory:%s Test Percentage: %d\nFree Space Remaining: %4.2f%%\nFreespace: %d Totalspace: %d\n"\
        %(options.machineIdentifier, parts[0], int(parts[1]), percentFree, freespace, totaldiskspace)
      testFail = True
      print(msg)
    else:
      if(sendEmail):
        msg += ("Machine: %s\nDirectory:%s Test Percentage: %d\nFreespace: %d Totalspace: %d Percentage free: %f\n" \
               %(options.machineIdentifier, parts[0], int(parts[1]), freespace,totaldiskspace, percentFree))    
        print(msg)
  if((sendEmail or testFail) and len(toList)):
    if(testFail):
      subject += "ALERT"
    smtp.rcpt_to(toList)
    smtp.subject(subject)
    smtp.message(msg)
    smtp.send()      
