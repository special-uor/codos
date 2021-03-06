#' Mean-preserving autoregressive interpolation
#'
#' Interpolate monthly time series to daily using a mean-preserving
#' autoregressive method.
#'
#' This method assumes a cycle (i.e. the last date interpolated influences
#' the first date as well).
#'
#' The idea of how this was done was taken from:
#'
#' - Rymes, M.D. and Myers, D.R., 2001. Mean preserving algorithm for smoothly
#' interpolating averaged data. Solar Energy, 71(4), pp.225-231.
#' DOI/URL: https://doi.org/10.1016/S0038-092X(01)00052-4
#'
#' The method outlined in the paper does not work entirely, and some equations
#' have been tweaked.
#' \eqn{(MN(i) = MN(i) + C(K)} as to \eqn{MN(i) - C(K)} and Equation 8 of
#' the paper.
#'
#' @param y_points Numeric vector with mean values at each timestep.
#' @param month_len Numeric vector with the number of days that each timestep
#'     represents. These can be obtained with \code{\link{days_in_month}} and
#'     \code{\link{retime}}.
#' @param max_val Numeric value with the upper bound for the interpolated
#'     entries.
#' @param min_val Numeric value with the lower bound for the interpolated
#'     entries.
#'
#' @return Numeric vector with the interpolated values, this one has the same
#'     length as the total sum of month_len.
#' @export
#'
#' @examples
#' # month length the data represents
#' month_len = c(31, 29 ,31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
#' y_points <- c(0, 0.1, 0.25, 0.5, 0.9, 1.0, 0.93, 0.8, 0.5, 0.25, 0.1, 0)
#' max_val <- 1
#' min_val <- 0
#' # interpolate with no bounds
#' y_interpolated <- int_acm(y_points, month_len)
#' # interpolate with maximum bounds
#' y_interpolated <- int_acm(y_points, month_len, max_val = max_val)
#' # interpolate with minimum bounds
#' y_interpolated <- int_acm(y_points, month_len, min_val = min_val)
#' # interpolate with bounds
#' y_interpolated <- int_acm(y_points, month_len, max_val, min_val)
#'
#' @author Kamolphat Atsawawaranunt
#' @references
#' Rymes, M.D. and Myers, D.R., 2001. Mean preserving algorithm for smoothly
#' interpolating averaged data. Solar Energy, 71(4), pp.225-231.
#' DOI/URL: https://doi.org/10.1016/S0038-092X(01)00052-4
int_acm <- function(y_points, month_len, max_val = NULL, min_val = NULL) {
  MN <- rep(y_points, times = month_len)
  new_MN <- MN
  # Set up progress bar
  pb <- progress::progress_bar$new(
    format = "(:current/:total) [:bar] :percent",
    total = length(MN), clear = FALSE, width = 60)

  groups <- rep(seq_len(length(month_len)), month_len)
  if (is.null(max_val) && is.null(min_val)) {
    print('interpolating with no bounds')
    for (i in seq_len(length(MN))) {
      pb$tick()
      new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1)) / 3
      new_mean <- unlist(lapply(unname(split(MN - new_MN, groups)), mean))
      Cterm <- rep(new_mean, times = month_len)
      new_MN <- new_MN + Cterm
    }
  }  else if (!is.null(max_val) && !is.null(min_val)) {
    print('interpolating with both minimum and maximum bounds')
    for (i in seq_len(length(MN))) {
      pb$tick()
      new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1)) / 3
      new_mean <- unlist(lapply(unname(split(MN - new_MN, groups)), mean))
      Cterm <- rep(new_mean, times = month_len)
      new_MN <- new_MN + Cterm

      new_MN[new_MN > max_val] <- max_val
      diff <- MN - new_MN
      sum1 <- unlist(lapply(unname(split(max_val - MN, groups)), sum))
      sum2 <- unlist(lapply(unname(split(max_val - new_MN, groups)), sum))
      ls <- sum1 / sum2
      fk <- rep(ls, times = month_len)
      new_MN[diff > 0] <- max_val - fk[diff > 0] * (max_val - new_MN[diff > 0])

      new_MN[new_MN < min_val] <- min_val
      diff <- MN - new_MN
      sum3 <- unlist(lapply(unname(split(new_MN - MN,
                                         rep(seq_len(length(month_len)),
                                             month_len))),
                            sum))
      sum4 <- unlist(lapply(unname(split(new_MN - min_val,
                                         rep(seq_len(length(month_len)),
                                             month_len))),
                            sum))
      ls2 <- sum3/sum4
      fk2 <- rep(ls2, times = month_len)
      new_MN[diff < 0] <- new_MN[diff < 0] - fk2[diff < 0] *
                          (new_MN[diff < 0] - min_val)
    }
  } else if (!is.null(max_val)) {
    print('interpolating with maximum bounds')
    for (i in seq_len(length(MN))) {
      pb$tick()
      new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1)) / 3
      new_mean <- unlist(lapply(unname(split(MN - new_MN, groups)), mean))
      Cterm <- rep(new_mean, times = month_len)
      new_MN <- new_MN + Cterm
      new_MN[new_MN > max_val] <- max_val

      diff <- MN - new_MN
      sum1 <- unlist(lapply(unname(split(max_val - MN, groups)), sum))
      sum2 <- unlist(lapply(unname(split(max_val - new_MN, groups)), sum))
      ls <- sum1 / sum2
      fk <- rep(ls, times = month_len)
      new_MN[diff > 0] <- max_val - fk[diff > 0] * (max_val - new_MN[diff > 0])
    }
  } else if (!is.null(min_val)) {
    print('interpolating with minimum bounds')
    for (i in seq_len(length(MN))) {
      pb$tick()
      new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1)) / 3
      new_mean <- unlist(lapply(unname(split(MN - new_MN, groups)), mean))
      Cterm <- rep(new_mean, times = month_len)
      new_MN <- new_MN + Cterm
      new_MN[new_MN < min_val] <- min_val

      diff <- MN - new_MN
      sum3 <- unlist(lapply(unname(split(new_MN - MN, groups)), sum))
      sum4 <- unlist(lapply(unname(split(new_MN - min_val, groups)), sum))
      ls2 <- sum3 / sum4
      fk2 <- rep(ls2, times = month_len)
      new_MN[diff < 0] <- new_MN[diff < 0] - fk2[diff < 0] *
                          (new_MN[diff < 0] - min_val)
    }
  }
  # tibble::tibble(time = unlist(lapply(month_len, seq_len)),
  #                mean = new_MN)
  new_MN
}

#' Simplified version of \code{\link{int_acm}}
#'
#' @inheritParams int_acm
#'
#' @return @return Numeric vector with the interpolated values, this one has the same
#'     length as the total sum of month_len.
#' @keywords internal
#' @noRd
int_acm2 <- function(y_points, month_len) {
  MN <- rep(y_points, times = month_len)
  new_MN <- MN

  groups <- rep(seq_len(length(month_len)), month_len)
  for (i in seq_len(length(MN))) {
    new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1)) / 3
    new_mean <- unlist(lapply(unname(split(MN - new_MN, groups)), mean))
    Cterm <- rep(new_mean, times = month_len)
    new_MN <- new_MN + Cterm
  }
  new_MN
}

#' Sinusoidal interpolation
#'
#' Create sinusoidal interpolation based on two values, \code{minv} and
#' \code{maxv}. The lower and upper bounds/peaks of the function.
#'
#' @param minv Numeric value, used as the lower bound.
#' @param maxv Numeric value, used as the upper bound.
#' @param period Numeric value, period width (e.g. 365 days).
#' @param x Numeric value, number of partitions to use.
#' @param phi Numeric value, phase shift.
#'
#' @return Numeric vector with the interpolated function. Same length as
#'    \code{x}. Returned invisibly, so it must be assigned to a variable.
#' @export
#'
#' @examples
#' int_sin(-1, 1)
#' int_sin(-1, 1, period = 10)
int_sin <- function(minv,
                    maxv,
                    period = 365,
                    x = period,
                    phi = - pi / 2) {
  amplitud <- (maxv - minv) / 2
  mid_point <- (maxv + minv) / 2
  x <- seq_len(x)
  y <- amplitud * sin(2 * pi / period * x + phi) + mid_point
  return(invisible(y))
}

#' Monthly to daily interpolation
#'
#' @importFrom foreach "%dopar%"
#' @param data Numeric vector with monthly entries.
#' @param time Numeric vector with the days in month for a particular time step.
#' @param cpus Numeric value with the number of CPUs to use for the computation.
#' @param thr Numeric value with the temporal length of the output, in months.
#'
#' @return Numeric value for the daily values interpolated.
#' @keywords internal
m2d <- function(data, time, cpus = 2, thr = 12) {
  # Local binding
  i <- NULL

  if (min(time) < 1 | max(time) > 31)
    stop("The time vector must contain values between 1 and 31, corresponding ",
         "to the days in each month. Use the following functions to compute ",
         "these values: days_in_month and retime.", call. = FALSE)
  if (length(data) != length(time))
    stop("The length of both data and time should be the same")

  # Check the number of CPUs does not exceed the availability
  avail_cpus <- parallel::detectCores() - 1
  cpus <- ifelse(cpus > avail_cpus, avail_cpus, cpus)

  # Start parallel backend
  cl <- parallel::makeCluster(cpus)
  on.exit(parallel::stopCluster(cl)) # Stop cluster
  doParallel::registerDoParallel(cl)

  breaks <- seq(0, length(data), thr)[-1]
  idx <- seq_len(length(breaks))
  foreach::foreach(i = idx, .combine = c) %dopar% {
    int_acm(data[(breaks[i] - (thr - 1)):breaks[i]],
            time[(breaks[i] - (thr - 1)):breaks[i]])
  }
}

#' Shift vector
#'
#' Shift vector by \code{n} positions.
#'
#' @param x Numeric vector.
#' @param n Number of positions.
#' @param invert Boolean flag to indicate if the vector should be inverted.
#'
#' @return Shifted numeric vector.
#' @keywords internal
#' @noRd
#'
#' @examples
#' shift(c(1:10), 2)
#'
#' @author Kamolphat Atsawawaranunt
#' @references https://stackoverflow.com/questions/26997586/shifting-a-vector
shift <- function(x, n, invert = FALSE) {
  stopifnot(length(x) >= n)
  if (n == 0)
    return(x)
  n <- ifelse(invert, -n, n)
  forward <- TRUE
  if (n < 0) {
    n <- abs(n)
    forward = FALSE
  }
  if (forward) {
    return(c(x[seq(length(x) - n + 1, length(x))], x[seq_len(length(x) - n)]))
  } else {
    return(c(x[seq(n + 1, length(x))], x[1:n]))
  }
}
