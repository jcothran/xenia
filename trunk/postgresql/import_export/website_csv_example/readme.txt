These scripts give an example of creating ObsKML from a website which lists its observation results as CSV.

fldep_to_obskml.pl is the main script called periodically via a cron job.

It reads the latest row values for individual stations and saves it to the latest.csv file.

The latest.csv file is processed row by row using text template files(fldep_template.kml, org_template.kml,placemark_template.kml,obs_template.kml) to produce the final fldep.kml file(zipped to fldep.kmz).

