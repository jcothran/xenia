

# Intro #

I've been experimenting some with Google spreadsheets lately and I did not realize that it includes a back-end data API for gathering/updating spreadsheet data.

A common issue from an IT perspective is that we are constantly trying to move and reformat Excel spreadsheet data (both data and metadata) from research projects/instrumentation logs into relational databases or other formats that are easier to work with and manage.

Turns out that google spreadsheets could be shared among a list of collaborators with a Google account(which can be aliased against an existing non-gmail email address). Spreadsheet info could be published for public viewing/access or kept private to the group of document collaborators.

Spreadsheets include a revision history so that if someone accidentally messed up the wrong sheet/tow/cell, we could correct using the earlier revision.  The revision capacity could also be used for provenance, time comparison purposes.

Best of all spreadsheets include an easy to use developer data API(supporting a variety of languages) that includes 'RESTful' data access/edit and some visualization capabilities via community-contributed 'gadgets'.

http://code.google.com/apis/spreadsheets/overview.html

http://code.google.com/apis/spreadsheets/docs/2.0/reference.html

http://code.google.com/apis/spreadsheets/spreadsheet_gadgets.html

I really like this approach as I think it would allow people to contribute easily on the front-end using a familiar approach (spreadsheets) while also allowing us automated access and display/report capabilities on the back-end. Might also allow us to bypass relational databases/sqlite altogether in regards to diverse but relatively low-volume metadata with the focus being on finding spreadsheet content layouts and visualizations/reports that are commonly useful.

# Potential spreadsheets #

  * service,format,application registries
  * observing capacity resource inventory/mapping
  * cruise, point-of-opportunity shared resource scheduling
  * instrumentation maintenance/tracking, reports
  * qc,monitoring reports

# Links #

Spreadsheet importing
  * http://docs.google.com/support/bin/answer.py?answer=75507
  * http://googlesystem.blogspot.com/2007/09/google-spreadsheets-lets-you-import.html

Spreadsheet functions(cell formulas)
  * http://docs.google.com/support/bin/answer.py?hl=en&answer=82712

Spreadsheet mapper - create kml displays via spreadsheet template
http://earth.google.com/outreach/tutorial_mapper.html

Simple example of retrieving JSON feeds from Spreadsheets Data API
http://code.google.com/apis/gdata/samples/spreadsheet_sample.html

Change contents of a cell
http://code.google.com/apis/spreadsheets/docs/2.0/developers_guide_protocol.html#UpdatingCells

Return CSV of sheet/gid
http://spreadsheets.google.com/pub?key=rtrdkWtsIxB5VQZ-f_F2Idw&output=csv&gid=1

  * For Google chrome prefix 'view-source:' to URL to see XML tags
  * Firefox and IE also present a very nice interface to the below ATOM formatted row responses

Return sheet/update time info
http://spreadsheets.google.com/feeds/worksheets/rtrdkWtsIxB5VQZ-f_F2Idw/public/values

Spreadsheet SQL-type query
http://spreadsheets.google.com/feeds/list/rtrdkWtsIxB5VQZ-f_F2Idw/od7/public/values?sq=id=CAP2

Google Map webpage embedding
http://www.askdavetaylor.com/how_to_embed_google_map_on_web_page.html

Google Apps scripting
http://googleenterprise.blogspot.com/2009/05/old-tool-new-tricks.html

Google Squared
http://radar.oreilly.com/2009/06/google-squared-is-an-exponenti.html

Google Forms (choose the 'form' option for an existing spreadsheet)<br />



wiki:video: cannot find YouTube video id within parameter "url".



## Troubleshooting ##

Google spreadsheets may become **slow** for imports from Excel spreadsheets(strange cell values), color coding, empty columns, browser issues, etc
http://www.mail-archive.com/chromium-bugs@googlegroups.com/msg53650.html

# examples #

## spreadsheet design ##

see
  * location [Well-Known Text(WKT)](http://en.wikipedia.org/wiki/Well-known_text)
  * time [ISO8601](http://en.wikipedia.org/wiki/ISO_8601)

conventions
  * spreadsheet name should include templateName\_versionNumber like 'SecooraSensorInventory\_v1.0'
  * column header names use no whitespace, camelCase convention

  * the **notes** sheet is special in the the only field descriptions are id and value which can be utilized more programmatically or free-form notes anywhere in the 3rd column or greater.  The 'templateURL' points to additional information regarding the template design/conventions, registries of other same formatted templates or scripts/links which style the template into other maps, reports or products
  * the **type** sheet is special in that the only field description is **id** and the number of row elements varies depending on the possible type values for a given id

  * field/column names are strings or numbers unless field name suffixed by
    * **Type** - indicates a Type lookup value which should be one of the associated row values on the 'type' sheet
    * **Id,TypeId** - indicates a row Id lookup value which should be on the associated Id sheet list
    * stated another way, a **Type** has a single possible value lookup while an **Id,TypeId** might have several row associated values
  * sheets suffixed **Type** correspond to row id associated **TypeId** references from other sheets (like sensor.sensorTypeId references sensorType.id)

  * if **Date** is used as a fieldname suffix, it implies a YYYY-MM-DD formatted day
  * if **Time** is used as a fieldname suffix, it implies an ISO8601 formatted datetime
  * if **List** is used as a fieldname suffix, it implies a comma separated list
  * if **TypeList** is used as a fieldname suffix, it implies a comma separated list of types from the associated 'type' sheet row

  * common sheet fields
    * **id**
      * required as first column on each sheet
      * id's must be unique within each sheet
      * may be autonumbered or string

  * **URL** - URL link to further webpage info/links
  * **description** - free-form verbiage description

  * **longitude** - decimal degrees East
  * **latitude** - decimal degrees North
  * **locationWKT** - Well-Known Text(WKT) representation of points and/or lines and/or polygons using decimal degrees and meters height(+)/depth(-) to mean sea level(MSL)
    * Bounding Box as lower-left, upper-right coordinates also acceptable, e.g. BBOX(-81,32,-77,35)
  * **locationDescription** - free-form verbiage describing location

  * **timeSpanList** - list of ISO8601 ranges like '2009-02-01T14:00:00Z/2009-02-02T14:00:00Z,2009-03-01T14:00:00Z/2009-03-02T14:00:00Z'
    * if seasonally repeating will accept 'XXXX' for the year like 'XXXX-02-01T14:00:00Z/XXXX-03-01T14:00:00Z' denoting a repeat span every February
  * **timeStart** - ISO8601 formatted time, like '2009-02-01T14:00:00Z'
  * **timeEnd** - ISO8601 formatted time, like '2009-02-01T14:00:00Z'

  * spreadsheet may be extended by additional sheets or fields and be template compliant as long as no sheets or fields are removed
  * _spreadsheet column color guide (required, optional) ?_


---

## SecooraSpreadsheetRegistry ##

This spreadsheet contains the key id's to other spreadsheets and their associated spreadsheetType and OrganizationType

Registry http://spreadsheets.google.com/pub?key=rZGUM4s620-UQ_OQ1AI6R_g


---

## SecooraSensorInventory\_v1.0 ##

Captures basic metadata regarding organization, platformList, sensorList, sensorTypes with linkages to further custom spreadsheets via MetadataId field

Blank template http://spreadsheets.google.com/pub?key=re-OoRQa_Xsr6k5mgzZlMLA

Partially populated examples
  * http://spreadsheets.google.com/pub?key=rtrdkWtsIxB5VQZ-f_F2Idw&gid=1
  * http://spreadsheets.google.com/pub?key=ryTSVxKd0ZEz2UbsmFiYZLA


---

## Scripts SI ##

http://carocoops.org/spreadsheet/

description of existing scripts([source svn](http://code.google.com/p/xenia/source/browse/#svn/trunk/sqlite/spreadsheet)) from http://carocoops.org/spreadsheet/readme.txt

Note that the script sheet\_to\_db.pl and refresh\_sheet.pl could be reused to create/refresh a sql database from other spreadsheet templates also.

The local database created in the below scripts is a sqlite file-database which acts as a SQL accessible, local cache of metadata/data for further maps/reports/products.
```
convert_sheet_si.pl

#this script converts a combined org/platform spreadsheet into two separate
#TSV spreadsheets org, platform with the correct field mappings for load/import
#by the google spreadsheet SecooraSensorInventory_v1.0

sheet_to_db.pl

#this script creates the necessary initial database table structure based on the
#header lines of the associated spreadsheet file referenced

refresh_sheet.pl

#this script populates/refreshes the local sqlite database with the
#latest google spreadsheet values.  Spreadsheets are located via the google
#spreadsheet registry file.

create_kml_si.pl

#this script reads the local si.db sqlite database and creates kml/kmz output
#files
```



---


Platforms KMZ file http://carocoops.org/spreadsheet/si.kmz
  * Google Maps http://maps.google.com/?q=http://carocoops.org/spreadsheet/si.kmz
  * note that the above kmz file is best viewed in Google Earth as Google Maps does not support the [visibility](http://code.google.com/p/kml-samples/issues/detail?id=1) tag at this time, causing all the placemarks to be displayed on the initial load of the file

### To Do ###
  * KML/KMZ maps
    * add observationType to platform descriptions
    * provide separate kmz layers by observationType
    * provide separate kmz layers styled by online/offline similar to NDBC status map
    * provide separate kmz layer denoting longer-term operational/funding issues/concerns
    * provide cruise/operations map

  * spreadsheet
    * track/check sheet update time to only load/update changed sheets
    * provide perl example of automated 'PUT' to change row/cell contents
    * cross-populate xenia rdb schema from spreadsheet

### Issues ###

  * switched to TSV(Tab Separated Value) related file import as CSV(Comma Separated Value) became difficult to process relating to commas within quotes type field issues(mainly in regards to sqlite .import)
  * Google spreadsheets
    * requires space character ' ' instead of null on importData function to successfully parse empty fields/cells.
    * includes footnotes within cells and formulas at the page bottom for CSV output which I filter out using regular expressions
    * does not include ending commas or null fields on empty cell values at the end of rows, making it difficult to automatically process nulls forward - get around this for now by checking the number of fields in the header line
    * updates the publish [update](http://spreadsheets.google.com/feeds/worksheets/ryTSVxKd0ZEz2UbsmFiYZLA/public/values) time for the entire spreadsheet on a single sheet cell change - would like it better if just the timestamp of the effected sheet were changed which would allow sheet specific upload/changes of metadata/data.  If sheet specific update was available, then perhaps a **latest data** sheet might also be a simple spreadsheet way of sharing latest in-situ data.
    * sq does not include 'like' function, meaning that all queries must fully(not partially) match the field content
  * Google maps
    * kml/kmz file is best viewed in Google Earth as Google Maps does not support the [visibility](http://code.google.com/p/kml-samples/issues/detail?id=1) tag at this time, causing all the placemarks to be displayed on the initial load of the file
    * Placemark listing order is random ( http://code.google.com/p/kml-samples/issues/detail?id=235 http://code.google.com/p/kml-samples/issues/detail?id=268 )


---

### Data Provider Steps ###

To have your metadata/data included with the current Secoora sensor inventory and presented in associated reports/maps, perform the following steps.

#### Using Google ####

##### Copy Spreadsheet Template #####

While logged into your own [Google account](http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=27441), make a copy of the blank template using the below link

http://spreadsheets.google.com/ccc?key=re-OoRQa_Xsr6k5mgzZlMLA&newcopy

##### Populate Spreadsheet #####

Rename the spreadsheet, removing the 'Copy of' and replacing 'Template' with your organization id (like 'carocoops').

Populate the spreadsheet similar to [this example](http://spreadsheets.google.com/pub?key=rtrdkWtsIxB5VQZ-f_F2Idw&gid=1), the main fields utilized at this time are:

  * organization
    * id
    * institution
  * platform
    * id
    * organizationId
    * URL
    * description
    * longitude
    * latitude
    * reportType

##### Publish Spreadsheet #####

At the top right page of the spreadsheet choose the **Share->Publish as a web page**

On the 'Publish as a web page' pop-up window choose **Publish Now**

On the refreshed **Publish as a web page** pop-up window choose **Automatically re-publish when changes are made** and **Re-publish document**, closing the pop-up when finished.

##### Notify staff #####

Send an email to jeremy.cothran [at](at.md) gmail.com with the spreadsheet key(the string hash in the browser address next to **key=**) which you would like included as part of the spreadsheet registry and associated products.  You should receive notification that your spreadsheet was successfully included or any issues related to upload.

#### Using internal TSV(Tab Separated Value) files ####

The steps are similar to the steps above for using Google spreadsheets for sharing metadata/data, except that the data provider is sharing an internally HTTP hosted set of TSV (Tab Separated Value) files that mimic the spreadsheet layout.

For example
  * organization http://carocoops.org/spreadsheet/si_organization.tsv
  * platform http://carocoops.org/spreadsheet/si_platform.tsv

Note that empty fields have a **space character ' '** and are not null.

Notify staff similarly regarding the URL's of the TSV files for access/collection.

These TSV files are imported on the collection end via a centrally hosted template-based google spreadsheet using the **importData(URL)** cell [function](http://docs.google.com/support/bin/answer.py?answer=75507).  Note that this google spreadsheet 'wrapper' provides [google data API functionality](http://code.google.com/apis/spreadsheets/overview.html) to the underlying source TSV file.


---

## SecooraServiceInventory\_v1.0 ##

Captures basic metadata regarding
  * organization
  * services and formats types
  * applications and website links

Blank template http://spreadsheets.google.com/pub?key=rK30gum7jSX4uFJktCozRmQ&gid=11


---

## SecooraMembers\_v1.0 ##

Captures basic metadata regarding
  * Secoora membership,status and location

Example http://spreadsheets.google.com/pub?key=rUevo3Uxo4Uyip3hLKWeA0Q

Styled Google Map http://maps.google.com/?q=http://carocoops.org/spreadsheet/sm.kmz

---


## Simple alert/process script control via spreadsheet ##

Trying the following to do some simple instrumentation email alert control and log some basic maintenance info as well.

Created the public google spreadsheet at

http://spreadsheets.google.com/pub?key=rmo6mOkVVsEN7fLqwN_7Qsg&gid=0

This spreadsheet just has two sheets - the 'instrument' sheet and 'maintenance' sheet

On the 'instrument' sheet I'm having my code look at the line with 'hfradar\_savannah' at the 'alertEnabled' column to determine (yes or no) whether the alerts are enabled or not.  I've gone ahead and set it to 'no' for now and added a short line on the 'maintenance' sheet that could be used to add rows as the equipment is disabled/re-enabled.

I would add the instrumentation staff google account(s) to the spreadsheet permissions so that they could edit the spreadsheet alert field to control the emails and leave maintenance notes.

I can get a CSV dump of the sheets using the following commands

#instrument (gid=0)

http://spreadsheets.google.com/pub?key=rmo6mOkVVsEN7fLqwN_7Qsg&single=true&gid=0&output=csv

#maintenance (gid=1)

http://spreadsheets.google.com/pub?key=rmo6mOkVVsEN7fLqwN_7Qsg&single=true&gid=1&output=csv

The google spreadsheets data/web API's allow me to plug my scripts in to automatically process/incorporate them with my data processing flows.

Could also add additional status fields to describe the status of the instrumentation as it should be reflected to various feeds/services.

```
use LWP::Simple;

#CONFIG BEGIN
my $sheet_key = 'rmo6mOkVVsEN7fLqwN_7Qsg';
#CONFIG END

#get sheet from registry
my $sheet_url = "http://spreadsheets.google.com/pub?key=$sheet_key&output=csv&gid=0";
my $retval = getstore($sheet_url,"./sheet.csv");
die "Couldn't get $sheet_url" unless defined $retval;

open (FILE,"./sheet.csv");

my $row_count = 0;
my $flag_alert = 'no';
foreach my $row (<FILE>) {
        $row_count++;

        #print $row;
        my @element = (split(',',$row));
        if ($element[0] eq 'hfradar_savannah') {
                if ($element[1] eq 'yes') { $flag_alert = 'yes'; }
                last;
        }
}

close (FILE);

if ($flag_alert eq 'yes') { print "flag_alert_yes\n"; } else { exit 0; }

#rest of alert code proceeds here if alert set to 'yes'
```

---

# google maps, javascript #

http://econym.org.uk/gmap/

## TimeMap ##
TimeMap includes a scrollable timeslider element to google maps that changes the placemarks according to the time window.

http://googlegeodevelopers.blogspot.com/2009/01/timemap-helping-you-add-4th-dimension.html

## MarkerCluster ##
MarkerCluster pools a large number(hundreds) of placemarks into single cluster which can be expanded to improve map performance.

http://googlegeodevelopers.blogspot.com/2009/04/markerclusterer-solution-to-too-many.html

## Jquery ##
Jquery is an open javascript library which simplifies javascript development including cross-browser compatibility

http://googlegeodevelopers.blogspot.com/2009/04/new-articles-jquery-heat-maps-multi.html

## real-time boat tracking ##

Sharing the following **experimental** technical browser/javascript/JSON based application link from Paul Reuter working with SCCOOS.

It shows live boat tracking via an AIS message stream(click the 'start streaming' button below the map).

http://cordc.ucsd.edu/projects/ais/

Jeremy

From Paul's email:

One more really nice thing about JSON is it's intrinsic web-based push capability.  Seen here, http://app.lightstreamer.com/GridDemo/ is an example of using an embedded iframe and inline scripting to execute a function upon receiving real-time data.  Their API is a bit more complex, but the results are a scalable, high-volume, high-connectivity application with bandwidth throttling and real-time push/pull capability.  From the Web Developer Toolbar -> View Javascript.

I personally use an iframe+inline scripting for updating real-time AIS tracks on Google Maps.  If I had parsed my data on the server, I would create JSON objects, rather than provide the raw data as a means of reducing the client-side load.  See: http://cordc.ucsd.edu/projects/ais/  (click the start streaming button).  The AIS feed is about 15 messages per second, and incurs a fair amount of client-side scripting - be forewarned.

Just throwing that out there, in case anyone hasn't seen a real-time web app yet.

Paul

## HF radar ##

National coastal HF(high-frequency) radar displayed via google maps, javascript

http://hfradar.ndbc.noaa.gov