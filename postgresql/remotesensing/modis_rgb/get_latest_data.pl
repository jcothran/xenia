#!/usr/bin/perl 

use LWP::Simple;
use POSIX qw(strftime);
use Time::Local;

require "../juliandatefunctions.pl";

my $layer_name  = 'modis_rgb';
my $table_name  = 'timestamp_lkp';
my $table_name_2  = 'raster_'.$layer_name;
my $scratch_dir = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name;
my $nautilus_dir_base = '/usr2/maps/seacoos/data/usf';
my $dest_dir    = '/home/xeniaprod/feeds/remotesensing/'.$layer_name;  
my $dest_dir_2          = '/nautilus_usr2/maps/seacoos/data/usf/'.$layer_name;  
my $passes_in_composite     = 4;
my $composite_sec_tolerance = 60*60*24*2;

my $psql_command = '/usr/bin/psql -U xeniaprod -d xenia -h 129.252.37.90 -c';
my $psql_command_2 = '/usr/bin/psql -U postgres -d sea_coos_obs -h nautilus.baruch.sc.edu -c';

my $fetch_logs   = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name.'/fetch_logs';
my $product_id = 2;

my $FtpFilenameConvention = 0;

#Get rid of any db entries older than 2 weeks
print("Delete entries older than 2 weeks.\n");
my $sql = 'DELETE FROM timestamp_lkp WHERE product_id=' . $product_id . ' AND pass_timestamp < now() - interval \'15 days\';';
print( "$sql\n" );
`$psql_command "$sql"`;

`rm -f $scratch_dir/*`;


my $two_weeks_ago = time - 60*60*24*14;

`rm -f $scratch_dir/*`;

@dir_urls = (
  #"http://cyclops.marine.usf.edu/modis/level3/husf/seacoos/$currentYear/$todayJulian/4km/pass/final/"
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/intermediate/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/final/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/intermediate/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/final/"
);

foreach (@dir_urls) {
  $this_dir_url = $_;

  print "$this_dir_url\n";
  do('get_latest_listing.pl');

  # get rid of duplicates
  @latest = sort keys %{ {map {$_, 1} @latest} };

  foreach (@latest) {
    $latest_file = $_;
    ($content_type, $document_length, $modified_time, $expires, $server) =
      head("$this_dir_url/$latest_file");

    #Filename is formatted: AQUA.20140408.1824.seacoos.sst.png
    my @filenameParts = split(/\./, $latest_file);
    #2014-04-22 DWR
    #Only continue if it's a png file.
    if($filenameParts[-1] eq 'png')
    {
        print "Processing  $latest_file\n     ";
        my $yyyy, $mm, $dd, $hh, $mi;
        if($FtpFilenameConvention == 0)
        {
            $latest_file_filter = $_;
            $latest_file_filter =~ s/-/_/g;
            # stuff.yyyyjul.hhmmss.stuff
            $latest_file_filter =~ /.*\.(\d\d\d\d)(\d\d\d)\.(\d\d)(\d\d)(\d\d)\..*/;
            ($yyyy, $jul, $hh, $mi, $ss) = ($1, $2, $3, $4, $5);
            $cmd = "/bin/date --date='01/00/$yyyy $jul days' +'%m %d'";
            $jul--;
            $cmd = "/bin/date --date='01/01/$yyyy $jul days' +'%m %d'";
            $res = `$cmd`;
            $res =~ /(\d*) (\d*)/;
            ($mm, $dd) = ($1, $2);
            ($this_date, $this_time) = ("$yyyy-$mm-$dd", "$hh:$mi");
        }
        else
        {
            #2014-04-22 DWR
            #The following block is new to handle the move from an HTTP to FTP access along with the
            #file name changes.
            #The date is stored in the filename like: yyyymmdd
            #print("Date part: $filenameParts[1]\n");
            my @dateParts = $filenameParts[1] =~ m/(\d\d\d\d)(\d\d)(\d\d)/;
            $yyyy = $dateParts[0];
            $mm = $dateParts[1];
            $dd = $dateParts[2];
            #The time is stored in the filename like: hhmm
            my @timeParts = $filenameParts[2] =~ m/(\d\d)(\d\d)/;
            $hh = $timeParts[0];
            $mi = $timeParts[1];

            ($this_date, $this_time) = ("$yyyy-$mm-$dd", "$hh:$mi");
            # End changes
        }
        $this_underline_timestamp = $yyyy.'_'.$mm.'_'.$dd.'_'.$hh.'_'.$mi;
        $this_files_epoch_time = timelocal(00,$mi,$hh,$dd,$mm-1,$yyyy);
        if ($this_files_epoch_time >= $two_weeks_ago)
        {
          if (open(LAST_FETCH,"$fetch_logs/$latest_file"))
          {
            next;
          }
          else
          {
            print "$latest_file downloaded\n";
            getstore("$this_dir_url/$latest_file",
              $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png');
            # make it properly transparent
            $cmd = '/usr/bin/gm mogrify -transparent "rgb(0,0,0)" '
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
            #`$cmd`;
            $sql = "insert into $table_name_2 (pass_timestamp, local_filename)"
              .' values (timestamp without time zone '
              ."'$this_date $this_time'"
              .','
              .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
              .');';
            `$psql_command_2 "$sql"`;


          #local - JTC - not doing composite at this time
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

          #local

            $composite = get('http://nautilus.baruch.sc.edu/seacoos_misc/build_composite.php'
              .'?raster_name='.$layer_name
              .'&raster_src_dir='.$nautilus_dir_base
              .'&raster_dest_dir_2='.$nautilus_dir_base.'/'.$layer_name.'_composite'
              .'&time_stamp='."$this_date $this_time"
              .'&total_passes='.$passes_in_composite
              .'&max_time_difference_sec='.$composite_sec_tolerance);
            if (!($composite =~ /-1/)) {
              $sql = "insert into $table_name_2".'_composite'." (pass_timestamp, local_filename)"
                .' values (timestamp without time zone '
                ."'$this_date $this_time'"
                .','
                .'\''.$layer_name.'_composite/'.$layer_name.'_composite_'.$this_underline_timestamp.'.png\''
                .');';
              `$psql_command_2 "$sql"`;
            }
            else
            {
                print "$latest_file not downloaded\n";
            }
          }
          print "$latest_file fetch log last modified            = ".scalar localtime($modified_time)."\n";
          $cmd = "touch $fetch_logs/$latest_file";
          `$cmd`;
          $cmd = "echo '$modified_time' > $fetch_logs/$latest_file";
          `$cmd`;
        } #if file < two weeks
        else
        {
          print "$latest_file not downloaded (file too old ".scalar(localtime($this_files_epoch_time)).')'."\n";
        }
     }
     else
     {
         print "$latest_file skipping file Type: $filenameParts[-1] \n";
     }
     print "$latest_file finished processing\n";
  } #latest files
} #dir_url
