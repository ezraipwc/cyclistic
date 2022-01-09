-- OCT 10 2021
-- Import csv files from 202008 to 202107.
-- Cannot import 202011 due to ride_id duplicate.
-- ride_id: 8758E473B457691C, 47E0C01E8F7BD830, 4AE7C88494448250
--SELECT *
-- FROM public.tripdata
-- WHERE ride_id= '4AE7C88494448250';


-- Erased this entry for the end time is 20~ days before start time.
-- DELETE
-- FROM public.tripdata
-- WHERE ride_id= '4AE7C88494448250';

-- That's too many of negative time data. 
-- Clean all negative duration before import 202011.
-- DELETE 
-- FROM public.tripdata
-- WHERE ended_at <= started_at;
-- 7723 entries removed.

-- And import 202011 csv. SUCCESS, 10.23 seconds
-- And erase all negative duration again
-- DELETE 
-- FROM public.tripdata
-- WHERE ended_at <= started_at;
-- 893 entries removed.

-- Now add a column for duration
-- ALTER TABLE public.tripdata
-- ADD duration interval;

-- Evaluate duration 
-- UPDATE public.tripdata
-- SET duration = ended_at - started_at;
-- UPDATE 4722462. Time elapsed: 2min45s.

-- SELECT *
-- FROM public.tripdata
-- LIMIT 1000;

-- Create columns with lat/lng data rounded off to 2 dp
-- ALTER TABLE public.tripdata
-- ADD COLUMN start_lat_2dp numeric, 
-- ADD COLUMN start_lng_2dp numeric,
-- ADD COLUMN end_lat_2dp numeric,
-- ADD COLUMN end_lng_2dp numeric;

-- Evaluate the round off of lat/lng data.
-- UPDATE public.tripdata
-- SET start_lat_2dp = ROUND(start_lat,2),
-- 	start_lng_2dp = ROUND(start_lng,2),
-- 	end_lat_2dp = ROUND(end_lat,2),
-- 	end_lng_2dp = ROUND(end_lng,2);
-- Time elapsed: 3min51s.


-- Now I export this database as tripdata.csv

-- DATA Cleaning
-- SELECT member_casual, COUNT(*)
-- FROM public.tripdata
-- GROUP BY member_casual;
-- tried on rideable_type, member_casual, no missing, no abberrant

-- ON station names and ids

-- SELECT DISTINCT start_station_id, start_station_name
-- FROM public.tripdata
-- ORDER BY start_station_id;
-- 1325 rows of start_station_id. Not surprised if a system has obsolete stns.
-- Stn_id missing: "W Oakdale Ave & N Broadway", "W Armitage Ave & N Sheffield Ave", "N Clark St & W Elm St", "S Michigan Ave & E 118th St"

-- SELECT DISTINCT end_station_id, end_station_name
-- FROM public.tripdata
-- ORDER BY end_station_id;
-- 1318 rows of end_station_id.
-- Stn_id missing: "W Oakdale Ave & N Broadway" and "W Armitage Ave & N Sheffield Ave"

-- Extract above output and create table containing station information
-- CREATE TABLE stn_info_start
-- AS (SELECT DISTINCT start_station_id, start_station_name
-- 		FROM public.tripdata
-- 		ORDER BY start_station_id );

-- CREATE TABLE stn_info_end
-- AS (SELECT DISTINCT end_station_id, end_station_name
-- 		FROM public.tripdata
-- 		ORDER BY end_station_id );

-- SELECT *
-- FROM public.stn_info_start
-- FULL JOIN public.stn_info_end
-- ON start_station_id = end_station_id;
-- INNER: 1378, LEFT: 1384, RIGHT: 1381, FULL: 1387

-- Query stn_info to find which station_ids contain multiple names.
-- SELECT start_station_id,
-- 	COUNT(start_station_id) AS number_of_names
-- FROM public.stn_info_start
-- GROUP BY start_station_id
-- ORDER BY number_of_names DESC;
-- 1288 rows. 32 stations have more than 1 names. "317" has 3 names.

-- Go the other way round, query stn_info to find which station_name contain multiple ids
-- SELECT start_station_name,
--  	COUNT(start_station_name) AS number_of_id
-- FROM public.stn_info_start
-- GROUP BY start_station_name
-- ORDER BY number_of_id DESC;
-- 739 rows. 584 stations have more than 1 ids. So the issue is duplicate ids.

-- Query stn_info to find which station_ids contain multiple names.
-- SELECT end_station_id,
-- 	COUNT(end_station_id) AS number_of_names
-- FROM public.stn_info_end
-- GROUP BY end_station_id
-- ORDER BY number_of_names DESC;
-- 1287 rows. 29 stations have 2 names.

--  SELECT end_station_name,
--  	COUNT(end_station_name) AS number_of_id
--  FROM public.stn_info_end
--  GROUP BY end_station_name
--  ORDER BY number_of_id DESC;
-- 736 rows. 581 stations have more than 1 ids. 

-- ISSUES between station names and IDs 
-- 1. We have missing IDs for stations with names 
-- 2. We have IDs with duplicate station names
-- 3. We have station names having more than 1 ID

-- ISSUE 1
-- match start_station_id for station_name
-- SELECT start_station_id
-- FROM public.stn_info_start
-- WHERE start_station_name = 'S Michigan Ave & E 118th St'; 

-- then change it with known id
-- UPDATE public.tripdata
-- SET start_station_id = '20209'
-- WHERE start_station_name = 'S Michigan Ave & E 118th St' AND start_station_id IS NULL;

-- SELECT * 
-- FROM public.tripdata
-- WHERE start_station_name IS NOT NULL AND start_station_id IS NULL;

-- SELECT end_station_id
-- FROM public.stn_info_end
-- WHERE end_station_name = 'W Armitage Ave & N Sheffield Ave';

-- UPDATE public.tripdata
-- SET end_station_id = '20254.0'
-- WHERE end_station_name = 'W Armitage Ave & N Sheffield Ave' AND end_station_id IS NULL;

-- SELECT * 
-- FROM public.tripdata
-- WHERE end_station_name IS NOT NULL AND end_station_id IS NULL;


-- ISSUE 2
-- Take id 317 as example
-- SELECT COUNT(*) AS occurrence, start_station_name
-- FROM tripdata
-- WHERE start_station_id = '317'
-- GROUP BY start_station_name
-- ORDER BY occurrence DESC;
-- Wood St & Taylor St (Temp), Wood St & Taylor St, Long Ave & Belmont Ave.
-- Googled two intersections: they're 8 miles apart on foot.

-- SELECT *
-- FROM public.tripdata
-- WHERE start_station_name = 'Wood St & Taylor St (Temp)'
-- ORDER BY started_at DESC;
-- So first occurrence of 317 at Long & Belmont is 2021-07-27, all five trips are on e-bike.
-- 1226 trips from Wood & Taylor. Last started_at time: 2020-09-22 09:09:28.
-- As for Wood St & Taylor St (Temp), commenced on 26 SEP 2020, id changed from 317 to 13285 in DEC 2020.
-- 13285 has unique name
-- SCHEME: Assign 13285 to ALL start_station_name = 'Wood St & Taylor St (Temp)'

-- BUT BEFORE THEN, I SHOULD START A SEPARATE LOG ON NAME CLEANING IN START_ID, INCLUDING A SCHEME ON CHANGING ID like this Wood St & Taylor St (Temp)

-- SELECT start_station_id,
-- 	COUNT(start_station_id) AS number_of_names
-- FROM public.stn_info_start
-- GROUP BY start_station_id
-- ORDER BY number_of_names DESC;

-- SELECT COUNT(*) AS occurrence, start_station_name
-- FROM tripdata
-- WHERE start_station_id = 'TA1306000029' 
-- GROUP BY start_station_name
-- ORDER BY occurrence DESC;

-- OCT 11 2021

-- PRINT start_station_ids having more than one names AND their start_station_name.
-- SELECT start_station_id, start_station_name
-- FROM public.stn_info_start
-- WHERE start_station_id IN (SELECT start_station_id
-- FROM public.stn_info_start
-- GROUP BY start_station_id
-- HAVING COUNT(*)> 1
-- ORDER BY COUNT(start_station_id) DESC);

-- THERE ARE SEVERAL SITUATIONS LEADING TO DUPLICATE NAMES
-- 1. Missing name [null]
-- 2. DuSable neighbourhood (id: TA..., LF-005)
-- 3. Temporary stns. (Temp)
-- 4. Vaccination Sites  
-- 5. Street name changed (e.g. id: 19 (Loomis))
-- 6. New stations reusing ids from previous site (notably route change on December 1 2020)
 
-- THERE ARE TWO SYSTEMS OF STATION ID, ONE BEFORE DEC 2020 AND ONE STARTING DEC 2020
-- SELECT DISTINCT start_station_name, start_station_id
-- FROM tripdata
-- WHERE started_at < '2020-12-01 00:00:00'
-- ORDER BY start_station_name;

-- 681 entries

-- SELECT DISTINCT start_station_name, start_station_id
-- FROM tripdata
-- WHERE started_at > '2020-12-01 00:00:00'
-- ORDER BY start_station_name;
-- 731 entries

-- Fix 1: Missing name
-- SELECT ride_id, start_station_name, start_station_id
-- FROM tripdata
-- WHERE start_station_name IS NULL AND start_station_id IS NOT NULL;
-- 1 entry: ride_id 176105D1F8A1216B, start_station_id: 13221

-- SELECT start_station_name, start_station_id
-- FROM stn_info_start
-- WHERE start_station_id = '13221'
-- 2 entries: Wood St & Milwaukee Ave and [null]

-- UPDATE tripdata
-- SET start_station_name = 'Wood St & Milwaukee Ave'
-- WHERE ride_id = '176105D1F8A1216B'
-- Fixed Issue 1 on missing start name

-- Issue 2: DuSable
-- SELECT DISTINCT start_station_id, start_station_name
-- FROM tripdata
-- WHERE start_station_name LIKE '%DuSable%'
-- 8 ids for 7 names: DuSable Museum has dublicate ids 
-- but DuSable Museum is indeed a place name
-- DuSable Lakeshore Dr is the new name of Lakeshore Dr in Honour of J.-B. Point du Sable

-- I want to prove a hypothesis that 
-- Extract above output and create table containing station information
-- CREATE TABLE stn_info_start_before_2020_12
-- AS (SELECT DISTINCT start_station_id, start_station_name
-- 		FROM public.tripdata
--    		WHERE started_at < '2020-12-01 00:00:00'
--    		ORDER BY start_station_id );

-- CREATE TABLE stn_info_start_after_2020_12
-- AS (SELECT DISTINCT start_station_id, start_station_name
-- 		FROM public.tripdata
--    		WHERE started_at > '2020-12-01 00:00:00'
-- 		ORDER BY start_station_id );

-- SELECT 
-- 	stn_info_start_before_2020_12.start_station_id AS old_id, 
-- 	stn_info_start_after_2020_12.start_station_id AS new_id,
-- 	stn_info_start_before_2020_12.start_station_name AS old_name,
-- 	stn_info_start_after_2020_12.start_station_name AS new_name
-- FROM stn_info_start_after_2020_12
-- FULL JOIN stn_info_start_before_2020_12
-- ON stn_info_start_before_2020_12.start_station_name = stn_info_start_after_2020_12.start_station_name
-- ORDER BY new_id;

-- Station names as such aren't for bikers "Lyft Driver Center Private Rack", "WATSON TESTING - DIVVY", "HUBBARD ST BIKE CHECKING (LBS-WH-TEST)", "Base - 2132 W Hubbard Warehouse", "WEST CHI-WATSON", "DIVVY CASSETTE REPAIR MOBILE STATION" 
-- "Lyft Driver Center Private Rack" interesting enough to keep, even if there is just one user

------------------
-- OK, enough of name and id problems studies
-- FOCUS on time usage between two groups: casual/members

-- OCT 21 2021
-- Today is a bad day, all sql queries I wrote were lost
-- Anyway, I split the station info into before and after December 2020
-- Created trip2 table, which contains all data including negative duration. No primary key were set
-- In trip2, duplicates ride_id from December 2020 were removed. negative time data were observed

-- Want to calibrate zero for each bike_type.
-- SELECT *
-- -- SELECT AVG(duration)
-- FROM trip2
-- WHERE duration <= '00:00:00' AND start_station_name = end_station_name AND duration >= '-00:14:03' AND rideable_type = 'docked_bike'
-- ORDER BY duration;
-- Negative time average: classic_bike: -00:00:04.606557, electric_bike: -00:00:00.704545, docked_bike: -00:00:26.011713
-- 26 seconds for docked_bike

-- Now this reflect an issue in tripdata: if time can revert on an average of 26 seconds parking in the same dock
-- then a single trip lasting less than 30s is not impossible at all

-- SELECT AVG(*)
-- FROM trip2
-- WHERE duration < '00:00:00' AND rideable_type = 'docked_bike' AND started_at < '2020-12-01 00:00:00'
-- ORDER BY duration;
-- ONLY 60 entries of t <= 0  docked_bike occurred after December 2020. The rest 7800+ occured before then. 
-- I further studied the duration < 0 for electric_bike. They usually occurred on 2020 OCT 16 or 2020 NOV 01, and is just 36 lines
-- Just ignore and dump all t < 0 entries. If there's no technical log, I can only assume most docks have calibrated time
-- Improvement: repeat cleaning for each monthly csv file. Drawback on this: repetitve and cost more time


-- SELECT AVG(duration)
-- FROM trip2
-- WHERE duration < '00:00:00' 
-- 	AND rideable_type = 'docked_bike' 
-- 	AND started_at > '2021-01-01 00:00:00'
-- 	AND duration > '-01:00:00';

------------------

-- OCT 28 2021
-- SELECT COUNT(*)
-- FROM tripdata
-- WHERE rideable_type = 'docked_bike';

-- Split tripdata 
-- CREATE TABLE tripdata_casual
-- AS (SELECT *
-- 	 FROM tripdata
-- 	 WHERE member_casual = 'casual')

-- export tripdata, tripdata_casual, tripdata_member as total_final.csv, casual_final.csv, member_final.csv
