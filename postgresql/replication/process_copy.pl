#!/usr/bin/perl

# This script will create copy files from a source db, copy files to a target db or delete files from a source db - usually processed in that step order

use strict;
use XML::XPath;

#usage: perl process_copy.pl environment_copy.xml <create,copy,delete>  2007_01_01_00-05 2007_02_01_00-05
my ($env_path,$mode,$time_start,$time_stop) = @ARGV;

my $time_start_full = substr($time_start,0,4).'-'.substr($time_start,5,2).'-'.substr($time_start,8,2).' '.substr($time_start,11,2).':00:00'.substr($time_start,13,3);
my $time_stop_full = substr($time_stop,0,4).'-'.substr($time_stop,5,2).'-'.substr($time_stop,8,2).' '.substr($time_stop,11,2).':00:00'.substr($time_stop,13,3);

#print $time_start_full."\n";

my $xp_env = XML::XPath->new(filename => $env_path);

my $db_source_host = $xp_env->findvalue('//db_source/host');
my $db_source_name = $xp_env->findvalue('//db_source/db_name');
my $db_source_username = $xp_env->findvalue('//db_source/username');
my $db_source_password = $xp_env->findvalue('//db_source/password');

my $db_target_host = $xp_env->findvalue('//db_target/host');
my $db_target_name = $xp_env->findvalue('//db_target/db_name');
my $db_target_username = $xp_env->findvalue('//db_target/username');
my $db_target_password = $xp_env->findvalue('//db_target/password');

#must use absolute psql path for successful server automation(will work without as user)
my $path_psql = $xp_env->findvalue('//path/path_psql');

my $path_tables = $xp_env->findvalue('//path/path_tables');
my $xp_tables = XML::XPath->new(filename => $path_tables);

my $dir_tmp_cpy_local = $xp_env->findvalue('//path/dir_tmp_cpy_local');
my $dir_tmp_cpy_host = $xp_env->findvalue('//path/dir_tmp_cpy_host');
my $dir_cpy = $xp_env->findvalue('//path/dir_cpy');

my ($this_table,$these_columns,$filename);

##################################################################
if ($mode eq 'create') {
foreach my $element ($xp_tables->findnodes('//tableList/table')) {

	$this_table = $element->findnodes('name');
	$this_table = $this_table->string_value();

	$these_columns = $element->findnodes('columns');
	$these_columns = $these_columns->string_value();

	$filename = "$this_table:$time_start:$time_stop.csv";

	#would like to use 'with csv header' in the copy commands below but need to be using postgresql version 8.2 or greater for this	
        `$path_psql -U $db_source_username -d $db_source_name -h $db_source_host -c "create temp table $this_table\_dump as select $these_columns from $this_table where row_entry_date >= '$time_start_full' and row_entry_date < '$time_stop_full'; copy $this_table\_dump to stdout with csv;" > $dir_tmp_cpy_local$filename`;

	#if file is empty then remove
	if (-z "$dir_tmp_cpy_local$filename") { `rm $dir_tmp_cpy_local$filename`; }	

}

}

##################################################################
if ($mode eq 'copy') {
foreach my $element ($xp_tables->findnodes('//tableList/table')) {

        $this_table = $element->findnodes('name');
        $this_table = $this_table->string_value();

        $these_columns = $element->findnodes('columns');
        $these_columns = $these_columns->string_value();

        $filename = "$this_table:$time_start:$time_stop.csv";

	#if copy file exists
	if (-e "$dir_tmp_cpy_host$filename") {
	#run copy file against target table to populate
        `$path_psql -U $db_target_username -d $db_target_name -h $db_target_host -c "copy $this_table($these_columns) from '$dir_tmp_cpy_host$filename' with csv"`;

        #just .gz instead of .tar.gz since testing indicated just .gz smaller
        `cd $dir_tmp_cpy_local; zip $filename.gz $filename; rm $filename; mv $filename.gz $dir_cpy`;
	}
}

}

##################################################################
if ($mode eq 'delete') {
my @tableList = ();
foreach my $element ($xp_tables->findnodes('//tableList/table/name')) {
        $this_table = $element->string_value();
	push(@tableList,$this_table);
}
@tableList = reverse(@tableList);

foreach $this_table (@tableList) {

	`$path_psql -U $db_source_username -d $db_source_name -h $db_source_host -c "delete from $this_table where row_entry_date >= '$time_start_full' and row_entry_date < '$time_stop_full'"`;
}

}
		
exit 0;

