### Download data
### kbmorales@protonmail.com

# This script will authenticate with Google Drive to download a version of
# the PPP data from the DataKind Team Drive

library(googledrive)
library(tidyverse)

# Interactively authenticate to Google Drive
drive_auth()

# Source helper files
source(here::here("code","collect.R"))

ppp_collect()
