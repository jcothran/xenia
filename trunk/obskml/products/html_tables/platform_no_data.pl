#!/usr/bin/perl
#platform_no_data.pl

use DBI;
use strict;

#####################
#config
my $db_host  = 'db_server';
my $db_name   = 'db_xenia_wx';
my $db_user   = 'postgres';
my $db_passwd = '';
my $target_dir = './html_tables';

#####################
##read sql query results into hash

my $dbh = DBI->connect ("dbi:Pg:dbname=$db_name;host=$db_host","$db_user","$db_passwd");
if(!defined $dbh) {die "Cannot connect to database!\n";}

#note: the below sql will get observations from the previous day -- now() - interval '1 day'
#note: make sure support table m_type_display_order is populated -- see http://carocoops.org/twiki_dmcc/pub/Main/XeniaTableSchema/m_type_display_order.sql

my $sql = qq{
  select platform_handle,url,long_name from platform
  order by platform_handle;
};

my $sth = $dbh->prepare($sql);
$sth->execute();

while (my (
     $platform_handle
    ,$platform_url
    ,$platform_desc
  ) = $sth->fetchrow_array) {

  #making the '.' separator substition for older '_' separator
  $platform_handle =~ s/_/./g ;
  $platform_handle = lc($platform_handle) ;

  #print "$platform_handle:$platform_url:$platform_desc\n\n";

my $html_content = <<"END_OF_FILE";
    <a name="$platform_handle"></a>
    <h3>
      <a href="$platform_url" target=new onclick="">$platform_desc</a>
    </h3>
    <table cellpadding="2" cellspacing="2">
      <caption>Platform not currently reporting</caption>
    </table>
END_OF_FILE

open (FILE_HTML,">html_tables/$platform_handle.htm");
print FILE_HTML $html_content;
close (FILE_HTML);

}
$sth->finish;
$dbh->disconnect();

exit 0;
