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
#' @export
ts_comp <- function(climatology,
                    interpolated,
                    month_len,
                    vars = c("cld", "pre", "tmn", "tmx", "vap"),
                    main = NULL,
                    xlab = NULL,
                    ylab = NULL) {
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
