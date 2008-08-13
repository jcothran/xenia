-- xenia sqlite schema version 3 (May 31, 2008)

CREATE TABLE obs_type (
    row_id integer PRIMARY KEY,
    standard_name varchar(50),
    definition varchar(1000)
);

CREATE TABLE uom_type (
    row_id integer PRIMARY KEY,
    standard_name varchar(50),
    definition varchar(1000),
    display varchar(50)
);

CREATE TABLE m_scalar_type (
    row_id integer PRIMARY KEY,    
    obs_type_id integer,
    uom_type_id integer
);

CREATE TABLE m_type (
    row_id integer PRIMARY KEY,
    num_types integer NOT NULL default 1,
    description varchar(1000),
    m_scalar_type_id integer,
    m_scalar_type_id_2 integer,
    m_scalar_type_id_3 integer,
    m_scalar_type_id_4 integer,
    m_scalar_type_id_5 integer,
    m_scalar_type_id_6 integer,
    m_scalar_type_id_7 integer,
    m_scalar_type_id_8 integer    
);

-- table m_type_display_order is used to determine the order in which measurement types are listed for various displays

CREATE TABLE m_type_display_order (
    row_id integer PRIMARY KEY,
    m_type_id integer NOT NULL
);

-- -----------------------------------------------------------------------------------

CREATE TABLE timestamp_lkp (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    product_id integer NOT NULL,
    pass_timestamp timestamp,
    filepath varchar(200)
);

CREATE TABLE product_type (
    row_id integer PRIMARY KEY,
    type_name varchar(50) NOT NULL,
    description varchar(1000)
);

-- -----------------------------------------------------------------------------------

CREATE TABLE multi_obs (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    platform_handle varchar(100) NOT NULL,
    sensor_id integer NOT NULL,
    m_type_id integer NOT NULL,
    m_date timestamp NOT NULL,
    m_lon double precision,
    m_lat double precision,
    m_z double precision,
    m_value double precision,
    m_value_2 double precision,
    m_value_3 double precision, 
    m_value_4 double precision, 
    m_value_5 double precision, 
    m_value_6 double precision, 
    m_value_7 double precision, 
    m_value_8 double precision,     
    qc_metadata_id integer,
    qc_level integer,
    qc_flag varchar(100),
    qc_metadata_id_2 integer,
    qc_level_2 integer,
    qc_flag_2 varchar(100),
    metadata_id integer,
    d_label_theta integer,
    d_top_of_hour integer,
    d_report_hour timestamp
);

CREATE TABLE organization (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    short_name varchar(50) NOT NULL,
    active boolean,
    long_name varchar(200),
    description varchar(1000),
    url varchar(200),
    opendap_url varchar(200)
);

CREATE TABLE platform (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    organization_id integer NOT NULL,
    type_id integer,
    short_name varchar(50),
    platform_handle varchar(100) NOT NULL,
    fixed_longitude double precision,
    fixed_latitude double precision,
    active boolean,
    begin_date timestamp,
    end_date timestamp,
    project_id integer,
    app_catalog_id integer,
    long_name varchar(200),
    description varchar(1000),
    url varchar(200),
    metadata_id integer    
);

CREATE TABLE platform_type (
    row_id integer PRIMARY KEY,
    type_name varchar(50) NOT NULL,
    description varchar(1000)
);


CREATE TABLE project (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    short_name varchar(50) NOT NULL,
    long_name varchar(200),
    description varchar(1000)
);

CREATE TABLE app_catalog (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp default '2008-01-01',
    row_update_date timestamp default '2008-01-01',
    short_name varchar(50) NOT NULL,
    long_name varchar(200),
    description varchar(1000)
);

CREATE TABLE sensor (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    platform_id integer NOT NULL,
    type_id integer,
    short_name varchar(50),
    m_type_id integer NOT NULL,
    fixed_z double precision,
    active boolean,
    begin_date timestamp,
    end_date timestamp,
    s_order integer NOT NULL default 1,
    url varchar(200),
    metadata_id integer,
    report_interval integer
);

CREATE TABLE sensor_type (
    row_id integer PRIMARY KEY,
    type_name varchar(50) NOT NULL,
    description varchar(1000)
);

-- -----------------------------------------------------------------------------------

CREATE TABLE metadata (
    row_id integer PRIMARY KEY,
    row_entry_date timestamp,
    row_update_date timestamp,
    metadata_id integer,
    active integer,
    schema_version varchar(200),
    schema_url varchar(500),
    file_url varchar(500),
    local_filepath varchar(500),
    netcdf_filepath varchar(500),
    begin_date timestamp,
    end_data timestamp
);

CREATE UNIQUE INDEX i_platform ON platform (platform_handle);

CREATE UNIQUE INDEX i_sensor ON sensor (platform_id,m_type_id,s_order);

CREATE UNIQUE INDEX i_multi_obs ON multi_obs (m_type_id, m_date, sensor_id);





