#################################################################
#super aggregate obskml for last hour/latest
#expand and zip new 'day' - past 24 hours of kml data kmz file

#remember microwfs.db maintain.pl cron step

#rem get Dan's ObsKML first - runs around the hour but latest before run is around :45
#obskml dan(netcdf2obskml - ndbc,nws,nos,usf,skio,cormp,carocoops)
#0,20,40 * * * * cd /home/buoy/scripts ; perl getDanObsKML.pl >> /tmp/buoy.log 2>&1

#rem root crontab/permissions html content
#10 * * * * cd /usr2/home/data/seacoos/html_tables ; perl obskml_to_html_table.pl http://carocoops.org/obskml/feeds/secoora_obskml_latest.kmz > /tmp/obs_out.log 2>&1
#10 * * * * cd /usr2/home/data/seacoos/html_tables ; perl obskml_to_html_content_sqlite.pl http://carocoops.org/obskml/feeds/secoora_obskml_latest.kmz > /tmp/obs_out.log 2>&1

#rem Dan's hourly torino grab of html_tables at 0:15
#rem Dan's metric process at 00:30


#start


#get Dan's ObsKML first
#obskml dan(netcdf2obskml - ndbc,nws,nos,usf,skio,cormp,carocoops)
cd /home/buoy/scripts

perl getDanObsKML.pl
/home/buoy/scripts/mk_seacoos_all_latest.sh >> /tmp/obskml.log 2>&1

#sqlite main db started with microwfs - need to change over to a name less specific at some point
cd /var/www/cgi-bin/microwfs
perl obskml_to_xenia_sqlite.pl http://carocoops.org/obskml/feeds/seacoos_all_latest.zip >>/tmp/microwfs_debug.log 2>/dev/null 
#perl obskml_to_xenia_sqlite.pl http://carocoops.org/obskml/feeds/nos/nos_latest_obskml.zip >>/tmp/microwfs_debug.log 2>/dev/null 
cp latest.sql /var/www/html/obskml/feeds/latest_raw.sql

perl xenia_sqlite_to_obskml.pl >/tmp/microwfs.log 2>&1
cp secoora_obskml_latest.kml /var/www/html/obskml/feeds
cp secoora_obskml_latest.kmz /var/www/html/obskml/feeds

##########################################################################
#had to make styling, etc dependent on *latest only* obs filtered above so not overwhelmed by duplicate data

cd /var/www/html/obskml/scripts
perl obskml_all_latest.pl
cp /var/www/html/obskml/feeds/seacoos_all_latest_styled.kmz /var/www/html/gearth/latest_placemarks.kmz
cp /var/www/html/obskml/feeds/seacoos_all_latest_styled.kmz /var/www/html/obskml/feeds/secoora_all_latest_styled.kmz

#create csv file for all latest
#DWR 4/28/2008 Added rm of the all_latest.csv
cd /var/www/html/obskml/scripts
rm /var/www/html/obskml/feeds/all_latest.csv
perl gen_csv_obskml.pl

#create shapefile for all latest
#DWR 4/28/2008 Added rm of the all_latest.dbf
rm /var/www/html/obskml/feeds/all_latest.dbf
/usr2/local/gdal/gdal-1.2.6/bin/ogr2ogr -f "ESRI Shapefile" /var/www/html/obskml/feeds /var/www/html/obskml/feeds/all_latest.csv >> /tmp/obskml.log 2>&1

/usr2/local/gdal/gdal-1.2.6/bin/ogr2ogr -f "ESRI Shapefile" /var/www/html/obskml/feeds /var/www/html/obskml/feeds/all_latest.vrt >> /tmp/obskml.log 2>&1

cd /var/www/html/obskml/feeds
zip -m all_latest_shapefile.zip all_latest_shapefile.* >> /tmp/obskml.log 2>&1

#################################################################
#secoora hourly CSV, shapefiles by_obs
#weird bug, crontab execution seems to require log output when ignorable errors are lengthy for the execution - otherwise cuts off midway
cd /usr2/home/data/seacoos
perl gen_csv_obskml_by_obs.pl http://nautilus.baruch.sc.edu/obskml/feeds/secoora_obskml_latest.kmz >> /tmp/obskml.log 2>&1

#secoora hourly styled KML
cd /usr2/home/data/seacoos
perl gen_obskml_by_obs.pl http://nautilus.baruch.sc.edu/obskml/feeds/secoora_obskml_latest.kmz >> /tmp/obskml.log 2>&1

#touchscreen kml - assumes http://nautilus.baruch.sc.edu/obskml/scripts/secoora_obskml_latest.kml
cd /var/www/html/obskml/scripts
perl gen_touchscreen_obskml.pl

