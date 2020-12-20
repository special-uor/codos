#' Budyko relationship
#'
#' Budyko relationship, obtain alpha from moisture index (MI).
#'
#' @param mi Numeric value with moisture index.
#'
#' @return Numeric value with alpha.
#' @export
alpha_from_mi_om3 <- function(mi) {
  1 + mi - (1 + mi ^ 3) ^ (1/3)
}

#' Fraction of sunshine hours
#'
#' @details
#' Given by (2.5):
#' \eqn{S_f = 0.6611 e^{-0.74m} + 0.2175}.
#'
#' @param m Numeric value for moisture index.
#'
#' @return Fraction of sunshine hours.
#' @references
#' I.C. Prentice, S.F. Cleator, Y.H. Huang, S.P. Harrison, I. Roulstone,
#' "Reconstructing ice-age palaeoclimates: Quantifying low-CO2 effects on
#' plants", Global and Planetary Change, Volume 149, 2017, Pages 166-176,
#' DOI: \url{https://doi.org/10.1016/j.gloplacha.2016.12.012}.
#' @export
S_f <- function(m) {
  0.6611 * exp(-0.74 * m) + 0.2175
}

#' Mean daytime air temperature
#'
#' Mean daytime air temperature (\eqn{T_g}) was estimated for each month by
#' assuming the diurnal temperature cycle to follow a sine curve, with daylight
#' hours determined by latitude and month.
#'
#' @details
#' Given by (7):
#'
#' \eqn{T_g = T_{max}\left[\frac{1}{2} +
#'                         \frac{(1-x^2)^{1/2}}{2 \cos^{-1}{x}}\right] +
#'            T_{min}\left[\frac{1}{2} -
#'                         \frac{(1-x^2)^{1/2}}{2 \cos^{-1}{x}}\right]}
#'
#' where
#'
#' \eqn{x = -\tan{\lambda}\tan{\delta}}.
#'
#' @param lat Latitude (\eqn{\lambda}).
#' @param delta Monthly average solar declination (\eqn{\delta}).
#' @param tmx Maximum value of temperature (\eqn{T_{max}}).
#' @param tmn Minimum value of temperature (\eqn{T_{min}}).
#'
#' @return Mean daytime air temperature.
#' @export
T_g <- function(lat, delta, tmx, tmn) {
  x <- tan(lat) * tan(delta)
  if (x >= 1) { # Polar day, no sunset
    x <- cos(pi)
  } else if (x <= -1) { # Polar night, no sunrise
    x <- cos(0)
  } else {
    x <- -x
  }
  tmx * (0.5 + sqrt(1 - x^2) / (2 * acos(x))) +
    tmn * (0.5 - sqrt(1 - x^2) / (2 * acos(x)))
}
