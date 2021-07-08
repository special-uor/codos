#' Calculate the Mean Annual Temperature (MAT)
#'
#' Calculate the Mean Annual Temperature (MAT) from Growing Degree Days above
#' 0 °C (GDD0) and Mean Temperature of the Coldest Month (MTCO).
#'
#' @importFrom magrittr `%>%`
#' @inheritParams gsl
#'
#' @return Numeric vector with Mean Annual Temperature (MAT) data.
#' @export
mat <- function(gdd0, mtco) {
  GDD0 <- gdd0
  MTCO <- mtco # Tmin
  MAT <- rep(NA, length(GDD0))
  # ============================================================================
  # If Tmin >= 0 MAT = GDD0/(2*pi)
  # ============================================================================
  MAT[MTCO >= 0] <- GDD0[MTCO >= 0] / (2 * pi)
  # ============================================================================
  # If Tmin < 0 and GDD0 = 0, MAT = less than Tmin/2 but cannot be accurately
  # determined
  # ============================================================================
  if (length(MTCO[(MTCO < 0) & (GDD0 == 0.0)]) > 0)
    message("There are values where MTCO < 0 and GDD0 = 0. ",
            "Only the maximum MAT can be determined (Tmin/2). ",
            "Return -9999 as values")
  MAT[(MTCO < 0) & (GDD0 == 0.0)] <- -9999
  # ============================================================================
  # If Tmin >= 0 and GDD0 = 0, something is fishy
  # ============================================================================
  if (length(MAT[(MTCO >= 0) & (GDD0 == 0.0)]) > 0)
    message("There seems to be some values where Tmin >= 0 and GDD0 = 0; ",
            "This is very fishy and should never happen (would mean that ",
            "MTCO was not really MTCO)")
  # ============================================================================
  # If Tmin < 0 and GDD0 > 0, MAT can be calculated using the optimise method
  # ============================================================================
  t0 <- GDD0 / MTCO
  min_u <- -1 # minimum valid value for 'u' is -1
  max_u <- 0.9999999999 # maximum valid value for 'u' is 1

  t0_input <- t0[(MTCO < 0) & (GDD0 > 0)]

  u <- t0_input %>%
    purrr::map(find_u,
               min_u = min_u,
               max_u = max_u,
               method = "Brent") %>%
    purrr::transpose("par") %>%
    purrr::pluck("par") %>%
    purrr::flatten_dbl()

  MAT[(MTCO < 0) & (GDD0 > 0)] <- -MTCO[(MTCO < 0) & (GDD0 > 0)] * u / (1 - u)
  MAT
}

#' Calculate the Growing Season Length (GSL)
#'
#' Calculate the Growing Season Length (GSL) from Growing Degree Days above 0 °C
#' (GDD0) and Mean Temperature of the Coldest Month (MTCO).
#'
#' @importFrom magrittr `%>%`
#' @param gdd0 Numeric vector with Growing Degree Days above 0 °C (GDD0) data.
#' @param mtco Numeric vector with Mean Temperature of the Coldest Month (MTCO)
#'     data.
#'
#' @return Numeric vector with Growing Season Length (GSL) data.
#' @export
#'
# @examples
# gsl(20, 5)
gsl <- function(gdd0, mtco) {
  GDD0 <- gdd0
  MTCO <- mtco # Tmin
  # Calculate `u` for all values pf `GDDD0 / MTCO`:
  x <- GDD0 / MTCO
  x[x > 0] <- -x[x > 0]
  u <- x %>%
    purrr::map(find_u) %>%
    purrr::transpose("par") %>%
    purrr::pluck("par") %>%
    purrr::flatten_dbl()

  # Calculate growing season length (GSL):
  (365 / pi) * acos(-u)
}
