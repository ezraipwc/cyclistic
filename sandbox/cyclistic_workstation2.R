# Import necessary packages
library(tidyverse)
library(ggplot2)
library(ggpubr) # this package helps with regression analysis
library(lubridate) # this package turns Tibble data as date time

# Import tripdata.csv containing data from 202008 to 202107
tripdata = read.csv("tripdata.csv")
glimpse(tripdata)

# Converted time data from char into date time using asPOSIXlt
tripdata$started_at= as.POSIXlt(tripdata$started_at)
tripdata$ended_at = as.POSIXlt(tripdata$ended_at)
mutate(tripdata, weekday = weekdays(tripdata$started_at))
tripdata$duration = tripdata$ended_at - tripdata$started_at

### TIME data cleaning ###
t = seq(0,1200,10) # create counter for for loop
total_short_vec = c()
round_trip_vec = c()
for(i in t)
{
  if(i == 0){
    # intiate vectors to count total trips for t <= 0
    round_trip = nrow(tripdata %>% filter(duration <= i & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp)))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = nrow(tripdata %>% filter(duration <= i))
    total_short_vec = c(total_short_vec, total_short)
  }
  else {
    # append each count of trips at every succeeding 10 seconds interval to vectors
    round_trip = nrow(tripdata %>% filter((duration > i-1 & duration <= i) & (start_lat_2dp == end_lat_2dp & start_lng_2dp == end_lng_2dp)))
    round_trip_vec = c(round_trip_vec, round_trip)
    total_short = nrow(tripdata %>% filter(duration > i-1 & duration <= i))
    total_short_vec = c(total_short_vec, total_short)
  }
}

# Stores all round trip data below 20 minutes as data frame short_round_trips 
short_round_trips = data.frame(t, round_trip_vec, total_short_vec, proportion = round_trip_vec/total_short_vec)
# Plot a graph showing round trip proportion for all bike rides below 20 minutes
ggplot(short_round_trips, aes(x = t, y = proportion)) + geom_point() 

# time limit set to time between <=0 to <=30s. stat_regline_equation: adds regression equation
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(0,30) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

# lm does coefficients analysis for linear regression
lm(short_round_trips$proportion ~ short_round_trips$t, subset = (t<=30))
# Intercept: 0.9934300            short_round_trips$t: 0.0000307
peak_short_trip = subset(short_round_trips$proportion,short_round_trips$t<=30)
mean(na.omit(peak_short_trip)) #around 1

# for the rapid drop range, time between 90 to 250
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(90,250) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=90 & t <=250))
rapid_drop_model = lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=90 & t <=250))
# lm does coefficients analysis for linear regression
# (Intercept): 1.08919           short_round_trips$t: -0.00357
# The formula for rapid drop range is y = -0.03622x + 1.106323 = mx + k
rapid_drop_intercept = coef(rapid_drop_model)["(Intercept)"]
rapid_drop_slope = coef(rapid_drop_model)["short_round_trips$t"]

# for longer trips, time between 625 to 1200
ggplot(short_round_trips, aes(x = t, y = proportion)) + 
  geom_point() + xlim(625,1200) + geom_smooth(method="lm", se = FALSE) + stat_regline_equation(label.y = 0.875, aes(label = ..eq.label..))

lm(short_round_trips$proportion ~ short_round_trips$t, subset =(t>=625 & t <=1200))
# lm does coefficients analysis for linear regression
# (Intercept): 1.236e-02           short_round_trips$t: 3.835e-05
level_off_short_trip = subset(short_round_trips$proportion,short_round_trips$t>=625)
mean(level_off_short_trip) 
# 0.04744852 proportion for round trip after t>625

midpoint = (mean(na.omit(peak_short_trip))+mean(level_off_short_trip))/2
cutoff_time = floor((midpoint - rapid_drop_intercept)/rapid_drop_slope)
# 159 seconds

### Re-import tripdata after all cleaning
tripdata = read.csv("total_final.csv")

# Converted time data from char into date time using asPOSIXlt
tripdata$started_at= as.POSIXlt(tripdata$started_at)
tripdata$ended_at = as.POSIXlt(tripdata$ended_at)
tripdata = tripdata %>% 
  mutate(weekday = weekdays(tripdata$started_at))
tripdata$duration = tripdata$ended_at - tripdata$started_at
tripdata$duration = as.numeric(tripdata)

casual_tripdata = tripdata %>%
  filter(member_casual == "casual")
member_tripdata = tripdata %>% 
  filter(member_casual == "member")

### Convert duration into numeric
casual_tripdata$duration = as.numeric(casual_tripdata$duration)
member_tripdata$duration = as.numeric(member_tripdata$duration)

## Find quartile distribution of duration
quantile(tripdata$duration)
quantile(casual_tripdata$duration)
quantile(member_tripdata$duration)

## Find usage by day
count(tripdata, weekday, sort = TRUE)
count(casual_tripdata, weekday, sort = TRUE)
count(member_tripdata, weekday, sort = TRUE)
