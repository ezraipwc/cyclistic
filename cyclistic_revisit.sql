-- raw csv files from cyclistic imported descendingly FROM JULY 2021 TO AUGUST 2020
-- import error occurred in November 2020

-- delete negative duration data
-- DELETE 
-- FROM public.tripdata
-- WHERE ended_at <= started_at;
-- OUTPUT: DELETE 704

-- delete again after import
-- DELETE 
-- FROM public.tripdata
-- WHERE ended_at <= started_at;
-- OUTPUT: DELETE 7915

-- rows with untraceable destination (missing end_lat/lng) are purged
-- DELETE
-- FROM public.tripdata
-- WHERE end_lat IS NULL OR end_lng IS NULL
-- DELETE 5202

-- DELETE
-- FROM public.tripdata
-- WHERE start_station_name = 'WATSON TESTING - DIVVY' 
-- OR end_station_name = 'WATSON TESTING - DIVVY'
-- DELETE 2867

-- DELETE
-- FROM public.tripdata
-- WHERE start_station_name = 'HUBBARD ST BIKE CHECKING (LBS-WH-TEST)' 
-- OR end_station_name = 'HUBBARD ST BIKE CHECKING (LBS-WH-TEST)'
-- DELETE 288

-- DELETE
-- FROM public.tripdata
-- WHERE start_station_name = 'Base - 2132 W Hubbard Warehouse' 
-- OR end_station_name = 'Base - 2132 W Hubbard Warehouse'
-- DELETE 0

-- DELETE
-- FROM public.tripdata
-- WHERE start_station_name = 'WEST CHI-WATSON' OR end_station_name = 'WEST CHI-WATSON'
-- DELETE 83

-- DELETE
-- FROM public.tripdata
-- WHERE start_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION' OR end_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION'
-- DELETE 8

-- SELECT COUNT(*)
-- FROM tripdata;
-- 4714014 entries

-- EXPORT the file as tripdata_purged_0.csv

-- Now add a column for duration
-- ALTER TABLE public.tripdata
-- ADD duration interval;

-- Evaluate duration 
-- UPDATE public.tripdata
-- SET duration = ended_at - started_at;
-- UPDATE 4714014.

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
-- 

-- Delete Round trip less than 88 seconds
-- DELETE
-- FROM tripdata
-- WHERE start_station_name = end_station_name AND duration < '00:01:28';
-- DELETE 61245

-- Delete Round trip less than 88 seconds
-- DELETE
-- FROM tripdata
-- WHERE start_lat_2dp = end_lat_2dp AND start_lng_2dp = end_lng_2dp AND duration < '00:01:28';
-- DELETE 24823

-- SELECT COUNT(*)
-- FROM tripdata;
-- 4627946 entries

-- EXPORT this as tripdata_cleaned.csv

