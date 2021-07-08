nc_gs_w_future <- function() {
  opts <- options(future.globals.maxSize = 850 * 1024 ^ 2)
  on.exit(options(opts))

  # Start parallel backend
  # cl <- parallel::makeCluster(cpus)
  # on.exit(parallel::stopCluster(cl)) # Stop cluster
  doFuture::registerDoFuture()
  # oplan <- future::plan(future::cluster, workers = cl)
  oplan <- future::plan(future::multisession, workers = cpus)
  on.exit(future::plan(oplan), add = TRUE)

  idx <- data.frame(i = seq_len(length(lon$data)),
                    j = rep(seq_along(lat$data), each = length(lon$data)))
  message("Calculating growing season...")
  # Set up progress API
  p <- progressr::progressor(along = seq_len(nrow(idx)))
  browser()
  idx <- idx[1:2000, ]
  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
                               i <- idx$i[k]
                               j <- idx$j[k]
                               p()
                               if (land_mask[i, j]) {
                                 !is.na(filter[i, j, ]) &
                                   !is.null(filter[i, j, ]) &
                                   filter[i, j, ] > thr
                               } else {
                                 rep(FALSE, length(time$data))
                               }
                             }

}
