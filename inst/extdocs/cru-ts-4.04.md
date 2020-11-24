CRU TS 4.04
================

## Raw data

## Calculate daily temperature

``` r
path <- "~/Desktop/iCloud/UoR/Data/CRU/4.04/"
tmin <- file.path(path, "cru_ts4.04.1901.2019.tmn.dat-clim-1961-1990-int.nc")
tmax <- file.path(path, "cru_ts4.04.1901.2019.tmx.dat-clim-1961-1990-int.nc")
codos::daily_temp(tmin = list(filename = tmin, id = "tmn"),
                  tmax = list(filename = tmax, id = "tmx"))
```
