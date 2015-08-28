The Xenia schema currently has the following fields on the multi\_obs table for tracking some basic QAQC type information with each row of observation data on the multi\_obs table.
```
#table multi_obs
qc_id
qc_level
qc_flag
```

# qc\_level, qc\_flag #

In reference to the qc\_level and qc\_flag fields, also see the [SECOORA QAQC documentation](http://trac.secoora.org/datamgmt/browser/docs/whitepapers/trunk/SEACOOS%20QA-QC%20Standards%20and%20Procedures%20Whitepaper.doc)

The valid values for the high/overview qc\_level flag are easiest to discuss.  It represents an integer field with one of the following five possible values.
```
VALUE	CONDITION
-9	the data field is missing a value
0	the data quality is not evaluated
1	the data quality is bad
2	the data quality is questionable or suspect
3	the data quality is good
```

For the qc\_flag, the below set of tests have been suggested, with the first two (data availability, sensor range) required.  An encoding has not been agreed upon.

```
#QA/QC Tests
Data Availability
Sensor Range
Gross Range
Climatological Range
Rate of Change
Nearest Neighbor
Other Comparison 1 
Other Comparison 2
...
```

'Other Comparisons' meaning would be described in qc metadata record documentation link -
multi\_obs.qc\_id = metadata.row\_id, metadata table row\_id contains additional pointers to documentation formats,links and effective dates.

My suggestion would be to use a position-dependent string encoding (**test not evaluated = 0, test fail = 1, test pass = 3**) as to mimic the qc\_level settings.  Also suggested is representing tests up through 'Other Comparison 1'(7 digits) although these last set of test may be unevaluated for some time to come and might act more as placeholders for later development.

Where the string qc\_level = '3330000' would represent data which passed the first three tests for data availability, sensor range, gross range and the other tests were unevaluated.

qc\_level = '3010000' would represent data which passed the first test, sensor range not evaluated and gross range test fail.

The above string could be shortened to just test fields which are being evaluated, the main concept being that the documentation of the string position and meaning is contained in the qc documentation link as referenced by the associated metadata.row\_id = multi\_obs.qc\_id

# qc\_id #

_section under development_

The qc\_id is a integer referencing a primary key row on the table metadata.row\_id and its associated metadata fields.  The following would be a suggested sample metadata record for an ongoing quality control application.

```
#table metadata
row_id = 1

```


---

= Secondary, Revisional QAQC

**Note:** This secondary,revisional level of quality control may be redeveloped under a **custom fields** type concept.  Please see discussion of that topic as it develops.

The Xenia schema currently includes a secondary repeat of the earlier discussed fields suffixed with '_2' as qc\_id\_2,qc\_level\_2,qc\_flag\_2_

These fields are **optional** placeholder fields for a secondary or revisional level of applied qc and would operate in the same manner as the **primary** qc listed earlier, just reflecting the qc results as applied by another party or later process.


---


# Related Links #

NDBC
  * http://www.ndbc.noaa.gov/qc.shtml
  * http://www.ndbc.noaa.gov/handbook.pdf

Quality Assurance of Real-Time Ocean Data http://qartod.org

SECOORA Whitepaper
http://trac.secoora.org/datamgmt/browser/docs/whitepapers/trunk/SEACOOS%20QA-QC%20Standards%20and%20Procedures%20Whitepaper.doc