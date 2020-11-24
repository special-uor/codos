from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap

path = "/Users/roberto.villegas-diaz/Desktop/iCloud/UoR/Data/CRU/4.04/"

data = Dataset(path + "cru_ts4.04.1901.2019.pre.dat-new-clim-1961-1990-int.nc")

lats = data.variables['lat'][:]
lons = data.variables['lon'][:]
time = data.variables['time'][:]
pre = data.variables['pre'][:]

mp = Basemap(projection = 'cyl',
             llcrnrlat = -90,
             urcrnrlat = 90,
             llcrnrlon = -180,
             urcrnrlon = 180,
             resolution = 'i')

lon, lat = np.meshgrid(lons, lats)
x, y = mp(lon, lat)

days = np.arange(0, 365)

for i in days:
    # c_scheme = mp.pcolor(x, y, np.squeeze(pre[0, :, :]), cmap = 'jet')
    plot = mp.contourf(x, y, np.squeeze(pre[i, :, :]), cmap = plt.cm.viridis) 
    cb = mp.colorbar(plot, "bottom", size = "5%", pad = "2%", extend = 'both')
    cb.set_label("Precipitation [mm/day]")
    # cb.set_label(u"Temperature \u2103")
    
    # mp.drawcoastlines()
    mp.drawstates()
    mp.drawcountries()
    
    plt.title("Daily Precipitation (1961-1990): Day " + str(i + 1))
    plt.annotate('Data - CRU TS v4.04',(-178, -88), fontsize = 6)
    plt.clim(-10, 40)
    plt.show() 
    plt.savefig("cruts_pre_" + str(i + 1) + ".png", dpi = 800)
    plt.clf()


# cbar = mp.colorbar(c_scheme, location = 'right', pad = '10%')
# plt.clim(0, 30)
# plt.savefig(str(i + 1) + '.jpg')
# plt.show()
# plt.clf()
