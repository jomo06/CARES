### Clean NAICS codes
### kbmorales@protonmail.com

# clean NAICS data to prep for join to PPP data
# Aligns all industry definition levels to 6L length NAICS codes

# Setup -------------------------------------------------------------------

library(tidyverse)

# Only run once to read in data
# source(file.path("bin", "pull_data.R"))

naics = read_csv(file.path("data",
                           "Lookup Tables",
                           "NAICS Codes.csv"))

# Clean -------------------------------------------------------------------

naics = naics[,1:2] # trim empty cols

# Rename for join
naics = naics %>% 
  rename(NAICSCode = NAICS) 


# Reconfigure -------------------------------------------------------------

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

# Export ------------------------------------------------------------------

# Validate
# naics_df %>% 
#   mutate_all(is.na) %>% 
#   summarise_all(~sum(.))

if(!dir.exists(file.path("data", "tidy_data"))) {
  dir.create(file.path("data", "tidy_data"))
}

write_csv(naics_df,
          "data/tidy_data/naics_clean.csv")

# Cleanup -----------------------------------------------------------------

rm(naics, naics_2L_rng, naics_2L_fix, naics_3L, naics_4L, 
   naics_5L, naics_6L)
