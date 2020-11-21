#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 29 10:30:14 2018

@author: pe915155

This file contains a snippet of code which I have used for mean-preserving
spline interpolation. The user may alter this in whichever way they want to
suit their own need.

The idea of how this was done was taken from:
    https://stats.stackexchange.com/questions/59418/interpolation-of-influenza-data-that-conserves-weekly-mean
    which follows methods described in:
        Harzallah, A., 1995. The interpolation of data series using a constrained iterating technique. Monthly weather review, 123(7), pp.2251-2254.
        DOI/URL: https://doi.org/10.1175/1520-0493(1995)123%3C2251:TIODSU%3E2.0.CO;2

The function follows an iterative process:
    1. Interpolate the data (in this case, using spline interpolation)
    2. Calculate the mean of each of the time periods defined
    3. Calculate the differences between the means of the timeperiods (from 2.) with the previous time period (original or the previous iteration)
    4. If the differences between the means (step 3.) is more than the threshold value:
        i. store the interpolated values.
        ii. store the residuals, and interpolate the residuals (go back to step 1., and repeat)
    5. If the differences between the means (step 4.) is less than the threshold value; or the maximum number of iterations are met:
        i. store the interpolated values
        ii. sum up the interpolated values, and return these values.

"""

# Import prerequisite functions
from scipy import interpolate
import numpy as np
import operator
import warnings

# Define functions
def interpol_spline_cons_mean(y_points, month_len, max_iter, tol):
    """Interpolate monthly timeseries data to daily.
    
    Prerequisites:
        scipy.interpolate
        numpy as np
        operator
        warnings
        accumulate function (defined below)
    
    Args:
        y_points: iterable(list or array), mean values at each timestep
        month_len: iterable(list or array), number of days at which each timestep represents
        max_iter: integer, maximum iterations if convegence is never met
        tol: numeric, the tolerance threshold for indicating convergence
    
    Returns:
        An array of interpolated values as the same length as the total sum of month_len
    
    Example:
        y_points = [12, 13, 14, 29, 32, 35, 33, 24, 18, 10, 8, 7] # data
        month_len = np.array([31, 29 ,31, 30, 31, 30, 31, 31, 30, 31, 30, 31]) # month length the data represents
        y_interpolated = interpol_spline_cons_mean(y_points, month_len, 100, 0.01) # interpolate
        map(np.mean, np.split(y_interpolated, np.array(list(accumulate(month_len))).astype(int)[:-1])) # see whether the means are the same with the threshold defined
    
    """
    # Check if month_len and y_points have the same dimension
    if len(month_len) != len(y_points):
        warnings.warn('Lengths of month_len and y_points are not the same.')
    else:
        x_points = (np.array(list(accumulate(month_len))) + 1) - (month_len + 1)/2    # create an array for object to keep interpolating
        y_points_mat = np.empty((max_iter + 1,len(y_points)))
        y_points_mat[:] = np.nan
        # input starting value as x_points
        y_points_mat[0,:] = y_points
        # create cumulative number of days from start from month_len
        cumm_date = np.array(list(accumulate(month_len))).astype(int)
        x_resampled_points = range(1, (cumm_date[-1] + 1))
        # create an array of the interpolated points
        y_points_interp_mat = np.empty((max_iter, (cumm_date[-1])))
        y_points_interp_mat[:] = np.nan
        # convert cummulated dates from start to indices 
        cumm_date = cumm_date[:-1]
        for i in range(max_iter):
            # create BSpline object 
            tck = interpolate.splrep(x_points, y_points_mat[i,:])
            # evaluate BSpline object at the different points
            y_points_interp_mat[i,:] = interpolate.splev(x_resampled_points, tck)
            new_mean = map(np.mean, np.split(y_points_interp_mat[i,:], cumm_date))
            resid = y_points_mat[i,:] - new_mean
            if max(resid) < tol:
                print('Converged after %d iterations with the tolerance of %f.' %(i,tol))
                break
            y_points_mat[i+1,:] = resid
        return(np.nansum(y_points_interp_mat, axis = 0))

def accumulate(iterable, func = operator.add):
    'Return running totals which must be listed using list()'
    it = iter(iterable)
    total = next(it)
    yield total
    for element in it:
        total = func(total, element)
        yield total
        
