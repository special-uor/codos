## code to prepare `ice_core` dataset goes here
# Download the text file
url <- "https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/antarctica2015co2composite.txt"
destfile <- tempfile(fileext = ".txt")
download.file(url, destfile, quiet = TRUE, mode = "wb")
ice_core <- readr::read_tsv(destfile, comment = "#", )
usethis::use_data(ice_core, overwrite = TRUE)
