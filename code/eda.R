### EDA
### kbmorales@protonmail.com

# Data exploration


# Setup -------------------------------------------------------------------

# Join NAICS data
adbs = adbs %>% 
  left_join(naics_df)

glimpse(adbs)

# Check for missingness ---------------------------------------------------

## Missingness summary table
adbs %>% 
  select(-source_file,
         -Zip_Valid_Format,
         -LoanRange_Unified,
         -JobsRetained_Grouped) %>% 
  mutate_all(is.na) %>% 
  summarise_all(~sum(.)) %>% 
  gather("variable", "n_missing") %>% 
  mutate(perc_missing = round(n_missing / nrow(adbs) * 100, 1)) %>% 
  kable()

# EDA ---------------------------------------------------------------------

## Loan range unified
adbs %>% 
  count(LoanRange_Unified) %>% 
  ggplot(aes(x = sort(LoanRange_Unified),
             y = n)
         ) +
  geom_col() +
  coord_flip()

## RaceEthnicity
adbs %>% 
  count(RaceEthnicity) 

## Loan Amount
range(adbs$LoanAmount[!is.na(adbs$LoanAmount)])
# Negative values?

# 72 with negative values
adbs %>% 
  filter(LoanAmount <= 0) %>% 
  summarise(n = n())

adbs %>% 
  filter(LoanAmount > 0) %>% 
  ggplot(aes(x = as.numeric(LoanAmount))) +
  geom_histogram()

## State
adbs %>% 
  count(State) %>% 
  arrange(desc(n)) %>% 
  filter(row_number()<=10) %>% 
  ggplot(aes(x = reorder(State,n),
             y = n)) +
  geom_col()



## Industry
adbs %>% 
  count(naics_lvl_1) %>% 
  ggplot(aes(x = reorder(naics_lvl_1,n),
             y = n)) +
  geom_col() +
  coord_flip() +
  labs(x = "",
       y = "Count") +
  theme_minimal()
