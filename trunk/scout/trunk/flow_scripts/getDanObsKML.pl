#getDanObsKML.pl
#this scripts moves the latest obskml files from their http locations to a local server file reference and gives an error if unsuccessful

use LWP::Simple;

$date_now = `date +%Y-%m-%dT%H:%M:%S`;
chomp($date_now);

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/ndbc/ndbc_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/ndbc/ndbc_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/nws/nws_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/nws/nws_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/nos/nos_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/nos/nos_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/usf/usf_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/usf/usf_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/skio/skio_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/skio/skio_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/cormp/cormp_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/cormp/cormp_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/carocoops/carocoops_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/carocoops/carocoops_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

#my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/seacoos/seacoos_latest_obskml.zip';
#my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/seacoos/seacoos_latest_obskml.zip');
#if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/scnms/scnms_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/scnms/scnms_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

my $obskml_url = 'http://129.252.139.56/~dramage/obskml/feeds/nccoos/nccoos_latest_obskml.zip';
my $content = getstore($obskml_url, '/var/www/html/obskml/feeds/nccoos/nccoos_latest_obskml.zip');
if ($content ne '200') { print "$date_now : Failed get $obskml_url\n"} ;

#print "ok $obskml_url $content\n";

exit 0;
