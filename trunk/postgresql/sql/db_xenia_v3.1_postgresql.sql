-- xenia postgresql schema version 3.1 (June 10, 2009)

-- -----------------------------------------------------------------------------------

-- data dictionary section for observations collected


CREATE TABLE obs_type (
    row_id integer NOT NULL,
    standard_name character varying(50),
    definition character varying(1000)
);


ALTER TABLE public.obs_type OWNER TO xeniaprod;
ALTER TABLE ONLY obs_type
    ADD CONSTRAINT obs_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.obs_type_pkey OWNER TO xeniaprod;

--

CREATE TABLE uom_type (
    row_id integer NOT NULL,
    standard_name character varying(50),
    definition character varying(1000),
    display character varying(50)
);


ALTER TABLE public.uom_type OWNER TO xeniaprod;
ALTER TABLE ONLY uom_type
    ADD CONSTRAINT uom_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.uom_type_pkey OWNER TO xeniaprod;

--

-- m_scalar_type defines a scalar reference

CREATE TABLE m_scalar_type (
    row_id integer NOT NULL,    
    obs_type_id integer,
    uom_type_id integer
);


ALTER TABLE public.m_scalar_type OWNER TO xeniaprod;
ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_scalar_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.m_scalar_type_pkey OWNER TO xeniaprod;

ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_type_obs_type_id_fkey FOREIGN KEY (obs_type_id) REFERENCES obs_type(row_id);
ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_type_uom_type_id_fkey FOREIGN KEY (uom_type_id) REFERENCES uom_type(row_id);

--

-- m_type defines a vector reference (all measurement types are vectors of 1 or more(num_types) scalars)

CREATE TABLE m_type (
    row_id integer NOT NULL,
    num_types integer NOT NULL default 1,
    description character varying(1000),
    m_scalar_type_id integer,
    m_scalar_type_id_2 integer,
    m_scalar_type_id_3 integer,
    m_scalar_type_id_4 integer,
    m_scalar_type_id_5 integer,
    m_scalar_type_id_6 integer,
    m_scalar_type_id_7 integer,
    m_scalar_type_id_8 integer    
);


ALTER TABLE public.m_type OWNER TO xeniaprod;
ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.m_type_pkey OWNER TO xeniaprod;

-- foreign key constraints for m_type

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_fkey FOREIGN KEY (m_scalar_type_id) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_2_fkey FOREIGN KEY (m_scalar_type_id_2) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_3_fkey FOREIGN KEY (m_scalar_type_id_3) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_4_fkey FOREIGN KEY (m_scalar_type_id_4) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_5_fkey FOREIGN KEY (m_scalar_type_id_5) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_6_fkey FOREIGN KEY (m_scalar_type_id_6) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_7_fkey FOREIGN KEY (m_scalar_type_id_7) REFERENCES m_scalar_type(row_id);

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_8_fkey FOREIGN KEY (m_scalar_type_id_8) REFERENCES m_scalar_type(row_id);

--

-- table m_type_display_order is used to determine the order in which measurement types are listed for various displays

CREATE TABLE m_type_display_order (
    row_id integer NOT NULL,
    m_type_id integer NOT NULL
);

ALTER TABLE public.m_type_display_order OWNER TO xeniaprod;
ALTER TABLE ONLY m_type_display_order
    ADD CONSTRAINT m_type_display_order_pkey PRIMARY KEY (row_id);
ALTER INDEX public.m_type_display_order_pkey OWNER TO xeniaprod;


-- -----------------------------------------------------------------------------------

-- product_type and timestamp_lkp are used in conjunction with imagery maps and can be ignored if not utilizing this type of metadata for applications

CREATE TABLE product_type (
    row_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.product_type OWNER TO xeniaprod;
ALTER TABLE ONLY product_type
    ADD CONSTRAINT product_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.product_type_pkey OWNER TO xeniaprod;

--

CREATE TABLE timestamp_lkp (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    product_id integer NOT NULL,
    pass_timestamp timestamp without time zone,
    filepath character varying(200)
);


ALTER TABLE public.timestamp_lkp OWNER TO xeniaprod;
ALTER TABLE ONLY timestamp_lkp
    ADD CONSTRAINT timestamp_lkp_pkey PRIMARY KEY (row_id);
ALTER INDEX public.timestamp_lkp_pkey OWNER TO xeniaprod;

ALTER TABLE ONLY timestamp_lkp
    ADD CONSTRAINT timestamp_lkp_product_id_fkey FOREIGN KEY (product_id) REFERENCES product_type(row_id);
	
-- -----------------------------------------------------------------------------------

-- app_catalog, project are available for use, but not required/utilized at this time
-- normally start with organization table

CREATE TABLE app_catalog (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    long_name character varying(200),
    description character varying(1000)
);


ALTER TABLE public.app_catalog OWNER TO xeniaprod;
ALTER TABLE ONLY app_catalog
    ADD CONSTRAINT app_catalog_pkey PRIMARY KEY (row_id);
ALTER INDEX public.app_catalog_pkey OWNER TO xeniaprod;

--

CREATE TABLE project (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    long_name character varying(200),
    description character varying(1000)
);


ALTER TABLE public.project OWNER TO xeniaprod;
ALTER TABLE ONLY project
    ADD CONSTRAINT project_pkey PRIMARY KEY (row_id);
ALTER INDEX public.project_pkey OWNER TO xeniaprod;

-- -----------------------------------------------------------------------------------

-- for table 'metadata' usage see http://code.google.com/p/xenia/wiki/XeniaUpdates section 'sqlite version 3'
-- table metadata not utilized at this time

CREATE TABLE metadata (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    metadata_id integer,
    active integer,
    schema_version varchar(200),
    schema_url varchar(500),
    file_url varchar(500),
    local_filepath varchar(500),
    begin_date timestamp,
    end_date timestamp
);

ALTER TABLE public.metadata OWNER TO xeniaprod;
ALTER TABLE ONLY metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (row_id);
ALTER INDEX public.metadata_pkey OWNER TO xeniaprod;

--

-- for table custom_fields usage see 'custom_fields' on page XeniaUpdates
-- table custom_fields not utilized at this time

CREATE TABLE custom_fields (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    metadata_id integer,
    ref_table varchar(50),
    ref_row_id integer,
    ref_date timestamp,
    custom_value double precision,
    custom_string varchar(200)    
);

ALTER TABLE public.custom_fields OWNER TO xeniaprod;
ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (row_id);
ALTER INDEX public.custom_fields_pkey OWNER TO xeniaprod;

-- -----------------------------------------------------------------------------------

CREATE TABLE organization (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    active integer,
    long_name character varying(200),
    description character varying(1000),
    url character varying(200),
    opendap_url character varying(200)
);


ALTER TABLE public.organization OWNER TO xeniaprod;
ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (row_id);
ALTER INDEX public.organization_pkey OWNER TO xeniaprod;

--

-- platform_type is available for use, but not required/utilized at this time

CREATE TABLE platform_type (
    row_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.platform_type OWNER TO xeniaprod;
ALTER TABLE ONLY platform_type
    ADD CONSTRAINT platform_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.platform_type_pkey OWNER TO xeniaprod;

--

CREATE TABLE platform (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    organization_id integer NOT NULL,
    type_id integer,
    short_name character varying(50),
    platform_handle character varying(100) NOT NULL,
    fixed_longitude double precision,
    fixed_latitude double precision,
    active integer,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    project_id integer,
    app_catalog_id integer,
    long_name character varying(200),
    description character varying(1000),
    url character varying(200),
    metadata_id integer
);


ALTER TABLE public.platform OWNER TO xeniaprod;
ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_pkey PRIMARY KEY (row_id);
ALTER INDEX public.platform_pkey OWNER TO xeniaprod;

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_app_catalog_id_fkey FOREIGN KEY (app_catalog_id) REFERENCES app_catalog(row_id);
ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(row_id);
ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(row_id);
ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_type_id_fkey FOREIGN KEY (type_id) REFERENCES platform_type(row_id);

-- -----------------------------------------------------------------------------------

-- sensor_type is available for use, but not required/utilized at this time

CREATE TABLE sensor_type (
    row_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.sensor_type OWNER TO xeniaprod;
ALTER TABLE ONLY sensor_type
    ADD CONSTRAINT sensor_type_pkey PRIMARY KEY (row_id);
ALTER INDEX public.sensor_type_pkey OWNER TO xeniaprod;

--

-- for table 'sensor' usage
-- only the NOT NULL fields in the sensor table are required to be populated, the other fields are included for metadata tracking purposes
-- report_interval default unit is minutes
-- see also http://code.google.com/p/xenia/wiki/InstrumentationExamples

CREATE TABLE sensor (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    platform_id integer NOT NULL,
    type_id integer,
    short_name character varying(50),
    m_type_id integer NOT NULL,
    fixed_z double precision,
    active integer,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    s_order integer NOT NULL default 1,
    url character varying(200),
    metadata_id integer,
    report_interval integer     
);

ALTER TABLE public.sensor OWNER TO xeniaprod;
ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_pkey PRIMARY KEY (row_id);
ALTER INDEX public.sensor_pkey OWNER TO xeniaprod;

ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_m_type_id_fkey FOREIGN KEY (m_type_id) REFERENCES m_type(row_id);
ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);
ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_type_id_fkey FOREIGN KEY (type_id) REFERENCES sensor_type(row_id);

--

-- -----------------------------------------------------------------------------------

CREATE TABLE multi_obs (
    row_id serial NOT NULL,
    row_entry_date timestamp with time zone NOT NULL default now(),
    row_update_date timestamp with time zone,
    platform_handle character varying(100) NOT NULL,
    sensor_id integer NOT NULL,
    m_type_id integer NOT NULL,
    m_date timestamp without time zone,
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
    qc_flag character varying(100),
    qc_metadata_id_2 integer,
    qc_level_2 integer,
    qc_flag_2 character varying(100),
    metadata_id integer,
    d_label_theta integer,
    d_top_of_hour integer,
    d_report_hour timestamp without time zone
);

ALTER TABLE public.multi_obs OWNER TO xeniaprod;
ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_pkey PRIMARY KEY (row_id);
ALTER INDEX public.multi_obs_pkey OWNER TO xeniaprod;

ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_m_type_id_fkey FOREIGN KEY (m_type_id) REFERENCES m_type(row_id);
ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES sensor(row_id);

-- ---------------------------------------------------------------------------------

CREATE UNIQUE INDEX i_platform ON platform (platform_handle);
ALTER INDEX public.i_platform OWNER TO xeniaprod;

CREATE UNIQUE INDEX i_sensor ON sensor (platform_id,m_type_id,s_order);
ALTER INDEX public.i_sensor OWNER TO xeniaprod;

CREATE UNIQUE INDEX i_multi_obs ON multi_obs USING btree (m_date,m_type_id,sensor_id);
ALTER INDEX public.i_multi_obs OWNER TO xeniaprod;

--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


