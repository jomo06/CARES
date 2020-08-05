### Join NAICS to ADBS
### kbmorales@protonmail.com

# This preps the tidy NAICS code data to be joined with PPP loan data, and 
# so prepares it specifically for joining to that specific dataset


# Setup -------------------------------------------------------------------

# Cleans NAICS data prior to joining
# source(file.path("code","naics","naics_clean.R"))

# Handle bad NAICS ---------------------------------------------------------

# Some of the 6-digit NAICS codes in the PPP loan data don't match up to the 
# 2017 NAICS code

naics_fails = adbs %>% 
  anti_join(naics_df) %>% 
  filter(!is.na(NAICSCode)) %>% 
  pull(NAICSCode) %>% 
  unique() %>% 
  sort()

## 999990 appears to be an unknown catch all
# adbs %>% filter(NAICSCode %in% naics_fails) %>% 
#   filter(str_detect(NAICSCode, "^99")) %>% 
#   pull(NAICSCode) %>% 
#   unique() # Only 999990

bad_naics = tibble(NAICSCode = naics_fails,
                   naics_2 = substr(naics_fails, 1,2)) %>% 
  left_join(naics_2L) %>% 
  select(-naics_2) %>% 
  mutate(naics_valid = F)

naics_df = naics_df %>% 
  mutate(naics_valid = T) %>% 
  bind_rows(bad_naics)

# Join --------------------------------------------------------------------

adbs = adbs %>% 
  left_join(naics_df)


# Write -------------------------------------------------------------------

write_csv(adbs,
          "data/tidy_data/adbs_naics.csv")

# Cleanup -----------------------------------------------------------------

rm(bad_naics, naics_2L, naics_fails)

