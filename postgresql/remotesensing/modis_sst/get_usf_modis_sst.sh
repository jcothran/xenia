#!/bin/bash
if [ ! -f /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst ]; then
  touch /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst
  cd /home/xeniaprod/scripts/postgresql/remotesensing/modis_sst
  perl get_latest_data.pl
  rm -f  /home/xeniaprod/tmp/remotesensing/lock_get_usf_modis_sst
fi
