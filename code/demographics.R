---
title: "Gather ACS Data for NPF CARES Project"
author: "Rich Carder"
date: "July 30, 2020"
#---
  

library(tidycensus)
library(sf)
library(tidyverse)
library(jsonlite)
library(geojsonio)

#This script extracts ACS 5-year estimates at the ZIP level group using the tidycensus package. To run tidycensus, you first need
#to set up a Census API key and run census_api_key(). Set working directory
#to where you want output files to save, or use the collect_acs_data function 
#to set a different outpath.
#


##Change to your wd where repo is cloned to pull in any auxiliary data that may be useful
setwd("C:/Users/rcarder/Documents/dev/CARES/data")
cities<-read.csv("cities.csv") ##to help provide context to state maps


census_api_key('b2e47f1f1e9c7115a34a02992c149628712ecff8', install=TRUE, overwrite = TRUE)


##To explore fields available in the ACS
acs_table <- load_variables(2018, "acs5", cache = TRUE)


###Choose Geography Options###

##Geographic Level (county, state, tract, zcta (ZIP), block group, congressional district, public use microdata area)
geoLevel='congressional district'  ##Zip Codes with approximate tabulation areas (ZIP codes are not actual polygons)

##Specific State? Leaving NULL will pull whole US. For anything more granular than census tracts, specify a state.
state=NULL

##Also pull in geometry polygons for mapping? Takes much longer, so leave FALSE if just the data is needed.
pullGeography=FALSE

##Now run lines 49-118


##Language - note for most geographies language data is missing for years past 2015 (its there for state up to 2018)
language <- get_acs(geography = geoLevel,
                    variables = c('B16001_001','B16001_002','B16001_003','B16001_004','B16001_005',
                                  'B16001_075','B16001_006'),
                    year = 2015, state = NULL, geometry = pullGeography) %>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    tot_population_language=B16001_001,
    only_english_pct = B16001_002/tot_population_language,
    any_other_than_english_pct = 1-(B16001_002/tot_population_language),
    spanish_pct=B16001_003/tot_population_language,
    french_pct=B16001_006/tot_population_language,  #removed later
    chinese_pct=B16001_075/tot_population_language, #removed later
    spanish_with_english_pct=B16001_004/tot_population_language, #removed later
    spanish_no_english_pct=B16001_005/tot_population_language) %>% #removed later
  dplyr::select(-c(NAME))

##Age - Binned into 4 pretty broad categories
age <- get_acs(geography = geoLevel,
               variables = c(sapply(seq(1,49,1), function(v) return(paste("B01001_",str_pad(v,3,pad ="0"),sep="")))),
               year = 2018, state = NULL, geometry = FALSE)%>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    denom = B01001_001,
    age_under18_ma = dplyr::select(., B01001_003:B01001_006) %>% rowSums(na.rm = TRUE),
    age_18_34_ma = dplyr::select(., B01001_007:B01001_012) %>% rowSums(na.rm = TRUE),
    age_35_64_ma = dplyr::select(., B01001_013:B01001_019) %>% rowSums(na.rm = TRUE),
    age_over65_ma = dplyr::select(., B01001_020:B01001_025) %>% rowSums(na.rm = TRUE),
    age_under18_fe = dplyr::select(., B01001_027:B01001_030) %>% rowSums(na.rm = TRUE),
    age_18_34_fe = dplyr::select(., B01001_031:B01001_036) %>% rowSums(na.rm = TRUE),
    age_35_64_fe = dplyr::select(., B01001_037:B01001_043) %>% rowSums(na.rm = TRUE),
    age_over65_fe = dplyr::select(., B01001_044:B01001_049) %>% rowSums(na.rm = TRUE),
    age_pct_under18 = (age_under18_ma + age_under18_fe)/denom,
    age_pct_18_34 = (age_18_34_ma + age_18_34_fe)/denom,
    age_pct_35_64 = (age_35_64_ma + age_35_64_fe)/denom,
    age_pct_over65 = (age_over65_ma + age_over65_fe)/denom
  ) %>%
  dplyr::select(-starts_with("B0"))%>%dplyr::select(-ends_with("_ma")) %>% dplyr::select(-ends_with("_fe")) %>% dplyr::select(-denom)


##Race and Income; joins langauge and age at end
assign(paste(geoLevel,"Demographics",sep=''),get_acs(geography = geoLevel,
                variables = c(sapply(seq(1,10,1), function(v) return(paste("B02001_",str_pad(v,3,pad ="0"),sep=""))),
                              'B03002_001','B03002_002','B03002_003','B03002_012','B03002_013','B02017_001',
                              'B19301_001', 'B17021_001', 'B17021_002',"B02001_005","B02001_004","B02001_006","B01003_001"),
                year = 2018, state = NULL, geometry = FALSE) %>%
  dplyr::select(-moe) %>%
  spread(key = 'variable', value = 'estimate') %>% 
  mutate(
    total_population=B01003_001,
    tot_population_race = B02001_001,
    pop_nonwhite=B02001_001-B02001_002,
    pop_nonwhitenh=B03002_001-B03002_003,
    race_pct_white = B02001_002/B02001_001,
    race_pct_whitenh = B03002_003/B03002_001,
    race_pct_nonwhite = 1 - race_pct_white,
    race_pct_nonwhitenh = 1 - race_pct_whitenh,
    race_pct_black = B02001_003/B02001_001,
    race_pct_aapi = (B02001_005+B02001_006)/B02001_001,
    race_pct_native = B02001_004/B02001_001,
    race_pct_hisp = B03002_012/B03002_001) %>%
  mutate(
    tot_population_income = B17021_001,
    in_poverty = B17021_002) %>%
  mutate(
    inc_pct_poverty = in_poverty/tot_population_income,
    inc_percapita_income = B19301_001) %>%
  left_join(language, by="GEOID")%>%
  left_join(age, by="GEOID")%>%
  dplyr::select(-starts_with("B0"))%>%
  dplyr::select(-starts_with("B1"))%>%
  dplyr::select(-2,-15,-23,-24,-25,-26,-27)%>%
  mutate(GEOID=as.character(GEOID)))

##writes file to repo. Be mindful of file size. Not sure if best place for these is in repo or in google drive folder.
setwd("C:/Users/rcarder/Documents/dev/CARES/data/demographics")

write.csv(get(paste(geoLevel,"Demographics",sep='')),paste(geoLevel,"Demographics.csv",sep=''), row.names = FALSE)

