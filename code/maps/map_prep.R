library(tidyverse)
library(ggplot2)
library(readxl)
library(tigris)
library(sf)
library(sp)
library(rgeos)

setwd("C:/Users/kathy/Documents/github/CARES")

############################
# read in data
############################
# create base ppp dataset
#source("bin/ppp_data_merge.R")

# read in lookup tables
zip2zcta <- read_csv("data/Lookup Tables/zip_to_zcta_2019.csv") %>%
    mutate(ZIP_CODE=str_pad(as.character(ZIP_CODE), width=5, side="left", pad="0"))

zip2tract <- read_excel("data/Lookup Tables/ZIP_TRACT_032020.xlsx",
                        col_types=c("text", "text", "numeric", "numeric", "numeric", "numeric"))

zip2county <- read_excel("data/Lookup Tables/ZIP_COUNTY_032020.xlsx",
                         col_types=c("text", "text", "numeric", "numeric", "numeric", "numeric"))

zip2cbsa <- read_excel("data/Lookup Tables/ZIP_CBSA_032020.xlsx",
                       col_types=c("text", "text", "numeric", "numeric", "numeric", "numeric"))

# read in demographic data
countydemo <- read_csv("data/demographics/countyDemographics.csv") 
statedemo <- read_csv("data/demographics/stateDemographics.csv")
cddemo <- read_csv("data/demographics/congressional districtDemographics.csv")

# download census geographies
states <- states()
counties <- counties(cb=TRUE)
cbsas <- core_based_statistical_areas(cb=TRUE)
cds <- congressional_districts(cb=TRUE)

counties$INTPTLON <- gCentroid(counties, byid = TRUE)$x
counties$INTPTLAT <- gCentroid(counties, byid = TRUE)$y

cds$INTPTLON <- gCentroid(cds, byid = TRUE)$x
cds$INTPTLAT <- gCentroid(cds, byid = TRUE)$y
############################
# clean up base ppp dataset
############################
# add point estimate for each loan
adbs$LoanAmount<-as.numeric(adbs$LoanAmount)
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
                                                is.na(LoanAmount) & LoanRange=="e $150,000-350,000" ~ 350000),
           LoanAmount_gt150k = (LoanAmount_Estimate_Low > 150000)*1)

# get congressional district code
state_fips <- states@data[,c('GEOID', 'STUSPS')] %>% 
    rename('state_fips' = 'GEOID',
           'state_name' = 'STUSPS') %>% 
    distinct()

adbs <- adbs %>% 
    mutate(state_name = str_sub(CD, 1, 2),
           cd_num = str_sub(CD, -2, -1)) %>% 
    left_join(state_fips, by="state_name") %>% 
    mutate(cd_fips = paste0(state_fips, cd_num))

############################
# aggregate loan amounts to various geographies
# and join to demographic files
############################
# zipcode
adbs_zip <- adbs %>% 
    group_by(Zip) %>% 
    summarise(LoanAmt_Est_All = sum(LoanAmount_Estimate_Mid),
              LoanAmt_Est_lt150k = sum(LoanAmount_Estimate_Mid*(1-LoanAmount_gt150k)),
              LoanCnt_All = n(),
              LoanCnt_lt150k = sum(1-LoanAmount_gt150k),
              LoanCnt_gt150k = sum(LoanAmount_gt150k)) %>% 
    rename('GEOID' = 'Zip') %>% 
    mutate('GEOID_TYPE' = 'Zip') %>% 
    select(GEOID, GEOID_TYPE, everything())

# county
adbs_county <- adbs_zip %>% 
    left_join(zip2county, by = c("GEOID" = "ZIP")) %>% 
    group_by(COUNTY) %>% 
    summarise(LoanAmt_Est_All = sum(LoanAmt_Est_All*BUS_RATIO, na.rm=T),
              LoanAmt_Est_lt150k = sum(LoanAmt_Est_lt150k*BUS_RATIO, na.rm=T),
              LoanCnt_All = sum(LoanCnt_All*BUS_RATIO, na.rm=T),
              LoanCnt_lt150k = sum(LoanCnt_lt150k*BUS_RATIO, na.rm=T),
              LoanCnt_gt150k = sum(LoanCnt_gt150k*BUS_RATIO, na.rm=T)) %>% 
    rename('GEOID' = 'COUNTY') %>% 
    mutate('GEOID_TYPE' = 'County') %>% 
    select(GEOID, GEOID_TYPE, everything()) %>% 
    right_join(countydemo, by="GEOID")

sum(adbs_county$LoanAmt_Est_All, na.rm = T)/sum(adbs_zip$LoanAmt_Est_All, na.rm = T) # 99.7% loans are mapped to counties

# state
adbs_state <- adbs_county %>% 
    mutate(STATE = str_sub(GEOID, 1, 2)) %>% 
    group_by(STATE) %>% 
    summarise(LoanAmt_Est_All = sum(LoanAmt_Est_All),
              LoanAmt_Est_lt150k = sum(LoanAmt_Est_lt150k),
              LoanCnt_All = sum(LoanCnt_All),
              LoanCnt_lt150k = sum(LoanCnt_lt150k),
              LoanCnt_gt150k = sum(LoanCnt_gt150k)) %>% 
    rename('GEOID' = 'STATE') %>% 
    mutate('GEOID_TYPE' = 'State') %>% 
    select(GEOID, GEOID_TYPE, everything()) %>% 
    right_join(statedemo, by="GEOID")

# congressional district
adbs_cd <- adbs %>% 
    group_by(cd_fips) %>% 
    summarise(LoanAmt_Est_All = sum(LoanAmount_Estimate_Mid),
              LoanAmt_Est_lt150k = sum(LoanAmount_Estimate_Mid*(1-LoanAmount_gt150k)),
              LoanCnt_All = n(),
              LoanCnt_lt150k = sum(1-LoanAmount_gt150k),
              LoanCnt_gt150k = sum(LoanAmount_gt150k)) %>% 
    rename('GEOID' = 'cd_fips') %>% 
    mutate('GEOID_TYPE' = 'Congressional District') %>% 
    select(GEOID, GEOID_TYPE, everything()) %>% 
    right_join(cddemo, by="GEOID")

############################
# combine & export
############################
adbs_all_geos <- rbind(adbs_county, 
                       adbs_state, 
                       adbs_cd)

write_csv(adbs_all_geos, "data/tidy_data/adbs_all_geos.csv")
write_csv(adbs_county, "data/tidy_data/adbs_county.csv")
write_csv(adbs_state, "data/tidy_data/adbs_state.csv")
write_csv(adbs_cd, "data/tidy_data/adbs_congressional_district.csv")
