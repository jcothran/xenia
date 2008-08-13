-- scalar data dictionary listing (standard listing)
-- select t1.row_id,t2.standard_name,t3.standard_name from m_scalar_type t1,obs_type t2,uom_type t3 where t1.obs_type_id = t2.row_id and t1.uom_type_id = t3.row_id;

INSERT INTO obs_type(row_id,standard_name,definition) VALUES (27, 'surface_chlorophyll', 'Bottom Water Chlorophyll');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (12, 'current_to_direction', 'Direction toward which current is flowing');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (14, 'dominant_wave_period', 'Dominant Wave period');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (2, 'wind_gust', 'Maximum instantaneous wind speed (usually no more than but not limited to 10 seconds) within a sample averaging interval');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (3, 'wind_from_direction', 'Direction from which wind is blowing.  Meteorological Convention.');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (4, 'air_pressure', 'Pressure exerted by overlying air.');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (5, 'air_temperature', 'Temperature of air, in situ.');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (6, 'water_temperature', 'Water temperature');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (8, 'water_pressure', 'Water Pressure');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (9, 'water_salinity', 'Water Salinity');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (11, 'current_speed', 'Water Current Magnitude');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (13, 'significant_wave_height', 'Significant wave height');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (15, 'significant_wave_to_direction', 'Significant Wave Direction');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (20, 'sea_surface_eastward_current', 'East/West component of ocean current near the sea surface, Eastward is positive');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (21, 'sea_surface_northward_current', 'North/South component of ocean current near the sea surface, Northward is positive');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (1, 'wind_speed', 'Wind speed');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (22, 'relative_humidity', 'Relative humidity');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (23, 'water_level', 'water_level');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (24, 'bottom_water_salinity', 'Bottom Water Salinity');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (25, 'surface_water_salinity', 'Surface Water Salinity');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (26, 'bottom_chlorophyll', 'Bottom Water Chlorophyll');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (28, 'salinity', 'salinity');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (18, 'sea_surface_temperature', 'Surface Water temperature');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (19, 'sea_bottom_temperature', 'Bottom Water temperature');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (29, 'precipitation', 'measured precipitation or rainfall');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (30, 'solar_radiation', 'measured solar radiation or sunlight');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (31, 'eastward_current', 'East/West component of water current, Eastward is positive');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (32, 'northward_current', 'North/South component of water current, Northward is positive');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (34, 'oxygen_concentration', 'concentration of oxygen in a defined volume of water');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (10, 'chl_concentration', 'concentration of cholorophyll-a in a defined volume of water');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (7, 'water_conductivity', 'Ability of a specific volume (1 cubic centimeter) of water to pass an electrical current');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (35, 'turbidity', 'Measure of light scattering due to suspended material in water.');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (36, 'ph', '(from potential of Hydrogen) the logarithm of the reciprocal of hydrogen-ion concentration in gram atoms per liter');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (37, 'visibility', 'Greatest distance an object can be seen and identified. Usually refering to visibility in air');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (33, 'precipitation_accumulated_daily', 'measured precipitation or rainfall daily accumulation');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (38, 'precipitation_accumulated_storm', 'measured precipitation or rainfall storm accumulation');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (39, 'drifter_speed', 'drifter speed');
INSERT INTO obs_type(row_id,standard_name,definition) VALUES (40, 'drifter_direction', 'direction which drifter is moving in degrees from North');

--
-- Data for Name: uom_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (12, 'ppt', 'parts per thousand', 'ppt');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (10, 'psu', 'practical salinity units', 'psu');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (6, 'm', 'meter', 'm');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (2, 'degrees_true', 'degrees clockwise from true north', 'deg');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (3, 'celsius', 'degrees celsius', 'deg C');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (4, 'mb', '1 mb = 0.001 bar = 100 Pa = 1 000 dyn/cm^2', 'mb');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (7, 's', 'seconds', 's');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (9, 'millibar', 'millibar', 'mb');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (11, 'percent', 'percentage', '%');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (1, 'm_s-1', 'meters per second', 'm/s');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (8, 'cm_s-1', 'centrimeter per second', 'cm/s');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (13, 'ug_L-1', 'micrograms per liter', 'ug/L');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (14, 'millimeter', 'millimeter', 'mm');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (15, 'millimoles_per_m^2', 'millimoles per meter squared', 'millimoles per m^2');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (16, 'units', 'a dimensionless unit', 'units');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (17, 'ntu', 'nephelometric turbidity units', 'ntu');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (18, 'mg_L-1', 'milligrams per liter', 'mg/L');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (5, 'mS_cm-1', 'milliSiemens per centimeter', 'mS/cm');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (19, 'nautical_miles', 'equal to 1.151 statue miles', 'nautical miles');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (20, 'mph', 'miles per hour', 'mph');
INSERT INTO uom_type(row_id,standard_name,definition,display) VALUES (21, 'knots', 'knots', 'knots');

--
-- Data for Name: m_scalar_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (10, 10, 13);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (9, 9, 10);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (24, 24, 10);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (25, 25, 10);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (28, 28, 10);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (2, 2, 1);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (3, 3, 2);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (4, 4, 4);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (5, 5, 3);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (6, 6, 3);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (7, 7, 5);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (8, 8, 4);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (11, 11, 8);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (12, 12, 2);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (13, 13, 6);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (14, 14, 7);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (15, 15, 2);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (18, 18, 3);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (20, 20, 8);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (21, 21, 8);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (1, 1, 1);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (22, 22, 11);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (19, 19, 3);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (23, 23, 6);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (26, 26, 13);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (27, 27, 13);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (29, 29, 14);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (30, 30, 15);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (31, 31, 8);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (32, 32, 8);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (33, 33, 14);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (34, 34, 18);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (35, 34, 11);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (36, 35, 17);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (38, 36, 16);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (39, 37, 19);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (40, 38, 14);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (41, 39, 1);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (42, 39, 20);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (43, 39, 21);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (44, 40, 2);
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (45, 31, 1);						  
INSERT INTO m_scalar_type(row_id,obs_type_id,uom_type_id) VALUES (46, 32, 1);

--
-- simple scalar types

INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (10, 1, 10);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (9, 1, 9);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (24, 1, 24);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (25, 1, 25);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (28, 1, 28);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (2, 1, 2);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (3, 1, 3);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (4, 1, 4);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (5, 1, 5);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (6, 1, 6);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (7, 1, 7);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (8, 1, 8);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (11, 1, 11);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (12, 1, 12);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (13, 1, 13);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (14, 1, 14);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (15, 1, 15);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (18, 1, 18);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (20, 1, 20);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (21, 1, 21);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (1, 1, 1);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (22, 1, 22);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (19, 1, 19);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (23, 1, 23);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (26, 1, 26);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (27, 1, 27);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (29, 1, 29);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (30, 1, 30);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (31, 1, 31);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (32, 1, 32);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (33, 1, 33);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (34, 1, 34);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (35, 1, 35);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (36, 1, 36);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (38, 1, 38);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (39, 1, 39);
INSERT INTO m_type (row_id,num_types,m_scalar_type_id) VALUES (40, 1, 40);

-- vector types

INSERT INTO m_type (row_id,num_types,m_scalar_type_id,m_scalar_type_id_2,m_scalar_type_id_3,m_scalar_type_id_4) VALUES (41,4,41,42,43,44);

INSERT INTO m_type (row_id,num_types,m_scalar_type_id,m_scalar_type_id_2) VALUES (42,2,45,46);
