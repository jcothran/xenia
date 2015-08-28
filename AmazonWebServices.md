see also [VMwareHome](VMwareHome.md)

The lead-in to this wikipage is related to the initial effort documented [here](http://code.google.com/p/xenia/wiki/VMwareInstall#Amazon_Web_Services) regarding converting our existing [VMware based .vmdk image](http://code.google.com/p/xenia/wiki/VMwareDownload) into an Amazon Machine Image(AMI) for running on [Amazon Web Services](http://aws.amazon.com) (Amazon's web server cloud).



# Xenia Amazon Machine Instance(AMI) #

The latest server image of our production development environment is available as a [publicly shared AMI](https://developer.amazonwebservices.com/connect/entry.jspa?externalID=3107) at [Amazon Web Services](http://aws.amazon.com) with <br />

AMI ID = **ami-9028caf9**

To instantiate this server instance, you will need to create a credit-card based account which Amazon can bill the server charges to.  The pricing fees are listed at http://aws.amazon.com/ec2/#pricing and the default basic server is currently billed at 8.5 cents per hour or about $2 per day.  Server monitoring can also be enabled for 1.5 cents per hour.

This server instance is an Ubuntu 8.10 version based OS, which uses previously developed scripts(perl mostly) to support a variety of output formats and web services http://code.google.com/p/xenia/wiki/VMwareProducts from a source relational database(PostgreSQL+PostGIS, schema label is 'Xenia').  The current aggregation datatype focus is in-situ data(buoys,stations,drifters,gliders,etc).  This vm was was developed on top of 'gisvm' http://gisvm.com (November 2008 version) which includes many popular open source geospatial tools.  The scripts developed include/support:

Eric Bridger's RDB to Oostethys SOS script http://code.google.com/p/xenia/wiki/XeniaSOS#Oostethys_SOS <br />
IOOS DIF SOS http://code.google.com/p/xenia/wiki/XeniaSOS#DIF_SOS <br />
GeoJSON http://code.google.com/p/xenia/wiki/VMwareProducts#GeoJSON

The intent would be that a data provider would only have know how to get data into the database via ObsKML(XML) or SQL directly and would automatically have several formats,services and tools readily available for data management and sharing.  The image(s)/appliances should be an ongoing production development snapshot of what we're doing within Secoora http://secoora.org made available to the observing community.  Glad to incorporate scripts/documentation which leverage the xenia RDB schema directly or more generally abstracted database view/resultset scripts which utilize those data elements captured by the xenia schema.

Would be interested to see more appliance/turn-key type approaches and further appliance type 'remixes' of various community tools to fit various audience needs.


---

# Next Steps #

[AmazonSetup](AmazonSetup.md) describes the server setup steps for your Amazon server instance

[VMwareProducts](VMwareProducts.md) describes the output formats and services which should be available from the server image

[ObsKML](http://code.google.com/p/xenia/wiki/VMwareTest#Adding_a_new_ObsKML_feed) describes adding new in-situ data to the Xenia database for aggregation and sharing via the output formats and services

A google groups has been setup for questions/discussion at http://groups.google.com/group/xeniavm

see also
  * http://code.google.com/p/xenia/wiki/XeniaHome