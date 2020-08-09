### Download NAICS data from Google Drive
### kbmorales@protonmail.com

# This script will connect to relevant data sources and pull them down

library(googledrive)
library(tidyverse)

# Interactively authenticate to Google Drive
drive_auth()

# NAICS ----------------------------------------------------------

# Search for shared folder -- takes a minute
drive_download(drive_get("NAICS Codes.csv"),
               path = file.path("data",
                                "Lookup Tables",
                                "NAICS Codes.csv"),
               overwrite = T)
