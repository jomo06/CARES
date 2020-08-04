# Setup -------------------------------------------------------------------

# Data prep should be performed first
# source("ppp data script.R")
# libraries used: tidyverse, knitr

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

# rank all (we can then subset this at any grain and still get accurate rank order results)
adbs$LoanRange_Rank <- rank(-adbs$LoanRangeMin, ties.method = "min") # 1 would be largest value in this case, and will be assigned to all 4,000 or so 5-10million dollar loan entries

# we can now output comparative tibbles such as the below:
# top 5 loans per state
top5loans_bystate <- adbs %>% 
                        arrange(-desc(LoanRange_Rank)) %>% 
                        group_by(State) %>% slice(1:5)

# top 5 loans per state and zip
top5loans_bystatezip <- adbs %>% 
                          arrange(-desc(LoanRange_Rank)) %>% 
                          group_by(State, Zip) %>% slice(1:5)

# estimated loan amounts per state
loanvalue_bystate <- adbs %>% 
                          group_by(State) %>%
                          summarise(SumLoanRangeMin = sum(LoanRangeMin),
                                    SumLoanRangeMax = sum(LoanRangeMax),
                                    SumLoanRangeMid = sum(LoanRangeMid)
                                    )
  
# estimated loan amounts per state and zip, including averages, with new ranks calculated within this grouped tibble
loanvalue_bystatezip <- adbs %>% 
  group_by(State, Zip) %>%
  summarise(SumLoanRangeMin = sum(LoanRangeMin),
            SumLoanRangeMax = sum(LoanRangeMax),
            SumLoanRangeMid = sum(LoanRangeMid),
            LoanCount = n(),
            AvgLoanMid = SumLoanRangeMid/LoanCount
            ) %>%
  mutate(LoanValueRank = rank(-SumLoanRangeMid, ties.method = "min"),
         AvgLoanRank = rank(-AvgLoanMid, ties.method = "min")) %>% 
  arrange(State,LoanValueRank)


### Example Outputs --------------------------------------------------------

# example output: top and bottom 5 zip codes per state by Average Loan value
a <- loanvalue_bystatezip %>% group_by(State) %>% slice_max(AvgLoanMid, n = 5)
b <- loanvalue_bystatezip %>% group_by(State) %>% slice_min(AvgLoanMid, n = 5)
toptail_avgloan_zips <- rbind(a,b[order(b$LoanValueRank),])
toptail_avgloan_zips <- arrange(toptail_avgloan_zips, State)
# slice out one specific state using filter, and create nicer looking table using knitr
knitr::kable(filter(toptail_avgloan_zips, State == "FL"), digits = 0, format.args = list(big.mark = ",", scientific = FALSE))