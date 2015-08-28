

We can attempt to cross-display others links to data or data maps or observations within our system catalogs or displays as our personnel time, and server/storage capacity allow.  Internally in the past we have focused mostly on near real-time observation data feeds, but can cross-reference other map points and displays as able.

We recommend coastal/ocean in-situ data providers that will have near real-time observations registering their wind and water ongoing for a year or more to register their platforms with [NDBC](http://www.ndbc.noaa.gov/) - or let us know if they want us to proxy/forward their data feed to NDBC for them.

Similarly for data archives, we recommend archive agreements with [NODC](http://www.nodc.noaa.gov/) for long-term data storage and sharing - or let us know if we should act as a proxy/forward for their data to NODC.


---

# Placemark links(URL'S) #

  * notice as to nature of links(URL's) are to
    * near real-time(past 24 hours)
    * delayed-mode
    * archival data
    * model data
  * organization
    * long name and short name - e.g. Florida Institute of Technology (long name) or FIT(short name)
    * URL link
    * (optional) - description(1000 char max)
    * (optional) - data dessimination/credit description(1000 char)
    * (optional) - data disclaimer description(1000 char)
  * location id/name(s - short format(50 char)) - e.g. cap2,sebastian,niwolmet
    * location(s) longitude/latitude
  * preferred format for sending this link mapping data is as a CSV or shapefile
  * notice as to observation types - water temperature,wind,etc


---

# Simple In-situ data #

  * organization
    * long name and short name - e.g. Florida Institute of Technology (long name) or FIT(short name)
    * URL link
    * (optional) - description(1000 char max)
    * (optional) - data dessimination/credit description(1000 char)
    * (optional) - data disclaimer description(1000 char)
  * platform id/name(s - short format(50 char)) - e.g. cap2,sebastian,niwolmet
    * platform(s) longitude/latitude
  * Size and format of files to be shared and frequency of update
    * timestamp information should be included with each observation or set of observations
  * HTTP folder location from which to get the most recent files - this folder should only hold the past few days worth of files to prevent a large number of files being scanned - older files can be moved to an older or julian day/week or month/year dated sub-folders
  * notice as to observation types - water temperature,wind,etc


---

# Imagery data #

We do not permanently archive imagery data, but we can cross-display map imagery for a limited time window and associated data/bandwidth size.  Imagery data is assumed to cover a simple longitude/latitude bounding box area with default projection of EPSG:4326

  * organization
    * long name and short name - e.g. Florida Institute of Technology (long name) or FIT(short name)
    * URL link
    * (optional) - description(1000 char max)
    * (optional) - data dessimination/credit description(1000 char)
    * (optional) - data disclaimer description(1000 char)
  * data/layer long name and short name - e.g. sea\_surface\_temperature (long name) or sst(short name)
  * data/layer description(1000 char)
  * Size of files to be shared and frequency of update
  * HTTP folder location from which to get the most recent files - this folder should only hold the past few days worth of files to prevent a large number of files being scanned - older files can be moved to an older or julian day/week or month/year dated sub-folders
  * image timestamp information(variablename\_YYYY\_MM\_DD\_HH\_MM\_SS.png) should be suffixed in the filename, suchas sst\_2011\_05\_14\_13\_00\_00.png
  * metadata associated with the image should be available in a projection.txt file or sent via email - such as the lat/long bounding box for the image and associated projection if not default EPSG:4326
  * legend information for the image should be provided in a separate legend.png file


---

# Model data #

The recommended method for sharing gridded model data is via a netCDF format, catalog enabled via [THREDDS](http://www.unidata.ucar.edu/projects/THREDDS/) and map visualization enabled via [ncWMS](http://www.resc.rdg.ac.uk/trac/ncWMS/)

Sample associated organization and model metadata and links, thumbnails are listed below(maximum number of characters in parenthesis) - one row for each data variable/layer and can be seen in the model inventory webpage at http://secoora.org/models/

| **field(max length)** | **example value** |
|:----------------------|:------------------|
| title(200)            | SABGOM            |
| institute(200)        | North Carolina State University (NCSU) |
| variable(200)         | sea\_surface\_temperature |
| variable\_aliases(200) | water\_temperature temp |
| abstract(1000)        | This quasi-operational model was implemented based on the Regional Ocean Modeling System (ROMS), a new community ocean circulation model that is in widespread use for estuarine, shelf, and coastal applications. |
| extent\_geographic(200) | South Atlantic Bight, Gulf of Mexico |
| extent\_temporal(200) |                   |
| url\_thumbnail(1024)  | thumb/ncsu\_sabgom/sea\_surface\_temperature.jpg |
| url\_details(1024)    |                   |
| url\_legend(1024)     | http://omglnx1.meas.ncsu.edu/thredds/wms/fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best.ncd?EXCEPTIONS=application/vnd.ogc.se_xml&FORMAT=image/gif&TRANSPARENT=true&VERSION=1.1.1&SERVICE=WMS&REQUEST=GetLegendGraphic&CRS=EPSG:4326&LAYER=temp |
| url\_getdata(1024)    | http://omglnx1.meas.ncsu.edu/thredds/catalog/fmrc/sabgom/catalog.html?dataset=fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best.ncd |
| wms\_base(1024)       | http://omglnx1.meas.ncsu.edu/thredds/catalog/fmrc/sabgom/catalog.html?dataset=fmrc/sabgom/SABGOM_Forecast_Model_Run_Collection_best.ncd |
| wms\_layers(1024)     | temp              |

