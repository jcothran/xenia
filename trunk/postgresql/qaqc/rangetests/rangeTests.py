import sys

"""
Class: qaqcTestFlags
Purpose: This is more of an enumeration class that details out the various quality flags.
"""    
class qaqcTestFlags:

  TQFLAG_DA = 0   #Data Availability               
  TQFLAG_SR = 1   #Sensor Range
  TQFLAG_GR = 2   #Gross Range
  TQFLAG_CR = 3   #Climatological Range
  TQFLAG_RC = 4  #Rate of Change
  TQFLAG_NN = 5  #Nearest Neighbor

  NO_TEST      = 0 # -1 in writeup Unable to perform the test  
  TEST_FAILED  = 1 # 0 in writeup The test failed.
  TEST_PASSED  = 2 #1 in writeup The test passed.
  
  
  NO_DATA           = -9 #the data field is missing a value
  DATA_QUAL_NO_EVAL = 0  #the data quality is not evaluated
  DATA_QUAL_BAD     = 1  #the data quality is bad
  DATA_QUAL_SUSPECT = 2  #the data quality is questionable or suspect
  DATA_QUAL_GOOD    = 3  #the data quality is good
  

"""
Class: rangeLimits
Purpose: Simple structure containing a hi and lo range.
"""
class rangeLimits:
  def __init__(self):
    self.rangeLo = None
    self.rangeHi = None

"""
Class: rangeLimits
Purpose: Container for the various limits(sensor,gross,climate) for the given observation type.
"""    
class rangeLimitTests:
  def __init__(self,obsName):
    #Values for each of these flags can be: Values can be qaqcTestFlags.NO_TEST, qaqcTestFlags.TEST_FAILED, qaqcTestFlags.TEST_PASSED
    self.dataAvailable      = qaqcTestFlags.NO_TEST   #Flag specifing the validity of whether data is available. 1st test performed
    self.sensorRangeCheck   = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the sensor range check. 2nd test performed
    self.grossRangeCheck    = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the gross range check. 3rd test performed
    self.climateRangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the climate range check. 4th test performed
    self.rateofchangeCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the rate of change check.
    self.nearneighborCheck  = qaqcTestFlags.NO_TEST   #Flag specifing the validity of the nearest neighbor check.
    
    self.obsName            = obsName
    self.sensorRangeLimits  = rangeLimits()  #The limits for the sensor range.
    self.grossRangeLimits   = rangeLimits()  #The limits for the gross range.
    self.climateRangeLimits = {}             #A dictionary keyed from 1-12 representing the climate ranges for the month.
  
  def resetFlags(self):
    self.dataAvailable      = qaqcTestFlags.NO_TEST   
    self.sensorRangeCheck   = qaqcTestFlags.NO_TEST   
    self.grossRangeCheck    = qaqcTestFlags.NO_TEST   
    self.climateRangeCheck  = qaqcTestFlags.NO_TEST   
    self.rateofchangeCheck  = qaqcTestFlags.NO_TEST   
    self.nearneighborCheck  = qaqcTestFlags.NO_TEST   
    
  def setSensorRangeLimits(self, limits):    
    self.sensorRangeLimits.rangeLo = limits.rangeLo
    self.sensorRangeLimits.rangeHi = limits.rangeHi
  def setGrossRangeLimits(self, limits):    
    self.grossRangeLimits.rangeLo = limits.rangeLo
    self.grossRangeLimits.rangeHi = limits.rangeHi
  def setClimateRangeLimits(self, limits, month):
    self.climateRangeLimits[month] = limits
  
  def testFlagToString(self, flag):
    if(flag == qaqcTestFlags.NO_TEST):
      return("No Test")
    elif(flag == qaqcTestFlags.TEST_FAILED):
      return("Failed")
    elif(flag == qaqcTestFlags.TEST_PASSED):
      return("Passed")
    else:
      return("Invalid Flag")
  """
  Function: rangeTest
  Purpose: performs the range test. Checks are done to verify limits were provided as well as a valid value. 
  Paramters: 
    value is the data we are range checking.
    limits is a rangeLimits object that has valid hi and low ranges to test against.
  Return:
    If the test is sucessful, qaqcTestFlags.TEST_PASSED is returned. 
    if the test fails, qaqcTestFlags.TEST_FAILED is returned.
    if no limits or no value was provided, qaqcTestFlags.NO_TEST is returned.
  """
  def rangeTest(self, value, limits):
    if( value != None ):
      if( value < limits.rangeLo or value > limits.rangeHi ):
        return( qaqcTestFlags.TEST_FAILED )
      return( qaqcTestFlags.TEST_PASSED )      
    return( qaqcTestFlags.NO_TEST )      

  """
  Function: runRangeTests
  Purpose: Runs each of the limits tests, starting with the sensor range test. Each must pass to be able to move on to the next one.
  As the tests are run, this function is also setting the flags specifing the outcome of each test. These flags are later used in the
  qclevel calculation.
  Parameters:
    value is the floating point value we are testing.
    month is the numeric representation of the month to use for the climate range tests.
  Return:
    qaqcTestFlags.TEST_PASSED is the tests were passed, otherwise qaqcTestFlags.TEST_FAILED.
  """
  def runRangeTests(self, value, month = 0):
    #Do we have a valid value?
    if(value != None):     
      self.dataAvailable = qaqcTestFlags.TEST_PASSED
      #Did we get a valid obsNfo that we need for the limits?
      if( self.sensorRangeLimits.rangeLo != None and self.sensorRangeLimits.rangeHi != None ):
        self.sensorRangeCheck = self.rangeTest( value, self.sensorRangeLimits )
        #If we don't pass the sensor range check, do not run any other tests.
        if( self.sensorRangeCheck == qaqcTestFlags.TEST_PASSED ):    
          #Run the gross range checks if we have limits.    
          if( self.grossRangeLimits.rangeLo != None and self.grossRangeLimits.rangeHi != None ):
            self.grossRangeCheck = self.rangeTest( value, self.grossRangeLimits )
          #Run the climatalogical range checks if we have limits.    
          if( len(self.climateRangeLimits) and month != 0 ):
            limits = self.climateRangeLimits[month]
            self.climateRangeCheck = self.rangeTest( value, limits )
    #No value, so we can't perform any other tests.
    else:
      self.dataAvailable      = qaqcTestFlags.TEST_FAILED  
    
##################################################################################################################################
#To run this test script, at the command line type:
# python rangeTests inputfile outputfile
# where inputfile is one of the files available in the ./datafiles directory, or any csv file whose structure is date,value
# outputfile is the file where the test results are to be stored.
##################################################################################################################################
    
if __name__ == '__main__':
  dataFilename = sys.argv[1]
  resultsFilename = sys.argv[2]

  #Let's create a range test object for salinity.  
  rangeTests = rangeLimitTests('salinity')
  
  #Here we create a rangeLimits object to use to set the limits for the various tests.
  obsLimits = rangeLimits()
  
  #First set of limits is for the sensor range. I just pick 0-65536 as an example, I am not sure what 
  #the true range is for the sensor in the datafile we are going to use.
  obsLimits.rangeLo = 0
  obsLimits.rangeHi = 65536
  rangeTests.setSensorRangeLimits(obsLimits)

  #Now we set the gross range limits with real values. These are set for the OCP1 platform as its low range is fairly low.
  #For the CAP2 and Apache Pier salinity files, more appropriate values would be: Hi: 37 Lo: 33
  obsLimits.rangeLo = 33 #25
  obsLimits.rangeHi = 37
  rangeTests.setGrossRangeLimits(obsLimits)
  
  for i in range(12):
    #Set the climate range. For example simplicity, I am just using the same limits I used in the gross range
    #test. I create an entry for each month using a 1's based index, hence the i+1.
    rangeTests.setClimateRangeLimits(obsLimits, i+1)
  
  #Now let's open the source file passed in on the command line. The format the data files are "date,value".
  #There could be holes in the data, I did no continuity checks, just a raw dump of the last 3 months of data.
  #We open the file for reading.
  inputFile = open(dataFilename, "r")
  
  #Let's create our results file.
  outputFile = open(resultsFilename, "w")
  outputFile.write("Date,Value,Data Available Test,Sensor Range Test(Hi: %4.2f Low: %4.2f),Gross Range Test(Hi: %4.2f Low: %4.2f),Climatalogical Range Test(Hi: %4.2f Low: %4.2f)\n" %\
                   (rangeTests.sensorRangeLimits.rangeHi,rangeTests.sensorRangeLimits.rangeLo,
                    rangeTests.grossRangeLimits.rangeHi,rangeTests.grossRangeLimits.rangeLo,
                    rangeTests.climateRangeLimits[1].rangeHi, rangeTests.climateRangeLimits[1].rangeLo) )
  
  #Now let's loop through all the rows.
  line = inputFile.readline()
  #Keep looping until we get an empty string, this means we have hit the end of file.
  while(len(line)):
    #Split the input line into the date and value.
    parseData = line.split(",")
    #convert the value to a float, it is a string when we read it out of the file.
    value = float(parseData[1])
    #Run the tests, for simplicity I use the month as 1(January).
    rangeTests.runRangeTests(value, 1)
    #Build our output string which will consist of: Date(value we got from the input data file), value(from input data), Data available,
    #Sensor Range Test Result(Passed/Failed), Gross Range Test, Climatological range test
    outputString = ("%s,%f,%s,%s,%s,%s\n"\
                    %(parseData[0],                                            #Date
                      value,                                                   #value tested
                      rangeTests.testFlagToString(rangeTests.dataAvailable),   #data available test result
                      rangeTests.testFlagToString(rangeTests.sensorRangeCheck),#sensor range test result
                      rangeTests.testFlagToString(rangeTests.grossRangeCheck), #gross range check result
                      rangeTests.testFlagToString(rangeTests.climateRangeCheck),#Climatalogical test result
                       ) )
    outputFile.write(outputString)
    
    #Reset the test flags for the next pass.
    rangeTests.resetFlags()
    
    #Read the next line, if there is one.    
    line = inputFile.readline()
    