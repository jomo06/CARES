library(tidyverse)
library(ggplot2)
library(readxl)
library(tigris)
library(sf)
library(sp)

setwd("C:/Users/kathy/Documents/github/CARES")

############################
# read in data
############################
# cleaned ZCTA-level PPP dataset
ppp <- read_csv("data/tidy_data/Michigan.csv")

# ZCTA to block-group mapping
zcta_mapping <- read_csv("data/Lookup Tables/acs_2018_block_groups_zcta.csv",
                         col_types = cols(
                             .default = col_character(),
                             block_group_interpolated_latitude = col_double(),
                             block_group_interpolated_longitude = col_double(),
                             zcta_interpolated_latitude = col_double(),
                             zcta_interpolated_longitude = col_double()
                         ))

# Demographic files
zcta_demo <- read_csv("data/demographics/zipcodeDemographics.csv")
county_demo <- read_csv("data/demographics/countyDemographics.csv")
cd_demo <- read_csv("data/demographics/congressional districtDemographics.csv")
state_demo <- read_csv("data/demographics/stateDemographics.csv")

# download shapefiles
#zcta_shp <- zctas(state = "MI")
counties_shp <- counties(state = "MI")
#cd_shp <- congressional_districts()

############################
# merge in census geos
############################
# clean up zcta to census geo cw
zcta_mapping <- zcta_mapping %>% 
    mutate(state_fips_code = str_pad(state_fips_code, 2, pad = "0"),
           county_fips_code = str_pad(county_fips_code, 3, pad = "0"),
           tract_fips_code = str_pad(tract_fips_code, 6, pad = "0"),
           zcta = str_pad(zcta, 5, pad = "0"),
           zcta_geoid = zcta,
           state_geoid = state_fips_code,
           county_geoid = paste0(state_fips_code, county_fips_code),
           tract_geoid = paste0(state_fips_code, county_fips_code, tract_fips_code),
           block_group_geoid = paste0(state_fips_code, county_fips_code, tract_fips_code, block_group_fips_code))

# keep only ZCTA-county mapping for now
zcta_county_mapping <- zcta_mapping %>% 
    select(zcta_geoid, county_geoid) %>% 
    distinct()

# add census geo to ppp dataset
ppp_census <- ppp %>% 
    mutate(GEOID = str_pad(as.character(GEOID), 5, pad = "0")) %>% 
    left_join(zcta_county_mapping, by = c("GEOID" = "zcta_geoid"))

# # aggregate by county & add county demographics
# dat <- ppp_census %>% 
#     group_by(county_geoid) %>% 
#     summarize(val = sum(Mid, na.rm = TRUE)) %>% 
#     left_join(county_demo, by = c("county_geoid" = "GEOID"))
# 
# ############################
# # create map
# ############################
# spdf <- merge(counties_shp, dat, by.x="GEOID", by.y="county_geoid")
# sf <- st_as_sf(spdf)
# sf <- cbind(sf, st_coordinates(st_centroid(sf)))
# 
# ggplot(sf) +
#     geom_sf(aes(fill = total_population)) +
#     geom_point(aes(x=X, y=Y, size=val), pch=21, fill = '#ffffff50') +
#     scale_fill_viridis_c(trans="sqrt")

############################
# leaflet + shiny
############################
