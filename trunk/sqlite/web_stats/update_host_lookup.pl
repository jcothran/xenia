#!/usr/bin/perl
use strict;

#CONFIG BEGIN
my $dbname = '/usr2/prod/buoys/perl/apachestats/web_stats.db';
my $min_ip_count = 5; #don't change ignore status if <= this number
#CONFIG END

###########################################################

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
my ($sql,$sth);


####
#db processing

$sql = qq{ SELECT ip_id,COUNT(*)
    FROM cross_ref_info
    GROUP BY ip_id
    HAVING COUNT(*) > $min_ip_count
    ORDER BY COUNT(*) DESC; };
#print $sql."\n";
$sth = $dbh->prepare( $sql );
$sth->execute();
my $ref = $sth->fetchall_arrayref;
foreach my $row ( @{$ref} ) {
    #print "@$row\n";
    my ($ip_id,$count) = @$row;
    #print "$ip_id $count\n";

    $sql = qq{ update ip_info set ignore = 1 where row_id = $ip_id; };
    #print $sql."\n";
    $sth = $dbh->prepare( $sql );
    $sth->execute();
}

exit 0;

