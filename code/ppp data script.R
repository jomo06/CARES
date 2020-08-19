# R version used with this script: 4.0.2
# RStudio used with this script: 1.3.1056
# packages used with this script last updated: July 24th 2020
# PPP data downloaded 642pm BST, July 22nd 2020 from: https://sba.app.box.com/s/tvb0v5i57oa8gc6b5dcm9cyw7y2ms6pp 


# Setup -------------------------------------------------------------------

# rm(list=ls()) # clean up workspace before beginning

# load all needed libraries upfront
library(tidyverse) # used for merging the various CSV files and manipulating the data
library(sf)

# Read --------------------------------------------------------------------

# the below code will work if your current working directory is CARES/code/
reldir <- "../data/All Data By State/"

#reldir<-"C:/Users/rcarder/Documents/dev/All Data by State/All Data by State"

dat_files <- list.files(reldir, full.names = T, recursive = T, pattern = ".*.csv") # scan through all directories and subdirectories for all CSVs

# read in each CSV, all as character values, to allow for a clean import with no initial manipulation
# for each file, attached the name of the data source file
adbs <- map_df(dat_files, ~read_csv(.x, col_types = cols(.default = "c")) %>%
                              mutate(source_file = str_remove_all(.x, "data/20200722/All Data by State/All Data by State/"))
                           )

# Clean -------------------------------------------------------------------


### Create unified Loan Amount / Loan Range cuts
adbs <- adbs %>% 
  mutate(LoanRange_Unified = case_when(!is.na(LoanRange) ~ LoanRange,
                                       is.na(LoanRange) & as.numeric(LoanAmount) > 125000 & as.numeric(LoanAmount) <= 150000 ~ "f $125,000 - $150,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) > 100000 & as.numeric(LoanAmount) <= 125000 ~ "g $100,000 - $125,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >  75000 & as.numeric(LoanAmount) <= 100000 ~ "h  $75,000 - $100,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >  50000 & as.numeric(LoanAmount) <=  75000 ~ "i  $50,000 -  $75,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >  25000 & as.numeric(LoanAmount) <=  50000 ~ "j  $25,000 -  $50,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >   1000 & as.numeric(LoanAmount) <=  25000 ~ "k   $1,000 -  $25,000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >    100 & as.numeric(LoanAmount) <=   1000 ~ "l     $100 -    $1000",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >     10 & as.numeric(LoanAmount) <=    100 ~ "m      $10 -     $100",
                                       is.na(LoanRange) & as.numeric(LoanAmount) >      0 & as.numeric(LoanAmount) <=     10 ~ "n           Up to $10",
                                       is.na(LoanRange) & as.numeric(LoanAmount) ==     0                                    ~ "o                Zero",
                                       is.na(LoanRange) & as.numeric(LoanAmount) <      0                                    ~ "p      Less than Zero",
                                       TRUE ~ "Unknown"))

# create for each loan that has no specific LoanAmount a numeric max/min value, to allow for quick computation of max/min totals
# for entries with specific LoanAmount values, use those as they are

adbs$LoanAmount<-as.numeric(adbs$LoanAmount)

#Low, Mid, Max values for large loans value range
adbs <- adbs %>% 
  mutate(LoanAmount_Estimate_Low = case_when(!is.na(LoanAmount) ~ LoanAmount,
                                         is.na(LoanAmount) & LoanRange=="a $5-10 million" ~ 5000000,
                                         is.na(LoanAmount) & LoanRange=="b $2-5 million" ~ 2000000,
                                         is.na(LoanAmount) & LoanRange=="c $1-2 million" ~ 1000000,
                                         is.na(LoanAmount) & LoanRange=="d $350,000-1 million" ~ 350000,
                                         is.na(LoanAmount) & LoanRange=="e $150,000-350,000" ~ 150000),
         LoanAmount_Estimate_Mid = case_when(!is.na(LoanAmount) ~ LoanAmount,
                                             is.na(LoanAmount) & LoanRange=="a $5-10 million" ~ 7500000,
                                             is.na(LoanAmount) & LoanRange=="b $2-5 million" ~ 3500000,
                                             is.na(LoanAmount) & LoanRange=="c $1-2 million" ~ 1500000,
                                             is.na(LoanAmount) & LoanRange=="d $350,000-1 million" ~ 675000,
                                             is.na(LoanAmount) & LoanRange=="e $150,000-350,000" ~ 250000),
         LoanAmount_Estimate_High = case_when(!is.na(LoanAmount) ~ LoanAmount,
                                             is.na(LoanAmount) & LoanRange=="a $5-10 million" ~ 10000000,
                                             is.na(LoanAmount) & LoanRange=="b $2-5 million" ~ 5000000,
                                             is.na(LoanAmount) & LoanRange=="c $1-2 million" ~ 2000000,
                                             is.na(LoanAmount) & LoanRange=="d $350,000-1 million" ~ 1000000,
                                             is.na(LoanAmount) & LoanRange=="e $150,000-350,000" ~ 350000))

n_distinct(adbs$Zip)


### Create Jobs Retained cuts
adbs <- adbs %>%
  mutate(JobsRetained_Grouped = case_when(as.numeric(JobsRetained) > 400 & as.numeric(JobsRetained) <= 500 ~ "a 400 - 500",
                                          as.numeric(JobsRetained) > 300 & as.numeric(JobsRetained) <= 400 ~ "b 300 - 400",
                                          as.numeric(JobsRetained) > 200 & as.numeric(JobsRetained) <= 300 ~ "c 200 - 300",
                                          as.numeric(JobsRetained) > 100 & as.numeric(JobsRetained) <= 200 ~ "d 100 - 200",
                                          as.numeric(JobsRetained) >  50 & as.numeric(JobsRetained) <= 100 ~ "e  50 - 100",
                                          as.numeric(JobsRetained) >  25 & as.numeric(JobsRetained) <=  50 ~ "f  25 -  50",
                                          as.numeric(JobsRetained) >  10 & as.numeric(JobsRetained) <=  25 ~ "g  10 -  25",
                                          as.numeric(JobsRetained) >   5 & as.numeric(JobsRetained) <=  10 ~ "h   5 -  10",
                                          as.numeric(JobsRetained) >   1 & as.numeric(JobsRetained) <=   5 ~ "i   2 -   5",
                                          as.numeric(JobsRetained) >   0 & as.numeric(JobsRetained) <=   1 ~ "j         1",
                                          as.numeric(JobsRetained) ==     0                                ~ "k      Zero",
                                          as.numeric(JobsRetained) <      0                                ~ "l  Negative",
                                          is.na(JobsRetained) ~ NA_character_,
                                          TRUE ~ "Unknown"))   


# Example of State Specific (Florida) Subset ------------------------------

# adbs_fl <- adbs[adbs$State=="FL",]
# 
# # Write to CSV
# write.csv(adbs_fl,
#           "data/adbs_fl.csv")



##Creating Summary Sets Using mid range estimate, plus join ZCTAs to ZIP level tables

setwd("C:/Users/rcarder/Documents/dev/CARES/data/Lookup Tables")
ZCTAlookup<-read.csv("zip_to_zcta_2019.csv")%>%
  mutate(ZIP_CODE=str_pad(as.character(ZIP_CODE), width=5, side="left", pad="0"))

#By ZIP only

ZipAmount<-adbs%>%
  dplyr::select(4:8,20:22)%>%  #make smaller before grouping
  group_by(Zip,State)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))%>%
  left_join(ZCTAlookup, by=c("Zip"="ZIP_CODE"))

StateIndustryAmount<-adbs%>%
  dplyr::select(4:8,20:22)%>%  #make smaller before grouping
  group_by(State, NAICSCode)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))

ZipIndustryAmount<-adbs%>%
  dplyr::select(4:8,20:22)%>%  #make smaller before grouping
  group_by(Zip,State, NAICSCode)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))%>%
  left_join(ZCTAlookup, by=c("Zip"="ZIP_CODE"))

##Join ZCTAs






# Cleanup -----------------------------------------------------------------

rm(dat_files, 
   reldir)


