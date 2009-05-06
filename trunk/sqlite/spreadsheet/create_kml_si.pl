#!/usr/bin/perl

#this script reads the local si.db sqlite database and creates kml/kmz output 
#files

use strict;
use DBI;

my $dbname = '/var/www/html/spreadsheet/si.db';

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth,$sth_2);

my $kml_placemarks = '';
##################
$sql = qq{ select id,institution from organization };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();

$kml_placemarks .= <<"END_OF_FILE";
<Folder>
<name>SECOORA Sensor Inventory</name>
<visibility>0</visibility>
END_OF_FILE

while (my ($org,$institution) = $sth->fetchrow_array) {

$kml_placemarks .= <<"END_OF_FILE";
<Folder>
<name>$org</name>
<visibility>0</visibility>
END_OF_FILE


##################
$sql = qq{ select id,url,description,longitude,latitude from platform where organizationId = '$org' };
print $sql."\n";
$sth_2 = $dbh->prepare( $sql );
$sth_2->execute();

##################
while (my ($id,$url,$description,$longitude,$latitude) = $sth_2->fetchrow_array) {

$description = '<![CDATA['."<a href=\"$url\">platformLink</a><br/>$description<br/>Longitude:$longitude<br/>Latitude:$latitude<br/>Intitution(s):$institution".']]>';

$kml_placemarks .= <<"END_OF_FILE";
<Placemark>
<name>$org:$id</name>
<visibility>0</visibility>
<description>$description</description>
<Point><coordinates>$longitude,$latitude</coordinates></Point>
</Placemark>
END_OF_FILE

} #while platform

$kml_placemarks .= <<"END_OF_FILE";
</Folder>
END_OF_FILE

} #while org

##################
open (FILE_KML,">si.kml");

my $kml_content;
$kml_content = <<"END_OF_FILE";
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>SECOORA Sensor Inventory</name>
END_OF_FILE

print FILE_KML $kml_content;
print FILE_KML $kml_placemarks;

$kml_content = <<"END_OF_FILE";
  </Folder>
  </Document>
</kml>
END_OF_FILE
print FILE_KML $kml_content;

close (FILE_KML);

`zip si.kmz si.kml`;

exit 0;
