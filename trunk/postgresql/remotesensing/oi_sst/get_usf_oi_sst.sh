#!/bin/bash
if [ ! -f /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst ]; then
  touch /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst

  #Cleanup any files older than 30 days
  /usr/bin/find /home/xeniaprod/feeds/remotesensing/oi_sst -maxdepth 1 -cmin +43200 -exec rm -f {} \;

  cd /home/xeniaprod/scripts/postgresql/remotesensing/oi_sst
  perl get_latest_data.pl

  rm -f  /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst
fi
