#!/usr/bin/perl
use strict;

####various elements which we are filtering as bad, ignored,good or subscriber - configure as needed
my @bots_ignore = qw(googlebot inktomi livebot crawl proxy.aol.com);
#my @ip_ignore = qw(129.252.37 129.252.37 129.252.37.86 129.252.139 129.252.139 127.0.0.1 152.2.92.48 152.20.240.9);
my @ip_ignore = qw(129.252.37 129.252.37 129.252.37.86 129.252.139 129.252.139 127.0.0.1);
my @agent_ignore = qw(bot Slurp Validator compass spider crawler);

my @page_ignore = qw(TWiki Sandbox robots.txt WebStatistics bin/oops bin/rdiff error_404 error_403);
#my @page_good = qw(carocoops_website/index.php carocoops_website/buoy_detail.php carocoops_website/buoy_graph.php folly/index.php springmaid/index.php carolinas/ gearth);

my @referer_ignore = qw(nautilus.baruch.sc.edu carocoops.org caro-coops.org search http://images.google.*/imgres);
#my @referer_good = qw(oifish magic oceanislebeachsurf charlestondiving catchsomeair oceanislefishingcenter palmettosurfers ocean.floridamarine.org iopweather www.follywaves.com);

#my @subscriber_good = qw(www.gomoos.org nys.biz.rr.com piper.weatherflow.com maury.marine.unc.edu cromwell.marine.unc.edu seacoos3.marine.unc.edu web1.iboattrack.com cormp2.das.uncw.edu oceanlab.rsmas.miami.edu rmo.bellsouth.net navy.mil);

##

#apache log record/line format like below
#74.220.203.50 - - [11/Jan/2009:04:26:27 -0500] "GET /seacoos_data/html_tables/html_tables/usgs.021720709.wq.htm HTTP/1.0" 200 213 "http://www.carocoops.org/seacoos_data/html_tables/html_tables/" "Wget/1.10.2 (Red Hat modified)"

my $date_yesterday = `date +%d/%b/%Y --date='1 day ago'`;
chomp $date_yesterday;
my ($day,$month,$year) = split(/\//, $date_yesterday);

@ARGV = glob 'log/*.log';

my ($total_count,$hit_count,$ip_ignore_count,$agent_ignore_count,$page_ignore_count,$referer_ignore_count);

use DBI;
my $dbname = '/usr2/prod/buoys/perl/apachestats/web_stats.db';
my $path_batch_insert = 'perl /var/www/cgi-bin/microwfs/batch_insert.pl';

open (SQL_OUT, ">web_stats_latest.sql");

###########################################################

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);


##################
while (my $input_file = shift @ARGV) {
print "$input_file\n";
open(LOGFILE, "$input_file");

foreach my $line (<LOGFILE>) {

my @record = split(/\s+/, $line);

my $date = @record[3];
#only tracking within date range
#if (!($date =~ /^\[$day\/$month\/$year/ )) { next; }

#only tracking successful page returns
my $return_code = @record[8];
$total_count++;

if ($return_code eq '200') {
#print "ok! $date\n";
$hit_count++;

my $ip = @record[0];

#my ($http_page,$http_args) = split(/\?/,@record[6]);
my ($http_page) = escape_literals(@record[6]);
#filtering out minor http args in page tracking
my $temp_http_page = '';
my @temp_array = split(/\&/,$http_page);
while (@temp_array) {
	my $element = shift @temp_array;

	#remove
	if ($element =~ /BBOX/i) { next; }
	if ($element =~ /HEIGHT/i) { next; }
	if ($element =~ /WIDTH/i) { next; }
	if ($element =~ /TIME_STAMP/i) { next; }
	if ($element =~ /FILE/i) { next; }
	if ($element =~ /OFFSET/i) { next; }
	if ($element =~ /OVERPASS/i) { next; }

	#substitute
	if ($element =~ /phpBB2/i) { $temp_http_page = 'phpbb2&'; @temp_array = (); next; }
	if ($element =~ /bb\/index/i) { $temp_http_page = 'phpbb2&'; @temp_array = (); next; }
	if ($element =~ /twiki/i) { $temp_http_page = 'twiki&'; @temp_array = (); next; }
	#temporary fix - want to show obs_types
	if ($element =~ /hourly/i) { $temp_http_page = 'secoora_hourly&'; @temp_array = (); next; }

	$temp_http_page .= $element."&";
}
chop($temp_http_page);
$http_page = $temp_http_page;

####
#time like [13/Jan/2009:09:29:55 - convert to db timestamp format
my $page_time = @record[3];
my $page_time_year = substr($page_time,8,4);

my $page_time_month = substr($page_time,4,3);
my $temp_var = `date --date='1 $page_time_month' +%m`; chomp $temp_var;
$page_time_month = $temp_var;

my $page_time_day = substr($page_time,1,2);
my $page_time_hour = substr($page_time,13,2);
my $page_time_minute = substr($page_time,16,2);
$page_time = "$page_time_year-$page_time_month-$page_time_day\T$page_time_hour:$page_time_minute:00";
#print $page_time."\n";
####

my $referer = @record[10];
my ($referer_page,$referer_args) = split(/\?/,$referer);

my @record_quotes = split(/\"/, $line);
my $agent = escape_literals(@record_quotes[5]);

        #only track initial starting page, not subsequent page hits, ignored, etc
        if (&search_array($ip, @ip_ignore)) { $ip_ignore_count++; next; }
        if (&search_array($agent, @agent_ignore)) { $agent_ignore_count++; next; }
        if (&search_array($http_page, @page_ignore)) { $page_ignore_count++; next; }
        if (&search_array($referer_page, @referer_ignore)) { $referer_ignore_count++; next; }

####
#db processing

	#insert ip
        $sql = qq{ SELECT row_id,ip from ip_info where ip = '$ip' };
        #print $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();
        my ($ip_row_id,$ip_lkp) = $sth->fetchrow_array;

        if ($ip_lkp) {} #print "$ip_lkp\n"; 
        else {
                print "ip $ip not found - inserting\n";
        
                $sql = qq{ INSERT into ip_info(row_entry_date,ip) values (datetime('now'),'$ip'); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                $sql = qq{ SELECT last_insert_rowid(); };
                $sth = $dbh->prepare( $sql );
                $sth->execute();
        	($ip_row_id) = $sth->fetchrow_array;
		#print "insert ip_row_id:$ip_row_id\n";
				
	}

        #insert agent
        $sql = qq{ SELECT row_id,agent from agent_info where agent = '$agent' };
        #print "agent:".$sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();
        my ($agent_row_id,$agent_lkp) = $sth->fetchrow_array;

        if ($agent_lkp) {} #print "$agent_lkp\n";           
        else {
                print "agent $agent not found - inserting\n";

                $sql = qq{ INSERT into agent_info(row_entry_date,agent) values (datetime('now'),'$agent'); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                $sql = qq{ SELECT last_insert_rowid(); };
                $sth = $dbh->prepare( $sql );
                $sth->execute();
        	($agent_row_id) = $sth->fetchrow_array;
        }

        #insert page
        $sql = qq{ SELECT row_id,page from page_info where page = '$http_page' };
        #print $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();
        my ($page_row_id,$page_lkp) = $sth->fetchrow_array;

        if ($page_lkp) {} #print "$page_lkp\n";
        else {
                print "page $http_page not found - inserting\n";

                $sql = qq{ INSERT into page_info(row_entry_date,page) values (datetime('now'),'$http_page'); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                $sql = qq{ SELECT last_insert_rowid(); };
                $sth = $dbh->prepare( $sql );
                $sth->execute();
        	($page_row_id) = $sth->fetchrow_array;
        }

        #insert referer
        $sql = qq{ SELECT row_id,referer from referer_info where referer = '$referer_page' };
        #print $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();
        my ($referer_row_id,$referer_lkp) = $sth->fetchrow_array;

        if ($referer_lkp) {} #print "$referer_lkp\n";
        else {
                print "referer $referer_page not found - inserting\n";

                $sql = qq{ INSERT into referer_info(row_entry_date,referer) values (datetime('now'),'$referer_page'); };
                #print $sql."\n";
                $sth = $dbh->prepare( $sql );
                $sth->execute();

                $sql = qq{ SELECT last_insert_rowid(); };
                $sth = $dbh->prepare( $sql );
                $sth->execute();
        	($referer_row_id) = $sth->fetchrow_array;
        }


        #insert cross_ref
        $sql = qq{ INSERT into cross_ref_info(ip_id,page_date,page_id,referer_id) values ($ip_row_id,'$page_time',$page_row_id,$referer_row_id); };
        #print $sql."\n";
	print SQL_OUT $sql."\n";
        $sth = $dbh->prepare( $sql );
        $sth->execute();


} #if return_code 200(successful) 

} #foreach line/record
} #while log file

print "total_hits:".$total_count."\n";
print "successful_hits:".$hit_count."\n";
print "ip_ignore:".$ip_ignore_count."\n";
print "agent_ignore:".$agent_ignore_count."\n";
print "page_ignore:".$page_ignore_count."\n";
print "referer_ignore:".$referer_ignore_count."\n";

my $good_hits = $hit_count-$ip_ignore_count-$agent_ignore_count-$page_ignore_count-$referer_ignore_count;
print "good_hits:".$good_hits."\n";

close (LOGFILE);
close (SQL_OUT);

exit 0;

########################

sub search_array {

my $search_term = shift @_;
my @search_array = @_;

foreach  my $search_page (@search_array) {
        if ($search_term =~ $search_page) { return 1; }
}

return 0;
}

#--------------------------------------------------------------------
#                   escape_literals
#--------------------------------------------------------------------
# Must make sure values don't contain problem chars for SQL,etc
sub escape_literals {
my $str = shift;
#$str =~ s/</&lt;/gs;
#$str =~ s/>/&gt;/gs;
#$str =~ s/&/&amp;/gs;
$str =~ s/"/&quot;/gs;
$str =~ s/'/&#39;/gs;
$str =~ s/%/&#pt;/gs; #not correct, but official included percent sign also
return ($str);
}

