#!/usr/bin/perl
use strict;

use LWP::Simple;

#normally kml tag would include xmlns like following, but xmlns has processing problem issues with XML::LibXML - <kml xmlns="http://earth.google.com/kml/2.1">
my $xml_content = <<"END_OF_FILE";
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns:kml="http://earth.google.com/kml/2.1" xmlns:obsList="http://carocoops.org/obskml/1.0.0/obskml_simple.xsd">
<!-- JTC - please forgive any unorthodoxy in the namespace declaration above, there's a bug with the perl XML::XPath package I'm using where all xmlns must be declared in the root element using prefix notation -->
<Document>
<name>Near Real-Time Data published by FIT</name>
<open>1</open>
END_OF_FILE

##repeating elements section

my $url = 'http://my.fit.edu/coastal/DATA.HTM';
getstore($url,'./latest.txt') or die "Couldn't get $url\n";

my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);
$temp_year = 1900+$temp_year; 

my $time_zone = '-05';                
#if ($isdst) { $time_zone = '-04:00'; } else { $time_zone = '-05:00'; } 
#print "year:$temp_year $time_zone\n";

#push valid lines(with year) into array
my @array_lines = ();
my $line = '';
open(FILE,"./latest.txt");
foreach $line (<FILE>) {
if (!($line =~ /$temp_year/)) { next; }
push(@array_lines,$line);
}
close(FILE);

#only process last few(hours worth) of lines

for (my $i = 0; $i < 6; $i++) {

$line = pop(@array_lines);

my @elements = split(/\s+/,$line);

@elements[1] = substr(@elements[1],1);
@elements[2] = substr(@elements[2],0,-1);

my $datetime = "@elements[1]T@elements[2]$time_zone";
print "$datetime $elements[5] $elements[6]\n";

$xml_content .= <<"END_OF_FILE";
<Placemark id="fit.sispnj.met">
<Metadata>
<obsList>
        <operatorURL>http://research.fit.edu/wave-data</operatorURL>
        <platformURL>http://research.fit.edu/wave-data/realtime-data.php</platformURL>
        <platformDescription>Sebastian Inlet met station</platformDescription>
        <obs>
                <obsType>air_temperature</obsType>
                <uomType>celsius</uomType>
                <value>$elements[5]</value>
                <elev>10</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>air_pressure</obsType>
                <uomType>mb</uomType>
                <value>$elements[6]</value>
                <elev>10</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>wind_speed</obsType>
                <uomType>m_s-1</uomType>
                <value>$elements[7]</value>
                <elev>10</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>wind_from_direction</obsType>
                <uomType>degrees_true</uomType>
                <value>$elements[8]</value>
                <elev>10</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>water_temperature</obsType>
                <uomType>celsius</uomType>
                <value>$elements[10]</value>
                <elev>-3</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>salinity</obsType>
                <uomType>psu</uomType>
                <value>$elements[13]</value>
                <elev>-3</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
        <obs>
                <obsType>depth</obsType>
                <uomType>m</uomType>
                <value>$elements[14]</value>
                <elev>-3</elev>
                <dataURL>http://my.fit.edu/coastal/DATA.HTM</dataURL>
        </obs>
</obsList>
</Metadata>
                <name>fit.sispnj.met</name>
                <description>Sebastian Inlet met station</description>
                <Point>
                <coordinates>-80.444722,27.861667</coordinates>
                </Point>
                <TimeStamp><when>$datetime</when></TimeStamp>
                </Placemark>
END_OF_FILE

}

$xml_content .= "</Document>\n</kml>";

open(FILE,">./fit.kml");
print FILE $xml_content;
close(FILE);

`zip fit.kmz fit.kml`;
`cp fit.kmz /var/www/xenia/feeds/fit/fit_metadata_latest.kmz`;

exit 0;
