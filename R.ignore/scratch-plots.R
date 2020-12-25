for (k in seq_len(nrow(idx))) {
  i <- idx$i[k]
  j <- idx$j[k]
  if (!is.na(elv[i, j])) {
    tictoc::tic()
    b <- unlist(lapply(seq_len(dim(tmp)[3]),
                  function(x, i, j) {
                    splash::calc_daily_solar(lat = lat$data[j],
                                             n = x,
                                             elv = elv[i, j],
                                             y = year,
                                             sf = sf[i, j, x],
                                             tc = tmp[i, j, x])$delta_deg
                  }, i = i, j = j))
    tictoc::toc()
    # b <- c()
    # tictoc::tic()
    # for (k in seq_len(365)) {
    #   b <- c(b, splash::calc_daily_solar(lat = lat$data[j],
    #                            n = k,
    #                            elv = elv[i, j],
    #                            y = year,
    #                            sf = sf[i, j, k],
    #                            tc = tmp[i, j, k])$delta_deg)
    # }
    # tictoc::toc()
    stop("i: ", i, " - j: ", j)
  } else {
    rep(NA, dim(tmp)[3])
  }
}


tg <- array(0, dim = c(720, 360))
for (i in seq_len(720)) {
  print(i)
  for (j in seq_len(360)) {
    tg[i, j] <- T_g(lat$data[j] * pi / 180,
                    dcl[1] * pi / 180,
                    tmx[i, j, 1],
                    tmn[i, j, 1])
  }
}

image(lon$data, lat$data, tg)
for (j in seq_len(360)) {
  tan(lat$data[j] * pi / 180) * tan(dcl[1] * pi / 180)
  x <- -tan(lat$data[j] * pi / 180) * tan(dcl[1] * pi / 180)
  print(paste0("lat: ", lat$data[j], " - j: ", j, " - x: ", x))
}

x <- tan(lat$data[j] * pi / 180) * tan(dcl[1] * pi / 180)
x <- cos(pi)
tmx[1, 1, 1] * (0.5 + sqrt(1 - x^2) / 2 * acos(x)) +
  Temp_min * (0.5 - sqrt(1 - x^2) / 2 * acos(x))
tg0 <- tg



ggplot2::ggplot(df[df$tg == i,], ggplot2::aes(MI, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
  ggplot2::scale_color_manual(values = c("#8c94c0"), guide = FALSE) +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(n = 8)) +
  ggplot2::theme_bw() +
  ggplot2::stat_smooth(method = lm, formula = log(y) ~ x)  +
  ggplot2::labs(title = paste0("Tg: ", i, " [°C] - Linear regression"),
                x = "MI [-]",
                y = "vpd [hPa]") +
  ggpubr::stat_regline_equation(
    ggplot2::aes(label = paste(..eq.label..,
                               ..adj.rr.label..,
                               sep = "~~~~")),
    formula = log(y) ~ x)

# Subset data
set.seed(1)
idx <- sample(seq_len(nrow(df)), size = floor(nrow(df) * 0.7), replace = FALSE)
df_train <- df[idx, ]
df_test <- df[-idx, ]

# # Build the models
## Start with a simple model to find the start points
lmod <- lm(log(vpd) ~ Tg * MI,# poly(Tg, 2) + poly(MI, 2),
           data = df_train)
summary(lmod)
plot(df_test$Tg, exp(predict(lmod, df_test)), col = df_test$mi)
exp(coef(lmod)[1])
# start <- list(a = exp(coef(lmod)[1]),
#               kTg = coef(lmod)[2],
#               kMI = coef(lmod)[4],
#               kaTg = coef(lmod)[3],
#               kaMI = coef(lmod)[5])
# ## Non-linear model
# # nls(vpd ~ a*exp(kTg * I(Tg) - kaTg * I(Tg ^ 2) - kMI * I(MI) + kaMI * I(MI ^ 2)),
# #     df_train,
# #     start = start)
f <- function(x1, x2, a, b1, b2, b3) {a * exp(b1 * x1 - b2 * x2 + b3 * I(x1 * x2))}
model1 <- nls(vpd ~ a * exp(kTg * Tg - I(Tg ^ kaTg) - kMI * I(MI ^ 2)),
              df_train,
              start = list(a = -1, kTg = 0, kMI = 0, kaTg = 2),
              control = list(maxiter = 200))
model1 <- nls(#vpd ~ f(Tg, MI, a, kTg, kMI, kMITg), #
              vpd ~ a * exp(kTg * Tg - kMI * MI + kMITg * MI * Tg),
              df_train,
              start = list(a = exp(coef(lmod)[1]),
                           kTg = coef(lmod)[2],
                           kMI = coef(lmod)[3],
                           kMITg = coef(lmod)[4]),
              control = list(maxiter = 200))
model1
plot(df_test$Tg, predict(model1, df_test), col = df_test$mi)
coef(model1)

mix <- mi
mix[Tg > 5 | mi > 0.5] <- NA
mix2 <- mix
mix2[codos:::ice_mask] <- NA
mix2[mix2 < 0.5 | Tg < 5] <- NA
image(lon$data, lat$data, mix)
codos:::nc_save_timeless(filename = "mi-gsv3.nc",
                 var = list(id = "mi",
                            longname = "moisture index",
                            missval = -999L,
                            prec = "double",
                            units = "-",
                            vals = mi),
                 lat = list(id = "lat", units = "degrees_north", vals = lat$data),
                 lon = list(id = "lon", units = "degrees_east", vals = lon$data),
                 var_atts = NULL,
                 overwrite = TRUE)

codos:::nc_save_timeless(filename = "tg-gsv2.nc",
                         var = list(id = "mdt",
                                    longname = "mean daytime temperature",
                                    missval = -999L,
                                    prec = "double",
                                    units = "degrees Celsius",
                                    vals = Tg),
                         lat = list(id = "lat", units = "degrees_north", vals = lat$data),
                         lon = list(id = "lon", units = "degrees_east", vals = lon$data),
                         var_atts = NULL,
                         overwrite = TRUE)
# # p <- lm(log(vpd) ~ poly(Tg, 2) + poly(MI, 2), data = df_test)
# # plot(df_test$Tg, predict(p, df_test), col = df_test$mi)
# # p2 <- lm(log(vpd) ~ Tg + MI, data = df_test)
# # plot(df_test$Tg, predict(p2, df_test), col = df_test$mi)
# # caret::R2(predict(p, df_test), df_test$vpd)
# # caret::R2(predict(p2, df_test), df_test$vpd)
# #
# # model1 <- nls(vpd ~ a*exp(kTg * I(Tg^2) - kMI * I(MI^2)),
# #               df_train,
# #               start = list(a = -1, kTg = 100, kMI = 100))
# # model_gam <- mgcv::gam(vpd ~ exp(Tg + MI),
# #           data = df_train)
# # coef(model_gam)
#
# model1 <- nls(vpd ~ a*exp(kTg * Tg - I(Tg ^ kaTg) - kMI * MI + I(MI ^ kaMI)),
#               df_train,
#               start = list(a = 2, kTg = 0, kMI = 0, kaTg = -1, kaMI = -1))
# # model1 <- nls(vpd ~ a * exp(kTg * I(Tg ^ kaTg) - kMI * I(MI ^ kaMI)),
# #               df_train,
# #               start = list(a = -1, kTg = 0, kMI = 0, kaTg = 2, kaMI = 2))

a <- coef(model1)[1]
kTg <- coef(model1)[2]
kMI <- coef(model1)[3]
kaTg <- coef(model1)[4]
kaMI <- 2

# # df_train$vpd[1]
# # coef(model1)[1] * exp(coef(model1)[2] * df_train$Tg[1] - coef(model1)[3] * df_train$MI[1])
#
# ## Linear model
# model2 <- lm(log(vpd) ~ Tg + MI,
#              data = df_test)
# # coef(model2)
# a <- c(a, exp(coef(model2)[1]))
# kTg <- c(kTg, coef(model2)[2])
# kMI <- c(kMI, coef(model2)[3])
#
# # Make predictions
# predictions1 <- predict(model1, df_test)
# predictions2 <- predict(model2, df_test)
#
# # Model performance
# knitr::kable(data.frame(
#   model = c("Non-linear", "Linear"),
#   RMSE = c(caret::RMSE(predictions1, df_test$vpd),
#            caret::RMSE(predictions2, df_test$vpd)),
#   R2 = c(caret::R2(predictions1, df_test$vpd),
#          caret::R2(predictions2, df_test$vpd))
# ))
#
# # Model coefficients
# knitr::kable(data.frame(
#   model = c("Non-linear", "Linear"),
#   a = unname(a),
#   kTg = unname(kTg),
#   kMI = unname(kMI)
# ))

# vpd_calc <- with(df_test, a[1] * exp(kTg[1] * Tg - kMI[1] * MI))
df2 <- data.frame(x = rep(seq(0, 6.6, 0.1), 7),
                  y = unlist(lapply(c(2.5, 7.5, 12.5, 17.5, 22.5, 27.5, 32.5),
                                    # function(x) a[1] * exp(kTg[1] * x -  x ^ kaTg - kMI[1] * seq(0, 6.6, 0.1) ^ kaMI))),
                                    function(x) a[1] * exp(kTg[1] * x - kMI[1] * seq(0, 6.6, 0.1) + kaTg * x * seq(0, 6.6, 0.1)))),
                  z = rep(c("0-5", "5-10", "10-15", "15-20", "20-25", "25-30", "30-35"),
                          each = length(seq(0, 6.6, 0.1))))
ggplot2::ggplot(df, ggplot2::aes(MI, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
  ggplot2::geom_line(data = df2, ggplot2::aes(x = x, y = y, color = z)) +
  ggplot2::geom_point(data = df2, ggplot2::aes(x = x, y = y)) +
  # ggplot2::geom_point(ggplot2::aes(y = vpd_calc, color = tg), alpha = 0.3) +
  ggplot2::labs(title = paste0("vpd = ",
                               round(a, 3),
                               " exp(",
                               round(kTg, 3),
                               " Tg - ",
                               # "Tg^{",
                               # round(kaTg, 3),
                               # "} - ",
                               round(kMI, 3),
                               " MI",
                               # "^",
                               # round(kaMI, 3),
                               " + ",
                               round(kaTg, 4),
                               " MI * Tg",
                               ")"),
                x = "MI [-]", y = "vpd [hPa]") +
  ggplot2::scale_color_brewer(palette = "Spectral", direction = -1) +
  ggplot2::theme_bw()
  # ggplot2::annotate("text", x = 20, y = 45, size = 3,
  #                   label = paste0("vpd = ", a, " exp(", kTg, " Tg - Tg^", kaTg, ")"))



# vpd_calc <- with(df_test, a[1] * exp(kTg[1] * Tg - kMI[1] * MI))
df2 <- data.frame(x = rep(seq(0, 35, 1), 5),
                  y = unlist(lapply(c(0.25, 0.75, 1.25, 1.75, 2.25),
                                    # function(x) a[1] * exp(kTg[1] * seq(0, 35, 1) - seq(0, 35, 1) ^ kaTg - kMI[1] * x ^ kaMI))),
                                    function(x) a[1] * exp(kTg[1] * seq(0, 35, 1) - kMI[1] * x + kaTg * x * seq(0, 35, 1)))),
                  z = rep(c("0-0.5", "0.5-1", "1-1.5", "1.5-2", "2+"),
                          each = length(seq(0, 35, 1))))
ggplot2::ggplot(df, ggplot2::aes(Tg, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = mi), alpha = 0.5) +
  ggplot2::geom_line(data = df2, ggplot2::aes(x = x, y = y, color = z)) +
  ggplot2::geom_point(data = df2, ggplot2::aes(x = x, y = y)) +
  ggplot2::labs(title = paste0("vpd = ",
                               round(a, 3),
                               " exp(",
                               round(kTg, 3),
                               " Tg - ",
                               # "Tg^{",
                               # round(kaTg, 3),
                               # "} - ",
                               round(kMI, 3),
                               " MI",
                               # "^",
                               # round(kaMI, 3),
                               " + ",
                               round(kaTg, 4),
                               " MI * Tg",
                               ")"),
                x = "Tg [°C]", y = "vpd [hPa]") +
  ggplot2::scale_color_brewer(palette = "Spectral", direction = -1) +
  ggplot2::theme_bw()


ggplot2::ggplot(df, ggplot2::aes(MI, vpd)) +
  ggplot2::geom_point(ggplot2::aes(color = tg), alpha = 0.5) +
  # ggplot2::geom_line(ggplot2::aes(y = vpd_T0_5)) +
  # ggplot2::labs(title = main, x = xlab, y = ylab) +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
  ggplot2::scale_color_brewer(palette = "Set1") +
  ggplot2::theme_bw() +
  ggplot2::stat_smooth(method = lm, formula = y ~ x)
