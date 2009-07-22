#!/bin/bash

cd /home/xeniaprod/scripts/QAQC; 
perl CalcPlatformUptimePercentage.pl --WorkingDir /home/xeniaprod/feeds/qaqc --TstProfFeed http://carocoops.org/~dramage_prod/rcoos/test_profiles.xml --XMLConfigFile=/home/xeniaprod/config/UptimeConfigPostgres.xml
perl GenPlatformUptimeWebpage.pl GenPlatformUptimeWebpage.pl --WorkingDir /home/xeniaprod/feeds/qaqc/ --StyleSheet http://carocoops.org/~dramage_prod/styles/main.css
