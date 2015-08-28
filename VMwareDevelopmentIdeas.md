[VMwareHome](VMwareHome.md)



# Short term #

  * Include earlier development
    * **shapefile** generation
    * '**by obs**' split-outs for several formats
    * '**scout**' component and associated [scripts](http://code.google.com/p/xenia/source/browse/#svn/trunk/scout) for generating obskml feeds
    * **backfilling** for feeds which may have data gaps related to transmission,etc
    * **ADCP** vector visualization [scripts](http://code.google.com/p/xenia/source/browse/#svn/trunk/sqlite/ADCP)
    * **web statistics** report [scripts](http://code.google.com/p/xenia/source/browse/#svn/trunk/sqlite/web_stats)
  * [QA/QC](http://code.google.com/p/xenia/wiki/QAQC) development scripts (R scripts, etc) , **status, updates and notification (internal/external)**
  * **Obsregistry** support http://obsregistry.org
  * ~~**Oostethys SOS** support http://oostethys.org~~~~

## June 5, 2009 ##

  * migrate focus back to postgresql from sqlite for latest/recent 2 weeks to help resolve multi-user, database/process contention issues - may still keep archives as weekly julian data sqlite files
  * migrate away from ObsKML as intermediate XML import/export format, simple CSV files/resultsets are probably easier/simpler to produce and comprehend

# Long term #

  * Other languages, databases, frameworks
    * Redevelop existing scripts and add additional scripts in popular languages/frameworks such as **python, java/J2EE, .NET**, etc
    * Redevelop scripts to allow connection to a variety of different backend relational databases (**Oracle,SQL Server,PostgreSQL,MySQL,Sqlite**)
  * Registry/Catalog of other ObsKML data providers or Xenia VMware instances
  * currently using gnuplot for graph images, would also like to provide more interactive/dynamic client-side type plots such as Google's [Chart API](http://code.google.com/apis/chart/types.html) or [Visualization API](http://code.google.com/apis/visualization/documentation/examples.html)
  * migration to Xen http://xen.org type multiple virtualized servers and cloud computing such as [EC2](http://tim.dysinger.net/2007/07/28/migrating-your-virtual-debian-server-from-xen-to-ec2/)

