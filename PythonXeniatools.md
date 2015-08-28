

# Introduction #

To make sure various Python scripts I create can re-use common code, I needed a place to store the scripts that the Python environment could find. Python has a site-packages directory that is a common location, so I created a xeniatools directory to house my various utilities. Xeniatools is a bit of a misnomer as I have scripts that do alot more than just interact with the Xenia database.

For brevity's sake "External Dependencies" are other Python packages I had to install. "Internal Dependencies" are Python objects developed in house, and most likely living in the xeniatools directory.


## Files ##
### [rangeCheck.py](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/rangeCheck.py) rangeCheck.py ###
This is the brains of our QAQC processing. It doesn't have a 'main' function, it is just a container for the various classes used for doing the QAQC.
[qaqcChecks.py](http://code.google.com/p/xenia/wiki/QAQCScripts#qaqcChecks.py) is the wrapper script that kicks off testing.
#### External Dependencies ####
  * [SQLAlchemy](http://www.sqlalchemy.org/)
  * [lxml](http://lxml.de/) using the  object etree
#### Internal Dependencies ####
  * qaqcTestFlags from [xeniatools.xenia](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xenia.py#21)
  * uomconversionFunctions from [xeniatools.xenia](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xenia.py#1011)
  * recursivedefaultdict from [xeniatools.xenia](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xenia.py#9)
  * xmlConfigFile from [xeniatools.xmlConfigFile](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xmlConfigFile.py#10)
  * smtpClass from [xeniatools.utils](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/utils.py#17)

---


### [xenia.py](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xenia.py) xenia.py ###

Basic Xenia database interface. This was the first Xenia database object I developed in Python before starting to use SQLAlchemy. This file houses some objects that are database specific, but not database connection specific. For instance the QAQC flags and units conversion functions.
#### External Dependencies ####
  * [pysqlite2](http://trac.edgewall.org/wiki/PySqlite)
  * [psycopg2](http://initd.org/psycopg/)
  * [lxml](http://lxml.de/)


---

### [xeniaSQLAlchemy.py](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/xeniaSQLAlchemy.py) xeniaSQLAlchemy.py ###
SQLAlchemy interface for the Xenia database. The main tables are all defined here.
#### External Dependencies ####
  * [SQLAlchemy](http://www.sqlalchemy.org/)
  * [GeoAlchemy](http://www.geoalchemy.org/)


---

### [utils.py](http://code.google.com/p/xenia/source/browse/trunk/python/xeniatools/utils.py) utils.py ###
This file is meant to house utility classes. Currently the only object available is the smtpClass which enables us to send emails.