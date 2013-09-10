import logging.config
import ConfigParser

"""
Class: dataIngestion
Purpose: THis is the base class to use to connect to a data source and bring it into the the xenia database.
This is strictly a class to override, there is no database connection here. The idea is to have a standard interface 
and simply create an object instance, then call processData.
"""  
class dataIngestion(object):
  def __init__(self, configFile, logger=True):
    
    self.logger = None
    if(logger):
      self.logger = logging.getLogger(type(self).__name__)

    if(configFile):
      self.config = ConfigParser.RawConfigParser()
      self.config.read(configFile)
      
  def processData(self):    
    recList = self.getData()
    self.saveData(recList)
    return(None)
    
  def getData(self):
    return([])
  
  def saveData(self, recordList):
    return
