#Notes on mapserver setup


# Packages #
I grabbed all the packages from the source, not through the Debian package manager. I ran into problem after problem grabbing source packages through Debian.


**LIBRARY PATHS**
A recurring problem I seem to have is shared library files not being found, or incorrect ones getting used. On this Ubuntu image, I've installed all the libs and bins in the default location which is /usr/local. For some reason, some of the libs weren't being found. If you have this issue check your ld.so.conf.d directory(if your system uses that, otherwise it you might just need to edit the ld.so.conf file) and make sure you have a .conf file that spells out the /usr/local/lib file for the shared libraries. My ld.so.conf.d directory had a libc.conf file that had /usr/local/lib yet I still had an issue. Once you make a change, you run 'ldconfig' to reload the changes. This seemed to cure my issue.

## LIBPNG ##
NOTE: I used v1.2.43 as the v1.4.x release seemed to have some incompatibility issues with GD2 below.
```
./configure 
make
make install
```

## FREETYPE ##

```
setenv GNUMAKE gmake
./configure 
make
make install
```
## LIBJPEG ##

```
./configure 
make
make install
```
## Tiff ##

```
./configure 
make
make install
```
## LIBGeoTiff ##

```
./configure --with-libtiff=/usr/local
make 
make install
```
UPDATE: Doing another round of builds, I was getting an error:
```
"Nonrepresentable section on output"
```
doing some internet searching turned up [this](http://mateusz.loskot.net/2008/07/31/libgeotiff-lesson-for-today/) need for this configure option:
```
./configure --with-ld-shared="gcc -shared"
or for UBUNTU
export CFLAGS=-fno-stack-protector
export CPPFLAGS=-fno-stack-protector
```

## LIBICONV ##

```
./configure  
make
make install
```
## GD 2 ##

```
./configure --with-libiconv-prefix=/usr/local --with-png=/usr/local --with-freetype=/usr/local --with-jpeg=/usr/local
make
make install
```
## PROJ.4 ##

```
./configure 
make
make install
```
## SQLite ##

```
./configure 
make
make install
```

## GDAL ##
NOTE: Swig must be installed to use the python bindings.
```
./configure --prefix=/usr/local --with-static-proj4=/usr/local --with-png=/usr/local --with-jpeg=/usr/local --with-sqlite3=/usr/local --with-geotiff=/usr/local --with-python --with-pymoddir=/usr/local/lib/python2.5/site-packages
--with-tif=/usr/local --without-odbcmake
make install
```
## GEOS ##
Needed to use sudo to do the make.
```
./configure 
sudo make
sudo make install
```
## AGG ##

```
make
```
## PostGIS ##
```
./configure 
```
Installed the postgresql-server-dev-8.3 package:
```
sudo apt-get postgresql-server-dev-8.3
```
Trying to use the latest release tar, I kept running into an error that postgis\_config.h could not be found. After some searching on the net, found someone else had the same issue with a previous version and the solution was to check the source out of SVN and build it, first running 'sh autogen.sh'. Then running configure and finally make. This worked fine.
I then went back and tried to rebuild the tarred version I had downloaded and that worked. Not sure what had changed other than perhaps a change in the shell/environemnt from running the 'autogen.sh'.
To run the 'make check', need to be the postgres user:
```
sudo su postgres
make check
```
If not, you get an error message of: "psql: FATAL:  permission denied to set parameter "lc\_messages""
## MAPSERVER ##
Added following packges:
```
sudo apt-get install libxslt1-dev
sudo apt-get install libpam0g-dev
```
```
./configure --enable-runpath --with-gdal=/usr/local/bin/gdal-config --with-ogr=/usr/local/bin/gdal-config --with-proj=/usr/local --with-php=/usr/include/php5 --with-gd=/usr/local --with-freetype=/usr/local --with-png=/usr/local --with-jpeg=/usr/local --with-libiconv=/usr/local --with-wmsclient --with-postgis=/usr/lib/postgresql/8.3/bin/pg_config
make
```
After making mapserver, you'll need to put the executable in a cgi-bin so apache or whatever webserver you are using will be able to access it.

Tilecache uses the mapscript.py script. To install the scripts go into mapserver/mapscript/python and run 'python setup.py install'


# Various Notes #
One issue I was having was some of the gdal utilities not being able to find a shared object that I had built. A useful tool to track down where/what shared libraries an executable is using is "ldd". If I do "ldd mapserver" my output is:
```
libjpeg.so.62 => /home/dramage/local/lib/libjpeg.so.62 (0x40018000)
libz.so.1 => /usr/lib/libz.so.1 (0x40046000)
libxerces-c.so.28 => /usr/local/lib/libxerces-c.so.28 (0x40058000)
libpthread.so.0 => /lib/libpthread.so.0 (0x4043e000)
libgeotiff.so => /home/dramage/local/lib/libgeotiff.so (0x4048f000)
libnetcdf.so.3 => /usr/lib/libnetcdf.so.3 (0x404f7000)
libpq.so.5 => /usr/local/pgsql/lib/libpq.so.5 (0x4051a000)
librt.so.1 => /lib/librt.so.1 (0x40533000)
libdl.so.2 => /lib/libdl.so.2 (0x40546000)
libcurl.so.4 => /usr/local/lib/libcurl.so.4 (0x4054a000)
libm.so.6 => /lib/libm.so.6 (0x4057d000)
libstdc++.so.5 => /usr/lib/libstdc++.so.5 (0x4059f000)
libgcc_s.so.1 => /lib/libgcc_s.so.1 (0x40659000)
libc.so.6 => /lib/libc.so.6 (0x40662000)
/lib/ld-linux.so.2 => /lib/ld-linux.so.2 (0x40000000)
libcrypt.so.1 => /lib/libcrypt.so.1 (0x40796000)
```
This is where the LD\_LIBRARY\_FLAGS really comes into play. If there is an existing build of any of the needed shared libraries and I did not have your environment setup to point to the builds I made, the executable would search the default path and use what it found, if it found anything. This could be problematic if the library was not built with whatever features I needed.

---

## PostGis ##
To get our postgis data brought over onto the VMWare machine, I exported the data via pg\_dump. After running into errors while importing, I noticed that the postgis functions it was trying to create was referencing a local directory, or trying to with a path like '$libdir/liblwgeom'. I did a global search in replace in the sql file to point to our target machine's fullpath to liblwgeom.