#!/usr/local/bin/perl

use strict;
use DBI;
use Net::SMTP;

#if $range_top is defined this is plot only
my ($dbname,$email_flag,$hour_offset,$status_file,$status_file_latest,$image_file,$title,$range_top) = @ARGV;

#config
#see 'tail' command and secondary file below
#

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","",{RaiseError => 0}) or die "Couldn't open dbfile.";
$dbh->func(60000, 'busy_timeout'); #timeout to wait in milliseconds, 60000 = 60 sec

my $flag_alert = 0;
my $org_count_listing = '';
my $org_count_total;

my ($sth,$sql);

my $m_date_start = `date +%Y-%m-%dT%H:%M:%S --date='$hour_offset hour'`;
chomp($m_date_start);
my $m_date_start_plot = `date +"%m %d %Y %H:%M" --date='$hour_offset hour'`;
chomp($m_date_start_plot);

my $hour_offset_stop = $hour_offset + 1;
my $m_date_stop = `date +%Y-%m-%dT%H:%M:%S --date='$hour_offset_stop hour'`;
chomp($m_date_stop);

#my $m_date_start = '2008-08-22T14:00:00';
#my $m_date_stop = '2008-08-22T15:00:00';

my @org_array = qw(carocoops cormp seacoos usf ndbc nos nws nerrs usgs);

if (!($range_top)) {
open(FILE_CHART,">>$status_file");
print FILE_CHART "$m_date_start_plot\t";

foreach my $org (@org_array) {
$sql = qq{ select count(*) from multi_obs where platform_handle like '$org.%' and m_date >= '$m_date_start' and m_date < '$m_date_stop'; }; 
#print $sql."\n";
$sth = $dbh->prepare($sql);
die "Couldn't prepare" unless defined $sth;
$sth->execute();
#print "ERROR:".$sth->err."\n" if $sth->err;
my ($org_count) = $sth->fetchrow_array;

$org_count_listing .= "$org = $org_count\n";
$org_count_total += $org_count;
print FILE_CHART "$org_count\t";

if ($org ne 'carocoops' && $org ne 'seacoos') {  #chronically low count org - ignore or remove from condition
	if ($org_count < 1) { $flag_alert = 1; }
}

}
        
$sth->finish;
undef $sth;  #have to undef $sth to keep from always referencing old pass
$dbh->disconnect();

print FILE_CHART "\n";
close(FILE_CHART);
`tail -n 216 $status_file > $status_file_latest`;
} #if !($range_top)

#plot status
#`perl plot_status.pl $status_file_latest $image_file "$title" $range_top`;
require "graphCommon.lib";
require "status.lib";

my $break_interval = 3700;
my $y_units = 'Sensor Count';
my $dir_path = "/var/www/html/obskml/scripts/$image_file";
my $size_x = 1800;
my $size_y = 300;

insert_break_interval($status_file_latest, $break_interval);
my_graph($status_file_latest, $title, $y_units, $dir_path, \@org_array, $size_x, $size_y, $range_top);

################################################

my $smtp = Net::SMTP->new("inlet.geol.sc.edu");
my ($message_importance,$message_subject,$send_message,@to_array);

if ($flag_alert == 1) {
print "flag alert \n";
$message_importance = "Importance: high\n";
$message_subject = "Subject: $title Alert - Low Sensor Count";
@to_array = qw(jcothran\@asg.sc.edu jeremy.cothran\@gmail.com dan\@inlet.geol.sc.edu);
}
else { #normal status - ignored by exit statement below (no email currently sent for normal)
$message_importance = "Importance: low\n";
$message_subject = "Subject: $title Status";
@to_array = qw(jcothran\@asg.sc.edu);
}

my $send_message = <<"END_OF_LIST";
$message_subject
Sensor records for time interval
start_time = $m_date_start
stop_time = $m_date_stop

$org_count_listing

count total = $org_count_total

see graph at http://carocoops.org/obskml/scripts/$image_file

END_OF_LIST

my $send_list = <<"END_OF_LIST";
This message was sent to the following persons:
@to_array
END_OF_LIST
$send_message = $send_message.$send_list;

print "$send_message";

#shortcut exit if no_email flag or no alert flag
if (($email_flag eq 'no_email') || ($flag_alert == 0)) { exit 0; }

#print "mailing\n";
$smtp->mail("jcothran\@asg.sc.edu");

$smtp->to(@to_array, { SkipBad => 1 });  #smtp->to is a scoped variable - had problems(no email) earlier with scope visibility
#$send_message = "DISREGARD THIS MESSAGE - THIS IS A TEST MESSAGE ONLY \n".$send_message;

$smtp->data();
$smtp->datasend($message_importance);
$smtp->datasend($message_subject);
$smtp->datasend("\n");
$smtp->datasend($send_message);
$smtp->dataend();
$smtp->quit();

exit 0;

