# Import necessary packages
library(tidyverse)
library(dplyr) # for checking duplicated
library(ggplot2)
library(ggpubr) # this package helps with regression analysis
library(lubridate) # this package turns Tibble data as date time

# Import Data From July 2021
tripdata_202107 = read.csv("raw/202107-divvy-tripdata.csv")
# typeof(tripdata_202107$colname) identifies data type of each column
glimpse(tripdata_202107)

# Converted time data from char into date time using asPOSIXlt
tripdata_202107$started_at= as.POSIXlt(tripdata_202107$started_at)
tripdata_202107$ended_at = as.POSIXlt(tripdata_202107$ended_at)
mutate(tripdata_202107, weekday = weekdays(tripdata_202107$started_at))
tripdata_202107$duration = tripdata_202107$ended_at - tripdata_202107$started_at

# Round off latitude and longitude information to 2 dp
tripdata_202107$start_lat_2dp = round(tripdata_202107$start_lat, digits = 2)
tripdata_202107$start_lng_2dp = round(tripdata_202107$start_lng, digits = 2)
tripdata_202107$end_lat_2dp = round(tripdata_202107$end_lat, digits = 2)
tripdata_202107$end_lng_2dp = round(tripdata_202107$end_lng, digits = 2)

# Another round off scheme, to 3 dp
tripdata_202107$start_lat_3dp = round(tripdata_202107$start_lat, digits = 3)
tripdata_202107$start_lng_3dp = round(tripdata_202107$start_lng, digits = 3)
tripdata_202107$end_lat_3dp = round(tripdata_202107$end_lat, digits = 3)
tripdata_202107$end_lng_3dp = round(tripdata_202107$end_lng, digits = 3)

### TIME data cleaning ###

# Filter data which didn't start any actual trip (duration too short & start_station is end_station)
tripdata_202107 %>% 
  filter(duration <= 120 & start_station_name == end_station_name) # found 16183 rows
tripdata_202107 %>% 
  filter(duration <= 120 & start_station_name == end_station_name & start_station_name !="") #12343
tripdata_202107 %>% 
  filter(duration <= 120 & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp) ) # found 20383 rows
tripdata_202107 %>% 
  filter(duration <= 1200 & start_station_name == end_station_name) # found 60386 rows
tripdata_202107 %>% 
  filter(duration <= 1200 & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp) ) # found 69542 rows
## Conclusion: not fair to say customers didn't start any actual trip just because they return bike at same place.
## Continue: find cut off time to determine non-actual trip
tripdata_202107 %>% 
  filter(duration <= 120) # found 22475 rows. 90.7% return to same place.
tripdata_202107 %>% 
  filter(duration <= 120 & start_station_name !="") # found 17951 rows. 68.8% return to same place
tripdata_202107 %>% 
  filter(duration <= 1200) # found 561798 rows. 12.4% return to same place.
tripdata_202107 %>% 
  filter(duration <= 0) # found 82 rows, many of which have empty end_station_name
tripdata_202107 %>% 
  filter(duration <= 0 & start_station_name == end_station_name) # found 28 rows
tripdata_202107 %>% 
  filter(duration <= 0 & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp) ) # found 81 rows


named_total = count(tripdata_202107 %>% 
  filter(duration <= 50 & start_station_name !=""))
named_round = count(tripdata_202107 %>% 
  filter(duration <= 50 & start_station_name == end_station_name & start_station_name !=""))
named_round/named_total

### Inspired from the above dry runs, create a chart showing proportional of round trips at short interval (from duration <= 0 to <=10 minutes, 10 seconds interval)
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
ggplot(short_round_trips, aes(x = t, y = proportion)) + geom_point() 
## Observation: at t<30, most bikes return at same point (proportion ~90%),
## rapid drop of round trip proportion observed starting around t>50 (hinting that actual trips begin),
## round trip proportion becomes stable (5%) at t>250 onwards

# time limit set to time between <=0 to <=30s. stat_regline_equation: adds regression equation
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(0,30) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

# lm does coefficients analysis for linear regression
lm(short_round_trips$proportion ~ short_round_trips$t, subset = (t<=30))
# Intercept: 0.88507            short_round_trips$t: 0.00206
peak_short_trip = subset(short_round_trips$proportion,short_round_trips$t<=30)
mean(peak_short_trip)

# for the rapid drop range, time between 60 to 110
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(60,110) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=60 & t <=110))
rapid_drop_model = lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=60 & t <=110))
# lm does coefficients analysis for linear regression
# (Intercept): 1.44767           short_round_trips$t: -0.01112
# The formula for rapid drop range is y = -0.01112x + 1.44767 = mx + k
rapid_drop_intercept = coef(rapid_drop_model)["(Intercept)"]
rapid_drop_slope = coef(rapid_drop_model)["short_round_trips$t"]

# for longer trips, time between 300 to 1200
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(300,1200) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=300 & t <=1200))
# lm does coefficients analysis for linear regression
# (Intercept): 9.134e-03           short_round_trips$t: 1.583e-05 
level_off_short_trip = subset(short_round_trips$proportion,short_round_trips$t>=300)
mean(level_off_short_trip) 
# 0.0210056 proportion for round trip after t>625

midpoint = (mean(peak_short_trip)+mean(level_off_short_trip))/2
cutoff_time = floor((midpoint - rapid_drop_intercept)/rapid_drop_slope)
# 87 seconds



### Or use rounded off coordinates to determine cutoff (to suit E-bikes with unnamed starting point)
total_short_vec = c()
round_trip_vec = c()
for(i in t)
{
  if(i == 0){
    # intiate vectors to count total trips for t <= 0
    round_trip = nrow(tripdata_202107 %>% filter(duration <= i & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp)))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = nrow(tripdata_202107 %>% filter(duration <= i))
    total_short_vec = c(total_short_vec, total_short)
  }
  else {
    # append each count of trips at every succeeding 10 seconds interval to vectors
    round_trip = nrow(tripdata_202107 %>% filter((duration > i-1 & duration <= i) & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp)))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = nrow(tripdata_202107 %>% filter(duration > i-1 & duration <= i))
    total_short_vec = c(total_short_vec, total_short)
  }
}

# Determine time-offset for actual trips: do 2 titration fit lines like Chemical experiments, for t<=50 and 90<=t<=250
# Stores all round trip data below 20 minutes as data frame short_round_trips 
short_round_trips = data.frame(t, round_trip_vec, total_short_vec, proportion = round_trip_vec/total_short_vec)

# Plot a graph showing round trip proportion for all bike rides below 20 minutes
ggplot(short_round_trips, aes(x = t, y = proportion)) 
## Observation: at t<60, most bikes return at same point (proportion ~=100%),
## rapid drop of round trip proportion observed starting around t>90 (hinting that actual trips begin),
## round trip proportion becomes stable (5%) at t>625 onwards

# time limit set to time between <=0 to <=60s. stat_regline_equation: adds regression equation
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(0,60) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

# lm does coefficients analysis for linear regression
lm(short_round_trips$proportion ~ short_round_trips$t, subset = (t<=60))
# Intercept: 0.9985049            short_round_trips$t: -0.0002284
peak_short_trip = subset(short_round_trips$proportion,short_round_trips$t<=60)
mean(peak_short_trip)

# for the rapid drop range, time between 90 to 250
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(90,250) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=90 & t <=250))
rapid_drop_model = lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=90 & t <=250))
# lm does coefficients analysis for linear regression
# (Intercept): 1.106323           short_round_trips$t: -0.003622
# The formula for rapid drop range is y = -0.03622x + 1.106323 = mx + k
rapid_drop_intercept = coef(rapid_drop_model)["(Intercept)"]
rapid_drop_slope = coef(rapid_drop_model)["short_round_trips$t"]

# for longer trips, time between 625 to 1200
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(625,1200) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=625 & t <=1200))
# lm does coefficients analysis for linear regression
# (Intercept): 0.0209367           short_round_trips$t: 0.0000201
level_off_short_trip = subset(short_round_trips$proportion,short_round_trips$t>=625)
mean(level_off_short_trip) 
# 0.03932864 proportion for round trip after t>625

midpoint = (mean(peak_short_trip)+mean(level_off_short_trip))/2
cutoff_time = floor((midpoint - rapid_drop_intercept)/rapid_drop_slope)
# 163 seconds

## Observation: if using "titration-fit" method take trips starting at ~40s onwards as actual trips
## But until 60s, round_trip proportion is high at 97.3%. Assume 60 seconds onward is actual trip for now.
## Conclusion: titration-fit didn't work. It's not Chemistry. (Or it works if taking cumulative observations?)

## Then, what are those data with duration <= 60 and end at different points?
short_single_tripdata_202107 = tripdata_202107 %>% filter(duration <= 60 & (start_lat_2dp != end_lat_2dp | start_lng_2dp != end_lng_2dp) & (start_station_id != end_station_id))
# Of 40 entries at short_single_tripdata_202107, most of these entries aren't meaningless data: quite a number belongs to trip between Walsh Park
# I rather want to find how many trips are round_trip below 90 seconds
round_trip_below_90 = tripdata_202107 %>% filter(duration <= 90 & ((start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp) | (start_station_id == end_station_id)))
not_round_trip_below_90 = tripdata_202107 %>% filter(duration <= 90 & ((start_station_id != end_station_id) | (start_lat_2dp != end_lat_2dp | start_lng_2dp != end_lng_2dp) ))

summary(equal_lat_ln_below_90$as.numeric(duration))

## Conclusion: filter all trips equal and below 90 seconds, except those with different starting and ending station id, or those with different 

# create actual_tripdata_202107 using the filter rule above
actual_tripdata_202107 = tripdata_202107 %>% filter(duration > 90 | (duration <= 90 & ((start_station_id != end_station_id) | (start_lat_2dp != end_lat_2dp | start_lng_2dp != end_lng_2dp))
## Wrong query: data with identical lat/lng kept
## 808380 obs

# For data with empty station names, are they really meaningless?
nrow(actual_tripdata_202107 %>% filter(start_station_name == "" | end_station_name == ""))
## Total entries with empty station name: 125519
healthy_empty = actual_tripdata_202107 %>% filter((start_station_name == "" | end_station_name == "") & (start_lat_2dp != end_lat_2dp | start_lng_2dp != end_lng_2dp))
## These 112110 entries having empty station name are actual trips. We need to query them out of useless ones.
actual_tripdata_202107 %>% filter(duration < 10)

# drop all bike depot entries as well
actual_tripdata_202107 = actual_tripdata_202107[!(actual_tripdata_202107$start_station_id == "DIVVY 001" | actual_tripdata_202107$start_station_id == "DIVVY CASSETTE REPAIR MOBILE STATION" | actual_tripdata_202107$start_station_id == "Hubbard Bike-checking (LBS-WH-TEST)")]
# start_id dropped:  obs left
actual_tripdata_202107 = actual_tripdata_202107[!(actual_tripdata_202107$end_station_id == "DIVVY 001" | actual_tripdata_202107$end_station_id == "DIVVY CASSETTE REPAIR MOBILE STATION" | actual_tripdata_202107$end_station_id == "Hubbard Bike-checking (LBS-WH-TEST)")]
# end_id dropped:  obs left

# separate two groups of users: casual and member
casual_tripdata_202107 = actual_tripdata_202107 %>% filter(member_casual == "casual")
member_tripdata_202107 = actual_tripdata_202107 %>% filter(member_casual == "member")

### END of TIME data cleaning ###

### GEO data cleaning ###

# Locate the only trip having start_station_id but not its name 
tripdata_202107 %>% 
  filter(start_station_id != "" & start_station_name == "") # ride_id 176105D1F8A1216B, id 13221

# Store unique input for station id and names
station_info = unique(tripdata_202107[,c('start_station_id','start_station_name')]) # this has 719 counts
station_info %>%  filter(start_station_id == "13221") # Wood St & Milwaukee Ave

# Change value:
tripdata_202107$start_station_name[tripdata_202107$ride_id == "176105D1F8A1216B"] = "Wood St & Milwaukee Ave"
station_info = unique(tripdata_202107[,c('start_station_id','start_station_name')]) # Now only 718 left 
station_info %>%  filter(start_station_id == "13221") # Wood St & Milwaukee Ave



# Find which stations has greatest/least starting
tail(names(sort(table(tripdata_202107$start_station_name))), 10)
# head(names(sort(table(tripdata_202107$start_station_name))), 10)
nrow(filter(tripdata_202107,start_station_name == ""))
nrow(filter(tripdata_202107,start_station_name == "DIVVY CASSETTE REPAIR MOBILE STATION"))

nrow(filter(tripdata_202107, start_station_name == "Streeter Dr & Grand Ave"))

# Find which stations has greatest/least ending
tail(names(sort(table(tripdata_202107$end_station_name))), 10)
head(names(sort(table(tripdata_202107$end_station_name))), 10)
nrow(filter(tripdata_202107,end_station_name == ""))
nrow(filter(tripdata_202107,end_station_name == "S Aberdeen St & W 106th St"))

nrow(filter(tripdata_202107, end_station_name == "Streeter Dr & Grand Ave"))

# Filter data for a geolocation

# to see if starting station has consistent geo data rounded off to 2 dp
tripdata_202107 %>% 
  filter(start_station_name == "Michigan Ave & Washington St") # 4097 rows


# to see where empty starting_station_name come from
tripdata_202107 %>% 
  filter(start_station_name == "" & rideable_type != "electric_bike") 
## Observation: no entries. 
## Conclusion: no missing name from bikes other than electric bikes

# Are all empty end_station_name come from electric bikes as well?
tripdata_202107 %>% 
  filter(end_station_name == "" & rideable_type != "electric_bike") 
## Observation: 1365 entries.
## Conclusion: some empty end_station_name are of classical bike. (Repeat for docked_bike with 0 entries)

# Given a station's lat/lng data, are there other known stations sharing same name?
tripdata_202107 %>% 
  filter(start_lat_2dp == 41.88 & start_lng_2dp == -87.62 & start_station_name != "Michigan Ave & Washington St" & start_station_name != "" ) # 25000+ rows omitted. Conclusion: there exists stations adjacent to each other in terms of coordinate
## Observation: 2dp round off indicates other stations nearby
tripdata_202107 %>% 
  filter(start_lat_3dp == 41.884 & start_lng_3dp == -87.625 & start_station_name != "Michigan Ave & Washington St" & start_station_name != "" ) # 0
## Observation: 3dp round off makes unique search of station name given the lat/lng

# Find if a station name has more than one set of lat/lng data (in 2 decimal place)
tripdata_202107 %>% 
  filter((start_lat_2dp != 41.88 | start_lng_2dp != -87.62) & start_station_name == "Michigan Ave & Washington St") # 2 entries. 
## Observation: if a station has more than one set of lat/lng data, chances are it's rare (2 out of 4097)
# Or in 3 decimal place
tripdata_202107 %>% 
  filter((start_lat_3dp != 41.884 | start_lng_3dp != -87.625) & start_station_name == "Michigan Ave & Washington St")
## Observation: 558 rows of data

## Conclusion: rounding off lat/lng in 3 decimal place is good for cleaning work for identifying station_name given the coordinate.
## Whereas rounding off lat/lng in 2 decimal place is good for matching the total unique entries, given the starting station name.
## Paradox: all fields with empty station_names also has only lat/lng in 2 decimal places, meaning that neither of the above tasks will work.

# For largest known start_station_name
nrow(tripdata_202107 %>% 
  filter(start_station_name == "Streeter Dr & Grand Ave")) # 17013
nrow(tripdata_202107 %>% 
  filter(start_lat_2dp == 41.89 & start_lng_2dp == -87.61 & start_station_name != "Streeter Dr & Grand Ave")) # 8186 entrie
nrow(tripdata_202107 %>% 
       filter((start_lat_2dp != 41.89 | start_lng_2dp != -87.61) & start_station_name == "Streeter Dr & Grand Ave")) # 0 entries

### END of GEO DATA cleaning ###


# no missing field for member_casual, good to go

# Q1 how are their usage time differ
# convert <drtn> type duration into numeric
casual_tripdata_202107$duration = as.numeric(casual_tripdata_202107$duration)
member_tripdata_202107$duration = as.numeric(member_tripdata_202107$duration)

summary(casual_tripdata_202107$duration)
summary(member_tripdata_202107$duration)

member_tripdata_202107 %>% filter(duration < 30)
# which poses me question: how many casual trips are overdue (24hrs>)
nrow(filter(casual_tripdata_202107, duration > 86400)) # 565
# as contrast to member users (who have annual pass)
nrow(filter(member_tripdata_202107, duration > 86400)) # 46

# which poses me question: how many casual trips are over 12 hrs
nrow(filter(casual_tripdata_202107, duration > 43200)) # 932
# as contrast to member users
nrow(filter(member_tripdata_202107, duration > 43200)) # 96

mean_casual = mean(casual_tripdata_202107$duration)
mean_member = mean(member_tripdata_202107$duration)
median_casual = median(casual_tripdata_202107$duration)
median_member = median(member_tripdata_202107$duration)
max_casual = max(casual_tripdata_202107$duration)
max_member = max(member_tripdata_202107$duration)

ggplot(data=casual_tripdata_202107, aes(x=duration)) + geom_histogram(alpha=0.3, binwidth = 60) + xlim(0,4000)

# Q2 how are their trip lengths differ [can't answer the best even remove round-trip]

# Q3 proportion of assistive bike by each group
casual_assistive_202107 = nrow(casual_tripdata_202107 %>% filter(rideable_type == "electric_bike"))
member_assistive_202107 = nrow(member_tripdata_202107 %>% filter(rideable_type == "electric_bike"))

casual_assistive_202107 / nrow(casual_tripdata_202107)
member_assistive_202107 / nrow(member_tripdata_202107)

# Q4 popular
### OBSOLETE 02/01/2022 ###
# Appendix - Out of scope algorithms
# This is for cleaning missing station names
# Definition Effective trips: trips which lasts more than certain minutes MIN (not too short) & starting_stn != ending_stn 
#   1. create [:3] array(station_stat), which will contain starting_(stn, lat, lng)
#   2. Round off starting_(lat,lng) and ending_(lat,lng) as ro_starting_(lat,lng) and ro_ending_(lat,lng)
#   2. if starting_stn != "(empty)" AND ending_stn != "(empty)" 
#     2.1 if starting_stn != ending_stn OR if MIN > 2 minute 
#       2.1.1 count total effective trips AS TRIP
#     2.2 else if starting_stn != "" AND ending_stn == ""
#       2.2.2 if ro_starting_(lat,lng) == ro_ending_(lat,lng)
#         2.2.2.1 ending_(stn, lat, lng) <- starting_(stn, lat, lng)
#         2.2.2.2 array(station_stat) += starting_(stn, lat, lng)
#     2.3 else if starting_stn == "" AND ending_stn != ""
#       2.3.2 if ro_starting_(lat,lng) == ro_ending_(lat,lng)
#         2.3.2.1 ending_(stn, lat, lng) <- ending_(stn, lat, lng)
#         2.3.2.2 array(station_stat) += ending_(stn, lat, lng)
