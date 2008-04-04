#!/bin/perl

use LWP::Simple;
use strict;
#my $URL = 'http://nautilus.baruch.sc.edu/wms/adcp_profiler?service=wms&version=1.1.0&request=getmap&layers=us_filled,us_outline,world_outline,country_names,adcp_xenia';
#my $URL ='http://nautilus.baruch.sc.edu/wms/adcp_profiler?service=wms&version=1.1.0&request=getmap&layers=us_filled,us_outline,world_outline,country_names,adcp_xenia&BBOX=-86.05,23.85,-74.7,36.50';
my $URL='http://nautilus.baruch.sc.edu/wms/adcp_profiler?service=wms&version=1.1.0&request=getmap&layers=us_filled,us_outline,world_filled,world_outline,country_names,adcp_xenia&BBOX=-86.05,23.85,-74.7,36.50';
getstore($URL,'/tmp/ms_tmp/adcp_profiler_platform_map.png') || warn $!;
exit 0;
