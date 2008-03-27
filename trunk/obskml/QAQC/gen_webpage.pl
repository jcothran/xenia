#!/usr/bin/perl
#script: gen_webpage.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#Date: August 10, 2007
#script description
#generates an html webpage table from csv output

use strict;
use Getopt::Long;

#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.
use constant MICROSOFT_PLATFORM => 0;
 
use constant
{
  RGB_DEFAULT => 'FFFFFF',
  RGB_FAIL    => 'FF0000',
  RGB_PASS    => '00FF00',
  RGB_LAGGING => 'a020f0',
  RGB_MISSING => '4169e1',
  RGB_MISSING_ALL => '4169e1'
};
my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "WorkingDir=s" );

my $output_name   = $CommandLineOptions{"WorkingDir"};   
#my $output_name = $ARGV[0];
if( length( $output_name ) == 0 )
{
  die print( "Missing required field(s).\n".
              "Command Line format: -WorkingDir\n". 
              "-WorkingDir provides the path to the directory where the test_results.csv resides for a given provider. HTML file created will be created here as well.\n" );  
}

#my $output_name = $ARGV[0];


if( !MICROSOFT_PLATFORM ) 
{
  open(CSV_FILE,"$output_name/test_results.csv") || die "ERROR: Unable to open file: $output_name\\test_results.csv";
  open(HTML_FILE,">$output_name/test_results.html")|| die "ERROR: Unable to open file: $output_name\\test_results.csv";
}
else
{
  open(CSV_FILE,"$output_name\\test_results.csv") || die "ERROR: Unable to open file: $output_name\\test_results.csv";
  open(HTML_FILE,">$output_name\\test_results.html") || die "ERROR: Unable to open file: $output_name\\test_results.csv"; 
}

print HTML_FILE "<html>\n";
print( HTML_FILE "<link href=\"http://carocoops.org/~dramage_prod/styles/main.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n" );

my $iTestProfileNdx = 0;
print( HTML_FILE "<table border=\"1\">\n" );
print( HTML_FILE "<CAPTION><H2>Sensor Range Checks</H2></CAPTION>\n" );

foreach my $line (<CSV_FILE>) 
{
	my $iWriteTableHeader = 0;
	my @elements = split(/,/,$line);
	if (@elements[0] =~ /Test_Profile/) 
	{ 
	  #If this is not the first test profile, we need to close out the previous table.
	  if( $iTestProfileNdx ne 0 )
	  {
    	print( HTML_FILE "<tr><td><BR></td></tr>\n" );    
	    #print( HTML_FILE "</table><BR><BR>" );
	  }
	  #Start a new table per test profile.
	  #print( HTML_FILE "<table border=\"1\">" );
	  
	  #For each new Test Profile, let's add a row to help show this.
	  #my $strBuf = "<tr><td><a name=\"$elements[0]\"><STRONG>$elements[0]</STRONG></A></td></tr>";  
	  #my $strBuf = "<CAPTION><a name=\"$elements[0]\">$elements[0]</A></CAPTION>\n";
	  #print( HTML_FILE $strBuf );
	  
	  $iTestProfileNdx++;
	  $iWriteTableHeader = 1;
	} 
	
	#Write the table header?
  if( $iWriteTableHeader )
  {
    $iWriteTableHeader = 0;
    print( HTML_FILE "<THEAD>" );
    my $iColCnt = 0;
    while (@elements)    
    {       
      my $strColumn = shift( @elements );
      
      #We don't add a header for the url, we use it to make a link on the platform id.
      if( $strColumn eq 'platform_url')
      {
      	$iColCnt++;
        next;
      }
      #First 3 columns are platform, url and date, then we have obs and range which we want to combine into 1 column.
      if( $iColCnt > 2 )
      {
        my( $strObs, $strUOM ) = split( /\./, $strColumn );
        my $strRange = shift( @elements );
        $iColCnt++;
        $strColumn = '<H4>'.$strObs.'<BR>'.$strUOM."<BR>".$strRange.'</H4>';
      }	      	
    	print( HTML_FILE "<TH>$strColumn</TH>\n" );
    	$iColCnt++;
    }
    print( HTML_FILE "</THEAD>\n" );
  }
  else
  {	
  	print HTML_FILE "<tr>";
      
	  my $rgbColor = RGB_DEFAULT;
		if ($elements[2] =~ /lagging/ )
		{ 
		  $rgbColor = RGB_LAGGING;
		}
		elsif( $elements[2] =~ /missing/ )
		{
		  $rgbColor = RGB_MISSING;  
		}
    my $strElement = "<td><A HREF=\"$elements[1]\">$elements[0]</A>\n</td><td bgcolor=\"$rgbColor\">$elements[2]</td>\n";       		  
 		print HTML_FILE $strElement; 
  			
  	if (@elements <= 1) 
  	{
  	 my $rgbColor = RGB_MISSING_ALL;
  	 print HTML_FILE "<td bgcolor=\"$rgbColor\">No data available.</td>\n"; 
  	}
  
  	shift(@elements);  #shift out the first column, for header rows this is the test_profile string, for data rows it is the  platform id.
  	shift(@elements);  #shift out the 2nd column, for header rows this is the platform url, same for data rows..
  	shift(@elements);  #shift out the 3rd column, for header rows this is the time, same for data.
  
  	while (@elements) 
  	{
  		my $test_result = shift(@elements);
  		my $m_value = shift(@elements);
  		
  		chomp($test_result);
  		chomp($m_value);
  		#print ":".$test_result.":\n"; #debug1
  		my $bgcolor = RGB_DEFAULT;
  		if ($test_result eq 'pass')
  		{ 
  		  $bgcolor = RGB_PASS;
      }
  		elsif($test_result eq 'fail low')
  		{ 
  		  $bgcolor = RGB_FAIL; 
  		}
  		elsif($test_result eq 'fail high')
  		{ 
  		  $bgcolor = RGB_FAIL; 
  		}
  		elsif($test_result =~ "missing" || $test_result =~ "none" )
  		{
        $bgcolor = RGB_MISSING; 
  		}
  		elsif($test_result =~ 'missing all')
  		{
  		  $bgcolor = RGB_MISSING_ALL; 	  
  		}
  		print HTML_FILE "<td bgcolor=\"$bgcolor\">$test_result($m_value)</td>\n";
  	}
  	print HTML_FILE "</tr>\n";
  }	
}

#print HTML_FILE "</html></table>\n";
print HTML_FILE "</html>\n";

close(CSV_FILE);
close(HTML_FILE);

exit 0;
