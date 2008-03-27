#!/usr/bin/perl
use strict;
use warnings;
use XML::XPath;
use Net::SMTP;
use Getopt::Long;
	
	#script that is called from call_email.pl and sends email depending on parameters in message_list.xml and email_list.xml
	my $testing =0;
	
	my %options;

	#`perl send_email.pl --p $platform_id --c $current_obs_value --a $obs_field --a $range_low --a $range_high --m $message_id --g $group_id --u $user_id --e email_list.xml --l message_list.xml`;		
	#`perl send_email.pl --platform $platform_id  --obs_field $obs_field --time_1 $time_1 --time_2 $time_2 --message $message_id --group $group_id --user $user_id --email email_list.xml --message_list message_list.xml`;		
	GetOptions(\%options, "test_type=s",
	                       "obs_value:f",
	                       "platform=s",
	                       "observation_id=s",
	                       "range_high:i",
	                       "range_low:i",
	                       "message=i", 
	                       "group=i", 
	                       "user:i",
	                       "email:s",
	                       "message_list:s",
	                       "time_1:s",
	                       "time_2:s",
	                       "value_1:f",
	                       "value_2:f",
	                       "delta_obs:i" );

	my ($message_id,$group_id,$user_id,$platform_id,$current_obs_value,$message_file,$email_file,$observation_id,$range_high,$range_low,$time_1,$time_2,$value_1,$value_2,$delta_obs);
	
	
	$platform_id = $options{'platform'};
	my $test_type = '';	
	#my $test_type= $options{'test_type'};	
	
	if ($test_type eq "range")
	{
		$range_high=$options{'range_high'};
		$range_low=$options{'range_low'};
		$current_obs_value=$options{'obs_value'};	
	}	
	
	if ($test_type eq "time_continuity")
	{
		$time_1 = $options{'time_1'};
		$time_2 = $options{'time_2'};	
		$value_1 = $options{'value_1'};
		$value_2 = $options{'value_2'};
		$delta_obs = $options{'delta_obs'};		
	}	
	$message_id = $options{'message'};
	print "Message id: $message_id \n";			
	
	if ($options{'message_list'}){	$message_file = $options{'message_list'};}	
	else {	$message_file="message_list.xml";}	
	
	if ($options{'email'}){	$email_file = $options{'email'};}	
	else {	$email_file="email_list.xml";	}
	
	$group_id = $options{'group'};
	print "Group id: $group_id \n";
	
	$observation_id=$options{'observation_id'};
	if (exists $options{'user'}){$user_id = $options{'user'};} 
	
	#EMAIL IDS
	my $xp_email_list = XML::XPath->new(filename => $email_file);
	my @email_array;
	my $sender=$xp_email_list->findvalue('//group[@id="'.$group_id.'"]/sender');
	my $domain=$xp_email_list->findvalue('//group[@id="'.$group_id.'"]/domain');
	
	if($user_id)
	{
		foreach my $element ($xp_email_list->findnodes('//group[@id="'.$group_id.'"]/user[@id="'.$user_id.'"]/email'))
		{
       		push(@email_array,$element->string_value());
		}
	}	
	else
	{
		foreach my $element ($xp_email_list->findnodes('//group[@id="'.$group_id.'"]/user/email'))
		{
       		push(@email_array,$element->string_value());
		}
	}
	
	print "@email_array \n";

	#MESSAGE LIST VALUES
	my $xp_message_list = XML::XPath->new(filename => $message_file);
	my $send_message = $xp_message_list->findvalue('//message[@id="'.$message_id.'"]/body');
	my $message_importance = $xp_message_list->findvalue('//message[@id="'.$message_id.'"]/importance');
	my $message_subject = $xp_message_list->findvalue('//message[@id="'.$message_id.'"]/subject');
	
	my %macro=();
	%macro = (
				'platform_id' => $platform_id,
				'test_type' => $test_type,
				'range_low' => $range_low,
				'range_high' => $range_high,
				'observation_id' => $observation_id,
				'current_value' => $current_obs_value,
				'time_1' => $time_1,
				'time_2' => $time_2,
				'value_1' => $value_1,
				'value_2' => $value_2,
				'delta_obs' => $delta_obs
				);	
	
	if ($test_type eq "range")
	{	
		$send_message=macro_process(\%macro,$send_message);
		print "Body of the Message: $send_message \n";
		$message_subject = macro_process(\%macro,$message_subject);
		print "Subject of the Message: $message_subject \n";
	}

	my @macro_time=();
	if ($test_type eq "time_continuity")
	{
		$send_message=macro_process(\%macro,$send_message);
		print "Body of the Message: $send_message \n";
		$message_subject = macro_process(\%macro,$message_subject);
		print "Subject of the Message: $message_subject \n";
	}
	
	#EMAIL 

	#sender's email address
	if( !$testing )
	{
  	my $smtp;
  	$smtp = Net::SMTP->new("$domain");
  	#print  $smtp->domain(),"\n";

  	$smtp->mail($sender);
  
		#??for some reason the body won't print without the below starting newline
		$send_message = "\n".$send_message;

		$smtp->to(@email_array,{ SkipBad => 1 }); # ignore for bad addresses.
		#$smtp->recipient(@email_array);
		#$smtp->recipient("monisha\@sc.edu"); #single recipient
  
  	#start the email
  	$smtp->data();
  
  	#Header  
  	#$smtp->datasend("Priority: Urgent\n");
  	$smtp->datasend("Importance: $message_importance\n");
  	$smtp->datasend("To: @email_array \n");
  	$smtp->datasend("Subject: $message_subject");
  	$smtp->datasend("\n");
  
  	#Body 
  	$smtp->datasend("$send_message");
  	$smtp->dataend();
  	$smtp->quit();
	}
	else
	{
    open( NOTIFY_FILE, ">NotifyEmailTest.txt");
    while( @email_array )
    {
      my $strTo = shift( @email_array );
      print NOTIFY_FILE "To: $strTo\n";
    }
    print NOTIFY_FILE "Subject: $message_subject\n";
    print NOTIFY_FILE "$send_message\n";
    
    close( NOTIFY_FILE );  
	}		
	exit 0;		
	
	###################################################
	#                                                 #  
	#   SUBROUTINE TO SPECIFY THE EMAIL TEXT.         #	
	#                                                 #  
	###################################################	
	
	sub macro_process
	{
		my ($macro_ref,$new_string)=@_;
		my %macro =%$macro_ref;
		my $test_type = $macro{'test_type'};
		my ($platform_id,$range_high,$range_low,$observation_id,$current_obs_value,$time_1,$time_2,$value_1,$value_2,$delta_obs);
				
		$platform_id = $macro{ 'platform_id'};
		$observation_id = $macro{ 'observation_id'};
						
		if ($test_type eq "range")
		{
			$range_low = $macro{ 'range_low'};
			$range_high = $macro{ 'range_high'};
			$current_obs_value = $macro{ 'current_value'};
			
			if ($new_string =~m/Macro0/) {$new_string =~ s/Macro0/$platform_id/g ; }				
			if ($new_string =~m/Macro1/) {$new_string =~ s/Macro1/$observation_id/g ;	}						
			if ($new_string =~m/Macro2/) {$new_string =~ s/Macro2/$range_high/g ;	}						
			if ($new_string =~m/Macro3/) {$new_string =~ s/Macro3/$range_low/g ;	}						
			if ($new_string =~m/Macro4/) {$new_string =~ s/Macro4/$current_obs_value/g ; }	
			if ($new_string =~m/Macro7/) {$new_string =~ s/Macro7/$test_type/g ; }	
		}	
					
		if ($test_type eq "time_continuity")
		{
			$time_1 = $macro{ 'time_1'};
			$time_2 = $macro{ 'time_2'};
			$value_1 = $macro{ 'value_1'};
			$value_2 = $macro{ 'value_2'};
			$delta_obs = $macro{ 'delta_obs'};
			
			if ($new_string =~m/Macro0/) {$new_string =~ s/Macro0/$platform_id/g ; }				
			if ($new_string =~m/Macro1/) {$new_string =~ s/Macro1/$observation_id/g ;	}						
			if ($new_string =~m/Macro2/) {$new_string =~ s/Macro2/$time_1/g ;	}						
			if ($new_string =~m/Macro3/) {$new_string =~ s/Macro3/$value_1/g ;	}	
			if ($new_string =~m/Macro4/) {$new_string =~ s/Macro4/$time_2/g ;	}						
			if ($new_string =~m/Macro5/) {$new_string =~ s/Macro5/$value_2/g ;	}
			if ($new_string =~m/Macro6/) {$new_string =~ s/Macro6/$delta_obs/g ;	}
			if ($new_string =~m/Macro7/) {$new_string =~ s/Macro7/$test_type/g ; }				
		}						
		return $new_string;		
	}	#end of subroutine macro_process
	
