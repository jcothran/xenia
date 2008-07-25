<?
//echo "hello";

$environment = $_REQUEST['environment'] ;
$time_query = $_REQUEST['time_query'] ;
$time_interval = $_REQUEST['time_interval'] ;
$time_from = $_REQUEST['time_from'] ;
$time_to = $_REQUEST['time_to'] ;

$sensor_id = $_REQUEST['sensor_id'] ;
$column_value = $_REQUEST['column_value'] ;
$qc_clause = $_REQUEST['qc_clause'] ;
$time_zone_arg = $_REQUEST['time_zone_arg'] ;
$output = $_REQUEST['output'] ;
$range_min = $_REQUEST['range_min'] ;
$range_max = $_REQUEST['range_max'] ;
$title = $_REQUEST['title'] ;
$y_units = $_REQUEST['y_units'] ;
$unit_conversion = $_REQUEST['unit_conversion'] ;
$break_interval = $_REQUEST['break_interval'] ;
$size_x = $_REQUEST['size_x'] ;
$size_y = $_REQUEST['size_y'] ;

//if (empty($environment)) { echo "Error: missing required http argument environment="; exit (0); }
if (empty($environment)) { $environment = 'secoora'; }
if (empty($sensor_id)) { echo "Error: missing required http argument sensor_id="; exit (0); }

if (empty($time_query)) { $time_query = 'time_last'; }
if (empty($time_interval)) { $time_interval = '1 day'; }

if (empty($column_value)) { $column_value = 'default'; }
if (empty($qc_clause)) { $qc_clause = 'default'; }
if (empty($time_zone_arg)) { $time_zone_arg = 'EASTERN'; }
if (empty($output)) { $output = 'webpage'; }
if (empty($range_min)) { $range_min = 'default'; }
if (empty($range_max)) { $range_max = 'default'; }
if (empty($title)) { $title = 'default'; }
if (empty($y_title)) { $y_title = 'default'; }
if (empty($unit_conversion)) { $unit_conversion = 'default'; }
if (empty($break_interval)) { $break_interval = 'default'; }
if (empty($size_x)) { $size_x = 'default'; }
if (empty($size_y)) { $size_y = 'default'; }

if ($time_query == 'time_last') {
//echo "$environment time_last $time_interval $sensor_id $column_value $qc_clause $time_zone_arg $output $range_min $range_max $title $y_title $unit_conversion $break_interval $size_x $size_y" ;
$filename = `cd /var/www/html/xenia_sqlite/graph; perl graphSingleLine.pl $environment time_last "$time_interval" $sensor_id $column_value "$qc_clause" $time_zone_arg $output $range_min $range_max "$title" $y_title $unit_conversion $break_interval $size_x $size_y` ;
}
elseif ($time_query == 'time_date') {
$filename = `cd /var/www/html/xenia_sqlite/graph; perl graphSingleLine.pl $environment time_date "$time_from" "$time_to" $sensor_id $column_value "$qc_clause" $time_zone_arg $output $range_min $range_max "$title" $y_title $unit_conversion $break_interval $size_x $size_y` ;
}
else { echo "Invalid http argument time_query=, should be time_last or time_date"; exit (0); }

//echo $filename; exit;

if ($output == 'download') {
	//$filename = 'xenia_5659327.csv';
	header("Content-type: text/csv");
        header("Content-Disposition: attachment; filename=$filename");
        header("Pragma: no-cache");
        header("Expires: 0");

        include "/tmp/ms_tmp/$filename";
        exit;
}
else {
	//$filename = 'xenia_612553.html';
	if (empty($filename)) { header( "Location: http://carocoops.org/no_data.png" ); }
	else { header( "Location: http://carocoops.org/ms_tmp/$filename" ); }
}

?>
