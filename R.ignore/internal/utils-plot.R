#' Format latitude labels
#'
#' @param x Latitude numeric value.
#'
#' @return String with latitude and corresponding direction suffix.
#' @keywords internal
#'
#' @examples
#' codos:::lat_lab(-30)
#' codos:::lat_lab(30)
lat_lab <- function(x) {
  ifelse(x < 0,
         paste(x, "°S"),
         ifelse(x > 0,
                paste(x, "°N"),
                x))
}

#' Format longitude labels
#'
#' @param x Longitude numeric value.
#'
#' @return String with longitude and corresponding direction suffix.
#' @keywords internal
#'
#' @examples
#' codos:::lon_lab(-30)
#' codos:::lon_lab(30)
lon_lab <- function(x) {
  ifelse(x < 0,
         paste(x, "°E"),
         ifelse(x > 0,
                paste(x, "°W"),
                x))
}

#' Compare time series
#'
#' Compare time series for climatologies (monthly) and interpolated (daily)
#' data.
#'
#' @param climatology Numeric vector with monthly climatologies data.
#' @param interpolated Numeric vector with daily interpolated data.
#' @param month_len Numeric vector with the number of days in each month.
#' @param vars Vector of strings with variables to be plotted.
#' @param main String with title for the plot.
#' @param xlab String with label for the x-axis.
#' @param ylab String with label for the y-axis.
#'
#' @return \code{ggplot2} graphic object.
#' @keywords internal
ts_comp <- function(climatology,
                    interpolated,
                    month_len,
                    vars = c("cld", "pre", "tmn", "tmx", "vap"),
                    main = NULL,
                    xlab = NULL,
                    ylab = NULL) {
  # Local binding
  variable <- x <- y <- NULL

  days = sum(month_len)
  months = length(month_len)
  df <- data.frame(x = rep(seq_len(days), length(vars)),
                   y = interpolated,
                   variable = rep(vars, each = days))
  df2 <- data.frame(x = cumsum(month_len) - month_len / 2,
                    y = climatology,
                    variable = rep(vars, each = months))
  ggplot2::ggplot(df, ggplot2::aes(x, y)) +
    ggplot2::geom_line(ggplot2::aes(color = variable, linetype = variable)) +
    ggplot2::geom_point(ggplot2::aes(x, y, color = variable), df2) +
    ggplot2::labs(title = main, x = xlab, y = ylab) +
    ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
    ggplot2::scale_color_brewer(palette = "Set1") +
    ggplot2::theme_bw()
}

#' Plot time series
#'
#' Plot time series for multiple variables.
#'
#' @param data Numeric vector with the data.
#' @param vars Vector of strings with variables to be plotted.
#' @param count Numeric, number of observations of each variable.
#' @param x Numeric vector with breaks for the x-axis.
#' @param main String with title for the plot.
#' @param xlab String with label for the x-axis.
#' @param ylab String with label for the y-axis.
#'
#' @return \code{ggplot2} graphic object.
#' @keywords internal
ts_plot <- function(data,
                    vars = c("cld", "pre", "tmn", "tmx", "vap"),
                    count = length(data) / length(vars),
                    x = rep(seq_len(count), length(vars)),
                    main = NULL,
                    xlab = NULL,
                    ylab = NULL) {
  # Local binding
  variable <- y <- NULL

  df <- data.frame(x = x,
                   y = data,
                   variable = rep(vars, each = count))
  ggplot2::ggplot(df, ggplot2::aes(x, y)) +
    ggplot2::geom_line(ggplot2::aes(color = variable, linetype = variable)) +
    ggplot2::labs(title = main, x = xlab, y = ylab) +
    ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
    ggplot2::scale_color_brewer(palette = "Set1") +
    ggplot2::theme_bw()
}
