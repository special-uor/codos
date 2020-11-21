tmp_file <- "~/Downloads/cru_ts_3_00.1901.2006.tmp.nc"
vap_file <- "~/Downloads/cru_ts_3_00.1901.2006.vap.nc"
wet_file <- "~/Downloads/cru_ts_3_00.1901.2006.wet.nc"

tmp_ts <- codos::nc2ts(tmp_file, "tmp")
vap_ts <- codos::nc2ts(vap_file, "vap")
wet_ts <- codos::nc2ts(wet_file, "wet")

write.csv(tmp_ts, "~/Desktop/iCloud/UoR/Data/CRU/tmp-ts.csv", row.names = FALSE)
write.csv(vap_ts, "~/Desktop/iCloud/UoR/Data/CRU/vap-ts.csv", row.names = FALSE)
write.csv(wet_ts, "~/Desktop/iCloud/UoR/Data/CRU/wet-ts.csv", row.names = FALSE)

tmp_ts <- cbind(tmp_ts, codos::retime(tmp_ts$time))
vap_ts <- cbind(vap_ts, codos::retime(vap_ts$time))
wet_ts <- cbind(wet_ts, codos::retime(wet_ts$time))

# Interpolate monthly values to daily
tmp_ts_ext <- codos::int_acm(tmp_ts$mean, codos::days_in_month(tmp_ts$date))
vap_ts_ext <- codos::int_acm(vap_ts$mean, codos::days_in_month(vap_ts$date))
wet_ts_ext <- codos::int_acm(wet_ts$mean, codos::days_in_month(wet_ts$date))

tictoc::tic()
tmp_ts_ext4 <- codos::m2d(tmp_ts$mean, codos::days_in_month(tmp_ts$date), thr = 24)
tictoc::toc()

################################################################################
ncfiles <- list.files("CRU/4.04", ".dat.nc$", full.names = TRUE)
ncfiles <- c("cru_ts4.04.1901.2019.cld.dat.nc",
             "cru_ts4.04.1901.2019.frs.dat.nc",
             "cru_ts4.04.1901.2019.pet.dat.nc",
             "cru_ts4.04.1901.2019.pre.dat.nc",
             "cru_ts4.04.1901.2019.tmn.dat.nc",
             "cru_ts4.04.1901.2019.tmp.dat.nc",
             "cru_ts4.04.1901.2019.tmx.dat.nc",
             "cru_ts4.04.1901.2019.vap.dat.nc",
             "cru_ts4.04.1901.2019.wet.dat.nc")
ncvars <- c("cld", "frs", "pet", "pre", "tmn", "tmp", "tmx", "vap", "wet")

for (i in seq_along(ncfiles))
  codos::monthly_clim(ncfiles[i], ncvars[i], 1961, 1990)

################################################################################
# Climatologies
ncfiles <- list.files("~/Desktop/iCloud/UoR/Data/CRU/4.04/", full.names = TRUE)

# Precipitation plots
filename <- "~/Downloads/cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990.nc"
out <- codos::extract_data(filename, "pre")
m_names <- c("jan", "feb", "mar", "apr", "may", "jun",
             "jul", "aug", "sep", "oct", "nov", "dec")
for (i in seq_along(m_names)) {
  pdf(paste0("~/Downloads/cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-",
             i, "-", m_names[i], ".pdf"),
      width = 8,
      height = 6)
  codos::plot_map(out$main$data[,,i], out$lat$data, out$lon$data)
  dev.off()
}

shp_path <- "~/Downloads"
shp_name <- "ne_110m_admin_0_countries.shp"
shp_file <- file.path(shp_path, shp_name)
world_shp <- sf::read_sf(shp_file)
world_outline <- as(sf::st_geometry(world_shp), Class = "Spatial")
# plot(world_outline, col="gray80", lwd=1)

pre_raster <- raster::brick(filename, "pre")
mapTheme <- rasterVis::rasterTheme(region = c(RColorBrewer::brewer.pal(9, "Blues")))
cutpts <- seq(0, 50, 10)# c(0, 10, 20, 30, 40, 50)
pre_raster2 <- raster::brick(out$main$data)
plt <- rasterVis::levelplot(raster::subset(pre_raster, 1),
                            margin = FALSE,
                            at = cutpts,
                            cuts = length(cutpts),
                            pretty=TRUE,
                            par.settings = mapTheme,
                            main = "January temperature")

plt + latticeExtra::layer(sp::sp.lines(world_outline, col = "black", lwd = 1.0))

# world <- data.frame(maps::map(plot=FALSE)[c("x","y")])
# plot(world)
# plt
# rasterVis::gplot(raster::subset(pre_raster, 1), par.settings = mapTheme) +
#   ggplot2::geom_tile(ggplot2::aes(fill = value)) +
#   ggplot2::geom_path(data=world, ggplot2::aes(x,y)) +
#   ggplot2::stat_contour(ggplot2::aes(z=value)) +
#   ggplot2::coord_equal()
# plt + maps::map(add = TRUE)



################################################################################
tmp <- readr::read_csv("~/Desktop/iCloud/UoR/Data/CRU/tmp.csv")
vap <- readr::read_csv("~/Desktop/iCloud/UoR/Data/CRU/vap.csv")
wet <- readr::read_csv("~/Desktop/iCloud/UoR/Data/CRU/wet.csv")

dates <- function(var) {
  ref_data <- lubridate::date("1870-01-01 00:00:00 UTC")
  aux <- ref_data + lubridate::dmonths(var)
  tibble::tibble(date = aux,
                 year = lubridate::year(aux),
                 month = lubridate::month(aux),
                 leap = lubridate::leap_year(aux))
}

days <- function(var) {
  aux <- dates(var)
  unname(lubridate::days_in_month(aux$date))
}

csv <- function(file, data) {
  aux <- data.frame(y_points = data[, 2],
                    month_len = data[, 3])
  colnames(aux) <- c("y_points", "month_len")
  write.csv(aux, file, row.names = FALSE)
}

tmp$days <- days(tmp$`months since 1870-1-1, standard calendar`)
vap$days <- days(vap$`months since 1870-1-1, standard calendar`)
wet$days <- days(wet$`months since 1870-1-1, standard calendar`)
csv("~/Desktop/iCloud/UoR/Data/CRU/tmp-int.csv", tmp)

accumulate <- function(iterable) {
  cumsum(iterable)
}

int <- function(y_points, month_len) {
  MN <- rep(y_points, month_len)
  new_MN <- MN[]
  cumm_date <- accumulate(month_len)
  for (i in seq_len(length(MN))) {
    new_MN <- (shift(new_MN, -1) + new_MN + shift(new_MN, 1))/3
    diff <- MN - new_MN
    new_mean <- unlist(lapply(unname(split(diff, rep(1:length(month_len), month_len))), mean))
    Cterm <- rep(new_mean, times = month_len)
    new_MN <- new_MN + Cterm
  }
  new_MN
}

shift <- function(x, n, invert=FALSE){
  # shift verctor by n position
  #
  # Prerequisites:
  #   none
  #
  # Args:
  #   x: list/vector
  #   n: numeric, the order to which the vector is shifted by
  #   invert: boolean, whether or not to invert the vector
  #
  # Returns:
  #   An array of the vector shifted
  #
  stopifnot(length(x)>=n)
  if(n==0){
    return(x)
  }
  n <- ifelse(invert, n*(-1), n)
  if(n<0){
    n <- abs(n)
    forward=FALSE
  }else{
    forward=TRUE
  }
  if(forward){
    return(c(x[seq(length(x) - n + 1, length(x))], x[seq_len(length(x)-n)]))
  }
  if(!forward){
    return(c(x[seq(n + 1, length(x))], x[1:n]))
  }
}

rep(c(1, 2, 3), c(2, 4, 8))
tmp <- cbind(tmp, codos::retime(tmp$time))
MN <- codos::int_acm(tmp$mean[1:12], codos::days_in_month(tmp$date[1:12]))
MN <- codos::int_acm(tmp$mean, codos::days_in_month(tmp$date))
plot(MN, type = "l")
accumulate(tmp$days)
