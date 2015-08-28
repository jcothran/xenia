Here's the link to the earlier Postgresql documentation

http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/XeniaPackageV2#Source


---

# [Install Notes](XeniaPackageV2#Install_Notes.md) #

Run the following sql in the following order against your database

[Postgres main schema](http://code.google.com/p/xenia/source/browse/trunk/postgresql/sql/db_xenia_v3.1_postgresql.sql)

[Observation data dictionary lookups](http://code.google.com/p/xenia/source/browse/trunk/sqlite/sql/obs.sql)

Note in the above sql file there is the below commented SELECT statement which will give a more human readable listing of the observation data dictionary

[Display order lookups](http://code.google.com/p/xenia/source/browse/trunk/sqlite/sql/display_order.sql)

## PostGIS Enabling ##
As taken from [here](http://postgis.refractions.net/docs/ch02.html)

Many of the PostGIS functions are written in the PL/pgSQL procedural language. As such, the next step to create a PostGIS database is to enable the PL/pgSQL language in your new database. This is accomplish by the command

createlang plpgsql xenia

Now load the PostGIS object and function definitions into your database by loading the postgis.sql definitions file (located in [prefix](prefix.md)/share/contrib as specified during the configuration step).

Some systems have postgis.sql others have lwpostgis.sql.

psql -d xenia -f postgis.sql

For a complete set of EPSG coordinate system definition identifiers, you can also load the spatial\_ref\_sys.sql definitions file and populate the spatial\_ref\_sys table. This will permit you to perform ST\_Transform() operations on geometries.

psql -d xenia -f spatial\_ref\_sys.sql

If you wish to add comments to the PostGIS functions, the final step is to load the postgis\_comments.sql into your spatial database. The comments can be viewed by simply typing \dd [function\_name](function_name.md) from a psql terminal window.

psql -d xenia -f postgis\_comments.sql

---

# Source Code #

http://code.google.com/p/xenia/source/browse/trunk/postgresql


---

# [Xenia Table Schema Diagram](XeniaPackageV2#Xenia_Table_Schema_Diagram.md) #

![http://xenia.googlecode.com/files/xenia_v2_marked.jpg](http://xenia.googlecode.com/files/xenia_v2_marked.jpg)