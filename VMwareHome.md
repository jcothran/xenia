see also [VMwareHome](VMwareHome.md) [AmazonWebServices](AmazonWebServices.md)

Developed a vmware appliance/image of the [Xenia](http://code.google.com/p/xenia/wiki/XeniaHome) relational database and associated scripts and products(see presentation materials [here](http://code.google.com/p/xenia/wiki/JCBroadNotes#presentation_materials)) for free community use, download and modification.  The current default Xenia setup uses a combination of perl scripts and sqlite relational database to process approximately 10,000 observations per hour.

The latest vmware image download link and instructions are at [VMwareDownload](VMwareDownload.md)

This vmware image was developed on top of the FOSS geospatial vmware image(geostatistics package which includes 'R') available at http://gisvm.com ([appliance description](http://www.vmware.com/appliances/directory/55606)) - thanks to Ricardo Pinho.

While the Xenia scripts do not directly utilize/interact those included applications in the gisvm image at this time, I thought they represent the best existing collection of FOSS geospatial software for future development.

The main links of interest regarding this vmware instance are
  * [VMwareTest](VMwareTest.md)
  * [VMwareProducts](VMwareProducts.md)
  * [VMwareDownload](VMwareDownload.md)
  * [VMwareInstall](VMwareInstall.md)
  * [VMwareDesign](VMwareDesign.md)
  * [VMwareMod](VMwareMod.md)
  * [VMwareUpdates](VMwareUpdates.md)
  * [VMwareDevelopmentIdeas](VMwareDevelopmentIdeas.md)

If you are looking to experiment with the xeniavm image instance on a local vmplayer, see [VMwareTest](VMwareTest.md) for instructions.

[VMwareUpdates](VMwareUpdates.md) will contain any notes regarding xenia vmware image related development updates.

A google groups has been setup for discussion at http://groups.google.com/group/xeniavm

A listserv or IRC channel(would suggest #xeniavm ) could also be established if enough developers are interested.


---

Trying to utilize this server virtualization as a means to help standardardize and maintain our in-house server setups. Additionally since the server is virtualized as a file image, it is possible to share and reproduce this server and associated tools/development wherever the vmware file image is supported (including other 'players' or cloud type services). The following article link describes how this concept is helpful to IT shops

http://rwhiffen.wordpress.com/2006/07/13/the-genius-of-free-vmware/

And the below link talks about vmware images as 'appliances'

http://fettig.net/weblog/2006/02/27/the-vmware-image-is-the-new-appliance/

which is how vmware also describes their community collection of them at their site http://www.vmware.com/appliances/

Other associated file links are at

http://delicious.com/giraclarc/vmware http://delicious.com/giraclarc/cloud