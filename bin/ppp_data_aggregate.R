library(tidyverse)

### read in lookup tables & demographic files -------------------------------------

# look up tables
zip_to_zcta<-read_csv("data/Lookup Tables/zip_to_zcta_2019.csv")%>%
    mutate(ZIP_CODE=str_pad(as.character(ZIP_CODE), width=5, side="left", pad="0"))

zcta_to_county <- read_csv("data/Lookup Tables/acs_2018_block_groups_zcta.csv",
                         col_types = cols(
                             .default = col_character(),
                             block_group_interpolated_latitude = col_double(),
                             block_group_interpolated_longitude = col_double(),
                             zcta_interpolated_latitude = col_double(),
                             zcta_interpolated_longitude = col_double()
                         ))

# demographic files
zcta_demo <- read_csv("data/demographics/zipcodeDemographics.csv")
county_demo <- read_csv("data/demographics/countyDemographics.csv")
cd_demo <- read_csv("data/demographics/congressional districtDemographics.csv")
state_demo <- read_csv("data/demographics/stateDemographics.csv")

### Aggregate by ZCTA -----------------------------------------

adbs_zcta<-adbs%>%
    left_join(zip_to_zcta, by=c("Zip"="ZIP_CODE")) # 373 records have no matching ZCTA

adbs_zcta <- adbs_zcta%>%
    filter(!is.na(ZCTA))%>% 
    group_by(ZCTA)%>%
    summarize(Low=sum(LoanAmount_Estimate_Low),
              Mid=sum(LoanAmount_Estimate_Mid),
              High=sum(LoanAmount_Estimate_High),
              Mid_lt150k=sum(LoanAmount_Estimate_Mid*LoanAmount_lt150k), # midpoint estimate for loans under 150k
              Cnt_ge150k=sum(LoanAmount_ge150k)) # count of loans 150k or more

adbs_zcta<-zcta_demo%>%
    left_join(adbs_zcta,by=c("GEOID"="ZCTA"))%>%
    filter(total_population>50)%>%
    mutate(Low=ifelse(is.na(Low),0,Low), # if loan amount is NA, assume this means that area did not receive any loans
           Mid=ifelse(is.na(Mid),0,Mid),
           High=ifelse(is.na(High),0,High),
           Mid_lt150k=ifelse(is.na(Mid_lt150k),0,Mid_lt150k),
           Cnt_ge150k=ifelse(is.na(Cnt_ge150k),0,Cnt_ge150k))
    mutate(LowPerCap=Low/total_population,
           MidPerCap=Mid/total_population,
           HighPerCap=High/total_population,
           MidPerCap_lt150k=Mid_lt150k/total_population,
           CntPerCap_ge150k=Cnt_ge150k/total_population)%>%
    mutate(pctile_MidPerCap=ntile(MidPerCap,100),
           pctile_MidPerCap_lt150k=ntile(MidPerCap_lt150k,100),
           pctile_CntPerCap_ge150k=ntile(CntPerCap_ge150k,100))

### Aggregate by Congressional District ---------------------
    
### Aggregate by County -------------------------------------