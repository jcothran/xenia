#more documentation at
http://code.google.com/p/xenia/wiki/Spreadsheet#SecooraSensorInventory__v1.0

convert_sheet_si.pl

#this script converts a combined org/platform spreadsheet into two separate
#TSV spreadsheets org, platform with the correct field mappings for load/import
#by the google spreadsheet SecooraSensorInventory_v1.0

sheet_to_db.pl

#this script creates the necessary initial si.db table structure based on the
#header lines of the associated spreadsheet file referenced

refresh_sheet.pl

#this script populates/refreshes the local si.db sqlite database with the
#latest google spreadsheet values.  Spreadsheets are located via the google
#spreadsheet registry file.

create_kml_si.pl

#this script reads the local si.db sqlite database and creates kml/kmz output
#files


