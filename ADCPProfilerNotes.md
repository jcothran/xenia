copied from [here](http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/AdcpProfilerNotes)

earlier notes with a sample script for going from adcp source data into Xenia available [here](http://nautilus.baruch.sc.edu/twiki_dmcc/bin/view/Main/XeniaPackageV2ADCP)

source code for creating vector plots (adcp) available [here](http://code.google.com/p/xenia/source/browse/trunk/postgresql/profiler)

# Creating Vector Plots #
  * adcp\_vector\_plot.pl - Queries multi\_obs table and creates data file for the vector plot. The data is broken into different files based on the magnitude of the current so that color coding exists in the output image file.
  * adcp\_gnuplot.lib - Includes syntax and commands for gnuplot to to create the vector plots from the data files.

# Imagemap #
WMS queries are made against the xenia database to indicate adcp platform and imagemap information is specified in the html to link back to the adcp profiler plots.

# Example output graph #

![http://nautilus.baruch.sc.edu/twiki_dmcc/pub/Main/AdcpProfilerNotes/xenia_adcp_gnuplot_graph.jpg](http://nautilus.baruch.sc.edu/twiki_dmcc/pub/Main/AdcpProfilerNotes/xenia_adcp_gnuplot_graph.jpg)