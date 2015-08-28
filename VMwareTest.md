see also [VMwareHome](VMwareHome.md),[VMwareInstall](VMwareInstall.md)



# Download the vmware player #

**Note** the below image install functions are for a desktop-PC based 'player' version, while the latest Xenia image is ESXi 4.0 server-based.  To convert to a player-based version of the image, see instructions at http://blog.laksha.net/2009/10/how-to-create-virtual-machine-using.html or use the vmware vCenter convertor standalone application(should be available for free from vmware website).

## Windows ##

Goto vmware player download page at http://www.vmware.com/download/player/download.html and download, install windows version(2.5.1 tested)

## Linux ##

Goto vmware player download page http://www.vmware.com/download/player/download.html and download the Linux version 2.5.1(the 32-bit, not 64-bit) .bundle file

Used the instructions at https://help.ubuntu.com/community/VMware/Player for guidance, only had to run the following line
```
gksudo bash ./VMware-Player-2.5.1-126130.i386.bundle
```

## Macintosh ##

see http://www.vmware.com/products/fusion


---


# Download the vmware image instance #

The latest vmware image download instructions are at [VMwareDownload](VMwareDownload.md)

This vmware image was developed on top of the FOSS geospatial vmware image(geostatistics package which includes 'R') available at http://gisvm.com ([appliance description](http://www.vmware.com/appliances/directory/55606)) - thanks to Ricardo Pinho.

While the Xenia scripts do not directly utilize/interact those included applications in the gisvm image at this time, I thought they represent the best existing collection of FOSS geospatial software for future development.

Start the vmware image on the vmware player by opening the associated .vmx file


---


# Startup #

The image being played may report in the player title the gisvm version 'gisvm20081101en\_r' which can be ignored.  I have not determined how to set this title properly yet.

For the 'virtual' server on the vmplayer menu at screen top, changed the 'Devices->Network Adapter' setting to 'Bridged' which establishes network communication between the virtual server and host.

The image should boot to a command line user login.  Login as user **xeniaprod** with password **xeniaprod99**

I have the GUI display (gdm) disabled by default.  To start a GUI session enter the following command and wait for the GUI to display.
```
sudo gdm start
```

If you wish to re-enable the GUI default behaviour see instructions at http://ubuntuforums.org/showthread.php?t=664199

You may also need to set the radio button '**Wired Network**' from the top menu icon(circled in red) in the following image

<img src='http://xenia.googlecode.com/files/screen_1.jpg' height='300' width='600'>

At this point your image instance should have internet connectivity and you should be able to start a firefox browser(browser shortcut at top-of-screen menu) which will default to the website at <a href='http://gisvm.com'>http://gisvm.com</a>  Typing in the URL <a href='http://localhost/xenia'>http://localhost/xenia</a> should display the same as the above screenshot.<br>
<br>
While leaving the xenia vmware instance running, it is by default using the xeniaprod crontab to once an hour(at the top of the hour) fetch 3 sample organization hourly data feed files formatted as ObsKML (see ObsKML simple sample below) to populate a local sqlite database and produce several products.<br>
<br>
The main file which creates the data process flow can be invoked manually by the following command (also automatically executed hourly at the top of the hour by the xeniaprod crontab)<br>
<pre><code>bash /home/xeniaprod/cron/xeniaflow.sh<br>
</code></pre>

After the <b>xeniaflow.sh</b> script has executed, most of the products listed at <a href='VMwareProductsLocal.md'>VMwareProductsLocal</a> should be populated locally to the vmware image instance(start a firefox browser image within the instance and goto <a href='http://localhost/xenia'>http://localhost/xenia</a> which should display the same as the above screenshot).  A few of the graph products,etc require two or more runs before displaying properly so you may have to wait a few hours/passes or so to start seeing proper results.<br>
<br>
<br>
<hr />
<h1>Adding a new ObsKML feed</h1>

<b>note - ObsKML is an XML feed oriented way of supplying new data to the Xenia database, but writing SQL INSERT statements to import/populate or ASCII/CSV export data are valid approaches also - in this case the import/export scripts at <a href='http://code.google.com/p/xenia/source/browse/#svn/trunk/postgresql/import_export'>http://code.google.com/p/xenia/source/browse/#svn/trunk/postgresql/import_export</a> (in particular <a href='http://code.google.com/p/xenia/source/browse/trunk/postgresql/import_export/obskml_to_xenia_postgresql.pl'>http://code.google.com/p/xenia/source/browse/trunk/postgresql/import_export/obskml_to_xenia_postgresql.pl</a> ) may be helpful in understanding the structure of the data as stored in the relational database</b>

How to add additional data feeds(obskml formatted) beyond those already included (usgs, nerrs, ndbc, nws).<br>
<br>
Note the following currently available ObsKML feeds at <a href='http://carocoops.org/obskml/feeds/'>http://carocoops.org/obskml/feeds/</a>
<ul><li>ndbc (National Data Buoy Center) <i>included with test install</i>
</li><li>nos (National Ocean Service - Tides and Currents)<br>
</li><li>nws (National Weather Service) <i>included with test install</i>
</li><li>usf (University of South Florida)<br>
</li><li>nccoos (North Carolina Coastal Ocean Observing System)<br>
</li><li>cormp (UNCS Coastal Ocean Research and Monitoring Program)<br>
</li><li>carocoops (Carolinas Coastal Ocean Observing and Prediction System)<br>
</li><li>wq  (this is Southeast USGS coastal stations) <i>included with test install</i>
</li><li>nerrs (National Estuarine Research Reserve System) <i>included with test install</i>
</li><li>vos (NOAA Volutary Observing Ships)<br>
</li><li><i>can add more ObsKML feeds to an online catalog if community interest</i></li></ul>

The following example demonstrates how the hourly ObsKML data feed was added for  <a href='http://www.nws.noaa.gov/'>NWS</a> as available from<br>
<br>
<a href='http://carocoops.org/obskml/feeds/nws/nws_latest_obskml.zip'>http://carocoops.org/obskml/feeds/nws/nws_latest_obskml.zip</a>

<h2>Changes</h2>

All the following steps are done as user <b>xeniaprod</b>

<h3>Create necessary organization folder</h3>
<pre><code>mkdir /home/xeniaprod/feeds/nws<br>
</code></pre>

<h3>Edit /home/xeniaprod/cron/getObskml.sh</h3>
add line to retrieve obskml files(one or several as .kmz,.zip) to local folder<br>
<pre><code>wget http://carocoops.org/obskml/feeds/nws/nws_latest_obskml.zip -O /home/xeniaprod/feeds/nws/nws_metadata_latest.kmz<br>
</code></pre>
<h3>Edit /home/xeniaprod/cron/mk_xenia_all_latest.sh</h3>
add line to unzip one or several input obskml files(.kmz,.zip) to common temporary folder for common zip/processing<br>
<pre><code>unzip -q "../nws/nws_metadata_latest.kmz" &gt;&gt; /home/xeniaprod/tmp/cron.log 2&gt;&amp;1    <br>
</code></pre>

<h3>Add organization name to be included in status graphs, email notification</h3>
file /home/xeniaprod/config/config.xml<br>
<pre><code>  &lt;Organizations&gt;<br>
    &lt;org&gt;<br>
      &lt;name&gt;nws&lt;/name&gt;<br>
      &lt;count&gt;1&lt;/count&gt;  &lt;!-- lowest expected count/email alert threshold --&gt;<br>
    &lt;/org&gt;<br>
...<br>
</code></pre>

utilized by file(as $XMLConfigFile, no changes) /home/xeniaprod/scripts/sqlite/flow_monitor/check_status.pl<br>
<pre><code>my ($dbname,$email_flag,$hour_offset,$status_file,$status_file_latest,$image_file,$title,$range_top,$XMLConfigFile) = @ARGV;<br>
</code></pre>

<h2>optional</h2>

<h3>add organization to styled KMZ</h3>
file /home/xeniaprod/cron/styleLatest.sh <br />
add org name to array list<br>
<pre><code>my @org_array = qw(usgs nerrs ndbc nws);<br>
</code></pre>

<pre><code>mkdir /home/xeniaprod/feeds/nws/archive<br>
</code></pre>

<h4>Edit xeniaprod crontab to nightly cleanup archive files</h4>
As user xeniaprod run the following command to edit xeniaprod crontab in 'nano' editor<br>
<code>crontab -e</code>
add line<br>
<pre><code>2 0 * * * find /home/xeniaprod/feeds/ndbc/archive/* -maxdepth 1 -cmin +1400 -exec rm -f {} \;<br>
</code></pre>

<h2>ObsKML simple example</h2>

The below sample kml file shows an example of two observations listed at a platform. The xml schema is available <a href='http://carocoops.org/obskml/1.0.0/obskml_simple.xsd.txt'>here</a>

ObsKML is not a community standard at this time, but an in-house developed convention for staging/ingesting imported data to a common XML format using KML as a wrapper(GeoRSS,Atom/JSON could also possibly utilize this data content schema also).  Further ObsKML documentation is available <a href='http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/ObsKML'>here</a>.  Specific instrumentation examples are available at <a href='InstrumentationExamples.md'>InstrumentationExamples</a>

<pre><code>&lt;?xml version="1.0" encoding="UTF-8"?&gt;<br>
&lt;kml xmlns="http://earth.google.com/kml/2.1"<br>
     xmlns:obskml="http://carocoops.org/obskml/1.0.0/obskml_simple.xsd"&gt;<br>
&lt;Document&gt;<br>
  &lt;name&gt;Obskml sample&lt;/name&gt;<br>
  &lt;open&gt;1&lt;/open&gt;<br>
  &lt;Placemark id="carocoops.CAP1.buoy"&gt;<br>
    &lt;name&gt;carocoops.CAP1.buoy&lt;/name&gt;<br>
    &lt;description&gt;An html table derived from the obs kml metadata tags would be displayed here&lt;/description&gt;<br>
    &lt;Point&gt;<br>
      &lt;coordinates&gt;-79.68,32.86,0&lt;/coordinates&gt;<br>
    &lt;/Point&gt;<br>
    &lt;TimeStamp&gt;&lt;when&gt;2007-01-15T14:00:00&lt;/when&gt;&lt;/TimeStamp&gt;<br>
 <br>
    &lt;Metadata&gt;<br>
    &lt;obsList&gt;<br>
    &lt;obs&gt;<br>
      &lt;obsType&gt;air_temperature&lt;/obsType&gt;<br>
      &lt;uomType&gt;celsius&lt;/uomType&gt;<br>
      &lt;value&gt;21&lt;/value&gt;<br>
      &lt;elev&gt;3&lt;/elev&gt;<br>
    &lt;/obs&gt;<br>
<br>
    &lt;obs&gt;<br>
      &lt;obsType&gt;water_temperature&lt;/obsType&gt;<br>
      &lt;uomType&gt;celsius&lt;/uomType&gt;<br>
      &lt;value&gt;16&lt;/value&gt;<br>
      &lt;elev&gt;-1&lt;/elev&gt;<br>
    &lt;/obs&gt;<br>
    &lt;/obsList&gt;<br>
    &lt;/Metadata&gt;<br>
<br>
  &lt;/Placemark&gt;<br>
&lt;/Document&gt;<br>
&lt;/kml&gt;<br>
</code></pre>
<pre><code>The above schema represents two observations from a single platform.<br>
<br>
The 'elev' tag in the above schema corresponds to elevation. Positive is meters above sea level and negative is meters below sea level. Missing or unknown elevation values can leave an empty elev tag like &lt;elev /&gt;<br>
<br>
A recommended but not required convention is to use the Placemark id attribute to help uniquely identify observations between data providers. The recommended convention is the concatenation of &lt;organization&gt;.&lt;platform&gt;.&lt;package&gt; like carocoops.CAP1.buoy or nws.KCAE.met<br>
<br>
Observation listing order is preferred to be from highest elevation/altitude to lowest elevation/depth.<br>
<br>
Redundant sensors/observations would be listed in their order of importance (primary, secondary, etc).<br>
</code></pre>

<h2>Adding new measurement types (m_type_id)</h2>

The existing database supported data dictionary of measurement types(m_type) which is the combination of observation type(obsType) and unit of measurement type(uom_type) is listed <a href='http://carocoops.org/microwfs/data_dictionary_listing.txt'>here</a>

If you would like to add additional measurement types see documentatation <a href='http://code.google.com/p/xenia/wiki/XeniaSqliteNotes#Adding_simple_scalar_types_to_the_data_dictionary_tables_and_pro'>here</a> and database schema diagram <a href='http://code.google.com/p/xenia/wiki/XeniaPackageSqlite#Simplified_schema'>here</a>

<h2>Example scripts for generating ObsKML</h2>

Example scripts detailing how to create ObsKML from several data source types are documented at<br>
<br>
<a href='http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/ObsKMLGenerate'>http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/ObsKMLGenerate</a>

<b>Note that the ObsKML schema does not currently utilize an 'obskml:' namespace convention but may in a future version.</b>

If you have created an ObsKML feed that you would like to share please email me (jeremy.cothran@gmail.com) and I will add it to an online community catalog.