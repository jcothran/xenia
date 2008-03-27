###################################################################################################################
# This script takes the data from the PlatformUptimePercentages.csv file and creates an HTML page with 
# the data presented in a table format.
##################################################################################################################
use strict;

use Getopt::Long;


#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.
use constant MICROSOFT_PLATFORM => 0;

use constant
{
  RGB_DEFAULT           => 'FFFFFF',
  RGB_90THPERCENTILE    => '00FF00',
  RGB_70THPERCENTILE    => 'FFFF00',
  RGB_UNDER70TH         => 'FF0000',
  RGB_MISSING           => '4169e1',
};

my $PLATFORMCSVFILE  = "PlatformUptimePercentages.csv";
my $PLATFORMHTMLFILE = "PlatformUptimePercentages.html";

my %CommandLineOptions;
GetOptions( \%CommandLineOptions,
            "WorkingDir=s" );

my $strWorkingDir   = $CommandLineOptions{"WorkingDir"};   
if( length( $strWorkingDir ) == 0 )
{

  die print( "Missing required field(s).\n".
              "Command Line format: -WorkingDir\n". 
              "-WorkingDir provides the path to the directory where the $PLATFORMCSVFILE resides for a given provider. HTML file created will be created here as well.\n" );  
}

my $PlatformPercentCSVFile;
my $PlatformPercentHTMLFile;

if( !MICROSOFT_PLATFORM ) 
{
  open($PlatformPercentCSVFile,"$strWorkingDir/$PLATFORMCSVFILE") || die "ERROR: Unable to open file: $strWorkingDir/$PLATFORMCSVFILE";
  open($PlatformPercentHTMLFile,">$strWorkingDir/$PLATFORMHTMLFILE")|| die "ERROR: Unable to open file: $strWorkingDir/$PLATFORMHTMLFILE";
}
else
{
  open($PlatformPercentCSVFile,"$strWorkingDir\\$PLATFORMCSVFILE") || die "ERROR: Unable to open file: $strWorkingDir\\$PLATFORMCSVFILE";
  open($PlatformPercentHTMLFile,">$strWorkingDir\\$PLATFORMHTMLFILE") || die "ERROR: Unable to open file: $strWorkingDir\\$PLATFORMHTMLFILE"; 
}
            
print( $PlatformPercentHTMLFile "<html>\n" );
print( $PlatformPercentHTMLFile  "<BODY>\n" );

print( $PlatformPercentHTMLFile "<link href=\"http://carocoops.org/~dramage_prod/styles/main.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n" );
my $iTestProfileNdx = 0;
#my @ReportIntervals;

print( $PlatformPercentHTMLFile "<table border=\"1\">\n" );
print( $PlatformPercentHTMLFile "<CAPTION><H2>Sensor Reporting Percentage</H2></CAPTION>\n" );
foreach my $strLine (<$PlatformPercentCSVFile>) 
{
	my @Columns = split(/,/,$strLine);
	my $iWriteTableHeader = 0;
	# Are we on a header line?
	if (@Columns[0] eq 'PlatformID' ) 
	{ 
	  #End last table, add some newlines for seperation.
	  if( $iTestProfileNdx ne 0 )
	  {
    	print( $PlatformPercentHTMLFile "<tr><td><BR></td></tr>" );
	    
	  #  print( $PlatformPercentHTMLFile "</table><BR><BR>" );
	  }
	  #Start a new table per new header.
	  #print( $PlatformPercentHTMLFile "<table border=\"1\">" );

	  #For each new haeder, let's add a row to help show this.
    #my $strBuf = "<CAPTION><H2>Sensor Reporting Percentage</H2></CAPTION>";
	  #print( $PlatformPercentHTMLFile $strBuf );
	  
	  $iTestProfileNdx++;
	  $iWriteTableHeader = 1;
	} 
  if( $iWriteTableHeader )
  {
    #@ReportIntervals = ();
 		print $PlatformPercentHTMLFile "<THEAD >\n";	  
    
    $iWriteTableHeader = 0;
  	while (@Columns) 
  	{
  	  my $strColumn = shift(@Columns);
  	  if( $strColumn eq 'URL' )
  	  {
  	    next;
  	  }
  	  if( $strColumn =~ /UpdateInterval/ )
  	  {
  	    #Sensor columns are in format: Sensor-UpdateInterval X.
  	    my( $strSensor,$strInterval ) = split( /-/, $strColumn );
  	    $strColumn = "$strSensor";
  	    #my( $strBuf, $iInterval) = split( / /, $strInterval );
  	    #push( @ReportIntervals, $iInterval );
  	  }
  		print $PlatformPercentHTMLFile "<TH><STRONG>$strColumn</STRONG></TH>\n";	  
  	}
 		print $PlatformPercentHTMLFile "</THEAD >\n";	  
  }
  else
  {
  	print $PlatformPercentHTMLFile "<tr>\n";
    my $iCnt = 0;
  	while (@Columns) 
  	{
  	  my $strColumn = shift(@Columns);
 	    my $rgbColor = RGB_DEFAULT;  	    
  	  if( $iCnt >= 3 )
  	  {
  	    if( $strColumn >= 90.0 )
  	    {
  	     $rgbColor = RGB_90THPERCENTILE;
  	    }
  	    elsif( $strColumn >= 70.0 )
  	    {
  	     $rgbColor = RGB_70THPERCENTILE;  	      
  	    }
  	    else
  	    {
  	      $rgbColor = RGB_UNDER70TH;
  	    }
  	  }
  	  # First 3 columns are platform, url, and date.
  	  else
  	  {
  	    #First Column is Platform, 2nd is URL so we want to create a clickable platform name.
  	    if( $iCnt == 0 )
  	    {
  	      my $strURL = shift(@Columns);
  	      $iCnt++; #Bump count by one since we grabbed the URL.
          $strColumn = "<A HREF=\"$strURL\">$strColumn</A>";       		    	      
  	    }
  	  }	  
  		print $PlatformPercentHTMLFile "<td bgcolor=\"$rgbColor\" >$strColumn</td>\n";    		
  	  $iCnt++;
  	}
    print( $PlatformPercentHTMLFile "</tr>\n" );
  }
}#foreach line
print( $PlatformPercentHTMLFile "</table><BR><BR>\n" ); #Close the table.
print( $PlatformPercentHTMLFile  "</BODY>\n" ); #Terminate page body.
print( $PlatformPercentHTMLFile "</html>\n" ); #Closing page tag.

close( $PlatformPercentHTMLFile );
close( $PlatformPercentCSVFile );
            