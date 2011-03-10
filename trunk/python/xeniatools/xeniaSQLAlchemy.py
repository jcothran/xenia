import time


from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey, DateTime, Float
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import eagerload
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship, backref
from sqlalchemy import exc
from sqlalchemy.orm.exc import *

Base = declarative_base()

class organization(Base):
  __tablename__ = 'organization'
  row_id           = Column(Integer,primary_key=True)                     
  row_entry_date   = Column(DateTime)       
  row_update_date  = Column(DateTime)       
  short_name       = Column(String(50))       
  active           = Column(Integer)                     
  long_name        = Column(String(200))      
  description      = Column(String(1000))    
  url              = Column(String(200))      
  opendap_url      = Column(String(200))      
  email_tech       = Column(String(150))                     

class platform(Base):
  __tablename__ = 'platform'
  row_id           = Column(Integer,primary_key=True)                     
  row_entry_date   = Column(DateTime)       
  row_update_date  = Column(DateTime)       
  organization_id  = Column(Integer,ForeignKey(organization.row_id))                     
  type_id          = Column(Integer)                     
  short_name       = Column(String(50))       
  platform_handle  = Column(String(100))      
  fixed_longitude  = Column(Float)            
  fixed_latitude   = Column(Float)            
  active           = Column(Integer)                     
  begin_date       = Column(DateTime(timezone=False)) 
  end_date         = Column(DateTime(timezone=False)) 
  project_id       = Column(Integer)                     
  app_catalog_id   = Column(Integer)                     
  long_name        = Column(String(200))      
  description      = Column(String(1000))    
  url              = Column(String(200))      
  metadata_id      = Column(Integer)                     
  #the_geom         geometry                 
  
  organization    = relationship(organization)   
  
   
class uom_type(Base):
  __tablename__ = 'uom_type'  
  row_id        = Column(Integer,primary_key=True)                     
  standard_name = Column(String(50))      
  definition    = Column(String(1000))      
  display       = Column(String(50))      
  
class obs_type(Base):
  __tablename__ = 'obs_type'  
  row_id        = Column(Integer,primary_key=True)                     
  standard_name = Column(String(50))      
  definition    = Column(String(1000))      

class m_scalar_type(Base):
  __tablename__ = 'm_scalar_type'  
  row_id        = Column(Integer,primary_key=True)                     
  obs_type_id   = Column(Integer,ForeignKey(obs_type.row_id))                     
  uom_type_id   = Column(Integer,ForeignKey(uom_type.row_id))            
  
  obs_type = relationship(obs_type)
  uom_type = relationship(uom_type)          

class m_type(Base):
  __tablename__ = 'm_type'  
  row_id           = Column(Integer,primary_key=True)                     
  num_types        = Column(Integer)
  description      = Column(String(1000))    
  m_scalar_type_id  = Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_2= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_3= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_4= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_5= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_6= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_7= Column(Integer,ForeignKey(m_scalar_type.row_id))
  m_scalar_type_id_8= Column(Integer,ForeignKey(m_scalar_type.row_id))
  
  #We have to declare the primaryjoin statement since we have multiple ForeignKeys that point
  #to the same relationship.
  scalar_type = relationship(m_scalar_type, primaryjoin=(m_scalar_type_id==m_scalar_type.row_id))
  
class sensor(Base):
  __tablename__ = 'sensor'
  row_id           = Column(Integer,primary_key=True)                     
  row_entry_date   = Column(DateTime)       
  row_update_date  = Column(DateTime)       
  platform_id      = Column(Integer,ForeignKey(platform.row_id))                     
  type_id          = Column(Integer)                     
  short_name       = Column(String(50))       
  m_type_id        = Column(Integer,ForeignKey(m_type.row_id))
  fixed_z          = Column(Float)
  active           = Column(Integer)                     
  begin_date       = Column(DateTime(timezone=False)) 
  end_date         = Column(DateTime(timezone=False)) 
  s_order          = Column(Integer)
  url              = Column(String(200))      
  metadata_id      = Column(Integer)                     
  report_interval  = Column(Integer)                     
  
  platform = relationship(platform)
  m_type = relationship(m_type)
  
class multi_obs(Base):
  __tablename__ = 'multi_obs'  
  row_id           = Column(Integer,primary_key=True)                     
  row_entry_date   = Column(DateTime)    
  row_update_date  = Column(DateTime)    
  platform_handle  = Column(String(100))    
  sensor_id        = Column(Integer,ForeignKey(sensor.row_id))                     
  m_type_id        = Column(Integer,ForeignKey(m_type.row_id))                     
  m_date           = Column(DateTime(timezone=False)) 
  m_lon            = Column(Float)            
  m_lat            = Column(Float)             
  m_z              = Column(Float)             
  m_value          = Column(Float)             
  m_value_2        = Column(Float)             
  m_value_3        = Column(Float)             
  m_value_4        = Column(Float)             
  m_value_5        = Column(Float)             
  m_value_6        = Column(Float)             
  m_value_7        = Column(Float)             
  m_value_8        = Column(Float)             
  qc_metadata_id   = Column(Integer)                     
  qc_level         = Column(Integer)                     
  qc_flag          = Column(String(100))         
  qc_metadata_id_2 = Column(Integer)                     
  qc_level_2       = Column(Integer)                     
  qc_flag_2        = Column(String(100))         
  metadata_id      = Column(Integer)                     
  d_label_theta    = Column(Integer)                     
  d_top_of_hour    = Column(Integer)                     
  d_report_hour    = Column(DateTime(timezone=False)) 
  #the_geom         = geometry                    
  
  m_type          = relationship(m_type)
  sensor          = relationship(sensor)
  
  
  def __init__(self, 
              row_id           = None,
              row_entry_date   = None,
              row_update_date  = None,
              platform_handle  = None,
              sensor_id        = None,
              m_type_id        = None,
              m_date           = None,
              m_lon            = None,
              m_lat            = None,
              m_z              = None,
              m_value          = None,
              m_value_2        = None,
              m_value_3        = None,
              m_value_4        = None,
              m_value_5        = None,
              m_value_6        = None,
              m_value_7        = None,
              m_value_8        = None,
              qc_metadata_id   = None,
              qc_level         = None,
              qc_flag          = None,
              qc_metadata_id_2 = None,
              qc_level_2       = None,
              qc_flag_2        = None,
              metadata_id      = None,
              d_label_theta    = None,
              d_top_of_hour    = None,
              d_report_hour    = None
              ):
    self.row_id           = row_id          
    self.row_entry_date   = row_entry_date  
    self.row_update_date  = row_update_date 
    self.platform_handle  = platform_handle 
    self.sensor_id        = sensor_id       
    self.m_type_id        = m_type_id       
    self.m_date           = m_date          
    self.m_lon            = m_lon           
    self.m_lat            = m_lat           
    self.m_z              = m_z             
    self.m_value          = m_value         
    self.m_value_2        = m_value_2       
    self.m_value_3        = m_value_3       
    self.m_value_4        = m_value_4       
    self.m_value_5        = m_value_5       
    self.m_value_6        = m_value_6       
    self.m_value_7        = m_value_7       
    self.m_value_8        = m_value_8       
    self.qc_metadata_id   = qc_metadata_id  
    self.qc_level         = qc_level        
    self.qc_flag          = qc_flag         
    self.qc_metadata_id_2 = qc_metadata_id_2
    self.qc_level_2       = qc_level_2      
    self.qc_flag_2        = qc_flag_2       
    self.metadata_id      = metadata_id     
    self.d_label_theta    = d_label_theta   
    self.d_top_of_hour    = d_top_of_hour   
    self.d_report_hour    = d_report_hour   


class platform_status(Base):  
  __tablename__ = 'platform_status'
  row_id           = Column(Integer,primary_key=True)                     
  row_entry_date   = Column(DateTime(timezone=False))    
  begin_date       = Column(DateTime(timezone=False))    
  expected_end_date= Column(DateTime(timezone=False))    
  end_date         = Column(DateTime(timezone=False))    
  row_update_date  = Column(DateTime(timezone=False))    
  platform_handle  = Column(String(50))    
  author           = Column(String(100))    
  reason           = Column(String(500))    
  status           = Column(Integer)    
  platform_id      = Column(Integer, ForeignKey(platform.row_id))    
   
  platform = relationship(platform)

class sensor_status(Base):  
  __tablename__ = 'sensor_status'
  row_id           = Column(Integer,primary_key=True)
  sensor_id        = Column(Integer, ForeignKey(sensor.row_id))
  sensor_name      = Column(String(50))                     
  platform_id      = Column(Integer, ForeignKey(platform.row_id))    
  row_entry_date   = Column(DateTime(timezone=False))    
  begin_date       = Column(DateTime(timezone=False))    
  end_date         = Column(DateTime(timezone=False))    
  expected_end_date= Column(DateTime(timezone=False))    
  row_update_date  = Column(DateTime(timezone=False))    
  author           = Column(String(100))    
  reason           = Column(String(500))    
  status           = Column(Integer)    
 
  platform = relationship(platform)
  sensor   = relationship(sensor)
    
class xeniaAlchemy(object):
  def __init__(self, logger=None):
    self.dbEngine = None
    self.metadata = None
    self.session  = None
    self.logger   = logger
    
  def connectDB(self, databaseType, dbUser, dbPwd, dbHost, dbName, printSQL = False):
    
    try:
      #Connect to the database
      connectionString = "%s://%s:%s@%s/%s" %(databaseType, dbUser, dbPwd, dbHost, dbName) 
      self.dbEngine = create_engine(connectionString, echo=printSQL)
      
      #metadata object is used to keep information such as datatypes for our table's columns.
      self.metadata = MetaData()
      self.metadata.bind = self.dbEngine
      
      Session = sessionmaker(bind=self.dbEngine)  
      self.session = Session()
      
      self.connection = self.dbEngine.connect()
      
      return(True)
    except exc.OperationalError, e:
      if(self.logger != None):
        self.logger.exception(e)
    return(False)
  """
  Function: sensorExists
  Purpose: Checks to see if the passed in obsName on the platform.
  Parameters: 
    obsName is the sensor(observation) we are testing for.
    platform is the platform on which we search for the obsName.
    sOrder, if provided specifies the specific sensor if there are multiples of the same on a platform.
  Returns:
    The sensor id(row_id) if it exists, -1 if it does not exists, or None if an error occured. If there was an error
    lastErrorMsg can be checked for the error message.
  """
  def sensorExists(self, obsName, uom, platformHandle, sOrder=1 ):
    
    try:  
      rec = self.session.query(sensor.row_id)\
        .join((platform, platform.row_id == sensor.platform_id))\
        .join((m_type, m_type.row_id == sensor.m_type_id))\
        .join((m_scalar_type, m_scalar_type.row_id == m_type.m_scalar_type_id))\
        .join((obs_type, obs_type.row_id == m_scalar_type.obs_type_id))\
        .join((uom_type, uom_type.row_id == m_scalar_type.uom_type_id))\
        .filter(sensor.s_order == sOrder)\
        .filter(platform.platform_handle == platformHandle)\
        .filter(obs_type.standard_name == obsName)\
        .filter(uom_type.standard_name == uom).one()
      return(rec.row_id)
    except NoResultFound, e:
      if(self.logger != None):
        self.logger.debug(e)
    except exc.InvalidRequestError, e:
      if(self.logger != None):
        self.logger.exception(e)
    
    return(None)

  def getCurrentPlatformStatus(self, platformHandle):
    try:
      rec = self.session.query(sensor_status.status)\
          .filter(platform_status.platform_handle==platformHandle).one()
      return(rec.status)
    except NoResultFound, e:
      if(self.logger != None):
        self.logger.debug(e)
    except exc.InvalidRequestError, e:
      if(self.logger != None):
        self.logger.exception(e)
    return(None)  

  def getCurrentSensorStatus(self, obsName, platformHandle):
    try:
      rec = self.session.query(platform_status.status)\
          .filter(platform.platform_handle==platformHandle)\
          .filter(sensor_status.sensor_name==obsName).one()
      return(rec.status)
    except NoResultFound, e:
      if(self.logger != None):
        self.logger.debug(e)
    except exc.InvalidRequestError, e:
      if(self.logger != None):
        self.logger.exception(e)
    return(None)  
      
if __name__ == '__main__':
  xeniaDB = xeniaAlchemy()
