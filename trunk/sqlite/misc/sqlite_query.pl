#sqlite_query.pl

use strict;
use DBI;

#####################
#config

#the below file assumes a text file with each line containing the resultset output filename and sql query separated by tab character
my $query_file = './query.txt';

#resultset filenames are appended to so that a query spanning several db files might append to the same resultfile

#####################

my ($dbh,$sth);

open(QUERY_FILE,"$query_file");

while (my $query_line = <QUERY_FILE>) {

if ($query_line =~ /^#/ || $query_line =~ /^\s/) { next; }
#print $query_line;

my ($filename_resultset,$dbname,$sql) = split(/\t/,$query_line);
print "filename_resultset:$filename_resultset\tdb:$dbname\tsql:$sql";

open(FILE_OUT, ">>$filename_resultset");

#note: tried using the ATTACH statement with a union between databases, but query performance was slow(ignoring indexes?)
#so for now recommending concatenating multiple query resulset files from separate queries

$dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                    { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}

$sth = $dbh->prepare($sql);
$sth->execute();

#example: selecting into variables from the returned row array directly
#while (my ($my_var1,$my_var2,...) = $sth->fetchrow_array) {

while (my @array_line = $sth->fetchrow_array) {
	#print "@array_line\n";
	print FILE_OUT "@array_line\n";
}

close(FILE_OUT);

} #while query_file

$sth->finish();
undef $sth; # to stop "closing dbh with active statement handles"
            # http://rt.cpan.org/Ticket/Display.html?id=22688
$dbh->disconnect();

exit 0;

