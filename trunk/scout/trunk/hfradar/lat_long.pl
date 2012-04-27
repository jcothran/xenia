
my $grid_size = 250;

#1.5*250 grid points = 375km per side
#http://www.nhc.noaa.gov/gccalc.shtml  #distance calculator

#given upper/left    28.58333     -84.41666
#offset bottom/right 25.21	  -80.57

#grids center or edge based ? assuming edge

my $grid_distance = (28.58333 - 25.21)/ $grid_size;
#print $grid_distance."\n";

my $lat = 28.58333;
my $string_lat;
for (my $i = 0; $i < $grid_size; $i++) {
        $string_lat .= "$lat,";
	$lat -= $grid_distance;
}
$string_lat = substr($string_lat,0,-1);
print $string_lat."\n";

my $grid_distance = (84.41666 - 80.57)/ $grid_size;
#print $grid_distance."\n";

my $long = -84.41666;
my $string_long;
for (my $i = 0; $i < $grid_size; $i++) {
        $string_long .= "$long,";
        $long += $grid_distance;
}
$string_long = substr($string_long,0,-1);
print $string_long;

