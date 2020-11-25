path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
ncfiles_clim <- file.path(path,
                          c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc",
                            "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc"))
ncfiles_int <- file.path(path,
                         c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc",
                           "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc"))

# Original climatologies
cld_ts_clim <- codos::extract_data(ncfiles_clim[1], "cld")$main$data
pre_ts_clim <- codos::extract_data(ncfiles_clim[2], "pre")$main$data
tmn_ts_clim <- codos::extract_data(ncfiles_clim[3], "tmn")$main$data
tmx_ts_clim <- codos::extract_data(ncfiles_clim[4], "tmx")$main$data
vap_ts_clim <- codos::extract_data(ncfiles_clim[5], "vap")$main$data

# Interpolated data
cld_ts_int <- codos::extract_data(ncfiles_int[1], "cld")$main$data
pre_ts_int <- codos::extract_data(ncfiles_int[2], "pre")$main$data
tmn_ts_int <- codos::extract_data(ncfiles_int[3], "tmn")$main$data
tmx_ts_int <- codos::extract_data(ncfiles_int[4], "tmx")$main$data
vap_ts_int <- codos::extract_data(ncfiles_int[5], "vap")$main$data

# Extract spatial dimensions
lat <- codos::extract_data(ncfiles_clim[1], "cld")$lat$data
lon <- codos::extract_data(ncfiles_clim[1], "cld")$lon$data

interpolated <- c(cld_ts_int[650, 120, ],
                  pre_ts_int[650, 120, ],
                  tmn_ts_int[650, 120, ],
                  tmx_ts_int[650, 120, ],
                  vap_ts_int[650, 120, ])
climatology <- c(cld_ts_clim[650, 120, ],
                 pre_ts_clim[650, 120, ],
                 tmn_ts_clim[650, 120, ],
                 tmx_ts_clim[650, 120, ],
                 vap_ts_clim[650, 120, ])
month_len <- codos::days_in_month(paste0("1961-", out$time$data, "-01"))
ts_comp(climatology,
        interpolated,
        month_len,
        main = paste0("Time series at (", lat[j], ", ", lon[i], ")"),
        xlab = "Days")

lon_start <- 650
lon_end <- 655
lon_delta <- lon_end - lon_start + 1
lat_start <- 120
lat_end <- 125
lat_delta <- lat_end - lat_start + 1
plots <- vector("list", lon_delta * lat_delta)
p <- 1
for (j in rev(seq(lat_start, lat_end, 1))) {
  for (i in seq(lon_start, lon_end, 1)) {
    interpolated <- c(cld_ts_int[i, j, ],
                      pre_ts_int[i, j, ],
                      tmn_ts_int[i, j, ],
                      tmx_ts_int[i, j, ],
                      vap_ts_int[i, j, ])
    climatology <- c(cld_ts_clim[i, j, ],
                     pre_ts_clim[i, j, ],
                     tmn_ts_clim[i, j, ],
                     tmx_ts_clim[i, j, ],
                     vap_ts_clim[i, j, ])
    plots[[p]] <- ts_comp(climatology,
                          interpolated,
                          month_len,
                          main = paste0("Time series at (", lat[j], ", ", lon[i], ")"),
                          xlab = "Days")
    p <- p + 1
  }
}

ggplot2::ggsave("ts-comparison.pdf",
                plot = gridExtra::grid.arrange(grobs = plots, nrow = lat_delta),
                device = "pdf",
                width = 5 * lon_delta,
                height = 4 * lat_delta,
                path = "~/Desktop/iCloud/UoR/Data/codos",
                limitsize = FALSE)

ts_comp <- function(climatology,
                    interpolated,
                    month_len,
                    vars = c("cld", "pre", "tmn", "tmx", "vap"),
                    days = 365,
                    months = 12,
                    main = NULL,
                    xlab = NULL,
                    ylab = NULL) {
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
