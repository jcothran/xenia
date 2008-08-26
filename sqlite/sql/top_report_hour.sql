-- this trigger works but is SLOW so *NOT* implemented for now, need to implement as a called function or push hourly data to separate hourly database

CREATE TRIGGER set_top_of_hour AFTER INSERT ON multi_obs 
  BEGIN

-- -------------------------------------------------------------
--assign d_report_hour, each hour is associated with the half hour before and after the top of that hour

update multi_obs
	set d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date),
	d_hour_offset_min = cast(strftime('%M',new.m_date) as integer)
	where cast(strftime('%M',new.m_date) as integer) <= 30
	and row_id = new.row_id;

update multi_obs
	set d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour')),
	d_hour_offset_min = 60 - cast(strftime('%M',new.m_date) as integer)
	where cast(strftime('%M',new.m_date) as integer) > 30
	and row_id = new.row_id;

-- -------------------------------------------------------------
-- <= 30 minutes

--set new row to top hour if closer and existing compare exists
update multi_obs
	set d_top_of_hour = 1
	where cast(strftime('%M',new.m_date) as integer) <= 30
	and row_id = new.row_id
	and (select d_hour_offset_min from multi_obs where row_id = new.row_id) < 
		(select d_hour_offset_min from multi_obs
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date)
		)
		
	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date))
		> 0;	


--unset old row top hour if further and existing compare exists
update multi_obs
	set d_top_of_hour = null
	where cast(strftime('%M',new.m_date) as integer) <= 30
	and row_id = (select min(row_id) from multi_obs
			where d_top_of_hour = 1
			and sensor_id = new.sensor_id
			and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date))
			
	and (select d_hour_offset_min from multi_obs where row_id = new.row_id) <= 
		(select min(d_hour_offset_min) from multi_obs
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date)
		)
		
	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date))
		> 1;	

--set new row to top hour if no compare exists
update multi_obs
	set d_top_of_hour = 1
	where cast(strftime('%M',new.m_date) as integer) <= 30
	and row_id = new.row_id

	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',new.m_date))
		= 0;	

-- -------------------------------------------------------------
-- > 30 minutes

--set new row to top hour if closer and existing compare exists
update multi_obs
	set d_top_of_hour = 1
	where cast(strftime('%M',new.m_date) as integer) > 30
	and row_id = new.row_id
	and (select d_hour_offset_min from multi_obs where row_id = new.row_id) < 
		(select d_hour_offset_min from multi_obs
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour'))
		)
		
	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour')))
		> 0;	


--unset old row top hour if further and existing compare exists
--min(row_id) assumes always increasing row_id (no same table roll-over for same report hour)
update multi_obs
	set d_top_of_hour = null
	where cast(strftime('%M',new.m_date) as integer) > 30
	and row_id = (select min(row_id) from multi_obs
			where d_top_of_hour = 1
			and sensor_id = new.sensor_id
			and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour')))
			
	and (select d_hour_offset_min from multi_obs where row_id = new.row_id) <= 
		(select min(d_hour_offset_min) from multi_obs
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour'))
		)
		
	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour')))
		> 1;	

--set new row to top hour if no compare exists
update multi_obs
	set d_top_of_hour = 1
	where cast(strftime('%M',new.m_date) as integer) > 30
	and row_id = new.row_id

	and (select count(*) from multi_obs 
		where d_top_of_hour = 1
		and sensor_id = new.sensor_id
		and d_report_hour = strftime('%Y-%m-%dT%H:00:00',datetime(new.m_date,'+1 hour')))
		= 0;	


--


  END;

-- CREATE INDEX i_multi_obs_top_hour ON multi_obs (d_top_of_hour,d_report_hour);

