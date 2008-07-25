get_graph.php is the php wrapper page that just passes http args or 'default' as the arg to the perl script graph/graphSingleLine.pl
 
graphSingleLine.pl uses the gnuplot libs graphCommon.lib and graphSingleLine.lib (you shouldn't need to touch those) and gets its database connection info,etc from the environment_xenia_secoora.xml file and graphing/conversion details from environment_xenia_graph.xml
 
The environment_xenia_graph.xml shown there is an older setup in that I list the m_type_id's directly - I'm changing this to just reference/lookup from the standard_name instead so its not as directly tied to the database details.  There are some more details on the graph.xml at http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/CarolinasCoastLite#a_description_of_the_graph_xml_f
 
Most of the code for creating the graph from the sql resultset should be pretty generic and reusable.

A working example query would be like

http://nautilus.baruch.sc.edu/xenia_sqlite/get_graph.php?sensor_id=4647&output=webpage&time_interval=-1%20day&unit_conversion=en&time_zone_arg=EASTERN


