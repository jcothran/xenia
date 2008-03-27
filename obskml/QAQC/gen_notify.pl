#!/usr/bin/perl
#script: gen_notify.pl
#Author: Jeremy Cothran (jeremy.cothran[at]gmail.com)
#Organization: Carocoops/SEACOOS
#Date: August 10, 2007
#script description
#generates a notification csv file output from test results csv input

use strict;
use XML::LibXML;
use Getopt::Long;
#Define to allow the script to be tested on another machine with local data.
#Set to 0 if running in a Linux/Unix environment. This mostly deals with how file paths are handled, as well as a couple
#of shell commands.
use constant MICROSOFT_PLATFORM => 0;
use constant USE_PRINT_DEBUGS   => 1;
 
######################
#read the earlier test_results_notify.csv file into a hash
my %CommandLineOptions;

GetOptions( \%CommandLineOptions,
            "WorkingDir=s",
            "EmailList=s",
            "MsgList=s");

my $output_name   = $CommandLineOptions{"WorkingDir"};   
my $strEmailList = $CommandLineOptions{"EmailList"};
my $strMessageList = $CommandLineOptions{"MsgList"};
if( !defined $output_name || !defined $strEmailList || !defined $strMessageList )
{
  die ("Missing required field(s).\n".
        "Command Line format: -WorkingDir -EmailList -MsgList.\n". 
        "-WorkingDir the path to the directory where the previously generated test_results.csv exists.\n".
        "-EmailList provides the fully qualifed path to the properly formatted xml file which details out the email list.\n".
        "-MsgList provides the fully qualifed path to the properly formatted xml file which details out the message list.\n");
}    
#my $output_name = $ARGV[0];
#my $strEmailList = $ARGV[1];        # Specifys which email list xml file to use.
#my $strMessageList = $ARGV[2];      # Specifys which message xml file to use.

if(!MICROSOFT_PLATFORM)
{
  open(NOTIFY_FILE,"$output_name/test_results_notify.csv");
}
else
{ 
  open(NOTIFY_FILE,"$output_name\\test_results_notify.csv"); 
}
#note that the below hashing convention assumes each element contains only one type of child element except at the terminals
my %HoH = ();
my $rHoH = \%HoH;

foreach my $line (<NOTIFY_FILE>)
{
	my ($test_profile_id,$notify_time) = split(/,/,$line);
	chomp($notify_time);

  $HoH{$test_profile_id}{'notify_time'} = $notify_time;
  $HoH{$test_profile_id}{'notify_status'} = 0; #0 = don't notify, 1 = do notify
}

close(NOTIFY_FILE);

######################
#read the latest test_results.csv file and modify hash notify_status accordingly

if(!MICROSOFT_PLATFORM)
{
  open(CSV_FILE,"$output_name/test_results.csv") || die "ERROR: Unable to open file: $output_name/test_results.csv\n";
}
else
{
  open(CSV_FILE,"$output_name\\test_results.csv") || die "ERROR: Unable to open file: $output_name\\test_results.csv\n"; 
}
my $test_profile_id = '';
foreach my $line (<CSV_FILE>)
{
  #if( USE_PRINT_DEBUGS )
  #{
	# print $line;
  #}

	my $notify_flag = 0; #false = 0, true = 1
	
	my @elements = split(/,/,$line);
	if (@elements[0] =~ /Test_Profile/ )
	{ 
	  $test_profile_id = substr(@elements[0],13); 
	  next;
	}
	else
	{
		if ($elements[2] =~ /lagging/)
		{ 
 			$notify_flag = 1; 
		}
	}
			
	if (@elements <= 1) 
	{ 
	  $notify_flag = 1; 
	}

	shift(@elements);  #shift the platform id out of array.
	shift(@elements);  #shift the pltform url out of the array.
	shift(@elements);  #shift the time out of the array.

	while (@elements)
	{

		my $test_result = shift(@elements);
		my $m_value = shift(@elements);
		
		chomp($test_result);
		chomp($m_value);
		#print ":".$test_result.":\n";
		if ($test_result eq 'fail high')
		{ 
		  $notify_flag = 1; 
		}
		if ($test_result eq 'fail low')
		{
		  $notify_flag = 1; 
		}
		if ($test_result eq 'missing')
		{ 
		  $notify_flag = 1; 
		}
		if ($test_result eq 'missing all')
		{ 
		  $notify_flag = 1; 
		}
	}
	if ($notify_flag == 1)
	{
    $HoH{$test_profile_id}{'notify_status'} = 1;
	}
}

close(CSV_FILE);

######################
#write the latest test_results_notify.csv file from the hash, looking up notify time differences to see whether notification should occur and notify_time updated to now

#open xml file to lookup notification wait interval in seconds
my $xp_tests;
if( ! MICROSOFT_PLATFORM )
{
  $xp_tests = XML::LibXML->new->parse_file("$output_name/test_profiles.xml");
}
else
{
  $xp_tests = XML::LibXML->new->parse_file("$output_name\\test_profiles.xml"); 
}


if( ! MICROSOFT_PLATFORM )
{
  open(NOTIFY_FILE,">$output_name/test_results_notify.csv") || die "ERROR: Unable to open file: $output_name/test_results.csv\n";;
}
else
{
  open(NOTIFY_FILE,">$output_name\\test_results_notify.csv") || die "ERROR: Unable to open file: $output_name\\test_results.csv\n";;  
}

my $date_now;
if( ! MICROSOFT_PLATFORM )
{ 
  $date_now = `date +%s`;
}
else
{
  #NOTE: Using UnxUtils: http://sourceforge.net/project/showfiles.php?group_id=9328 to emulate the date function in windows.
  # Will need to adjust the path based on where you install them. 
  $date_now = `\\UnixUtils\\usr\\local\\wbin\\date.exe +%s`; 
}
chomp($date_now);

foreach $test_profile_id ( sort keys %{$rHoH} )
{
	my $notify_status = sprintf("%s",$rHoH->{$test_profile_id}{'notify_status'});
	my $notify_time = sprintf("%s",$rHoH->{$test_profile_id}{'notify_time'});

	my $new_notify_flag = 0;
	if ($notify_status == 1) 
	{
    #my $date_test = `date --date='$datetime' +%s`;
    #chomp($date_test);
    if( USE_PRINT_DEBUGS )
    {   
		  print "notify_time: $notify_time\n";
    }		
		if ($notify_time eq '')
		{ 
		  $new_notify_flag = 1; 
		}
		else
		{
			my $time_diff = $date_now - $notify_time;
			#lookup time_diff
			my $wait_interval = 0;
			foreach my $xp_test_profile ($xp_tests->findnodes('//testProfile')) 
			{
				my $xp_test_profile_id = sprintf("%s",$xp_test_profile->find('id'));
				if ($xp_test_profile_id eq $test_profile_id)
				{ $wait_interval = sprintf("%s",$xp_test_profile->find('notify/wait'))
				  
				}
			}
			if ($time_diff > $wait_interval)
			{
			 $new_notify_flag = 1; 
        if( USE_PRINT_DEBUGS )
        {		
  			 print "Notify: $test_profile_id. wait_interval = $wait_interval time_diff = $time_diff\n";
        }
			}
			else
		  {
  		  print "No Notification: $test_profile_id wait_interval = $wait_interval time_diff = $time_diff\n";		    
		  }
		}

		if ($new_notify_flag == 1)
		{
    	$notify_time = $date_now;

			#carry out notification

			my ($emailGroup,$emailMessage);
			#Loops through each test profile and grabs the who and what to email out.
			foreach my $xp_test_profile ($xp_tests->findnodes('//testProfile'))
			{
				my $xp_test_profile_id = sprintf("%s",$xp_test_profile->find('id'));
				if ($xp_test_profile_id eq $test_profile_id)
				{ 
					$emailGroup = sprintf("%s",$xp_test_profile->find('notify/emailGroup'));
					$emailMessage = sprintf("%s",$xp_test_profile->find('notify/emailMessage'));
				}
			}
    	#`cd /usr2/prod/buoys/perl/mail; perl send_email.pl --group $emailGroup --message $emailMessage`;
      if( !MICROSOFT_PLATFORM )
      {
      	`perl send_email.pl --message_list $strMessageList --email $strEmailList --group $emailGroup --message $emailMessage`;
      }
      else
      {
      	 `perl send_email.pl --message_list $strMessageList --email $strEmailList --group $emailGroup --message $emailMessage`;
        
      }
		}

	}

  print NOTIFY_FILE "$test_profile_id,$notify_time\n";
}

close(NOTIFY_FILE);

exit 0;
