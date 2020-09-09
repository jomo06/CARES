#' NAICS downloading, processing, joining scripts
#' Note: currently only downloads 2017
#' 
#' @author kbmorales at protonmail dot com

naics_collect = function(){

  # Downloads final NAICS file from DataKind Google Drive
  # Ready for joining with PPP data

  cat("This will save data to ~/data/tidy_data\n")
  # cat('It will download over 600 MB of files.\n')
  cat('Any existing files will be overwritten.\n')

  proceed = menu(c("Yes", "Cancel"),
                 title = "Proceed?")

  if (proceed!=1) stop("Canceling download.")

  datapath = 'data/tidy_data'
  if (!dir.exists(datapath)) dir.create(datapath,recursive = T)

  # Search for shared folder -- takes a minute
  drive_download(drive_get("adbs_naics.csv"),
                 path = file.path("data",
                                  "tidy_data",
                                  "naics_clean.csv"),
                 overwrite = T)
}
