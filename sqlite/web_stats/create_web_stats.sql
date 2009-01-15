create table ip_info (
row_id integer PRIMARY KEY,
row_entry_date timestamp,
ip text,
dns_lookup text,
desc text,
ignore int
);

create table agent_info (
row_id integer PRIMARY KEY,
row_entry_date timestamp,
agent text,
ignore int
);

create table page_info (
row_id integer PRIMARY KEY,
row_entry_date timestamp,
page text,
ignore int
);

create table referer_info (
row_id integer PRIMARY KEY,
row_entry_date timestamp,
referer text,
ignore int
);

create table cross_ref_info (
row_id integer PRIMARY KEY,
ip_id int,
page_date timestamp,
page_id int,
referer_id int
);

