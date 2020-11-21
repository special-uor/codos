#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Oct 31 16:51:50 2018

@author: Kamolphat Atsawawaranunt

This script is partially altered from previously written codes for 
interpolating netCDF files which were used to interpolate PMIP3 climate
model output files

The script is written as a function which gets called by being
imported into other scripts. There are many options which the user may have
to specify and therefore it is suggested to be used called when imported 
into another script

When it is in the python path or within the directory to which your current 
script is:
It is used as follow:
    from interpolate_netCDF import int_netcdf
    run_int_netcdf = int_netcdf()
    run_int_netcdf.interpolate_netcdf_iris(......)
    # ...... are the arguments for the interpolate_netcdf_iris function

"""


# Import prerequisite modules 
import numpy as np
import logging
import iris

# Define 
class int_netcdf:
    """
    Name: int_netcdf
    """
    def __init__(self):
        """
        Name: int_netcdf.__init__
        Input: None
        Features: Initialise class variables
        """
        self.logger = logging.getLogger(__name__)
    def interpolate_netcdf_iris(self, input_netcdf, 
                                method, 
                                new_lat_dim, 
                                new_lon_dim, 
                                new_lat_start=None,
                                new_lat_stop=None,
                                new_lon_start=None,
                                new_lon_stop=None,
                                author_details=None, 
                                output_netcdf=None,
                                mask=None,
                                mask_values=None,
                                mask_values_moreorlessthan='Less',
                                output_netcdf_masked=None,
				output_netcdf_format='NETCDF3_CLASSIC'):
        """
        Name: int_netcdf.interpolate_netcdf_iris
        Features:   Interpolate netcdf file and output netcdf file using the iris module 
                    which is faster than the netcdf4 and the mpl_toolkits module
                    allows for definition of specific area of interests and
                    different method of interpolation
        Input:  input_netcdf = netcdf input file
                output_netcdf = output netcdf file name
                method = method of interpolation:
                                "Nearest" = Nearest Neighbour
                                "Linear" = Linear interpolation
                                "AreaWeighted" = Area Weighted
                new_lat_dim   = output latitude cell size
                new_lon_dim   = output longitude cell size
                new_lat_start = latitude boundary (lower bound) 
                new_lat_stop  = latitude boundary (upper bound)
                new_lon_start = longitude boundary (lower bound)
                new_lon_stop  = longitude boundary (upper bound)
                author_details =    details of person who executed this function,
                                    to be stored in netcdf file attributes
                                    Default = None
                mask =              masking file (netcdf file with lat and lon dimension, NO TIME dimension)
                                    Default = None
                mask_values =       values to be masked off (i.e. if sea=0, and land=1, 
                                                       masked_values=0 if land variables wanted)
                output_netcdf_masked = output netcdf file name of masked file
                                        Default = None
        Output: None
        """
        self.logger.info("Read in netcdf file : %s" %input_netcdf)
        cube1 = iris.load_cube(input_netcdf)
        lat,lon = cube1.coord('latitude'),cube1.coord('longitude')
        if new_lat_start == None:
            lat_min = lat.bounds.min()
        else:
            lat_min = new_lat_start
        if new_lat_stop == None:
            lat_max = lat.bounds.max()
        else:
            lat_max = new_lat_stop
        if new_lon_start == None:
            lon_min = lon.bounds.min()
        else:
            lon_min = new_lon_start
        if new_lon_stop == None:
            lon_max = lon.bounds.max()
        else:
            lon_max = new_lon_stop    
        lat_min_st = lat_min + new_lat_dim/2
        lon_min_st = lon_min + new_lon_dim/2
        lat_5 = np.arange(lat_min_st, lat_max, new_lat_dim)
        lon_5 = np.arange(lon_min_st, lon_max, new_lon_dim)
        self.logger.info("Start interpolation using the %s method" %method)
        lat = iris.coords.DimCoord(lat_5, standard_name='latitude', units='degrees')
        lon = iris.coords.DimCoord(lon_5, standard_name='longitude', units='degrees')
        cube = iris.cube.Cube(np.zeros((len(lat_5), len(lon_5)), np.float32),
                            dim_coords_and_dims=[(lat, 0), (lon, 1)])
        cube.coord('latitude').guess_bounds()
        cube.coord('longitude').guess_bounds()
        if method == "Nearest":
            scheme = iris.analysis.Nearest()
            result = cube1.regrid(cube, scheme)
            #result = cube1.interpolate([('latitude', lat_5), ('longitude', lon_5)], iris.analysis.Nearest())
        elif method == "Linear":
            scheme = iris.analysis.Linear()
            result = cube1.regrid(cube, scheme)
            #result = cube1.interpolate([('latitude', lat_5), ('longitude', lon_5)], iris.analysis.Linear())
        elif method == "AreaWeighted":
            scheme = iris.analysis.AreaWeighted(mdtol=1)
            result = cube1.regrid(cube, scheme)
        result.attributes['regridded_descriptions'] = ('Regridded using iris module in python')
        if author_details != None:
            self.logger.info("Store author details")
            result.attributes['regridded_contacts'] = ('%s' %str(author_details))
        result.attributes['regridded_method'] = ('%s' %method)
        result.attributes['regridded_resolution'] = ('latitude x longitude = %s x %s' %(str(new_lat_dim), str(new_lon_dim)))
        if output_netcdf != None:
            self.logger.info("Save interpolated results to %s" %output_netcdf)
            iris.save(result, output_netcdf, netcdf_format=output_netcdf_format)
        if mask != None:
            self.logger.info("Perform masking with %s" %mask)
            land = iris.load_cube(mask)
            self.logger.info("Regridded mask file to match interpolated results using Nearest Neighbour method")
            land = land.interpolate([('latitude', lat_5), ('longitude', lon_5)], iris.analysis.Nearest())
            #sublon = iris.Constraint(longitude=lambda cell: new_lon_start < cell < new_lon_stop)
            #sublat = iris.Constraint(latitude=lambda cell: new_lat_start < cell < new_lat_stop)
            #land = land.extract(sublon & sublat)
            if mask_values_moreorlessthan == 'More':
                true_false = land.data >= mask_values
            else:
                true_false = land.data < mask_values
            if result.ndim == 2:
                #n = np.empty((len(lat_5), len(lon_5)))
                #n[:] = None
                #n[:] = 1e20
                #n[~true_false] = result.data[~true_false]
                result.data[true_false] = np.nan
            else:
                for i in range(0,np.shape(result.data)[0],1):
                    #n = np.empty((len(lat_5), len(lon_5)))
                    #n[:] = None
                    #n[:] = 1e20
                    #n[~true_false] = result.data[i][~true_false]
                    result.data[i][true_false] = None
                    #result.data[i] = np.ma.array(result.data[i], mask=true_false)
            self.logger.info("Save masked output to %s" %output_netcdf_masked)
            iris.save(result, output_netcdf_masked, netcdf_format=output_netcdf_format)

if __name__ == '__main__':
    input_file = 'clt_Amon_GISS-E2-R_past1000_r1i1p124_085001-089912.nc'
    run_int_netcdf = int_netcdf()
    run_int_netcdf.interpolate_netcdf_iris(input_netcdf=input_file, 
    output_netcdf='output4_file.nc',
    method="Nearest",
    new_lat_dim=0.5, 
    new_lon_dim=0.5, 
    author_details="A: K.Atsawawaranunt@reading.ac.uk", 
    mask = 'fAPAR_global_mask.nc',
    mask_values = 0, 
    mask_values_moreorlessthan = 'More',
    output_netcdf_masked='output4_masked.nc')
    #run_int_netcdf.interpolate_netcdf_iris(input_file, 'Nearest', 0.5, 0.5)
    #run_int_netcdf.interpolate_netcdf(input_file, "tas", 0.5, 0.5, 0)
