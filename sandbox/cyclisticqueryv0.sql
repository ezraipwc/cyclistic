-- confirm ride_id unique in this 202107 data
-- SELECT COUNT(DISTINCT ride_id)
-- FROM public.tripdata_202107;

-- 710, 717 entries for start_station_id and start_station_name
-- SELECT COUNT(DISTINCT start_station_id), COUNT(DISTINCT start_station_name)
-- FROM public.tripdata_202107;

-- SELECT start_station_name
-- FROM public.tripdata_202107
-- WHERE start_station_id='WL-012';

-- Found 719 entries, 1 empty, obviously some stations id have duplicate names
-- SELECT DISTINCT start_station_id, start_station_name
-- FROM public.tripdata_202107
-- ORDER BY start_station_id; 

-- Extract above output and create table containing station information
-- CREATE TABLE stn_info
-- AS (SELECT DISTINCT start_station_id, start_station_name
-- 		FROM public.tripdata_202107
-- 		ORDER BY start_station_id ); -- SUCCESS

-- Query stn_info to find which station_ids contain multiple names
-- SELECT start_station_id,
-- 	COUNT(start_station_id) AS number_of_names
-- FROM public.stn_info
-- GROUP BY start_station_id
-- ORDER BY number_of_names DESC;
-- I found id "13221", "LF-005", "TA1306000029", "TA1309000049"
-- "13099", "TA1309000039", "13300", "TA1307000041"

-- Just 8 out of 718 effective names, OK for manual search as below
-- SELECT *
-- FROM public.stn_info
-- WHERE start_station_id='13221';
-- After queries, all duplicates but 13221 and 13099 had DuSable in the name
-- 13099 was a temp station and became permanent later
-- 13221 missed a station name. Suppose to be 'Wood St & Milwaukee Ave'

-- IDENTIFY this missing station name row with id 13321
-- SELECT * 
-- FROM public.tripdata_202107
-- WHERE start_station_id='13221' AND start_station_name IS NULL;
-- ride_id = '176105D1F8A1216B'

-- Clean this line by given start_station_name
-- UPDATE public.tripdata_202107
-- SET start_station_name = 'Wood St & Milwaukee Ave'
-- WHERE ride_id = '176105D1F8A1216B';

-- Go the other way round, query stn_info to find which station_name contain multiple ids
-- SELECT start_station_name,
-- 	COUNT(start_station_name) AS number_of_id
-- FROM public.stn_info
-- GROUP BY start_station_name
-- ORDER BY number_of_id DESC;
-- no duplicates

-- This should tell which known start_station_id is most popular
-- SELECT 
-- 	DISTINCT start_station_id, 
-- 	start_station_name, 
-- 	COUNT(*) AS total_starting
-- FROM public.tripdata_202107
-- GROUP BY start_station_id, start_station_name
-- ORDER BY total_starting DESC
-- LIMIT 30;


--- Some station names are temporary, 6 in start list
-- SELECT DISTINCT start_station_id, start_station_name
-- FROM public.tripdata_202107
-- WHERE start_station_name LIKE '%emp%'
-- ORDER BY start_station_id; 

--- 5 are labelled as vaccination site
-- SELECT DISTINCT start_station_id, start_station_name
-- FROM public.tripdata_202107
-- WHERE start_station_name LIKE '%accinat%'
-- ORDER BY start_station_id; 

-- Search if there exists unidentifiable starting point
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE start_station_id IS NULL AND (start_lat IS NULL OR start_lng IS NULL);
-- 0 entries

-- Search if there exists unidentifiable ending point
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE end_station_id IS NULL AND (end_lat IS NULL OR end_lng IS NULL);
-- 731 entries

-- About time data
-- Search if there exists null data
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE started_at IS NULL OR ended_at IS NULL;
-- no, so good to go

-- create column to find trip duration
-- ALTER TABLE public.tripdata_202107
-- ADD duration interval;

-- UPDATE public.tripdata_202107
-- SET duration = ended_at - started_at;

-- UPDATE public.tripdata_202107
-- SET duration_num = to_char(interval (ended_at - started_at), 'HH24:MI:SS');

-- TODAY is Oct 7 2021
-- ALTER TABLE public.tripdata_202107
-- ADD COLUMN start_lat_2dp numeric, start_lng_2dp numeric, end_lat_2dp numeric, end_lng_2dp numeric;

-- UPDATE public.tripdata_202107
-- SET start_lat_2dp = ROUND(start_lat,2),
-- 	start_lng_2dp = ROUND(start_lng,2),
-- 	end_lat_2dp = ROUND(end_lat,2),
-- 	end_lng_2dp = ROUND(end_lng,2);

-- Following is mean lat/lng value for station detail. 
-- However, this is meaningless
-- One station can have multiple values of lat/lng data, with uncertanties starting at 3dp
-- Many station can have sharing lat_mean/lng_mean at 2dp. Again, paradox of round off for identifying station
-- SELECT 
-- 	DISTINCT start_station_id,
-- 	(AVG(start_lat) + AVG(end_lat))/2 AS lat_mean,
-- 	(AVG(start_lng) + AVG(end_lng))/2 AS lng_mean,
-- 	ROUND((AVG(start_lat) + AVG(end_lat))/2,2) AS lat_mean_2dp,
-- 	ROUND((AVG(start_lng) + AVG(end_lng))/2,2) AS lng_mean_2dp
-- FROM public.tripdata_202107
-- GROUP BY start_station_id;

-- FIND meaningless round trip that are too short
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id != end_station_id AND (start_lat = end_lat AND start_lng = end_lng));
-- Now this is weird. Found 5 trips with different start/end ids but they have exact same coordinates. All electric bikes
-- Found this by an accident. Was to use the start_lat_2dp

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE start_station_id != end_station_id AND (start_lat = end_lat AND start_lng = end_lng);
-- Found total of 15 trips like this. 14 of them electric bikes (1 from DIVVY depot). Something's matter with Electric bike?

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id != end_station_id) AND (start_lat_2dp = end_lat_2dp AND start_lng_2dp = end_lng_2dp);
-- 7224 rows found

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id = end_station_id);
-- 13570 rows found

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id = end_station_id OR (start_lat_2dp = end_lat_2dp AND start_lng_2dp = end_lng_2dp));
-- 27506 rows found

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_lat_2dp IS NULL OR end_lat_2dp IS NULL);
-- 7 rows found

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE end_lat_2dp IS NULL;
-- 731 rows found. These are really useless coz no destinations can be traced. I doubt these are done by our rebalancers. Vandals/clients on accidents are possibilities.

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE end_station_id IS NULL AND end_lat_2dp IS NOT NULL;
-- 92427 rows found, mostly electric_bike. Just some system error doesn't mean they're meaningless

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE start_lat_2dp IS NULL;
-- No untraceable geodata from starting point

-- SELECT * 
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'DIVVY 001' OR end_station_id = 'DIVVY 001';
-- DIVVY 001: 57 rows

-- SELECT * 
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'DIVVY CASSETTE REPAIR MOBILE STATION' OR end_station_id = 'DIVVY CASSETTE REPAIR MOBILE STATION';
-- This has 8 rows

-- SELECT * 
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'Hubbard Bike-checking (LBS-WH-TEST)' OR end_station_id = 'Hubbard Bike-checking (LBS-WH-TEST)';
-- This has 157 rows. Funny enough how some trips starting from repairing depot have member status

-- SELECT start_station_id,
-- 	COUNT(start_station_id) AS number_of_names,
-- 	start_station_name
-- FROM public.stn_info
-- GROUP BY start_station_id
-- ORDER BY number_of_names DESC;

-- Oct 8 2021
-- Today I want to purge all meaningless trip entries from yesterday's tests 

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE end_station_id IS NULL AND end_lat IS NOT NULL AND rideable_type != 'electric_bike';
-- I just wanted to test how many classical bike trips were there that are missing end_station_id but having end_lat/lng

-- 1. Trips that are shorter than 163 seconds with identical start and end id are purged
-- I obtained 163 by finding midpoint between round trip proportion at starting phase and ending phase, and substitute to rapid drop phase
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND start_station_id = end_station_id;
-- 13570 rows
-- DELETE 
-- FROM public.tripdata_202107
-- where duration <= '00:02:43' AND start_station_id = end_station_id;
-- Return: DELETE 13570

-- 2. Trips that are shorter than 163 seconds, missing station_id at either point and start_lat/lng_2dp == end_lat/lng_2dp
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id IS NULL OR end_station_id IS NULL) AND (start_lat_2dp = end_lat_2dp AND start_lng_2dp = end_lng_2dp);
-- 6712 rows out of 130000~ rows of missing stn_id data
-- DELETE
-- FROM public.tripdata_202107
-- WHERE duration <= '00:02:43' AND (start_station_id IS NULL OR end_station_id IS NULL) AND (start_lat_2dp = end_lat_2dp AND start_lng_2dp = end_lng_2dp);
-- Return: DELETE 6712

-- 3. Trips that have untraceable geodata at starting point or ending point
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE start_lat_2dp IS NULL OR end_lat_2dp IS NULL OR start_lng_2dp IS NULL OR end_lng_2dp IS NULL;
-- 731 rows, all have missing end_lat/lng and end_station_id
-- DELETE
-- FROM public.tripdata_202107
-- WHERE start_lat_2dp IS NULL OR end_lat_2dp IS NULL OR start_lng_2dp IS NULL OR end_lng_2dp IS NULL;
-- Return: DELETE 731

-- 4. Trips that start/end from 3 repairing centres
-- DELETE
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'DIVVY 001' OR end_station_id = 'DIVVY 001';
-- Return: DELETE 4. Not 57. I'm shocked. Probably due to some other rows deleted before.

-- DELETE
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'DIVVY CASSETTE REPAIR MOBILE STATION' OR end_station_id = 'DIVVY CASSETTE REPAIR MOBILE STATION';
-- Return: DELETE 8.

-- DELETE
-- FROM public.tripdata_202107
-- WHERE start_station_id = 'Hubbard Bike-checking (LBS-WH-TEST)' OR end_station_id = 'Hubbard Bike-checking (LBS-WH-TEST)';
-- Return: DELETE 155.

-- Check Purging results
-- SELECT *
-- FROM public.tripdata_202107
-- ORDER BY duration DESC;
-- 801230 rows left. Originally 822410.

-- SELECT AVG(duration) AS mean_duration,
-- 	MAX(duration) AS max_duration,
-- 	MIN(duration) AS min_duration
-- FROM public.tripdata_202107;

-- 4 seconds for min and 28 days for max. Check if more purging needed
-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:00:30';
-- Just 14 entries under 30 seconds, 3 of which are known to have different starting/ending points.

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration <= '00:00:60' AND (start_station_id IS NULL OR end_station_id IS NULL);
-- Of 228 entries under 60 seconds, only 34 of them have empty station id (15 percent).

-- SELECT *
-- FROM public.tripdata_202107
-- WHERE duration >= '72:00:00';
-- 94 out of 801230 trips last longer than 3 days. Not much issues.

-- Now find week number of year and weekday
-- SELECT ride_id, 
-- 	started_at, 
-- 	DATE_PART('week', started_at) AS week_number, -- Monday Jan 4 starts the week count ISO 8601
-- 	DATE_PART('dow', started_at) AS weekday_num, -- where 0 is Sunday, 6 is Saturday
-- 	To_Char(started_at, 'Day') AS Weekday
-- FROM public.tripdata_202107
-- LIMIT 100;

-- SELECT to_char(started_at, 'Day'), COUNT(*) AS usage_frequency 
-- FROM public.tripdata_202107
-- GROUP BY To_Char(started_at, 'Day')
-- ORDER BY usage_frequency DESC;
-- Usage frequency by weekday in July 2021 (high to low): Saturday (158k), Friday (133k), Thursday (118k), Sunday (107k), Wednesday (98k), Tuesday (95k), Monday (92k)

-- SELECT DATE_PART('week', started_at) AS week_number, COUNT(*) AS usage_frequency 
-- FROM public.tripdata_202107
-- GROUP BY week_number
-- ORDER BY usage_frequency DESC;
-- Usage frequency by week (not accurate for some intermonth weeks) (high to low): 29 28 30 27 26 (about the same)

-- SELECT DATE(started_at) AS date_of_trip, COUNT(*) AS usage_frequency
-- FROM public.tripdata_202107
-- GROUP BY date_of_trip
-- ORDER BY date_of_trip;
-- Daily trip usage

-- SELECT EXTRACT('HOUR' FROM started_at) AS hour_of_day, COUNT(*)
-- FROM public.tripdata_202107
-- GROUP BY hour_of_day
-- ORDER BY hour_of_day;
-- Usage frequency by hour of day; highest at 15 to 19; lowest at 2 to 5


-- OCT 10 2021

-- SELECT COUNT(start_station_id) AS starting_point_frequency, start_station_name, start_station_id
-- FROM public.tripdata_202107
-- GROUP BY start_station_name, start_station_id 
-- ORDER BY usage_frequency DESC
-- LIMIT 10;
-- Ten most popular starting station of all time

-- SELECT COUNT(end_station_id) AS ending_point_frequency, end_station_name, end_station_id
-- FROM public.tripdata_202107
-- GROUP BY end_station_name, end_station_id 
-- ORDER BY usage_frequency DESC
-- LIMIT 10;
-- Ten most popular end station of all time


-- SELECT 
-- 	CONCAT(start_station_id, '--', end_station_id) AS trip_id,
-- 	COUNT(CONCAT(start_station_id, '--', end_station_id)) AS trip_frequency
-- FROM public.tripdata_202107
-- GROUP BY trip_id
-- ORDER BY trip_frequency DESC
-- LIMIT 11;
-- Find which trip routes have greatest usage of all time, NULL being 1st. Greatest 3: 13022-13022, 13300-13022, 13300-13300


-- SELECT * 
-- FROM public.tripdata_202107
-- WHERE start_station_id = '13022' AND end_station_id = '13022' AND duration <= '00:02:43';
-- Total: 2215, and 2202 have duration longer than 3 minutes, 2109 longer than 5 min, 1981 longer than 10 min

-- SELECT 
-- 	CONCAT('(', start_lat_2dp, ',', start_lng_2dp,')','to','(',end_lat_2dp, ',', end_lng_2dp,')') AS trip_id,
-- 	COUNT(CONCAT('(', start_lat_2dp, ',', start_lng_2dp,')','to','(',end_lat_2dp, ',', end_lng_2dp,')')) AS trip_frequency
-- FROM public.tripdata_202107
-- GROUP BY trip_id
-- ORDER BY trip_frequency DESC
-- LIMIT 11;
-- Using coordinate, the greatest three trips looks like round trip, but might end at different stations

-- SELECT 
-- 	DISTINCT start_station_id
-- FROM public.tripdata_202107
-- WHERE start_lat_2dp = '41.88' AND start_lng_2dp = '-87.62';
-- This coordinate has 11 distinct stations

-- SELECT COUNT(*)
-- FROM public.tripdata_202107
-- WHERE DATE_PART('dow', started_at) != 0 AND DATE_PART('dow', started_at) != 6;
-- 536416 trips in weekday / 801230 = 66.95%

-- SELECT COUNT(*)
-- FROM public.tripdata_202107
-- WHERE DATE_PART('dow', started_at) = 0 OR DATE_PART('dow', started_at) = 6;
-- 264814 trips in weekend = 33.05%

-- NOW WE CAN REDO ALL ANALYSIS ABOVE USING rideable_type filter

-- SELECT AVG(duration) AS mean_duration,
-- 	MAX(duration) AS max_duration,
-- 	MIN(duration) AS min_duration
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike';
-- 00:18:37.73, 08:00:31, 00:00:04

-- SELECT AVG(duration) AS mean_duration,
-- 	MAX(duration) AS max_duration,
-- 	MIN(duration) AS min_duration
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike';
-- 00:26:03.50, 28 days 22:05:31, 00:00:30

-- SELECT to_char(started_at, 'Day'), COUNT(*) AS usage_frequency 
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike'
-- GROUP BY To_Char(started_at, 'Day')
-- ORDER BY usage_frequency DESC;
-- Ebike: FRIDAY(45k) Sat(44k) Thur Tue(32k) Wed Sun Mon(28k)

-- SELECT to_char(started_at, 'Day'), COUNT(*) AS usage_frequency 
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike'
-- GROUP BY To_Char(started_at, 'Day')
-- ORDER BY usage_frequency DESC;
-- Regular bike: SATURDAY(115k) Fri(88k) Thu Sun(77k) Wed Mon Tue(63k)
-- CONCLUSION: Ebike is most popular on Friday, while Regular bike is most popular on Saturday

-- SELECT DATE_PART('week', started_at) AS week_number, COUNT(*) AS usage_frequency 
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike'
-- GROUP BY week_number
-- ORDER BY usage_frequency DESC;
-- More or less the same for week

-- SELECT EXTRACT('HOUR' FROM started_at) AS hour_of_day, COUNT(*)
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike'
-- GROUP BY hour_of_day
-- ORDER BY hour_of_day;
-- More or less the same for hour_of_day

-- SELECT COUNT(start_station_id) AS starting_point_frequency, start_station_name, start_station_id
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike'
-- GROUP BY start_station_name, start_station_id 
-- ORDER BY starting_point_frequency DESC
-- LIMIT 10;
-- Conclusion: Ten most popular starting station of all time for E-bike is vastly different from classical bike

-- SELECT COUNT(end_station_id) AS ending_point_frequency, end_station_name, end_station_id
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike'
-- GROUP BY end_station_name, end_station_id 
-- ORDER BY ending_point_frequency DESC
-- LIMIT 10;
-- Ten most popular end station of all time

-- SELECT COUNT(*)
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike' AND (DATE_PART('dow', started_at) = 0 OR DATE_PART('dow', started_at) = 6);
-- 174915 weekday (70.49%), 73217 (29.5%) weekend. Total 248132

-- SELECT COUNT(*)
-- FROM public.tripdata_202107
-- WHERE rideable_type != 'electric_bike' AND (DATE_PART('dow', started_at) = 0 OR DATE_PART('dow', started_at) = 6);
-- 361501 weekday (65.36%), 191597 weekend (34.64%). Total 553098


-- SELECT 
-- 	CONCAT(start_station_id, '--', end_station_id) AS trip_id,
-- 	COUNT(CONCAT(start_station_id, '--', end_station_id)) AS trip_frequency
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike'
-- GROUP BY trip_id
-- ORDER BY trip_frequency DESC
-- LIMIT 11;
-- DIRTY Data for ebike since they tend to miss station id, perhaps coordinates can help

-- SELECT 
-- 	CONCAT('(', start_lat_2dp, ',', start_lng_2dp,')','to','(',end_lat_2dp, ',', end_lng_2dp,')') AS trip_id,
-- 	COUNT(CONCAT('(', start_lat_2dp, ',', start_lng_2dp,')','to','(',end_lat_2dp, ',', end_lng_2dp,')')) AS trip_frequency
-- FROM public.tripdata_202107
-- WHERE rideable_type = 'electric_bike'
-- GROUP BY trip_id
-- ORDER BY trip_frequency DESC
-- LIMIT 11;
-- Funny enough that first 5, 7th, 11th look like round trip but it is reminded that 0.01 uncertainty is ~1km on map

