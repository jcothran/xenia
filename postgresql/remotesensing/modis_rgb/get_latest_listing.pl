#!/usr/local/bin/perl
# Last modified:  Time-stamp: <2003-09-25 11:45:33 haines>
#
# Abstract:  get listing of files with "latest.nc" in name from http index, 
#
# Usage:  % get_latest_listing.pl [-d]
#
# Author: Sara Haines (2003-09) 

# Processing:
#    (1) Screen scrape http index listing sent by server for all HREF data
#    (2) further limit it by glob

# if debugging requested print messages to STDOUT
if (grep /[debug|DEBUG|d]/, @ARGV) {
  $debug = 0;
}

# add libraries needed for this function
use POSIX qw(strftime);

# 
$now = strftime("%Y:%m:%d %H:%M:%S",gmtime);
if ($debug) { print "\n==== Starting: $now UTC ==== Perl Version: $]\n"; }

$dods_url = $this_dods_url;
$dir_url = $this_dir_url;

$time_stamp = strftime("%Y%j",gmtime);
# $time_stamp = strftime("%Y",gmtime);

$common = 'MODIS.*.fullpass.rgb.png'; 

# @latest = get_index_match($dods_url, $common);

# print "------------------------------" . "\n";
# print "Common file names scraped from " . "\n";
# print "$dods_url:". "\n";
# for (@latest) { 
#    print($_, "\n"); 
# }

@latest = get_index_match($dir_url, $common);

# print "------------------------------" . "\n";
# print "Common file names scraped from " . "\n";
# print "$dir_url:". "\n";
# for (@latest) { 
#    print($_, "\n"); 
# }
# ----------------------------------------------------------------
# subroutines
# ----------------------------------------------------------------

sub get_index_match {
# Processing:
#    (0) Get html document--no checking done to make sure this is an index
#            or that it's live and accessible.  (future upgrade?)
#    (1) Screen scrape http index listing sent by server for all HREF data
#    (2) further limit it by regexp match to pattern desired by user

    # add libraries needed for this function
    use LWP::Simple;
    use URI;

    
    # passed parameters
    my ($path, $pattern) = @_;
    my $isFTP = 0;

    #2014-04-22 DWR
    #We need to check the URL to see if it is an FTP site or an HTML directory.
    my $uriObj = URI->new($path);
    print("Connection type: " . $uriObj->scheme . "\n");
    if($uriObj->scheme eq 'ftp')
    {
      $isFTP = 1;
    }

    # escape any regexp chars given by user 
    # (so $pattern can't be constructed regexp)
    # $pattern =~ s/([\*\.\<\>\{\}\[\]\^\$\|\+\?\\\/])/\\$1/g;

    # (0) Get html document
    $doc = get($path);
    print "$doc\n";
    #2014-04-22 DWR
    #We need to check the URL to see if it is an FTP site or an HTML directory.
    if($isFTP)
    {
        print "Processing FTP listing.\n";

        my @fileLines = split('\n', $doc);
        foreach $fileLine (@fileLines)
        {
          my @parts = split(" ", $fileLine);
          my $fileName = $parts[-1];
          print("$fileName\n");
          push(@matched, $fileName);
        }
    }
    else
    {
        print "Processing HTML listing.\n";

        # some other possible html scrapes
        # @all_href = $doc =~ m{href=(.*?)>}gi;
        # @all_href = $doc =~ m{href\s*=\s*(.*?)>}gi;

        # (1) Screen scrape http for href lines
        @all_href = $doc =~ m{href\s*=[\s|"]*(.*?)[\s|"]*>}gi;


        # (2) further limit with users pattern
        @matched = grep /$pattern$/, @all_href;
    }
    foreach(@matched)
    {
        print "Matched: $_\n";
    }

    return @matched;

} # sub glob_html
# ----------------------------------------------------------------
