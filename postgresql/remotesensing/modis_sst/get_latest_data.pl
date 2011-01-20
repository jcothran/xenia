#!/usr/bin/perl 

use LWP::Simple;
use POSIX qw(strftime);
use Time::Local;
use Cwd;

require "../juliandatefunctions.pl";

my $working_dir = getcwd;
my $layer_name  = 'modis_sst';
my $table_name  = 'timestamp_lkp';
my $scratch_dir = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name;
my $dest_dir    = '/home/xeniaprod/feeds/remotesensing/'.$layer_name;  
my $fetch_logs   = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name.'/fetch_logs';
my $product_id = 1;


my $psql_command = '/usr/bin/psql -U xeniaprod -d xenia -h 129.252.37.90 -c';

my $two_weeks_ago = time - 60*60*24*14;

`rm -f $scratch_dir/*`;

@dir_urls = (
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/intermediate/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$yesterdayJulian/1km/pass/final/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/intermediate/",
  "http://cyclops.marine.usf.edu/modis/level3/husf/fullpass/$currentYear/$todayJulian/1km/pass/final/"
  #'http://modis.marine.usf.edu/products/fullpass/sst/'
);

my $dirSortOptions = "\?C=M;O=D";


#Get rid of any db entries older than 2 weeks
#Get rid of any db entries older than 2 weeks
print("Delete entries older than 2 weeks.\n");
my $sql = 'DELETE FROM timestamp_lkp WHERE product_id=' . $product_id . ' AND pass_timestamp < now() - interval \'15 days\';';
print( "$sql\n" );
`$psql_command "$sql"`;


foreach (@dir_urls) {
  my $url = $_;
  #Add the directory sort options.
  $this_dir_url = "$url$dirSortOptions";


  print "$this_dir_url\n";
  do('get_latest_listing.pl');

  # get rid of duplicates
  @latest = sort keys %{ {map {$_, 1} @latest} };

  foreach (@latest) {
    $latest_file = $_;
    ($content_type, $document_length, $modified_time, $expires, $server) = head("$url/$latest_file");
    print "  $latest_file\n     ";
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
    $this_underline_timestamp = $yyyy.'_'.$mm.'_'.$dd.'_'.$hh.'_'.$mi;
    $this_files_epoch_time = timelocal(00,$mi,$hh,$dd,$mm-1,$yyyy);
    if ($this_files_epoch_time >= $two_weeks_ago) 
    {
      my $destFilename = $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png';
      if (open(LAST_FETCH,"$fetch_logs/$latest_file")) 
      {
        $last_fetch_time = <LAST_FETCH>;
        print 'file last modified on record  = '.scalar localtime($last_fetch_time)."\n     ";
        chop($last_fetch_time);
        if ($modified_time > $last_fetch_time) 
        {
          $last_fetch_time = <LAST_FETCH>;
          print 'file last modified on record  = '.scalar localtime($last_fetch_time)."\n     ";
          chop($last_fetch_time);
          if( $modified_time > $last_fetch_time ) 
          {
            downloadFile($url, $latest_file, $destFilename, $this_underline_timestamp);
            print LAST_FETCH $modified_time;
          }
          else 
          {
            print 'not downloaded';
          }        
        }
      }
      else 
      {
        downloadFile($url, $latest_file, $destFilename, $this_underline_timestamp);
      }      
      print "\n     ".'file last modified            = '.scalar localtime($modified_time)."\n";
      $cmd = "touch $fetch_logs/$latest_file";
      print("$cmd\n");
      `$cmd`;
      $cmd = "echo '$modified_time' > $fetch_logs/$latest_file";
      `$cmd`;
      print("$cmd\n");
    }
    else 
    {
      print '  not downloaded (file too old '.scalar(localtime($this_files_epoch_time)).')'."\n";
      last;
    }
  }
}
sub downloadFile
{
  my ( $url, $latest_file, $destFilename, $this_underline_timestamp ) = @_;
  print "downloaded\n";
  print( "SrcFile: $url/$latest_file DestFile: $destFilename\n" );
  getstore("$url/$latest_file", $destFilename );

  # make it properly transparent
  print("Setting transparency.\n");
  $cmd = '/usr/bin/gm mogrify -transparent "rgb(1,1,1)" ' . $destFilename;          
  `$cmd`;
  print( "$cmd\n" );

  $cmd = 'cp -f '
    .$destFilename
    .' '
    .$dest_dir;
  `$cmd`;
  print( "$cmd\n" );

  $cmd = 'cp -f '
    . $working_dir .'/.'.$layer_name.'.wld'
    .' '.$dest_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.wld';
  `$cmd`;
  print( "$cmd\n" );

  $sql = "insert into $table_name "
         ."( row_entry_date, "
         ."row_update_date, " 
         ."product_id, "
         ."pass_timestamp, "
         ." filepath ) "
         ."values( timestamp without time zone '$this_date $this_time', "
         ."timestamp without time zone '$this_date $this_time', "
         ."$product_id, "
         ."timestamp without time zone '$this_date $this_time', "
         .'\''.$layer_name.'/'.$layer_name.'_'.$this_underline_timestamp.'.png\''
         . ');';

  print( "$sql\n" );
  `$psql_command "$sql"`
}