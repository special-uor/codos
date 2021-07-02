## code to prepare the `ice_mask` dataset
# Download and uncompress the source netCDF file
url <- "https://www.atmosp.physics.utoronto.ca/~peltier/datasets/Ice7G_NA_VM7/I7G_NA.VM7_1deg.0.nc.gz"
destfile <- tempfile(fileext = ".nc.gz")
download.file(url, destfile, quiet = TRUE, mode = "wb")
R.utils::gunzip(destfile)
ncfile <- gsub(".gz$", "", destfile)
stgit_original <- codos:::nc_var_get(ncfile, "stgit")$data
# Re-grid original data to 0.5x0.5
ncfile2 <- tempfile(fileext = ".nc")
codos:::nc_regrid(ncfile, "stgit", NULL, "lat", "lon", c(0.5, 0.5), ncfile2)
stgit <- codos:::nc_var_get(ncfile2, varid = "stgit")
# Create ice mask as a boolean matrix with TRUE for grid cells with any ice
ice_mask <- matrix(FALSE, nrow = nrow(stgit$data), ncol = ncol(stgit$data))
ice_mask[stgit$data > 0] <- TRUE
# Create the dataset
usethis::use_data(ice_mask, overwrite = TRUE, internal = TRUE)
# Delete temporal files
unlink(ncfile)
unlink(ncfile2)
image(codos::lon$data, codos::lat$data, stgit)

codos:::nc_save_timeless(filename = "ice-mask.nc",
                         var = list(id = "ice mask",
                                    longname = "ice mask",
                                    missval = -999L,
                                    prec = "double",
                                    units = "-",
                                    vals = ice_mask),
                         lat = list(id = "lat", units = "degrees_north", vals = lat$data),
                         lon = list(id = "lon", units = "degrees_east", vals = lon$data),
                         var_atts = NULL,
                         overwrite = TRUE)
