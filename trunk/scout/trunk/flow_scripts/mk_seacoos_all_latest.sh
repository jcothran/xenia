#this script unzips all the individual kml zipped files into one temp folder and puts the collection of individual files into one single zip file

cd /var/www/html/obskml/feeds/temp ;

unzip -q "../wq/wq_metadata_latest.kmz" >> /tmp/obskml.log 2>&1 ;
#unzip -q "../vos/vos_metadata_latest.kmz" >> /tmp/obskml.log 2>&1 ;
unzip -q "../nerrs/nerrs_metadata_latest.kmz" >> /tmp/obskml.log 2>&1 ;
#unzip -q "../seacoos/seacoos_metadata_latest.kmz" >> /tmp/obskml.log 2>&1 ; 
unzip -q "../ndbc/ndbc_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../nws/nws_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../nos/nos_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../usf/usf_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../skio/skio_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../cormp/cormp_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../carocoops/carocoops_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;

unzip -q "../nccoos/nccoos_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;

#only use one of the following once voulgaris is fully obskml
#unzip -q "../seacoos/seacoos_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;
unzip -q "../scnms/scnms_latest_obskml.zip" >> /tmp/obskml.log 2>&1 ;

zip -m -q seacoos_all_latest.zip *.kml >> /tmp/obskml.log 2>&1 ;
cp seacoos_all_latest.zip ../secoora_all_latest.zip;
mv -f seacoos_all_latest.zip ..

