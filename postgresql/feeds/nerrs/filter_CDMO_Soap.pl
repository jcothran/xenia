#JTC filter_CDMO.pl
use strict;
use SOAP::Lite;

my $num_recs = @ARGV[0];
my $output_dir = @ARGV[1];


print("num_recs = $num_recs\n");
print("output_dir = $output_dir\n");

my @station_list = ('niwolmet','niwolwq','acebpmet','acespwq','apaebmet','apaebwq','gndcrmet','gndblwq','gtmpcmet','gtmpcwq','jobjbmet','job20wq','job09wq','nocrcmet','nocrcwq','rkbuhmet','rkblhwq','sapmlmet','sapldwq','cbmjbmet','cbmocwq','cbmrrwq','cbvgiwq','cbvshwq','cbvtcmet','delllwq','delsjmet','delslwq','elkcwmet','elksmwq','grbglmet','grborwq','hudfsmet','hudtnwq','hudtswq','jacb6wq','jacnewq','jacncmet','kachomet','kachdwq','kacsdwq','marabwq','marcemet','narpcmet','nartbwq','owcolwq','owcowmet','pdbpfmet','pdbbvwq','pdbjlwq','sfbccwq','sfbrrmet','soschwq','soscmmet','sosvawq','sossewq','soswiwq','tjroswq','tjrtlmet','wqbchmet','wqbmhwq','wkbfrwq','wkbwbmet','wellfmet','welsmwq');
#my @station_list = ("niwolmet");
my ($endpoint, $uri, $method, $method_urn);
$endpoint   = "http://cdmo.baruch.sc.edu/webservices/xmldatarequest.cfc";
$uri         = "http://uri.not";
$method     = 'exportAllParamsXML';

my $station_id = '';
foreach $station_id (@station_list) 
{
  print $station_id . "\n";
  my $filename = "$output_dir/cdmo_$station_id";
  my $file_out = $filename . '.txt';
  my $fh;
  open($fh, ">$file_out") or die("Failed to open file $file_out");
  
  
  my $soap = SOAP::Lite
      ->uri($uri)
      ->proxy($endpoint)
      ->outputxml(1);


  my $response = $soap->$method(SOAP::Data->name(tbl => "$station_id"),
                      SOAP::Data->name(numrecs => "$num_recs"));
  
  print $fh $response;
  print 'All Parameter Response: <xmp>'.$response."</xmp>\n";
  close($fh);
  
  open($fh, "<$file_out")  or die("Failed to open file $file_out");

  my $line_feed = 0;
  my $content = '';
  foreach my $line (<$fh>)
  {
    if (!($line =~ /nds/) && ($line_feed == 0)) 
    { 
      next; 
    } 
    else 
    { 
      $line_feed = 1; 
    }
    $content .= $line;
    if ($line =~ /\/nds/)
    { 
      last; 
    }
  }

  close ($fh);

  open ($fh,">$filename".'.xml');
  print $fh $content;
  close($fh);

}
########################################################
#get rid of extra unnecessary header and footer lines with namespaces that confuse LibXML



exit 0;
