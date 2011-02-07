#!/usr/bin/perl 

use LWP::Simple;
use POSIX qw(strftime);
use Time::Local;

my $layer_name  = 'avhrr_sst';
my $institution = 'USF Institute for Marine Remote Sensing (IMaRS)';
my $institution_url = 'http://imars.usf.edu';
my $title       = 'Advanced Very High Resolution Radiometer (AVHRR)';
my $table_name  = 'timestamp_lkp';
my $table_name_2  = 'raster_'.$layer_name;
my $scratch_dir = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name;
my $dest_dir    = '/home/xeniaprod/feeds/remotesensing/'.$layer_name;  
my $dest_dir_2    = '/nautilus_usr2/maps/seacoos/data/usf/'.$layer_name;  

my $psql_command = '/usr/bin/psql -U xeniaprod -d xenia -h 129.252.37.90 -c';
my $psql_command_2 = '/usr/bin/psql -U postgres -d sea_coos_obs -h nautilus.baruch.sc.edu -c';

my $fetch_logs   = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name.'/fetch_logs';
my $product_id = 3;

#Get rid of any db entries older than 2 weeks
print("Delete entries older than 2 weeks.\n");
my $sql = 'DELETE FROM timestamp_lkp WHERE product_id=' . $product_id . ' AND pass_timestamp < now() - interval \'15 days\';';
print( "$sql\n" );
`$psql_command "$sql"`;

my $two_weeks_ago = time - 60*60*24*14;

`rm -f $scratch_dir/*`;

$yyyy_dot_mm = strftime("%Y.%m",gmtime);

@dir_urls = (
  'http://www.imars.usf.edu/husf_avhrr/products/images/fullpass/'.$yyyy_dot_mm
);

@final_dods_urls = (
  'http://www.imars.usf.edu/dods-bin/nph-dods/husf_avhrr/FULL_PASS_HDF_SST/'.$yyyy_dot_mm
);
$final_suffix = 'usf.sst.hdf.html';

@auto_dods_urls = (
  'http://www.imars.usf.edu/dods-bin/nph-dods/husf_avhrr/FULL_PASS_HDF_SST/auto/'.$yyyy_dot_mm
);
$auto_suffix = 'auto.usf.sst.hdf.html';

$i = 0;

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
    # stuff.yyyymmdd.hhmm.stuff
    $latest_file_filter =~ /(.*)\.(\d\d\d\d)(\d\d)(\d\d)\.(\d\d)(\d\d).*/;
    $latest_file_prefix = $1;
    $latest_file_infix  = "$2$3$4.$5$6";
    ($this_date, $this_time) = ("$2-$3-$4", "$5:$6");
    $this_underline_timestamp = "$2_$3_$4_$5_$6";
    $this_files_epoch_time = timelocal(00,$6,$5,$4,$3-1,$2);
    if ($this_files_epoch_time >= $two_weeks_ago) {
      # Look for a DODS URL to match this image.
      # A final file is better than an auto file, so look for it first.
      if (head($final_dods_urls[$i].'/'.$latest_file_prefix.'.'.$latest_file_infix.'.'.$final_suffix)) {
        $dods_url = $final_dods_urls[$i].'/'.$latest_file_prefix.'.'.$latest_file_infix.'.'.$final_suffix;
      }
      elsif (head($auto_dods_urls[$i].'/'.$latest_file_prefix.'.'.$latest_file_infix.'.'.$auto_suffix)) {
        $dods_url = $auto_dods_urls[$i].'/'.$latest_file_prefix.'.'.$latest_file_infix.'.'.$auto_suffix;
      }
      else {
        $dods_url = 'None';
      }
      if (open(LAST_FETCH,"$fetch_logs/$latest_file")) { next; }
=comment
      if (open(LAST_FETCH,"$fetch_logs/$latest_file")) {
        $last_fetch_time = <LAST_FETCH>;
        print 'file last modified on record  = '.scalar localtime($last_fetch_time)."\n     ";
        chop($last_fetch_time);
        if ($modified_time > $last_fetch_time) {
            print 'downloaded';
          getstore("$this_dir_url/$latest_file",
            $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png');
          # make it properly transparent
          $cmd = '/usr/bin/gm mogrify -transparent "rgb(230,230,230)" '
            .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png';
          `$cmd`;
          $cmd = 'cp -f '
            .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png'
            .' '
            .$dest_dir_2;
          `$cmd`;
          $cmd = 'cp -f '
            .$dest_dir_2.'/.'.$layer_name.'.wld'
            .' '.$dest_dir_2.'/'.$layer_name.'_'.$this_underline_timestamp.'.wld';
          `$cmd`;

          $sql = "insert into $table_name_2 (pass_timestamp, local_filename)"
            .' values (timestamp without time zone '
            ."'$this_date $this_time'"
            .','
            .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
            .');';
          `$psql_command_2 "$sql"`;

	  ##local
          $cmd = 'cp -f '
            .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png'
            .' '
            .$dest_dir;
          `$cmd`;

  $sql = "insert into $table_name "
         ."( row_entry_date, "
         ."product_id, "
         ."pass_timestamp, "
         ." filepath ) "
         ."values( now(), "
         ."$product_id, "
         ."timestamp without time zone '$this_date $this_time', "
         .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
         . ');';
         print( "$sql\n" );
         `$psql_command "$sql"`;
	 ##local

        }
        else {
          print 'not downloaded';
        }
      }
=cut
      else {
        print 'downloaded';
        getstore("$this_dir_url/$latest_file",
          $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png');
        # make it properly transparent
        $cmd = '/usr/bin/gm mogrify -transparent "rgb(230,230,230)" '
          .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png';
        `$cmd`;
        $cmd = 'cp -f '
          .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png'
          .' '
          .$dest_dir_2;
        `$cmd`;
        $cmd = 'cp -f '
          .$dest_dir_2.'/.'.$layer_name.'.wld'
          .' '.$dest_dir_2.'/'.$layer_name.'_'.$this_underline_timestamp.'.wld';
        `$cmd`;
        $sql = "insert into $table_name_2 (pass_timestamp, local_filename)"
          .' values (timestamp without time zone '
          ."'$this_date $this_time'"
          .','
          .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
          .');';
        `$psql_command_2 "$sql"`;
  print( "$sql\n" );

	  ##local
          $cmd = 'cp -f '
            .$scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png'
            .' '
            .$dest_dir;
          `$cmd`;

  $sql = "insert into $table_name "
         ."( row_entry_date, "
         ."product_id, "
         ."pass_timestamp, "
         ." filepath ) "
         ."values( now(), "
         ."$product_id, "
         ."timestamp without time zone '$this_date $this_time', "
         .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
         . ');';
 
         print( "$sql\n" );
         `$psql_command "$sql"`;
	 ##local

      }
      print "\n     ".'file last modified            = '.scalar localtime($modified_time)."\n";
      $cmd = "touch $fetch_logs/$latest_file";
      `$cmd`;
      $cmd = "echo '$modified_time' > $fetch_logs/$latest_file";
      `$cmd`;

      # Run UPDATEs for the metadata.
      $sql = "update $table_name_2 set"
        ." institution = '$institution'"
        .', institution_url ='
        .'\''.'<a href='.$institution_url.' target=_blank>'.$institution_url.'</a>'.'\''
        .', institution_dods_url = '
        .'\''.'<a href='.$dods_url.' target=_blank>Click here</a>'.'\''
        .', title = '
        ."'$title'"
        .' where pass_timestamp ='
        .' timestamp without time zone '
        ."'$this_date $this_time'"
        .' and local_filename ='
        .'\''.$layer_name.'_'.$this_underline_timestamp.'.png\''
        .';';
      `$psql_command_2 "$sql"`;
    }
    else {
      print '  not downloaded (file too old '.scalar(localtime($this_files_epoch_time)).')'."\n";
    }
  }
  $i++;
}
