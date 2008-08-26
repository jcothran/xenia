#!/usr/local/bin/perl

use strict;
use DBI;

#note we assume $sth->err returns a matching error string for sqlite, but for postgres,etc it may return an integer, etc

#expect full paths for below command line args
my ($dbname,$sql_file) = @ARGV;

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname","","",{RaiseError => 0}) or die "Couldn't open dbfile.";
$dbh->func(60000, 'busy_timeout'); #timeout to wait in milliseconds, 60000 = 60 sec

open(SQL_FILE,"$sql_file");

foreach my $sql (<SQL_FILE>) {
  #print "$sql\n";

  my $sth;
  my $error = 1; #assume error to force at least one pass
  while($error){
        $sth = $dbh->prepare($sql);
        die "Couldn't prepare" unless defined $sth;
        
        #print "Execute sth\n";
        $sth->execute();
        #print "ERROR:".$sth->err."\n" if $sth->err;
        
        #clear error flag if no error so can proceed
	$error = '';
        if ($sth->err =~ 'locked') { print $sth->err."\n"; $error = 1; }
        
        $sth->finish;
        undef $sth;  #have to undef $sth to keep from always referencing old pass
        #sleep 1;
  }
} #foreach $sql

$dbh->disconnect();

exit 0;

