Page outline:



# NANOOS Xenia OOSTethys SOS Perl server #

## Background ##

We are implementing GoMOOS/Eric Bridger's Perl SOS server (oostethys\_sos.cgi) on [the NANOOS Xenia database we've developed at APL](http://code.google.com/p/xenia/wiki/NANOOSXenia). This SOS server is currently only running within our firewall at APL, for testing purposes. Eric's code is available as an [OOSTethys SOS Cookbook (with additional documentation)](http://www.oostethys.org/downloads/sos-cookbook-perl) and as code files in his [Google Code SVN repository](http://code.google.com/p/oostethys/source/browse/#svn/trunk/component/server/perl).

While the code I've adapted originally came from Eric, I got it via Jeremy Cothran (SECOORA) and Xiaoyin Qi (Carolinas RCOOS); this code is available at [Jeremy's Xenia repository](http://code.google.com/p/xenia/wiki/XeniaSOS). They made [some adaptations to Eric's code for PostgreSQL-Xenia](http://groups.google.com/group/xeniavm/browse_thread/thread/37618beca6d0a159) which made it easier to get going.

Jeremy has extensive comments and discussions on this server on [his Xenia SOS page](http://code.google.com/p/xenia/wiki/XeniaSOS). oostethys\_sos.cgi implements the OOSTethys SOS flavor, not the DIF flavor. Jeremy has a separate Perl SOS server that implements DIF SOS (also available from that page). According to Rick Blair, the OOSTethys flavor is also acceptable to IOOS.

Our adapted SOS server code will be made available once our SOS service goes operational.

## Brief technical specs ##

[I've adapted the Xenia data model for PostgreSQL; here's the documentation page for that implementation](http://code.google.com/p/xenia/wiki/NANOOSXenia).

Eric's code can use configurations and pull data from a set of XML and ascii files, or do everything by directly querying the database, or a mix of both. Currently I'm relying exclusively on database queries. I've created a Xenia table (_obs\_series\_cat_) that holds what I call an "observation series catalog" summarizing available platforms, sensors, measurements, locations and data extent (and automatically kept updated); I'm making use of this catalog table for quick summary data extraction from the SOS server.

## Issues identified and already addressed ##

  * [Rick Blair identified a validation error with &lt;sos:eventTime&gt;. After pointing it out to Eric, he provided a solution](http://groups.google.com/group/xeniavm/browse_thread/thread/dda47881b87e5206#), which I've implemented.
  * Implemented Eric's correction (April 2009) to 

&lt;swe:elementCount&gt;



&lt;swe:Count&gt;



&lt;swe:value&gt;

 in GetObservation (it's supposed to represent the number of swe:values DataRecords, but it wasn't doing that).
  * I'm querying _obs\_series\_cat_ (see above) to extract and populate an accurate start\_time. Previously, it was hard-wired to a fixed value.
  * Our Xenia implementation includes observations from ship cruises and buoys. The SOS server is hard-wired to expect moorings. I adapted the code to provide the center point of each cruise program as the boundedBy:Envelope point location in the GetCapabilities and GetObservation responses.

## Other outstanding issues or decision points ##

  * The SOS server hardwires the assumption that all platforms are moorings. This creates awkward descriptive text in many places, for cruises. I plan to tweak the text so that the response is suits the platform type, queried from the database.
  * Bounding box issues:
    1. The SOS server provides all bounding box envelopes as points, because it has a hard-wired expectation that all platforms are moorings. But for ship cruises, a rectangular bounding box seems more appropriate and realistic. I've modified the code to do this for cruises (again by querying _obs\_series\_cat_), but I'm not yet 100% sure this would be a valid response. The NANOOS CMOP/PySOS service currently does serve rectangular bounding boxes for cruises.
    1. Currently the bounding box includes a third value that's probably for depth. But the code hard-wires that value to be zero. We could modify it so it returns actual depth envelopes.
  * The "elevation" value in _multi\_obs_ (m\_z column) is interpreted as depth (hard-wired in the code). But I've adopted the convention that m\_z is positive up, so maybe it should be identified as such?
  * Change time/TimePeriod/timeInterval so it's not hardwired? But what would we use instead? Many of the platforms in the Xenia-APL database provide observations at irregular intervals. Even ORCA observations have intervals that change throughout the year.
  * Measurements vs. observations vs. sensors
    1. We need to look into using observation type (O&M's) terms that correspond to a defined ontology on MMI. The server currently just uses what's found in the Xenia data dictionary
    1. I've run into two important problems: 1, For a platform, multiple sensors with the same m\_type (measurement type); it's not clear whether results are coming from only one of the sensors, or mixing up data from both sensors. 2, Vector m\_type's, such as velocity vectors. The query in the SOS server has no mechanism to return the 2nd component. [A discussion with Jeremy and Eric provided some ideas for moving forward on this.](http://groups.google.com/group/xeniavm/browse_thread/thread/49bb9549cb35f8a2#)
  * Improve the text currently used to compose the ObservationOffering Description. It's very awkward
  * Data provider vs. data originator vs. Regional Association: how and where to give proper attribution and contact information? See the template DataProvider xml file (example\_sos\_config.xml), where platform-specific DataProviders are specified separate from the overall "Publisher" and "RegionalAssociation"
  * Data requests that return many, many observations result in XML files (when downloaded) with a **huge** line in the swe:values array. Such a huge line can overwhelm some text editors, so it's a drag.