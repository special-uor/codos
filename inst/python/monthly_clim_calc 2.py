#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 12:33:29 2017

@author: pe915155

Create Monthly climatology data over a defined time period

The monthly climatology data is calculated ignoring NA

If you would like this to account for NA (i.e. if NA exists, the monthly climatology data is NA, please change

var[range(i,time,12)].nanmean(axis = 0) 

to

var[range(i,time,12)].mean(axis = 0)

The codes assume that the variable is of 3 dimensions, and the time dimension is the first dimension

"""
# Import prerequisite modules
import sys
import netCDF4 as nc4
import numpy as np

# Define input arguments from terminal
input_file = sys.argv[1]
output_file_name = sys.argv[2]
varName = sys.argv[3]
start_year = int(sys.argv[4])
end_year = int(sys.argv[5])

# Read input file
input_file = input_file
f = nc4.Dataset(input_file, 'r')
# Read in longitude and latitudes
try:
    lons = f.variables['longitude'][:]
except:
    print("some error, longitude variable not called 'longitude', trying 'lon';")
    lons = f.variables['lon'][:]
try:
    lats = f.variables['latitude'][:]
except:
    print("some error, latitude variable not called 'latitude', trying 'lat';")
    lats = f.variables['lat'][:]

# Extract time variable. The units and the calendar follows netCDF standards
timein = f.variables['time'][:]
timeincal = f.variables['time'].calendar
timeinunits = f.variables['time'].units
yrls = []
# Convert time variable to actual dates
time_date = nc4.num2date(timein, timeinunits, timeincal)
# Appending the years
for k in time_date:
    yrls = np.append(yrls, k.year)
# Sort the years out. This should already be in order
yrls = list(yrls)
yrls.sort()
yrls = np.array(yrls)

# Create an index of what years we are subsetting
time_idx = np.flatnonzero((yrls >= start_year) & (yrls <= end_year))
# Extract the variable with the years we want
var = f.variables['%s' %varName][time_idx,:,:]

# var[np.isnan(var)] = 0 # fill 0 instead of nan if this is what you want
var_fill = f.variables['%s' %varName]._FillValue
var_units = f.variables['%s' %varName].units

# Creat output file
output_file = nc4.Dataset(output_file_name, 'w')
# Define output file dimensions
output_file.createDimension('latitude', len(lats))
output_file.createDimension('longitude', len(lons))
output_file.createDimension('time', None)
# Create output file variables
times = output_file.createVariable('time', np.float, ('time',))
latitudes = output_file.createVariable('latitude', np.float32, ('latitude',))
longitudes = output_file.createVariable('longitude', np.float32, ('longitude',))
main = output_file.createVariable('%s' %varName, np.float, ('time','latitude', 'longitude'), fill_value=var_fill)
# Define output file units
times.units = "months in a year"
latitudes.units = 'degrees_north'
longitudes.units = 'degrees_east'
main.units = var_units
main._missing_value = var_fill
# Store the values to the variables
latitudes[:] = lats
longitudes[:] = lons
time = len(time_idx)
for i in range(0,12,1):
    main[i,:,:] = var[range(i,time,12)].nanmean(axis = 0)
times[:] = range(1,13,1)
main.description = ('%s created by averaging monthly %s from %s' %(output_file_name, varName, input_file))
# Close both the input and output file
f.close()
output_file.close()



