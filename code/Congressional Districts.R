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
library(hrbrthemes)
library(scales)
library(ggthemes)
#This script extracts ACS 5-year estimates at the ZIP level group using the tidycensus package. To run tidycensus, you first need
#to set up a Census API key and run census_api_key(). Set working directory
#to where you want output files to save, or use the collect_acs_data function 
#to set a different outpath.
#


##Change to your wd where repo is cloned to pull in any auxiliary data that may be useful
setwd("C:/Users/rcarder/Documents/dev/CARES/data/Lookup Tables")
cities<-read.csv("cities.csv") ##to help provide context to state maps

##removed census key. Sign up for one for free at https://api.census.gov/data/key_signup.html
census_api_key('', install=TRUE, overwrite = TRUE)


##To explore fields available in the ACS
acs_table <- load_variables(2018, "acs5", cache = TRUE)


###Choose Geography Options###

##Geographic Level (county, state, tract, zcta (ZIP), block group, congressional district, public use microdata area)
geoLevel='congressional district'  ##Zip Codes with approximate tabulation areas (ZIP codes are not actual polygons)

##Specific State? Leaving NULL will pull whole US. For anything more granular than census tracts, specify a state.
state=NULL

##Also pull in geometry polygons for mapping? Takes much longer, so leave FALSE if just the data is needed.
pullGeography=TRUE

##Now run lines 49-118


##Language - note for most geographies language data is missing for years past 2015 (its there for state up to 2018)
language <- get_acs(geography = geoLevel,
                    variables = c('B16001_001','B16001_002','B16001_003','B16001_004','B16001_005',
                                  'B16001_075','B16001_006'),
                    year = 2015, state = NULL, geometry = FALSE) %>%
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
                year = 2018, state = NULL, geometry = TRUE) %>%
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
  dplyr::select(-15,-23,-24,-25,-26,-27)%>%
  mutate(GEOID=as.character(GEOID)))

##writes file to repo. Be mindful of file size. Not sure if best place for these is in repo or in google drive folder.
setwd("C:/Users/rcarder/Documents/dev/CARES/data/demographics")

write.csv(get(paste(geoLevel,"Demographics",sep='')),paste(geoLevel,"Demographics.csv",sep=''), row.names = FALSE)

### Read --------------------------------------------------------------------
setwd("C:/Users/rcarder/Documents/dev/All Data by State")

# set relative directory to search then scan through subdirectories for CSVs
csv_dir <- paste(getwd(),"/All Data 0808", sep="")
cat(sprintf("Looking for data files in: %s\n", csv_dir))
csv_files <- list.files(csv_dir, full.names = T, recursive = T, pattern = ".*.csv") 

# read in each CSV as character values, to allow for a clean import, attach the name of the data source file
adbs <- map_df(csv_files, ~read_csv(.x, col_types = cols(.default = "c")) %>%
                 mutate(source_file = str_remove_all(.x, ".*/"))
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
n_distinct(adbs$CD)




##load election data and create join fields; filter to just 2018 election; calculate difference between democrat and republican vote percentages
setwd("C:/Users/rcarder/Documents/dev/CARES/data/Lookup Tables")

electiondataraw<-read.csv("HouseElections.csv")%>%
  mutate(district=str_pad(district, width=2, side="left", pad="0"),
         state_fips=str_pad(state_fips, width=2, side="left", pad="0"),
         votePer=candidatevotes/totalvotes)%>%
          filter(year==2018)

unique(electiondataraw[electiondataraw$totalvotes>350000,]$party)

electiondata<-electiondataraw%>%
  mutate(GEOID=paste(state_fips,district,sep=''))%>%
  dplyr::select(13,20,21)%>%
  mutate(party=ifelse(party=="democrat"|party=="democratic-farmer-labor","democrat",
                      ifelse(party=="republican"|party=="libertarian","republican","other")))%>% ##note im including libertarian with republican.
  mutate(party=ifelse(is.na(party),"other",party))%>%
  group_by(GEOID,party)%>%
  summarize(votePer=sum(votePer))%>%
  pivot_wider(names_from = party,values_from = votePer)

electiondata[is.na(electiondata)]<-0

electiondata<-electiondata%>%
  mutate(DemPlus=democrat-republican,
         check=democrat+republican+other) ##All but 6 districts equal exactly 1. Those 6 are very close.
  
statelookup<-electiondataraw%>%
  group_by(state,state_po,state_fips,district)%>%
  summarise(totalvotes=sum(totalvotes))%>%
  mutate(GEOID=paste(state_fips,district,sep=''),
         CD=paste(state_po," - ",district))

StateAbbrs<-statelookup%>%
  group_by(state_fips,state_po)%>%
  summarize(dummy=sum(totalvotes))

#Aggregate PPP data by district
CDAggregate<-adbs%>%
  group_by(CD)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))%>%
  mutate(state=substr(CD,1,2),
         district=substr(CD,4,5))%>%
  left_join(StateAbbrs,by=c("state"="state_po"))%>%
  mutate(GEOID=paste(state_fips,district,sep=''),
         GEOID=ifelse(state=="DC","1198",GEOID),   #DC's CD and GEOID didnt match
         GEOID=ifelse(state=="PR","7298",GEOID))%>%  #PR's CD and GEOID didnt match
  dplyr::select(2,3,4,9)

sum(CDAggregate$Low) ##399 billion
sum(CDAggregate$Mid) ##577 billion
sum(CDAggregate$High) ##755 billion
##Actual amount of total PPP loan amount is 659 billion


##join PPP and election data to demographics file with geometry

MasterDistricts<-`congressional districtDemographics`%>%
  left_join(electiondata)%>%
  left_join(statelookup)%>%
  left_join(CDAggregate)%>%##DC and 3 non-districts didnt have election data
  mutate(LowPerCap=Low/total_population,
         MidPerCap=Mid/total_population,
         HighPerCap=High/total_population)%>%
  mutate(percentileLow=ntile(LowPerCap,100),  ##percentiles for 
         percentileMid=ntile(MidPerCap,100),
         percentileHigh=ntile(HighPerCap,100))
  
sum(MasterDistricts$Low,na.rm = TRUE)/sum(CDAggregate$Low) 
sum(MasterDistricts$Mid,na.rm = TRUE)/sum(CDAggregate$Mid) 
sum(MasterDistricts$High,na.rm = TRUE)/sum(CDAggregate$High) ##99.9% accounted for!

##Create a set without geometry to speed up non spatial analyses
MasterDistrictsAnalysis<-st_drop_geometry(MasterDistricts)

setwd("C:/Users/rcarder/Documents/dev/CARES/data/Enhanced Datasets")
write.csv(MasterDistrictsAnalysis,"CongressionalDistrictsEnhanced.csv",row.names = FALSE)


##Write Shapefile
#MasterDistrictsSF <- st_collection_extract(MasterDistricts, "POLYGON")
#st_write(MasterDistrictsSF, dsn = "CongressionalDistrictsEnhanced.shp", layer = "CongressionalDistrictsEnhanced.shp", driver = "ESRI Shapefile")



###Some Sample Plots###

##Voting v Loan per Capita
MasterDistrictsAnalysis%>%
  ggplot(aes(x=DemPlus,y=MidPerCap,color=DemPlus))+
  scale_color_gradient("Voting",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount per Capita",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Loan Amount per Capita - Mid Estimate")+
  theme_ipsum()

##Voting v Loan Total
MasterDistrictsAnalysis%>%
  ggplot(aes(x=DemPlus,y=Mid,color=DemPlus))+
  scale_color_gradient("% Dem",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount by Election Results",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Total Loan Amount - Mid Estimate")+
  theme_ipsum()


##Voting v Loan Total - Color by Race
MasterDistrictsAnalysis%>%
  ggplot(aes(x=DemPlus,y=Mid,color=race_pct_nonwhitenh))+
  scale_color_gradient("% Non-White",low = "yellow", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount by Voting and Race",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Total Loan Amount - Mid Estimate")+
  theme_ipsum()

##Voting v Loan Total - Color by % Below Poverty Line
MasterDistrictsAnalysis%>%
  ggplot(aes(x=DemPlus,y=Mid,color=inc_pct_poverty))+
  scale_color_gradient("% Below Poverty Line",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Total Loan Amount - Mid Estimate")+
  theme_ipsum()


##Race v Loan Total - Color by Voting
MasterDistrictsAnalysis%>%
  ggplot(aes(x=race_pct_nonwhitenh,y=Mid,color=DemPlus))+
  scale_color_gradient("% Dem",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount by Voting and Race",
       x="% Non-White",
       y="PPP Total Loan Amount - Mid Estimate")+
  theme_ipsum()

##Race v Loan Total - Color by Voting and Race
MasterDistrictsAnalysis%>%
  ggplot(aes(x=inc_pct_poverty,y=Mid,color=race_pct_nonwhitenh))+
  scale_color_gradient("% Non-white",low = "yellow", high = "red", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount by Voting and Poverty",
       x="% Below Poverty Line",
       y="PPP Total Loan Amount - Mid Estimate")+
  theme_ipsum()


MasterDistrictsAnalysis%>%
  filter(state_po=="MI"|state_po=="WI"|state_po=="IL"|state_po=="MN"|state_po=="OH"|state_po=="PA")%>%
  ggplot(aes(x=race_pct_nonwhitenh,y=MidPerCap,color=race_pct_nonwhitenh))+
  scale_color_gradient("Voting",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount per Capita",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Loan Amount per Capita - Mid Estimate")+
  facet_wrap(~state)+
  theme_ipsum()

MasterDistrictsAnalysis%>%
  filter(state_po=="NC"|state_po=="FL"|state_po=="OH"|state_po=="MI"|state_po=="VA"|state_po=="PA")%>%
  ggplot(aes(x=DemPlus,y=MidPerCap,color=DemPlus))+
  scale_color_gradient("Voting",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format())+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount per Capita",
       x="2018 Voting (+ Democrat/- Republican)",
       y="PPP Loan Amount per Capita - Mid Estimate")+
  facet_wrap(~state)+
  theme_ipsum()


MasterDistrictsAnalysis%>%
  filter(state_po=="TX"|state_po=="FL"|state_po=="NY"|state_po=="CA"|state_po=="IL"|state_po=="PA")%>%
  ggplot(aes(x=inc_pct_poverty,y=Mid,color=DemPlus))+
  scale_color_gradient("% Dem",low = "red", high = "blue", labels = percent)+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1))+
  scale_y_continuous(labels = scales::dollar_format(),limits=c(0,7500000000))+
  geom_point(alpha=.9)+geom_smooth(
    method = "loess")+
  labs(title="Congressional Districts - Loan Amount by Voting, Poverty, and State",
       x="% Below Poverty Line",
       y="PPP Loan Amount per Capita - Mid Estimate")+
  facet_wrap(~state)+
  theme_ipsum()

###Sample Maps####

##Map
MasterDistricts%>%
  filter(state_po!="HI"&state_po!="AK")%>%
  ggplot() +
  geom_sf(aes(fill=(MidPerCap)),color="#ffffff",alpha=1) +
  scale_fill_distiller(palette="Blues",na.value="000000",limits=c(0, 8000),direction = 1)+
  # geom_sf(data = MI, color = '#f0f0f0', fill = NA, lwd=.001)+
  #geom_point(data=michigancities,aes(x=lon,y=lat),size=.5)+
  labs(fill="Loan Amount Per Capita")+
  # geom_text_repel(data=michigancities,aes(x=lon,y=lat,label=City),family="Montserrat",size=2)+
  theme_map()+
  theme(legend.position = "right")

##options
statefilter="Minnesota"
cutoff=100

statecities<-cities%>%
  filter(State==statefilter&Rank<=cutoff)

##State Map of Loan Amount Per Capita
MasterDistricts%>%
  filter(state==statefilter)%>%
  ggplot() +
  geom_sf(aes(fill=(MidPerCap)),color="#ffffff",alpha=1) +
  scale_fill_distiller(palette="Blues",na.value="000000",limits=c(0, 8000),direction = 1,labels=currency)+
  geom_point(data=statecities,aes(x=lon,y=lat),size=.5)+
  labs(fill="Loan Amount Per Capita")+
  geom_text_repel(data=statecities,aes(x=lon,y=lat,label=City),family="Montserrat",size=3)+
  theme_map()+
  theme(legend.position = "right")

MasterDistricts%>%
  filter(state==statefilter)%>%
  ggplot() +
  geom_sf(aes(fill=(inc_pct_poverty)),color="#ffffff",alpha=1) +
  scale_fill_distiller(palette="Greens",na.value="000000",direction = 1,labels=percent)+
  geom_point(data=statecities,aes(x=lon,y=lat),size=.5)+
  labs(fill="% Below Poverty Line")+
  geom_text_repel(data=statecities,aes(x=lon,y=lat,label=City),family="Montserrat",size=3)+
  theme_map()+
  theme(legend.position = "right")

MasterDistricts%>%
  filter(state==statefilter)%>%
  ggplot() +
  geom_sf(aes(fill=(race_pct_nonwhitenh)),color="#ffffff",alpha=1) +
  scale_fill_distiller(palette="RdPu",na.value="000000",direction = 1,labels=percent)+
  geom_point(data=statecities,aes(x=lon,y=lat),size=.5)+
  labs(fill="% NonWhite")+
  geom_text_repel(data=statecities,aes(x=lon,y=lat,label=City),family="Montserrat",size=3)+
  theme_map()+
  theme(legend.position = "right")

MasterDistricts%>%
  filter(state==statefilter)%>%
  ggplot() +
  geom_sf(aes(fill=(DemPlus)),color="#ffffff",alpha=1) +
  scale_fill_distiller(palette="RdBu",na.value="000000",direction = 1,limits=c(-1,1),labels=percent)+
  geom_point(data=statecities,aes(x=lon,y=lat),size=.5)+
  labs(fill="Election Results")+
  geom_text_repel(data=statecities,aes(x=lon,y=lat,label=City),family="Montserrat",size=3)+
  theme_map()+
  theme(legend.position = "right")

geom_point(data=michigancities,aes(x=lon,y=lat))+
  labs(fill="Loan Amount")+
  geom_text_repel(data=michigancities,aes(x=lon,y=lat,label=City),family="Montserrat",size=2)+


  ##End of Congressional Districts Code - Below is ZCTA from earlier### 
  
  
setwd("C:/Users/rcarder/Documents/dev/CARES/data/Lookup Tables")
ZCTAlookup<-read.csv("zip_to_zcta_2019.csv")%>%
  mutate(ZIP_CODE=str_pad(as.character(ZIP_CODE), width=5, side="left", pad="0"))

#Aggregate by ZIP
ZCTAAggregate<-adbs%>%
  left_join(ZCTAlookup, by=c("Zip"="ZIP_CODE"))%>%  #make smaller before grouping
  group_by(ZCTA)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))

##Join to ZCTAs (347 ZIPS will be left out)
ZCTAjoined<-zctaDemographics%>%
  left_join(ZCTAAggregate,by=c("GEOID"="ZCTA"))%>%
  filter(total_population>50)%>%
  mutate(LowPerCap=Low/total_population,
         MidPerCap=Mid/total_population,
         HighPerCap=High/total_population)%>%
  mutate(percentile=ntile(MidPerCap,100))

##Brings in state field to be able to filter/split by state, but this duplicates ZCTAs that cross borders so dont use for country wide aggregates
ZCTAjoinedforStates<-zctaDemographics%>%
  left_join(ZCTAAggregate,by=c("GEOID"="ZCTA"))%>%
  filter(total_population>50)%>%
  mutate(LowPerCap=Low/total_population,
         MidPerCap=Mid/total_population,
         HighPerCap=High/total_population)%>%
  left_join(ZCTAlookup,by=c("GEOID"="ZCTA"))%>%
  mutate(percentile=ntile(MidPerCap,100))

#Scatter plots faceted by some states - change x and y. Removes 100th percentile which are contain some huge outliers
FACET<-ZCTAjoinedforStates%>%
 filter(STATE=="TX"|STATE=="MI"|STATE=="CA"|STATE=="NY"|STATE=="FL"|STATE=="GA")%>%
  filter(percentile<100)%>%
  #filter(inc_percapita_income<150000)%>% 
  ggplot(aes(x=race_pct_black,y=MidPerCap))+
  geom_point(color="red",alpha=.1)+geom_smooth(
    method = "loess")+
  facet_wrap(~STATE)

#make michigan data
MI<-ZCTAjoinedforStates%>%
  filter(STATE=="MI")
#remove duplicates created from border ZCTAs
MI<-MI[!duplicated(MI$GEOID),] #remove duplicate organization names (removes phase 1 where there are duplicates since phase 2 is at top)



##Map
TotalLoan<-ggplot() +
  geom_sf(data = FACET, aes(fill=(percentile)),color=NA,alpha=1) +
  scale_fill_distiller(palette="Spectral",na.value="000000",limits=c(0, 100),direction = -1)+
 # geom_sf(data = MI, color = '#f0f0f0', fill = NA, lwd=.001)+
  #geom_point(data=michigancities,aes(x=lon,y=lat),size=.5)+
  labs(fill="Percentile SBA Per Capita")+
 # geom_text_repel(data=michigancities,aes(x=lon,y=lat,label=City),family="Montserrat",size=2)+
  map_theme()+
  theme(legend.position = "right")
  


n_distinct(ZCTAlookup$ZCTA)


ZipAmount<-adbs%>%
  dplyr::select(4:8,20:22)%>%  #make smaller before grouping
  group_by(Zip,State)%>%
  summarize(Low=sum(LoanAmount_Estimate_Low),
            Mid=sum(LoanAmount_Estimate_Mid),
            High=sum(LoanAmount_Estimate_High))%>%
  left_join(ZCTAlookup, by=c("Zip"="ZIP_CODE"))

michigan<-ZCTAjoined%>%
  filter(LowPerCap<10000)%>%
  mutate(percentile=ntile(LowPerCap,100))
  ggplot()+geom_histogram(aes(LowPerCap))

michigancities<-cities%>%
  filter(State=="Michigan"&Rank<220)


map_theme<- function(...) {
  theme_minimal() +
    theme(
      #text = element_text(family = "Ubuntu Regular", color = "#22211d"),
      axis.line = element_blank(),
      text = element_text(color = "#000000",family="Montserrat"),
      legend.title = element_text(size=6, family="Montserrat SemiBold"),
      legend.text = element_text(size=6),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      # panel.grid.minor = element_line(color = "#ebebe5", size = 0.2),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_blank(), 
      panel.background = element_blank(), 
      legend.background = element_blank(),
      panel.border = element_blank(),
      ...
    )
}

TotalLoan<-ggplot() +
  geom_sf(data = michigan, aes(fill=(race_pct_nonwhitenh)),color=NA,alpha=1) +
  scale_fill_gradient(low="white",high="#ffbb00",na.value="000000",limits=c(0, 100))+
 geom_sf(data = michigan, color = '#f0f0f0', fill = NA, lwd=.01)+
 geom_point(data=michigancities,aes(x=lon,y=lat))+
  labs(fill="Loan Amount")+
 geom_text_repel(data=michigancities,aes(x=lon,y=lat,label=City),family="Montserrat",size=2)+
  map_theme()+
  theme(legend.position = "right")



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








