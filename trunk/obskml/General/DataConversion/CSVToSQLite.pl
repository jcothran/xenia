use warnings;
use strict;

use Getopt::Long;
use LWP::Simple;
use DBI;

my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "SourceFile=s",
            "DestinationDB=s",
            "DBTableName=s",
            "LatitudeColumn=s",
            "LongitudeColumn=s",
            "DataColumnsToInclude=s",
            "DataColumnNames:s",
            "Delimeter:s",
            "CSSTableStyleID:s"
          );

my $strSourceFile           = $CommandLineOptions{"SourceFile"};
my $strDestinationDB        = $CommandLineOptions{"DestinationDB"};
my $strDBTableName          = $CommandLineOptions{"DBTableName"};
my $strLatitudeColName      = $CommandLineOptions{"LatitudeColumn"};
my $strLongitudeColName     = $CommandLineOptions{"LongitudeColumn"};
my $strDataColumnsToInclude = $CommandLineOptions{"DataColumnsToInclude"};
my $strDataColumnNames      = $CommandLineOptions{"DataColumnNames"};
my $strDelimeter            = $CommandLineOptions{"Delimeter"};
my $strCSSTableStyleID      = $CommandLineOptions{"CSSTableStyleID"};
if( length( $strSourceFile ) == 0     ||
    length( $strDestinationDB ) == 0  ||  
    length( $strLatitudeColName ) == 0  ||  
    length( $strLongitudeColName ) == 0  ||  
    length( $strDataColumnsToInclude ) == 0 ||
    length( $strDBTableName ) == 0 
   )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --SourceFile --DestinationDB --LatitudeColumn --LongitudeColumn --DataColumnsToInclude --Delimeter\n" 
            );
              
}

my $SourceSCVFile;
open( $SourceSCVFile, "< $strSourceFile") || die( "ERROR: Unable to open file: $strSourceFile");

my $SQLFile;
my $strFileName = "$strDBTableName".'_html_content.sql';
open ($SQLFile,">./$strFileName") || die( "ERROR: Unable to open file: ./$strFileName");;


#Break out the columns into an array we use to find out which column they are in in the file.
my @aDataCols;
if( length( $strDataColumnsToInclude ) )
{
  @aDataCols = split(  /\,/, $strDataColumnsToInclude );
}
my @aDataColNames;
if( length( $strDataColumnNames ) )
{
  @aDataColNames = split(  /\,/, $strDataColumnNames );
}

my $iLineCnt = 0;
my $iTotalColCnt = 0;
my %Header;
my $refHeader = \%Header;
while( my $strRow = <$SourceSCVFile> )  
{ 
  my @aRow = split(  /\,/, $strRow );
  #Read header line.
  if( $iLineCnt == 0 )
  {
    $iTotalColCnt = @aRow;
    my $iColCnt = 0;
    my $iCnt = @aRow;
    #Loop through the header and save off the columns for the data we need. 
    while( $iColCnt < $iCnt )
    {
      my $strCol = shift( @aRow );
      $strCol = trim( $strCol );
      chomp( $strCol );
      if( length( $strCol ) )
      {
        if( $strCol eq $strLatitudeColName )
        {
          $refHeader->{$strLatitudeColName}{Ndx} = $iColCnt;
        }
        elsif( $strCol eq $strLongitudeColName )
        {
          $refHeader->{$strLongitudeColName}{Ndx} = $iColCnt;
        }
        my $iDataCol = 0;
        my $iDataColCnt = @aDataCols;
        while( $iDataCol < $iDataColCnt )
        {
          my $strDataCol =@aDataCols[$iDataCol];  
          if( $strCol eq $strDataCol )
          {
            #Save the column index for the datacolumn.
            $refHeader->{$strDataCol}{Ndx}        = $iColCnt;
            #If we have a prefered column name to use, save it.
            if( length( @aDataColNames[$iDataCol] ) )
            { 
              $refHeader->{$strDataCol}{ColumnName} = @aDataColNames[$iDataCol];
            }
            else
            {
              $refHeader->{$strDataCol}{ColumnName} = $strDataCol;
            }
            last;
          }
          $iDataCol++;
        }
      }
      $iColCnt++;
    }
  }
  #Process the data.
  else
  {
    #$html_content .= "INSERT INTO html_content(wkt_geometry,organization,html) values ('POINT($longitude $latitude)','$operator','<a href=\"$operator_url\" target=new onclick=\"\">organization: $operator</a><br/><a href=\"$platform_url\" target=new onclick=\"\">platform: $placemark_id</a><br/>$platform_desc<table cellpadding=\"2\" cellspacing=\"2\"><caption>$datetime_label</caption>";
    my $strTable;
    if( length( $strCSSTableStyleID ) )
    {
     $strTable = "<table id=$strCSSTableStyleID>";     
    }
    else
    {
     $strTable = '<table>';
    }
    my $iDataCol = 0;
    my $iDataColCnt = @aDataCols;
    #Loop though and build our table.
    while( $iDataCol < $iDataColCnt )
    {
      my $strDataCol = @aDataCols[$iDataCol];
      my $strData = trim( @aRow[$refHeader->{$strDataCol}{Ndx}] );
      $strTable .= "<tr><th>$refHeader->{$strDataCol}{ColumnName}</th><td>$strData</td></tr>";
      $iDataCol++;
    }
    $strTable .= '</table>';
    my $strSQL = "INSERT INTO $strDBTableName(wkt_geometry,html) values( ('POINT(@aRow[$refHeader->{$strLongitudeColName}{Ndx}] @aRow[$refHeader->{$strLatitudeColName}{Ndx}])') ,'$strTable' );\n";
    
    print( $SQLFile $strSQL );
  }
  $iLineCnt++;
}
sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
       