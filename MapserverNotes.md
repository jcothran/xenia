After my recent struggle getting mapserver setup to run open layers against, I thought I would document a couple of things I did, mostly the config settings I used for each package.
I used the notes [here](http://www.jasonbirch.com/files/install_mapserver_pair_networks_freebsd.txt) as a starting point.

# Environment Setup #

All these steps were done under an "etch" Debian install.
I built the code and installed it all under my /home directory so as to not overwrite any existing packages. The directory structure I use is:

/home/dramage/local Which contains the installed packages.
/home/dramage/src  Which contains all the source packages.

Ensure that the following environment variables include the local path I am not well versed in good/bad Linux practices concerning setting the environment variables, however I set these in my user .bash\_profile. I did see some posts about the use of LD\_LIBRARY\_PATH as being a no-no, however I wanted to get a working product so I went with it.

```
PATH -> $HOME/local/bin 
LDFLAGS -> -L$HOME/local/lib
CPPFLAGS -> -I$HOME/local/include
LD_LIBRARY_PATH -> $HOME/local/lib
LD_RUN_PATH -> $HOME/local/lib
```

# Packages #
I grabbed all the packages from the source, not through the Debian package manager. I ran into problem after problem grabbing source packages through Debian.

**Recent Changes**
Recently I have been attempting to get [TileCache](http://tilecache.org/) up and running. TileCache relies on the python mapscript from mapserver to work. I have been running into issues of undefined symbols with mapscript ranging from FT\_New\_Face to libiconv\_open not being found. I think I have traced the issue to the fact I build all the mapserver pieces with --disable-shared. I have gone back and made most of them without that switch and seem to be getting closer. Basically this means instead of the libraries being linked into the exectuable, mapserver will now be using the components as **.so or shared objects.**



## LIBPNG ##
Version used: 1.2.29
```
./configure --prefix=$HOME/local --disable-shared \n
make
make install
```

## FREETYPE ##
Version used: 2.3.5
```
setenv GNUMAKE gmake
./configure  --prefix=$HOME/local
make
make install
```
## LIBJPEG ##
Version used: 6b
```
./configure  --prefix=$HOME/local --disable-shared
make
make install
make install-lib
```
## Tiff ##
Version used: 3.8.2
```
./configure --prefix=$HOME/local --disable-shared
make
make install
```
## LIBGeoTiff ##
Version used: 1.2.4
```
./configure --prefix=$HOME/local --disable-shared --with-libtiff=$HOME/local
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
Version used: 1.12
```
./configure  --prefix=$HOME/local
make
make install
```
## GD 2 ##
Version used: 2.0.35
```
./configure --prefix=$HOME/local --disable-shared  --with-libiconv-prefix=$HOME/local --with-png=$HOME/local --with-freetype=$HOME/local --with-jpeg=$HOME/local
make
make install
```
## PROJ.4 ##
Version used: 4.6.0
```
./configure --prefix=$HOME/local --disable-shared
make
make install
```
## SQLite ##
Version used: 3.5.8
```
./configure --prefix=$HOME/local --disable-shared
make
make install
```
## Python ##
Version used: 2.5.2

I built my own copy of Python so I could make sure I had everything I needed. I did not want to chance messing up the Python being used on the system.

```
./configure --prefix=$HOME/local
make
make install
```

## GDAL ##
Version used: 1.5.1

**NOTE**
Since I had my own local build of python, that is what I wanted gdal to use, however I cannot find how you set an option to tell the make to look locally. Where I was having problems was when the make install got to the swig/python make, it would error out.
In the swig/python/GNUMakefile I changed PYTHON=python to PYTHON=/home/dramage/local/bin/python

```
./configure --prefix=$HOME/local --with-static-proj4=$HOME/local --with-png=$HOME/local --with-jpeg=$HOME/local --with-sqlite3=$HOME/local --with-geotiff=$HOME/local --with-python --with-pymoddir=$HOME/local/lib/python2.5/site-packages
--with-tif=$HOME/local --without-odbcmake
make install
```
## GEOS ##
Version used: 3.0.0
```
./configure --prefix=$HOME/local --disable-shared 
make
make install
```
## AGG ##
Version used: 2.5
```
make
```
## PHP ##
Version used: 5.2.6

I built my own copy of PHP so I could make sure I had everything I needed. I did not want to chance messing up the PHP being used on the system.

```
./configure --prefix=$HOME/local
make
make install
```
## PostGresSQL ##
Version used: 8.2.7
```
./configure --prefix=/usr/local/pgsql/
make
make install
```
## PostGIS ##
Version used: 1.3.3
```
./configure --prefix=/usr/local/pgsql --with-pgsql=/usr/local/pgsql/bin/pg_config
```
UPDATE: For our VMWARE image, I installed the postgresql-server-dev-8.3 package:
```
sudo apt-get postgresql-server-dev-8.3
```

## MAPSERVER ##
One thing to notice here is I did not use my own Postgres build. The latest source was already on the machine and PostGIS was build as well, so I used that. However I went ahead and listed them above since you do need them.
Version used: 5.0.2
```
./configure --prefix=$HOME/local --enable-runpath --with-gdal=$HOME/local/bin/gdal-config --with-ogr=$HOME/local/bin/gdal-config --with-proj=$HOME/local --with-php=$HOME/local --with-gd=$HOME/local --with-freetype=$HOME/local --with-png=$HOME/local --with-jpeg=$HOMEe/local --with-libiconv=$HOME/local --with-wmsclient --with-postgis=/usr/local/pgsql/bin/pg_config
make
```
After making mapserver, you'll need to put the executable in a cgi-bin so apache or whatever webserver you are using will be able to access it.

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