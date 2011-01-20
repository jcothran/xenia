#!/usr/bin/perl 

use LWP::Simple;
use POSIX qw(strftime);

my $layer_name  = 'oi_sst';
my $table_name  = 'timestamp_lkp';
my $scratch_dir = '/home/xeniaprod/tmp/remotesensing/usf/'.$layer_name;
my $dest_dir    = '/home/xeniaprod/feeds/remotesensing/'.$layer_name;  
my $fetch_logs   = '/home/xeniaprod/tmp/remotesensing/usf/oi_sst/fetch_logs';

my $psql_command = '/usr/bin/psql -U xeniaprod -d xenia -h 129.252.37.90 -c';

`rm -f $scratch_dir/*`;

$yyyy_mm_dd  = strftime("%Y_%m_%d",gmtime);

#These will cause the directory listing to be sorted descending.
@dir_urls = (
  #changed per Aida Azcarate 10/19/2005
  #'http://ocg6.marine.usf.edu/helber/ocg/'
  'http://ocgweb.marine.usf.edu/Products/OI/oidat/'
);

my $dirSortOptions = "\?C=M;O=D";
#my $dirSortOptions = "";
my $product_id = 0;


#Get rid of any db entries older than 2 weeks
print("Delete entries older than 2 weeks.\n");
my $sql = 'DELETE FROM timestamp_lkp WHERE product_id=' . $product_id . ' AND pass_timestamp < now() - interval \'15 days\';';
print( "$sql\n" );
`$psql_command "$sql"`;



#Get current date, since the remote directory has all files from all years we don't want to run through anything older than the current
#year/month. We subtract off 30 days worth of seconds to get us a 30 day window.
my $cutoffTime = time() - ( 30 * 24 * 60 * 60 );
foreach (@dir_urls) {
  my $url = $_;
  #Add the directory sort options.
  $this_dir_url = "$url$dirSortOptions";
  
  print "$this_dir_url\n";
  do('get_latest_listing.pl');
  
  foreach (@latest) {
    $latest_file = $_;
    ($content_type, $document_length, $modified_time, $expires, $server) = head("$url/$latest_file");
    print "  $latest_file\n     ";
    #The files are sorted in descending order, if we hit a file older than our cut off time, then we quit scanning the files.
    if( $modified_time > $cutoffTime )
    {
      $latest_file_filter = $_;
      $latest_file_filter =~ s/-/_/g;
      # stuff.yyyymmdd.stuff
      $latest_file_filter =~ /.*\.(\d\d\d\d)(\d\d)(\d\d)\..*/;
      ($this_date, $this_time) = ("$1-$2-$3", "17:30");
      $this_underline_timestamp = "$1_$2_$3_17_30";
      my $destFilename = $scratch_dir.'/'.$layer_name.'_'.$this_underline_timestamp.'.png';
      if (open(LAST_FETCH,"$fetch_logs/$latest_file"))
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
      else 
      {
        downloadFile($url, $latest_file, $destFilename, $this_underline_timestamp);
      }
      print "\n     ".'file last modified            = '.scalar localtime($modified_time)."\n";
      $cmd = "touch $fetch_logs/$latest_file";
      `$cmd`;
      $cmd = "echo '$modified_time' > $fetch_logs/$latest_file";
      `$cmd`;
     }
     else
     {
       print( "File is older than the month cutoff, terminating loop.\n" );
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
    .$dest_dir.'/.'.$layer_name.'.wld'
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
  `$psql_command "$sql"`;
}