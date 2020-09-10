### NAICS setup script
### kbmorales@protonmail.com

# Setup -------------------------------------------------------------------

library(tidyverse)
library(readxl)

# Read --------------------------------------------------------------------

# source: 

naics_2017 = read_excel(here::here("data",
                                 "Lookup Tables",
                                 "naics_raw",
                                 "2-6 digit_2017_Codes.xlsx"),
                        skip = 2, col_names = F) %>% 
  select(NAICSCode = 2,
         Industry = 3) %>% 
  mutate(naics_version = 2017)

naics_2012 = read_excel(here::here("data",
                                 "Lookup Tables",
                                 "naics_raw",
                                 "2-digit_2012_Codes.xls"),
                        skip = 2, col_names = F) %>% 
  select(NAICSCode = 2,
         Industry = 3) %>% 
  mutate(naics_version = 2012)

naics_2007 = read_excel(here::here("data",
                                   "Lookup Tables",
                                   "naics_raw",
                                   "naics07.xls"),
                        skip = 2, col_names = F) %>% 
  select(NAICSCode = 2,
         Industry = 3) %>% 
  mutate(naics_version = 2007)

naics_2002 = read_tsv(here::here("data",
                                 "Lookup Tables",
                                 "naics_raw",
                                 "naics_2_6_02.txt"),
                      col_names = F,
                      skip = 5,
                      skip_empty_rows = T) %>% 
  separate(X1, into = c("NAICSCode", "Industry"),sep="\\s+",
           extra = "merge") %>% 
  mutate(naics_version = 2002)

# Clean -------------------------------------------------------------------

# clean NAICS data to prep for join to PPP data
# Aligns all industry definition levels to 6L length NAICS codes

# Reconfigure

## This will be master list
naics_6L = naics %>% 
  filter(str_length(NAICSCode) == 6) %>% 
  rename(naics_lvl_5 = Industry) %>% 
  ## Temp joining cols
  mutate(naics_2 = str_trunc(NAICSCode, 2, ellipsis = ""),
         naics_3 = str_trunc(NAICSCode, 3, ellipsis = ""),
         naics_4 = str_trunc(NAICSCode, 4, ellipsis = ""),
         naics_5 = str_trunc(NAICSCode, 5, ellipsis = "")) 

## Higher level industry codes
naics_2L = naics %>% 
  filter(str_length(NAICSCode) == 2 | 
           str_detect(NAICSCode,"\\d{2}-\\d{2}")) %>% # Find ranges
  rename(naics_2 = NAICSCode,
         naics_lvl_1 = Industry)

### Handle ranges in naics_2L
naics_2L_rng = naics_2L %>%
  filter(str_detect(naics_2,"\\d{2}-\\d{2}"))

naics_2L_fix = tibble(naics_2 = as.character(c(seq(31,33),44,45,48,49)),
                      naics_lvl_1 = c(rep("Manufacturing", 3),
                                      rep("Retail Trade", 2),
                                      rep("Transportation and Warehousing", 2))
)

naics_2L = naics_2L %>%
  filter(!str_detect(naics_2,"\\d{2}-\\d{2}")) %>% 
  bind_rows(naics_2L_fix) %>% 
  arrange(naics_2)

naics_3L = naics %>% 
  filter(str_length(NAICSCode) == 3) %>% 
  rename(naics_3 = NAICSCode,
         naics_lvl_2 = Industry)

naics_4L = naics %>% 
  filter(str_length(NAICSCode) == 4) %>% 
  rename(naics_4 = NAICSCode,
         naics_lvl_3 = Industry)

naics_5L = naics %>% 
  filter(str_length(NAICSCode) == 5) %>% 
  rename(naics_5 = NAICSCode,
         naics_lvl_4 = Industry)

## Join together and tidy
naics_df = naics_6L %>% 
  left_join(naics_2L) %>% 
  left_join(naics_3L) %>% 
  left_join(naics_4L) %>% 
  left_join(naics_5L) %>% 
  select(NAICSCode,
         naics_lvl_1,
         naics_lvl_2,
         naics_lvl_3,
         naics_lvl_4,
         naics_lvl_5)

# Export

# Validate
# naics_df %>% 
#   mutate_all(is.na) %>% 
#   summarise_all(~sum(.))

if(!dir.exists(file.path("data", "tidy_data"))) {
  dir.create(file.path("data", "tidy_data"))
}

write_csv(naics_df,
          "data/tidy_data/naics_clean.csv")

# Cleanup 

rm(naics, naics_2L_rng, naics_2L_fix, naics_3L, naics_4L, 
   naics_5L, naics_6L)

join

# Join --------------------------------------------------------------------

# Some of the 6-digit NAICS codes in the PPP loan data don't match up to the 
# 2017 NAICS code

naics_fails = adbs_raw %>% 
  anti_join(naics_df, by = "NAICSCode") %>% count() 
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

# Join 

adbs = adbs %>% 
  left_join(naics_df)

# Write 

write_csv(adbs,
          here::here("data", "tidy_data",
                     "adbs_naics.csv"))

# Cleanup 

rm(bad_naics, naics_2L, naics_fails)