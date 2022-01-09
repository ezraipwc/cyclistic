# cyclistic

This is a data analytical project in studying the usage behaviour of a bike sharing company between August 2020 and July 2021. These are the links to the [dashboard](https://public.tableau.com/views/Cyclistic_16416492843350/TripLengthContribution?:language=en-US&:display_count=n&:origin=viz_share_link) and [results](https://medium.com/@ezraipwc/summary-on-cyclistic-chapter-1-the-usage-time-difference-between-casuals-and-members-23898515ac86).


## Source of Data
Data available [here[(https://divvy-tripdata.s3.amazonaws.com/index.html). Permission by Motivate International Inc. under this [licence](https://ride.divvybikes.com/data-license-agreement).

## Files and Folders
### Files
* log_data_cleaning.Rmd. This file logs my data work, including ideas, steps and even mistakes. A diary to keep me moving.
* cyclistic_final.R. This file contains the R source code in the final form.
* createquery.sql. An SQL command for creating database suitable for this task. Contains 13 columns like a raw csv file from the source.
* cyclistic_revisit.sql. Records the necessary steps taken in SQL database for cleaning the aggregate. 


###Folders
* img. This is a folder to store screen captures of outputs and graphs.
* raw. This folder stores 12-month csv, from August 2020 to July 2021, extracted from the .zip files downlaoded from the source. The csv file name format is like "yyyymm-divvy-tripdata.csv". E.g. The file for July 2021 is 202107-divvy-tripdata.csv.
* sandbox. More of the previous R and SQL lab works were done before the final results. Although not all of the insights were taken at last, those are many of the studies leading to the final decisions for the scope and tasks of the project .