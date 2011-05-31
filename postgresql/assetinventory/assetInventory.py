import sys
import os
import optparse
import time
import urllib
import urllib2
from urllib2 import Request, urlopen, URLError, HTTPError
import pickle
import traceback
from sqlalchemy import exc
from sqlalchemy.orm.exc import *

from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 
from xeniatools.xenia import uomconversionFunctions



class assetInventory(object):
  def __init__(self, baseUrl=None):
    self.baseUrl = baseUrl
    return 

  def doRequest(self, query):
    data = None
    try:       
      #The requests to the inventory are structure as follows:
      #url/title/request type
      #The title is defined in the inventory directory as the "title" field.
      #The request type are the same(hopefully stay that way) as the "get" functions defined below.
      #An example is: http://inventory.secoora.org/platforms/capers-island-buoy-2/getLocationDescription
      url = "%s/%s" % (self.baseUrl,query)
      request = urllib2.Request(url)
      response = urllib2.urlopen(request)
      data = response.read()
    
    except URLError, e:
      #If there is a code member and it is 204, that means there was nothing for the server to return.
      if(hasattr(e, 'code') and e.code == 204):
        data = ""
      else:
        print e.reason
    except HTTPError, e:
      print 'An HTTP error occured. Error code: ', e.code      
    return(data)
    
  def getDirectory(self, url=None):
    directory = None
    if(url != None):
      directoryUrl = url
    
    data = self.doRequest("directory")
    if(data != None):
      directory = eval(data)  

    return(directory)    
  
  def getLocationDescription(self, urlId):
    query = "%s/%s" %(urlId,self.getLocationDescription.__name__)
    return(self.doRequest(query))
  def getPlatformId(self, urlId):
    query = "%s/%s" %(urlId,self.getLocationDescription.__name__)
    return(self.doRequest(query))
  def getRegionalId(self, urlId):
    query = "%s/%s" %(urlId,self.getRegionalId.__name__)
    return(self.doRequest(query))
  def getAgencyId(self, urlId):
    query = "%s/%s" %(urlId,self.getAgencyId.__name__)
    return(self.doRequest(query))
  def getResponsibleMember(self, urlId):
    query = "%s/%s" %(urlId,self.getResponsibleMember.__name__)
    return(self.doRequest(query))
  def getAssociatedEntities(self, urlId):
    query = "%s/%s" %(urlId,self.getAssociatedEntities.__name__)
    return(self.doRequest(query))
  def getMemberOwned(self, urlId):
    query = "%s/%s" %(urlId,self.getMemberOwned.__name__)
    return(self.doRequest(query))
  def getPlatformType(self, urlId):
    query = "%s/%s" %(urlId,self.getPlatformType.__name__)
    return(self.doRequest(query))
  def getDeploymentContactName(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentContactName.__name__)
    return(self.doRequest(query))
  def getDeploymentContactPhone(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentContactPhone.__name__)
    return(self.doRequest(query))
  def getDeploymentContactPhoneExt(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentContactPhoneExt.__name__)
    return(self.doRequest(query))
  def getDeploymentContactEmail(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentContactEmail.__name__)
    return(self.doRequest(query))
  def getDataContactName(self, urlId):
    query = "%s/%s" %(urlId,self.getDataContactName.__name__)
    return(self.doRequest(query))
  def getDataContactPhone(self, urlId):
    query = "%s/%s" %(urlId,self.getDataContactPhone.__name__)
    return(self.doRequest(query))
  def getDataContactPhoneExt(self, urlId):
    query = "%s/%s" %(urlId,self.getDataContactPhoneExt.__name__)
    return(self.doRequest(query))
  def getDataContactEmail(self, urlId):
    query = "%s/%s" %(urlId,self.getDataContactEmail.__name__)
    return(self.doRequest(query))
  def getPlatformStatus(self, urlId):
    query = "%s/%s" %(urlId,self.getPlatformStatus.__name__)
    return(self.doRequest(query))
  def getDeploymentStart(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentStart.__name__)
    return(self.doRequest(query))
  def getDeploymentEnd(self, urlId):
    query = "%s/%s" %(urlId,self.getDeploymentEnd.__name__)
    return(self.doRequest(query))
  def getEndReason(self, urlId):
    query = "%s/%s" %(urlId,self.getEndReason.__name__)
    return(self.doRequest(query))
  def getLocationDescription(self, urlId):
    query = "%s/%s" %(urlId,self.getLocationDescription.__name__)
    return(self.doRequest(query))
  def getLatitude(self, urlId):
    query = "%s/%s" %(urlId,self.getLatitude.__name__)
    return(self.doRequest(query))
  def getLongitude(self, urlId):
    query = "%s/%s" %(urlId,self.getLongitude.__name__)
    return(self.doRequest(query))
  def getElevation(self, urlId):
    query = "%s/%s" %(urlId,self.getElevation.__name__)
    return(self.doRequest(query))
  def getNearRealTime(self, urlId):
    query = "%s/%s" %(urlId,self.getNearRealTime.__name__)
    return(self.doRequest(query))
  def getSamplePeriod(self, urlId):
    query = "%s/%s" %(urlId,self.getSamplePeriod.__name__)
    return(self.doRequest(query))
  def getLatencyTime(self, urlId):
    query = "%s/%s" %(urlId,self.getLatencyTime.__name__)
    return(self.doRequest(query))
  def getDataURL(self, urlId):
    query = "%s/%s" %(urlId,self.getDataURL.__name__)
    return(self.doRequest(query))
  def getDataArchive(self, urlId):
    query = "%s/%s" %(urlId,self.getDataArchive.__name__)
    return(self.doRequest(query))
  def getDataPage(self, urlId):
    query = "%s/%s" %(urlId,self.getDataPage.__name__)
    return(self.doRequest(query))
  def getObservedVariables(self, urlId):
    query = "%s/%s" %(urlId,self.getObservedVariables.__name__)
    return(self.doRequest(query))
  def getIntendedAudience(self, urlId):
    query = "%s/%s" %(urlId,self.getIntendedAudience.__name__)
    return(self.doRequest(query))
  def getRelocatable(self, urlId):
    query = "%s/%s" %(urlId,self.getRelocatable.__name__)
    return(self.doRequest(query))
  def getExpandable(self, urlId):
    query = "%s/%s" %(urlId,self.getExpandable.__name__)
    return(self.doRequest(query))
  def getAssociatedModels(self, urlId):
    query = "%s/%s" %(urlId,self.getAssociatedModels.__name__)
    return(self.doRequest(query))
  def getModelNames(self, urlId):
    query = "%s/%s" %(urlId,self.getModelNames.__name__)
    return(self.doRequest(query))
  def getAssociatedApplications(self, urlId):
    query = "%s/%s" %(urlId,self.getAssociatedApplications.__name__)
    return(self.doRequest(query))
  def getApplicationNames(self, urlId):
    query = "%s/%s" %(urlId,self.getApplicationNames.__name__)
    return(self.doRequest(query))
  def getFunding(self, urlId):
    query = "%s/%s" %(urlId,self.getFunding.__name__)
    return(self.doRequest(query))
  def getInitialPurchaseCost(self, urlId):
    query = "%s/%s" %(urlId,self.getInitialPurchaseCost.__name__)
    return(self.doRequest(query))
  def getInitialDeploymentCost(self, urlId):
    query = "%s/%s" %(urlId,self.getInitialDeploymentCost.__name__)
    return(self.doRequest(query))
  def getAnnualPersonnelCost(self, urlId):
    query = "%s/%s" %(urlId,self.getAnnualPersonnelCost.__name__)
    return(self.doRequest(query))
  def getAnnualNonPersonnelCost(self, urlId):
    query = "%s/%s" %(urlId,self.getAnnualNonPersonnelCost.__name__)
    return(self.doRequest(query))
  
  
  
if __name__ == '__main__':
  
  try:
    import psyco
    psyco.full()
  except Exception, E:
    print("psyco package not installed, will not be able to accelerate the program.")
      
  parser = optparse.OptionParser()
  
  parser.add_option("-r", "--BaseUrl", dest="baseUrl",
                    help="The url to the asset directory page." )
  parser.add_option("-d", "--dbName", dest="dbName",
                    help="The name of the xenia database to connect to." )
  parser.add_option("-o", "--dbHost", dest="dbHost",
                    help="The xenia database host address to connect to." )
  parser.add_option("-u", "--dbUser", dest="dbUser",
                    help="The xenia database user name to connect with." )
  parser.add_option("-p", "--dbPwd", dest="dbPwd",
                    help="The xenia database password name to connect with." )
  parser.add_option("-f", "--ResultsFile", dest="resultsFile",
                    help="" )
  
  (options, args) = parser.parse_args()
  
  try:
    outFile = open(options.resultsFile, "w")
    
    inventory = assetInventory(baseUrl=options.baseUrl)
    directoryObjs = inventory.getDirectory()
    if(directoryObjs == None):
      print("Did not receive a valid directory object, cannot continue.")
      sys.exit(-1)
      
    db = xeniaAlchemy()
    if(db.connectDB("postgresql+psycopg2", options.dbUser, options.dbPwd, options.dbHost, options.dbName, False) != True):
      print("Unable to connect to database. Host: %s DBName: %s" %(options.dbHost, options.dbName))
      sys.exit(-1)
    
    #First pass to log out platforms that aren't in our database.
    outFile.write("Platforms not in database.\n\n")
    for mooring in directoryObjs:
      if(len(mooring['regionalId']) == 0):
        type = inventory.getPlatformType(mooring['urlId'])
        if(type == None):
          type = ""
        status = inventory.getPlatformStatus(mooring['urlId'])
        if(status == None):
          status = ""
        responsible = inventory.getResponsibleMember(mooring['urlId'])
        if(responsible == None):
          responsible = ""          
        lon = inventory.getLongitude(mooring['urlId'])
        if(lon == None):
          lon = ""
        lat = inventory.getLatitude(mooring['urlId'])
        if(lat == None):
          lat = ""
        #Check to see if the agencyId is something we match on.
        potentialPlatform = ""
        if(len(mooring['agencyId'])):
          try:
            rec = db.session.query(platform).filter(platform.short_name == mooring['agencyId']).one()
            potentialPlatform = rec.platform_handle
          #Didn't find anything that matchched, so this most likely is not in the database
          except NoResultFound, e:
            potentialPlatform = ""
        outFile.write("%s|%s|%s|%s|%s|%s|%s|%s\n" %(mooring['title'],
                                  mooring['agencyId'],
                                  type,
                                  status,
                                  responsible,
                                  lon,
                                  lat,
                                  potentialPlatform))

    outFile.write("\nPlatform Descriptions\n\n")
    for mooring in directoryObjs:
      if(len(mooring['regionalId']) != 0):
        inventory.getDeploymentEnd(mooring['urlId'])
        desc = inventory.getLocationDescription(mooring['urlId'])
        rec = db.session.query(platform).filter(platform.platform_handle == mooring['regionalId']).one()
        outFile.write("%s|DB: %s| Inv: %s\n" %(mooring['regionalId'], rec.description, desc))
        
    outFile.close()      
  except Exception, E:
    print( traceback.print_exc() )
