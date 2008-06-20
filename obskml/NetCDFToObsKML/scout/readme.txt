There are several files here but the main workflow is:

get_latest_data.pl includes get_latest_data_listing.pl and they both basically work to get and log netCDF files to be processed by:

cdl_0master.pl decides which category(point, map, etc) the netCDF file is and passes it to one of the following:

cdl_fixed_point.pl is the main one used for the buoys, etc.

cdl_fixed_map.pl is used for hf radar

cdl_moving_point.pl is used for Explorer of the Seas, but we should really merge this code with cdl_fixed_point.pl - if you compare the two scripts the only main difference is that moving point requires the extra long/lat info to be supplied dynamically, but the rest is basically the same.

cdl_grid.pl and cdl_grid_jpl.pl can be ignored for now since they were mainly used in aggregating quickscat which is a processing/storage bear by itself and which I've put the kabosh on for now as we're struggling to just keep out own Seacoos provider observations flowing smoothly.

Jeremy


