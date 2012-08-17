--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: app_catalog; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE app_catalog (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    long_name character varying(200),
    description character varying(1000)
);


ALTER TABLE public.app_catalog OWNER TO xeniaprod;

--
-- Name: box2d; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2d;


--
-- Name: st_box2d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_in(cstring) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_in(cstring) OWNER TO postgres;

--
-- Name: st_box2d_out(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_out(box2d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_out(box2d) OWNER TO postgres;

--
-- Name: box2d; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box2d (
    INTERNALLENGTH = 16,
    INPUT = st_box2d_in,
    OUTPUT = st_box2d_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


ALTER TYPE public.box2d OWNER TO postgres;

--
-- Name: box3d; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box3d;


--
-- Name: st_box3d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box3d_in(cstring) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box3d_in(cstring) OWNER TO postgres;

--
-- Name: st_box3d_out(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box3d_out(box3d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box3d_out(box3d) OWNER TO postgres;

--
-- Name: box3d; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE box3d (
    INTERNALLENGTH = 48,
    INPUT = st_box3d_in,
    OUTPUT = st_box3d_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.box3d OWNER TO postgres;

--
-- Name: chip; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE chip;


--
-- Name: st_chip_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_chip_in(cstring) RETURNS chip
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_chip_in(cstring) OWNER TO postgres;

--
-- Name: st_chip_out(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_chip_out(chip) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_chip_out(chip) OWNER TO postgres;

--
-- Name: chip; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE chip (
    INTERNALLENGTH = variable,
    INPUT = st_chip_in,
    OUTPUT = st_chip_out,
    ALIGNMENT = double,
    STORAGE = extended
);


ALTER TYPE public.chip OWNER TO postgres;

--
-- Name: custom_fields; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE custom_fields (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    metadata_id integer,
    ref_table character varying(50),
    ref_row_id integer,
    ref_date timestamp without time zone,
    custom_value double precision,
    custom_string character varying(200)
);


ALTER TABLE public.custom_fields OWNER TO xeniaprod;

--
-- Name: geometry; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry;


--
-- Name: st_geometry_analyze(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_analyze(internal) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_analyze'
    LANGUAGE c STRICT;


ALTER FUNCTION public.st_geometry_analyze(internal) OWNER TO postgres;

--
-- Name: st_geometry_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_in(cstring) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_in(cstring) OWNER TO postgres;

--
-- Name: st_geometry_out(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_out(geometry) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_out(geometry) OWNER TO postgres;

--
-- Name: st_geometry_recv(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_recv(internal) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_recv'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_recv(internal) OWNER TO postgres;

--
-- Name: st_geometry_send(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_send(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_send'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_send(geometry) OWNER TO postgres;

--
-- Name: geometry; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry (
    INTERNALLENGTH = variable,
    INPUT = st_geometry_in,
    OUTPUT = st_geometry_out,
    RECEIVE = st_geometry_recv,
    SEND = st_geometry_send,
    ANALYZE = st_geometry_analyze,
    DELIMITER = ':',
    ALIGNMENT = int4,
    STORAGE = main
);


ALTER TYPE public.geometry OWNER TO postgres;

SET default_with_oids = true;

--
-- Name: geometry_columns; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE geometry_columns (
    f_table_catalog character varying(256) NOT NULL,
    f_table_schema character varying(256) NOT NULL,
    f_table_name character varying(256) NOT NULL,
    f_geometry_column character varying(256) NOT NULL,
    coord_dimension integer NOT NULL,
    srid integer NOT NULL,
    type character varying(30) NOT NULL
);


ALTER TABLE public.geometry_columns OWNER TO postgres;

--
-- Name: geometry_dump; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE geometry_dump AS (
	path integer[],
	geom geometry
);


ALTER TYPE public.geometry_dump OWNER TO postgres;

--
-- Name: histogram2d; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE histogram2d;


--
-- Name: st_histogram2d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_histogram2d_in(cstring) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwhistogram2d_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_histogram2d_in(cstring) OWNER TO postgres;

--
-- Name: st_histogram2d_out(histogram2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_histogram2d_out(histogram2d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwhistogram2d_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_histogram2d_out(histogram2d) OWNER TO postgres;

--
-- Name: histogram2d; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE histogram2d (
    INTERNALLENGTH = variable,
    INPUT = st_histogram2d_in,
    OUTPUT = st_histogram2d_out,
    ALIGNMENT = double,
    STORAGE = main
);


ALTER TYPE public.histogram2d OWNER TO postgres;

SET default_with_oids = false;

--
-- Name: loginuser; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE loginuser (
    id integer NOT NULL,
    username character varying(40),
    password character varying(50),
    regdate character varying(20),
    email character varying(100),
    show_email integer DEFAULT 0,
    last_login character varying(20),
    name character varying(100),
    address character varying(250),
    city character varying(100),
    state character varying(50),
    zip character varying(25),
    organization character varying(250),
    count integer
);


ALTER TABLE public.loginuser OWNER TO xeniaprod;

--
-- Name: m_scalar_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE m_scalar_type (
    row_id integer NOT NULL,
    obs_type_id integer,
    uom_type_id integer
);


ALTER TABLE public.m_scalar_type OWNER TO xeniaprod;

--
-- Name: m_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE m_type (
    row_id integer NOT NULL,
    num_types integer DEFAULT 1 NOT NULL,
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

--
-- Name: m_type_display_order; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE m_type_display_order (
    row_id integer NOT NULL,
    m_type_id integer NOT NULL
);


ALTER TABLE public.m_type_display_order OWNER TO xeniaprod;

--
-- Name: metadata; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE metadata (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    metadata_id integer,
    active integer,
    schema_version character varying(200),
    schema_url character varying(500),
    file_url character varying(500),
    local_filepath character varying(500),
    begin_date timestamp without time zone,
    end_date timestamp without time zone
);


ALTER TABLE public.metadata OWNER TO xeniaprod;

--
-- Name: geometrytype(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometrytype(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_getTYPE'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometrytype(geometry) OWNER TO postgres;

--
-- Name: ndims(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ndims(geometry) RETURNS smallint
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_ndims'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.ndims(geometry) OWNER TO postgres;

--
-- Name: srid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION srid(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_getSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.srid(geometry) OWNER TO postgres;

--
-- Name: multi_obs; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE multi_obs (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
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
    d_report_hour timestamp without time zone,
    the_geom geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((srid(the_geom) = (-1)))
);


ALTER TABLE public.multi_obs OWNER TO xeniaprod;

--
-- Name: obs_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE obs_type (
    row_id integer NOT NULL,
    standard_name character varying(50),
    definition character varying(1000)
);


ALTER TABLE public.obs_type OWNER TO xeniaprod;

--
-- Name: organization; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE organization (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    active integer,
    long_name character varying(200),
    description character varying(1000),
    url character varying(200),
    opendap_url character varying(200),
    email_tech character varying(150)
);


ALTER TABLE public.organization OWNER TO xeniaprod;

--
-- Name: platform; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE platform (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
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
    metadata_id integer,
    the_geom geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((srid(the_geom) = (-1)))
);


ALTER TABLE public.platform OWNER TO xeniaprod;

--
-- Name: platform_status; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE platform_status (
    row_id integer NOT NULL,
    organization_id integer,
    platform_handle character varying(50),
    row_entry_date timestamp without time zone,
    begin_date timestamp without time zone,
    expected_end_date timestamp without time zone,
    end_date timestamp without time zone,
    row_update_date timestamp without time zone,
    author character varying(100),
    reason character varying(500),
    status integer,
    platform_id integer
);


ALTER TABLE public.platform_status OWNER TO xeniaprod;

--
-- Name: platform_status_archive; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE platform_status_archive (
    row_id integer NOT NULL,
    organization_id integer,
    platform_id integer,
    row_entry_date timestamp without time zone,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    row_update_date timestamp without time zone,
    author character varying(100),
    reason character varying(500),
    status integer
);


ALTER TABLE public.platform_status_archive OWNER TO xeniaprod;

--
-- Name: platform_type_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE platform_type_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.platform_type_id_seq OWNER TO xeniaprod;

--
-- Name: platform_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE platform_type (
    row_id integer DEFAULT nextval('platform_type_id_seq'::regclass) NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000),
    short_name character varying(50)
);


ALTER TABLE public.platform_type OWNER TO xeniaprod;

--
-- Name: product_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE product_type (
    row_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.product_type OWNER TO xeniaprod;

--
-- Name: project; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE project (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    short_name character varying(50) NOT NULL,
    long_name character varying(200),
    description character varying(1000)
);


ALTER TABLE public.project OWNER TO xeniaprod;

--
-- Name: sensor; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE sensor (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    platform_id integer NOT NULL,
    type_id integer,
    short_name character varying(50),
    m_type_id integer NOT NULL,
    fixed_z double precision,
    active integer,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    s_order integer DEFAULT 1 NOT NULL,
    url character varying(200),
    metadata_id integer,
    report_interval integer
);


ALTER TABLE public.sensor OWNER TO xeniaprod;

--
-- Name: sensor_status; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE sensor_status (
    row_id integer NOT NULL,
    sensor_id integer,
    sensor_name character varying(50),
    platform_id integer,
    row_entry_date timestamp without time zone,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    expected_end_date timestamp without time zone,
    row_update_date timestamp without time zone,
    author character varying(100),
    reason character varying(500),
    status integer
);


ALTER TABLE public.sensor_status OWNER TO xeniaprod;

--
-- Name: sensor_status_archive; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE sensor_status_archive (
    row_id integer NOT NULL,
    sensor_id integer,
    platform_id integer,
    row_entry_date timestamp without time zone,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    row_update_date timestamp without time zone,
    author character varying(100),
    reason character varying(500),
    status integer
);


ALTER TABLE public.sensor_status_archive OWNER TO xeniaprod;

--
-- Name: sensor_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE sensor_type (
    row_id integer NOT NULL,
    type_name character varying(50) NOT NULL,
    description character varying(1000)
);


ALTER TABLE public.sensor_type OWNER TO xeniaprod;

--
-- Name: spatial_ref_sys; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE spatial_ref_sys (
    srid integer NOT NULL,
    auth_name character varying(256),
    auth_srid integer,
    srtext character varying(2048),
    proj4text character varying(2048)
);


ALTER TABLE public.spatial_ref_sys OWNER TO postgres;

--
-- Name: spheroid; Type: SHELL TYPE; Schema: public; Owner: postgres
--

CREATE TYPE spheroid;


--
-- Name: st_spheroid_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_spheroid_in(cstring) RETURNS spheroid
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'ellipsoid_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_spheroid_in(cstring) OWNER TO postgres;

--
-- Name: st_spheroid_out(spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_spheroid_out(spheroid) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'ellipsoid_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_spheroid_out(spheroid) OWNER TO postgres;

--
-- Name: spheroid; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE spheroid (
    INTERNALLENGTH = 65,
    INPUT = st_spheroid_in,
    OUTPUT = st_spheroid_out,
    ALIGNMENT = double,
    STORAGE = plain
);


ALTER TYPE public.spheroid OWNER TO postgres;

--
-- Name: status_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE status_type (
    row_id integer NOT NULL,
    description character varying(100),
    details character varying(150)
);


ALTER TABLE public.status_type OWNER TO xeniaprod;

--
-- Name: tablefunc_crosstab_2; Type: TYPE; Schema: public; Owner: xeniaprod
--

CREATE TYPE tablefunc_crosstab_2 AS (
	row_name text,
	category_1 text,
	category_2 text
);


ALTER TYPE public.tablefunc_crosstab_2 OWNER TO xeniaprod;

--
-- Name: tablefunc_crosstab_3; Type: TYPE; Schema: public; Owner: xeniaprod
--

CREATE TYPE tablefunc_crosstab_3 AS (
	row_name text,
	category_1 text,
	category_2 text,
	category_3 text
);


ALTER TYPE public.tablefunc_crosstab_3 OWNER TO xeniaprod;

--
-- Name: tablefunc_crosstab_4; Type: TYPE; Schema: public; Owner: xeniaprod
--

CREATE TYPE tablefunc_crosstab_4 AS (
	row_name text,
	category_1 text,
	category_2 text,
	category_3 text,
	category_4 text
);


ALTER TYPE public.tablefunc_crosstab_4 OWNER TO xeniaprod;

--
-- Name: timestamp_lkp; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE timestamp_lkp (
    row_id integer NOT NULL,
    row_entry_date timestamp with time zone DEFAULT now() NOT NULL,
    row_update_date timestamp with time zone,
    product_id integer NOT NULL,
    pass_timestamp timestamp without time zone,
    filepath character varying(200)
);


ALTER TABLE public.timestamp_lkp OWNER TO xeniaprod;

--
-- Name: uom_type; Type: TABLE; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE TABLE uom_type (
    row_id integer NOT NULL,
    standard_name character varying(50),
    definition character varying(1000),
    display character varying(50),
    alt_name character varying(50)
);


ALTER TABLE public.uom_type OWNER TO xeniaprod;

--
-- Name: _st_asgml(integer, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_asgml(integer, geometry, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asGML'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_asgml(integer, geometry, integer) OWNER TO postgres;

--
-- Name: _st_askml(integer, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_askml(integer, geometry, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asKML'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_askml(integer, geometry, integer) OWNER TO postgres;

--
-- Name: _st_contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_contains(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'contains'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_contains(geometry, geometry) OWNER TO postgres;

--
-- Name: _st_crosses(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_crosses(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'crosses'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_crosses(geometry, geometry) OWNER TO postgres;

--
-- Name: _st_intersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_intersects(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'intersects'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_intersects(geometry, geometry) OWNER TO postgres;

--
-- Name: _st_overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_overlaps(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'overlaps'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_overlaps(geometry, geometry) OWNER TO postgres;

--
-- Name: _st_touches(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_touches(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'touches'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_touches(geometry, geometry) OWNER TO postgres;

--
-- Name: _st_within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION _st_within(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'within'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public._st_within(geometry, geometry) OWNER TO postgres;

--
-- Name: addauth(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addauth(text) RETURNS boolean
    AS $_$
DECLARE
	lockid alias for $1;
	okay boolean;
	myrec record;
BEGIN
	-- check to see if table exists
	--  if not, CREATE TEMP TABLE mylock (transid xid, lockcode text)
	okay := 'f';
	FOR myrec IN SELECT * FROM pg_class WHERE relname = 'temp_lock_have_table' LOOP
		okay := 't';
	END LOOP; 
	IF (okay <> 't') THEN 
		CREATE TEMP TABLE temp_lock_have_table (transid xid, lockcode text);
			-- this will only work from pgsql7.4 up
			-- ON COMMIT DELETE ROWS;
	END IF;

	--  INSERT INTO mylock VALUES ( $1)
--	EXECUTE 'INSERT INTO temp_lock_have_table VALUES ( '||
--		quote_literal(getTransactionID()) || ',' ||
--		quote_literal(lockid) ||')';

	INSERT INTO temp_lock_have_table VALUES (getTransactionID(), lockid);

	RETURN true::boolean;
END;
$_$
    LANGUAGE plpgsql;


ALTER FUNCTION public.addauth(text) OWNER TO postgres;

--
-- Name: addbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addbbox(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.addbbox(geometry) OWNER TO postgres;

--
-- Name: addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer) RETURNS text
    AS $_$
DECLARE
	catalog_name alias for $1;
	schema_name alias for $2;
	table_name alias for $3;
	column_name alias for $4;
	new_srid alias for $5;
	new_type alias for $6;
	new_dim alias for $7;
	rec RECORD;
	schema_ok bool;
	real_schema name;

BEGIN

	IF ( not ( (new_type ='GEOMETRY') or
		   (new_type ='GEOMETRYCOLLECTION') or
		   (new_type ='POINT') or 
		   (new_type ='MULTIPOINT') or
		   (new_type ='POLYGON') or
		   (new_type ='MULTIPOLYGON') or
		   (new_type ='LINESTRING') or
		   (new_type ='MULTILINESTRING') or
		   (new_type ='GEOMETRYCOLLECTIONM') or
		   (new_type ='POINTM') or 
		   (new_type ='MULTIPOINTM') or
		   (new_type ='POLYGONM') or
		   (new_type ='MULTIPOLYGONM') or
		   (new_type ='LINESTRINGM') or
		   (new_type ='MULTILINESTRINGM') or
                   (new_type = 'CIRCULARSTRING') or
                   (new_type = 'CIRCULARSTRINGM') or
                   (new_type = 'COMPOUNDCURVE') or
                   (new_type = 'COMPOUNDCURVEM') or
                   (new_type = 'CURVEPOLYGON') or
                   (new_type = 'CURVEPOLYGONM') or
                   (new_type = 'MULTICURVE') or
                   (new_type = 'MULTICURVEM') or
                   (new_type = 'MULTISURFACE') or
                   (new_type = 'MULTISURFACEM')) )
	THEN
		RAISE EXCEPTION 'Invalid type name - valid ones are: 
			GEOMETRY, GEOMETRYCOLLECTION, POINT, 
			MULTIPOINT, POLYGON, MULTIPOLYGON, 
			LINESTRING, MULTILINESTRING,
                        CIRCULARSTRING, COMPOUNDCURVE,
                        CURVEPOLYGON, MULTICURVE, MULTISURFACE,
			GEOMETRYCOLLECTIONM, POINTM, 
			MULTIPOINTM, POLYGONM, MULTIPOLYGONM, 
			LINESTRINGM, MULTILINESTRINGM 
                        CIRCULARSTRINGM, COMPOUNDCURVEM,
                        CURVEPOLYGONM, MULTICURVEM or MULTISURFACEM';
		return 'fail';
	END IF;

	IF ( (new_dim >4) or (new_dim <0) ) THEN
		RAISE EXCEPTION 'invalid dimension';
		return 'fail';
	END IF;

	IF ( (new_type LIKE '%M') and (new_dim!=3) ) THEN

		RAISE EXCEPTION 'TypeM needs 3 dimensions';
		return 'fail';
	END IF;

	IF ( schema_name != '' ) THEN
		schema_ok = 'f';
		FOR rec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			schema_ok := 't';
		END LOOP;

		if ( schema_ok <> 't' ) THEN
			RAISE NOTICE 'Invalid schema name - using current_schema()';
			SELECT current_schema() into real_schema;
		ELSE
			real_schema = schema_name;
		END IF;

	ELSE
		SELECT current_schema() into real_schema;
	END IF;


	-- Add geometry column

	EXECUTE 'ALTER TABLE ' ||
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD COLUMN ' || quote_ident(column_name) || 
		' geometry ';


	-- Delete stale record in geometry_column (if any)

	EXECUTE 'DELETE FROM geometry_columns WHERE
		f_table_catalog = ' || quote_literal('') || 
		' AND f_table_schema = ' ||
		quote_literal(real_schema) || 
		' AND f_table_name = ' || quote_literal(table_name) ||
		' AND f_geometry_column = ' || quote_literal(column_name);


	-- Add record in geometry_column 

	EXECUTE 'INSERT INTO geometry_columns VALUES (' ||
		quote_literal('') || ',' ||
		quote_literal(real_schema) || ',' ||
		quote_literal(table_name) || ',' ||
		quote_literal(column_name) || ',' ||
		new_dim::text || ',' || new_srid::text || ',' ||
		quote_literal(new_type) || ')';

	-- Add table checks

	EXECUTE 'ALTER TABLE ' || 
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD CONSTRAINT ' 
		|| quote_ident('enforce_srid_' || column_name)
		|| ' CHECK (SRID(' || quote_ident(column_name) ||
		') = ' || new_srid::text || ')' ;

	EXECUTE 'ALTER TABLE ' || 
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD CONSTRAINT '
		|| quote_ident('enforce_dims_' || column_name)
		|| ' CHECK (ndims(' || quote_ident(column_name) ||
		') = ' || new_dim::text || ')' ;

	IF (not(new_type = 'GEOMETRY')) THEN
		EXECUTE 'ALTER TABLE ' || 
		quote_ident(real_schema) || '.' || quote_ident(table_name)
		|| ' ADD CONSTRAINT '
		|| quote_ident('enforce_geotype_' || column_name)
		|| ' CHECK (geometrytype(' ||
		quote_ident(column_name) || ')=' ||
		quote_literal(new_type) || ' OR (' ||
		quote_ident(column_name) || ') is null)';
	END IF;

	return 
		real_schema || '.' || 
		table_name || '.' || column_name ||
		' SRID:' || new_srid::text ||
		' TYPE:' || new_type || 
		' DIMS:' || new_dim::text || chr(10) || ' '; 
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, character varying, character varying, integer, character varying, integer) OWNER TO postgres;

--
-- Name: addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer) RETURNS text
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('',$1,$2,$3,$4,$5,$6) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STABLE STRICT;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, character varying, integer, character varying, integer) OWNER TO postgres;

--
-- Name: addgeometrycolumn(character varying, character varying, integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addgeometrycolumn(character varying, character varying, integer, character varying, integer) RETURNS text
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT AddGeometryColumn('','',$1,$2,$3,$4,$5) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.addgeometrycolumn(character varying, character varying, integer, character varying, integer) OWNER TO postgres;

--
-- Name: addpoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addpoint(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.addpoint(geometry, geometry) OWNER TO postgres;

--
-- Name: addpoint(geometry, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addpoint(geometry, geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.addpoint(geometry, geometry, integer) OWNER TO postgres;

--
-- Name: affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_affine'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $2, $3, 0,  $4, $5, 0,  0, 0, 1,  $6, $7, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: area(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION area(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_area_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.area(geometry) OWNER TO postgres;

--
-- Name: area2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION area2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_area_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.area2d(geometry) OWNER TO postgres;

--
-- Name: asbinary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asbinary(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asBinary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.asbinary(geometry) OWNER TO postgres;

--
-- Name: asbinary(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asbinary(geometry, text) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asBinary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.asbinary(geometry, text) OWNER TO postgres;

--
-- Name: asewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asewkb(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'WKBFromLWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.asewkb(geometry) OWNER TO postgres;

--
-- Name: asewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asewkb(geometry, text) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'WKBFromLWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.asewkb(geometry, text) OWNER TO postgres;

--
-- Name: asewkt(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asewkt(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asEWKT'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.asewkt(geometry) OWNER TO postgres;

--
-- Name: asgml(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asgml(geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsGML(2, $1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.asgml(geometry, integer) OWNER TO postgres;

--
-- Name: asgml(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION asgml(geometry) RETURNS text
    AS $_$SELECT _ST_AsGML(2, $1, 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.asgml(geometry) OWNER TO postgres;

--
-- Name: ashexewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ashexewkb(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asHEXEWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.ashexewkb(geometry) OWNER TO postgres;

--
-- Name: ashexewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ashexewkb(geometry, text) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asHEXEWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.ashexewkb(geometry, text) OWNER TO postgres;

--
-- Name: askml(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION askml(geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsKML(2, transform($1,4326), $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.askml(geometry, integer) OWNER TO postgres;

--
-- Name: askml(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION askml(geometry) RETURNS text
    AS $_$SELECT _ST_AsKML(2, transform($1,4326), 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.askml(geometry) OWNER TO postgres;

--
-- Name: askml(integer, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION askml(integer, geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsKML($1, transform($2,4326), $3)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.askml(integer, geometry, integer) OWNER TO postgres;

--
-- Name: assvg(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION assvg(geometry, integer, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.assvg(geometry, integer, integer) OWNER TO postgres;

--
-- Name: assvg(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION assvg(geometry, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.assvg(geometry, integer) OWNER TO postgres;

--
-- Name: assvg(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION assvg(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.assvg(geometry) OWNER TO postgres;

--
-- Name: astext(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION astext(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asText'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.astext(geometry) OWNER TO postgres;

--
-- Name: azimuth(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION azimuth(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_azimuth'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.azimuth(geometry, geometry) OWNER TO postgres;

--
-- Name: bdmpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION bdmpolyfromtext(text, integer) RETURNS geometry
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := multi(BuildArea(mline));

	RETURN geom;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.bdmpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: bdpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION bdpolyfromtext(text, integer) RETURNS geometry
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := BuildArea(mline);

	IF GeometryType(geom) != 'POLYGON'
	THEN
		RAISE EXCEPTION 'Input returns more then a single polygon, try using BdMPolyFromText instead';
	END IF;

	RETURN geom;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.bdpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: boundary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION boundary(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'boundary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.boundary(geometry) OWNER TO postgres;

--
-- Name: box(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box(geometry) RETURNS box
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box(geometry) OWNER TO postgres;

--
-- Name: box(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box(box3d) RETURNS box
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_BOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box(box3d) OWNER TO postgres;

--
-- Name: box2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d(geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX2DFLOAT4'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d(geometry) OWNER TO postgres;

--
-- Name: box2d(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d(box3d) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_BOX2DFLOAT4'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d(box3d) OWNER TO postgres;

--
-- Name: box2d_contain(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_contain(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_contain'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_contain(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_contained(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_contained(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_contained'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_contained(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_in(cstring) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_in(cstring) OWNER TO postgres;

--
-- Name: box2d_intersects(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_intersects(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_intersects'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_intersects(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_left(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_left(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_left'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_left(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_out(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_out(box2d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_out(box2d) OWNER TO postgres;

--
-- Name: box2d_overlap(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_overlap(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overlap'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_overlap(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_overleft(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_overleft(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overleft'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_overleft(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_overright(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_overright(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overright'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_overright(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_right(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_right(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_right'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_right(box2d, box2d) OWNER TO postgres;

--
-- Name: box2d_same(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box2d_same(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_same'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box2d_same(box2d, box2d) OWNER TO postgres;

--
-- Name: box3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d(geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX3D'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box3d(geometry) OWNER TO postgres;

--
-- Name: box3d(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d(box2d) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_to_BOX3D'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box3d(box2d) OWNER TO postgres;

--
-- Name: box3d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d_in(cstring) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box3d_in(cstring) OWNER TO postgres;

--
-- Name: box3d_out(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3d_out(box3d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.box3d_out(box3d) OWNER TO postgres;

--
-- Name: box3dtobox(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION box3dtobox(box3d) RETURNS box
    AS $_$SELECT box($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.box3dtobox(box3d) OWNER TO postgres;

--
-- Name: buffer(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION buffer(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'buffer'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.buffer(geometry, double precision) OWNER TO postgres;

--
-- Name: buffer(geometry, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION buffer(geometry, double precision, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'buffer'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.buffer(geometry, double precision, integer) OWNER TO postgres;

--
-- Name: build_histogram2d(histogram2d, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION build_histogram2d(histogram2d, text, text) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'build_lwhistogram2d'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.build_histogram2d(histogram2d, text, text) OWNER TO postgres;

--
-- Name: build_histogram2d(histogram2d, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION build_histogram2d(histogram2d, text, text, text) RETURNS histogram2d
    AS $_$
BEGIN
	EXECUTE 'SET local search_path = '||$2||',public';
	RETURN public.build_histogram2d($1,$3,$4);
END
$_$
    LANGUAGE plpgsql STABLE STRICT;


ALTER FUNCTION public.build_histogram2d(histogram2d, text, text, text) OWNER TO postgres;

--
-- Name: buildarea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION buildarea(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_buildarea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.buildarea(geometry) OWNER TO postgres;

--
-- Name: bytea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION bytea(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_bytea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.bytea(geometry) OWNER TO postgres;

--
-- Name: cache_bbox(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION cache_bbox() RETURNS trigger
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'cache_bbox'
    LANGUAGE c;


ALTER FUNCTION public.cache_bbox() OWNER TO postgres;

--
-- Name: centroid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION centroid(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'centroid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.centroid(geometry) OWNER TO postgres;

--
-- Name: checkauth(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauth(text, text, text) RETURNS integer
    AS $_$
DECLARE
	schema text;
BEGIN
	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	if ( $1 != '' ) THEN
		schema = $1;
	ELSE
		SELECT current_schema() into schema;
	END IF;

	-- TODO: check for an already existing trigger ?

	EXECUTE 'CREATE TRIGGER check_auth BEFORE UPDATE OR DELETE ON ' 
		|| quote_ident(schema) || '.' || quote_ident($2)
		||' FOR EACH ROW EXECUTE PROCEDURE CheckAuthTrigger('
		|| quote_literal($3) || ')';

	RETURN 0;
END;
$_$
    LANGUAGE plpgsql;


ALTER FUNCTION public.checkauth(text, text, text) OWNER TO postgres;

--
-- Name: checkauth(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauth(text, text) RETURNS integer
    AS $_$SELECT CheckAuth('', $1, $2)$_$
    LANGUAGE sql;


ALTER FUNCTION public.checkauth(text, text) OWNER TO postgres;

--
-- Name: checkauthtrigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION checkauthtrigger() RETURNS trigger
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'check_authorization'
    LANGUAGE c;


ALTER FUNCTION public.checkauthtrigger() OWNER TO postgres;

--
-- Name: chip_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION chip_in(cstring) RETURNS chip
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.chip_in(cstring) OWNER TO postgres;

--
-- Name: chip_out(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION chip_out(chip) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.chip_out(chip) OWNER TO postgres;

--
-- Name: collect(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION collect(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.collect(geometry, geometry) OWNER TO postgres;

--
-- Name: collect_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION collect_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.collect_garray(geometry[]) OWNER TO postgres;

--
-- Name: collector(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION collector(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.collector(geometry, geometry) OWNER TO postgres;

--
-- Name: combine_bbox(box2d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION combine_bbox(box2d, geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_combine'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.combine_bbox(box2d, geometry) OWNER TO postgres;

--
-- Name: combine_bbox(box3d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION combine_bbox(box3d, geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_combine'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.combine_bbox(box3d, geometry) OWNER TO postgres;

--
-- Name: compression(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION compression(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getCompression'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.compression(chip) OWNER TO postgres;

--
-- Name: connectby(text, text, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION connectby(text, text, text, text, integer, text) RETURNS SETOF record
    AS '$libdir/tablefunc', 'connectby_text'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.connectby(text, text, text, text, integer, text) OWNER TO postgres;

--
-- Name: connectby(text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION connectby(text, text, text, text, integer) RETURNS SETOF record
    AS '$libdir/tablefunc', 'connectby_text'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.connectby(text, text, text, text, integer) OWNER TO postgres;

--
-- Name: connectby(text, text, text, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION connectby(text, text, text, text, text, integer, text) RETURNS SETOF record
    AS '$libdir/tablefunc', 'connectby_text_serial'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.connectby(text, text, text, text, text, integer, text) OWNER TO postgres;

--
-- Name: connectby(text, text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION connectby(text, text, text, text, text, integer) RETURNS SETOF record
    AS '$libdir/tablefunc', 'connectby_text_serial'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.connectby(text, text, text, text, text, integer) OWNER TO postgres;

--
-- Name: contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION contains(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'contains'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.contains(geometry, geometry) OWNER TO postgres;

--
-- Name: convexhull(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION convexhull(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'convexhull'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.convexhull(geometry) OWNER TO postgres;

--
-- Name: create_histogram2d(box2d, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_histogram2d(box2d, integer) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'create_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.create_histogram2d(box2d, integer) OWNER TO postgres;

--
-- Name: crosses(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosses(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'crosses'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.crosses(geometry, geometry) OWNER TO postgres;

--
-- Name: crosstab(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab(text) RETURNS SETOF record
    AS '$libdir/tablefunc', 'crosstab'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab(text) OWNER TO postgres;

--
-- Name: crosstab(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab(text, integer) RETURNS SETOF record
    AS '$libdir/tablefunc', 'crosstab'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab(text, integer) OWNER TO postgres;

--
-- Name: crosstab(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab(text, text) RETURNS SETOF record
    AS '$libdir/tablefunc', 'crosstab_hash'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab(text, text) OWNER TO postgres;

--
-- Name: crosstab2(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab2(text) RETURNS SETOF tablefunc_crosstab_2
    AS '$libdir/tablefunc', 'crosstab'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab2(text) OWNER TO postgres;

--
-- Name: crosstab3(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab3(text) RETURNS SETOF tablefunc_crosstab_3
    AS '$libdir/tablefunc', 'crosstab'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab3(text) OWNER TO postgres;

--
-- Name: crosstab4(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION crosstab4(text) RETURNS SETOF tablefunc_crosstab_4
    AS '$libdir/tablefunc', 'crosstab'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.crosstab4(text) OWNER TO postgres;

--
-- Name: datatype(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION datatype(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getDatatype'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.datatype(chip) OWNER TO postgres;

--
-- Name: difference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION difference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'difference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.difference(geometry, geometry) OWNER TO postgres;

--
-- Name: dimension(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dimension(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dimension'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.dimension(geometry) OWNER TO postgres;

--
-- Name: disablelongtransactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION disablelongtransactions() RETURNS text
    AS $$
DECLARE
	rec RECORD;

BEGIN

	--
	-- Drop all triggers applied by CheckAuth()
	--
	FOR rec IN
		SELECT c.relname, t.tgname, t.tgargs FROM pg_trigger t, pg_class c, pg_proc p
		WHERE p.proname = 'checkauthtrigger' and t.tgfoid = p.oid and t.tgrelid = c.oid
	LOOP
		EXECUTE 'DROP TRIGGER ' || quote_ident(rec.tgname) ||
			' ON ' || quote_ident(rec.relname);
	END LOOP;

	--
	-- Drop the authorization_table table
	--
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorization_table' LOOP
		DROP TABLE authorization_table;
	END LOOP;

	--
	-- Drop the authorized_tables view
	--
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorized_tables' LOOP
		DROP VIEW authorized_tables;
	END LOOP;

	RETURN 'Long transactions support disabled';
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.disablelongtransactions() OWNER TO postgres;

--
-- Name: disjoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION disjoint(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'disjoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.disjoint(geometry, geometry) OWNER TO postgres;

--
-- Name: distance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION distance(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_mindistance2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.distance(geometry, geometry) OWNER TO postgres;

--
-- Name: distance_sphere(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION distance_sphere(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_distance_sphere'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.distance_sphere(geometry, geometry) OWNER TO postgres;

--
-- Name: distance_spheroid(geometry, geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION distance_spheroid(geometry, geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_distance_ellipsoid_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.distance_spheroid(geometry, geometry, spheroid) OWNER TO postgres;

--
-- Name: dropbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropbbox(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dropBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.dropbbox(geometry) OWNER TO postgres;

--
-- Name: dropgeometrycolumn(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(character varying, character varying, character varying, character varying) RETURNS text
    AS $_$
DECLARE
	catalog_name alias for $1; 
	schema_name alias for $2;
	table_name alias for $3;
	column_name alias for $4;
	myrec RECORD;
	okay boolean;
	real_schema name;

BEGIN


	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = 'f';

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := 't';
		END LOOP;

		IF ( okay <> 't' ) THEN
			RAISE NOTICE 'Invalid schema name - using current_schema()';
			SELECT current_schema() into real_schema;
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT current_schema() into real_schema;
	END IF;

 	-- Find out if the column is in the geometry_columns table
	okay = 'f';
	FOR myrec IN SELECT * from geometry_columns where f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := 't';
	END LOOP; 
	IF (okay <> 't') THEN 
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN 'f';
	END IF;

	-- Remove ref from geometry_columns table
	EXECUTE 'delete from geometry_columns where f_table_schema = ' ||
		quote_literal(real_schema) || ' and f_table_name = ' ||
		quote_literal(table_name)  || ' and f_geometry_column = ' ||
		quote_literal(column_name);
	
	-- Remove table column
	EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) || '.' ||
		quote_ident(table_name) || ' DROP COLUMN ' ||
		quote_ident(column_name);


	RETURN real_schema || '.' || table_name || '.' || column_name ||' effectively removed.';
	
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.dropgeometrycolumn(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: dropgeometrycolumn(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(character varying, character varying, character varying) RETURNS text
    AS $_$
DECLARE
	ret text;
BEGIN
	SELECT DropGeometryColumn('',$1,$2,$3) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.dropgeometrycolumn(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: dropgeometrycolumn(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrycolumn(character varying, character varying) RETURNS text
    AS $_$
DECLARE
	ret text;
BEGIN
	SELECT DropGeometryColumn('','',$1,$2) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.dropgeometrycolumn(character varying, character varying) OWNER TO postgres;

--
-- Name: dropgeometrytable(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(character varying, character varying, character varying) RETURNS text
    AS $_$
DECLARE
	catalog_name alias for $1; 
	schema_name alias for $2;
	table_name alias for $3;
	real_schema name;

BEGIN

	IF ( schema_name = '' ) THEN
		SELECT current_schema() into real_schema;
	ELSE
		real_schema = schema_name;
	END IF;

	-- Remove refs from geometry_columns table
	EXECUTE 'DELETE FROM geometry_columns WHERE ' ||
		'f_table_schema = ' || quote_literal(real_schema) ||
		' AND ' ||
		' f_table_name = ' || quote_literal(table_name);
	
	-- Remove table 
	EXECUTE 'DROP TABLE '
		|| quote_ident(real_schema) || '.' ||
		quote_ident(table_name);

	RETURN
		real_schema || '.' ||
		table_name ||' dropped.';
	
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.dropgeometrytable(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: dropgeometrytable(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(character varying, character varying) RETURNS text
    AS $_$SELECT DropGeometryTable('',$1,$2)$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.dropgeometrytable(character varying, character varying) OWNER TO postgres;

--
-- Name: dropgeometrytable(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dropgeometrytable(character varying) RETURNS text
    AS $_$SELECT DropGeometryTable('','',$1)$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.dropgeometrytable(character varying) OWNER TO postgres;

--
-- Name: dump(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dump(geometry) RETURNS SETOF geometry_dump
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dump'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.dump(geometry) OWNER TO postgres;

--
-- Name: dumprings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION dumprings(geometry) RETURNS SETOF geometry_dump
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dump_rings'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.dumprings(geometry) OWNER TO postgres;

--
-- Name: enablelongtransactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION enablelongtransactions() RETURNS text
    AS $$
DECLARE
	"query" text;
	exists bool;
	rec RECORD;

BEGIN

	exists = 'f';
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorization_table'
	LOOP
		exists = 't';
	END LOOP;

	IF NOT exists
	THEN
		"query" = 'CREATE TABLE authorization_table (
			toid oid, -- table oid
			rid text, -- row id
			expires timestamp,
			authid text
		)';
		EXECUTE "query";
	END IF;

	exists = 'f';
	FOR rec IN SELECT * FROM pg_class WHERE relname = 'authorized_tables'
	LOOP
		exists = 't';
	END LOOP;

	IF NOT exists THEN
		"query" = 'CREATE VIEW authorized_tables AS ' ||
			'SELECT ' ||
			'n.nspname as schema, ' ||
			'c.relname as table, trim(' ||
			quote_literal(chr(92) || '000') ||
			' from t.tgargs) as id_column ' ||
			'FROM pg_trigger t, pg_class c, pg_proc p ' ||
			', pg_namespace n ' ||
			'WHERE p.proname = ' || quote_literal('checkauthtrigger') ||
			' AND c.relnamespace = n.oid' ||
			' AND t.tgfoid = p.oid and t.tgrelid = c.oid';
		EXECUTE "query";
	END IF;

	RETURN 'Long transactions support enabled';
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.enablelongtransactions() OWNER TO postgres;

--
-- Name: endpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION endpoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_endpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.endpoint(geometry) OWNER TO postgres;

--
-- Name: envelope(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION envelope(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_envelope'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.envelope(geometry) OWNER TO postgres;

--
-- Name: equals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION equals(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'geomequals'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.equals(geometry, geometry) OWNER TO postgres;

--
-- Name: estimate_histogram2d(histogram2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION estimate_histogram2d(histogram2d, box2d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'estimate_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.estimate_histogram2d(histogram2d, box2d) OWNER TO postgres;

--
-- Name: estimated_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION estimated_extent(text, text, text) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_estimated_extent'
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER;


ALTER FUNCTION public.estimated_extent(text, text, text) OWNER TO postgres;

--
-- Name: estimated_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION estimated_extent(text, text) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_estimated_extent'
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER;


ALTER FUNCTION public.estimated_extent(text, text) OWNER TO postgres;

--
-- Name: expand(box3d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION expand(box3d, double precision) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.expand(box3d, double precision) OWNER TO postgres;

--
-- Name: expand(box2d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION expand(box2d, double precision) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.expand(box2d, double precision) OWNER TO postgres;

--
-- Name: expand(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION expand(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.expand(geometry, double precision) OWNER TO postgres;

--
-- Name: explode_histogram2d(histogram2d, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION explode_histogram2d(histogram2d, text) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'explode_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.explode_histogram2d(histogram2d, text) OWNER TO postgres;

--
-- Name: exteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION exteriorring(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_exteriorring_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.exteriorring(geometry) OWNER TO postgres;

--
-- Name: factor(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION factor(chip) RETURNS real
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getFactor'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.factor(chip) OWNER TO postgres;

--
-- Name: find_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_extent(text, text, text) RETURNS box2d
    AS $_$
DECLARE
	schemaname alias for $1;
	tablename alias for $2;
	columnname alias for $3;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT extent("'||columnname||'") FROM "'||schemaname||'"."'||tablename||'"' LOOP
		return myrec.extent;
	END LOOP; 
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.find_extent(text, text, text) OWNER TO postgres;

--
-- Name: find_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_extent(text, text) RETURNS box2d
    AS $_$
DECLARE
	tablename alias for $1;
	columnname alias for $2;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT extent("'||columnname||'") FROM "'||tablename||'"' LOOP
		return myrec.extent;
	END LOOP; 
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.find_extent(text, text) OWNER TO postgres;

--
-- Name: find_srid(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION find_srid(character varying, character varying, character varying) RETURNS integer
    AS $_$DECLARE
   schem text;
   tabl text;
   sr int4;
BEGIN
   IF $1 IS NULL THEN
      RAISE EXCEPTION 'find_srid() - schema is NULL!';
   END IF;
   IF $2 IS NULL THEN
      RAISE EXCEPTION 'find_srid() - table name is NULL!';
   END IF;
   IF $3 IS NULL THEN
      RAISE EXCEPTION 'find_srid() - column name is NULL!';
   END IF;
   schem = $1;
   tabl = $2;
-- if the table contains a . and the schema is empty
-- split the table into a schema and a table
-- otherwise drop through to default behavior
   IF ( schem = '' and tabl LIKE '%.%' ) THEN
     schem = substr(tabl,1,strpos(tabl,'.')-1);
     tabl = substr(tabl,length(schem)+2);
   ELSE
     schem = schem || '%';
   END IF;

   select SRID into sr from geometry_columns where f_table_schema like schem and f_table_name = tabl and f_geometry_column = $3;
   IF NOT FOUND THEN
       RAISE EXCEPTION 'find_srid() - couldnt find the corresponding SRID - is the geometry registered in the GEOMETRY_COLUMNS table?  Is there an uppercase/lowercase missmatch?';
   END IF;
  return sr;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.find_srid(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: fix_geometry_columns(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fix_geometry_columns() RETURNS text
    AS $$
DECLARE
	mislinked record;
	result text;
	linked integer;
	deleted integer;
	foundschema integer;
BEGIN

	-- Since 7.3 schema support has been added.
	-- Previous postgis versions used to put the database name in
	-- the schema column. This needs to be fixed, so we try to 
	-- set the correct schema for each geometry_colums record
	-- looking at table, column, type and srid.
	UPDATE geometry_columns SET f_table_schema = n.nspname
		FROM pg_namespace n, pg_class c, pg_attribute a,
			pg_constraint sridcheck, pg_constraint typecheck
                WHERE ( f_table_schema is NULL
		OR f_table_schema = ''
                OR f_table_schema NOT IN (
                        SELECT nspname::varchar
                        FROM pg_namespace nn, pg_class cc, pg_attribute aa
                        WHERE cc.relnamespace = nn.oid
                        AND cc.relname = f_table_name::name
                        AND aa.attrelid = cc.oid
                        AND aa.attname = f_geometry_column::name))
                AND f_table_name::name = c.relname
                AND c.oid = a.attrelid
                AND c.relnamespace = n.oid
                AND f_geometry_column::name = a.attname

                AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(srid(% = %)'
                AND sridcheck.consrc ~ textcat(' = ', srid::text)

                AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
	'((geometrytype(%) = ''%''::text) OR (% IS NULL))'
                AND typecheck.consrc ~ textcat(' = ''', type::text)

                AND NOT EXISTS (
                        SELECT oid FROM geometry_columns gc
                        WHERE c.relname::varchar = gc.f_table_name
                        AND n.nspname::varchar = gc.f_table_schema
                        AND a.attname::varchar = gc.f_geometry_column
                );

	GET DIAGNOSTICS foundschema = ROW_COUNT;

	-- no linkage to system table needed
	return 'fixed:'||foundschema::text;

	-- fix linking to system tables
	SELECT 0 INTO linked;
	FOR mislinked in
		SELECT gc.oid as gcrec,
			a.attrelid as attrelid, a.attnum as attnum
                FROM geometry_columns gc, pg_class c,
		pg_namespace n, pg_attribute a
                WHERE ( gc.attrelid IS NULL OR gc.attrelid != a.attrelid 
			OR gc.varattnum IS NULL OR gc.varattnum != a.attnum)
                AND n.nspname = gc.f_table_schema::name
                AND c.relnamespace = n.oid
                AND c.relname = gc.f_table_name::name
                AND a.attname = f_geometry_column::name
                AND a.attrelid = c.oid
	LOOP
		UPDATE geometry_columns SET
			attrelid = mislinked.attrelid,
			varattnum = mislinked.attnum,
			stats = NULL
			WHERE geometry_columns.oid = mislinked.gcrec;
		SELECT linked+1 INTO linked;
	END LOOP; 

	-- remove stale records
	DELETE FROM geometry_columns WHERE attrelid IS NULL;

	GET DIAGNOSTICS deleted = ROW_COUNT;

	result = 
		'fixed:' || foundschema::text ||
		' linked:' || linked::text || 
		' deleted:' || deleted::text;

	return result;

END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.fix_geometry_columns() OWNER TO postgres;

--
-- Name: force_2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_2d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_2d(geometry) OWNER TO postgres;

--
-- Name: force_3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_3d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dz'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_3d(geometry) OWNER TO postgres;

--
-- Name: force_3dm(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_3dm(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dm'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_3dm(geometry) OWNER TO postgres;

--
-- Name: force_3dz(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_3dz(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dz'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_3dz(geometry) OWNER TO postgres;

--
-- Name: force_4d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_4d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_4d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_4d(geometry) OWNER TO postgres;

--
-- Name: force_collection(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION force_collection(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.force_collection(geometry) OWNER TO postgres;

--
-- Name: forcerhr(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION forcerhr(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_forceRHR_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.forcerhr(geometry) OWNER TO postgres;

--
-- Name: geom_accum(geometry[], geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geom_accum(geometry[], geometry) RETURNS geometry[]
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_accum'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.geom_accum(geometry[], geometry) OWNER TO postgres;

--
-- Name: geomcollfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomcollfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomcollfromtext(text, integer) OWNER TO postgres;

--
-- Name: geomcollfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomcollfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomcollfromtext(text) OWNER TO postgres;

--
-- Name: geomcollfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomcollfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromWKB($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomcollfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: geomcollfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomcollfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromWKB($1)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomcollfromwkb(bytea) OWNER TO postgres;

--
-- Name: geometry(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(box2d) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry(box2d) OWNER TO postgres;

--
-- Name: geometry(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(box3d) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry(box3d) OWNER TO postgres;

--
-- Name: geometry(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'parse_WKT_lwgeom'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry(text) OWNER TO postgres;

--
-- Name: geometry(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(chip) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry(chip) OWNER TO postgres;

--
-- Name: geometry(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_bytea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry(bytea) OWNER TO postgres;

--
-- Name: geometry_above(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_above(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_above'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_above(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_analyze(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_analyze(internal) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_analyze'
    LANGUAGE c STRICT;


ALTER FUNCTION public.geometry_analyze(internal) OWNER TO postgres;

--
-- Name: geometry_below(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_below(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_below'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_below(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_cmp(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_cmp(geometry, geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_cmp'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_cmp(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_contain(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_contain(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_contain'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_contain(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_contained(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_contained(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_contained'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_contained(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_eq(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_eq(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_eq'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_eq(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_ge(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_ge(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_ge'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_ge(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_gt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_gt(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_gt'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_gt(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_in(cstring) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_in(cstring) OWNER TO postgres;

--
-- Name: geometry_le(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_le(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_le'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_le(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_left(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_left(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_left'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_left(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_lt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_lt(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_lt'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_lt(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_out(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_out(geometry) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_out(geometry) OWNER TO postgres;

--
-- Name: geometry_overabove(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overabove(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overabove'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_overabove(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_overbelow(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overbelow(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overbelow'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_overbelow(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_overlap(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overlap(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overlap'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_overlap(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_overleft(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overleft(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overleft'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_overleft(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_overright(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_overright(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overright'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_overright(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_recv(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_recv(internal) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_recv'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_recv(internal) OWNER TO postgres;

--
-- Name: geometry_right(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_right(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_right'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_right(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_same(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_same(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_same'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_same(geometry, geometry) OWNER TO postgres;

--
-- Name: geometry_send(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometry_send(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_send'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometry_send(geometry) OWNER TO postgres;

--
-- Name: geometryfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometryfromtext(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometryfromtext(text) OWNER TO postgres;

--
-- Name: geometryfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometryfromtext(text, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometryfromtext(text, integer) OWNER TO postgres;

--
-- Name: geometryn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geometryn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_geometryn_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geometryn(geometry, integer) OWNER TO postgres;

--
-- Name: geomfromewkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromewkb(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOMFromWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromewkb(bytea) OWNER TO postgres;

--
-- Name: geomfromewkt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromewkt(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'parse_WKT_lwgeom'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromewkt(text) OWNER TO postgres;

--
-- Name: geomfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromtext(text) RETURNS geometry
    AS $_$SELECT geometryfromtext($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromtext(text) OWNER TO postgres;

--
-- Name: geomfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromtext(text, integer) RETURNS geometry
    AS $_$SELECT geometryfromtext($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromtext(text, integer) OWNER TO postgres;

--
-- Name: geomfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromwkb(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_WKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromwkb(bytea) OWNER TO postgres;

--
-- Name: geomfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomfromwkb(bytea, integer) RETURNS geometry
    AS $_$SELECT setSRID(GeomFromWKB($1), $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.geomfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: geomunion(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geomunion(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'geomunion'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.geomunion(geometry, geometry) OWNER TO postgres;

--
-- Name: geosnoop(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION geosnoop(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'GEOSnoop'
    LANGUAGE c STRICT;


ALTER FUNCTION public.geosnoop(geometry) OWNER TO postgres;

--
-- Name: get_proj4_from_srid(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_proj4_from_srid(integer) RETURNS text
    AS $_$
BEGIN
	RETURN proj4text::text FROM spatial_ref_sys WHERE srid= $1;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.get_proj4_from_srid(integer) OWNER TO postgres;

--
-- Name: getbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getbbox(geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX2DFLOAT4'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.getbbox(geometry) OWNER TO postgres;

--
-- Name: getsrid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getsrid(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_getSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.getsrid(geometry) OWNER TO postgres;

--
-- Name: gettransactionid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gettransactionid() RETURNS xid
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'getTransactionID'
    LANGUAGE c;


ALTER FUNCTION public.gettransactionid() OWNER TO postgres;

--
-- Name: hasbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hasbbox(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_hasBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.hasbbox(geometry) OWNER TO postgres;

--
-- Name: height(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION height(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getHeight'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.height(chip) OWNER TO postgres;

--
-- Name: histogram2d_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION histogram2d_in(cstring) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwhistogram2d_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.histogram2d_in(cstring) OWNER TO postgres;

--
-- Name: histogram2d_out(histogram2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION histogram2d_out(histogram2d) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwhistogram2d_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.histogram2d_out(histogram2d) OWNER TO postgres;

--
-- Name: interiorringn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION interiorringn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_interiorringn_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.interiorringn(geometry, integer) OWNER TO postgres;

--
-- Name: intersection(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION intersection(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'intersection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.intersection(geometry, geometry) OWNER TO postgres;

--
-- Name: intersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION intersects(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'intersects'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.intersects(geometry, geometry) OWNER TO postgres;

--
-- Name: isclosed(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isclosed(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_isclosed_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.isclosed(geometry) OWNER TO postgres;

--
-- Name: isempty(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isempty(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_isempty'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.isempty(geometry) OWNER TO postgres;

--
-- Name: isring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isring(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'isring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.isring(geometry) OWNER TO postgres;

--
-- Name: issimple(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION issimple(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'issimple'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.issimple(geometry) OWNER TO postgres;

--
-- Name: isvalid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION isvalid(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'isvalid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.isvalid(geometry) OWNER TO postgres;

--
-- Name: jtsnoop(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION jtsnoop(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'JTSnoop'
    LANGUAGE c STRICT;


ALTER FUNCTION public.jtsnoop(geometry) OWNER TO postgres;

--
-- Name: length(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length(geometry) OWNER TO postgres;

--
-- Name: length2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length2d_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length2d(geometry) OWNER TO postgres;

--
-- Name: length2d_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length2d_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length2d_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length2d_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: length3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length3d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length3d(geometry) OWNER TO postgres;

--
-- Name: length3d_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length3d_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length3d_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: length_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION length_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.length_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: line_interpolate_point(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION line_interpolate_point(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_interpolate_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.line_interpolate_point(geometry, double precision) OWNER TO postgres;

--
-- Name: line_locate_point(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION line_locate_point(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_locate_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.line_locate_point(geometry, geometry) OWNER TO postgres;

--
-- Name: line_substring(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION line_substring(geometry, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_substring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.line_substring(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: linefrommultipoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linefrommultipoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_from_mpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.linefrommultipoint(geometry) OWNER TO postgres;

--
-- Name: linefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linefromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'LINESTRING'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linefromtext(text) OWNER TO postgres;

--
-- Name: linefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linefromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'LINESTRING'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linefromtext(text, integer) OWNER TO postgres;

--
-- Name: linefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linefromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: linefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'LINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linefromwkb(bytea) OWNER TO postgres;

--
-- Name: linemerge(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linemerge(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'linemerge'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.linemerge(geometry) OWNER TO postgres;

--
-- Name: linestringfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linestringfromtext(text) RETURNS geometry
    AS $_$SELECT LineFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linestringfromtext(text) OWNER TO postgres;

--
-- Name: linestringfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linestringfromtext(text, integer) RETURNS geometry
    AS $_$SELECT LineFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linestringfromtext(text, integer) OWNER TO postgres;

--
-- Name: linestringfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linestringfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linestringfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: linestringfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION linestringfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'LINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.linestringfromwkb(bytea) OWNER TO postgres;

--
-- Name: locate_along_measure(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION locate_along_measure(geometry, double precision) RETURNS geometry
    AS $_$SELECT locate_between_measures($1, $2, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.locate_along_measure(geometry, double precision) OWNER TO postgres;

--
-- Name: locate_between_measures(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION locate_between_measures(geometry, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_locate_between_m'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.locate_between_measures(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: lockrow(text, text, text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, text, timestamp without time zone) RETURNS integer
    AS $_$
DECLARE
	myschema alias for $1;
	mytable alias for $2;
	myrid   alias for $3;
	authid alias for $4;
	expires alias for $5;
	ret int;
	mytoid oid;
	myrec RECORD;
	
BEGIN

	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	EXECUTE 'DELETE FROM authorization_table WHERE expires < now()'; 

	SELECT c.oid INTO mytoid FROM pg_class c, pg_namespace n
		WHERE c.relname = mytable
		AND c.relnamespace = n.oid
		AND n.nspname = myschema;

	-- RAISE NOTICE 'toid: %', mytoid;

	FOR myrec IN SELECT * FROM authorization_table WHERE 
		toid = mytoid AND rid = myrid
	LOOP
		IF myrec.authid != authid THEN
			RETURN 0;
		ELSE
			RETURN 1;
		END IF;
	END LOOP;

	EXECUTE 'INSERT INTO authorization_table VALUES ('||
		quote_literal(mytoid::text)||','||quote_literal(myrid)||
		','||quote_literal(expires::text)||
		','||quote_literal(authid) ||')';

	GET DIAGNOSTICS ret = ROW_COUNT;

	RETURN ret;
END;$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) OWNER TO postgres;

--
-- Name: lockrow(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, text) RETURNS integer
    AS $_$SELECT LockRow($1, $2, $3, $4, now()::timestamp+'1:00');$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.lockrow(text, text, text, text) OWNER TO postgres;

--
-- Name: lockrow(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text) RETURNS integer
    AS $_$SELECT LockRow(current_schema(), $1, $2, $3, now()::timestamp+'1:00');$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.lockrow(text, text, text) OWNER TO postgres;

--
-- Name: lockrow(text, text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lockrow(text, text, text, timestamp without time zone) RETURNS integer
    AS $_$SELECT LockRow(current_schema(), $1, $2, $3, $4);$_$
    LANGUAGE sql STRICT;


ALTER FUNCTION public.lockrow(text, text, text, timestamp without time zone) OWNER TO postgres;

--
-- Name: longtransactionsenabled(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION longtransactionsenabled() RETURNS boolean
    AS $$
DECLARE
	rec RECORD;
BEGIN
	FOR rec IN SELECT oid FROM pg_class WHERE relname = 'authorized_tables'
	LOOP
		return 't';
	END LOOP;
	return 'f';
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.longtransactionsenabled() OWNER TO postgres;

--
-- Name: lwgeom_gist_compress(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_compress(internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_compress'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_compress(internal) OWNER TO postgres;

--
-- Name: lwgeom_gist_consistent(internal, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_consistent(internal, geometry, integer) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_consistent'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_consistent(internal, geometry, integer) OWNER TO postgres;

--
-- Name: lwgeom_gist_decompress(internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_decompress(internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_decompress'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_decompress(internal) OWNER TO postgres;

--
-- Name: lwgeom_gist_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_penalty(internal, internal, internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_penalty'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_penalty(internal, internal, internal) OWNER TO postgres;

--
-- Name: lwgeom_gist_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_picksplit(internal, internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_picksplit'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_picksplit(internal, internal) OWNER TO postgres;

--
-- Name: lwgeom_gist_same(box2d, box2d, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_same(box2d, box2d, internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_same'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_same(box2d, box2d, internal) OWNER TO postgres;

--
-- Name: lwgeom_gist_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION lwgeom_gist_union(bytea, internal) RETURNS internal
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_union'
    LANGUAGE c;


ALTER FUNCTION public.lwgeom_gist_union(bytea, internal) OWNER TO postgres;

--
-- Name: m(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION m(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_m_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.m(geometry) OWNER TO postgres;

--
-- Name: makebox2d(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makebox2d(geometry, geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_construct'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makebox2d(geometry, geometry) OWNER TO postgres;

--
-- Name: makebox3d(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makebox3d(geometry, geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_construct'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makebox3d(geometry, geometry) OWNER TO postgres;

--
-- Name: makeline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makeline(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makeline'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makeline(geometry, geometry) OWNER TO postgres;

--
-- Name: makeline_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makeline_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makeline_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makeline_garray(geometry[]) OWNER TO postgres;

--
-- Name: makepoint(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepoint(double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepoint(double precision, double precision) OWNER TO postgres;

--
-- Name: makepoint(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepoint(double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepoint(double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: makepoint(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepoint(double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepoint(double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: makepointm(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepointm(double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint3dm'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepointm(double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: makepolygon(geometry, geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepolygon(geometry, geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepolygon(geometry, geometry[]) OWNER TO postgres;

--
-- Name: makepolygon(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION makepolygon(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.makepolygon(geometry) OWNER TO postgres;

--
-- Name: max_distance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION max_distance(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_maxdistance2d_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.max_distance(geometry, geometry) OWNER TO postgres;

--
-- Name: mem_size(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mem_size(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_mem_size'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.mem_size(geometry) OWNER TO postgres;

--
-- Name: mk_platform_geom(); Type: FUNCTION; Schema: public; Owner: xeniaprod
--

CREATE FUNCTION mk_platform_geom() RETURNS trigger
    AS $$
begin
  if (new.the_geom is null) then
    new.the_geom = geomfromtext('POINT(' || new.fixed_longitude || ' ' || new.fixed_latitude || ')',-1);
  end if;
  return new;
end;$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.mk_platform_geom() OWNER TO xeniaprod;

--
-- Name: mk_the_geom(); Type: FUNCTION; Schema: public; Owner: xeniaprod
--

CREATE FUNCTION mk_the_geom() RETURNS trigger
    AS $$
begin
if (new.the_geom is null) then
  new.the_geom = geomfromtext('POINT(' || new.m_lon || ' ' || new.m_lat || ')',-1);
end if;
return new;
end;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.mk_the_geom() OWNER TO xeniaprod;

--
-- Name: mlinefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mlinefromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1, $2)) = 'MULTILINESTRING'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mlinefromtext(text, integer) OWNER TO postgres;

--
-- Name: mlinefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mlinefromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTILINESTRING'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mlinefromtext(text) OWNER TO postgres;

--
-- Name: mlinefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mlinefromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mlinefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: mlinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mlinefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mlinefromwkb(bytea) OWNER TO postgres;

--
-- Name: mpointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpointfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1,$2)) = 'MULTIPOINT'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpointfromtext(text, integer) OWNER TO postgres;

--
-- Name: mpointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpointfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTIPOINT'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpointfromtext(text) OWNER TO postgres;

--
-- Name: mpointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1,$2)) = 'MULTIPOINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: mpointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpointfromwkb(bytea) OWNER TO postgres;

--
-- Name: mpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpolyfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: mpolyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpolyfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTIPOLYGON'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpolyfromtext(text) OWNER TO postgres;

--
-- Name: mpolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpolyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: mpolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION mpolyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.mpolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: multi(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multi(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_multi'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.multi(geometry) OWNER TO postgres;

--
-- Name: multilinefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multilinefromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multilinefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: multilinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multilinefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multilinefromwkb(bytea) OWNER TO postgres;

--
-- Name: multilinestringfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multilinestringfromtext(text) RETURNS geometry
    AS $_$SELECT MLineFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multilinestringfromtext(text) OWNER TO postgres;

--
-- Name: multilinestringfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multilinestringfromtext(text, integer) RETURNS geometry
    AS $_$SELECT MLineFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multilinestringfromtext(text, integer) OWNER TO postgres;

--
-- Name: multipointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipointfromtext(text, integer) RETURNS geometry
    AS $_$SELECT MPointFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipointfromtext(text, integer) OWNER TO postgres;

--
-- Name: multipointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipointfromtext(text) RETURNS geometry
    AS $_$SELECT MPointFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipointfromtext(text) OWNER TO postgres;

--
-- Name: multipointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1,$2)) = 'MULTIPOINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: multipointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipointfromwkb(bytea) OWNER TO postgres;

--
-- Name: multipolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipolyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: multipolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipolyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: multipolygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipolygonfromtext(text, integer) RETURNS geometry
    AS $_$SELECT MPolyFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipolygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: multipolygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION multipolygonfromtext(text) RETURNS geometry
    AS $_$SELECT MPolyFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.multipolygonfromtext(text) OWNER TO postgres;

--
-- Name: noop(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION noop(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_noop'
    LANGUAGE c STRICT;


ALTER FUNCTION public.noop(geometry) OWNER TO postgres;

--
-- Name: normal_rand(integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION normal_rand(integer, double precision, double precision) RETURNS SETOF double precision
    AS '$libdir/tablefunc', 'normal_rand'
    LANGUAGE c STRICT;


ALTER FUNCTION public.normal_rand(integer, double precision, double precision) OWNER TO postgres;

--
-- Name: npoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION npoints(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_npoints'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.npoints(geometry) OWNER TO postgres;

--
-- Name: nrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION nrings(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_nrings'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.nrings(geometry) OWNER TO postgres;

--
-- Name: numgeometries(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION numgeometries(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numgeometries_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.numgeometries(geometry) OWNER TO postgres;

--
-- Name: numinteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION numinteriorring(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numinteriorrings_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.numinteriorring(geometry) OWNER TO postgres;

--
-- Name: numinteriorrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION numinteriorrings(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numinteriorrings_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.numinteriorrings(geometry) OWNER TO postgres;

--
-- Name: numpoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION numpoints(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numpoints_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.numpoints(geometry) OWNER TO postgres;

--
-- Name: overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "overlaps"(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'overlaps'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public."overlaps"(geometry, geometry) OWNER TO postgres;

--
-- Name: perimeter(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION perimeter(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.perimeter(geometry) OWNER TO postgres;

--
-- Name: perimeter2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION perimeter2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter2d_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.perimeter2d(geometry) OWNER TO postgres;

--
-- Name: perimeter3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION perimeter3d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.perimeter3d(geometry) OWNER TO postgres;

--
-- Name: point_inside_circle(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION point_inside_circle(geometry, double precision, double precision, double precision) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_inside_circle_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.point_inside_circle(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: pointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'POINT'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.pointfromtext(text) OWNER TO postgres;

--
-- Name: pointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'POINT'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.pointfromtext(text, integer) OWNER TO postgres;

--
-- Name: pointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'POINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.pointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: pointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.pointfromwkb(bytea) OWNER TO postgres;

--
-- Name: pointn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_pointn_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.pointn(geometry, integer) OWNER TO postgres;

--
-- Name: pointonsurface(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointonsurface(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'pointonsurface'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.pointonsurface(geometry) OWNER TO postgres;

--
-- Name: polyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polyfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'POLYGON'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polyfromtext(text) OWNER TO postgres;

--
-- Name: polyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polyfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'POLYGON'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polyfromtext(text, integer) OWNER TO postgres;

--
-- Name: polyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'POLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: polyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polyfromwkb(bytea) OWNER TO postgres;

--
-- Name: polygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polygonfromtext(text, integer) RETURNS geometry
    AS $_$SELECT PolyFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: polygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polygonfromtext(text) RETURNS geometry
    AS $_$SELECT PolyFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polygonfromtext(text) OWNER TO postgres;

--
-- Name: polygonfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polygonfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1,$2)) = 'POLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polygonfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: polygonfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polygonfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.polygonfromwkb(bytea) OWNER TO postgres;

--
-- Name: polygonize_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION polygonize_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'polygonize_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.polygonize_garray(geometry[]) OWNER TO postgres;

--
-- Name: postgis_full_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_full_version() RETURNS text
    AS $$
DECLARE
	libver text;
	projver text;
	geosver text;
	jtsver text;
	usestats bool;
	dbproc text;
	relproc text;
	fullver text;
BEGIN
	SELECT postgis_lib_version() INTO libver;
	SELECT postgis_proj_version() INTO projver;
	SELECT postgis_geos_version() INTO geosver;
	SELECT postgis_jts_version() INTO jtsver;
	SELECT postgis_uses_stats() INTO usestats;
	SELECT postgis_scripts_installed() INTO dbproc;
	SELECT postgis_scripts_released() INTO relproc;

	fullver = 'POSTGIS="' || libver || '"';

	IF  geosver IS NOT NULL THEN
		fullver = fullver || ' GEOS="' || geosver || '"';
	END IF;

	IF  jtsver IS NOT NULL THEN
		fullver = fullver || ' JTS="' || jtsver || '"';
	END IF;

	IF  projver IS NOT NULL THEN
		fullver = fullver || ' PROJ="' || projver || '"';
	END IF;

	IF usestats THEN
		fullver = fullver || ' USE_STATS';
	END IF;

	-- fullver = fullver || ' DBPROC="' || dbproc || '"';
	-- fullver = fullver || ' RELPROC="' || relproc || '"';

	IF dbproc != relproc THEN
		fullver = fullver || ' (procs from ' || dbproc || ' need upgrade)';
	END IF;

	RETURN fullver;
END
$$
    LANGUAGE plpgsql IMMUTABLE;


ALTER FUNCTION public.postgis_full_version() OWNER TO postgres;

--
-- Name: postgis_geos_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_geos_version() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_geos_version'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_geos_version() OWNER TO postgres;

--
-- Name: postgis_gist_joinsel(internal, oid, internal, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_gist_joinsel(internal, oid, internal, smallint) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_joinsel'
    LANGUAGE c;


ALTER FUNCTION public.postgis_gist_joinsel(internal, oid, internal, smallint) OWNER TO postgres;

--
-- Name: postgis_gist_sel(internal, oid, internal, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_gist_sel(internal, oid, internal, integer) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_sel'
    LANGUAGE c;


ALTER FUNCTION public.postgis_gist_sel(internal, oid, internal, integer) OWNER TO postgres;

--
-- Name: postgis_jts_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_jts_version() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_jts_version'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_jts_version() OWNER TO postgres;

--
-- Name: postgis_lib_build_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_lib_build_date() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_lib_build_date'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_lib_build_date() OWNER TO postgres;

--
-- Name: postgis_lib_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_lib_version() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_lib_version'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_lib_version() OWNER TO postgres;

--
-- Name: postgis_proj_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_proj_version() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_proj_version'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_proj_version() OWNER TO postgres;

--
-- Name: postgis_scripts_build_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_build_date() RETURNS text
    AS $$SELECT '2008-04-22 14:59:00'::text AS version$$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.postgis_scripts_build_date() OWNER TO postgres;

--
-- Name: postgis_scripts_installed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_installed() RETURNS text
    AS $$SELECT '1.3.3'::text AS version$$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.postgis_scripts_installed() OWNER TO postgres;

--
-- Name: postgis_scripts_released(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_scripts_released() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_scripts_released'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_scripts_released() OWNER TO postgres;

--
-- Name: postgis_uses_stats(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_uses_stats() RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_uses_stats'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_uses_stats() OWNER TO postgres;

--
-- Name: postgis_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION postgis_version() RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'postgis_version'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.postgis_version() OWNER TO postgres;

--
-- Name: probe_geometry_columns(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION probe_geometry_columns() RETURNS text
    AS $$
DECLARE
	inserted integer;
	oldcount integer;
	probed integer;
	stale integer;
BEGIN

	SELECT count(*) INTO oldcount FROM geometry_columns;

	SELECT count(*) INTO probed
		FROM pg_class c, pg_attribute a, pg_type t, 
			pg_namespace n,
			pg_constraint sridcheck, pg_constraint typecheck

		WHERE t.typname = 'geometry'
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND sridcheck.connamespace = n.oid
		AND typecheck.connamespace = n.oid

		AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(srid('||a.attname||') = %)'
		AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
	'((geometrytype('||a.attname||') = ''%''::text) OR (% IS NULL))'
		;

	INSERT INTO geometry_columns SELECT
		''::varchar as f_table_catalogue,
		n.nspname::varchar as f_table_schema,
		c.relname::varchar as f_table_name,
		a.attname::varchar as f_geometry_column,
		2 as coord_dimension,
		trim(both  ' =)' from substr(sridcheck.consrc,
			strpos(sridcheck.consrc, '=')))::integer as srid,
		trim(both ' =)''' from substr(typecheck.consrc, 
			strpos(typecheck.consrc, '='),
			strpos(typecheck.consrc, '::')-
			strpos(typecheck.consrc, '=')
			))::varchar as type

		FROM pg_class c, pg_attribute a, pg_type t, 
			pg_namespace n,
			pg_constraint sridcheck, pg_constraint typecheck
		WHERE t.typname = 'geometry'
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND sridcheck.connamespace = n.oid
		AND typecheck.connamespace = n.oid
		AND sridcheck.conrelid = c.oid
		AND sridcheck.consrc LIKE '(srid('||a.attname||') = %)'
		AND typecheck.conrelid = c.oid
		AND typecheck.consrc LIKE
	'((geometrytype('||a.attname||') = ''%''::text) OR (% IS NULL))'

                AND NOT EXISTS (
                        SELECT oid FROM geometry_columns gc
                        WHERE c.relname::varchar = gc.f_table_name
                        AND n.nspname::varchar = gc.f_table_schema
                        AND a.attname::varchar = gc.f_geometry_column
                );

	GET DIAGNOSTICS inserted = ROW_COUNT;

	IF oldcount > probed THEN
		stale = oldcount-probed;
	ELSE
		stale = 0;
	END IF;

        RETURN 'probed:'||probed::text||
		' inserted:'||inserted::text||
		' conflicts:'||(probed-inserted)::text||
		' stale:'||stale::text;
END

$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.probe_geometry_columns() OWNER TO postgres;

--
-- Name: relate(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION relate(geometry, geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'relate_full'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.relate(geometry, geometry) OWNER TO postgres;

--
-- Name: relate(geometry, geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION relate(geometry, geometry, text) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'relate_pattern'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.relate(geometry, geometry, text) OWNER TO postgres;

--
-- Name: removepoint(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION removepoint(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_removepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.removepoint(geometry, integer) OWNER TO postgres;

--
-- Name: rename_geometry_table_constraints(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rename_geometry_table_constraints() RETURNS text
    AS $$
SELECT 'rename_geometry_table_constraint() is obsoleted'::text
$$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.rename_geometry_table_constraints() OWNER TO postgres;

--
-- Name: reverse(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION reverse(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_reverse'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.reverse(geometry) OWNER TO postgres;

--
-- Name: rotate(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rotate(geometry, double precision) RETURNS geometry
    AS $_$SELECT rotateZ($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.rotate(geometry, double precision) OWNER TO postgres;

--
-- Name: rotatex(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rotatex(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1, 1, 0, 0, 0, cos($2), -sin($2), 0, sin($2), cos($2), 0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.rotatex(geometry, double precision) OWNER TO postgres;

--
-- Name: rotatey(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rotatey(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  cos($2), 0, sin($2),  0, 1, 0,  -sin($2), 0, cos($2), 0,  0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.rotatey(geometry, double precision) OWNER TO postgres;

--
-- Name: rotatez(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rotatez(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  cos($2), -sin($2), 0,  sin($2), cos($2), 0,  0, 0, 1,  0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.rotatez(geometry, double precision) OWNER TO postgres;

--
-- Name: scale(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION scale(geometry, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $2, 0, 0,  0, $3, 0,  0, 0, $4,  0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.scale(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: scale(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION scale(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT scale($1, $2, $3, 1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.scale(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: se_envelopesintersect(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_envelopesintersect(geometry, geometry) RETURNS boolean
    AS $_$
	SELECT $1 && $2
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.se_envelopesintersect(geometry, geometry) OWNER TO postgres;

--
-- Name: se_is3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_is3d(geometry) RETURNS boolean
    AS $_$
    SELECT CASE ST_zmflag($1)
               WHEN 0 THEN false
               WHEN 1 THEN false
               WHEN 2 THEN true
               WHEN 3 THEN true
               ELSE false
           END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.se_is3d(geometry) OWNER TO postgres;

--
-- Name: se_ismeasured(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_ismeasured(geometry) RETURNS boolean
    AS $_$
    SELECT CASE ST_zmflag($1)
               WHEN 0 THEN false
               WHEN 1 THEN true
               WHEN 2 THEN false
               WHEN 3 THEN true
               ELSE false
           END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.se_ismeasured(geometry) OWNER TO postgres;

--
-- Name: se_locatealong(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_locatealong(geometry, double precision) RETURNS geometry
    AS $_$SELECT locate_between_measures($1, $2, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.se_locatealong(geometry, double precision) OWNER TO postgres;

--
-- Name: se_locatebetween(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_locatebetween(geometry, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_locate_between_m'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.se_locatebetween(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: se_m(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_m(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_m_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.se_m(geometry) OWNER TO postgres;

--
-- Name: se_z(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION se_z(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_z_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.se_z(geometry) OWNER TO postgres;

--
-- Name: segmentize(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION segmentize(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_segmentize2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.segmentize(geometry, double precision) OWNER TO postgres;

--
-- Name: set_top_of_hour(); Type: FUNCTION; Schema: public; Owner: xeniaprod
--

CREATE FUNCTION set_top_of_hour() RETURNS trigger
    AS $$
       
       declare
       old_row_id int;
       old_date_minute int;
       new_date text;
       comp_date_hour int;
       new_date_minute int;
       new_comp_date timestamp;
       new_comp_date_min timestamp;
       new_comp_date_max timestamp;
       
       begin
         
         --see whether to set comparison hour to this hour or next
         select to_char(new.m_date,'YYYY-MM-DD') into new_date;
         select to_char(new.m_date,'HH24') into comp_date_hour;  
         select to_char(new.m_date,'MI') into new_date_minute;
   
         if (new_date_minute > 30) then
             --go to the next hour unless close to midnight, then go to next day, 0 hour
             if (comp_date_hour <> 23) then 
                 comp_date_hour = comp_date_hour + 1;
             else
                 comp_date_hour = 0;
                 select to_char((new.m_date + interval '1 day'),'YYYY-MM-DD') into new_date;
             end if;
         end if;
       
         new_comp_date = new_date || ' ' || comp_date_hour || ':00:00';
         
         select to_char((new_comp_date - interval '30 minutes'),'YYYY-MM-DD HH24:MI:SS') into new_comp_date_min;
         select to_char((new_comp_date + interval '30 minutes'),'YYYY-MM-DD HH24:MI:SS') into new_comp_date_max;
        
         --new_comp_date_min = new_date || ' ' || comp_date_hour-1 || ':30';
         --new_comp_date_max = new_date || ' ' || comp_date_hour || ':30';
       
   
         --RAISE NOTICE "new_comp_date = %", new_comp_date;
         --RAISE NOTICE "new_comp_date_min = %", new_comp_date_min;
         --RAISE NOTICE "new_comp_date_max = %", new_comp_date_max;
       
         --assign d_report_hour, each hour is associated with the half hour before and after the top of that hour
         update multi_obs set d_report_hour = new_comp_date where row_id = new.row_id;
       
         --select existing top_of_hour row(if exists) within hour comparison
         select into old_row_id,old_date_minute row_id,to_char(m_date,'MI')  
           from multi_obs
           where m_type_id = new.m_type_id and sensor_id = new.sensor_id and d_top_of_hour = 1
           and m_date > new_comp_date_min and m_date <= new_comp_date_max;
       
         --if not found then
         --	raise notice "select not found";
         --end if;
         
         --decide whether new row is closer to top_of_hour or not
         if (old_row_id is null) then
           update multi_obs set d_top_of_hour = 1 , d_report_hour = new_comp_date where row_id = new.row_id;
         elsif (new_date_minute <= 30) then
           if (old_date_minute > new_date_minute) then
             update multi_obs set d_top_of_hour = 1 where row_id = new.row_id;
             update multi_obs set d_top_of_hour = null where row_id = old_row_id;
           end if;
         elsif (new_date_minute > 30) and (old_date_minute <> 0) then
           if (old_date_minute < new_date_minute) then
             update multi_obs set d_top_of_hour = 1 where row_id = new.row_id;
             update multi_obs set d_top_of_hour = null where row_id = old_row_id;
           end if;    
         end if;
       
         return new;
       end;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.set_top_of_hour() OWNER TO xeniaprod;

--
-- Name: setfactor(chip, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION setfactor(chip, real) RETURNS chip
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_setFactor'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.setfactor(chip, real) OWNER TO postgres;

--
-- Name: setpoint(geometry, integer, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION setpoint(geometry, integer, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_setpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.setpoint(geometry, integer, geometry) OWNER TO postgres;

--
-- Name: setsrid(chip, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION setsrid(chip, integer) RETURNS chip
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_setSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.setsrid(chip, integer) OWNER TO postgres;

--
-- Name: setsrid(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION setsrid(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_setSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.setsrid(geometry, integer) OWNER TO postgres;

--
-- Name: shift_longitude(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION shift_longitude(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_longitude_shift'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.shift_longitude(geometry) OWNER TO postgres;

--
-- Name: simplify(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION simplify(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_simplify2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.simplify(geometry, double precision) OWNER TO postgres;

--
-- Name: snaptogrid(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION snaptogrid(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_snaptogrid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.snaptogrid(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: snaptogrid(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION snaptogrid(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT SnapToGrid($1, 0, 0, $2, $3)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.snaptogrid(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: snaptogrid(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION snaptogrid(geometry, double precision) RETURNS geometry
    AS $_$SELECT SnapToGrid($1, 0, 0, $2, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.snaptogrid(geometry, double precision) OWNER TO postgres;

--
-- Name: snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_snaptogrid_pointoff'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: spheroid_in(cstring); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION spheroid_in(cstring) RETURNS spheroid
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'ellipsoid_in'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.spheroid_in(cstring) OWNER TO postgres;

--
-- Name: spheroid_out(spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION spheroid_out(spheroid) RETURNS cstring
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'ellipsoid_out'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.spheroid_out(spheroid) OWNER TO postgres;

--
-- Name: srid(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION srid(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.srid(chip) OWNER TO postgres;

--
-- Name: st_addbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addbbox(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_addbbox(geometry) OWNER TO postgres;

--
-- Name: st_addpoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addpoint(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_addpoint(geometry, geometry) OWNER TO postgres;

--
-- Name: st_addpoint(geometry, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_addpoint(geometry, geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_addpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_addpoint(geometry, geometry, integer) OWNER TO postgres;

--
-- Name: st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_affine'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $2, $3, 0,  $4, $5, 0,  0, 0, 1,  $6, $7, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_area(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_area_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_area(geometry) OWNER TO postgres;

--
-- Name: st_area2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_area2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_area_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_area2d(geometry) OWNER TO postgres;

--
-- Name: st_asbinary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asBinary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_asbinary(geometry) OWNER TO postgres;

--
-- Name: st_asbinary(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asbinary(geometry, text) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asBinary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_asbinary(geometry, text) OWNER TO postgres;

--
-- Name: st_asewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkb(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'WKBFromLWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_asewkb(geometry) OWNER TO postgres;

--
-- Name: st_asewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkb(geometry, text) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'WKBFromLWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_asewkb(geometry, text) OWNER TO postgres;

--
-- Name: st_asewkt(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asewkt(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asEWKT'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_asewkt(geometry) OWNER TO postgres;

--
-- Name: st_asgml(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsGML(2, $1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_asgml(geometry, integer) OWNER TO postgres;

--
-- Name: st_asgml(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(geometry) RETURNS text
    AS $_$SELECT _ST_AsGML(2, $1, 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_asgml(geometry) OWNER TO postgres;

--
-- Name: st_asgml(integer, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(integer, geometry) RETURNS text
    AS $_$SELECT _ST_AsGML($1, $2, 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_asgml(integer, geometry) OWNER TO postgres;

--
-- Name: st_asgml(integer, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_asgml(integer, geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsGML($1, $2, $3)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_asgml(integer, geometry, integer) OWNER TO postgres;

--
-- Name: st_ashexewkb(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ashexewkb(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asHEXEWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_ashexewkb(geometry) OWNER TO postgres;

--
-- Name: st_ashexewkb(geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ashexewkb(geometry, text) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asHEXEWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_ashexewkb(geometry, text) OWNER TO postgres;

--
-- Name: st_askml(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsKML(2, transform($1,4326), $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_askml(geometry, integer) OWNER TO postgres;

--
-- Name: st_askml(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(geometry) RETURNS text
    AS $_$SELECT _ST_AsKML(2, transform($1,4326), 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_askml(geometry) OWNER TO postgres;

--
-- Name: st_askml(integer, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(integer, geometry) RETURNS text
    AS $_$SELECT _ST_AsKML($1, transform($2,4326), 15)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_askml(integer, geometry) OWNER TO postgres;

--
-- Name: st_askml(integer, geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_askml(integer, geometry, integer) RETURNS text
    AS $_$SELECT _ST_AsKML($1, transform($2,4326), $3)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_askml(integer, geometry, integer) OWNER TO postgres;

--
-- Name: st_assvg(geometry, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(geometry, integer, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_assvg(geometry, integer, integer) OWNER TO postgres;

--
-- Name: st_assvg(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(geometry, integer) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_assvg(geometry, integer) OWNER TO postgres;

--
-- Name: st_assvg(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_assvg(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'assvg_geometry'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_assvg(geometry) OWNER TO postgres;

--
-- Name: st_astext(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_astext(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_asText'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_astext(geometry) OWNER TO postgres;

--
-- Name: st_azimuth(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_azimuth(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_azimuth'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_azimuth(geometry, geometry) OWNER TO postgres;

--
-- Name: st_bdmpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_bdmpolyfromtext(text, integer) RETURNS geometry
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := multi(BuildArea(mline));

	RETURN geom;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.st_bdmpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_bdpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_bdpolyfromtext(text, integer) RETURNS geometry
    AS $_$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline geometry;
	geom geometry;
BEGIN
	mline := MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := BuildArea(mline);

	IF GeometryType(geom) != 'POLYGON'
	THEN
		RAISE EXCEPTION 'Input returns more then a single polygon, try using BdMPolyFromText instead';
	END IF;

	RETURN geom;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.st_bdpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_boundary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_boundary(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'boundary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_boundary(geometry) OWNER TO postgres;

--
-- Name: st_box(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box(geometry) RETURNS box
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box(geometry) OWNER TO postgres;

--
-- Name: st_box(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box(box3d) RETURNS box
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_BOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box(box3d) OWNER TO postgres;

--
-- Name: st_box2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d(geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX2DFLOAT4'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d(geometry) OWNER TO postgres;

--
-- Name: st_box2d(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d(box3d) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_BOX2DFLOAT4'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d(box3d) OWNER TO postgres;

--
-- Name: st_box2d_contain(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_contain(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_contain'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_contain(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_contained(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_contained(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_contained'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_contained(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_intersects(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_intersects(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_intersects'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_intersects(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_left(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_left(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_left'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_left(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_overlap(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_overlap(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overlap'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_overlap(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_overleft(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_overleft(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overleft'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_overleft(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_overright(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_overright(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_overright'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_overright(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_right(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_right(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_right'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_right(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box2d_same(box2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box2d_same(box2d, box2d) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2D_same'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box2d_same(box2d, box2d) OWNER TO postgres;

--
-- Name: st_box3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box3d(geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_BOX3D'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box3d(geometry) OWNER TO postgres;

--
-- Name: st_box3d(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_box3d(box2d) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_to_BOX3D'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_box3d(box2d) OWNER TO postgres;

--
-- Name: st_buffer(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'buffer'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_buffer(geometry, double precision) OWNER TO postgres;

--
-- Name: st_buffer(geometry, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buffer(geometry, double precision, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'buffer'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_buffer(geometry, double precision, integer) OWNER TO postgres;

--
-- Name: st_build_histogram2d(histogram2d, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_build_histogram2d(histogram2d, text, text) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'build_lwhistogram2d'
    LANGUAGE c STABLE STRICT;


ALTER FUNCTION public.st_build_histogram2d(histogram2d, text, text) OWNER TO postgres;

--
-- Name: st_build_histogram2d(histogram2d, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_build_histogram2d(histogram2d, text, text, text) RETURNS histogram2d
    AS $_$
BEGIN
	EXECUTE 'SET local search_path = '||$2||',public';
	RETURN public.build_histogram2d($1,$3,$4);
END
$_$
    LANGUAGE plpgsql STABLE STRICT;


ALTER FUNCTION public.st_build_histogram2d(histogram2d, text, text, text) OWNER TO postgres;

--
-- Name: st_buildarea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_buildarea(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_buildarea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_buildarea(geometry) OWNER TO postgres;

--
-- Name: st_bytea(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_bytea(geometry) RETURNS bytea
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_bytea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_bytea(geometry) OWNER TO postgres;

--
-- Name: st_cache_bbox(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_cache_bbox() RETURNS trigger
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'cache_bbox'
    LANGUAGE c;


ALTER FUNCTION public.st_cache_bbox() OWNER TO postgres;

--
-- Name: st_centroid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_centroid(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'centroid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_centroid(geometry) OWNER TO postgres;

--
-- Name: st_collect(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collect(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.st_collect(geometry, geometry) OWNER TO postgres;

--
-- Name: st_collect_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collect_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_collect_garray(geometry[]) OWNER TO postgres;

--
-- Name: st_collector(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_collector(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_collect'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.st_collector(geometry, geometry) OWNER TO postgres;

--
-- Name: st_combine_bbox(box2d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_combine_bbox(box2d, geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_combine'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.st_combine_bbox(box2d, geometry) OWNER TO postgres;

--
-- Name: st_combine_bbox(box3d, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_combine_bbox(box3d, geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_combine'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.st_combine_bbox(box3d, geometry) OWNER TO postgres;

--
-- Name: st_compression(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_compression(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getCompression'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_compression(chip) OWNER TO postgres;

--
-- Name: st_contains(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_contains(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Contains($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_contains(geometry, geometry) OWNER TO postgres;

--
-- Name: st_convexhull(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_convexhull(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'convexhull'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_convexhull(geometry) OWNER TO postgres;

--
-- Name: st_coorddim(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_coorddim(geometry) RETURNS smallint
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_ndims'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_coorddim(geometry) OWNER TO postgres;

--
-- Name: st_create_histogram2d(box2d, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_create_histogram2d(box2d, integer) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'create_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_create_histogram2d(box2d, integer) OWNER TO postgres;

--
-- Name: st_crosses(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_crosses(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Crosses($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_crosses(geometry, geometry) OWNER TO postgres;

--
-- Name: st_curvetoline(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_curvetoline(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_curve_segmentize'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_curvetoline(geometry, integer) OWNER TO postgres;

--
-- Name: st_curvetoline(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_curvetoline(geometry) RETURNS geometry
    AS $_$SELECT ST_CurveToLine($1, 32)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_curvetoline(geometry) OWNER TO postgres;

--
-- Name: st_datatype(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_datatype(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getDatatype'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_datatype(chip) OWNER TO postgres;

--
-- Name: st_difference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_difference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'difference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_difference(geometry, geometry) OWNER TO postgres;

--
-- Name: st_dimension(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dimension(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dimension'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_dimension(geometry) OWNER TO postgres;

--
-- Name: st_disjoint(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_disjoint(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'disjoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_disjoint(geometry, geometry) OWNER TO postgres;

--
-- Name: st_distance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_mindistance2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_distance(geometry, geometry) OWNER TO postgres;

--
-- Name: st_distance_sphere(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance_sphere(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_distance_sphere'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_distance_sphere(geometry, geometry) OWNER TO postgres;

--
-- Name: st_distance_spheroid(geometry, geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_distance_spheroid(geometry, geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_distance_ellipsoid_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_distance_spheroid(geometry, geometry, spheroid) OWNER TO postgres;

--
-- Name: st_dropbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dropbbox(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dropBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_dropbbox(geometry) OWNER TO postgres;

--
-- Name: st_dump(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dump(geometry) RETURNS SETOF geometry_dump
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dump'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_dump(geometry) OWNER TO postgres;

--
-- Name: st_dumprings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dumprings(geometry) RETURNS SETOF geometry_dump
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_dump_rings'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_dumprings(geometry) OWNER TO postgres;

--
-- Name: st_dwithin(geometry, geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_dwithin(geometry, geometry, double precision) RETURNS boolean
    AS $_$SELECT $1 && ST_Expand($2,$3) AND $2 && ST_Expand($1,$3) AND ST_Distance($1, $2) < $3$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_dwithin(geometry, geometry, double precision) OWNER TO postgres;

--
-- Name: st_endpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_endpoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_endpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_endpoint(geometry) OWNER TO postgres;

--
-- Name: st_envelope(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_envelope(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_envelope'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_envelope(geometry) OWNER TO postgres;

--
-- Name: st_equals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_equals(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'geomequals'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_equals(geometry, geometry) OWNER TO postgres;

--
-- Name: st_estimate_histogram2d(histogram2d, box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_estimate_histogram2d(histogram2d, box2d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'estimate_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_estimate_histogram2d(histogram2d, box2d) OWNER TO postgres;

--
-- Name: st_estimated_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_estimated_extent(text, text, text) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_estimated_extent'
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER;


ALTER FUNCTION public.st_estimated_extent(text, text, text) OWNER TO postgres;

--
-- Name: st_estimated_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_estimated_extent(text, text) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_estimated_extent'
    LANGUAGE c IMMUTABLE STRICT SECURITY DEFINER;


ALTER FUNCTION public.st_estimated_extent(text, text) OWNER TO postgres;

--
-- Name: st_expand(box3d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(box3d, double precision) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_expand(box3d, double precision) OWNER TO postgres;

--
-- Name: st_expand(box2d, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(box2d, double precision) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_expand(box2d, double precision) OWNER TO postgres;

--
-- Name: st_expand(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_expand(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_expand'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_expand(geometry, double precision) OWNER TO postgres;

--
-- Name: st_explode_histogram2d(histogram2d, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_explode_histogram2d(histogram2d, text) RETURNS histogram2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'explode_lwhistogram2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_explode_histogram2d(histogram2d, text) OWNER TO postgres;

--
-- Name: st_exteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_exteriorring(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_exteriorring_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_exteriorring(geometry) OWNER TO postgres;

--
-- Name: st_factor(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_factor(chip) RETURNS real
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getFactor'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_factor(chip) OWNER TO postgres;

--
-- Name: st_find_extent(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_find_extent(text, text, text) RETURNS box2d
    AS $_$
DECLARE
	schemaname alias for $1;
	tablename alias for $2;
	columnname alias for $3;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT extent("'||columnname||'") FROM "'||schemaname||'"."'||tablename||'"' LOOP
		return myrec.extent;
	END LOOP; 
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.st_find_extent(text, text, text) OWNER TO postgres;

--
-- Name: st_find_extent(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_find_extent(text, text) RETURNS box2d
    AS $_$
DECLARE
	tablename alias for $1;
	columnname alias for $2;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT extent("'||columnname||'") FROM "'||tablename||'"' LOOP
		return myrec.extent;
	END LOOP; 
END;
$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.st_find_extent(text, text) OWNER TO postgres;

--
-- Name: st_force_2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_2d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_2d(geometry) OWNER TO postgres;

--
-- Name: st_force_3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dz'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_3d(geometry) OWNER TO postgres;

--
-- Name: st_force_3dm(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3dm(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dm'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_3dm(geometry) OWNER TO postgres;

--
-- Name: st_force_3dz(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_3dz(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_3dz'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_3dz(geometry) OWNER TO postgres;

--
-- Name: st_force_4d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_4d(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_4d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_4d(geometry) OWNER TO postgres;

--
-- Name: st_force_collection(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_force_collection(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_force_collection(geometry) OWNER TO postgres;

--
-- Name: st_forcerhr(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_forcerhr(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_forceRHR_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_forcerhr(geometry) OWNER TO postgres;

--
-- Name: st_geom_accum(geometry[], geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geom_accum(geometry[], geometry) RETURNS geometry[]
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_accum'
    LANGUAGE c IMMUTABLE;


ALTER FUNCTION public.st_geom_accum(geometry[], geometry) OWNER TO postgres;

--
-- Name: st_geomcollfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomcollfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_geomcollfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomcollfromtext(text) OWNER TO postgres;

--
-- Name: st_geomcollfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromWKB($1, $2)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomcollfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_geomcollfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomcollfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromWKB($1)) = 'GEOMETRYCOLLECTION'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomcollfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_geometry(box2d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry(box2d) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry(box2d) OWNER TO postgres;

--
-- Name: st_geometry(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry(box3d) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry(box3d) OWNER TO postgres;

--
-- Name: st_geometry(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'parse_WKT_lwgeom'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry(text) OWNER TO postgres;

--
-- Name: st_geometry(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry(chip) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_to_LWGEOM'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry(chip) OWNER TO postgres;

--
-- Name: st_geometry(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_bytea'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry(bytea) OWNER TO postgres;

--
-- Name: st_geometry_above(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_above(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_above'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_above(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_below(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_below(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_below'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_below(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_cmp(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_cmp(geometry, geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_cmp'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_cmp(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_contain(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_contain(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_contain'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_contain(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_contained(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_contained(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_contained'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_contained(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_eq(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_eq(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_eq'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_eq(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_ge(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_ge(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_ge'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_ge(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_gt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_gt(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_gt'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_gt(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_le(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_le(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_le'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_le(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_left(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_left(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_left'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_left(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_lt(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_lt(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'lwgeom_lt'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_lt(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_overabove(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_overabove(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overabove'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_overabove(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_overbelow(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_overbelow(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overbelow'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_overbelow(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_overlap(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_overlap(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overlap'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_overlap(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_overleft(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_overleft(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overleft'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_overleft(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_overright(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_overright(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_overright'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_overright(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_right(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_right(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_right'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_right(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometry_same(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometry_same(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_same'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometry_same(geometry, geometry) OWNER TO postgres;

--
-- Name: st_geometryfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryfromtext(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometryfromtext(text) OWNER TO postgres;

--
-- Name: st_geometryfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryfromtext(text, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometryfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_geometryn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometryn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_geometryn_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometryn(geometry, integer) OWNER TO postgres;

--
-- Name: st_geometrytype(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geometrytype(geometry) RETURNS text
    AS $_$
    DECLARE
        gtype text := geometrytype($1);
    BEGIN
        IF (gtype IN ('POINT', 'POINTM')) THEN
            gtype := 'Point';
        ELSIF (gtype IN ('LINESTRING', 'LINESTRINGM')) THEN
            gtype := 'LineString';
        ELSIF (gtype IN ('POLYGON', 'POLYGONM')) THEN
            gtype := 'Polygon';
        ELSIF (gtype IN ('MULTIPOINT', 'MULTIPOINTM')) THEN
            gtype := 'MultiPoint';
        ELSIF (gtype IN ('MULTILINESTRING', 'MULTILINESTRINGM')) THEN
            gtype := 'MultiLineString';
        ELSIF (gtype IN ('MULTIPOLYGON', 'MULTIPOLYGONM')) THEN
            gtype := 'MultiPolygon';
        ELSE
            gtype := 'Geometry';
        END IF;
        RETURN 'ST_' || gtype;
    END
	$_$
    LANGUAGE plpgsql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geometrytype(geometry) OWNER TO postgres;

--
-- Name: st_geomfromewkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromewkb(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOMFromWKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromewkb(bytea) OWNER TO postgres;

--
-- Name: st_geomfromewkt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromewkt(text) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'parse_WKT_lwgeom'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromewkt(text) OWNER TO postgres;

--
-- Name: st_geomfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromtext(text) RETURNS geometry
    AS $_$SELECT geometryfromtext($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromtext(text) OWNER TO postgres;

--
-- Name: st_geomfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromtext(text, integer) RETURNS geometry
    AS $_$SELECT geometryfromtext($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_geomfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromwkb(bytea) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_from_WKB'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_geomfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_geomfromwkb(bytea, integer) RETURNS geometry
    AS $_$SELECT setSRID(GeomFromWKB($1), $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_geomfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_hasarc(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_hasarc(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_has_arc'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_hasarc(geometry) OWNER TO postgres;

--
-- Name: st_hasbbox(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_hasbbox(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_hasBBOX'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_hasbbox(geometry) OWNER TO postgres;

--
-- Name: st_height(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_height(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getHeight'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_height(chip) OWNER TO postgres;

--
-- Name: st_interiorringn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_interiorringn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_interiorringn_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_interiorringn(geometry, integer) OWNER TO postgres;

--
-- Name: st_intersection(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersection(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'intersection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_intersection(geometry, geometry) OWNER TO postgres;

--
-- Name: st_intersects(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_intersects(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Intersects($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_intersects(geometry, geometry) OWNER TO postgres;

--
-- Name: st_isclosed(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isclosed(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_isclosed_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_isclosed(geometry) OWNER TO postgres;

--
-- Name: st_isempty(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isempty(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_isempty'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_isempty(geometry) OWNER TO postgres;

--
-- Name: st_isring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isring(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'isring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_isring(geometry) OWNER TO postgres;

--
-- Name: st_issimple(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_issimple(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'issimple'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_issimple(geometry) OWNER TO postgres;

--
-- Name: st_isvalid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_isvalid(geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'isvalid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_isvalid(geometry) OWNER TO postgres;

--
-- Name: st_length(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length2d_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length(geometry) OWNER TO postgres;

--
-- Name: st_length2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length2d_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length2d(geometry) OWNER TO postgres;

--
-- Name: st_length2d_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length2d_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length2d_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length2d_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: st_length3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length3d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length3d(geometry) OWNER TO postgres;

--
-- Name: st_length3d_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length3d_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length3d_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: st_length_spheroid(geometry, spheroid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_length_spheroid(geometry, spheroid) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_length_ellipsoid_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_length_spheroid(geometry, spheroid) OWNER TO postgres;

--
-- Name: st_line_interpolate_point(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_interpolate_point(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_interpolate_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_line_interpolate_point(geometry, double precision) OWNER TO postgres;

--
-- Name: st_line_locate_point(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_locate_point(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_locate_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_line_locate_point(geometry, geometry) OWNER TO postgres;

--
-- Name: st_line_substring(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_line_substring(geometry, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_substring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_line_substring(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_linefrommultipoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefrommultipoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_from_mpoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_linefrommultipoint(geometry) OWNER TO postgres;

--
-- Name: st_linefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'LINESTRING'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linefromtext(text) OWNER TO postgres;

--
-- Name: st_linefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'LINESTRING'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linefromtext(text, integer) OWNER TO postgres;

--
-- Name: st_linefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_linefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'LINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linefromwkb(bytea) OWNER TO postgres;

--
-- Name: st_linemerge(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linemerge(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'linemerge'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_linemerge(geometry) OWNER TO postgres;

--
-- Name: st_linestringfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linestringfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'LINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linestringfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_linestringfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linestringfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'LINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_linestringfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_linetocurve(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_linetocurve(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_line_desegmentize'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_linetocurve(geometry) OWNER TO postgres;

--
-- Name: st_locate_along_measure(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locate_along_measure(geometry, double precision) RETURNS geometry
    AS $_$SELECT locate_between_measures($1, $2, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_locate_along_measure(geometry, double precision) OWNER TO postgres;

--
-- Name: st_locate_between_measures(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_locate_between_measures(geometry, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_locate_between_m'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_locate_between_measures(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_m(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_m(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_m_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_m(geometry) OWNER TO postgres;

--
-- Name: st_makebox2d(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makebox2d(geometry, geometry) RETURNS box2d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX2DFLOAT4_construct'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makebox2d(geometry, geometry) OWNER TO postgres;

--
-- Name: st_makebox3d(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makebox3d(geometry, geometry) RETURNS box3d
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_construct'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makebox3d(geometry, geometry) OWNER TO postgres;

--
-- Name: st_makeline(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makeline(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makeline'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makeline(geometry, geometry) OWNER TO postgres;

--
-- Name: st_makeline_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makeline_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makeline_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makeline_garray(geometry[]) OWNER TO postgres;

--
-- Name: st_makepoint(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makepoint(double precision, double precision) OWNER TO postgres;

--
-- Name: st_makepoint(double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makepoint(double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_makepoint(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepoint(double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_makepolygon(geometry, geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepolygon(geometry, geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makepolygon(geometry, geometry[]) OWNER TO postgres;

--
-- Name: st_makepolygon(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_makepolygon(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_makepolygon(geometry) OWNER TO postgres;

--
-- Name: st_max_distance(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_max_distance(geometry, geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_maxdistance2d_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_max_distance(geometry, geometry) OWNER TO postgres;

--
-- Name: st_mem_size(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mem_size(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_mem_size'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_mem_size(geometry) OWNER TO postgres;

--
-- Name: st_mlinefromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE
	WHEN geometrytype(GeomFromText($1, $2)) = 'MULTILINESTRING'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mlinefromtext(text, integer) OWNER TO postgres;

--
-- Name: st_mlinefromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTILINESTRING'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mlinefromtext(text) OWNER TO postgres;

--
-- Name: st_mlinefromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mlinefromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_mlinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mlinefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mlinefromwkb(bytea) OWNER TO postgres;

--
-- Name: st_mpointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'MULTIPOINT'
	THEN GeomFromText($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpointfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_mpointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTIPOINT'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpointfromtext(text) OWNER TO postgres;

--
-- Name: st_mpointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTIPOINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_mpointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_mpolyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromText($1,$2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpolyfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_mpolyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'MULTIPOLYGON'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpolyfromtext(text) OWNER TO postgres;

--
-- Name: st_mpolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_mpolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_mpolyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_mpolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multi(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multi(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_force_multi'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_multi(geometry) OWNER TO postgres;

--
-- Name: st_multilinefromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinefromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTILINESTRING'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multilinefromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multilinestringfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinestringfromtext(text) RETURNS geometry
    AS $_$SELECT MLineFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multilinestringfromtext(text) OWNER TO postgres;

--
-- Name: st_multilinestringfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multilinestringfromtext(text, integer) RETURNS geometry
    AS $_$SELECT MLineFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multilinestringfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_multipointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromtext(text) RETURNS geometry
    AS $_$SELECT MPointFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipointfromtext(text) OWNER TO postgres;

--
-- Name: st_multipointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1,$2)) = 'MULTIPOINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_multipointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multipolyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipolyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_multipolyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'MULTIPOLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipolyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_multipolygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolygonfromtext(text, integer) RETURNS geometry
    AS $_$SELECT MPolyFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipolygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_multipolygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_multipolygonfromtext(text) RETURNS geometry
    AS $_$SELECT MPolyFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_multipolygonfromtext(text) OWNER TO postgres;

--
-- Name: st_ndims(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ndims(geometry) RETURNS smallint
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_ndims'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_ndims(geometry) OWNER TO postgres;

--
-- Name: st_noop(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_noop(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_noop'
    LANGUAGE c STRICT;


ALTER FUNCTION public.st_noop(geometry) OWNER TO postgres;

--
-- Name: st_npoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_npoints(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_npoints'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_npoints(geometry) OWNER TO postgres;

--
-- Name: st_nrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_nrings(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_nrings'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_nrings(geometry) OWNER TO postgres;

--
-- Name: st_numgeometries(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numgeometries(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numgeometries_collection'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_numgeometries(geometry) OWNER TO postgres;

--
-- Name: st_numinteriorring(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numinteriorring(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numinteriorrings_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_numinteriorring(geometry) OWNER TO postgres;

--
-- Name: st_numinteriorrings(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numinteriorrings(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numinteriorrings_polygon'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_numinteriorrings(geometry) OWNER TO postgres;

--
-- Name: st_numpoints(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_numpoints(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_numpoints_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_numpoints(geometry) OWNER TO postgres;

--
-- Name: st_orderingequals(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_orderingequals(geometry, geometry) RETURNS boolean
    AS $_$
    SELECT $1 && $2 AND $1 ~= $2
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_orderingequals(geometry, geometry) OWNER TO postgres;

--
-- Name: st_overlaps(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_overlaps(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Overlaps($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_overlaps(geometry, geometry) OWNER TO postgres;

--
-- Name: st_perimeter(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter2d_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_perimeter(geometry) OWNER TO postgres;

--
-- Name: st_perimeter2d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter2d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter2d_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_perimeter2d(geometry) OWNER TO postgres;

--
-- Name: st_perimeter3d(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_perimeter3d(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_perimeter_poly'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_perimeter3d(geometry) OWNER TO postgres;

--
-- Name: st_point(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_point(double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_makepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_point(double precision, double precision) OWNER TO postgres;

--
-- Name: st_point_inside_circle(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_point_inside_circle(geometry, double precision, double precision, double precision) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_inside_circle_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_point_inside_circle(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_pointfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'POINT'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointfromtext(text) OWNER TO postgres;

--
-- Name: st_pointfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'POINT'
	THEN GeomFromText($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_pointfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'POINT'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_pointfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POINT'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_pointn(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointn(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_pointn_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointn(geometry, integer) OWNER TO postgres;

--
-- Name: st_pointonsurface(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_pointonsurface(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'pointonsurface'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_pointonsurface(geometry) OWNER TO postgres;

--
-- Name: st_polyfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromtext(text) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1)) = 'POLYGON'
	THEN GeomFromText($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polyfromtext(text) OWNER TO postgres;

--
-- Name: st_polyfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromtext(text, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromText($1, $2)) = 'POLYGON'
	THEN GeomFromText($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polyfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_polyfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1, $2)) = 'POLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polyfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_polyfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polyfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polyfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_polygon(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygon(geometry, integer) RETURNS geometry
    AS $_$
	SELECT setSRID(makepolygon($1), $2)
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygon(geometry, integer) OWNER TO postgres;

--
-- Name: st_polygonfromtext(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromtext(text, integer) RETURNS geometry
    AS $_$SELECT PolyFromText($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygonfromtext(text, integer) OWNER TO postgres;

--
-- Name: st_polygonfromtext(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromtext(text) RETURNS geometry
    AS $_$SELECT PolyFromText($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygonfromtext(text) OWNER TO postgres;

--
-- Name: st_polygonfromwkb(bytea, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromwkb(bytea, integer) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1,$2)) = 'POLYGON'
	THEN GeomFromWKB($1, $2)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygonfromwkb(bytea, integer) OWNER TO postgres;

--
-- Name: st_polygonfromwkb(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonfromwkb(bytea) RETURNS geometry
    AS $_$
	SELECT CASE WHEN geometrytype(GeomFromWKB($1)) = 'POLYGON'
	THEN GeomFromWKB($1)
	ELSE NULL END
	$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygonfromwkb(bytea) OWNER TO postgres;

--
-- Name: st_polygonize_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_polygonize_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'polygonize_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_polygonize_garray(geometry[]) OWNER TO postgres;

--
-- Name: st_postgis_gist_joinsel(internal, oid, internal, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_postgis_gist_joinsel(internal, oid, internal, smallint) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_joinsel'
    LANGUAGE c;


ALTER FUNCTION public.st_postgis_gist_joinsel(internal, oid, internal, smallint) OWNER TO postgres;

--
-- Name: st_postgis_gist_sel(internal, oid, internal, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_postgis_gist_sel(internal, oid, internal, integer) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_gist_sel'
    LANGUAGE c;


ALTER FUNCTION public.st_postgis_gist_sel(internal, oid, internal, integer) OWNER TO postgres;

--
-- Name: st_relate(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relate(geometry, geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'relate_full'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_relate(geometry, geometry) OWNER TO postgres;

--
-- Name: st_relate(geometry, geometry, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_relate(geometry, geometry, text) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'relate_pattern'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_relate(geometry, geometry, text) OWNER TO postgres;

--
-- Name: st_removepoint(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_removepoint(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_removepoint'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_removepoint(geometry, integer) OWNER TO postgres;

--
-- Name: st_reverse(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_reverse(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_reverse'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_reverse(geometry) OWNER TO postgres;

--
-- Name: st_rotate(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotate(geometry, double precision) RETURNS geometry
    AS $_$SELECT rotateZ($1, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_rotate(geometry, double precision) OWNER TO postgres;

--
-- Name: st_rotatex(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatex(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1, 1, 0, 0, 0, cos($2), -sin($2), 0, sin($2), cos($2), 0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_rotatex(geometry, double precision) OWNER TO postgres;

--
-- Name: st_rotatey(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatey(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  cos($2), 0, sin($2),  0, 1, 0,  -sin($2), 0, cos($2), 0,  0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_rotatey(geometry, double precision) OWNER TO postgres;

--
-- Name: st_rotatez(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_rotatez(geometry, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  cos($2), -sin($2), 0,  sin($2), cos($2), 0,  0, 0, 1,  0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_rotatez(geometry, double precision) OWNER TO postgres;

--
-- Name: st_scale(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_scale(geometry, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $2, 0, 0,  0, $3, 0,  0, 0, $4,  0, 0, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_scale(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_scale(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_scale(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT scale($1, $2, $3, 1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_scale(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_segmentize(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_segmentize(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_segmentize2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_segmentize(geometry, double precision) OWNER TO postgres;

--
-- Name: st_setfactor(chip, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_setfactor(chip, real) RETURNS chip
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_setFactor'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_setfactor(chip, real) OWNER TO postgres;

--
-- Name: st_setpoint(geometry, integer, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_setpoint(geometry, integer, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_setpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_setpoint(geometry, integer, geometry) OWNER TO postgres;

--
-- Name: st_setsrid(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_setsrid(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_setSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_setsrid(geometry, integer) OWNER TO postgres;

--
-- Name: st_shift_longitude(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_shift_longitude(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_longitude_shift'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_shift_longitude(geometry) OWNER TO postgres;

--
-- Name: st_simplify(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_simplify(geometry, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_simplify2d'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_simplify(geometry, double precision) OWNER TO postgres;

--
-- Name: st_snaptogrid(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_snaptogrid'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_snaptogrid(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_snaptogrid(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT SnapToGrid($1, 0, 0, $2, $3)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_snaptogrid(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_snaptogrid(geometry, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, double precision) RETURNS geometry
    AS $_$SELECT SnapToGrid($1, 0, 0, $2, $2)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_snaptogrid(geometry, double precision) OWNER TO postgres;

--
-- Name: st_snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_snaptogrid_pointoff'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_snaptogrid(geometry, geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_srid(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_srid(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_srid(chip) OWNER TO postgres;

--
-- Name: st_srid(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_srid(geometry) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_getSRID'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_srid(geometry) OWNER TO postgres;

--
-- Name: st_startpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_startpoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_startpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_startpoint(geometry) OWNER TO postgres;

--
-- Name: st_summary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_summary(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_summary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_summary(geometry) OWNER TO postgres;

--
-- Name: st_symdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_symdifference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'symdifference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_symdifference(geometry, geometry) OWNER TO postgres;

--
-- Name: st_symmetricdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_symmetricdifference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'symdifference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_symmetricdifference(geometry, geometry) OWNER TO postgres;

--
-- Name: st_text(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_text(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_text(geometry) OWNER TO postgres;

--
-- Name: st_text(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_text(boolean) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOOL_to_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_text(boolean) OWNER TO postgres;

--
-- Name: st_touches(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_touches(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Touches($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_touches(geometry, geometry) OWNER TO postgres;

--
-- Name: st_transform(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_transform(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'transform'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_transform(geometry, integer) OWNER TO postgres;

--
-- Name: st_translate(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_translate(geometry, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1, 1, 0, 0, 0, 1, 0, 0, 0, 1, $2, $3, $4)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_translate(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_translate(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_translate(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT translate($1, $2, $3, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_translate(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: st_transscale(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_transscale(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $4, 0, 0,  0, $5, 0, 
		0, 0, 1,  $2 * $4, $3 * $5, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_transscale(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: st_union(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_union(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'geomunion'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_union(geometry, geometry) OWNER TO postgres;

--
-- Name: st_unite_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_unite_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'unite_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_unite_garray(geometry[]) OWNER TO postgres;

--
-- Name: st_width(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_width(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getWidth'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_width(chip) OWNER TO postgres;

--
-- Name: st_within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_within(geometry, geometry) RETURNS boolean
    AS $_$SELECT $1 && $2 AND _ST_Within($1,$2)$_$
    LANGUAGE sql IMMUTABLE;


ALTER FUNCTION public.st_within(geometry, geometry) OWNER TO postgres;

--
-- Name: st_wkbtosql(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_wkbtosql(bytea) RETURNS geometry
    AS $_$SELECT GeomFromWKB($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_wkbtosql(bytea) OWNER TO postgres;

--
-- Name: st_wkttosql(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_wkttosql(text) RETURNS geometry
    AS $_$SELECT geometryfromtext($1)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.st_wkttosql(text) OWNER TO postgres;

--
-- Name: st_x(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_x(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_x_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_x(geometry) OWNER TO postgres;

--
-- Name: st_xmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_xmax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_xmax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_xmax(box3d) OWNER TO postgres;

--
-- Name: st_xmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_xmin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_xmin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_xmin(box3d) OWNER TO postgres;

--
-- Name: st_y(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_y(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_y_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_y(geometry) OWNER TO postgres;

--
-- Name: st_ymax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ymax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_ymax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_ymax(box3d) OWNER TO postgres;

--
-- Name: st_ymin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_ymin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_ymin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_ymin(box3d) OWNER TO postgres;

--
-- Name: st_z(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_z(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_z_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_z(geometry) OWNER TO postgres;

--
-- Name: st_zmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_zmax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_zmax(box3d) OWNER TO postgres;

--
-- Name: st_zmflag(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmflag(geometry) RETURNS smallint
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_zmflag'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_zmflag(geometry) OWNER TO postgres;

--
-- Name: st_zmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION st_zmin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_zmin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.st_zmin(box3d) OWNER TO postgres;

--
-- Name: startpoint(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION startpoint(geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_startpoint_linestring'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.startpoint(geometry) OWNER TO postgres;

--
-- Name: summary(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION summary(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_summary'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.summary(geometry) OWNER TO postgres;

--
-- Name: symdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION symdifference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'symdifference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.symdifference(geometry, geometry) OWNER TO postgres;

--
-- Name: symmetricdifference(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION symmetricdifference(geometry, geometry) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'symdifference'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.symmetricdifference(geometry, geometry) OWNER TO postgres;

--
-- Name: text(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION text(geometry) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_to_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.text(geometry) OWNER TO postgres;

--
-- Name: text(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION text(boolean) RETURNS text
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOOL_to_text'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.text(boolean) OWNER TO postgres;

--
-- Name: touches(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION touches(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'touches'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.touches(geometry, geometry) OWNER TO postgres;

--
-- Name: transform(geometry, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION transform(geometry, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'transform'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.transform(geometry, integer) OWNER TO postgres;

--
-- Name: transform_geometry(geometry, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION transform_geometry(geometry, text, text, integer) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'transform_geom'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.transform_geometry(geometry, text, text, integer) OWNER TO postgres;

--
-- Name: translate(geometry, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION translate(geometry, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1, 1, 0, 0, 0, 1, 0, 0, 0, 1, $2, $3, $4)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.translate(geometry, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: translate(geometry, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION translate(geometry, double precision, double precision) RETURNS geometry
    AS $_$SELECT translate($1, $2, $3, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.translate(geometry, double precision, double precision) OWNER TO postgres;

--
-- Name: transscale(geometry, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION transscale(geometry, double precision, double precision, double precision, double precision) RETURNS geometry
    AS $_$SELECT affine($1,  $4, 0, 0,  0, $5, 0, 
		0, 0, 1,  $2 * $4, $3 * $5, 0)$_$
    LANGUAGE sql IMMUTABLE STRICT;


ALTER FUNCTION public.transscale(geometry, double precision, double precision, double precision, double precision) OWNER TO postgres;

--
-- Name: unite_garray(geometry[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION unite_garray(geometry[]) RETURNS geometry
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'unite_garray'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.unite_garray(geometry[]) OWNER TO postgres;

--
-- Name: unlockrows(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION unlockrows(text) RETURNS integer
    AS $_$
DECLARE
	ret int;
BEGIN

	IF NOT LongTransactionsEnabled() THEN
		RAISE EXCEPTION 'Long transaction support disabled, use EnableLongTransaction() to enable.';
	END IF;

	EXECUTE 'DELETE FROM authorization_table where authid = ' ||
		quote_literal($1);

	GET DIAGNOSTICS ret = ROW_COUNT;

	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.unlockrows(text) OWNER TO postgres;

--
-- Name: update_geometry_stats(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_geometry_stats() RETURNS text
    AS $$ SELECT 'update_geometry_stats() has been obsoleted. Statistics are automatically built running the ANALYZE command'::text$$
    LANGUAGE sql;


ALTER FUNCTION public.update_geometry_stats() OWNER TO postgres;

--
-- Name: update_geometry_stats(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_geometry_stats(character varying, character varying) RETURNS text
    AS $$SELECT update_geometry_stats();$$
    LANGUAGE sql;


ALTER FUNCTION public.update_geometry_stats(character varying, character varying) OWNER TO postgres;

--
-- Name: updategeometrysrid(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(character varying, character varying, character varying, character varying, integer) RETURNS text
    AS $_$
DECLARE
	catalog_name alias for $1; 
	schema_name alias for $2;
	table_name alias for $3;
	column_name alias for $4;
	new_srid alias for $5;
	myrec RECORD;
	okay boolean;
	cname varchar;
	real_schema name;

BEGIN


	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = 'f';

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := 't';
		END LOOP;

		IF ( okay <> 't' ) THEN
			RAISE EXCEPTION 'Invalid schema name';
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT INTO real_schema current_schema()::text;
	END IF;

 	-- Find out if the column is in the geometry_columns table
	okay = 'f';
	FOR myrec IN SELECT * from geometry_columns where f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := 't';
	END LOOP; 
	IF (okay <> 't') THEN 
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN 'f';
	END IF;

	-- Update ref from geometry_columns table
	EXECUTE 'UPDATE geometry_columns SET SRID = ' || new_srid::text || 
		' where f_table_schema = ' ||
		quote_literal(real_schema) || ' and f_table_name = ' ||
		quote_literal(table_name)  || ' and f_geometry_column = ' ||
		quote_literal(column_name);
	
	-- Make up constraint name
	cname = 'enforce_srid_'  || column_name;

	-- Drop enforce_srid constraint
	EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
		'.' || quote_ident(table_name) ||
		' DROP constraint ' || quote_ident(cname);

	-- Update geometries SRID
	EXECUTE 'UPDATE ' || quote_ident(real_schema) ||
		'.' || quote_ident(table_name) ||
		' SET ' || quote_ident(column_name) ||
		' = setSRID(' || quote_ident(column_name) ||
		', ' || new_srid::text || ')';

	-- Reset enforce_srid constraint
	EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
		'.' || quote_ident(table_name) ||
		' ADD constraint ' || quote_ident(cname) ||
		' CHECK (srid(' || quote_ident(column_name) ||
		') = ' || new_srid::text || ')';

	RETURN real_schema || '.' || table_name || '.' || column_name ||' SRID changed to ' || new_srid::text;
	
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.updategeometrysrid(character varying, character varying, character varying, character varying, integer) OWNER TO postgres;

--
-- Name: updategeometrysrid(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(character varying, character varying, character varying, integer) RETURNS text
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT UpdateGeometrySRID('',$1,$2,$3,$4) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) OWNER TO postgres;

--
-- Name: updategeometrysrid(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updategeometrysrid(character varying, character varying, integer) RETURNS text
    AS $_$
DECLARE
	ret  text;
BEGIN
	SELECT UpdateGeometrySRID('','',$1,$2,$3) into ret;
	RETURN ret;
END;
$_$
    LANGUAGE plpgsql STRICT;


ALTER FUNCTION public.updategeometrysrid(character varying, character varying, integer) OWNER TO postgres;

--
-- Name: width(chip); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION width(chip) RETURNS integer
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'CHIP_getWidth'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.width(chip) OWNER TO postgres;

--
-- Name: within(geometry, geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION within(geometry, geometry) RETURNS boolean
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'within'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.within(geometry, geometry) OWNER TO postgres;

--
-- Name: x(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION x(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_x_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.x(geometry) OWNER TO postgres;

--
-- Name: xmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION xmax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_xmax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.xmax(box3d) OWNER TO postgres;

--
-- Name: xmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION xmin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_xmin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.xmin(box3d) OWNER TO postgres;

--
-- Name: y(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION y(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_y_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.y(geometry) OWNER TO postgres;

--
-- Name: ymax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ymax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_ymax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.ymax(box3d) OWNER TO postgres;

--
-- Name: ymin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ymin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_ymin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.ymin(box3d) OWNER TO postgres;

--
-- Name: z(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION z(geometry) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_z_point'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.z(geometry) OWNER TO postgres;

--
-- Name: zmax(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION zmax(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_zmax'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.zmax(box3d) OWNER TO postgres;

--
-- Name: zmflag(geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION zmflag(geometry) RETURNS smallint
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'LWGEOM_zmflag'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.zmflag(geometry) OWNER TO postgres;

--
-- Name: zmin(box3d); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION zmin(box3d) RETURNS double precision
    AS '/usr/lib/postgresql/8.3/lib/liblwgeom', 'BOX3D_zmin'
    LANGUAGE c IMMUTABLE STRICT;


ALTER FUNCTION public.zmin(box3d) OWNER TO postgres;

--
-- Name: accum(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE accum(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[]
);


ALTER AGGREGATE public.accum(geometry) OWNER TO postgres;

--
-- Name: collect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE collect(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_collect_garray
);


ALTER AGGREGATE public.collect(geometry) OWNER TO postgres;

--
-- Name: extent(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE extent(geometry) (
    SFUNC = public.st_combine_bbox,
    STYPE = box2d
);


ALTER AGGREGATE public.extent(geometry) OWNER TO postgres;

--
-- Name: extent3d(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE extent3d(geometry) (
    SFUNC = public.combine_bbox,
    STYPE = box3d
);


ALTER AGGREGATE public.extent3d(geometry) OWNER TO postgres;

--
-- Name: geomunion(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE geomunion(geometry) (
    SFUNC = geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_unite_garray
);


ALTER AGGREGATE public.geomunion(geometry) OWNER TO postgres;

--
-- Name: makeline(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE makeline(geometry) (
    SFUNC = geom_accum,
    STYPE = geometry[],
    FINALFUNC = makeline_garray
);


ALTER AGGREGATE public.makeline(geometry) OWNER TO postgres;

--
-- Name: memcollect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE memcollect(geometry) (
    SFUNC = public.st_collect,
    STYPE = geometry
);


ALTER AGGREGATE public.memcollect(geometry) OWNER TO postgres;

--
-- Name: memgeomunion(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE memgeomunion(geometry) (
    SFUNC = public.geomunion,
    STYPE = geometry
);


ALTER AGGREGATE public.memgeomunion(geometry) OWNER TO postgres;

--
-- Name: polygonize(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE polygonize(geometry) (
    SFUNC = geom_accum,
    STYPE = geometry[],
    FINALFUNC = polygonize_garray
);


ALTER AGGREGATE public.polygonize(geometry) OWNER TO postgres;

--
-- Name: st_accum(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_accum(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[]
);


ALTER AGGREGATE public.st_accum(geometry) OWNER TO postgres;

--
-- Name: st_collect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_collect(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_collect_garray
);


ALTER AGGREGATE public.st_collect(geometry) OWNER TO postgres;

--
-- Name: st_extent(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_extent(geometry) (
    SFUNC = public.st_combine_bbox,
    STYPE = box2d
);


ALTER AGGREGATE public.st_extent(geometry) OWNER TO postgres;

--
-- Name: st_extent3d(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_extent3d(geometry) (
    SFUNC = public.st_combine_bbox,
    STYPE = box3d
);


ALTER AGGREGATE public.st_extent3d(geometry) OWNER TO postgres;

--
-- Name: st_makeline(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_makeline(geometry) (
    SFUNC = geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_makeline_garray
);


ALTER AGGREGATE public.st_makeline(geometry) OWNER TO postgres;

--
-- Name: st_memcollect(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_memcollect(geometry) (
    SFUNC = public.st_collect,
    STYPE = geometry
);


ALTER AGGREGATE public.st_memcollect(geometry) OWNER TO postgres;

--
-- Name: st_memunion(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_memunion(geometry) (
    SFUNC = public.st_union,
    STYPE = geometry
);


ALTER AGGREGATE public.st_memunion(geometry) OWNER TO postgres;

--
-- Name: st_polygonize(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_polygonize(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_polygonize_garray
);


ALTER AGGREGATE public.st_polygonize(geometry) OWNER TO postgres;

--
-- Name: st_union(geometry); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE st_union(geometry) (
    SFUNC = st_geom_accum,
    STYPE = geometry[],
    FINALFUNC = st_unite_garray
);


ALTER AGGREGATE public.st_union(geometry) OWNER TO postgres;

--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR && (
    PROCEDURE = st_geometry_overlap,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &&,
    RESTRICT = st_postgis_gist_sel,
    JOIN = st_postgis_gist_joinsel
);


ALTER OPERATOR public.&& (geometry, geometry) OWNER TO postgres;

--
-- Name: &<; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &< (
    PROCEDURE = st_geometry_overleft,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&< (geometry, geometry) OWNER TO postgres;

--
-- Name: &<|; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &<| (
    PROCEDURE = st_geometry_overbelow,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = |&>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&<| (geometry, geometry) OWNER TO postgres;

--
-- Name: &>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR &> (
    PROCEDURE = st_geometry_overright,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &<,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.&> (geometry, geometry) OWNER TO postgres;

--
-- Name: <; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR < (
    PROCEDURE = st_geometry_lt,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.< (geometry, geometry) OWNER TO postgres;

--
-- Name: <<; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR << (
    PROCEDURE = st_geometry_left,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.<< (geometry, geometry) OWNER TO postgres;

--
-- Name: <<|; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <<| (
    PROCEDURE = st_geometry_below,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = |>>,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.<<| (geometry, geometry) OWNER TO postgres;

--
-- Name: <=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR <= (
    PROCEDURE = st_geometry_le,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.<= (geometry, geometry) OWNER TO postgres;

--
-- Name: =; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR = (
    PROCEDURE = st_geometry_eq,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = =,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.= (geometry, geometry) OWNER TO postgres;

--
-- Name: >; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR > (
    PROCEDURE = st_geometry_gt,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.> (geometry, geometry) OWNER TO postgres;

--
-- Name: >=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR >= (
    PROCEDURE = st_geometry_ge,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.>= (geometry, geometry) OWNER TO postgres;

--
-- Name: >>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR >> (
    PROCEDURE = st_geometry_right,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <<,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.>> (geometry, geometry) OWNER TO postgres;

--
-- Name: @; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR @ (
    PROCEDURE = st_geometry_contained,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = ~,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.@ (geometry, geometry) OWNER TO postgres;

--
-- Name: |&>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR |&> (
    PROCEDURE = st_geometry_overabove,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = &<|,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.|&> (geometry, geometry) OWNER TO postgres;

--
-- Name: |>>; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR |>> (
    PROCEDURE = st_geometry_above,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = <<|,
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


ALTER OPERATOR public.|>> (geometry, geometry) OWNER TO postgres;

--
-- Name: ~; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR ~ (
    PROCEDURE = st_geometry_contain,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = @,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


ALTER OPERATOR public.~ (geometry, geometry) OWNER TO postgres;

--
-- Name: ~=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR ~= (
    PROCEDURE = st_geometry_same,
    LEFTARG = geometry,
    RIGHTARG = geometry,
    COMMUTATOR = ~=,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


ALTER OPERATOR public.~= (geometry, geometry) OWNER TO postgres;

--
-- Name: btree_geometry_ops; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS btree_geometry_ops
    DEFAULT FOR TYPE geometry USING btree AS
    OPERATOR 1 <(geometry,geometry) ,
    OPERATOR 2 <=(geometry,geometry) ,
    OPERATOR 3 =(geometry,geometry) ,
    OPERATOR 4 >=(geometry,geometry) ,
    OPERATOR 5 >(geometry,geometry) ,
    FUNCTION 1 geometry_cmp(geometry,geometry);


ALTER OPERATOR CLASS public.btree_geometry_ops USING btree OWNER TO postgres;

--
-- Name: gist_geometry_ops; Type: OPERATOR CLASS; Schema: public; Owner: postgres
--

CREATE OPERATOR CLASS gist_geometry_ops
    DEFAULT FOR TYPE geometry USING gist AS
    STORAGE box2d ,
    OPERATOR 1 <<(geometry,geometry) RECHECK ,
    OPERATOR 2 &<(geometry,geometry) RECHECK ,
    OPERATOR 3 &&(geometry,geometry) RECHECK ,
    OPERATOR 4 &>(geometry,geometry) RECHECK ,
    OPERATOR 5 >>(geometry,geometry) RECHECK ,
    OPERATOR 6 ~=(geometry,geometry) RECHECK ,
    OPERATOR 7 ~(geometry,geometry) RECHECK ,
    OPERATOR 8 @(geometry,geometry) RECHECK ,
    OPERATOR 9 &<|(geometry,geometry) RECHECK ,
    OPERATOR 10 <<|(geometry,geometry) RECHECK ,
    OPERATOR 11 |>>(geometry,geometry) RECHECK ,
    OPERATOR 12 |&>(geometry,geometry) RECHECK ,
    FUNCTION 1 lwgeom_gist_consistent(internal,geometry,integer) ,
    FUNCTION 2 lwgeom_gist_union(bytea,internal) ,
    FUNCTION 3 lwgeom_gist_compress(internal) ,
    FUNCTION 4 lwgeom_gist_decompress(internal) ,
    FUNCTION 5 lwgeom_gist_penalty(internal,internal,internal) ,
    FUNCTION 6 lwgeom_gist_picksplit(internal,internal) ,
    FUNCTION 7 lwgeom_gist_same(box2d,box2d,internal);


ALTER OPERATOR CLASS public.gist_geometry_ops USING gist OWNER TO postgres;

SET search_path = pg_catalog;

--
-- Name: CAST (public.box2d AS public.box3d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box2d AS public.box3d) WITH FUNCTION public.st_box3d(public.box2d) AS IMPLICIT;


--
-- Name: CAST (public.box2d AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box2d AS public.geometry) WITH FUNCTION public.st_geometry(public.box2d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS box); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS box) WITH FUNCTION public.st_box(public.box3d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS public.box2d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS public.box2d) WITH FUNCTION public.st_box2d(public.box3d) AS IMPLICIT;


--
-- Name: CAST (public.box3d AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.box3d AS public.geometry) WITH FUNCTION public.st_geometry(public.box3d) AS IMPLICIT;


--
-- Name: CAST (bytea AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (bytea AS public.geometry) WITH FUNCTION public.st_geometry(bytea) AS IMPLICIT;


--
-- Name: CAST (public.chip AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.chip AS public.geometry) WITH FUNCTION public.st_geometry(public.chip) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS box); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS box) WITH FUNCTION public.st_box(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.box2d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.box2d) WITH FUNCTION public.st_box2d(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS public.box3d); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS public.box3d) WITH FUNCTION public.st_box3d(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS bytea); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS bytea) WITH FUNCTION public.st_bytea(public.geometry) AS IMPLICIT;


--
-- Name: CAST (public.geometry AS text); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (public.geometry AS text) WITH FUNCTION public.st_text(public.geometry) AS IMPLICIT;


--
-- Name: CAST (text AS public.geometry); Type: CAST; Schema: pg_catalog; Owner: 
--

CREATE CAST (text AS public.geometry) WITH FUNCTION public.st_geometry(text) AS IMPLICIT;


SET search_path = public, pg_catalog;

--
-- Name: app_catalog_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE app_catalog_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.app_catalog_row_id_seq OWNER TO xeniaprod;

--
-- Name: app_catalog_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE app_catalog_row_id_seq OWNED BY app_catalog.row_id;


--
-- Name: custom_fields_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE custom_fields_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.custom_fields_row_id_seq OWNER TO xeniaprod;

--
-- Name: custom_fields_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE custom_fields_row_id_seq OWNED BY custom_fields.row_id;


--
-- Name: loginuser_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE loginuser_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.loginuser_id_seq OWNER TO xeniaprod;

--
-- Name: loginuser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE loginuser_id_seq OWNED BY loginuser.id;


--
-- Name: metadata_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE metadata_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.metadata_row_id_seq OWNER TO xeniaprod;

--
-- Name: metadata_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE metadata_row_id_seq OWNED BY metadata.row_id;


--
-- Name: multi_obs_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE multi_obs_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.multi_obs_row_id_seq OWNER TO xeniaprod;

--
-- Name: multi_obs_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE multi_obs_row_id_seq OWNED BY multi_obs.row_id;


--
-- Name: organization_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE organization_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.organization_row_id_seq OWNER TO xeniaprod;

--
-- Name: organization_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE organization_row_id_seq OWNED BY organization.row_id;


--
-- Name: platform_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE platform_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.platform_row_id_seq OWNER TO xeniaprod;

--
-- Name: platform_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE platform_row_id_seq OWNED BY platform.row_id;


--
-- Name: platform_status_archive_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE platform_status_archive_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.platform_status_archive_row_id_seq OWNER TO xeniaprod;

--
-- Name: platform_status_archive_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE platform_status_archive_row_id_seq OWNED BY platform_status_archive.row_id;


--
-- Name: platform_status_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE platform_status_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.platform_status_row_id_seq OWNER TO xeniaprod;

--
-- Name: platform_status_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE platform_status_row_id_seq OWNED BY platform_status.row_id;


--
-- Name: project_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE project_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.project_row_id_seq OWNER TO xeniaprod;

--
-- Name: project_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE project_row_id_seq OWNED BY project.row_id;


--
-- Name: sensor_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE sensor_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sensor_row_id_seq OWNER TO xeniaprod;

--
-- Name: sensor_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE sensor_row_id_seq OWNED BY sensor.row_id;


--
-- Name: sensor_status_archive_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE sensor_status_archive_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sensor_status_archive_row_id_seq OWNER TO xeniaprod;

--
-- Name: sensor_status_archive_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE sensor_status_archive_row_id_seq OWNED BY sensor_status_archive.row_id;


--
-- Name: sensor_status_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE sensor_status_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sensor_status_row_id_seq OWNER TO xeniaprod;

--
-- Name: sensor_status_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE sensor_status_row_id_seq OWNED BY sensor_status.row_id;


--
-- Name: status_type_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE status_type_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.status_type_row_id_seq OWNER TO xeniaprod;

--
-- Name: status_type_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE status_type_row_id_seq OWNED BY status_type.row_id;


--
-- Name: timestamp_lkp_row_id_seq; Type: SEQUENCE; Schema: public; Owner: xeniaprod
--

CREATE SEQUENCE timestamp_lkp_row_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.timestamp_lkp_row_id_seq OWNER TO xeniaprod;

--
-- Name: timestamp_lkp_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: xeniaprod
--

ALTER SEQUENCE timestamp_lkp_row_id_seq OWNED BY timestamp_lkp.row_id;


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE app_catalog ALTER COLUMN row_id SET DEFAULT nextval('app_catalog_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE custom_fields ALTER COLUMN row_id SET DEFAULT nextval('custom_fields_row_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE loginuser ALTER COLUMN id SET DEFAULT nextval('loginuser_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE metadata ALTER COLUMN row_id SET DEFAULT nextval('metadata_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE multi_obs ALTER COLUMN row_id SET DEFAULT nextval('multi_obs_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE organization ALTER COLUMN row_id SET DEFAULT nextval('organization_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE platform ALTER COLUMN row_id SET DEFAULT nextval('platform_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE platform_status ALTER COLUMN row_id SET DEFAULT nextval('platform_status_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE platform_status_archive ALTER COLUMN row_id SET DEFAULT nextval('platform_status_archive_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE project ALTER COLUMN row_id SET DEFAULT nextval('project_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE sensor ALTER COLUMN row_id SET DEFAULT nextval('sensor_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE sensor_status ALTER COLUMN row_id SET DEFAULT nextval('sensor_status_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE sensor_status_archive ALTER COLUMN row_id SET DEFAULT nextval('sensor_status_archive_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE status_type ALTER COLUMN row_id SET DEFAULT nextval('status_type_row_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: public; Owner: xeniaprod
--

ALTER TABLE timestamp_lkp ALTER COLUMN row_id SET DEFAULT nextval('timestamp_lkp_row_id_seq'::regclass);


--
-- Name: app_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY app_catalog
    ADD CONSTRAINT app_catalog_pkey PRIMARY KEY (row_id);


--
-- Name: custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (row_id);


--
-- Name: geometry_columns_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY geometry_columns
    ADD CONSTRAINT geometry_columns_pk PRIMARY KEY (f_table_catalog, f_table_schema, f_table_name, f_geometry_column);


--
-- Name: loginuser_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY loginuser
    ADD CONSTRAINT loginuser_pkey PRIMARY KEY (id);


--
-- Name: m_scalar_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_scalar_type_pkey PRIMARY KEY (row_id);


--
-- Name: m_type_display_order_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY m_type_display_order
    ADD CONSTRAINT m_type_display_order_pkey PRIMARY KEY (row_id);


--
-- Name: m_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_type_pkey PRIMARY KEY (row_id);


--
-- Name: metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (row_id);


--
-- Name: multi_obs_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_pkey PRIMARY KEY (row_id);


--
-- Name: obs_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY obs_type
    ADD CONSTRAINT obs_type_pkey PRIMARY KEY (row_id);


--
-- Name: organization_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (row_id);


--
-- Name: platform_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_pkey PRIMARY KEY (row_id);


--
-- Name: platform_status_archive_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY platform_status_archive
    ADD CONSTRAINT platform_status_archive_pkey PRIMARY KEY (row_id);


--
-- Name: platform_status_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY platform_status
    ADD CONSTRAINT platform_status_pkey PRIMARY KEY (row_id);


--
-- Name: platform_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY platform_type
    ADD CONSTRAINT platform_type_pkey PRIMARY KEY (row_id);


--
-- Name: product_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY product_type
    ADD CONSTRAINT product_type_pkey PRIMARY KEY (row_id);


--
-- Name: project_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_pkey PRIMARY KEY (row_id);


--
-- Name: sensor_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_pkey PRIMARY KEY (row_id);


--
-- Name: sensor_status_archive_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY sensor_status_archive
    ADD CONSTRAINT sensor_status_archive_pkey PRIMARY KEY (row_id);


--
-- Name: sensor_status_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY sensor_status
    ADD CONSTRAINT sensor_status_pkey PRIMARY KEY (row_id);


--
-- Name: sensor_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY sensor_type
    ADD CONSTRAINT sensor_type_pkey PRIMARY KEY (row_id);


--
-- Name: spatial_ref_sys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY spatial_ref_sys
    ADD CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid);


--
-- Name: status_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY status_type
    ADD CONSTRAINT status_type_pkey PRIMARY KEY (row_id);


--
-- Name: timestamp_lkp_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY timestamp_lkp
    ADD CONSTRAINT timestamp_lkp_pkey PRIMARY KEY (row_id);


--
-- Name: uom_type_pkey; Type: CONSTRAINT; Schema: public; Owner: xeniaprod; Tablespace: 
--

ALTER TABLE ONLY uom_type
    ADD CONSTRAINT uom_type_pkey PRIMARY KEY (row_id);


--
-- Name: i_multi_obs; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE UNIQUE INDEX i_multi_obs ON multi_obs USING btree (m_date, m_type_id, sensor_id);


--
-- Name: i_multi_obs_top_hour; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE INDEX i_multi_obs_top_hour ON multi_obs USING btree (d_report_hour, d_top_of_hour);


--
-- Name: i_platform; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE UNIQUE INDEX i_platform ON platform USING btree (platform_handle);


--
-- Name: i_sensor; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE UNIQUE INDEX i_sensor ON sensor USING btree (platform_id, m_type_id, s_order);


--
-- Name: idx_timestamp_lkp; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE UNIQUE INDEX idx_timestamp_lkp ON timestamp_lkp USING btree (product_id, pass_timestamp);


--
-- Name: platform_status_archive_index; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE INDEX platform_status_archive_index ON platform_status_archive USING btree (platform_id, row_entry_date);


--
-- Name: platform_status_index; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE INDEX platform_status_index ON platform_status USING btree (platform_handle);


--
-- Name: platform_type_idx; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE UNIQUE INDEX platform_type_idx ON platform_type USING btree (type_name, short_name);


--
-- Name: sensor_status_archive_index; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE INDEX sensor_status_archive_index ON sensor_status_archive USING btree (sensor_id, row_entry_date);


--
-- Name: sensor_status_index; Type: INDEX; Schema: public; Owner: xeniaprod; Tablespace: 
--

CREATE INDEX sensor_status_index ON sensor_status USING btree (sensor_id);


--
-- Name: mk_platform_geom; Type: TRIGGER; Schema: public; Owner: xeniaprod
--

CREATE TRIGGER mk_platform_geom
    BEFORE INSERT ON platform
    FOR EACH ROW
    EXECUTE PROCEDURE mk_platform_geom();


--
-- Name: mk_the_geom; Type: TRIGGER; Schema: public; Owner: xeniaprod
--

CREATE TRIGGER mk_the_geom
    BEFORE INSERT ON multi_obs
    FOR EACH ROW
    EXECUTE PROCEDURE mk_the_geom();


--
-- Name: set_top_of_hour; Type: TRIGGER; Schema: public; Owner: xeniaprod
--

CREATE TRIGGER set_top_of_hour
    AFTER INSERT ON multi_obs
    FOR EACH ROW
    EXECUTE PROCEDURE set_top_of_hour();


--
-- Name: m_scalar_type_id_2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_2_fkey FOREIGN KEY (m_scalar_type_id_2) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_3_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_3_fkey FOREIGN KEY (m_scalar_type_id_3) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_4_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_4_fkey FOREIGN KEY (m_scalar_type_id_4) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_5_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_5_fkey FOREIGN KEY (m_scalar_type_id_5) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_6_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_6_fkey FOREIGN KEY (m_scalar_type_id_6) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_7_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_7_fkey FOREIGN KEY (m_scalar_type_id_7) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_8_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_8_fkey FOREIGN KEY (m_scalar_type_id_8) REFERENCES m_scalar_type(row_id);


--
-- Name: m_scalar_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_type
    ADD CONSTRAINT m_scalar_type_id_fkey FOREIGN KEY (m_scalar_type_id) REFERENCES m_scalar_type(row_id);


--
-- Name: m_type_obs_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_type_obs_type_id_fkey FOREIGN KEY (obs_type_id) REFERENCES obs_type(row_id);


--
-- Name: m_type_uom_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY m_scalar_type
    ADD CONSTRAINT m_type_uom_type_id_fkey FOREIGN KEY (uom_type_id) REFERENCES uom_type(row_id);


--
-- Name: multi_obs_m_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_m_type_id_fkey FOREIGN KEY (m_type_id) REFERENCES m_type(row_id);


--
-- Name: multi_obs_sensor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY multi_obs
    ADD CONSTRAINT multi_obs_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES sensor(row_id);


--
-- Name: platform_app_catalog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_app_catalog_id_fkey FOREIGN KEY (app_catalog_id) REFERENCES app_catalog(row_id);


--
-- Name: platform_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(row_id);


--
-- Name: platform_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(row_id);


--
-- Name: platform_status_archive_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status_archive
    ADD CONSTRAINT platform_status_archive_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(row_id);


--
-- Name: platform_status_archive_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status_archive
    ADD CONSTRAINT platform_status_archive_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);


--
-- Name: platform_status_archive_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status_archive
    ADD CONSTRAINT platform_status_archive_status_fkey FOREIGN KEY (status) REFERENCES status_type(row_id);


--
-- Name: platform_status_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status
    ADD CONSTRAINT platform_status_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(row_id);


--
-- Name: platform_status_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status
    ADD CONSTRAINT platform_status_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);


--
-- Name: platform_status_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform_status
    ADD CONSTRAINT platform_status_status_fkey FOREIGN KEY (status) REFERENCES status_type(row_id);


--
-- Name: platform_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_type_id_fkey FOREIGN KEY (type_id) REFERENCES platform_type(row_id);


--
-- Name: sensor_m_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_m_type_id_fkey FOREIGN KEY (m_type_id) REFERENCES m_type(row_id);


--
-- Name: sensor_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);


--
-- Name: sensor_status_archive_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status_archive
    ADD CONSTRAINT sensor_status_archive_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);


--
-- Name: sensor_status_archive_sensor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status_archive
    ADD CONSTRAINT sensor_status_archive_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES sensor(row_id);


--
-- Name: sensor_status_archive_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status_archive
    ADD CONSTRAINT sensor_status_archive_status_fkey FOREIGN KEY (status) REFERENCES status_type(row_id);


--
-- Name: sensor_status_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status
    ADD CONSTRAINT sensor_status_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platform(row_id);


--
-- Name: sensor_status_sensor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status
    ADD CONSTRAINT sensor_status_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES sensor(row_id);


--
-- Name: sensor_status_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor_status
    ADD CONSTRAINT sensor_status_status_fkey FOREIGN KEY (status) REFERENCES status_type(row_id);


--
-- Name: sensor_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY sensor
    ADD CONSTRAINT sensor_type_id_fkey FOREIGN KEY (type_id) REFERENCES sensor_type(row_id);


--
-- Name: timestamp_lkp_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: xeniaprod
--

ALTER TABLE ONLY timestamp_lkp
    ADD CONSTRAINT timestamp_lkp_product_id_fkey FOREIGN KEY (product_id) REFERENCES product_type(row_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE geometry_columns FROM PUBLIC;
REVOKE ALL ON TABLE geometry_columns FROM postgres;
GRANT ALL ON TABLE geometry_columns TO postgres;
GRANT ALL ON TABLE geometry_columns TO PUBLIC;


--
-- PostgreSQL database dump complete
--

