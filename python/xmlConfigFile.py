from lxml import etree



'''
Class: xmlConfigFile
Purpose: Base class for working with "standard" xml configuration files.
'''

class xmlConfigFile(object):
  def __init__(self, xmlConfigFileName, parseFile=True):
    self.xmlConfigFileName = xmlConfigFileName
    #We want to go ahead and parse the file in memory.
    if( parseFile ):
      self.xmlTree = etree.parse(self.xmlConfigFileName)
  '''
  Function: getEntry
  Purpose: Attemps to look up a xml tag hierarchy and returns the associated text if found.
  Parameters:
    xmlTag is the xpath tag to look for. In the form of \\root\child\node
  Returns: 
    The text associated with the path, or None if not found.
  '''
  def getEntry(self, xmlTag, xmlElement=None ):
    if( xmlElement == None ):
      xmlElement = self.xmlTree  
    tag = xmlElement.xpath( xmlTag )
    if( len(tag) ):
      return( tag[0].text )
    return(None)
  
  '''
  Function: getListHead
  Purpose: For a section that is a list for a particular set of parameters, this returns the
    Element which will be the head of the list. To iterate over this list, call getNextInList()
  '''
  def getListHead(self, xmlTag):
    return( self.xmlTree.xpath( '//environment/twitterList') )
  
  def getNextInList(self, elementList ):
    return( elementList[0].getchildren() )
  '''
  Function: getDatabaseSettings
  Purpose: Returns various settings from the database section of the config file.
  The structure for this section is:
    <environment>
      <database>
        <db>
          <type></type>
          <name></name>
          <user></user>
          <pwd></pwd>
          <host></host>
        </db>
      </database> 
   Parameters: None
   Return: Returns a keyed dictionary which could have the following keys.
     For sqlite:
       ['type'] is the type of the database, will contain 'sqlite'.
       ['dbName'] is the full path to the sqlite db file.
    For postgres
       ['type'] is the type of the database, will contain 'postgres'.
       ['dbName'] is the postgres database name.
       ['dbUser'] is the user to logon to the postgres server with.
       ['dbPwd'] is the password used for the dbUser above.
       ['dbHost'] is the IP address of the host machine running the postgres instance.
  '''
  def getDatabaseSettings(self):
    settings = None    
    type = self.getEntry( '//environment/database/db/type' )
    if( type != None ):
      if( type == 'sqlite' ):
        xmlVal = self.getEntry( '//environment/database/db/name' )
        if( xmlVal != None ):
          settings = {}
          settings['type']  = 'sqlite'
          settings['dbName'] = xmlVal
        else:
          return(None)
      elif( type == 'postgres' ):
        settings = {}
        settings['type']   = 'postgres'
        settings['dbName'] = self.getEntry( '//environment/database/db/name' )
        settings['dbUser'] = self.getEntry( '//environment/database/db/user' )
        settings['dbPwd']  = self.getEntry( '//environment/database/db/pwd' )
        settings['dbHost'] = self.getEntry( '//environment/database/db/host' )
       
    return( settings )
  