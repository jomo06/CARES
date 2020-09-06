### Merge all PPP loan data files from SBA (original source: https://sba.app.box.com/s/tvb0v5i57oa8gc6b5dcm9cyw7y2ms6pp0)
### john.patrick.mccambridge@gmail.com
### This script combines all PPP csvs into a single unified file and create basic needed variables to allow analysis across all fields for all rows

### Working Directory Reminder  ---------------------------------------------

cat(sprintf("This script expects your working directory to be the base directory of the /DataKind-DC/CARES/ github repo structure, i.e., /CARES\nCurrent working directory: %s\n", getwd()))


### Libraries ---------------------------------------------------------------

library("tidyverse")  # merging, manipulating


### Read --------------------------------------------------------------------

# set relative directory to search then scan through subdirectories for CSVs
csv_dir <- paste(getwd(),"/data/All Data 0808", sep="")
cat(sprintf("Looking for data files in: %s\n", csv_dir))
csv_files <- list.files(csv_dir, full.names = T, recursive = T, pattern = ".*.csv") 

# read in each CSV as character values, to allow for a clean import, attach the name of the data source file
adbs <- map_df(csv_files, ~read_csv(.x, col_types = cols(.default = "c")) %>%
                  mutate(source_file = str_remove_all(.x, ".*/"))
               )

### Clean -------------------------------------------------------------------

# Create unified Loan Amount / Loan Range cuts
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

# Create Jobs Retained cuts

adbs$JobsRetained <- "Source Field No Longer Available as of 0808"
adbs$JobsRetained_Grouped <- "Computed Field No Longer Available as of 0808"
  
adbs <- adbs %>%
  mutate(JobsReported_Grouped = case_when(as.numeric(JobsReported) > 400 & as.numeric(JobsReported) <= 500 ~ "a 400 - 500",
                                          as.numeric(JobsReported) > 300 & as.numeric(JobsReported) <= 400 ~ "b 300 - 400",
                                          as.numeric(JobsReported) > 200 & as.numeric(JobsReported) <= 300 ~ "c 200 - 300",
                                          as.numeric(JobsReported) > 100 & as.numeric(JobsReported) <= 200 ~ "d 100 - 200",
                                          as.numeric(JobsReported) >  50 & as.numeric(JobsReported) <= 100 ~ "e  50 - 100",
                                          as.numeric(JobsReported) >  25 & as.numeric(JobsReported) <=  50 ~ "f  25 -  50",
                                          as.numeric(JobsReported) >  10 & as.numeric(JobsReported) <=  25 ~ "g  10 -  25",
                                          as.numeric(JobsReported) >   5 & as.numeric(JobsReported) <=  10 ~ "h   5 -  10",
                                          as.numeric(JobsReported) >   1 & as.numeric(JobsReported) <=   5 ~ "i   2 -   5",
                                          as.numeric(JobsReported) >   0 & as.numeric(JobsReported) <=   1 ~ "j         1",
                                          as.numeric(JobsReported) ==     0                                ~ "k      Zero",
                                          as.numeric(JobsReported) <      0                                ~ "l  Negative",
                                          is.na(JobsReported) ~ NA_character_,
                                          TRUE ~ "Unknown"))   


### Enhance -------------------------------------------------------------------

# Create valid Loan Values for all rows -----------------------------------

# Set numeric min, mid and max values for all loan ranges, keep exact values as-is
adbs <- adbs %>% 
  mutate(LoanRangeMin = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & LoanRange == "a $5-10 million"       ~ as.numeric( 5000000),
                                  is.na(LoanAmount) & LoanRange == "b $2-5 million"        ~ as.numeric( 2000000),
                                  is.na(LoanAmount) & LoanRange == "c $1-2 million"        ~ as.numeric( 1000000),
                                  is.na(LoanAmount) & LoanRange == "d $350,000-1 million"  ~ as.numeric(  350000),
                                  is.na(LoanAmount) & LoanRange == "e $150,000-350,000"    ~ as.numeric(  150000),
                                  TRUE ~ NA_real_))

adbs <- adbs %>% 
  mutate(LoanRangeMax = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & LoanRange == "a $5-10 million"       ~ as.numeric(10000000),
                                  is.na(LoanAmount) & LoanRange == "b $2-5 million"        ~ as.numeric( 5000000),
                                  is.na(LoanAmount) & LoanRange == "c $1-2 million"        ~ as.numeric( 2000000),
                                  is.na(LoanAmount) & LoanRange == "d $350,000-1 million"  ~ as.numeric( 1000000),
                                  is.na(LoanAmount) & LoanRange == "e $150,000-350,000"    ~ as.numeric(  350000),
                                  TRUE ~ NA_real_))

adbs <- adbs %>% 
  mutate(LoanRangeMid = case_when(!is.na(LoanAmount) ~ as.numeric(LoanAmount),
                                  is.na(LoanAmount) & LoanRange == "a $5-10 million"       ~ as.numeric( 7500000),
                                  is.na(LoanAmount) & LoanRange == "b $2-5 million"        ~ as.numeric( 3500000),
                                  is.na(LoanAmount) & LoanRange == "c $1-2 million"        ~ as.numeric( 1500000),
                                  is.na(LoanAmount) & LoanRange == "d $350,000-1 million"  ~ as.numeric(  675000),
                                  is.na(LoanAmount) & LoanRange == "e $150,000-350,000"    ~ as.numeric(  250000),
                                  TRUE ~ NA_real_))


# Rank All by LoanRangeMin  -----------------------------------------------
# we can then subset this at any grain and still get accurate rank order results

adbs$LoanRange_Rank <- rank(-adbs$LoanRangeMin, ties.method = "min") # 1 would be largest value in this case, and will be assigned to all 4,000 or so 5-10million dollar loan entries


# Add NAICS join from Ken Morales
naics_df = read_csv("data/tidy_data/naics_clean.csv", col_types = cols(.default = "c"))

adbs <- adbs %>% left_join(naics_df)

### Tidy Workspace ---------------------------------------------------------

rm(csv_dir,
   csv_files,
   naics_df)
