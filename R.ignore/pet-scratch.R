# Find modern avg CO2
`%>%` <- magrittr::`%>%`
modern_co2 <- tibble::tibble(age = 1950 - c(1961:1990),
                             co2 = purrr::map_dbl(age, codos::past_co2))
knitr::kable(modern_co2, "pandoc", col.names = c("age cal BP", "co2"))
mean(modern_co2$co2, na.rm = TRUE)

plot_pet <- function(y, x = seq_len(365)) {
  p <- tibble::tibble(x = x,
                      y = purrr::flatten_dbl(y)) %>%
    ggplot2::ggplot(ggplot2::aes(x, y)) +
    ggplot2::geom_line() +
    ggplot2::labs(x = "[days]",
                  y = "PET [mm/month]") +
    ggplot2::theme_bw()
  print(p)
}

plot_pet(out[1])
plot_pet(out[324])
plot_pet(out[400])

k <- 274
padul$`Age (cal yr BP)`[k]
a <- padul_anomalies[k][[1]]
b <- purrr::map_dbl(seq_len(365),
                    function(i) {
                      splash::calc_daily_evap(lat = 37.0108,
                                              n = i,
                                              elv = padul_elv,
                                              y = year,
                                              sf = padul_sf[i],
                                              tc = padul_tmp[i] + a[i])$pet_mm
                    })
# waldo::compare(b, out[k][[1]])
tibble::tibble(x = seq_len(365),
               y = out[k][[1]]) %>% # padul_tmp + a) %>%
  ggplot2::ggplot(ggplot2::aes(x, y)) +
  ggplot2::geom_point() +
  ggplot2::geom_line(ggplot2::aes(x = seq_len(365),
                                  y = b),
                     colour = "red") +
  ggplot2::geom_line(ggplot2::aes(x = seq_len(365),
                                  y = a),
                     colour = "green") +
  ggplot2::labs(x = "[days]",
                y = "Temp [°C]") +
  ggplot2::theme_bw()

tibble::tibble(x = seq_len(365),
               y = padul_tmp + a) %>%
  ggplot2::ggplot(ggplot2::aes(x, y)) +
  ggplot2::geom_line() +
  ggplot2::geom_line(ggplot2::aes(x = seq_len(365),
                                  y = a)) +
  ggplot2::labs(x = "[days]",
                y = "Temp [°C]") +
  ggplot2::theme_bw()

tictoc::tic()
padul_anomalies[1] %>%
  purrr::map(~{
    purrr::map_dbl(seq_len(365),
                   function(i) {
                     splash::calc_daily_evap(lat = 37.0108,
                                             n = i,
                                             elv = padul_elv,
                                             y = 1961,
                                             sf = padul_sf[i],
                                             tc = padul_tmp[i] + .x[i])$pet_mm
                   })
  })
tictoc::toc()

#### Padul PET comparison
tictoc::tic()
k <- 297
padul_pet0 <-
  purrr::map_dbl(seq_len(365),
                 function(i) {
                   splash::calc_daily_evap(lat = 37.0108,
                                           n = i,
                                           elv = padul_elv,
                                           y = 1961,
                                           sf = padul_sf[i],
                                           tc = padul_tmp[i])$pet_mm
                 })
padul_pet_p_anomalies <-
  purrr::map_dbl(seq_len(365),
                 function(i) {
                   splash::calc_daily_evap(lat = 37.0108,
                                           n = i,
                                           elv = padul_elv,
                                           y = 1961,
                                           sf = padul_sf[i],
                                           tc = padul_tmp[i] + padul_anomalies[k][[1]][i])$pet_mm
                 }) #%>%
  # plot(type = "l", lty = 2, col = "blue")
# lines(padul_pet0)

tibble::tibble(x = rep(seq_len(365), 2),
               y = c(padul_pet0, padul_pet_p_anomalies),
               Temperature = rep(c("daily", "+ anomalies"),
                                 each = 365)) %>%
  ggplot2::ggplot(ggplot2::aes(x, y)) +
  ggplot2::geom_line(ggplot2::aes(colour = Temperature)) +
  ggplot2::labs(x = "day of the year",
                y = "daily PET [mm]",
                title = paste0(padul$`Age (cal yr BP)`[k], " yr cal BP")) +
  ggplot2::scale_colour_brewer(palette = "Set1") +
  ggplot2::theme_bw()



# purrr::map_dbl(seq_len(365),
#                function(i) {
#                  splash::calc_daily_evap(lat = 37.0108,
#                                          n = i,
#                                          elv = padul_elv,
#                                          y = 1961,
#                                          sf = padul_sf[i],
#                                          tc = padul_anomalies[k][[1]][i])$pet_mm
#                }) %>%
#   lines(lty = 2, col = "red")

tictoc::toc()

# purrr::map_dbl(seq_len(365),
#                function(i) {
#                  splash::calc_daily_evap(lat = 37.0108,
#                                          n = i,
#                                          elv = padul_elv,
#                                          y = 1961,
#                                          sf = padul_sf[i],
#                                          tc = padul_tmp[i])$pet_mm
#                }) %>%
#   lines(col = "red", lwd = 2)



padul$`Age (cal yr BP)`[k]
codos::int_sin(padul$Tmin[k] - padul$Tmin[1],
               padul$Tmax[k] - padul$Tmax[1]) %>%
  tibble::tibble(x = seq_len(365), y = .) %>%
  ggplot2::ggplot(ggplot2::aes(x, y)) +
  ggplot2::geom_line() +
  ggplot2::geom_point(data = tibble::tibble(x = 1, y = padul$T_djf[k] - padul$T_djf[1]),
                      ggplot2::aes(x, y, colour = "ΔT_djf")) +
  ggplot2::geom_point(data = tibble::tibble(x = 365 / 2, y = padul$T_jja[k] - padul$T_jja[1]),
                      ggplot2::aes(x, y, colour = "ΔT_jja")) +
  ggplot2::scale_colour_manual(name = "Recon. \nTemp.",
                               values = c("#0080ff","#ff3333")) +
  ggplot2::labs(x = "[days]",
                y = "Temp [°C]") +
  ggplot2::theme_bw()
