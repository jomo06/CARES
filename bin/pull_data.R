### Download data
### kbmorales@protonmail.com

# WIP
# This script will connect to relevant data sources and pull them down

library(googledrive)
library(tidyverse)

# Interactively authenticate to Google Drive
drive_auth()

# PPP Data ----------------------------------------------------------------
# drive_ls("National Press Foundation - DataKind Volunteers/Data/All Data by State") 

# NAICS ----------------------------------------------------------

# Search for shared folder -- takes a minute
drive_download(drive_get("NAICS Codes.csv"),
               path = file.path("data",
                                "Lookup Tables",
                                "NAICS Codes.csv"),
               overwrite = T)
