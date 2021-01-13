## code to prepare the `lat` dataset
lat <- list(data = seq(-89.75, 89.75, 0.5),
            id = "lat",
            longname = "latitude",
            units = "degrees_north")

usethis::use_data(lat, overwrite = TRUE, internal = TRUE)
