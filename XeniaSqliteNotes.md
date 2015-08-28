

# Data Dictionary Listing(Simple Scalar Types) #

```
-- scalar data dictionary listing for simple scalar obs (standard listing)
-- Xenia version 3
-- select t0.row_id,t2.standard_name,t3.standard_name from m_type t0,m_scalar_type t1,obs_type t2,uom_type t3 where t0.m_scalar_type_id = t1.row_id and t0.num_types = 1 and t1.obs_type_id = t2.row_id and t1.uom_type_id = t3.row_id;

-- Xenia version 2
-- select t1.row_id,t2.standard_name,t3.standard_name from m_type t1,obs_type t2,uom_type t3 where t1.obs_type_id = t2.row_id and t1.uom_type_id = t3.row_id;
```

# Adding simple scalar types to the data dictionary tables and processing scripts #

The below example shows how to add a simple scalar data type (a vector of only one component) to the data dictionary.  The particular observation type is 'depth' and the unit of measurement is meters 'm'

For the tables involved, the row\_id on each of the tables is defined as the primary key so they will autoincrement on inserts to the next available row\_id.

For further examples see the initial data dictionary population script at http://code.google.com/p/xenia/source/browse/trunk/sqlite/sql/obs.sql


---


Add observation type row to obs\_type table.  Note that the naming convention is all lower
case with underscore character as a space/word separator.
`INSERT INTO obs_type(standard_name,definition) VALUES ('depth', 'approximate water depth');`

Check the row\_id of the newly inserted row for reference in later step

obs\_type.row\_id = 42


---


Add unit of measurement type row to uom\_type table.  Note that the naming convention is all lower case with underscore character as a space/word separator.

For this example the uom\_type row (meter) already exists on the database so we do not perform the below step, but the below line shows how we would add this row.

`INSERT INTO uom_type(standard_name,definition,display) VALUES ('m', 'meter', 'm');`

Check the row\_id of the newly inserted row for reference in later step

uom\_type.row\_id = 6


---


**Note** if using Xenia version 2 database the below INSERT statement will be against the m\_type table and not the m\_scalar\_type

Add row to m\_scalar\_type table to associate the obs\_type with its uom - note the referenced row\_id's used from the previous 2 steps

`INSERT INTO m_scalar_type(obs_type_id,uom_type_id) VALUES (42,6);`

Check the row\_id of the newly inserted row for reference in later step

m\_scalar\_type.row\_id = 48


---


**Note** step for Xenia version 3(or above) which includes both tables m\_type and m\_scalar\_type

Add row to m\_type table to associate the m\_type.row\_id=m\_type\_id to the m\_scalar\_type.row\_id  The inserted '1' value lets us know that there is only one component to this vector

`INSERT INTO m_type (num_types,m_scalar_type_id) VALUES (1,48);`

m\_type.row\_id = 44


---


Add or update rows on m\_type\_display\_order which correspond to the display order of observation types for certain products(air,surface,water,etc) - if the order is unimportant, just insert the m\_type\_id the last row of the table.


---


associated scripts for new observation types

http://code.google.com/p/xenia/source/browse/trunk/sqlite/import_export/obskml_to_xenia_sqlite.pl script, function get\_m\_type\_id allows for creating synonym terms to also recognize the available data

graph.xml used by http://code.google.com/p/xenia/source/browse/#svn/trunk/sqlite/time_series and http://code.google.com/p/xenia/source/browse/#svn/trunk/obskml/products/html_tables

style.xml used by http://code.google.com/p/xenia/source/browse/#svn/trunk/obskml/products/gearth

# datetime formatting example for time comparison statements #

see http://www.sqlite.org/cvstrac/wiki?p=DateAndTimeFunctions

`multi_obs.m_date <= strftime('%Y-%m-%dT%H:00:00','2008-09-24T14:00:00','+1 hour')`

Note that function datetime by default returns a space separated result which will only compare the date portion against the ISO8601 'T' separated multi\_obs.m\_date field.  The above comparison avoids that date only comparison error.

Note to use strftime, datetime, etc on single values or small subsets as they add much time cost to queries.

# use UNION instead of JOIN/OR #

from experimentation it seems JOINS and OR statements may not correctly use/invoke indexes and it may be faster to do a UNION of two separate SELECT statements which are making use of table indexes

# dumping a table select as insert statements #

http://www.sqlite.org/sqlite.html

Below commands will dump the table select on table platform to the text file 'test.sql' as insert statements

```
sqlite> .output test.sql
sqlite> .mode insert platform
sqlite> select * from platform;
sqlite> .quit
```

# get all sensors per platform #

in below example, change WHERE statement for testing as needed

```
select distinct platform.platform_handle
    ,fixed_longitude
    ,fixed_latitude
    ,'2009-01-02T15:00:00Z'
    ,''
    ,platform.description
    ,obs_type.standard_name
  from platform
    left join sensor on platform.row_id=sensor.platform_id
    left join m_type on m_type.row_id=sensor.m_type_id
    left join m_scalar_type on m_scalar_type.row_id=m_type.m_scalar_type_id
    left join obs_type on obs_type.row_id=m_scalar_type.obs_type_id
where platform_handle like 'carocoops%'
  order by platform_handle,obs_type.standard_name;
```

# get all the latest observations per platform #

http://www.sql-tutorial.com/sql-group-by-sql-tutorial/ <br>
<a href='http://www.w3schools.com/sql/sql_groupby.asp'>http://www.w3schools.com/sql/sql_groupby.asp</a> <br>
<a href='http://manuals.sybase.com/onlinebooks/group-as/asg1250e/sqlug/@Generic__BookTextView/9669;pt=9699'>http://manuals.sybase.com/onlinebooks/group-as/asg1250e/sqlug/@Generic__BookTextView/9669;pt=9699</a>

in below example, change WHERE statement for testing as needed<br>
<br>
use left join to add in additional table columns<br>
<br>
<pre><code>select platform_handle<br>
    ,m_type_id<br>
    ,max(m_date)<br>
    ,m_lat<br>
    ,m_lon<br>
    ,m_z<br>
    ,m_value<br>
  from multi_obs<br>
  where platform_handle like 'carocoops%'<br>
  and m_date &gt; strftime('%Y-%m-%dT%H:%M:%S','now','-12 hours')<br>
group by platform_handle,m_type_id;<br>
</code></pre>

<b>note: on postgres, group by requires all select columns except the aggregate column specified in the group by</b>

<h1>simple row formatting on SELECT result</h1>

<pre><code>select ',"'||standard_name||'"' from obs_type;<br>
</code></pre>




<h1>SELECT dates from one sensor that are the same dates from another sensor</h1>
Recently I wanted to do some correlation testing for our platforms against some known good NDBC platforms. Correlation requires the list of values to be the same length, however we might miss an update throughout the day so we'd have a hole in our data. This query is useful to make sure the dates in the outer select match the dates in the sbuquery select, thereby giving us the data points for the same time periods. You have to execute this twice, swapping the sensor ID's.<br>
<br>
<pre><code>SELECT m_date,sensor_id,m_value,d_report_hour as control_hour <br>
FROM multi_obs mo <br>
WHERE m_date &gt;= '2011-03-23T00:00:00' and <br>
m_date &lt; '2011-03-23T24:00:00' AND <br>
sensor_id = 518 AND <br>
EXISTS <br>
(SELECT d_report_hour <br>
FROM multi_obs <br>
WHERE m_date &gt;= '2011-03-23T00:00:00' AND <br>
m_date &lt; '2011-03-23T24:00:00' AND <br>
sensor_id=4644 and <br>
mo.d_report_hour=d_report_hour) <br>
ORDER BY sensor_id ASC, d_report_hour ASC;<br>
</code></pre>

<h1>crosstab query</h1>

see also<br>
<a href='http://www.postgresql.org/docs/9.1/static/tablefunc.html'>http://www.postgresql.org/docs/9.1/static/tablefunc.html</a> <br />
<a href='http://code.google.com/p/xenia/wiki/VMwareMod#crosstab_query'>http://code.google.com/p/xenia/wiki/VMwareMod#crosstab_query</a>

Not sure how well this query performs or utilizes indexes, but need something like this for 'pivot' table type transforms of row values to column values.<br>
<br>
Can dynamically do a pre-query to lookup and substitute readable column header names like wind_speed,air_pressure,etc in the below final results query.<br>
<br>
Can also dynamically substitute in the where clauses additional m_date,sensor_id or other key search parameters.<br>
<br>
sample query for platform = carocoops.CAP2.buoy - wind_speed(4644) and air_pressure(4648) sensor_id's<br>
<ul><li>note the 'SELECT' and 'AS' parameters should be equal in number of expected columns.<br>
</li><li>note the SELECT statements have been optimized to trigger the multi_obs index usage with m_date,sensor_id order and specifics - below query returned in < 100 ms.  Can run 'EXPLAIN ANALYZE' on overall and subqueries to gauge performance.</li></ul>

<pre><code>SELECT * FROM crosstab<br>
(<br>
  'SELECT m_date,sensor_id,m_value from multi_obs where m_date &gt;= ''2011-10-10'' and sensor_id in (4644,4648) ORDER BY 1',<br>
  'SELECT DISTINCT sensor_id FROM multi_obs where m_date &gt;= ''2011-10-10'' and sensor_id in (4644,4648) ORDER BY 1'<br>
)<br>
AS<br>
(<br>
       m_date timestamp,<br>
       m_value_1 float8,<br>
       m_value_2 float8<br>
);<br>
</code></pre>

sample output<br>
<pre><code>     m_date        | m_value_1 | m_value_2 <br>
---------------------+-----------+-----------<br>
 2011-10-09 01:00:00 |       9.9 |    1024.9<br>
 2011-10-09 02:00:00 |      11.6 |    1024.4<br>
 2011-10-09 03:00:00 |        10 |    1024.6<br>
 2011-10-09 04:00:00 |      11.9 |    1023.8<br>
 2011-10-09 05:00:00 |      11.3 |      1023<br>
 2011-10-09 06:00:00 |      10.4 |    1022.7<br>
 2011-10-09 07:00:00 |      11.1 |    1022.9<br>
 2011-10-09 08:00:00 |      12.2 |    1022.2<br>
 2011-10-09 09:00:00 |       9.4 |    1022.2<br>
 2011-10-09 10:00:00 |      11.1 |      1022<br>
 2011-10-09 11:00:00 |      11.6 |    1022.1<br>
</code></pre>

<h2>segmentation fault: work-around</h2>

I ended up getting intermittent(hard to troubleshoot) segmentation faults in postgresql using the crosstab functionality and just ended up using the below perl transformation of the resultset to get the same type of crosstab output format.<br>
<br>
<pre><code>#output results<br>
my $sensor_id_list = '1,2,3,4,5";<br>
<br>
my $content .= $sensor_header_display_list."\n";<br>
<br>
$sql = "SELECT m_date,sensor_id,m_value from multi_obs where m_date &gt;= '$startd' and m_date &lt;= '$endd' and sensor_id in ($sensor_id_list) ORDER BY 1";<br>
#print $sql; #debug<br>
$sth = $dbh-&gt;prepare($sql);<br>
$sth-&gt;execute();<br>
<br>
my $time_key = '';<br>
my %sensor = ();<br>
my @array_sensor_id_list = split(/,/,$sensor_id_list);<br>
while (my @row = $sth-&gt;fetchrow_array) {<br>
if ($time_key eq '') { $time_key = $row[0]; } #initial row only<br>
<br>
if (@row[0] ne $time_key) {<br>
  $time_key=row[0];<br>
  my $line = "$time_key,";<br>
  foreach my $id (@array_sensor_id_list) {<br>
    $line .= "$sensor{$id},";<br>
  }<br>
  chop($line);<br>
  $content .= "$line\n";<br>
<br>
  $time_key = @row[0];<br>
  %sensor = ();<br>
}<br>
<br>
$sensor{@row[1]} = @row[2];<br>
}<br>
<br>
print $content;<br>
</code></pre>