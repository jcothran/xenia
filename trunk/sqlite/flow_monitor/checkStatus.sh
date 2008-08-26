cd /var/www/cgi-bin/microwfs
perl check_status.pl ./microwfs.db email 0 status_microwfs.txt status_microwfs_latest.txt flow_microwfs.png "Flow Microwfs" >>/tmp/microwfs_status.log 2>&1
perl check_status.pl ./microwfs.db no_email 0 status_low.txt status_low_latest.txt flow_low.png "Flow Low" 100 >>/dev/null 2>&1


#perl check_status.pl /usr2/home/data/seacoos/sqlite/latest.db email -10 status_latest.txt status_latest_latest.txt flow_latest.png "Flow Latest" >>/tmp/latest_status.log 2>&1

year_week=`date '+%Y_%V'`;
perl check_status.pl /usr2/home/data/seacoos/sqlite/weekly/secoora_weekly_$year_week.db email -10 status_archive.txt status_archive_latest.txt flow_archive.png "Flow Archive" >>/tmp/archive_status.log 2>&1
