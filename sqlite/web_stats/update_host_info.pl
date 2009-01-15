#!/usr/bin/perl
use strict;

use DBI;
my $dbname = '/usr2/prod/buoys/perl/apachestats/web_stats.db';
#my $path_batch_insert = 'perl /var/www/cgi-bin/microwfs/batch_insert.pl';

###########################################################

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);


####
#db processing

$sql = qq{ SELECT row_id,ip from ip_info where dns_lookup is null and ignore = 1; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $ref = $sth->fetchall_arrayref;
foreach my $row ( @{$ref} ) {
    #print "@$row\n";
    my ($row_id,$ip) = @$row;
    #print "$row_id $ip\n";

    my $this_host = `host $ip`; 
    my @host_string = split(/\s+/,$this_host);
    my $host_name = @host_string[-1];
    #print $host_name;

    $sql = qq{ update ip_info set dns_lookup = '$host_name' where row_id = $row_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();

}


exit 0;

