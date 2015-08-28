developed from discussions with working group http://groups.google.com/group/ioos-kml

see also [geojson](http://geojson.org/geojson-spec.html) <br />
[json schema](http://json-schema.org) <br />
[json schema discussion](http://nico.vahlas.eu/2010/04/23/json-schema-specifying-and-validating-json-data-structures/) <br />
[NDBC implementation(see SOS KML/JSON output)](http://sdf.ndbc.noaa.gov/sos/) <br />


see also [latest 12 hours from platforms as ObsJSON](http://carocoops.org/obsjson/feeds/all/latest_hours_12), note the function and smooth brackets wrapping the GeoJSON are utilized to support the dynamic Javascript callback functionality for KML in GE version 5.

see also [xenia to json perl script](http://code.google.com/p/xenia/source/browse/trunk/sqlite/json/xenia_sqlite_to_json.pl)

developed from earlier documentation regarding [ObsJSON](http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/ObsKML#Simple_schema_JSON_Alternate_1_O) and [ObsKML](http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/ObsKML)

[Version 2](http://code.google.com/p/xenia/wiki/ObsJSON#Simple_schema_version_2) is the preferred working version at this time.



# Simple schema #

Below example is more flat/array oriented like netCDF,CSV and could support moving platforms(ships,gliders) as well as stationary ones.

  * elevRel is the 'relative elevation' in meters height(+) or depth(-) from the given GeoJSON z coordinate(s) with zero z coordinate corresponding to mean sea level(MSL).
  * The ordering of effected list arguments is in time increasing order(oldest first, latest last) allowing picking off the latest value be grabbing the last associated set of time/values off the list.
  * Stationary platforms would use GeoJSON 'Point' type and mobile platforms would use 'MultiPoint' type.  Multipoint coordinates are paired with listed time values.
  * (optional) Observation listing order is preferred to be from highest elevation/altitude to lowest elevation/depth.
  * (optional) Redundant sensors/observations would be listed in their order of importance (primary, secondary, etc) or depth(highest to lowest elevation).

```
{
    "type": "Feature",
    "geometry": {
        "type": "MultiPoint",
        "coordinates": [[-80.55,30.04,0],[-79.00,31.00,0],[-78.00,32.00,0]] 
    },
    "properties": {
        "schemaRef": "ioos blessed schema name reference",
        "dictionaryRef": "ioos blessed obstype uom dictionary reference",
        "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",
        "metadataURL": "a link to further operator/platform metadata as GeoJSON"
        "operatorName": "ndbc",
        "operatorURL": "http://www.ndbc.noaa.gov/",
        "platformName": "41012",
        "platformURL": "http://www.ndbc.noaa.gov/station_page.php?station=41012",
        "platformId": "urn:x-noaa:def:station:noaa.nws.ndbc::41012",
   
        "time": ["2009-03-31T10:50:00Z","2009-03-31T11:50:00Z","2009-03-31T12:50:00Z"],

        "obsList": [
            {
                "obsType": "air_temperature",
                "uomType": "celsius",
                "valueList": ["22.0","23.0","24.0"],
                "elevRel": "3" 
            },
            {
                "obsType": "water_temperature",
                "uomType": "celsius",
                "valueList": ["17.0","18.0","19.0"],
                "elevRel": "-1" 
            } 
        ] 
    } 
} 
```

# embedded in KML as atom:link #

Could also use the KML TimeSpan tag below as well (especially if only referencing TimeSpan files only)

```
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.1">
<Document>
  <name>ObsJSON example</name>
  <open>1</open>
  <Placemark id="ndbc.41024.buoy">
    <name>ndbc.41024.buoy</name>
    <description>An html table derived from the ObsJSON would be displayed here</description>
    <Point>
      <coordinates>-77.0,32.0,0</coordinates>
    </Point>
    <TimeStamp><when>2009-03-14T16:00Z</when></TimeStamp>

    <ExtendedData>

   <!-- GeoJSON related link(latest obs) -->
   <atom:link type="application/json"
    href="http://myurl/feeds/ndbc/latest/ndbc.41024.buoy.json" />

   <!-- GeoJSON related link (latest obs - past 48 hours -->
   <atom:link type="application/json"
    href="http://myurl/feeds/ndbc/latest_hours_48/ndbc.41024.buoy.json" />

    </ExtendedData>

  </Placemark>
</Document>
</kml>
```

# embedded in Atom #

A simple Atom example using just JSON links, in this scenario each entry could reference the available platforms from a given provider.

```
...
<entry>
   <id>latest/ndbc.41024.buoy.json</id>
   <title>ndbc.41024.buoy</title>
   <updated>2009-03-14T16:00:00Z</updated>
   <georss:where>
     <gml:Point><gml:pos>-77 32</gml:pos></gml:Point>
   </georss:where>

   <!-- GeoJSON related link -->
   <link type="application/json"
    href="http://myurl/feeds/ndbc/latest/ndbc.41024.buoy.json" />
</entry>

<entry>
   <id>latest_hours_48/ndbc.41024.buoy.json</id>
   <title>ndbc.41024.buoy</title>
   <updated>2009-03-14T16:00:00Z</updated>
   <georss:where>
     <gml:Point><gml:pos>-77 32</gml:pos></gml:Point>
   </georss:where>

   <!-- GeoJSON related link -->
   <link type="application/json"
    href="http://myurl/feeds/ndbc/latest_hours_48/ndbc.41024.buoy.json" />
</entry>
...
```

Used the following links for examples <br>
<a href='http://sgillies.net/blog/883/sensible-observation-services'>http://sgillies.net/blog/883/sensible-observation-services</a> <br>
<a href='http://www.youtube.com/watch?v=T04fKsD56LU'>http://www.youtube.com/watch?v=T04fKsD56LU</a>

<hr />
<h1>Simple schema version 2</h1>

Below is another revision to the initial ObsJSON schema, which treats each platform sensor as a feature with associated geometries,properties and utilizing list association between geometry/time/value per feature/sensor.<br>
<br>
<ul><li>Geometry z coordinate is relative to mean sea level(MSL) with height(+) or depth(-) in meters.<br>
</li><li>The ordering of effected list arguments is in time increasing order(oldest first, latest last) allowing picking off the latest value be grabbing the last associated set of time/values off the list.<br>
</li><li>Stationary platforms would use GeoJSON 'Point' type and mobile platforms would use 'MultiPoint' type.  MultiPoint coordinates are paired with listed time values.<br>
</li><li>(optional ?) All fields under 'FeatureCollection' are optional except platformId.  Think the other fields give some more self-contained minimal context,usage but all these could be linked in some way via the platformId reference.<br>
</li><li>(optional ?) sensorId is optional but would provide a means of association for related time-series or sensor metadata.<br>
<pre><code>{<br>
    "type": "FeatureCollection",<br>
    "schemaRef": "ioos blessed schema name reference(s)",<br>
    "dictionaryRef": "ioos blessed obstype uom dictionary reference(s)",<br>
    "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",<br>
    "platformId": "urn:x-noaa:def:station:noaa.nws.ndbc::41012",<br>
    "metadataURL": "link to further operator/platform metadata/links as XML/JSON",<br>
    "operatorName": "ndbc",<br>
    "operatorURL": "http://www.ndbc.noaa.gov/",<br>
    "platformName": "41012",<br>
    "platformURL": "http://www.ndbc.noaa.gov/station_page.php?station=41012",<br>
    "features": [<br>
        {<br>
            "type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.55,30.04,3],[-79.00,31.00,3],[-78.00,32.00,3]] <br>
            },<br>
            "properties": {<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "air_temperature",<br>
                "uomType": "celsius",<br>
                "time": ["2009-03-31T10:50:00Z","2009-03-31T11:50:00Z","2009-03-31T12:50:00Z"],<br>
                "value": ["22.0","23.0","24.0"] <br>
            } <br>
        },<br>
        {<br>
            "type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.55,30.04,-1],[-79.00,31.00,-1],[-78.00,32.00,-1]] <br>
            },<br>
            "properties": {<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "water_temperature",<br>
                "uomType": "celsius",<br>
                "time": ["2009-03-31T10:50:00Z","2009-03-31T11:50:00Z","2009-03-31T12:50:00Z"],<br>
                "value": ["17.0","18.0","19.0"] <br>
            } <br>
        } <br>
    ] <br>
}<br>
</code></pre></li></ul>

<h2>Potential issues</h2>

<ul><li>Traditional request/response approaches are single-obs centric(give me just water_temperature for platform/area) rather than platform/sensor-centric(give me everything for a given platform)<br>
</li><li>How good/complete are request/response from SOS,ERDDAP,etc for 'all' recent platform data?<br>
</li><li>How would KML/javascript styling support possible JSON/GeoJSON</li></ul>

<h1>Simple schema version 3</h1>

The below schema is flattened as much as possible, dropping the GeoJSON nesting/list and time/value list.  Would be very similar schema-wise to <a href='http://www.ogcnetwork.net/node/189'>WFS Simple GetFeature</a> (thanks Raj Singh for the reminder/link regarding WFS Simple) or the earlier example ERDDAP GeoJSON response(thanks Roy Mendelssohn) below.<br>
<br>
<pre><code>{<br>
    "type": "FeatureCollection",<br>
    "schemaRef": "ioos blessed schema name reference(s)",<br>
    "dictionaryRef": "ioos blessed obstype uom dictionary reference(s)",<br>
    "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",<br>
    "platformId": "urn:x-noaa:def:station:noaa.nws.ndbc::41012",<br>
    "metadataURL": "link to further operator/platform metadata/links as XML/JSON",<br>
    "operatorName": "ndbc",<br>
    "operatorURL": "http://www.ndbc.noaa.gov/",<br>
    "platformName": "41012",<br>
    "platformURL": "http://www.ndbc.noaa.gov/station_page.php?station=41012",<br>
    "features": [<br>
        {<br>
            "type": "Feature",<br>
            "properties": {<br>
                "latitude": "-80.55",<br>
                "longitude": "30.04",<br>
                "elevation": "3",<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "air_temperature",<br>
                "uomType": "celsius",<br>
                "time": "2009-03-31T10:50:00Z",<br>
                "value": "22.0" <br>
            } <br>
        },<br>
       {<br>
            "type": "Feature",<br>
            "properties": {<br>
                "latitude": "-80.55",<br>
                "longitude": "30.04",<br>
                "elevation": "3",<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "air_temperature",<br>
                "uomType": "celsius",<br>
                "time": "2009-03-31T11:50:00Z",<br>
                "value": "23.0" <br>
            } <br>
        },        <br>
       {<br>
            "type": "Feature",<br>
            "properties": {<br>
                "latitude": "-80.55",<br>
                "longitude": "30.04",<br>
                "elevation": "-1",<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "water_temperature",<br>
                "uomType": "celsius",<br>
                "time": "2009-03-31T10:50:00Z",<br>
                "value": "17.0" <br>
            } <br>
        }, <br>
       {<br>
            "type": "Feature",<br>
            "properties": {<br>
                "latitude": "-80.55",<br>
                "longitude": "30.04",<br>
                "elevation": "-1",<br>
                "sensorId": "link to further sensor metadata/links as XML/JSON",<br>
                "obsType": "water_temperature",<br>
                "uomType": "celsius",<br>
                "time": "2009-03-31T11:50:00Z",<br>
                "value": "18.0" <br>
            } <br>
        }              <br>
    ] <br>
}<br>
</code></pre>

<h1>example ERDDAP GeoJSON response</h1>

response below to request<br>
<br>
<a href='http://coastwatch.pfeg.noaa.gov/erddap/tabledap/ndbcSosWTemp.geoJson?longitude,latitude,station_id,altitude,time,WaterTemperature&longitude%3E=-130&longitude%3C=-110&latitude%3E=30&latitude%3C=39&time%3E=2009-04-03T00:00:00Z'>http://coastwatch.pfeg.noaa.gov/erddap/tabledap/ndbcSosWTemp.geoJson?longitude,latitude,station_id,altitude,time,WaterTemperature&amp;longitude%3E=-130&amp;longitude%3C=-110&amp;latitude%3E=30&amp;latitude%3C=39&amp;time%3E=2009-04-03T00:00:00Z</a>

This bounding box request might include several platforms data, requiring the station_id with each observation feature.<br>
<br>
<pre><code>{<br>
  "type": "FeatureCollection",<br>
  "propertyNames": ["station_id", "altitude", "time", "WaterTemperature"],<br>
  "propertyUnits": [null, "m", "UTC", "degrees_C"],<br>
  "bbox": [-130.0, 33.74, -119.06, 38.23],<br>
  "features": [<br>
<br>
{"type": "Feature",<br>
  "geometry": {<br>
    "type": "Point",<br>
    "coordinates": [-123.32, 38.23] },<br>
  "properties": {<br>
    "station_id": "urn:x-noaa:def:station:noaa.nws.ndbc::46013",<br>
    "altitude": null,<br>
    "time": "2009-04-03T10:50:00Z",<br>
    "WaterTemperature": 10.6 }<br>
},<br>
{"type": "Feature",<br>
  "geometry": {<br>
    "type": "Point",<br>
    "coordinates": [-123.32, 38.23] },<br>
  "properties": {<br>
    "station_id": "urn:x-noaa:def:station:noaa.nws.ndbc::46013",<br>
    "altitude": null,<br>
    "time": "2009-04-03T14:50:00Z",<br>
    "WaterTemperature": 9.9 }<br>
},<br>
{"type": "Feature",<br>
  "geometry": {<br>
    "type": "Point",<br>
    "coordinates": [-120.97, 34.71] },<br>
  "properties": {<br>
    "station_id": "urn:x-noaa:def:station:noaa.nws.ndbc::46023",<br>
    "altitude": null,<br>
    "time": "2009-04-03T00:50:00Z",<br>
    "WaterTemperature": 10.5 }<br>
}<br>
]<br>
}<br>
</code></pre>

<h1>Suggestions</h1>

<h2>dictionary URI, platformType(systemType)</h2>

<hr />
suggested by Luis Bermudez<br>
<br>
1)  if we were going to make this dictionary available for  the semantic web we should have a base URI. I think, all the values you have,  will not have problems of  being part of a URI ( they have no spaces etc ..).<br>
<br>
Could you define a base URI ? It could be for example:<br>
<br>
<a href='http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json'>http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json</a>

I know  expressing the URI may appear unnecessary, but if we have this file in another location (e.g. locally), it will help us going back to it and will be easier to creating an RDF from it.<br>
<br>
2) There is no platform type (which  I prefer to call it system type ). I think this is important if we want to categorize observations by source and even putting nice icons.<br>
<hr />

<i>dictionary URI example</i>

For platformType(systemType) property, the simplest initial values I'd imagine would be 'fixed' or 'mobile'.  Could reference developed lookup list from others as suggested.<br>
<br>
<br>
<br>
<h1>Demo 1</h1>
Date: April 29, 2009<br>
<br>
<h2>Links</h2>

Latest 24 hour file folder<br>
<a href='http://neptune.baruch.sc.edu/xenia/feeds/obsjson/all/latest_hours_24/'>http://neptune.baruch.sc.edu/xenia/feeds/obsjson/all/latest_hours_24/</a>

Latest 24 hour dynamic javascript styled kmz<br>
<a href='http://neptune.baruch.sc.edu/xenia/feeds/obsjson/all/latest_hours_24/all_latest.kmz'>http://neptune.baruch.sc.edu/xenia/feeds/obsjson/all/latest_hours_24/all_latest.kmz</a>


<h2>Known issues</h2>

Jeremy will address<br>
<br>
<ul><li>some platforms repeat multiple times<br>
</li><li>some wind_from_direction reporting > 360 degrees<br>
</li><li>order sensor listing to match elevation ? top to bottom?<br>
</li><li>will add 'describeSensorURL' to platform metadata JSON</li></ul>

Pete ?<br>
<br>
<ul><li>label y-value splits may have a large number of decimal places(19.000000003) - can style to 2 or 3 decimals max?<br>
</li><li>safe to show all graphs with no time axis?  need filler/blank graph values if only one or two observations in past 24 hours?  some platforms sampling more/less than once per hour.</li></ul>

<h2>Sample schema</h2>

<h1>metadata</h1>

<pre><code>{<br>
"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30]<br>
            },<br>
"properties": {<br>
    "schemaRef": "ioos_blessed_schema_name_reference",<br>
    "dictionaryRef": "ioos_blessed_obstype_uom_dictionary_reference",<br>
    "dictionaryURL": "http://nautilus.baruch.sc.edu/obsjson/secoora_dictionary.json",<br>
    "organizationName": "ndbc",<br>
    "organizationURL": "http://www.ndbc.noaa.gov",<br>
    "stationId": "urn:x-noaa:def:station:ndbc::41012",<br>
    "stationURL": "http://www.ndbc.noaa.gov/station_page.php?station=41012",<br>
    "stationTypeName": "buoy",<br>
    "stationTypeImage": "http://www.ndbc.noaa.gov/images/stations/3m.jpg",<br>
    "describeSensorURL": "TBD",<br>
<br>
    "origin":"National Data Buoy Center",<br>
    "useconst":"The information on government servers are in the public domain, unless specifically annotated otherwise, and may be used freely by the public so long as you do not 1) claim it is your own (e.g. by claiming copyright for NWS information -- see below), 2) use it in a manner that implies an endorsement or affiliation with NOAA/NWS, or 3) modify it in content and then present it as official government material. You also cannot present information of your own in a way that makes it appear to be official government information."<br>
}<br>
}<br>
</code></pre>

<h1>data</h1>

<pre><code>json_callback({<br>
"type": "FeatureCollection",<br>
    "stationId": "urn:x-noaa:def:station:ndbc::41012",<br>
    "features": [        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0]] <br>
            },<br>
         "properties": {<br>
            "obsType": "air_pressure",<br>
            "uomType": "mb",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z","2009-04-29T00:50:00Z","2009-04-29T01:50:00Z","2009-04-29T02:50:00Z","2009-04-29T03:50:00Z","2009-04-29T04:50:00Z","2009-04-29T05:50:00Z","2009-04-29T06:50:00Z","2009-04-29T07:50:00Z","2009-04-29T08:50:00Z","2009-04-29T09:50:00Z","2009-04-29T10:50:00Z","2009-04-29T11:50:00Z","2009-04-29T12:50:00Z","2009-04-29T13:50:00Z","2009-04-29T14:50:00Z","2009-04-29T15:50:00Z","2009-04-29T16:50:00Z"],<br>
            "value": ["1027.3","1026.5","1026","1025.9","1025.5","1025.3","1025.7","1025.6","1025.9","1026","1025.8","1025.7","1025","1024.6","1024.5","1024.9","1025.4","1025.9","1026.3","1026.3","1026.6","1026.2","1025.7"]<br>
        }},<br>
        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4],[-80.5,30,4]] <br>
            },<br>
         "properties": {<br>
            "obsType": "air_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z","2009-04-29T00:50:00Z","2009-04-29T01:50:00Z","2009-04-29T02:50:00Z","2009-04-29T03:50:00Z","2009-04-29T04:50:00Z","2009-04-29T05:50:00Z","2009-04-29T06:50:00Z","2009-04-29T07:50:00Z","2009-04-29T08:50:00Z","2009-04-29T09:50:00Z","2009-04-29T10:50:00Z","2009-04-29T11:50:00Z","2009-04-29T12:50:00Z","2009-04-29T13:50:00Z","2009-04-29T14:50:00Z","2009-04-29T15:50:00Z","2009-04-29T16:50:00Z"],<br>
            "value": ["23","23.2","23","23","23","22.9","22.9","22.8","22.8","22.8","22.7","22.7","22.4","22.4","22.2","22.2","22.1","22.2","22.6","22.4","22.7","23","23"]<br>
        }},<br>
...<br>
</code></pre>

<h1>Simple schema version 5</h1>

The below is the most compact form I can currently think of, using a leading 'platform' set of data which does not contain a uom or values but does provide a list of location and time points which are inherited by other sensors in the listing that do not contain a location or time list.  Each sensor could contain an 'elevation' if included that specifies the elevation above(+) or below(-) the platform location in meters.  I'm doubtful that this qualifies as GeoJSON at this point, but it should be very minimal data transfer for cases - the only other additional compression step past this that comes to mind for now would be for cases where large sets of platform data(say greater than 100 platforms requested at once), to provide id lookup tables(organization,platform,sensor types, carocoops = 12, air_temperature = 23 for example) as json and use integer id lookups within the repeated data listings instead of the full string listing.<br>
<br>
<pre><code>json_callback({<br>
"type": "FeatureCollection",<br>
    "stationId": "urn:x-noaa:def:station:ndbc::41012",<br>
    "features": [        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0],[-80.5,30,0]] <br>
            },<br>
         "properties": {<br>
            "obsType": "platform",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z","2009-04-29T00:50:00Z","2009-04-29T01:50:00Z","2009-04-29T02:50:00Z","2009-04-29T03:50:00Z","2009-04-29T04:50:00Z","2009-04-29T05:50:00Z","2009-04-29T06:50:00Z","2009-04-29T07:50:00Z","2009-04-29T08:50:00Z","2009-04-29T09:50:00Z","2009-04-29T10:50:00Z","2009-04-29T11:50:00Z","2009-04-29T12:50:00Z","2009-04-29T13:50:00Z","2009-04-29T14:50:00Z","2009-04-29T15:50:00Z","2009-04-29T16:50:00Z"],<br>
            ]<br>
        }},<br>
        {"type": "Feature",<br>
         "properties": {<br>
            "obsType": "air_temperature",<br>
            "uomType": "celsius",<br>
            "elevation": "4",<br>
            "value": ["23","23.2","23","23","23","22.9","22.9","22.8","22.8","22.8","22.7","22.7","22.4","22.4","22.2","22.2","22.1","22.2","22.6","22.4","22.7","23","23"]<br>
        }},<br>
...<br>
</code></pre>


<hr />
<h1>instrumentation case examples</h1>

<ul><li>Geometry z coordinate is relative to mean sea level(MSL) with height(+) or depth(-) in meters.<br>
</li><li>The ordering of effected list arguments is in time increasing order(oldest first, latest last) allowing picking off the latest value be grabbing the last associated set of time/values off the list.<br>
</li><li>? Stationary platforms would use GeoJSON 'Point' type and mobile platforms would use 'MultiPoint' type. MultiPoint coordinates are paired with listed time values.<br>
</li><li>? sOrder(sensor order) is optional but would provide a means of distinguishing between redundant sensors with primary, secondary, etc level of importance. sOrder integer increases with direction away from MSL.</li></ul>

<h2>stationary platform</h2>

The below example shows an air_pressure and two air_temperature readings(a primary sensor and redundant secondary sensor - differing by z-coordinate and sOrder)<br>
<br>
<pre><code>json_callback({<br>
"type": "FeatureCollection",<br>
    "id": "urn:x-noaa:def:station:ndbc::41012",<br>
    "features": [        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30,0] <br>
            },<br>
         "properties": {<br>
            "sOrder": "1",<br>
            "obsType": "air_pressure",<br>
            "uomType": "mb",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z"],<br>
            "value": ["1027.3","1026.5","1026","1025.9","1025.5","1025.3"]<br>
        }},<br>
        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30,4] <br>
            },<br>
         "properties": {<br>
            "sOrder": "1",<br>
            "obsType": "air_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z"],<br>
            "value": ["23","23.2","23","23","23","22.9"]<br>
        }},<br>
        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30,6] <br>
            },<br>
         "properties": {<br>
            "sOrder": "2",<br>
            "obsType": "air_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z"],<br>
            "value": ["23","23.2","23","23","23","22.9"]<br>
        }},<br>
...<br>
</code></pre>

<h2>stationary profiler</h2>

e.g. a temperature,current,etec profiler looking up or down a water column - this is basically the same format as a stationary platform, just the same observation type listed and distinguished by z-coordinate elevation and sOrder.<br>
<br>
<pre><code>json_callback({<br>
"type": "FeatureCollection",<br>
    "id": "urn:x-noaa:def:station:ndbc::41012",<br>
    "features": [        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30,-1] <br>
            },<br>
         "properties": {<br>
            "sOrder": "1",<br>
            "obsType": "water_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z"],<br>
            "value": ["23","23.2","23","23","23","22.9"]<br>
        }},<br>
        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "Point",<br>
                "coordinates": [-80.5,30,-2] <br>
            },<br>
         "properties": {<br>
            "sOrder": "2",<br>
            "obsType": "water_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z","2009-04-28T21:50:00Z","2009-04-28T22:50:00Z","2009-04-28T23:50:00Z"],<br>
            "value": ["23","23.2","23","23","23","22.9"]<br>
        }},<br>
...<br>
</code></pre>


<h2>glider</h2>

e.g. measuring different obs on a freely moving platform<br>
<br>
<br>
<pre><code>json_callback({<br>
"type": "FeatureCollection",<br>
    "id": "urn:x-noaa:def:station:ndbc::41012",<br>
    "features": [        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.5,30,-1.3],[-80.55,29.5,-3.8],[-80.61,28.94,-15.8]] <br>
            },<br>
         "properties": {<br>
            "sOrder": "1",<br>
            "obsType": "water_temperature",<br>
            "uomType": "celsius",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z"],<br>
            "value": ["23","23.2","23"]<br>
        }},<br>
        {"type": "Feature",<br>
            "geometry": {<br>
                "type": "MultiPoint",<br>
                "coordinates": [[-80.5,30,-1.3],[-80.55,29.5,-3.8],[-80.61,28.94,-15.8]] <br>
            },<br>
         "properties": {<br>
            "sOrder": "1",<br>
            "obsType": "salinity",<br>
            "uomType": "psu",<br>
            "time": ["2009-04-28T18:50:00Z","2009-04-28T19:50:00Z","2009-04-28T20:50:00Z"],<br>
            "value": ["33.5","33.8","34.2"]<br>
        }},<br>
...<br>
</code></pre>