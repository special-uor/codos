#' @keywords internal
"_PACKAGE"

#' Stomatal sensitivity factor, E (\code{sqrt(Pa)})
#' @param Tc Numeric value of temperature (°C).
#' @param beta Numeric constant, default = 146.
#'
#' @return Numeric value of stomatal sensitivity factor.
#' @keywords internal
E <- function(Tc, beta = 146) {
  sqrt(beta * (K(Tc) + compensation_point(Tc)) / (1.6 * eta(Tc) / eta(25)))
}

#' Effective Michaelis constant of Rubisco (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param dHc Carbon activation energy (J mol^-1), default = 79430.
#' @param dHo Oxygen activation energy (J mol^-1), default = 36380.
#' @param O Atmospheric concentration of oxygen (Pa), default = 21278.
#' @param R Universal gas constant (J mol^-1 K^-1), default = 8.314.
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of effective Michaelis constant of Rubisco.
#' @keywords internal
K <- function(Tc, dHc = 79430, dHo = 36380, O = 21278, R = 8.314) {
  pre_calc <- 1 / R * (1 / 298 - 1 / (Tc + 273.15))
  39.97 * exp(dHc * pre_calc) * ( 1 + O / (27480 * exp(dHo * pre_calc)))
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
#' @keywords internal
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
#' @keywords internal
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

#' Budyko relationship
#'
#' Budyko relationship, obtain alpha from moisture index (MI).
#'
#' @param mi Numeric value with moisture index.
#'
#' @return Numeric value with alpha.
#' @keywords internal
alpha_from_mi_om3 <- function(mi) {
  1 + mi - (1 + mi ^ 3) ^ (1/3)
}

#' Ratio of leaf-internal to ambient CO2 partial pressures (–)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index (-).
#' @param co2 Numeric value of CO2 partial pressure (umol/mol).
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of ratio of leaf-internal to ambient CO2 partial
#' pressures.
#' @keywords internal
chi <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
  co2 <-  scale_factor * co2
  E(Tc) / (E(Tc) + sqrt(vpd_internal(Tc, MI))) * (1 - compensation_point(Tc) / co2) +
    compensation_point(Tc) / co2
}

#' Photorespiratory compensation point (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param delta_H Compensation point activation energy (J mol^-1), default =
#'     37830.
#' @param R Universal gas constant (J mol^-1 K^-1), default = 8.314.
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value of photorespiratory compensation point.
#' @keywords internal
compensation_point = function(Tc,
                              delta_H = 37830,
                              R = 8.314,
                              scale_factor = 101.325 * 10^-3) {
  aux <- delta_H / R
  42.75 * exp(aux * (1 / 298 - 1 / (Tc + 273.15))) * scale_factor
}

#' Viscosity of water
#'
#' @param Tc Numeric value of temperature (°C).
#'
#' @return Numeric value of viscosity of water.
#' @keywords internal
eta = function(Tc) {
  0.024258 * exp(580 / (Tc + 273.15 + 138))
}

#' f(T, m, ca) (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index (-).
#' @param co2 Numeric value of CO2 partial pressure (umol/mol).
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#'
#' @return Numeric value.
#' @keywords internal
f <- function(Tc, MI, co2, scale_factor = 101.325 * 10^-3) {
  co2 <- scale_factor * co2
  vpd_internal(Tc, MI) / (co2 * (1 - chi(Tc, MI, co2 / scale_factor)))
  # (E(Tc) * sqrt(vpd_internal(Tc, MI)) + vpd_internal(Tc, MI)) / (co2 - compensation_point(Tc))
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

#' Find past CO2
#'
#' Find past CO2 linked to a given \code{age}.
#'
#' @param age Numeric value with the \code{age}.
#' @param ref Reference data frame containing ice core composite
#'     information, defaults to \code{codos::ice_core}:
#'
#' Bereiter, B., Eggleston, S., Schmitt, J., Nehrbass‐Ahles, C., Stocker, T. F.,
#' Fischer, H., Kipfstuhl, S., and Chappellaz, J. (2015), Revision of the EPICA
#' Dome C CO2 record from 800 to 600 kyr before present, Geophys. Res. Lett.,
#' 42, 542– 549, <doi:10.1002/2014GL061957>.
#' @param digits Number of significant digits used to match \code{age} to
#'     the age values in \code{ref}.
#' @param use_loess Boolean flag to indicate whether to use a LOESS smoothing
#'     (\code{TRUE}) or use adjacent records to find the corresponding value of
#'     CO2 (\code{FALSE}).
#' @param ... Extra arguments passed to \code{\link[stats:loess]{stats::loess}}.
#'
#' @return Numeric value of CO2 linked to the given \code{age}.
#' @export
#'
#' @examples
#' codos::past_co2(-47)
#' codos::past_co2(-47, use_loess = TRUE)
#' codos::past_co2(-47, use_loess = TRUE, span = 0.05)
past_co2 <- function(age,
                     ref = codos::ice_core,
                     digits = 2,
                     use_loess = FALSE,
                     ...) {
  if (use_loess)
    return(past_co2_loess(age = age,
                          ref = ref,
                          digits = digits,
                          ...))

  # Check the reference tibble, must have at least two columns
  if (ncol(ref) < 2)
    stop("The `ref` data frame, must have at least two columns: ",
         "`age` and `co2`.", call. = FALSE)
  # Extract the reference age and co2
  ref_age <- purrr::pluck(ref, 1)
  ref_co2 <- purrr::pluck(ref, 2)
  # Check for exact match, rounding to `digits`
  if (any(round(ref_age, digits) == age))
    return(ref_co2[round(ref_age, digits) == age])
  # Sort by age, ascending
  idx <- order(ref_age)
  ref_age <- ref_age[idx]
  ref_co2 <- ref_co2[idx]
  # Find the nearest ref_age to the given age
  idx <- sort(order(abs(ref_age - age))[1:2])
  down <- idx[1]
  up <- idx[2]
  if ((abs(age) > abs(ref_age[down]) & age < 0) |
      (abs(age) < abs(ref_age[down]) & age > 0))
    return(ref_co2[down])
  if ((abs(age) < abs(ref_age[up]) & age < 0) |
      (abs(age) > abs(ref_age[up]) & age > 0))
    return(ref_co2[up])
  return(mean(ref_co2[c(down, up)]))
}

#' Find past CO2 using \code{loess}
#'
#' Find past CO2 linked to a given \code{age} using \code{loess}.
#'
#' @importFrom stats loess predict
#' @inheritParams past_co2
#' @param span Numeric value, \eqn{\alpha}, which controls the degree of
#' smoothing.
#' @param ... Extra arguments passed to \code{\link[stats:loess]{stats::loess}}.
#'
#' @return Numeric value of CO2 linked to the given \code{age}.
#' @keywords internal
past_co2_loess <- function(age, ref = codos::ice_core, span = 0.1, ...) {
  # Check the reference tibble, must have at least two columns
  if (ncol(ref) < 2)
    stop("The `ref` data frame, must have at least two columns: ",
         "`age` and `co2`.", call. = FALSE)
  # Extract the reference age and co2
  ref_age <- purrr::pluck(ref, 1)
  ref_co2 <- purrr::pluck(ref, 2)
  loessMod10 <- loess(co2 ~ age,
                      tibble::tibble(age = ref_age,
                                     co2 = ref_co2), span = span, ...)
  return(predict(loessMod10, age))
}

#' Calculate corrected moisture index (MI)
#'
#' Calculate corrected moisture index (MI) based on reconstructed MI, CO2 and
#' temperature, past and modern.
#'
#' @inheritParams vpd
#' @inheritDotParams vpd
#'
#' @return Numeric vector with corrected moisture index values.
#' @export
corrected_mi <- function(Tc0, Tc1, MI, ca0, ca1, ...) {
  # terms <- list(a = 4.61232447483209,
  #               kTmp = 0.0609249286877394,
  #               kMI = 0.872588565709498)
  terms <- list(a = 4.58914835462018,
                kTmp = 0.0611076815696193,
                kMI = 0.870229500285838)
  vpd <- vpd(Tc0, Tc1, MI, ca0, ca1, ...) / 100
  with(terms, (log(vpd / a) - kTmp * Tc1) / (-kMI))
}

#' Vapour-pressure deficit (Pa)
#'
#' @param Tc Numeric value of temperature (°C).
#' @param MI Numeric value of moisture index.
#' @param scale_factor Scale factor to transform the output, default =
#'     100 Pa/hPa.
#'
#' @return Numeric value of vapour-pressure deficit.
#' @keywords internal
vpd_internal <- function(Tc, MI, scale_factor = 100) {
  # terms <- list(a = 4.61232447483209,
  #               kTmp = 0.0609249286877394,
  #               kMI = 0.872588565709498)
  terms <- list(a = 4.58914835462018,
                kTmp = 0.0611076815696193,
                kMI = 0.870229500285838)
  with(terms, a * exp(kTmp * Tc - kMI * MI)) * scale_factor
}

#' Vapour-pressure deficit (Pa)
#'
#' @param Tc0 Numeric vector with present temperature values (°C).
#' @param Tc1 Numeric vector with past temperature values (°C).
#' @param MI Numeric vector with reconstructed moisture index values (-).
#' @param ca0 Numeric vector of 'recent' CO2 partial pressures (umol/mol).
#' @param ca1 Numeric vector of past CO2 partial pressures (umol/mol).
#' @param scale_factor Scale factor to transform the output, default =
#'     101.325 Pa/ppm at standard sea level pressure.
#' @return Numeric vector with vapour-pressure deficit values.
#' @export
vpd <- function(Tc0, Tc1, MI, ca0, ca1, scale_factor = 101.325 * 10^-3) {
  ca0 <- scale_factor * ca0
  ca1 <- scale_factor * ca1
  f0 <- vpd_internal(Tc0, MI) / (ca0 * (1 - chi(Tc0, MI, ca0 / scale_factor)))

  purrr::map_dbl(seq_len(length(Tc1)),
                 function (i) {
                   optim(par = 0,
                         function(x, kE, val) abs(kE * sqrt(x) + x - val),
                         kE = E(Tc1[i]),
                         val = f0[i] * (ca1[i] - compensation_point(Tc1[i])),
                         method = "Brent",
                         lower = 0,
                         upper = 10^6)$par
                 })
}
