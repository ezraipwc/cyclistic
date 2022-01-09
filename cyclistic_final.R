# Import necessary packages
library(tidyverse)
library(dplyr) # for checking duplicated # Why must I need to call this when it's a package of tidyverse?
library(ggplot2)
library(ggpubr) # this package helps with regression analysis
library(lubridate) # this package turns Tibble data as date time

# Import monthly data from August 2020 to July 2021
tripdata_monthly = read.csv("raw/202010-divvy-tripdata.csv") # Edit also the name on row 90
# typeof(tripdata_monthly$colname) identifies data type of each column
glimpse(tripdata_monthly) # station_id weird: character after 202012 but int before 

# Converted time data from char into date time using asPOSIXct
tripdata_monthly$started_at= as.POSIXct(tripdata_monthly$started_at)
tripdata_monthly$ended_at = as.POSIXct(tripdata_monthly$ended_at)
tripdata_monthly$duration = tripdata_monthly$ended_at - tripdata_monthly$started_at

## 1. Duplicate data?
tripdata_monthly$ride_id[duplicated(tripdata_monthly$ride_id)]
#character(0)

## 2. Missing fields?
# For character field
sum(tripdata_monthly$end_station_name == '')
# For double field/POSIXct/int (id before Dec 2020)
sum(is.na(tripdata_monthly$end_lng))

tripdata_monthly %>% 
  filter(end_lat == "" & end_station_name == "")
# Before Dec 2020
tripdata_monthly %>% 
  filter(is.na(end_lat) & end_station_name != "") 

## 3. Station Names and IDs
# Store unique input for station id and names
# Find trips with missing id/name to fill in
tripdata_monthly %>% 
  filter(start_station_id != "" & start_station_name == "")
tripdata_monthly %>% 
  filter(start_station_id == "" & start_station_name != "")
tripdata_monthly %>% 
  filter(end_station_id != "" & end_station_name == "")
tripdata_monthly %>% 
  filter(end_station_id == "" & end_station_name != "")

# Before December 2020
tripdata_monthly %>% 
  filter(!is.na(start_station_id) & start_station_name == "")  
tripdata_monthly %>% 
  filter(is.na(start_station_id) & start_station_name != "") # Not fixing data with name but not id in 202011 as no audience care about id, or do it later in SQL
tripdata_monthly %>% 
  filter(!is.na(end_station_id) & end_station_name == "") 
tripdata_monthly %>% 
  filter(is.na(end_station_id) & end_station_name != "") # Not fixing data with name but not id in 202011

# Missing name at 202107
station_info = unique(tripdata_monthly[,c('start_station_id','start_station_name')]) # this has 719 counts for July 2021
station_info %>%  filter(start_station_id == "13221") # Wood St & Milwaukee Ave
# Change value:
tripdata_monthly$start_station_name[tripdata_monthly$ride_id == "176105D1F8A1216B"] = "Wood St & Milwaukee Ave"
# Check new station info
station_info = unique(tripdata_monthly[,c('start_station_id','start_station_name')]) # Now only 718 left

## 4. Create rounded off latitude/longitude data (2 decimal places) for later use
tripdata_monthly$start_lat_2dp = round(tripdata_monthly$start_lat, digits = 2)
tripdata_monthly$start_lng_2dp = round(tripdata_monthly$start_lng, digits = 2)
tripdata_monthly$end_lat_2dp = round(tripdata_monthly$end_lat, digits = 2)
tripdata_monthly$end_lng_2dp = round(tripdata_monthly$end_lng, digits = 2)

## 5. Range of trip duration
min(tripdata_monthly$duration)
tripdata_monthly %>% 
  filter(duration < -100) %>% 
    select(ride_id, started_at, ended_at, duration, start_station_name, end_station_name)

# In Nov 1 2021 (1st Sunday), 27 trips out of 259716 trips have duration less than -1000 seconds due to time change
DST = tripdata_monthly %>% 
  filter(duration <= 0 & started_at >= "2020-11-01 01:00:00" & started_at <= "2020-11-01 02:00:00") %>% 
    select(ride_id, started_at, ended_at, duration, start_station_name, end_station_name)

max(tripdata_monthly$duration)
tripdata_monthly %>% 
  filter(duration >= 86400)
mean(tripdata_monthly$duration)
quantile(tripdata_monthly$duration)

## Export monthly csv for further cleaning in SQL -- OPTIONAL
# Notice the change of filename; to avoid overwrite, manually drag these csv to folder "to_sql" later on
# Also, set row.names to FALSE to skip row indexing
# write.csv(tripdata_monthly, "202008-divvy-tripdata_.csv", row.names = FALSE)


# import purged tripdata for final cleaning
tripdata =read.csv("tripdata_purged_0.csv")
tripdata$started_at= as.POSIXct(tripdata$started_at)
tripdata$ended_at = as.POSIXct(tripdata$ended_at)
tripdata$duration = tripdata$ended_at - tripdata$started_at

tripdata$start_lat_2dp = round(tripdata$start_lat, digits = 2)
tripdata$start_lng_2dp = round(tripdata$start_lng, digits = 2)
tripdata$end_lat_2dp = round(tripdata$end_lat, digits = 2)
tripdata$end_lng_2dp = round(tripdata$end_lng, digits = 2)


### Fixing round trips
### Create a chart showing proportional of round trips at short interval (from duration <= 0 to <=10 minutes, 10 seconds interval)
t = seq(10,1200,10) # create counter for for loop
total_short_vec = c()
round_trip_vec = c()
for(i in t)
{
  if(i == 0){
    # intiate vectors to count total trips for t <= 0
    round_trip = count(tripdata_202107 %>% filter(duration <= i & start_station_name == end_station_name & start_station_name !=""))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = count(tripdata_202107 %>% filter(duration <= i & start_station_name !=""))
    total_short_vec = c(total_short_vec, total_short)
  }
  else {
    # append each count of trips at every succeeding 10 seconds interval to vectors
    round_trip = nrow(tripdata_202107 %>% filter((duration > i-1 & duration <= i) & start_station_name == end_station_name & start_station_name !=""))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = nrow(tripdata_202107 %>% filter((duration > i-1 & duration <= i) & start_station_name !=""))
    total_short_vec = c(total_short_vec, total_short)
  }
}

# Determine time-offset for actual trips: do 2 titration fit lines like Chemical experiments, for t<=50 and 90<=t<=250
# Stores all round trip data below 20 minutes as data frame short_round_trips 
short_round_trips = data.frame(t, round_trip_vec, total_short_vec, proportion = round_trip_vec/total_short_vec)

# Plot a graph showing round trip proportion for all bike rides below 20 minutes
ggplot(short_round_trips, aes(x = t, y = proportion)) +
  geom_point()
## Observation: at t<40, most bikes return at same point (proportion ~=100%),
## rapid drop of round trip proportion observed starting around 60<t<120 (hinting that actual trips begin),
## round trip proportion becomes stable (5%) at t>500 onwards

# time limit set to time between <=0 to <=40s. stat_regline_equation: adds regression equation
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(0,40) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

# lm does coefficients analysis for linear regression
lm(short_round_trips$proportion ~ short_round_trips$t, subset = (t<=40))
# Intercept: 0.9149573            short_round_trips$t: 0.0002667
peak_short_trip = subset(short_round_trips$proportion,short_round_trips$t<=40)
mean(peak_short_trip) #0.9216239

# for the rapid drop range, time between 60 to 120
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(60,120) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=60 & t <=120))
rapid_drop_model = lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=60 & t <=120))
# lm does coefficients analysis for linear regression
# (Intercept): 1.39391           short_round_trips$t: -0.01042
# The formula for rapid drop range is y = -0.01042x + 1.39391 = mx + k
rapid_drop_intercept = coef(rapid_drop_model)["(Intercept)"]
rapid_drop_slope = coef(rapid_drop_model)["short_round_trips$t"]

# for longer trips, time between 500 to 1200
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(500,1200) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=500 & t <=1200))
# lm does coefficients analysis for linear regression
# (Intercept): 1.609e-03           short_round_trips$t: 2.386e-05
level_off_short_trip = subset(short_round_trips$proportion,short_round_trips$t>=500)
mean(level_off_short_trip) 
# 0.02188733 proportion for round trip after t>625

midpoint = (mean(peak_short_trip)+mean(level_off_short_trip))/2
cutoff_time = floor((midpoint - rapid_drop_intercept)/rapid_drop_slope)
# 88 seconds