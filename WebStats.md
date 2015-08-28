earlier Google Analytics filtering/proxy ideas at http://trac.secoora.org/datamgmt/wiki/JCothranGAProxy

Developed these scripts out of frustration with other freely available web analysis packages including Google Analytics which has been having problems lately with how statistics are reported(documented [here](http://www.google.com/support/forum/p/Google+Analytics/thread?tid=77847d39560ae940&fid=77847d39560ae94000045dd9df11662b&hl=en))  Mainly I am looking for more than just total hits, but also to filter and cross reference content with its users and references.

source code http://code.google.com/p/xenia/source/browse/#svn/trunk/sqlite/web_stats

Create sqlite database web\_stats.db using [create\_web\_stats.sql](http://code.google.com/p/xenia/source/browse/trunk/sqlite/web_stats/create_web_stats.sql) or use existing created(unpopulated) at [web\_stats.db](http://code.google.com/p/xenia/source/browse/trunk/sqlite/web_stats/web_stats.db)

apache web log input or script [web\_stats.v2.pl](http://code.google.com/p/xenia/source/browse/trunk/sqlite/web_stats/web_stats.v2.pl) should be modified to pull apache record fields (see @record variable) in same format as
```
#apache log record/line format like below
#74.220.203.50 - - [11/Jan/2009:04:26:27 -0500] "GET /seacoos_data/html_tables/html_tables/usgs.021720709.wq.htm HTTP/1.0" 200 213 "http://www.carocoops.org/seacoos_data/html_tables/html_tables/" "Wget/1.10.2 (Red Hat modified)"
```

[web\_stats.v2.pl](http://code.google.com/p/xenia/source/browse/trunk/sqlite/web_stats/web_stats.v2.pl) can also be modified to ignore particular ip,page,agent,referer arguments and filter page content, etc

secondary analysis scripts can have '`min_`' variables set to other minimum thresholds for reporting

```
#general flow
move log files(suffixed .log) to be analyzed to subfolder 'log' within scripts folder

no duplicate row checking/indexes on table cross_ref_info
so delete cross_ref_info rows depending on date overlap? 
#to see latest cross_ref_info.page_date row processed
select * from cross_ref_info order by page_date desc limit 1;

#populate lookup tables and cross_ref_info table
perl web_stats.v2.pl > logfile &

#mark significant ip's for host/dns lookup    
perl update_host_lkp.pl    
perl update_host_info.pl

#set analysis date_range,min_page/ip/ref
#generates set of report .txt files
perl report_cross_ref.pl
```

Description of report text files created
  * page\_summary.txt - top pages/content requested
  * ip\_summary.txt - top ip (users)
  * ref\_summary - top referers
  * page\_ip\_summary.txt - cross reference of pages with ip users
  * page\_ref\_summary.txt - cross reference of pages with referers

Note that these perl scripts do not include closing statement handlers (sth) or database disconnects(dbh) at the end of file but this does not seem to have any negative effects.

Other potential development options
  * providing content/user trending via indicators,graphs,etc
  * profile page return codes that are **not** 200(unsuccessful) web hits
  * profile page,ip,ref history over time
  * profile agents