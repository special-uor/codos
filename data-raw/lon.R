## code to prepare the `lon` dataset
lon <- list(data = seq(-179.75, 179.75, 0.5),
            id = "lon",
            longname = "longitude",
            units = "degrees_east")

usethis::use_data(lon, overwrite = TRUE, internal = TRUE)
