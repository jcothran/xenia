use warnings;
use strict;

use XML::LibXML;
use Getopt::Long;
use LWP::Simple;
use DBI;

my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "SourceFile=s",
            "DestinationFile=s",
            "DBTableName=s",
            "LatitudeColumn=s",
            "LongitudeColumn=s",
            "KMLPlacemarkNameColumn=s",
            "DataColumnsToInclude=s",
            "DataColumnNames:s",
            "Delimeter:s"
          );

my $strSourceFile           = $CommandLineOptions{"SourceFile"};
my $strDestinationFile      = $CommandLineOptions{"DestinationFile"};
my $strLatitudeColName      = $CommandLineOptions{"LatitudeColumn"};
my $strLongitudeColName     = $CommandLineOptions{"LongitudeColumn"};
my $KMLPlacemarkNameColumn  = $CommandLineOptions{"KMLPlacemarkNameColumn"};
my $strDataColumnsToInclude = $CommandLineOptions{"DataColumnsToInclude"};
my $strDataColumnNames      = $CommandLineOptions{"DataColumnNames"};
my $strDelimeter            = $CommandLineOptions{"Delimeter"};
if( length( $strSourceFile ) == 0     ||
    length( $strDestinationFile ) == 0  ||  
    length( $strLatitudeColName ) == 0  ||  
    length( $strLongitudeColName ) == 0  ||  
    length( $strDataColumnsToInclude ) == 0 ||
    length( $KMLPlacemarkNameColumn ) == 0 
   )
{
  die print( "Missing required field(s).\n".
              "Command Line format: --SourceFile --DestinationDB --LatitudeColumn --LongitudeColumn --DataColumnsToInclude --Delimeter\n" 
            );
              
}

my $SourceSCVFile;
open( $SourceSCVFile, "< $strSourceFile") || die( "ERROR: Unable to open file: $strSourceFile");

#my $KMLFile;
#my $strFileName = "$strDestinationFile";
#open ($SQLFile,">"$strDestinationFile") || die( "ERROR: Unable to open file: "$strDestinationFile");;


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

my $XMLDoc = BeginKML();
if( $XMLDoc == undef )
{
  die( "ERROR: Unable to create XML document. Cannot continue.\n" );
}
my $DocTagRoot = KMLAddHeader( $XMLDoc );


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
        elsif( $strCol eq $KMLPlacemarkNameColumn )
        {
          $refHeader->{$KMLPlacemarkNameColumn}{Ndx} = $iColCnt;
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
    $strTable = '<table>';
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
    KMLAddPlacemarkSimple( $XMLDoc, $DocTagRoot, 
                           @aRow[$refHeader->{$strLatitudeColName}{Ndx}], @aRow[$refHeader->{$strLongitudeColName}{Ndx}],
                           @aRow[$refHeader->{$KMLPlacemarkNameColumn}{Ndx}],
                           $strTable
                         );#( $XMLDoc, $ParentTag, $Lat, $Long, $strName, $strDescription );
    
  }
  $iLineCnt++;
#    my $strSQL = "INSERT INTO $strDBTableName(wkt_geometry,html) values( ('POINT(@aRow[$refHeader->{$strLongitudeColName}{Ndx}] @aRow[$refHeader->{$strLatitudeColName}{Ndx}])') ,'$strTable' );\n";
  
}
EndKML( $XMLDoc, $strDestinationFile );
#######################################################################################################
#Subroutines
#######################################################################################################
sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}
       
#######################################################################################################
#Subroutine: BuildKMLFile
# Given a hash and a filename, this set of subroutines will build an obsKML file.
# Parameters:
# 1 $strKMLFileName is a string that contains the fully qualified filename to use to write the XML to.
########################################################################################################

sub BeginKML #( $strKMLFileName )
{
  my( $strKMLFileName ) = @_;
  
  my %PlatformIDHash;
   
  my $XMLFile = undef;
  #Create the XML document object.
  my $XMLDoc = XML::LibXML::Document->new();

  #Open the file we write the XML into.
  open( $XMLFile, ">", $strKMLFileName );
  if( !defined $XMLFile )
  {
   print( "ERROR: Unable to open file: $strKMLFileName\n" );
   die;
  }   
  return( $XMLDoc );
}

#######################################################################################################
#Subroutine: KMLAddHeader
# Builds the KMl header, adding the root node, as well as the Document node.
# Parameters:
# 1) $Doc is a valid XML::LibXML::Document->new() object.
# Return:
# Returns the $DocumentTag node to work off of.
########################################################################################################
sub KMLAddHeader
{
 my $Doc = shift @_;
 my $DocumentTag = undef;
 my $RootTag = undef;
 if( defined $Doc )
 {
  $RootTag = $Doc->createElement( 'kml');
  $RootTag->setAttribute('xmlns:kml', "http://earth.google.com//kml//2.2" );
  $Doc->setDocumentElement($RootTag);

  $DocumentTag = $Doc->createElement( 'Document');
  $RootTag->appendChild( $DocumentTag );      
 }
 return( $DocumentTag );
}
########################################################################################################
#Subroutine: KMLAddPlacemarkSimple
#
# Description:
# Adds a placemark with the minimal data set needed.
#Parameters:
# 1. A valid XMLDoc 
# 2. A valid Parent node to build from. Should be the return of the sub KMLAddHeader.
# 3. A string name for the placemark.
# 4. A string description of the placemark.
# 5. A string representing the platform ID.
# 6. String to be used for the description field.
########################################################################################################
sub KMLAddPlacemarkSimple  #( $XMLDoc, $ParentTag, $Lat, $Long, $strName, $strDescription );
{
  my( $Doc, $Parent, $Lat, $Long, $strName, $strDescription ) = @_;
  
  my $Placemark = $Doc->createElement( 'Placemark'); 
 
  KMLAddLatLong( $Doc, $Placemark, $Lat, $Long );
  KMLAddDescription( $Doc, $Placemark, $strDescription );
  AddChild( $Doc, $Placemark, 'name', $strName );
  
  $Parent->appendChild( $Placemark );
  return(1);
}
########################################################################################################
#Subroutine: AddChild
#
#Parameters:
# 1: XML::LibXML::Document variable This is the valid "newed" document object we are going to work on.
# 2: The createElement parent variable to which we attach the child.
# 3: string representing the name of the element we are going to add.
# 4: string representing the text field we want to add to the element.
#
# Return:
# none 
########################################################################################################
sub AddChild
{
 my $Doc = shift @_;
 my $Parent = shift @_;
 my $Element = shift @_;
 my $Text    = shift @_;
 
 my $ChildEle = $Doc->createElement( $Element );
 $ChildEle->appendText( $Text );
 $Parent->appendChild($ChildEle);

 return;
}

########################################################################################################
# KMLAddLatLong
# Adds the lat and long into the placemark tag.
########################################################################################################

sub KMLAddLatLong #( $Doc, $Parent, $dLat, $dLong )
{
  my ( $Doc, $Parent, $dLat, $dLong ) = @_;
  
  my $Points = $Doc->createElement( 'Point');
  my $strCoords = "$dLong,$dLat";
  AddChild( $Doc, $Points, 'coordinates', $strCoords );  
  $Parent->appendChild( $Points );
}
########################################################################################################
# KMLAddTimeStamp
# Adds the timestamp into the placemark tag.
########################################################################################################
sub KMLAddTimeStamp#( $Doc, $Parent, $strTimeStamp )
{
  my ( $Doc, $Parent, $strTimeStamp ) = @_;
  
  my $TimeStamp = $Doc->createElement( 'TimeStamp');
  AddChild( $Doc, $TimeStamp, 'when', $strTimeStamp );  
  $Parent->appendChild( $TimeStamp );

}
########################################################################################################
# KMLAddDescription
# Adds the timestamp into the placemark tag.
########################################################################################################
sub KMLAddDescription#( $Doc, $Parent, $strDesc )
{
  my ( $Doc, $Parent, $strDesc ) = @_;
  
  my $Desc = $Doc->createElement( 'description'); 
  my $CDATADesc = $Doc->createCDATASection( $strDesc );
  $Desc->appendChild( $CDATADesc );
  $Parent->appendChild( $Desc );
}

sub EndKML #( $XMLDoc, $strDestinationFile )
{
  my ( $XMLDoc, $strDestFile ) = @_;
  
  my $XMLFile;
  open ($XMLFile,">$strDestFile") || die( "ERROR: Unable to open file: $strDestFile");
  
  # Write the XML data to the file.
  print( $XMLFile $XMLDoc->toString );      
  close( $XMLFile );
}
       