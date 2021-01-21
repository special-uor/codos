## code to prepare the `land_mask` dataset
# Use the `tmn` as reference to find land_mask
filename <- "~/Downloads/CRU/cru_ts4.04.1901.2019.tmn.dat.nc"
tmn <- codos:::nc_var_get(filename, "tmn")
ref <- tmn$data
tictoc::tic()
out <- purrr::map2_lgl(rep(seq_len(nrow(ref)), each = ncol(ref)),
                       rep(seq_len(ncol(ref)), times = nrow(ref)),
                       function(i, j) any(!is.na(ref[i, j, ])))
tictoc::toc()
land_mask <- matrix(out, nrow = nrow(ref), ncol = ncol(ref), byrow = TRUE)

# Double check using a different variable, `vap`
filename2 <- "~/Downloads/CRU/cru_ts4.04.1901.2019.vap.dat.nc"
vap <- codos:::nc_var_get(filename2, "vap")
ref2 <- vap$data
tictoc::tic()
out2 <- purrr::map2_lgl(rep(seq_len(nrow(ref2)), each = ncol(ref2)),
                        rep(seq_len(ncol(ref2)), times = nrow(ref2)),
                        function(i, j) any(!is.na(ref2[i, j, ])))
tictoc::toc()

land_mask2 <- matrix(out2, nrow = nrow(ref2), ncol = ncol(ref2), byrow = TRUE)

# Check that both masks have the same number of `TRUE` values, land
sum(land_mask) == sum(land_mask2)
# Check that both masks are exactly the same.
sum(land_mask == land_mask2) == length(land_mask)
# image(lon$data, lat$data, land_mask)
usethis::use_data(land_mask, overwrite = TRUE)
