#!/bin/bash
if [ ! -f /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst ]; then
  touch /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst

  #Cleanup any files older than 30 days
  /usr/bin/find /home/xeniaprod/feeds/remotesensing/modis_sst -maxdepth 1 -cmin +43200 -exec rm -f {} \;

  cd /home/xeniaprod/scripts/postgresql/remotesensing/modis_sst
  perl get_latest_data.pl
  rm -f  /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst
fi
