days <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
cumdays <- cumsum(days)

int_sin <- function(minv,
                    maxv,
                    period = 365,
                    x = period,
                    phi = - pi / 2,
                    plot = FALSE) {
  amplitud <- (maxv - minv) / 2
  mid_point <- (maxv + minv) / 2
  x <- seq_len(x)
  y <- amplitud * sin(2 * pi / period * x + phi) + mid_point
  if (plot) {
    p <- tibble::tibble(x = x,
                   y = y) %>%
    ggplot2::ggplot(ggplot2::aes(x, y)) +
      ggplot2::geom_line() +
      ggplot2::geom_point(data = tibble::tibble(x = 1, y = minv),
                          ggplot2::aes(x, y, colour = "T_djf")) +
                          # colour = "#0080ff") +
      ggplot2::geom_point(data = tibble::tibble(x = period / 2, y = maxv),
                          ggplot2::aes(x, y, colour = "T_jja")) +
                          # colour = "#ff3333") +
      ggplot2::scale_colour_manual(name = "Recon. \nTemp.",
                                   values = c("#0080ff","#ff3333")) +
      ggplot2::labs(x = "[days]",
                    y = "Temp [°C]") +
      ggplot2::theme_bw()
    print(p)
    # plot(x, y, type = "l")
    # points(1, minv, pch = 19, col = "blue")
    # points(period / 2, maxv, pch = 19, col = "red")
  }
  return(invisible(y))
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
#' @param plot Boolean flag, to indicate whether or not a plot should be
#'     displayed.
#'
#' @return Numeric vector with the interpolated function. Same length as
#'    \code{x}. Returned invisibly, so it must be assigned to a variable.
#' @export
#'
#' @examples
#' int_sin(-1, 1)
#' int_sin(-1, 1, plot = TRUE)
#' int_sin(-1, 1, period = 10, plot = TRUE)
int_sin <- function(minv,
                    maxv,
                    period = 365,
                    x = period,
                    phi = - pi / 2,
                    plot = FALSE,
                    minlab = "T_djf",
                    maxlab = "T_jja") {
  amplitud <- (maxv - minv) / 2
  mid_point <- (maxv + minv) / 2
  x <- seq_len(x)
  y <- amplitud * sin(2 * pi / period * x + phi) + mid_point
  if (plot) {
    p <- tibble::tibble(x = x,
                        y = y) %>%
      ggplot2::ggplot(ggplot2::aes(x, y)) +
      ggplot2::geom_line() +
      ggplot2::geom_point(data = tibble::tibble(x = 1, y = minv),
                          ggplot2::aes(x, y, colour = minlab)) +
      ggplot2::geom_point(data = tibble::tibble(x = period / 2, y = maxv),
                          ggplot2::aes(x, y, colour = maxlab)) +
      ggplot2::scale_colour_manual(name = "Recon. \nTemp.",
                                   values = c("#0080ff","#ff3333")) +
      ggplot2::labs(x = "[days]",
                    y = "Temp [°C]") +
      ggplot2::theme_bw()
    print(p)
    # plot(x, y, type = "l")
    # points(1, minv, pch = 19, col = "blue")
    # points(period / 2, maxv, pch = 19, col = "red")
  }
  return(invisible(y))
}

# Calculate anomalies
padul_anomalies <- seq_len(nrow(padul)) %>%
  purrr::map(~int_sin(padul$T_djf[.x] - padul$T_djf[1],
                      padul$T_jja[.x] - padul$T_jja[1]))

out <- int_sin(padul$T_djf[i], padul$T_jja[i])

# Winter months
out[c(1:cumdays[2], cumdays[11]:cumdays[12])]
mean(out[c(1:cumdays[2], cumdays[11]:cumdays[12])])
padul$T_djf[i]
# Summer months
out[cumsum(days)[6]:cumsum(days)[8]]
mean(out[cumsum(days)[6]:cumsum(days)[8]])
padul$T_jja[i]

