#!/usr/bin/perl

# This script will create copy files from a source db, copy files to a target db or delete files from a source db - usually processed in that step order

use strict;
use XML::XPath;

#usage: perl process_copy.pl environment_copy.xml <create,copy,delete>  2007_01_01_00-05 2007_02_01_00-05
my ($env_path,$mode,$time_start,$time_stop) = @ARGV;

my $time_start_full = substr($time_start,0,4).'-'.substr($time_start,5,2).'-'.substr($time_start,8,2).' '.substr($time_start,11,2).':00:00';
my $time_stop_full = substr($time_stop,0,4).'-'.substr($time_stop,5,2).'-'.substr($time_stop,8,2).' '.substr($time_stop,11,2).':00:00';

print "$time_start_full:$time_stop_full\n";

my $xp_env = XML::XPath->new(filename => $env_path);

my $db_source_name = $xp_env->findvalue('//db_source/db_name');
my $db_target_name = $xp_env->findvalue('//db_target/db_name');

#must use absolute psql path for successful server automation(will work without as user)
my $path_sqlite = $xp_env->findvalue('//path/path_sqlite');

my $path_tables = $xp_env->findvalue('//path/path_tables');
my $xp_tables = XML::XPath->new(filename => $path_tables);

my $dir_cpy = $xp_env->findvalue('//path/dir_cpy');

my $filename_latest = 'latest.sql';

my ($this_table,$these_columns,$filename_csv,$filename_sql);

##################################################################
#'create' will create the source files from the source db within the specified time range
if ($mode eq 'create') {
        #replace content for 'latest.sql' file with placeholder line below
        `echo "-- any sql statements will follow below here - may be no sql at times" > $dir_cpy$filename_latest`;

foreach my $element ($xp_tables->findnodes('//tableList/table')) {

	$this_table = $element->findnodes('name');
	$this_table = $this_table->string_value();

	$these_columns = $element->findnodes('columns');
	$these_columns = $these_columns->string_value();

	$filename_csv = "$this_table:$time_start:$time_stop.csv";
	$filename_sql = "$this_table:$time_start:$time_stop.sql";

	#print "$dir_cpy$filename\n";
	open (SQL_OUT, ">./temp.sql");
  	print SQL_OUT ".m csv \n.o $dir_cpy$filename_csv \nselect $these_columns from $this_table where row_entry_date >= '$time_start_full' and row_entry_date < '$time_stop_full' ;\n"; 
  	print SQL_OUT ".m insert $this_table\n.o $dir_cpy$filename_sql \nselect $these_columns from $this_table where row_entry_date >= '$time_start_full' and row_entry_date < '$time_stop_full' ; "; 
	close (SQL_OUT);
 
        system("$path_sqlite $db_source_name < temp.sql");

	#add column references since sqlite mistakenly assumes all columns on creating insert sql
	#having trouble getting regex to work with open,close parenthesis, ASCII hex \x28 = ( , \x29 = )
	my $op = '\x28';
	my $cp = '\x29';
	my $quoted = '\x27now\x27';
	my $column_1 = 'row_entry_date,';

	system("perl -pi -e 's/VALUES$op/$op$column_1$these_columns$cp VALUES $op\datetime$op$quoted$cp,/g' $dir_cpy$filename_sql");
	#system("perl -pi -e 's/VALUES/$op$these_columns$cp VALUES/g' $dir_cpy$filename_sql");

	#if file is empty then remove
	if (-z "$dir_cpy$filename_csv") { system("rm $dir_cpy$filename_csv"); }	
	if (-z "$dir_cpy$filename_sql") { system("rm $dir_cpy$filename_sql"); }	
	else {
		#concatenate this sql to 'latest.sql' file
		system("cat $dir_cpy$filename_sql >> $dir_cpy$filename_latest");
	}
}

}

##################################################################
#'copy' will copy from the source files within the specified time range to the target db
if ($mode eq 'copy') {
foreach my $element ($xp_tables->findnodes('//tableList/table')) {

        $this_table = $element->findnodes('name');
        $this_table = $this_table->string_value();

        $these_columns = $element->findnodes('columns');
        $these_columns = $these_columns->string_value();

        $filename_sql = "$this_table:$time_start:$time_stop.sql";

	#if copy file exists
	if (-e "$dir_cpy$filename_sql") {
	#print "$db_target_name $dir_cpy$filename_sql\n";

	#run copy file against target table to populate
        `$path_sqlite $db_target_name < $dir_cpy$filename_sql`;

	}
}

}

##################################################################
#'delete' will delete from the source db table data where the row_entry_date is within the specified time range
if ($mode eq 'delete') {
my @tableList = ();
foreach my $element ($xp_tables->findnodes('//tableList/table/name')) {
        $this_table = $element->string_value();
	push(@tableList,$this_table);
}
@tableList = reverse(@tableList);

foreach $this_table (@tableList) {

        open (SQL_OUT, ">./temp.sql");
        print SQL_OUT "delete from $this_table where row_entry_date >= '$time_start_full' and row_entry_date < '$time_stop_full' ; ";
        close (SQL_OUT);

        system("$path_sqlite $db_source_name < temp.sql");

}

}
		
exit 0;

