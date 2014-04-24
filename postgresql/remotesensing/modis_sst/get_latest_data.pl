#!/usr/bin/perl

use LWP::Simple;
use POSIX qw(strftime);
use Time::Local;
use Cwd;

require "../juliandatefunctions.pl";

my $working_dir = getcwd;
my $layer_name  = 'modis_sst';
my $table_name  = 'timestamp_lkp';
my $table_name_2  = 'raster_'.$layer_name;

my $scratch_dir = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name;
my $dest_dir    = '/home/xeniaprod/feeds/remotesensing/'.$layer_name;
my $dest_dir_2    = '/nautilus_usr2/maps/seacoos/data/usf/'.$layer_name;

my $fetch_logs   = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name.'/fetch_logs';
my $product_id = 1;

my $psql_command = '/usr/bin/psql -U xeniaprod -d xenia -h 129.252.37.90 -c';
my $psql_command_2 = '/usr/bin/psql -U postgres -d sea_coos_obs -h nautilus.baruch.sc.edu -c';

my $two_weeks_ago = time - 60*60*24*14;

`rm -f $scratch_dir/*`;

my $yyyy_dot_mm = strftime("%Y.%m",gmtime);

@dir_urls = (
  "ftp://imars.marine.usf.edu/modis/imars/intermediate/pass/1km/sst/seacoos/$yyyy_dot_mm"
  #"http://cyclops.marine.usf.edu/modis/level3/husf/seacoos"
  #"http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/intermediate/",
  #"http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/final/",
  #"http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/intermediate/",
  #"http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/final/"
);

my $dirSortOptions = "\?C=M;O=D";
my $FtpFilenameConvention = 1;

#Get rid of any db entries older than 2 weeks
#Get rid of any db entries older than 2 weeks
print("Delete entries older than 2 weeks.\n");
my $sql = 'DELETE FROM timestamp_lkp WHERE product_id=' . $product_id . ' AND pass_timestamp < now() - interval \'15 days\';';
print( "$sql\n" );
`$psql_command "$sql"`;


foreach (@dir_urls) {
  my $url = $_;
  #Add the directory sort options.
  #$this_dir_url = "$url$dirSortOptions";
  #DWR 2014-03-06
  #Using FTP url.
  $this_dir_url = "$url";

  print "$this_dir_url\n";
  do('get_latest_listing.pl');

  # get rid of duplicates
  @latest = sort keys %{ {map {$_, 1} @latest} };

  foreach (@latest) {
    $latest_file = $_;
    ($content_type, $document_length, $modified_time, $expires, $server) = head("$url/$latest_file");
    #Filename is formatted: AQUA.20140408.1824.seacoos.sst.png
    my @filenameParts = split(/\./, $latest_file);
    #2014-04-22 DWR
    #Only continue if it's a png file and not a thumbnail(has brws in the filename).
    if($filenameParts[-1] eq 'png' and !(grep $_ eq 'brws', @filenameParts))
    {
        print "$latest_file processing\n";
        #2014-04-22 DWR
        #Unsure on where we are supposed to pull files, for now I use the $FtpFilenameConvention to
        #switch between the old style file name processing and what I see in the ftp directory.
        my $yyyy, $mm, $dd, $hh, $mi;
        if($FtpFilenameConvention == 0)
        {
            $latest_file_filter = $_;
            $latest_file_filter =~ s/-/_/g;
            # stuff.yyyyjul.hhmmss.stuff
            $latest_file_filter =~ /.*\.(\d\d\d\d)(\d\d\d)\.(\d\d)(\d\d)(\d\d)\..*/;
            ($yyyy, $jul, $hh, $mi, $ss) = ($1, $2, $3, $4, $5);

            #Subtract a day off since the date command on the machine that originally ran the script would accept
            #01/00/yyyy as a valid date.
            $jul = $jul - 1;
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
        #print("Time stamp: $this_underline_timestamp\n");
        $this_files_epoch_time = timelocal(00,$mi,$hh,$dd,$mm-1,$yyyy);
        #print("File epoch time: $this_files_epoch_time\n");

        if ($this_files_epoch_time >= $two_weeks_ago)
        {
          my $destFilename = $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png';
          if (open(LAST_FETCH,"$fetch_logs/$latest_file"))
          {
            $last_fetch_time = <LAST_FETCH>;
            print "$latest_file fetch log last modified on record  = ".scalar localtime($last_fetch_time)."\n";
            chop($last_fetch_time);
            if ($modified_time > $last_fetch_time)
            {
              $last_fetch_time = <LAST_FETCH>;
              print "$latest_file fetch log last modified on record  = ".scalar localtime($last_fetch_time)."\n";
              chop($last_fetch_time);
              if( $modified_time > $last_fetch_time )
              {
                downloadFile($url, $latest_file, $destFilename, $this_underline_timestamp);
                print LAST_FETCH $modified_time;
              }
              else
              {
                print "$latest_file not downloaded\n";
              }
            }
          }
          else
          {
            downloadFile($url, $latest_file, $destFilename, $this_underline_timestamp);
          }
          print "$latest_file fetch log last modified            = ".scalar localtime($modified_time)."\n";
          $cmd = "touch $fetch_logs/$latest_file";
          print("$cmd\n");
          `$cmd`;
          $cmd = "echo '$modified_time' > $fetch_logs/$latest_file";
          `$cmd`;
          print("$cmd\n");
        }
        else
        {
          print "$latest_file not downloaded (file too old ".scalar(localtime($this_files_epoch_time)).')'."\n";
          #last;
        }
     }
     else
     {
         print "$latest_file skipping file Type: $filenameParts[-1] \n";
     }
     print "$latest_file finished processing\n";
  }
}
sub downloadFile
{
  my ( $url, $latest_file, $destFilename, $this_underline_timestamp ) = @_;
  print "$latest_file downloaded\n";
  print( "SrcFile: $url/$latest_file DestFile: $destFilename\n" );
  getstore("$url/$latest_file", $destFilename );

  # make it properly transparent
  print("Setting transparency.\n");
  #$cmd = '/usr/bin/gm mogrify -transparent "rgb(1,1,1)" ' . $destFilename;
  $cmd = '/usr/bin/gm mogrify -transparent "rgb(0,0,0)" ' . $destFilename;
  `$cmd`;
  print( "$cmd\n" );

  $cmd = 'cp -f '
    .$destFilename
    .' '
    .$dest_dir;
  `$cmd`;
  print( "$cmd\n" );

  $cmd = 'cp -f '
    .$destFilename
    .' '
    .$dest_dir_2;
  `$cmd`;

  $cmd = 'cp -f '
    . $working_dir .'/.'.$layer_name.'.wld'
    .' '.$dest_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.wld';
  `$cmd`;
  print( "$cmd\n" );

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

  $sql = "insert into $table_name_2 (pass_timestamp, local_filename)"
    .' values (timestamp without time zone '
    ."'$this_date $this_time'"
    .','
    .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
    .');';
  `$psql_command_2 "$sql"`;

}
