


---

# Navigation from website #

The below [circled links](http://secoora.org) are the navigation points of interest for model data.

  * Explore Real-Time Data(Interactive map)
  * THREDDS server
  * ncWMS/Godiva viewer
  * Data Download

<img src='http://xenia.googlecode.com/files/model3.jpg' />


---

# Interactive map #

The [interactive map](http://secoora.org/maps) displays model output for the current hour and provides controls(the 'I' button next to the layer name) for changing the datetime of the layer displayed.

In addition to Secoora regional models, other global model forecast layers(at lower spatial resolution) are included also(via a THREDDS server at PacIOOS) for waves(WaveWatch), water(NCOM) and air(NCEP).

See also this [video tutorial](http://www.youtube.com/watch?v=N-eOz58mA-c) on using the interactive map with model outputs.

<img src='http://xenia.googlecode.com/files/model4.jpg' />


---

# THREDDS server - catalog reference #

[Model data](http://129.252.139.124/thredds/catalog_models.html) is currently available via [THREDDS](http://www.unidata.ucar.edu/projects/THREDDS/) servers set up at each of the below listed institutions.

The NCSU/MEAS and USF groups both run similar ROMS model circulation outputs for variables such temperature, salinity, elevation and surface currents although covering different locations and resolution.

UF forecasts for 4 near-coastal areas for Florida providing elevation/storm-surge related data.

NCSU/CFDL forecasts a storm-surge model for the SECOORA region.

<img src='http://xenia.googlecode.com/files/model5.jpg' />


---

# ncWMS #

[ncWMS](http://www.resc.rdg.ac.uk/trac/ncWMS/) is stand-alone software of the 'Godiva' functionality of THREDDS allowing WMS(Web Mapping Service) requests.  It allows for vector-styling and map image caching of THREDDS WMS requests.  Currently this is used as middleware between the interactive map and the remote model thredds servers.

[SECOORA ncWMS](http://129.252.139.124/ncWMS/godiva2.html)

See also this [video tutorial](http://www.youtube.com/watch?v=S5Dkp8PG0nM) on using ncWMS/Godiva.

See also this [video tutorial](http://www.youtube.com/watch?v=_nNpRwtFHX4) on using the online Unidata CDM/CF validator tool and configuring ncWMS.

<img src='http://xenia.googlecode.com/files/model6.jpg' />


---

# automatic checks and notification #

Automated THREDDS/WMS [requests](http://neptune.baruch.sc.edu/xenia/misc/link_check.html) are made hourly to check if the model outputs are still available.  A datetime history of request success(Y)/fail(n) is kept.

<img src='http://xenia.googlecode.com/files/model7.jpg' />


---

# Shapefile and GIS downloads #

For NCSU/MEAS, hourly forecast shapefiles are produced for several depths and made available for general download via website.  Shapefiles for USF are produced similarly for surface and bottom layers.

Further development notes and source code are available [here](http://code.google.com/p/xenia/wiki/ROMSprocessing)

<img src='http://xenia.googlecode.com/files/model1.jpg' />

[Zipped shapefiles](http://neptune.baruch.sc.edu/xenia/model_shapefiles/) for download generated daily with filenames by forecast date, depth

<img src='http://xenia.googlecode.com/files/model2.jpg' />