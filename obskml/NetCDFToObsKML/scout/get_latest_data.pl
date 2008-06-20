#!/usr/bin/perl 

use LWP::Simple;

# qs needs its own individual cycle
my $qs_only = @ARGV[0];

#12/5/05 Payne Seal changed all http://nccoos.unc.edu to http://nemo.isis.unc.edu per Sara Haines
if (length($qs_only) <= 0) {
  @dir_urls = (
    ##'http://nccoos.unc.edu/data/nos/proc_data/latest_v2.0'
    'http://nemo.isis.unc.edu/data/nos/proc_data/latest_v2.0/'
    ,'http://seacoos.skio.peachnet.edu/proc_data/latest_v2.0'
    ##,'http://nccoos.unc.edu/data/nws_metar/proc_data/latest_v2.0'
    ,'http://nemo.isis.unc.edu/data/nws_metar/proc_data/latest_v2.0/'
    ,'http://trident.baruch.sc.edu/usgs_data'
    ,'http://trident.baruch.sc.edu/storm_surge_data/latest'
    ,'http://trident.baruch.sc.edu/storm_surge_data/netcdf_latest'
    ,'http://seacoos.marine.usf.edu/data/seacoos_rt_v2'
    ,'http://oceanlab.rsmas.miami.edu/ELWX5/v2'
    ,'http://aigeann.ucsc.edu/cimtLatest'
    ##,'http://nccoos.unc.edu/data/nc-coos/latest_v2.0'
    ,'http://nemo.isis.unc.edu/data/nc-coos/latest_v2.0/'
    ##,'http://iwave.rsmas.miami.edu/wera/efs/data'
    ,'http://oceanlab.rsmas.miami.edu/wera'
    ##,'http://ak.aoos.org/seacoos/codar'
    ,'http://www.cormp.org/data'
    ##'http://www.cormp.org/data'
  );
}
else {
  @dir_urls = (
   #'http://trident.baruch.sc.edu/po.daac_data/OVW'
  );
  $qs_prefix = 'qs_';
}

foreach (@dir_urls) {
  $this_dir_url = $_;

  print "$this_dir_url\n";
  do('get_latest_listing.pl');

  foreach (@latest) {
    $latest_file = $_;
    ($content_type, $document_length, $modified_time, $expires, $server) =
      head("$this_dir_url/$latest_file");
    print "  $latest_file\n     ";
    $latest_file_filter = $_;
    $latest_file_filter =~ s/-/_/g;
    if (open(LAST_FETCH,"./fetch_logs/$latest_file")) {
      $last_fetch_time = <LAST_FETCH>;
      print 'file last modified on record  = '.scalar localtime($last_fetch_time)."\n     ";
      chop($last_fetch_time);
      if ($modified_time > $last_fetch_time) {
        print 'downloaded';
        getstore("$this_dir_url/$latest_file","/home/scscout/sc/obs/2.0/".$qs_prefix."data/$latest_file");
      }
      else {
        print 'not downloaded';
      }
    }
    else {
      print 'downloaded';
      getstore("$this_dir_url/$latest_file",lc("/home/scscout/sc/obs/2.0/".$qs_prefix."data/$latest_file"));
    }
    print "\n     ".'file last modified            = '.scalar localtime($modified_time)."\n";
    $cmd = "touch ./fetch_logs/$latest_file";
    `$cmd`;
    $cmd = "echo '$modified_time' > ./fetch_logs/$latest_file";
    `$cmd`;
  }
}
