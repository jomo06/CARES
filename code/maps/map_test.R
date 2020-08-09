library(tidyverse)
library(readxl)
library(tigris)

###########################################################
# Below is a very rough mapping between PPP data and census data
# Replace this section with cleaned data set when it's ready
##########################################################

### read in data
ppp_mi <- read_csv("data/All Data By State/PPP Data up to 150K - MI.csv")

census_geo <- read_csv("data/demographics/acs_2018_block_groups_zcta.csv",
                         col_types = cols(
                             .default = col_character(),
                             block_group_interpolated_latitude = col_double(),
                             block_group_interpolated_longitude = col_double(),
                             zcta_interpolated_latitude = col_double(),
                             zcta_interpolated_longitude = col_double()
                         ))

zcta_demo <- read_csv("data/demographics/zipcodeDemographics.csv")
county_demo <- read_csv("data/demographics/countyDemographics.csv")
cd_demo <- read_csv("data/demographics/congressional districtDemographics.csv")
state_demo <- read_csv("data/demographics/stateDemographics.csv")

### download shapefiles
counties_mi <- counties(state = "MI")

### merge in census geo
ppp_mi$Zip <- as.character(ppp_mi$Zip)
ppp_mi_2 <- ppp_mi %>% left_join(zcta_demo, by = c("zcta" = "GEOID"))
sum(is.na(ppp_mi_2$county_fips_code)) # 660 out of 101166 have no match

# concatenate state codes and fips codes to create GEOID
ppp_mi_3 <- ppp_mi_2 %>% 
    mutate(county_geoid = paste0(str_pad(state_fips_code, 2, pad = "0"), 
                                 str_pad(county_fips_code, 3, pad = "0")))
# TO DO: add congressional district

### aggregate by county
ppp_mi_county <- ppp_mi_3 %>% 
    group_by(county_geoid) %>% 
    summarise(sum(LoanAmount)) %>% 
    left_join(county_demo, by = c("county_geoid" = "GEOID"))
# sum(is.na(ppp_mi_county$total_population)) # only 1 missing

###########################################################
# Mapping code starts here
###########################################################

### create leaflet map of counties
