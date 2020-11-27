#' Calculate potential evapotranspiration
#' Calculate potential evapotranspiration in mm using SPLASH V1.0:
#' \url{https://doi.org/10.5281/zenodo.376293}.
#'
#' @importFrom foreach "%dopar%"
#'
#' @param filename String with the output filename (.nc).
#' @param elv 2D structure with elevation data.
#' @param sf 3D structure with sunshine fraction data.
#' @param tmp 3D structure with daily temperature data.
#' @param year Numeric value with the year.
#' @param lat List with latitude \code{data} and variable \code{id}.
#' @param lon List with longitude \code{data} and variable \code{id}.
#' @param cpus Number of CPUs to use for the computation.
#' @param overwrite Boolean flag to indicate if the output file should be
#'     overwritten (if it exists).
#'
#' @export
splash_evap <- function(filename,
                        elv,
                        sf,
                        tmp,
                        year,
                        lat = NULL,
                        lon = NULL,
                        cpus = 2,
                        overwrite = TRUE) {

  if (length(dim(tmp)) != length(dim(sf)) ||
      any(dim(tmp) != dim(sf)))
    stop("The dimensions of tmp and sf must be the same: \n",
         "- tmp: (", paste0(dim(tmp), collapse = ", "), ")\n",
         "- sf: (", paste0(dim(sf), collapse = ", "), ")\n")

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(dim(tmp)[1]),
                    j = rep(seq_along(lat$data), each = dim(tmp)[1]))
  message("Calculating potential evapotranspiration...")

  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
    i <- idx$i[k]
    j <- idx$j[k]
    if (!is.na(elv[i, j])) {
      unlist(lapply(seq_len(dim(tmp)[3]),
                    function(x, i, j) {
                      splash::calc_daily_evap(lat = lat$data[j],
                                              n = x,
                                              elv = elv[i, j],
                                              y = year,
                                              sf = sf[i, j, x],
                                              tc = tmp[i, j, x])$pet_mm
                    }, i = i, j = j))
    } else {
     rep(NA, dim(tmp)[3])
    }
  }

  message("Done calculating potential evapotranspiration.")
  message("Reshaping output...")
  pet <- array(NA, dim = dim(tmp))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    pet[i, j, ] <- output[, k]
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Potential evapotranspiration, calculated as ",
                                 "a function of ",
                                 "latitute, elevation, daily temperature, and ",
                                 "sunshine fraction. The calculations were ",
                                 "done using SPLASH V1.0: ",
                                 "https://doi.org/10.5281/zenodo.376293")
  nc_save(filename = filename,
          var = list(id = "pet",
                     longname = "potential evapotranspiration",
                     missval = -999L,
                     prec = "double",
                     units = "mm",
                     vals = pet),
          lat = list(id = "lat", units = lat$units, vals = lat$data),
          lon = list(id = "lon", units = lon$units, vals = lon$data),
          time = list(calendar = "standard",
                      id = "time",
                      units = "days in a year",
                      vals = seq_len(dim(tmp)[3])),
          var_atts = var_atts,
          overwrite = overwrite)

  message("Done. Bye!")
}

#' Calculate solar declination
#' Calculate solar declination angle in degrees using SPLASH V1.0:
#' \url{https://doi.org/10.5281/zenodo.376293}.
#'
#' @param year Numeric value with the year.
#'
#' @return Numeric vector with the solar declination angle for each day of the
#' given year.
#'
#' @export
#' @examples
#' splash_dcl(1960)
#' splash_dcl(1961)
splash_dcl <- function(year) {
# splash_dcl <- function(filename,
#                        year,
#                        lat = NULL,
#                        lon = NULL,
#                        overwrite = TRUE) {
  # # Check if the spatial dimensions were passed
  # if (is.null(lat))
  #   data("lat", envir = environment())
  # if (is.null(lon))
  #   data("lon", envir = environment())
  # # Load land-sea mask
  # data("land_mask", envir = environment())

  # Adjust the number of days based on the given year
  days <- 365
  if (lubridate::leap_year(as.Date(paste0(year, "-01-01"))))
    days <- days + 1

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # 04. Calculate the declination angle (delta), degrees
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Woolf (1968)
  # Paleoclimate variables:
  ke <- 0.01670       # eccentricity of earth's orbit, 2000CE (Berger 1978)
  keps <- 23.44       # obliquity of earth's elliptic, 2000CE (Berger 1978)
  pir <- pi / 180
  dcl <- c()
  for (n in seq_len(days)) {
    lam <- splash::berger_tls(n, 365)[2]
    dcl <- c(dcl, asin(sin(lam * pir) * sin(keps * pir)) / pir)
  }
  dcl
}

#' Calculate solar declination
#' Calculate solar declination angle in degrees using SPLASH V1.0:
#' \url{https://doi.org/10.5281/zenodo.376293}.
#'
#' @importFrom foreach "%dopar%"
#'
#' @param filename String with the output filename (.nc).
#' @param elv 2D structure with elevation data.
#' @param sf 3D structure with sunshine fraction data.
#' @param tmp 3D structure with daily temperature data.
#' @param year Numeric value with the year.
#' @param lat List with latitude \code{data} and variable \code{id}.
#' @param lon List with longitude \code{data} and variable \code{id}.
#' @param cpus Number of CPUs to use for the computation.
#' @param overwrite Boolean flag to indicate if the output file should be
#'     overwritten (if it exists).
#'
#' @keywords internal
splash_solar <- function(filename,
                         elv,
                         sf,
                         tmp,
                         year,
                         lat = NULL,
                         lon = NULL,
                         cpus = 2,
                         overwrite = TRUE) {
  if (length(dim(tmp)) != length(dim(sf)) ||
      any(dim(tmp) != dim(sf)))
    stop("The dimensions of tmp and sf must be the same: \n",
         "- tmp: (", paste0(dim(tmp), collapse = ", "), ")\n",
         "- sf: (", paste0(dim(sf), collapse = ", "), ")\n")

  # solar_decl <- array(NA, dim = dim(tmp))

  # for (j in seq_along(lat)) {
  #   for (i in seq_len(dim(tmp)[1])) {
  #     if (!is.na(elv[i, j])) {
  #       message(i, ", ", j)
  #       solar_decl[i, j, ] <-
  #         unlist(lapply(seq_len(dim(tmp)[3]),
  #                       function(x, i, j) {
  #                         splash::calc_daily_solar(lat = lat[j],
  #                                                  n = x,
  #                                                  elv = elv[i, j],
  #                                                  y = year,
  #                                                  sf = sf[i, j, x],
  #                                                  tc = tmp[i, j, x])$delta_deg
  #                       }, i = i, j = j))
  #     stop("i: ", i, " j: ", j)
  #     }
  #   }
  # }

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  idx <- data.frame(i = seq_len(dim(tmp)[1]),
                    j = rep(seq_along(lat$data), each = dim(tmp)[1]))
  message("Calculating solar declination...")
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # 04. Calculate the declination angle (delta), degrees
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Woolf (1968)
  # Paleoclimate variables:
  # ke <- 0.01670       # eccentricity of earth's orbit, 2000CE (Berger 1978)
  # keps <- 23.44       # obliquity of earth's elliptic, 2000CE (Berger 1978)
  # pir <- pi / 180
  # lam <- splash::berger_tls(n, 365)[2]
  # delta_deg <- asin(sin(lam * pir) * sin(keps * pir)) / pir

  output <- foreach::foreach(k = seq_len(nrow(idx)),
                             .combine = cbind) %dopar% {
    i <- idx$i[k]
    j <- idx$j[k]
    if (!is.na(elv[i, j])) {
      unlist(lapply(seq_len(dim(tmp)[3]),
                    function(x, i, j) {
                      splash::calc_daily_solar(lat = lat$data[j],
                                               n = x,
                                               elv = elv[i, j],
                                               y = year,
                                               sf = sf[i, j, x],
                                               tc = tmp[i, j, x])$delta_deg
                    }, i = i, j = j))
    } else {
      rep(NA, dim(tmp)[3])
    }
  }

  message("Done calculating solar declination.")
  message("Reshaping output...")
  solar_decl <- array(NA, dim = dim(tmp))
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = nrow(idx), clear = FALSE, width = 60)
  for (k in seq_len(nrow(idx))) {
    pb$tick()
    i <- idx$i[k]
    j <- idx$j[k]
    solar_decl[i, j, ] <- output[, k]
  }

  message("Saving output to netCDF...")
  var_atts <- list()
  var_atts$description <- paste0("Solar declination angle, calculated as a ",
                                 "function of",
                                 "latitute, elevation, daily temperature, and ",
                                 "sunshine fraction. The calculations were ",
                                 "done using SPLASH V1.0: ",
                                 "https://doi.org/10.5281/zenodo.376293")
  nc_save(filename = filename,
          var = list(id = "dcl",
                     longname = "solar declination angle",
                     missval = -999L,
                     prec = "double",
                     units = "degrees",
                     vals = solar_decl),
          lat = list(id = "lat", units = lat$units, vals = lat$data),
          lon = list(id = "lon", units = lon$units, vals = lon$data),
          time = list(calendar = "standard",
                      id = "time",
                      units = "days in a year",
                      vals = seq_len(dim(tmp)[3])),
          var_atts = var_atts,
          overwrite = overwrite)

  message("Done. Bye!")
}
