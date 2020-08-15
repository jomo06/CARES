### Data Dictionary Exploration
### kbmorales@protonmail.com
###


# Setup -------------------------------------------------------------------

# Data prep should be performed first
# source("./bin/ppp_data_merge.R")

library(tidyverse)
library(lubridate)
library(knitr)
library(stringdist) # for fuzzy matching

# Summaries ---------------------------------------------------------------

glimpse(adbs)

# Data Check: LoanRange_Unified -------------------------------------------

# evaluate how many Loan Range values are sensible
table(adbs$LoanRange_Unified, useNA="always")


# Data Check: ZipCodes ----------------------------------------------------

# generate table to check lengths and also run a simple grep ZIP validator
table(grepl("\\d{5}([ \\-]\\d{4})?", adbs$Zip), nchar(adbs$Zip),useNA = "always", dnn = c("Passes Simple ZIP Validation","Number of Characters"))

# OUTPUT:
#                             Number of Characters
# Passes Simple ZIP Validation        5    <NA>
#                         FALSE       0     224
#                         TRUE  4885164       0
#                         <NA>        0       0
#
# result indicates that all present values are of valid length as simple 5 digit zips, however 224 are missing entirely and are recorded in original data as NAs
# let's code this into a new variable, so that we can later evaluate each row for validation along various checks

adbs <- adbs %>%
  mutate(Zip_Valid_Format = case_when(grepl("\\d{5}", Zip)        ~ "Pass: 5 Digit Format",
                                      grepl("\\d{5}-\\d{4}", Zip) ~ "Pass: 5dash4 Digit Format ",
                                      TRUE ~ "Fail"))

table(adbs$Zip_Valid_Format, useNA = "always")

# let's validate against a large list of ZIPs from: https://simplemaps.com/data/us-cities


uszips <- read.csv("data/simplemaps_uszips_basicv1.72/uszips.csv")

length(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", uszips$zip))])            # 42,580 rows without a zip in the list
length(unique(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", uszips$zip))]))    # 5,036 unique unmatched zips
sample(unique(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", uszips$zip))]), 5) # this tends to give what are, according to Google Maps, valid ZIPs. Perhaps the simplemaps list is too old...
# we do not appear to be much closer, but at least the error rate isn't horrible (42,000 out of 4,800,000)


#Data Validation: Zip --------------------------------------------------------------
#True indicates entry is a valid zip, i.e. it exists in the zip-reference list
adbs <- adbs %>% mutate(ValidZip = case_when(
  is.na(Zip) ~ "No Entry",
  Zip %in% sprintf("%05d", uszips$zip) ~ "True",
  !Zip %in% sprintf("%05d", uszips$zip) ~ "Fail"))

table(adbs$ValidZip, useNA = "always")


# instead let's use the file 'zip_to_zcta_2019.csv' and see if we get better coverage
ztz <- read.csv("data/Lookup Tables/zip_to_zcta_2019.csv")

length(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", ztz$ZIP_CODE))])            # 1,627 rows without a zip in the list
length(unique(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", ztz$ZIP_CODE))]))    # 331 unique unmatched zips
sample(unique(adbs$Zip[(!adbs$Zip %in% sprintf("%05d", ztz$ZIP_CODE))]), 5) # this sampling does not seem to be all valid zips!
# we appear to be much closer using this list

### Data Check: State Names -----------------------------------------------
# check against US Census data: American National Standards Institute (ANSI) Codes for States, the District of Columbia, Puerto Rico, and the Insular Areas of the United States
#via: https://www.census.gov/library/reference/code-lists/ansi.html
statecodes <- read.table("./data/census/state.txt", sep = "|", header = TRUE)

table(adbs$State[(!adbs$State %in% statecodes$STUSAB)]) # list counts of unmatched results, showing 1 AE, 1 FI, 210 XX

adbs[adbs$State == "FI",] # based on the ZIP code, this should be FL, and can be 'fixed' easily enough as part of final data cleaning
adbs[adbs$State == "AE",] # when viewing ZIP, Lending data, this does indeed appear to be tied to a military address in Europe, Middle East, Africa or Canada

# Impute Missing Fields: state --------------------------------------------------------------
# Impute missing state by zipcode. Here, we do not check if city and zipcode match
cat(sprintf("%s missing states", nrow(adbs[adbs$ImputedState=='XX',])))
XXstate_zip = adbs[(adbs$State=='XX' & !is.na(adbs$Zip)),]$Zip
XXstate_city = adbs[(adbs$State=='XX' & !is.na(adbs$Zip)),]$City
cat(sprintf("%s missing states, with zip entry", length(XXstate_zips)))


adbs$ImputedState =adbs$State
imputed_states = c()
missing_zips = c()
for (zip in XXstate_zip){
  state = uszips[uszips$zip==zip,]$state_id

  if (identical(state, character(0))){
    state = NA
    missing_zips = c(missing_zips, zip)}
  imputed_states=c(imputed_states, state)
}

adbs[which(adbs$ImputedState=='XX' & !is.na(adbs$Zip)), arr.ind=TRUE]$ImputedState = imputed_states

cat(sprintf("out of the %s missing states that had zip entry, %s states imputed from zipcodes, %s zipcodes not found in 'uszips' file", length(impute_zips), (length(imputed_states) - length(missing_zips)),length(missing_zips)))



### Data Check: City Names -------------------------------------------------
# check City values against a large list of likely names, via: https://simplemaps.com/data/us-cities
uscities <- read.csv("./data/simplemaps_uscities_basicv1.6/uscities.csv")

citydict <- sort(unique(tolower(gsub("[[:digit:][:space:][:punct:]]", "", uscities$city))))
adbscities <- sort(unique(tolower(gsub("[[:digit:][:space:][:punct:]]", "", adbs$City))))

citymatch_01 <- amatch(adbscities, citydict, method = "lv", maxDist = 0.1)
citymatch_05 <- amatch(adbscities, citydict, method = "lv", maxDist = 0.5)
citymatch_10 <- amatch(adbscities, citydict, method = "lv", maxDist = 1.0)

adbscities <- as.data.frame(adbscities)
adbscities$match_01 <- citydict[citymatch_01]
adbscities$match_05 <- citydict[citymatch_05]
adbscities$match_10 <- citydict[citymatch_10]

# this output is showing issues: for example, "schicago" matches to chicago, but really it is more likely to be "South Chicago"
# a hand built list, with the above as a baseline, may be most effective.


#Data Validation: City Names --------------------------------------------------------------
#True indicates entry is a valid city name, i.e. it exists in the city-reference list
#SpecialChar indicates entry is not in city-reference list and has non-alphabetical characters, other than '-' and/or '.'
#False indicates entry is not in city-reference list and does not have special characters.
#looking at False cities, we see that sometimes neighborhood was entered instead of city.
#For example, entries such as vannuys or north hollywood: both are neighborhoods in LA county, but neither are cities!
#Also, some of these erroneous entries are a result of including N/S/E/W. For example, while N LEWISBURG is not a city, LEWISBURG is a city

#Note: We also replace "saint" by "st": going from 4581465 True entries to 4625483, increase of 44,000


adbs <- adbs %>% mutate(ValidCity = case_when(
  (is.na(City) | City =="N/A") ~ "No Entry",
  (tolower(gsub("[[:digit:][:space:][:punct:]]", "" , str_replace(tolower(City), "saint", "st"))) %in%  citydict) ~ "True",
  !grepl("^[A-Za-z]+$", gsub("[,.[:space:]]", "" , City)) ~ "SpecialChar",
  TRUE ~ "Fail"))

table(adbs$ValidCity, useNA = "always")





### Data Check: Jobs Retained ----------------------------------------------

#confirm all Jobs Retained values are integers (whole numbers) or NAs
summary(near(as.numeric(adbs$JobsRetained), as.integer(as.numeric(adbs$JobsRetained))))

# Coerce -------------------------------------------------------------------

### Coersions
adbs = adbs %>%
  mutate(JobsRetained = as.numeric(JobsRetained),
         DateApproved = as.Date(DateApproved,
                                 "%m/%d/%Y"),
         LoanAmount = as.numeric(LoanAmount))


# Data Check: Date Approved  ------------------------------------------------
table(adbs$DateApproved, useNA="always")


# Duplicates --------------------------------------------------------------

### Duplicates

## Takes a long time! Be patient.

# sum(duplicated(adbs))
# 4353 exact duplicates

# adbs_dupes=adbs[duplicated(adbs),]




