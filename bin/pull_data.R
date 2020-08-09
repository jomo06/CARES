### Download data
### kbmorales@protonmail.com

# WIP
# This script will connect to relevant data sources and pull them down

library(googledrive)
library(tidyverse)

# Interactively authenticate to Google Drive
drive_auth()

# PPP Data ----------------------------------------------------------------
files_ls <- drive_ls("National Press Foundation - DataKind Volunteers/Data/All Data by State", recursive = TRUE) 
csv_ls <- files_ls[str_ends(files_ls$name, ".csv"),]

for (i in 1:nrow(csv_ls)) {
    drive_download(csv_ls[i,], 
                   path = file.path("data",
                                    "All Data By State",
                                    csv_ls[i, "name"]), 
                   overwrite = TRUE)  
}
