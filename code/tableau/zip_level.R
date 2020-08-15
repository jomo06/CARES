# Setup -------------------------------------------------------------------

# Data prep should be performed first
# source("ppp data script.R")
# libraries used: tidyverse

### Using code chunks from loan_value_ranking.R for now -------------------

# Create valid Loan Values for all rows -----------------------------------

# Set numeric min, mid and max values for all loan ranges, keep exact values as-is
adbs <- adbs %>% 
  mutate(LoanRangeMin = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & adbs$LoanRange == "a $5-10 million"       ~ as.numeric( 5000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "b $2-5 million"        ~ as.numeric( 2000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "c $1-2 million"        ~ as.numeric( 1000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "d $350,000-1 million"  ~ as.numeric(  350000),
                                  is.na(LoanAmount) & adbs$LoanRange == "e $150,000-350,000"    ~ as.numeric(  150000),
                                  TRUE ~ NA_real_))

adbs <- adbs %>% 
  mutate(LoanRangeMax = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & adbs$LoanRange == "a $5-10 million"       ~ as.numeric(10000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "b $2-5 million"        ~ as.numeric( 5000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "c $1-2 million"        ~ as.numeric( 2000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "d $350,000-1 million"  ~ as.numeric( 1000000),
                                  is.na(LoanAmount) & adbs$LoanRange == "e $150,000-350,000"    ~ as.numeric(  350000),
                                  TRUE ~ NA_real_))

adbs <- adbs %>% 
  mutate(LoanRangeMid = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & adbs$LoanRange == "a $5-10 million"       ~ as.numeric( 7500000),
                                  is.na(LoanAmount) & adbs$LoanRange == "b $2-5 million"        ~ as.numeric( 3500000),
                                  is.na(LoanAmount) & adbs$LoanRange == "c $1-2 million"        ~ as.numeric( 1500000),
                                  is.na(LoanAmount) & adbs$LoanRange == "d $350,000-1 million"  ~ as.numeric(  675000),
                                  is.na(LoanAmount) & adbs$LoanRange == "e $150,000-350,000"    ~ as.numeric(  250000),
                                  TRUE ~ NA_real_))




# our next step is somewhat tricky. The most precise geo data we have in the PPP data is ZIP (since the address data is very unreliable).
# ZIPs are not great, of course, for geo-location. We could map them to ZCTA using 'zip_to_zcta_2019' and if ZCTA shapefiles are what we're using
# to create our maps, that's a wise step. However, we face a problem: we don't have demographic data by ZCTA. We do have it by ZIP in 'zipcodeDemographics'
# but that data doesn't have matches to about 40,000 of our records. I'm also not clear on its source. For now, I will push ahead with that file
# as a way of getting at least a proof-of-concept running:




### Group by ZIP, prior to then attaching ZIP level demographics -----------

# estimated loan amounts per zip, including averages, with new ranks calculated within this grouped tibble
loanvalue_byzip <- adbs %>% 
  group_by(Zip) %>%
  summarise(SumLoanRangeMin = sum(LoanRangeMin),
            SumLoanRangeMax = sum(LoanRangeMax),
            SumLoanRangeMid = sum(LoanRangeMid),
            LoanCount = n(),
            AvgLoanMid = SumLoanRangeMid/LoanCount
  ) %>%
  mutate(LoanValueRank = rank(-SumLoanRangeMid, ties.method = "min"),
         AvgLoanRank = rank(-AvgLoanMid, ties.method = "min")) %>% 
  arrange(Zip,LoanValueRank)


zipdemos <- read.csv("data/demographics/zipcodeDemographics.csv", as.is = TRUE)
zipdemos$GEOID_match <- sprintf("%05d", zipdemos$GEOID)


loanvalue_zipdemos <- full_join(loanvalue_byzip, zipdemos, by = c("Zip" = "GEOID_match"))

write.csv(loanvalue_zipdemos,"data/tableau/loanvalue_zipdemos.csv")