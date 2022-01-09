CREATE TABLE public.tripdata
(
	ride_id	char(16),  -- no foresight needed but assign 16 characters for this small project
	rideable_type varchar(32),
	started_at timestamp, -- this is the datetime datatype for postgresql
	ended_at timestamp,
	start_station_name varchar(256),
	start_station_id varchar(256),
	end_station_name varchar(256),
	end_station_id varchar(256),
	start_lat NUMERIC, -- Postgresql dialect
	start_lng NUMERIC,
	end_lat NUMERIC,
	end_lng NUMERIC,
	member_casual char(6), -- 6 characters for member and casual not more or less
  	PRIMARY KEY(ride_id)
);
