CRU TS 4.04
================

## Raw data

``` r
ncfiles_raw <- c("cru_ts4.04.1901.2019.cld.dat.nc",
                 "cru_ts4.04.1901.2019.pre.dat.nc",
                 "cru_ts4.04.1901.2019.tmn.dat.nc",
                 "cru_ts4.04.1901.2019.tmx.dat.nc",
                 "cru_ts4.04.1901.2019.vap.dat.nc")
ncfiles_var <- c("cld", "pre", "tmn", "tmx", "vap")
```

## Convert precipitation from `[mm/month]` to `[mm/day]`

``` r
codos::convert_units.m2d("cru_ts4.04.1901.2019.pre.dat.nc", "pre")
```

##### Output file

``` bash
"cru_ts4.04.1901.2019.pre.dat-new.nc"
```

## Create monthly climatologies: 1960-1990

``` r
for (i in seq_along(ncfiles_raw))
  codos::monthly_clim(ncfiles_raw[i], ncfiles_var[i], 1961, 1990)
```

##### Output files

``` bash
"cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.pre.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc"
"cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc"
```

## Interpolate monthly data to daily

``` r
ncfiles_clim <- c("cru_ts4.04.1901.2019.cld.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.pre.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990.nc",
                  "cru_ts4.04.1901.2019.vap.dat-clim-1961-1990.nc")
ncfiles_var <- c("cld", "pre", "tmn", "tmx", "vap")

for (i in seq_along(ncfiles_raw))
  codos::nc_int(ncfiles_clim[i], ncfiles_var[i], cpus = 20)
```

##### Output files

``` bash
"cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.pre.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc"
"cru_ts4.04.1901.2019.vap.dat-clim-1961-1990-int.nc"
```

## Calculate daily temperature

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
tmin <- file.path(path, "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc")
tmax <- file.path(path, "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc")
codos::daily_temp(tmin = list(filename = tmin, id = "tmn"),
                  tmax = list(filename = tmax, id = "tmx"))
```

##### Output file

``` bash
"cru_ts4.04.1901.2019.daily.tmp.nc"
```

## Calculate solar declination and moisture index with [SPLASH](https://bitbucket.org/labprentice/splash)

SPLASH is driven by daily temperature (`tmp`), precipitation (`pre`),
cloud coverage (`cld`), and latitude.

## Convert elevations file from CRU TS 2.0

The original file was downloaded from:
<https://crudata.uea.ac.uk/~timm/grid/CRU_TS_2_0.html>

``` r
elv_filename <- "halfdeg.elv"
codos::grim2nc(elv_filename, "elv", scale_factor = 1, longname = "elevation")
```

##### Output file

``` bash
"halfdeg.elv.nc"
```

## Run SPLASH

Install wrapper R package for SPLASH:

``` r
remotes::install_github("villegar/splash", "dev")
```

### Solar declination

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
elv <- codos:::nc_var_get(file.path(path, "halfdeg.elv.nc"), "elv")$data
lat <- codos:::nc_var_get(file.path(path, "halfdeg.elv.nc"), "lat")
lon <- codos:::nc_var_get(file.path(path, "halfdeg.elv.nc"), "lon")
tmp <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.daily.tmp.nc"), "tmp")$data
cld <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.cld.dat-clim-1961-1990-int.nc"), "cld")$data
sf <- 1 - cld / 100

output_filename <- file.path(path, "cru_ts4.04-clim-1961-1990-solar-dcl.nc")
codos::splash_solar(output_filename, elv, sf, tmp, 1961, lat, lon, cpus = 20)
```

##### Output file

``` bash
"cru_ts4.04-clim-1961-1990-solar-dcl.nc"
```

### Moisture Index

``` r
pre <- codos:::nc_var_get(file.path(path, "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc"), "pre")$data
```
