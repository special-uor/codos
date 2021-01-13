#' Function to calculate \eqn{u}
#' @details
#' This function is used to optimise values x and y, for the equation to
#' calculate MAT based on GDD0 and MTCO.
#'
#' This equation is only used when MTCO < 0 and GDD0 > 0
#'
#' If MTCO > 0, GDD0 must be > 0, T0 = GDD0 / 2 * pi
#' Units:
#' GDD0 = K rad
#'
#' u = MAT/(MAT-MTCO)
#' @param u \eqn{u}.
#' @param t0 \eqn{GDD0/Tmin}.
#'
#' @return Numeric value
#' @keywords internal
f <- function(u, t0) {
  abs((2 * (u * acos(-u) + sqrt(1 - u ^ 2)) / (1 - u)) + t0)
}


#' Function used to optimise \eqn{u}
#' @importFrom stats optim
#' @param min_u Minimum value for \eqn{u (MAT/(MAT-MTCO))}, numeric, unitless.
#' @param max_u Maximum value for \eqn{u (MAT/(MAT-MTCO))}, numeric, unitless.
#' @param t0 Value for \eqn{GDD0/Tmin}, numeric (radians).
#'
#' @return \eqn{u: MAT / (MAT-MTCO)}.
#' @keywords internal
#'
#' @examples
#' codos:::find_u(-4525.758, -1, 0.9999999)
#' codos:::find_u(-9613.333, -1, 0.9999999)
find_u <- function(t0, min_u = -1, max_u = 0.9999999999999, method = "Brent") {
  optim(par = 0, fn = f, t0 = t0, method = method, lower = min_u, upper = max_u)
}

# find_u2 <- function(t0, min_u = -1, max_u = 0.9999999999999, method = "Brent") {
#   optim(par = 0, fn = function(u, t0) {
#           abs((2 * (u * acos(-u) + sqrt(1 - u ^ 2)) / (1 - u)) - t0)
#         },
#         t0 = t0, method = method, lower = min_u, upper = max_u)
# }
#
# find_u2(629.7071)

#' #' Obtain number of days in a year
#' #'
#' #' @param x Numeric value, year.
#' #'
#' #' @return Number of days in the year.
#' #' @keywords internal
#' days_in_year <- function(x) {
#'   if (lubridate::leap_year(paste0(x, "-01-01")))
#'     return(366)
#'   365
#' }
