
#! /bin/bash

#
# A bash script to download drifter text files, run a perl parser, initiate a DB insert, and then cleanup
#

# get the text files
wget http://cromwell.marine.unc.edu/drifters/aoml_drifters.txt -O /home/jcleary/drifter/aoml_drifters.txt
wget http://www.horizonmarine.com/ioos/seacoos.txt -O  /home/jcleary/drifter/seacoos.txt

#
# run entire process on each file

#
# AOML
#
# JC's perl processing code
/home/jcleary/drifter/process_file_xenia_aoml.pl /home/jcleary/drifter/aoml_drifters.txt

# psql insert
psql -h coriolis.marine.unc.edu -U jcleary -d db_xenia_v2 -f /home/jcleary/drifter/test.sorted.sql 2> /dev/null

# remove SQL files
rm /home/jcleary/drifter/test*


#
# Horizon Marine
#

# JC's perl processing code
/home/jcleary/drifter/process_file_xenia_hm.pl /home/jcleary/drifter/seacoos.txt

# psql insert
psql -h coriolis.marine.unc.edu -U jcleary -d db_xenia_v2 -f /home/jcleary/drifter/test.sorted.sql 2> /dev/null

# remove SQL files
rm /home/jcleary/drifter/test*

#cleanup source files
rm /home/jcleary/drifter/*.txt

