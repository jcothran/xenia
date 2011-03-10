import sys
import array
import time
import optparse
import math

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 

from xeniatools.xenia import dbXenia
from xeniatools.xenia import xeniaSQLite
from xeniatools.xenia import xeniaPostGres
from xeniatools.xenia import dbTypes
from xeniatools.xenia import qaqcTestFlags
from xeniatools.xenia import uomconversionFunctions
from xeniatools.xenia import recursivedefaultdict
from xeniatools.xmlConfigFile import xmlConfigFile
from xeniatools.utils import smtpClass 

from lxml import etree
import logging
import logging.config
#import logging.handlers




"""
Class: rangeLimits
Purpose: Simple structure containing a hi and lo range.
"""
class rangeLimits:
  def __init__(self):
    self.rangeLo = None
    self.rangeHi = None

class obsQAQC:
  def __init__(self,obsName, uom, sOrder):
    self.obsName        = obsName           #Observation these limits are for.
    self.uom            = uom
    self.sOrder         = sOrder
    self.updateInterval = None              #The rate at which the sensor updates.
    self.sensorBad      = False             #Flag that specifies the sensor is bad, so no tests to perform, set data flags as bad.
    self.sensorRangeLimits = rangeLimits()  #The limits for the sensor range.
    self.grossRangeLimits = rangeLimits()   #The limits for the gross range.
    self.climateRangeLimits = {}            #A dictionary keyed from 1-12 representing the climate ranges for the month.
    self.stdDeviation   = None              #Standard deviation used for the time continuity check.
        
  def setSensorRangeLimits(self, rangeLo, rangeHi):    
    self.sensorRangeLimits.rangeLo = rangeLo
    self.sensorRangeLimits.rangeHi = rangeHi
  def setGrossRangeLimits(self, rangeLo, rangeHi):    
    self.grossRangeLimits.rangeLo = rangeLo
    self.grossRangeLimits.rangeHi = rangeHi
  def setClimateRangeLimits(self, rangeLo, rangeHi, month):
    limits = rangeLimits()
    limits.rangeLo = rangeLo
    limits.rangeHi = rangeHi
    self.climateRangeLimits[month] = limits
  def setStandardDeviation(self, stdDev):
    self.stdDeviation = stdDev  
"""
Class: qcTestSuite
Purpose: Implements the range tests and qcFlag determination detailed in the Seacoos netCDF documentation.
"""
class qcTestSuite:
  def __init__(self, logger=None):
    self.logger = logger
    
    
    
  """
  Function: rangeTest
  Purpose: performs the range test. Checks are done to verify limits were provided as well as a valid value. 
  Paramters: 
    value is the data we are range checking.
    limits is a rangeLimits object that contains the hi/lo limits to test against.
    
  Return:
    If the test is sucessful, qaqcTestFlags.TEST_PASSED is returned. 
    if the test fails, qaqcTestFlags.TEST_FAILED is returned.
    if no limits or no value was provided, qaqcTestFlags.NO_TEST is returned.
  """
  def rangeTest(self, value, limits):
    if( limits.rangeLo != None and limits.rangeHi != None ):
      if( value != None ):
        if( value < limits.rangeLo or value > limits.rangeHi ):
          return( qaqcTestFlags.TEST_FAILED )
        return( qaqcTestFlags.TEST_PASSED )      
      else:
        return( qaqcTestFlags.NO_TEST )      
    return( qaqcTestFlags.NO_TEST )

  """
  Function: runRangeTests
  Purpose: Runs each of the limits tests, starting with the sensor range test. Each must pass to be able to move on to the next one.
  As the tests are run, this function is also setting the flags specifing the outcome of each test. These flags are later used in the
  qclevel calculation.
  Parameters:
    obsNfo is the obsInfo object used.
    value is the floating point value we are testing.
    month is the numeric representation of the month to use for the climate range tests.
  Return:
    qaqcTestFlags.TEST_PASSED is the tests were passed, otherwise qaqcTestFlags.TEST_FAILED.
  """
  def runRangeTests(self, obsNfo, rec, month = 0):
    #Do we have a valid value?
    if(rec.m_value != None):     
      rec.dataAvailable = qaqcTestFlags.TEST_PASSED
      if(rec.sensor.active < 3):
        #Did we get a valid obsNfo that we need for the limits?
        if( obsNfo != None ):
          if( obsNfo.sensorRangeLimits.rangeLo != None and obsNfo.sensorRangeLimits.rangeHi != None ):
            rec.sensorRangeCheck = self.rangeTest( rec.m_value, obsNfo.sensorRangeLimits )
            #If we don't pass the sensor range check, do not run any other tests.
            if( rec.sensorRangeCheck == qaqcTestFlags.TEST_PASSED ):    
              #Run the gross range checks if we have limits.    
              if( obsNfo.grossRangeLimits.rangeLo != None and obsNfo.grossRangeLimits.rangeHi != None ):
                rec.grossRangeCheck = self.rangeTest( rec.m_value, obsNfo.grossRangeLimits )
              #Run the climatalogical range checks if we have limits.    
              if( len(obsNfo.climateRangeLimits) and month != 0 ):
                limits = obsNfo.climateRangeLimits[month]
                rec.climateRangeCheck = self.rangeTest(rec.m_value, limits)
      else:
        #The sensor is marked as offline, however we are still getting data. We can't
        #trust the data, so we are going to flag it as bad.
        if(rec.sensor.active == 3):
          rec.dataAvailable      = qaqcTestFlags.TEST_FAILED                    
    else:
      rec.dataAvailable      = qaqcTestFlags.TEST_FAILED
    
    rec.prelimQCFlag = self.calcQCFlags(rec)
    rec.prelimQCLevel = self.calcQCLevel(rec)
    if(rec.prelimQCLevel != qaqcTestFlags.DATA_QUAL_GOOD):
      if(self.logger != None):          
        self.logger.debug( "Range Test Failed: Date %s Platform: %s obsName: %s value: %f(%s) qcFlag: %s qcLevel: %d"\
                     % (rec.m_date.__str__(), rec.platform_handle, obsNfo.obsName, ( rec.m_value != None ) and rec.m_value or -9999.0, ( obsNfo.uom != None ) and obsNfo.uom or '', rec.prelimQCFlag.tostring(), rec.prelimQCLevel) )
      
  """
  Function: timeContinuityCheck
  Purpose: Implements the NDBC time continuity(rate of change) test. 
    The formula is: M = 0.8 * standard deviation of observation * square root(time difference in hours since last good observation)
    Time is never greater than 3 hours.
    The standard deviations used come from a table provided by NDBC.
  Parameters
    recs is the array of observation records to process.
    obsNfo is the QAQC information for the observation.
  """
  def getNextTestedRec(self, curNdx, recs, reverse=False):
    if(reverse == False):
      ndx = curNdx + 1
      if(ndx >= len(recs)):
        return(None)
    else:
      ndx = curNdx - 1
      if(ndx < 0):
        return(None)
    rec = recs[ndx]
    
    #Is the data good? Previously checked.
    if(rec.qc_level != None and rec.qc_level == qaqcTestFlags.DATA_QUAL_GOOD):
      #If the record had the range tests performed, let's get those results.
      if(rec.qc_level != None):
        self.decodeQCFlags(rec, rec.qc_flag) 
        rec.prelimQCLevel= rec.qc_level
      return(rec)
    #Is the data good? Current check.
    elif(rec.prelimQCLevel != None and rec.prelimQCLevel == qaqcTestFlags.DATA_QUAL_GOOD):
        return(rec)
      
    self.getNextTestedRec(ndx, recs, reverse)
      
      
    
  def timeContinuityCheck(self, recs, obsNfo, ignoreQAQCFlags):    
    rowCnt = len(recs) - 1
    while rowCnt > 0:
      curRec = recs[rowCnt]
      #Has the record already been rate of change tested?
      if((curRec.qc_level != None and curRec.qc_flag != None and curRec.qc_level == qaqcTestFlags.DATA_QUAL_GOOD and int(curRec.qc_flag[qaqcTestFlags.TQFLAG_RC]) == qaqcTestFlags.NO_TEST)\
         or (curRec.prelimQCLevel != None and curRec.prelimQCFlag != None and curRec.prelimQCLevel == qaqcTestFlags.DATA_QUAL_GOOD and int(curRec.prelimQCFlag[qaqcTestFlags.TQFLAG_RC]) == qaqcTestFlags.NO_TEST)\
         or ignoreQAQCFlags):
        
        #If the record had the range tests performed, let's get those results.
        if(curRec.qc_level != None):
          self.decodeQCFlags(curRec, curRec.qc_flag) 
          curRec.prelimQCLevel= curRec.qc_level
        nextRec = self.getNextTestedRec(rowCnt, recs, True)
        nextM = None
        prevM = None
        #First let's try and check the next record, if it exists.
        if(nextRec != None):
          timeDelta = nextRec.m_date - curRec.m_date 
          nextHours = timeDelta.seconds / 3600
          if(nextHours > 3):
            nextHours = 3
            if(self.logger != None):
              self.logger.info("Last good measurement more than 3 hours old for Obs: %s Date: %s" %(obsNfo.obsName,curRec.m_date.__str__()))
          elif(nextHours < 1):
            nextHours = 1              

          nextM = 0.8 * obsNfo.stdDeviation * math.sqrt(nextHours)
          
          prevRec = self.getNextTestedRec(rowCnt, recs, False)
          #Get the record prior to the current record.
          if(prevRec != None):
            timeDelta = curRec.m_date - prevRec.m_date  
            prevHours = timeDelta.seconds / 3600
            if(prevHours > 3):
              prevHours = 3
              if(self.logger != None):
                self.logger.info("Last good measurement more than 3 hours old for Obs: %s Date: %s" %(obsNfo.obsName,curRec.m_date.__str__()))
            elif(prevHours < 1):
              prevHours = 1
            prevM = 0.8 * obsNfo.stdDeviation * math.sqrt(prevHours)
            #We are comparing the current record with the next one and then the previous one. If both are
            #within the allowed deviation, the current record is good.   
            if(math.fabs(curRec.m_value - nextRec.m_value) <= nextM and\
               math.fabs(curRec.m_value - prevRec.m_value) <= prevM):
              curRec.rateofchangeCheck = qaqcTestFlags.TEST_PASSED
            else:
              #The current record failed the deviation, check if it failed with the previous record. 
              #This is to ensure when we mark a record is bad, we don't mark the last good record before the
              #spike/dip.
              if(math.fabs(curRec.m_value - prevRec.m_value) > prevM):
                curRec.rateofchangeCheck = qaqcTestFlags.TEST_FAILED
              #The deviation between the current record and last record is ok, so this record is good, this
              #means the next record is the bad one. Next pass through the loop, we will catch and mark it as
              #it will fail the deviation between it and the previous record.            
              else:             
                curRec.rateofchangeCheck = qaqcTestFlags.TEST_PASSED
          #No previous record, this is the first record.
          #We don't have three points to check, so we must assume the current record is the bad one.
          #This might result in flagging one record bad that might be good.
          else:
            if(math.fabs(curRec.m_value - nextRec.m_value) <= nextM):                                             
              curRec.rateofchangeCheck = qaqcTestFlags.TEST_PASSED
            else:
              curRec.rateofchangeCheck = qaqcTestFlags.TEST_FAILED
                
            
          curRec.prelimQCFlag = self.calcQCFlags(curRec)
          curRec.prelimQCLevel = self.calcQCLevel(curRec)
          if(curRec.prelimQCLevel != qaqcTestFlags.DATA_QUAL_GOOD):
            if(self.logger != None):          
              self.logger.debug( "Rate of Change Test Failed: Date %s Platform: %s obsName: %s value: %f(%s) qcFlag: %s qcLevel: %d"\
                           % (curRec.m_date.__str__(), curRec.platform_handle, obsNfo.obsName,\
                              ( curRec.m_value != None ) and curRec.m_value or -9999.0,\
                              ( obsNfo.uom != None ) and obsNfo.uom or '', curRec.prelimQCFlag.tostring(), curRec.prelimQCLevel) )
              
        else:
          if(self.logger != None):
            self.logger.info("No rec found with good QAQC. Obs: %s Rec date: %s" %(obsNfo.obsName,curRec.m_date.__str__()))
      else:
        if(self.logger != None):
          self.logger.error("Record has no valid qc_flag/qc_level or prelimQCFlag/prelimQCLevel. Date: %s" %(curRec.m_date))          
      rowCnt -= 1
  """
  Function: calcQCLevel
  Purpose: Calculates the aggregate data quality flag. This determination depends on the value of each of the limit test flags.
  Parameters:
  Return:
    qaqcTestFlags.DATA_QUAL_GOOD if all the range tests were completed successfully. 
  """
  def calcQCLevel(self, rec):
    qcFlag = qaqcTestFlags.NO_DATA
    if( rec.dataAvailable == qaqcTestFlags.NO_TEST or rec.sensorRangeCheck == qaqcTestFlags.NO_TEST ):
      qcFlag = qaqcTestFlags.DATA_QUAL_NO_EVAL
    #Was there any data available?
    elif( rec.dataAvailable == qaqcTestFlags.TEST_FAILED ):
      qcFlag = qaqcTestFlags.NO_DATA
    else:
      #Did the sensor range test fail?
      if( rec.sensorRangeCheck == qaqcTestFlags.TEST_FAILED ):
        qcFlag = qaqcTestFlags.DATA_QUAL_BAD
      else:
        #Were tests performed for range, climate and rate of change?
        if( (rec.grossRangeCheck == qaqcTestFlags.NO_TEST) and
            (rec.climateRangeCheck == qaqcTestFlags.NO_TEST) and
            (rec.rateofchangeCheck == qaqcTestFlags.NO_TEST) ):
          qcFlag = qaqcTestFlags.DATA_QUAL_NO_EVAL
        #Did the tests performed for range or climate or rate of change fail?
        elif( (rec.grossRangeCheck == qaqcTestFlags.TEST_FAILED) or
               (rec.climateRangeCheck == qaqcTestFlags.TEST_FAILED) or
               (rec.rateofchangeCheck == qaqcTestFlags.TEST_FAILED) ):
          qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
        #
        elif( ( (rec.grossRangeCheck == qaqcTestFlags.NO_TEST) and (rec.climateRangeCheck == qaqcTestFlags.NO_TEST) ) or
              ( (rec.grossRangeCheck == qaqcTestFlags.NO_TEST) and (rec.rateofchangeCheck == qaqcTestFlags.NO_TEST) ) or
              ( (rec.climateRangeCheck == qaqcTestFlags.NO_TEST) and (rec.rateofchangeCheck == qaqcTestFlags.NO_TEST) ) ):  
          qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
        #
        elif( ( (rec.grossRangeCheck == qaqcTestFlags.TEST_PASSED) and (rec.climateRangeCheck == qaqcTestFlags.TEST_PASSED) ) or
              ( (rec.grossRangeCheck == qaqcTestFlags.TEST_PASSED) and (rec.rateofchangeCheck == qaqcTestFlags.TEST_PASSED) ) or
              ( (rec.climateRangeCheck == qaqcTestFlags.TEST_PASSED) and (rec.rateofchangeCheck == qaqcTestFlags.TEST_PASSED) ) ):  
          qcFlag = qaqcTestFlags.DATA_QUAL_GOOD
        else:
          qcFlag = qaqcTestFlags.DATA_QUAL_SUSPECT
            
    return( qcFlag )
  
  """
  Function: calcQCFlag
  Purpose: Sets the results of the individual tests in the appropriate array index.
  Parameters:
  Return:
    The array representing the test results. 
  """
  def calcQCFlags(self, rec):
    #the qc_flag in the database is a string. We've defined a character array to represent each type of test, so
    #here we fill up the array with 0s to begin with, then per array ndx set the test results.
    qcFlag = array.array('c')
    fill = ''       
    fill = fill.zfill(qaqcTestFlags.TQFLAG_NN+1)   
    qcFlag.fromstring(fill)
    
    #The qcFlag string is interpreted as follows. The leftmost byte is the first test, which is the data available test,
    #each preceeding byte is another test of lesser importance. We store the values in a string which is to always contain
    #the same number of bytes for consistency. Some examples:
    #"000000" would represent no tests were done
    #"200000" represents the data available test was done and passed(0 = no test, 1 = failed, 2 = passed)
    #"220000" data available, sensor range tests performed.
    qcFlag[qaqcTestFlags.TQFLAG_DA] = ("%d" % rec.dataAvailable)
    qcFlag[qaqcTestFlags.TQFLAG_SR] = ("%d" % rec.sensorRangeCheck)
    qcFlag[qaqcTestFlags.TQFLAG_GR] = ("%d" % rec.grossRangeCheck)
    qcFlag[qaqcTestFlags.TQFLAG_CR] = ("%d" % rec.climateRangeCheck)
    qcFlag[qaqcTestFlags.TQFLAG_RC] = ("%d" % rec.rateofchangeCheck)
    qcFlag[qaqcTestFlags.TQFLAG_NN] = ("%d" % rec.nearneighborCheck)
    
    return(qcFlag)
    
  """
  Function: decodeQCFlags
  Purpose: Given an array reprenting the QAQC tests, decodes them into the idividual pieces.
  Parameters:
  Return:
    The array representing the test results. 
  """
  def decodeQCFlags(self, rec, qcFlags):
    rec.dataAvailable     = int(qcFlags[qaqcTestFlags.TQFLAG_DA])      
    rec.sensorRangeCheck  = int(qcFlags[qaqcTestFlags.TQFLAG_SR])
    rec.grossRangeCheck   = int(qcFlags[qaqcTestFlags.TQFLAG_GR])
    rec.climateRangeCheck = int(qcFlags[qaqcTestFlags.TQFLAG_CR])
    rec.rateofchangeCheck = int(qcFlags[qaqcTestFlags.TQFLAG_RC])
    rec.nearneighborCheck = int(qcFlags[qaqcTestFlags.TQFLAG_NN])
"""
Class: obsInfo
Purpose: Container for the various limits(sensor,gross,climate) for the given observation type.
Represents a single point observation from the xenia DB.
"""    
class observation(multi_obs):
  dataAvailable      = qaqcTestFlags.NO_TEST   #Flag specifing the validity of whether data is available. 1st test performed
  sensorRangeCheck   = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the sensor range check. 2nd test performed
  grossRangeCheck    = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the gross range check. 3rd test performed
  climateRangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the climate range check. 4th test performed
  rateofchangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the rate of change check.
  nearneighborCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the nearest neighbor check.
  prelimQCFlag       = None
  prelimQCLevel      = None



"""
Class: platformInfo
Purpose: This class encapsulates the limits for each sensor on a platform.     
"""
class platformInfo(qcTestSuite):
  """
  Function: __init__
  Purpose: Initializes the class. 
  Paramters: 
    platform is the platform name this class is used for.
  """
  def __init__(self,platform, logger=None, ignoreQAQCFlags=False):
    qcTestSuite.__init__(self, logger)
    self.platformHandle = platform      #Platform name
    self.obsQAQCList    = {}            #Dictionary of QAQC settings keyed on the observation the QAQC represents.
    self.logger         = logger        #Logger object
    self.rowCount       = 0             #Total number of rows processed
    self.ignoreQAQCFlags = ignoreQAQCFlags  #If true, the testing will ignore any existing QAQC flags and retest.
    self.failList       = []            #List of failed records
    self.testRunFlag    = False         #Flag, if true will not commit records to the database.
  """
  Function: ignoreQAQCFlags
  Purpose: If we set this to true, we will restamp all the records, regardless of their current QAQC status.
  """
  def setIgnoreQAQCFlags(self, ignoreQAQCFlags):
    self.ignoreQAQCFlags = ignoreQAQCFlags
  
  def setTestRun(self, testRunFlag):
    self.testRunFlag = testRunFlag
  """
  Function:addObsInfo
  Purpose: Add a new obsInfo class into this classes obsList dictionary
  Parameters: 
    obsNfo is an obsInfo class to store into the dictionary
  """  
  def addObsQAQCInfo(self, obsNfo):
    self.obsQAQCList[obsNfo.obsName] = obsNfo
    
  """
  Function: getObsInfo
  Purpose: For the given obsName, this routine looks to see if it exists in the dictionary, and if so returns it.
  Parameters: 
    obsName is the observation name we are looking up.
  Return: 
    obsInfo class for the obsName, if none found returns None.
  """  
  def getObsQAQCInfo(self, obsName):
    if( obsName in self.obsQAQCList != False ):
      return( self.obsQAQCList[obsName] )
    return( None )
  
  def testDateRange(self, db, beginDate, endDate):
    for obs in self.obsQAQCList:
      obsNfo = self.obsQAQCList[obs]
      sensorId = db.sensorExists(obs, obsNfo.uom, self.platformHandle, obsNfo.sOrder)
      if(sensorId != None):
        try:
          recs = db.session.query(observation)\
            .join((sensor,sensor.row_id == observation.sensor_id))\
            .join((m_type,m_type.row_id == observation.m_type_id))\
            .join((m_scalar_type,m_scalar_type.row_id == m_type.m_scalar_type_id))\
            .join((obs_type,obs_type.row_id == m_scalar_type.obs_type_id))\
            .join((uom_type,uom_type.row_id == m_scalar_type.uom_type_id))\
            .filter(observation.m_date >= beginDate)\
            .filter(observation.m_date < endDate)\
            .filter(observation.sensor_id == sensorId)\
            .order_by("m_date DESC").all()     
          self.testRecs(obsNfo, db, recs)
          
        except NoResultFound, e:
          if(self.logger != None):
            self.logger.debug(e)
      else:
        if(self.logger != None):
          self.logger.error("No sensor_id was found, cannot perform QAQC on observation.")
          
  def testLastNHours(self, db, dateOffset):
    for obs in self.obsQAQCList:
      obsNfo = self.obsQAQCList[obs]
      if(self.logger != None):
        self.logger.info("Observation: %s(%s) s_order: %d" %(obs,obsNfo.uom,obsNfo.sOrder))
      sensorId = db.sensorExists(obs, obsNfo.uom, self.platformHandle, obsNfo.sOrder)
      if(sensorId != None):
        try:
          recs = db.session.query(observation)\
            .join((sensor,sensor.row_id == observation.sensor_id))\
            .join((m_type,m_type.row_id == observation.m_type_id))\
            .join((m_scalar_type,m_scalar_type.row_id == m_type.m_scalar_type_id))\
            .join((obs_type,obs_type.row_id == m_scalar_type.obs_type_id))\
            .join((uom_type,uom_type.row_id == m_scalar_type.uom_type_id))\
            .filter(observation.m_date >= dateOffset)\
            .filter(observation.sensor_id == sensorId)\
            .order_by("m_date DESC").all()
          
          self.testRecs(obsNfo, db, recs)
        except NoResultFound, e:
          if(self.logger != None):
            self.logger.debug(e)          
      else:
        if(self.logger != None):
          self.logger.error("No sensor_id was found, cannot perform QAQC on observation.")
  """
  Function: testRecs
  Purpose: For the given set of observation records in recs, loop through and perform the various QAQC tests.
  Parameters:
    obsNfo - An obsQAQC that contains the various QAQC settings for the observation.
    db - A xeniaAlchemy object that represents the connected database.
    recs - An array of observation objects for the observations to process.
  """
  def testRecs(self, obsNfo, db, recs):
    obsProcdCnt = 0
    qcFailCount= 0
    if(len(recs)):
      #First pass we do the range checks.  
      recCnt = len(recs)
      cnt = 0
      while(cnt < recCnt):
        rec = recs[cnt]
        #Get the numeric representation of the month(1...12)
        dateformat = "%Y-%m-%dT%H:%M:%S"
        if( rec.m_date.__str__().find("T") == -1 ):
          dateformat = "%Y-%m-%d %H:%M:%S"          
        month = int(time.strftime( "%m", time.strptime(rec.m_date.__str__(), dateformat) ))
        if(rec.qc_level == None or self.ignoreQAQCFlags):
          self.runRangeTests(obsNfo, rec, month)
            
        cnt += 1
        self.rowCount += 1
      #Next we do the time continuity tests. We do them after the range tests since we need to know if the data
      #points are good before we can test.
      if(obsNfo.stdDeviation):
        self.timeContinuityCheck(recs, obsNfo, self.ignoreQAQCFlags)
      
      #Loops through making the changes in the records we want to then update back to the database.     
      for rec in recs:
        if(rec.prelimQCLevel != None and rec.prelimQCFlag != None):        
          rec.qc_level = rec.prelimQCLevel
          rec.qc_flag = rec.prelimQCFlag.tostring()
          if(rec.qc_level != qaqcTestFlags.DATA_QUAL_GOOD):
            qcFailCount += 1
            #IF the sensor is not in one of the automatically set states, let's not save the record to send in an email.
            #The reason for this is we may have a known bad sensor that will continue to fail QAQC, so we want
            #to only send emails on sensors we think should be good.
            if(rec.sensor.active < 3):
              self.failList.append(rec)
          obsProcdCnt += 1
      try:       
        if(self.testRunFlag == False):     
          db.session.commit()
        if(self.logger != None):
          self.logger.info("Observation processing complete. Observation Record Count: %d Processed: %d Record Fail Count: %d" %(len(recs), obsProcdCnt, qcFailCount))
      except exc.InvalidRequestError, e:
        if(self.logger != None):
          self.logger.exception(e)
      except Exception, e:
        if(self.logger != None):
          self.logger.exception(e)
    else:
      if(self.logger != None):
        self.logger.warning("No records available for testing.")
  
 
  
class rangeTests(object):
  def __init__(self, xmlConfigFilename):
    self.cfgFile = xmlConfigFile(xmlConfigFilename)
    #DWR 2/9/2011
    #Finally sussed out the logging config file, so implement it instead of re-inventing the wheel.
    logFile = self.cfgFile.getEntry('//environment/logging/configFile')
    logging.config.fileConfig(logFile)
    self.logger = logging.getLogger("qaqc_logger")
    
    #Get the settings for how the qc Limits are stored so we know how to process them.
    type = self.cfgFile.getEntry('//environment/qcLimits/fileType')
    if(type != None):
      if( type == 'test_profiles' ):
        tag = self.cfgFile.getEntry('//environment/qcLimits/file')
        if(tag != None):
          self.platformInfoDict = self.loadFromTestProfilesXML(tag)
          if(self.logger != None):
            self.logger.info("Limits type file: %s File: %s" % (type,tag) )
          else:
            print("Limits type file: %s File: %s" % (type,tag))
        else:
          if(self.logger != None):
            self.logger.error("No QC Limits provided.")
          else:
            print("No QC Limits provided.")
          sys.exit(-1)
    else:
      if(self.logger != None):
        self.logger.error("No QC Limits type provided.")
      else:
        print("No QC Limits type provided.")      
      sys.exit(-1)
      
    self.db = None
    sqlAlchemyLog = self.cfgFile.getEntry("//environment/database/sqlAlchemyLog")
    if(sqlAlchemyLog != None):
      sqlAlchemyLog = int(sqlAlchemyLog)
    else:
      sqlAlchemyLog = 0
    dbSettings = self.cfgFile.getDatabaseSettings()
    if(dbSettings['type'] != None):
      self.db = xeniaAlchemy(self.logger)      
      #Are we connecting to a SQLite database?
      #if(dbSettings['type'] == 'sqlite'):
        #if(dbSettings['dbName']):
          #if(self.db.connect(dbSettings['dbName']) == False):
          #  if(self.logger != None):
          #    self.logger.error("Unable to connect to SQLite database.")
          #  else:
          #    print("Unable to connect to SQLite database.")              
          # sys.exit(-1)
          #if(self.logger != None):           
          #  self.logger.info("Database type: %s File: %s" % (dbSettings['type'],dbSettings['dbName']) )
          #else:
          #  print("Database type: %s File: %s" % (dbSettings['type'],dbSettings['dbName']) )            
      #PostGres db?
      if(len(dbSettings['dbName']) and len(dbSettings['dbUser']) and len(dbSettings['dbPwd'])):
        if(self.db.connectDB("postgresql+psycopg2", dbSettings['dbUser'], dbSettings['dbPwd'], dbSettings['dbHost'], dbSettings['dbName'], sqlAlchemyLog) == True):
          if(self.logger != None):
            self.logger.info("Succesfully connect to DB: %s at %s" %(dbSettings['dbName'],dbSettings['dbHost']))
        else:
          self.logger.error("Unable to connect to DB: %s at %s. Terminating script." %(dbSettings['dbName'],dbSettings['dbHost']))
          sys.exit(-1)            
      else:
        if(self.logger != None):
          self.logger.error( "Missing configuration info for PostGres setup. Terminating script." )
        sys.exit(-1)        
    else:
      if(self.logger != None):
        self.logger.error( "No database type provided. Terminating script." )
      sys.exit(-1)
    
    self.sqlUpdateFile = self.cfgFile.getEntry( '//environment/database/sqlQCUpdateFile' )
    if(tag != None):
      if(self.logger != None):
        self.logger.info( "SQL QC Update file: %s" % (self.sqlUpdateFile))
    else:
      if(self.logger != None):
        self.logger.error("No SQL update filename.")
      
    #Get conversion xml file
    self.uomConvertFile = self.cfgFile.getEntry('//environment/unitsCoversion/file')
    if(self.uomConvertFile != None):
      if(self.logger != None):
        self.logger.info("Units conversion file: %s" % (self.uomConvertFile) )
    else:
      if(self.logger != None):
        self.logger.error("No units conversion file specified in config file." % (self.uomConvertFile) )
  
    self.lastNHours = None
    self.startDate  = None
    self.endDate    = None
    self.ignoreQAQCFlags = False
    self.totalRows  = 0
    self.qcTotalFailCnt = 0
    self.qcTotalMissingLimitsCnt = 0
    self.testRunFlag = False
    
  def testRun(self, testRunFlag):
    self.testRunFlag = testRunFlag
  """
  Function: loadFromTestProfilesXML
  Purpose: Loads the limits from the test_profiles.xml file passed in with xmlConfigFile
  Parameters: 
    xmlConfigFile is the full path to the test_profiles file to use.
  """  
  def loadFromTestProfilesXML(self, xmlConfigFile):  
    platformInfoDict = {}
    try:
      monthList = {'Jan': 1, 'Feb': 2, 'Mar': 3, "Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12 }
      xmlTree = etree.parse(xmlConfigFile)
      #Get the default standard deviations for the observations.
      stdDevList = xmlTree.xpath('//standardDeviations')
      stdDeviations = recursivedefaultdict()
      for stdDev in stdDevList[0].getchildren():
        
        val = stdDev.xpath("stdDev")
        if(val != None):
          val = float(val[0].text)
          stdDeviations[stdDev.tag]['stdDev'] = val
        units = stdDev.xpath("units")
        if(units != None):
          units = units[0].text
          stdDeviations[stdDev.tag]['units'] = units
      
      testProfileList = xmlTree.xpath( '//testProfileList')
      for testProfile in testProfileList[0].getchildren():
        #See if the test profile has an ID.
        id = testProfile.xpath( 'id' )
        if( len(id) ):
          id = id[0].text
        #Determine which platforms are in this testProfile
        platformList = testProfile.xpath('platformList')
        for platform in platformList[0].getchildren():          
          platformHandle = platform.text
          platformInfoDict[platformHandle] = platformInfo(platformHandle, self.logger)
          
          #Now loop through and get all the observations.
          obsList = testProfile.xpath('obsList')
          for obs in obsList[0].getchildren():             
            obsHandle  = obs.xpath('obsHandle' )
            if( len(obsHandle) ):             
              obsHandle = obsHandle[0].text
                            
              #The handle is in the form of observationname.units of measure: "wind_speed.m_s-1" for example               
              parts = obsHandle.split('.')
              #Added sorder since if we do have multiples of the same obs on a platform, we need to distinguish them.
              sOrder = obs.xpath('sOrder')
              #Set the sOrder if we have one.
              if(len(sOrder)):
                sOrder = int(sOrder[0].text)
              else:
                sOrder = 1
              obsSettings = obsQAQC(parts[0], parts[1], sOrder)
              
              #DWR 02/28/2011
              #Get the standard dev value for the obs.
              if(obsSettings.obsName in stdDeviations):
                obsSettings.stdDeviation = stdDeviations[obsSettings.obsName]['stdDev']

                          
              #Rate at which the sensor updates.              
              interval  = obs.xpath('UpdateInterval' )
              if( len(interval) ):
                obsSettings.updateInterval = int(interval[0].text)            
              #Ranges
              hi  = obs.xpath('rangeHigh' )
              lo  = obs.xpath('rangeLow' )
              if(len(hi) and len(lo)):
                obsSettings.setSensorRangeLimits(float(lo[0].text), float(hi[0].text))
                        
              hi  = obs.xpath('grossRangeHigh' )
              lo  = obs.xpath('grossRangeLow' )
              if(len(hi) and len(lo)):
                obsSettings.setGrossRangeLimits(float(lo[0].text), float(hi[0].text))
             
              
              #Check to see if we have a climate range, if not, we just use the grossRange.
              climateList = obs.xpath('climatologicalRangeList')
              if( len(climateList ) ):
                for climateRange in climateList[0].getchildren():             
                  #limits = rangeLimits()
                  startMonth  = climateRange.xpath('startMonth' )
                  rangeHi  = climateRange.xpath('rangeHigh' )
                  rangeLo  = climateRange.xpath('rangeLow' )
                  if( len(startMonth) ):
                    startMonth = startMonth[0].text
                  endMonth  = climateRange.xpath('endMonth' )
                  if( len(endMonth) ):
                    endMonth = endMonth[0].text
                  rangeHi  = climateRange.xpath('rangeHigh' )
                  if( len(rangeHi) ):
                    rangeHi = float(rangeHi[0].text)
                  rangeLo  = climateRange.xpath('rangeLow' )
                  if( len(rangeLo) ):
                    rangeLo = float(rangeLo[0].text)
                  #Since the climate range entries can span multiple months, for ease of use we want to have a 
                  #bucket per month so we need to check the start and end dates to see if we need to break them up.
                  #Also to take note, the limits are stored in a dictionary keyed by the month number, so we normally 
                  #start at 1 and not 0. 
                  strtNum = monthList[startMonth]
                  endNum = monthList[endMonth]
                  #If we have an interval between the start and end greater than one, we've got a range of months covered.
                  if( (endNum - strtNum) > 1 ):
                    i = strtNum
                    #Loop adding limits for each month in the range.
                    while( i < endNum ):
                      obsSettings.setClimateRangeLimits(rangeLo, rangeHi, i)
                      #obsSettings.climateRangeLimits[i] = limits
                      i += 1
                  else:
                    obsSettings.setClimateRangeLimits(rangeLo, rangeHi, strtNum)
                    #obsSettings.climateRangeLimits[strtNum] = limits
              #No climate range given, so we default to the grossRange.
              else:
                #limits = rangeLimits()
                rangeHi = obsSettings.grossRangeLimits.rangeHi
                rangeLo = obsSettings.grossRangeLimits.rangeLo
                for i in range( 1,13 ):
                  obsSettings.setClimateRangeLimits(rangeLo, rangeHi, i)                  
                  #obsSettings.climateRangeLimits[i] = limits
                  
              #Now add the observation to our platform info dictionary.
              platformNfo = platformInfoDict[platformHandle]
              
              platformNfo.addObsQAQCInfo(obsSettings)
              
        
      return( platformInfoDict )
    except Exception, e:
      if(self.logger != None):
        self.logger.exception(e)
        sys.exit(-1)
  
  def setLastNHours(self, lastNHours):
    self.lastNHours = lastNHours
    self.queryRecords(lastNHours, None, None, self.ignoreQAQCFlags)
  
  def setDateRange(self, startDate, endDate):
    self.startDate = startDate
    self.endDate = endDate
    self.queryRecords(None, self.startDate, self.endDate, self.ignoreQAQCFlags)
    
  def setQCSQLFile(self, sqlFileName):
    self.sqlUpdateFile = sqlFileName
  
  def restampQAQCRecords(self, restampQAQC):
    self.ignoreQAQCFlags = restampQAQC
    for platformHandle in self.platformInfoDict:
      platObj = self.platformInfoDict[platformHandle]
      platObj.setIgnoreQAQCFlags(self.ignoreQAQCFlags)
    if(self.logger != None and restampQAQC):
      self.logger.debug("Restamping QAQC Flags.")
         

  def queryRecords(self, lastNHours=None, beginDate=None, endDate=None, ignoreQCedRecords=False):
    try:
      sqlUpdateFile = open(self.sqlUpdateFile, "w")
      totalprocTime = processingEnd = processingStart = 0
      if( lastNHours != None ):
        #Get calc the dateOffset from current time - lastNHours we want to query for.
        dateOffset = time.time() - (lastNHours * 3600)
        dateOffset = "%s" % (time.strftime('%Y-%m-%dT%H:00:00', time.gmtime(dateOffset)))
        if(self.logger != None):
          self.logger.debug( "Processing Last: %d hours." % (lastNHours) )
      else:
        if(self.logger != None):
          self.logger.error("No time period specified for database query. Cannot continue.")
        else:
          print("No time period specified for database query. Cannot continue.")
        sys.exit(-1)

      for platformKey in self.platformInfoDict.keys():
        
        if( sys.platform == 'win32'):
          processingStart = time.clock()
        else:
          processingStart = time.time()
           
        if(self.logger != None):
          self.logger.debug( "Start processing platform: %s" % (platformKey) )
        
        platformObj = self.platformInfoDict[platformKey]
        platformObj.setTestRun(self.testRunFlag)
            
        if(lastNHours != None):                                   
          platformObj.testLastNHours(self.db, dateOffset)
        else:   
          platformObj.testDateRange(self.db, beginDate, endDate)
        
        if( sys.platform == 'win32'):
          processingEnd = time.clock()
        else:
          processingEnd = time.time()
        totalprocTime += (processingEnd-processingStart)
        
        if(self.logger != None):
          self.logger.debug( "Rows processed: %d Time: %f(ms)" %(platformObj.rowCount, ((processingEnd-processingStart)*1000.0 )) )
          self.logger.debug( "End processing platform: %s" % (platformKey) )
        self.totalRows += platformObj.rowCount
          
      if(self.logger != None):
        self.logger.debug("QAQC Proc'd: %d rows in time: %f(ms)" %(self.totalRows, totalprocTime * 1000.0 ))
        self.logger.debug("End QAQC processing")
        
      self.sendAlertEmail()
       
    except Exception, e:
      import traceback     
      errMsg = "ERROR Terminating script." 
      if( self.logger != None ):
        self.logger.error(errMsg, exc_info=1)
      else:
        print( traceback.print_exc() )
    except IOError, e:
      import traceback      
      errMsg = "ERROR Terminating script." 
      if( self.logger != None ):
        self.logger.error(errMsg, exc_info=1)
      else:
        print( traceback.print_exc() )
  """
  Function: sendAlertEmail
  Purpose: Loop through the platforms and check if we have any records that failed the QAQC.
  If so, we send out an email alert.  
  """        
  def sendAlertEmail(self):
    emailSettings = self.cfgFile.getEmailSettings()
    
    emailMsg = ''
    for platformKey in self.platformInfoDict.keys():
      platformObj = self.platformInfoDict[platformKey]
      #Do we have any failed records?
      msg = ''
      if(len(platformObj.failList)):
        if(len(msg)):
          msg += "\n"
        msg = "Platform: %s\n" %(platformKey)
        for rec in platformObj.failList:
          msg += "Observation: %s Date: %s Value: %4.2f qc_flag: %s qc_level: %d\n"\
            %(rec.sensor.m_type.scalar_type.obs_type.standard_name, rec.m_date, rec.m_value, rec.qc_flag, rec.qc_level)
            
        if(len(msg)):
          emailMsg += msg
    if(len(emailMsg)):
      try:
        subject = "[secoora_auto_alert]QAQC Failure"
        msg = "This is an automated email to inform you of one or more data points that have not passed QAQC.\n\n"
        if(self.testRunFlag):
          subject += " This is a test run, ignore"
          msg += "This is a test run, ignore the results.\n"
        msg += emailMsg
        smtp = smtpClass(emailSettings['server'], emailSettings['from'], emailSettings['pwd'])
        smtp.from_addr("%s@%s" % (emailSettings['from'],emailSettings['server']))
        smtp.rcpt_to(emailSettings['toList'])
        smtp.subject(subject)
        smtp.message(msg)
        smtp.send()      
        if(self.logger != None):
          self.logger.info("Sending email alerts.")
      except Exception,e:
        if(self.logger != None):
          self.logger.exception(e)
    return     
    
if __name__ == '__main__':
  if( len(sys.argv) < 2 ):
    print( "Usage: rangeCheck.py xmlconfigfile")
    sys.exit(-1)    
    



