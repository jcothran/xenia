#!/usr/bin/perl

#Note that eval is used(always a security issue) in this code for the conversion using the xml file lookup so the xml file should only come from the server internally

#$output options are graph(the graph plot only), webpage(graph plot and data table in html page), table(data table in html page) and download(a download csv file of the data table).

#unit_conversion=en will do a lookup for the default english conversion lookup 'standard_uom_en'

require "graphCommon.lib";
require "graphSingleLine.lib";

use strict;
use DBI;
use XML::XPath;

#open (DEBUG,">/tmp/ms_tmp/debug.txt");

#load database and path info
my $env = shift; 
my $xp_env = XML::XPath->new(filename => "../environment_xenia_$env.xml");

#print DEBUG "$env ";

#load graph info
my $xp_graph = XML::XPath->new(filename => '../environment_xenia_graph.xml');

my $db_name   = $xp_env->findvalue('//db/name');
#print "db_name: $db_name\n";
my $db_user   = $xp_env->findvalue('//db/user');
my $db_passwd = $xp_env->findvalue('//db/passwd');
my $db_table  = $xp_env->findvalue('//db/table');

my $dir_tmp = $xp_env->findvalue('//path/dir_tmp');
my $http_base = $xp_env->findvalue('//path/http_base');
my $http_xenia_graph = $xp_env->findvalue('//path/http_xenia_graph');
my $use_archive = $xp_env->findvalue('//use/archive');

#establish database connection
my ($dbh,$sth,$sql);
$dbh = DBI->connect("dbi:SQLite:dbname=$db_name", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}

##

my $time_query = shift;
#print DEBUG "$time_query ";
my ($time_interval, $from_date, $to_date);
if ($time_query eq 'time_last') {
	$time_interval = shift;	
	#print DEBUG "$time_interval ";
}
elsif ($time_query eq 'time_date') {
	$from_date = shift;
	$to_date = shift;
}

my ($sensor_id, $column_value, $qc_clause, $time_zone_arg, $output, $range_min, $range_max, $title, $y_title, $unit_conversion, $break_interval, $size_x, $size_y) = @ARGV;

#print DEBUG "$sensor_id $column_value $qc_clause $time_zone_arg $output $range_min $range_max $title $y_title $unit_conversion $break_interval $size_x $size_y";

#close (DEBUG);


#get m_type_id info for selecting graph options
$sql = qq{ select m_type_id from sensor where row_id = $sensor_id; }; 
#print "sql:".$sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my ($m_type_id) = $sth->fetchrow_array;
#print "m_type_id: $m_type_id \n";
if (!($m_type_id)) { &exit_no_data; }

####get organization/platform info for html display later

$sql = qq{ select platform_id from sensor where row_id = $sensor_id; };
#print "sql:".$sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my ($platform_id) = $sth->fetchrow_array;
if (!($platform_id)) { &exit_no_data; }

#assumes fixed platform
$sql = qq{ select platform_handle,organization_id,url,fixed_longitude,fixed_latitude from platform where row_id = $platform_id; };
#print "sql:".$sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my ($platform_handle,$organization_id,$platform_url,$platform_long,$platform_lat) = $sth->fetchrow_array;
if (!($platform_handle)) { &exit_no_data; }

$sql = qq{ select short_name,url from organization where row_id = $organization_id; };
#print "sql:".$sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my ($org_name,$org_url) = $sth->fetchrow_array;
if (!($org_name)) { &exit_no_data; }

####


if ($column_value eq 'default') { $column_value = $xp_env->findvalue('//db/column_value'); }
if ($qc_clause eq 'default') { $qc_clause = $xp_env->findvalue('//db/qc_clause'); }

if ($range_min eq 'default') { $range_min = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/range_min'); }
if ($range_max eq 'default') { $range_max = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/range_max'); }
if ($title eq 'default') { $title = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/title'); }
if ($y_title eq 'default') { $y_title = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/y_title'); }
my $with_clause = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/with_clause'); 
if ($break_interval eq 'default') { $break_interval = int($xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/break_interval')); }
if ($size_x eq 'default') { $size_x = int($xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/size_x')); }
if ($size_y eq 'default') { $size_y = int($xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/size_y')); }

my $standard_name = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/standard_name');
my $conversion_formula;
if ($unit_conversion ne 'default') {
	if ($unit_conversion eq 'en') { #lookup standard english conversion
		$unit_conversion = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/standard_uom_en');
	}
	my $standard_uom = $xp_graph->findvalue('//observation_list/observation[@m_type_id="'.$m_type_id.'"]/standard_uom');
	$y_title = $xp_graph->findvalue('//unit_conversion_list/unit_conversion[@id="'.$standard_uom.'_to_'.$unit_conversion.'"]/y_title');
	$conversion_formula = $xp_graph->findvalue('//unit_conversion_list/unit_conversion[@id="'.$standard_uom.'_to_'.$unit_conversion.'"]/conversion_formula');
}

#print $db_host.":".$db_name.":".$db_user.":".$db_passwd."\n";

###########################
# time zone setting
###########################

#if you want to reference other time zones, add them here
my %time_zone = ('GMT',0,'EST',-5,'EDT',-4,'CST',-6,'CDT',-5,'MST',-7,'MDT',-6,'PST',-8,'PDT',-7);
#print 'time_zone='.$time_zone{$time_zone_arg}."\n";

#daylight savings time consideration
my ($temp_sec,$temp_min,$temp_hour,$temp_mday,$temp_mon,$temp_year,$temp_wday,$temp_yday,$isdst) = localtime(time);

#correct $time_zone_arg depending on whether $isdst is set for EASTERN,etc
if ($time_zone_arg eq 'EASTERN') {if ($isdst) { $time_zone_arg = 'EDT'; } else { $time_zone_arg = 'EST'; }}
if ($time_zone_arg eq 'CENTRAL') {if ($isdst) { $time_zone_arg = 'CDT'; } else { $time_zone_arg = 'CST'; }}
if ($time_zone_arg eq 'MOUNTAIN') {if ($isdst) { $time_zone_arg = 'MDT'; } else { $time_zone_arg = 'MST'; }}
if ($time_zone_arg eq 'PACIFIC') {if ($isdst) { $time_zone_arg = 'PDT'; } else { $time_zone_arg = 'PST'; }}
#print 'time_zone_arg='.$time_zone_arg."\n";
#print 'time_zone='.$time_zone{$time_zone_arg}."\n";

my $time_subtract = -1*$time_zone{$time_zone_arg};

###########################

#'Mon dd hh:mi PM' more readable time format
#'MM DD YYYY hh24:mi'  military time format

#the below should be faster queries making use of the multi_obs index
#if ($time_query eq 'time_last') { $sql = qq{ SELECT TO_CHAR((m_date - interval '$time_subtract hours'), 'MM-DD-YYYY hh24:mi'), $column_value FROM $db_table where sensor_id = $sensor_id and m_date > datetime('now','-1 day') and $column_value >= $range_min and $column_value <= $range_max $qc_clause and m_type_id = $m_type_id order by m_date; }; }

#FIX - the below m_date is truncated to 19 characters as sqlite doesn't properly recognize timezone suffixes in time manipulations
#      I've changed the database population code to not include timezone(assume GMT) so the substr should be able to go away
if ($time_query eq 'time_last') { $sql = qq{ SELECT strftime('%m-%d-%Y %H:%M',datetime(substr(m_date,1,19),'-$time_subtract hours')), $column_value FROM $db_table where sensor_id = $sensor_id and m_date > datetime('now','$time_interval') and $column_value >= $range_min and $column_value <= $range_max $qc_clause order by m_date; }; }

elsif ($time_query eq 'time_date') { $sql = qq{ SELECT strftime('%m-%d-%Y %H:%M',datetime(substr(m_date,1,19),'-$time_subtract hours')), $column_value FROM $db_table where sensor_id = $sensor_id and datetime(m_date) >= datetime('$from_date 00:00:00','$time_subtract hours') and datetime(m_date) <= datetime('$to_date 00:00:00','$time_subtract hours') and $column_value >= $range_min and $column_value <= $range_max $qc_clause order by m_date; }; }

#print "sql:".$sql."\n";
$sth = $dbh->prepare( $sql );
#$sth->execute() || print $sth->errstr;
$sth->execute();

my $graph_image_filename = 'xenia_'.int(rand(10000000)).'.png';
my $graph_image_file = $dir_tmp.$graph_image_filename;
my $graph_data_file;

my $random_num = int(rand(10000000));
my $csv_filename = $platform_handle.':'.$standard_name.':'.$random_num.'.csv';
#print "csv_filename:$csv_filename\n";
my $csv_file = $dir_tmp.$csv_filename;

my $data_table;

if  ($output eq 'download') {
	open (CSV_FILE,">$csv_file");
	print CSV_FILE "Date/Time($time_zone_arg),$title($y_title)\n";
}
elsif ($output eq 'graph' || $output eq 'webpage') {	
	$graph_data_file = $dir_tmp.'gnuplot_'.int(rand(10000000));
	#print "$graph_data_file\n";
	open (OUTFILE,">$graph_data_file");
}

my $conversion_val;
while ( my @row = $sth->fetchrow_array ) {
#while ( my ($m_date,$m_value) = $sth->fetchrow_array ) {
	if (!(@row)) { &exit_no_data; }

	if ($unit_conversion eq 'default') {
    		$conversion_val = @row[1];
	}
	else {
    		#unit conversion using supplied equation(e.g. celcius to fahrenheit)
    		my $conversion_string = $conversion_formula;
    		$conversion_string =~ s/var1/@row[1]/g;
    		$conversion_val = eval $conversion_string;
	}

	if ($output eq 'download') {
    		print CSV_FILE @row[0].",".$conversion_val."\n";
	}
	elsif ($output eq 'graph' || $output eq 'webpage') {	
    		print OUTFILE @row[0]."\t".$conversion_val."\n";
	}
	

	if ($output eq 'webpage' || $output eq 'table') {
		$data_table .= qq(<tr><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2">@row[0]</font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2">$conversion_val</font></td></tr>);
	}

}

#print "debug10\n";

if  ($output eq 'download') {
	close CSV_FILE;
}
elsif ($output eq 'graph' || $output eq 'webpage') {	
	close OUTFILE;
}

$sth->finish;
undef $sth; # to stop "closing dbh with active statement handles"
            # http://rt.cpan.org/Ticket/Display.html?id=22688

$dbh->disconnect();

if ($output eq 'graph' || $output eq 'webpage') {	
insert_break_interval($graph_data_file, $break_interval);

my $time_zone = '-'.$time_subtract;
my_graph($graph_data_file, $title, $y_title, $with_clause, $graph_image_file, $time_zone_arg, $size_x, $size_y);
}

#determine whether we return a graph, webpage or download

if ($output eq 'graph') {
	print $graph_image_filename;
}

elsif ($output eq 'webpage' || $output eq 'table') {
my $html_filename = 'xenia_'.int(rand(10000000)).'.html';
my $html_file = $dir_tmp.$html_filename;
open (HTML_FILE,">$html_file");

my $archive_link;
if ($use_archive eq 'yes') { $archive_link = "<a href=\"$http_base\platform/$platform_handle\/archive\" target=\"new\">Archive</a>"; }

my $html_content = <<"END_OF_FILE";
<title>Query Results</title>
<body>
<form name='details'>
<table bgcolor="#999999" border="0" cellspacing="1" cellpadding="4">
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"><b>Platform</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2"><a href="$platform_url" target="new">$platform_handle</a></font></td>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
<b>Organization</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2"><a href="$org_url" target="new">$org_name</a></font></td>
</tr>
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
<b>Lon, Lat</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2">$platform_long E, $platform_lat N</font></td>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2">
<b>Additional Data</b></font></td><td nowrap bgcolor="#ffffff"><font face="Arial, Helvetica, sans-serif" size="2">$archive_link</font></td>
</tr>
</table>
</br>
<table bgcolor="#999999" width="100%" border="0" cellspacing="1" cellpadding="4">
END_OF_FILE

if ($output eq 'webpage') {

my $other_times = $http_xenia_graph."environment=$env&sensor_id=$sensor_id&column_value=$column_value&qc_clause=$qc_clause&time_zone_arg=$time_zone_arg&output=$output&range_min=$range_min&range_max=$range_max&title=$title&y_title=$y_title&unit_conversion=$unit_conversion&break_interval=$break_interval&size_x=$size_x&size_y=$size_y";

$html_content .= <<"END_OF_FILE";
<tr><td colspan="4" bgcolor="#C1D8E3"><font face="Arial, Helvetica, sans-serif" size="2"><b>Observations 
<a href="$other_times&time_interval=-1 day">1</a>
<a href="$other_times&time_interval=-2 days">2</a>
<a href="$other_times&time_interval=-3 days">3</a>
<a href="$other_times&time_interval=-7 days">7</a>
<a href="$other_times&time_interval=-14 days">14</a>
 day(s) before</b></font></td></tr>
<tr><td colspan="4" bgcolor="#ffffff"><img src="/ms_tmp/$graph_image_filename"></td></tr>
END_OF_FILE

}

$html_content .= <<"END_OF_FILE";
<tr>
<td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"> <b>Date/Time ($time_zone_arg)</b></font></td><td nowrap bgcolor="#E2EFF5"><font face="Arial, Helvetica, sans-serif" size="2"> <b>$title ($y_title)</b></font></td>
</tr>
$data_table
</table>
</form>
</body>
END_OF_FILE

print HTML_FILE $html_content;

close (HTML_FILE);
print $html_filename;
}

elsif ($output eq 'download') {
	print $csv_filename;
}

exit 0;

sub exit_no_data {
	$sth->finish;
	undef $sth; # to stop "closing dbh with active statement handles"
            # http://rt.cpan.org/Ticket/Display.html?id=22688

	$dbh->disconnect();

        if ($output ne 'download') {
                #printf("Not enough recent measurements to produce graph\n");
                `cp no_data.png $dir_tmp`;
                print 'no_data.png';
	}
        else {
                `cp no_data.csv $dir_tmp`;
                print 'no_data.csv';
        }

        exit 0;
}

