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

adbs %>% 
  group_by(naics_lvl_1) %>% 
  filter(!str_detect(LoanRange_Unified,
                    "^l|^m|^n|^o|^p")) %>% 
  count(LoanRange_Unified) %>% 
  na.omit() %>% 
  ggplot(aes(x = LoanRange_Unified,
             y = n,
             fill = LoanRange_Unified)) +
  geom_col() +
  facet_wrap(~naics_lvl_1,
             nrow = 5) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        legend.position = 'none') +
  labs(x = "Loan Range",
       y = "# of Loans") +
  scale_fill_viridis_d()

# No orgs in the f or higher loanrange?

adbs %>% 
  filter(is.na(naics_lvl_1)) %>% 
  mutate(DateApproved = as.Date(DateApproved,
                                format="%m/%d/%Y")) %>% 
  group_by(DateApproved) %>% 
  count(NAICSCode) %>% 
  # count(DateApproved) %>% 
  ggplot(aes(x = DateApproved,
             y = n,
             fill = NAICSCode)) +
  geom_area() +
  theme_minimal() +
  scale_x_date(date_breaks = "week",
               date_minor_breaks = "day") +
  theme(legend.position = c(0.8,0.8),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
        ) +
  labs(x = "",
       y = "# of Loans",
       title = "Loans with a missing or 999990 NAICS Code")

# NAICS over time

adbs %>% 
  filter(is.na(naics_lvl_1)) %>% 
  count(NAICSCode) %>% 
  mutate(perc = n / nrow(adbs) * 100)

