import sys
import optparse
import math
import time
import datetime
from datetime import timedelta
import logging
import logging.config

from sqlalchemy import exc
from sqlalchemy.orm.exc import *
from sqlalchemy.orm import joinedload_all,subqueryload,aliased
from sqlalchemy.sql import *
from xeniatools.xeniaSQLAlchemy import xeniaAlchemy, multi_obs, organization, platform, uom_type, obs_type, m_scalar_type, m_type, sensor 
from xeniatools.rangeCheck import rangeTests
from xeniatools.stats import *
#from scipy import fft



if __name__ == '__main__':
  try:
    import psyco
    psyco.full()
  except Exception, E:
    import traceback
    print( traceback.print_exc() )
  
  parser = optparse.OptionParser()
  
  parser.add_option("-c", "--XMLConfigFile", dest="xmlConfigFile",
                  help="The xml file containing the configuration information." )  
  parser.add_option("-f", "--OutputDirectory", dest="outputDirectory",
                  help="Output directory to write the results per platform." )  
  parser.add_option("-b", "--BeginDate", dest="beginDate",
                    help="The date/time that starts our query")
  parser.add_option("-e", "--EndDate", dest="endDate",
                    help="The end date/time to use for the query.")
  parser.add_option("-d", "--LastNDays", dest="lastNDays",
                    help="Query the last N days for the correlation.")
  parser.add_option("-a", "--AppendFile", dest="appendFile", action="store_true",
                    help="If set, will append to the files instead of creating new ones.")
  parser.add_option("-l", "--LogConfigFile", dest="logConfigFile",
                    help="Logging configuration file to use.")
  

  (options, args) = parser.parse_args()

  qaqc = rangeTests(options.xmlConfigFile)
  if(options.logConfigFile != None):
    logging.config.fileConfig(options.logConfigFile)
    logger= logging.getLogger('root')
  else:
    logging = None
    
  
  beginDate = None
  endDate = None
  lastNDays = None
  dateOffset = None
  today = time.time()
  if(options.appendFile == None):
    options.appendFile = False
    
  if( options.lastNDays != None ):
    #Get calc the dateOffset from current time - lastNDays we want to query for.
    beginDate = time.time() - (int(options.lastNDays) * 24 * 3600)
    beginDate = "%s" % (time.strftime('%Y-%m-%dT00:00:00', time.gmtime(beginDate)))
    #We don't want to include the current day as it is not going to be complete.
    endDate = "%s" % (time.strftime('%Y-%m-%dT00:00:00', time.gmtime()))
  elif(options.beginDate != None and options.endDate != None):
    beginDate = options.beginDate
    endDate = options.endDate
  else:
    if(logging != None):
      logging.info("Must use options LastNDays or BeginDate/EndDate.")    
    sys.exit(-1)
    
  for platformKey in qaqc.platformInfoDict:
    if(logging != None):
      logging.info( "Processing: %s" % (platformKey) )    
    filename = "%s/%s.csv" %(options.outputDirectory,platformKey)
    if(options.appendFile == False):
      outFile = open(filename, "w")
      outFile.write("BeginDate,EndDate,Platform,NearestNeighbor,Observation,Correlation,PlatformRecCount,NNRecCount\n")
      if(logging != None):
        logging.info("Opening file: %s" % (filename))          
    else:
      outFile = open(filename, "a")
      if(logging != None):
        logging.info("Opening file for appending: %s" % (filename))          

    filename = "%s/%s-raw_data.csv" %(options.outputDirectory,platformKey)
    rawOutFile = open(filename, "w")    
    #for year in yearList:
    for obsKey in qaqc.platformInfoDict[platformKey].obsQAQCList:
      obsQAQC = qaqc.platformInfoDict[platformKey].obsQAQCList[obsKey]
      if(len(obsQAQC.nearestNeighbor)):
        sensorId = qaqc.db.sensorExists(obsKey, obsQAQC.uom, platformKey, obsQAQC.sOrder)
        #Get the days that are in the database for the observation between the start/end dates.
        days = qaqc.db.session.query(func.date(multi_obs.m_date)).distinct().\
          filter(multi_obs.m_date >= beginDate).\
          filter(multi_obs.m_date < endDate).\
          filter(multi_obs.sensor_id == sensorId).all()
        for nnKey in obsQAQC.nearestNeighbor:
          nnSensorId = qaqc.db.sensorExists(obsKey, obsQAQC.uom, nnKey, obsQAQC.sOrder)
          if(sensorId != None and nnSensorId != None):
            for day in days:
              beginDate = "%sT00:00:00" %(day)
              endDate = "%sT24:00:00" %(day)
            
              if(logging != None):
                logging.info("Query records for: %s BeginDate: %s EndDate: %s" % (obsKey,beginDate,endDate))          

              multi_obs2 = aliased(multi_obs)
              subQ = qaqc.db.session.query(multi_obs2).\
                        filter(multi_obs2.m_date >= beginDate).\
                        filter(multi_obs2.m_date < endDate).\
                        filter(multi_obs2.sensor_id == nnSensorId).\
                        filter(multi_obs2.d_top_of_hour == 1).\
                        filter(multi_obs2.d_report_hour == multi_obs.d_report_hour).\
                        correlate(multi_obs.__table__).\
                        statement
              if( sys.platform == 'win32'):
                processingStart = time.clock()
              else:
                processingStart = time.time()                 
              
              recs = qaqc.db.session.query(multi_obs).\
                  filter(multi_obs.m_date >= beginDate).\
                  filter(multi_obs.m_date < endDate).\
                  filter(multi_obs.sensor_id == sensorId).\
                  filter(multi_obs.d_top_of_hour == 1).\
                  filter(exists(subQ)).\
                  order_by(multi_obs.m_date.asc()).all()
              if( sys.platform == 'win32'):
                processingEnd = time.clock()
              else:
                processingEnd = time.time()
              if(logging != None):
                logging.info("Query time: %f" % (processingEnd-processingStart) )          
              
              subQ = qaqc.db.session.query(multi_obs2).\
                        filter(multi_obs2.m_date >= beginDate).\
                        filter(multi_obs2.m_date < endDate).\
                        filter(multi_obs2.sensor_id == sensorId).\
                        filter(multi_obs2.d_top_of_hour == 1).\
                        filter(multi_obs2.d_report_hour == multi_obs.d_report_hour).\
                        correlate(multi_obs.__table__).\
                        statement
              if( sys.platform == 'win32'):
                processingStart = time.clock()
              else:
                processingStart = time.time()                 
              if(logging != None):
                logging.info("Query NN records." )          
              nnRecs = qaqc.db.session.query(multi_obs).\
                  filter(multi_obs.m_date >= beginDate).\
                  filter(multi_obs.m_date < endDate).\
                  filter(multi_obs.sensor_id == nnSensorId).\
                  filter(multi_obs.d_top_of_hour == 1).\
                  filter(exists(subQ)).\
                  order_by(multi_obs.m_date.asc()).all()
              if( sys.platform == 'win32'):
                processingEnd = time.clock()
              else:
                processingEnd = time.time()
              if(logging != None):
                logging.info("NN query time: %f" % (processingEnd-processingStart) )          

              xList= []
              yList = []
              rawOutFile.write("%s,%s,date,value\n" %(platformKey,obsKey))
              for rec in recs:
                xList.append(rec.m_value)  
                rawOutFile.write("%s,%f\n" %(rec.m_date,rec.m_value))            
              rawOutFile.write("\n")            
              rawOutFile.write("%s,%s,date,value\n" %(nnKey,obsKey))
              for rec in nnRecs:
                yList.append(rec.m_value)
                rawOutFile.write("%s,%f\n" %(rec.m_date,rec.m_value))            
              rawOutFile.write("\n")            
              
              xCnt = len(xList)
              yCnt = len(yList)
              corr = correlation()
              if(len(xList) > len(yList)):
                xList = xList[0:len(yList)]
              elif(len(xList) < len(yList)):
                yList = yList[0:len(xList)]
              try:
                cor = corr.doCalculations(xList, yList)
                outFile.write("%s,%s,%s,%s,%s,%f,%d,%d\n" %(beginDate,endDate,platformKey,nnKey,obsKey,cor,xCnt,yCnt))                              
              except statsException, e:
                if(logging != None):
                  logging.exception(e)                        
              except Exception, e:
                if(logging != None):
                  logging.exception(e)                        

          else:
            if(sensorId == None):
              if(logging != None):
                logging.debug("Missing sensor id for: %s %s(%s).\n" %(platformKey,obsKey, obsQAQC.uom))                        
            elif(nnSensorId == None):
              if(logging != None):
                logging.debug("Missing sensor id for: %s %s(%s).\n" %(obsQAQC.nearestNeighbor,obsKey, obsQAQC.uom))                        
    outFile.close()
    rawOutFile.close()
    
            #for rec in fftRecs.real:
            #  outFile.write("%f," %(rec))
            #outFile.write("\n")


          #Now search for any observations within our radius.
          #sensorList = qaqc.db.session.query(platform).\
          #  join(platform.sensors).\
          #  filter(platform.active == 1).\
          #  filter(sensor.row_id != sensorId).\
          # filter(sensor.active == 1).\
          # filter(sensor.m_type_id == mTypeId).\
          #  filter(platform.the_geom.within_distance(geom, searchRadius))
          #sensorList = qaqc.db.session.query(sensor).\
          # join(platform).\
          # filter(platform.active == 1).\
          #filter(sensor.row_id != sensorId).\
          # filter(sensor.active == 1).\
          # filter(sensor.m_type_id == mTypeId).\
          # filter(platform.the_geom.within_distance(geom, searchRadius)).all()
          #Let's get the data for the sensor we are interested in to start the stats.
          
          #for rec in parentRec.all():
          #  coVar.addVar1Record(rec.m_value)
          #for rec in sensorList:
            #Run the query to get the data for each sensor.    