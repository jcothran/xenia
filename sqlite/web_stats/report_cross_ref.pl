#!/usr/bin/perl
use strict;

use DBI;
my $dbname = '/usr2/prod/buoys/perl/apachestats/web_stats.db';
#my $path_batch_insert = 'perl /var/www/cgi-bin/microwfs/batch_insert.pl';

my $min_page_count = 5;  #must be at least this number of page hits to be included in report
my $min_ip_count = 1;  #must be at least this number of ip hits to be included in report
my $min_ip_count = 0;  #must be at least this number of ip hits to be included in report
my $min_ref_count = 0;  #must be at least this number of ref hits to be included in report

my ($date_start,$date_end,$date_clause);
=comment
#report in below date range on cross_ref_info.page_date
$date_start = '2009-01-13T06:00:00';
$date_end = '2009-01-13T07:00:00';
$date_clause = "page_date >= '$date_start' and page_date <= '$date_end'";
=cut
#no date range applied
$date_clause = "page_date is not null";

open (FILE_PAGE,">page_summary.txt");
open (FILE_PAGE_IP,">page_ip_summary.txt");
open (FILE_PAGE_REF,">page_ref_summary.txt");
open (FILE_IP,">ip_summary.txt");
open (FILE_REF,">ref_summary.txt");

###########################################################

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);


####################################
#get summary info
$sql = qq{ select count(*) from cross_ref_info; };
$sth = $dbh->prepare( $sql );
$sth->execute();
my ($total_page_count) = $sth->fetchrow_array;

if (!($date_start)) {
$sql = qq{ select min(page_date) from cross_ref_info; };
$sth = $dbh->prepare( $sql );
$sth->execute();
($date_start) = $sth->fetchrow_array;

$sql = qq{ select max(page_date) from cross_ref_info; };
$sth = $dbh->prepare( $sql );
$sth->execute();
($date_end) = $sth->fetchrow_array;
}

my $summary_line = "total_pages:$total_page_count\tdate_start:$date_start\tdate_end:$date_end\tmin_page_count:$min_page_count\tmin_ip_count:$min_ip_count\tmin_ref_count:$min_ref_count\n\n";
print FILE_PAGE $summary_line;
print FILE_PAGE_IP $summary_line;
print FILE_PAGE_REF $summary_line;
print FILE_IP $summary_line;
print FILE_REF $summary_line;

####################################
#do page select

$sql = qq{ SELECT page_id,COUNT(*)
    FROM cross_ref_info where $date_clause
    GROUP BY page_id
    HAVING COUNT(*) >= $min_page_count
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $arrayref_page = $sth->fetchall_arrayref;
foreach my $row_page ( @{$arrayref_page} ) {
    #print "@$row_page\n";
    my ($page_id,$count) = @$row_page;
    #print "$page_id $count\n";

    $sql = qq{ select page from page_info where row_id = $page_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($page_lkp) = $sth->fetchrow_array;
    print FILE_PAGE "$count\t$page_lkp\n";
    print FILE_PAGE_IP "#######################################################\n$count\t$page_lkp\n";
    print FILE_PAGE_REF "#######################################################\n$count\t$page_lkp\n";

####################################
#do ip subselect

my $low_ip_counts = 0;
$sql = qq{ SELECT ip_id,COUNT(*)
    FROM cross_ref_info where page_id = $page_id and $date_clause
    GROUP BY ip_id
    HAVING COUNT(*) > 0
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $arrayref_ip = $sth->fetchall_arrayref;
foreach my $row_ip ( @{$arrayref_ip} ) {
    #print "@$row_ip\n";
    my ($ip_id,$count) = @$row_ip;
    #print "$ip_id $count\n";

    if ($count > $min_ip_count) {  #not reporting below $min_ip_count, summarized report after loop
    $sql = qq{ select ip,dns_lookup from ip_info where row_id = $ip_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($ip_lkp,$dns_lookup) = $sth->fetchrow_array;
    print FILE_PAGE_IP "$count\t$ip_lkp\t$dns_lookup\n";
    }
    else { $low_ip_counts++; }

} #foreach $row_ip
if ($low_ip_counts > 0) { print FILE_PAGE_IP "$low_ip_counts\tlow_counts(<=$min_ip_count)\n"; }

####################################
#do ref subselect

my $low_ref_counts = 0;
$sql = qq{ SELECT referer_id,COUNT(*)
    FROM cross_ref_info where page_id = $page_id and $date_clause
    GROUP BY referer_id
    HAVING COUNT(*) > 0
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $arrayref_referer = $sth->fetchall_arrayref;
foreach my $row_referer ( @{$arrayref_referer} ) {
    #print "@$row_referer\n";
    my ($referer_id,$count) = @$row_referer;
    #print "$referer_id $count\n";

    if ($count > $min_ref_count) {  #not reporting below $min_ref_count, summarized report after loop
    $sql = qq{ select referer from referer_info where row_id = $referer_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($referer_lkp) = $sth->fetchrow_array;
    print FILE_PAGE_REF "$count\t$referer_lkp\n";
    }
    else { $low_ref_counts++; }

} #foreach $row_ref
if ($low_ref_counts > 0) { print FILE_PAGE_REF "$low_ref_counts\tlow_counts(<=$min_ref_count)\n"; }


} #foreach $row_page

####################################
#do ip select

$sql = qq{ SELECT ip_id,COUNT(*)
    FROM cross_ref_info where $date_clause
    GROUP BY ip_id
    HAVING COUNT(*) >= $min_ip_count
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $arrayref_ip = $sth->fetchall_arrayref;
foreach my $row_ip ( @{$arrayref_ip} ) {
    #print "@$row_ip\n";
    my ($ip_id,$count) = @$row_ip;
    #print "$ip_id $count\n";

    $sql = qq{ select ip,dns_lookup from ip_info where row_id = $ip_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($ip_lkp,$dns_lookup) = $sth->fetchrow_array;
    print FILE_IP "$count\t$ip_lkp\t$dns_lookup\n";

} #foreach $row_ip


####################################
#do ref select - (note that the below terms in below section for page referer and array reference can get confusing)

$sql = qq{ SELECT referer_id,COUNT(*)
    FROM cross_ref_info where $date_clause
    GROUP BY referer_id
    HAVING COUNT(*) >= $min_ref_count
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $arrayref_page = $sth->fetchall_arrayref;
foreach my $row_ref ( @{$arrayref_page} ) {
    #print "@$row_ref\n";
    my ($referer_id,$count) = @$row_ref;
    #print "$referer_id $count\n";

    $sql = qq{ select referer from referer_info where row_id = $referer_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
    my ($referer_lkp) = $sth->fetchrow_array;
    print FILE_REF "$count\t$referer_lkp\n";

} #foreach $row_ref

close(FILE_PAGE);
close(FILE_PAGE_IP);
close(FILE_PAGE_REF);
close(FILE_IP);
close(FILE_REF);

exit 0;

