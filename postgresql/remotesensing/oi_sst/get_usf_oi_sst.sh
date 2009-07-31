#!/bin/bash
if [ ! -f /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst ]; then
  touch /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst
  cd /home/xeniaprod/scripts/postgresql/remotesensing/oi_sst
  perl get_latest_data.pl
  rm -f  /home/xeniaprod/tmp/remotesensing/lock_get_usf_oi_sst
fi
