# -*- coding: utf-8 -*-
# Copyright 2014 Peter Williams <peter@newton.cx>
# Licensed under the GNU General Public License, version 3 or higher.

"""pdm - period-finding with phase dispersion minimization

As defined in Stellingwerf (1978ApJ...224..953S). See the update in
Schwarzenberg-Czerny (1997ApJ...489..941S), however, which corrects the
significance test formally; Linnell Nemec & Nemec (1985AJ.....90.2317L)
provide a Monte Carlo approach. Also, Stellingwerf has developed "PDM2" which
attempts to improve a few aspects; see

  http://www.stellingwerf.com/rfs-bin/index.cgi?action=PageView&id=29
  http://en.wikipedia.org/wiki/Phase_dispersion_minimization

"""

# TODO: automatic rule for nbin?
# TODO: ditto for nr periods to try?
# TODO: confidence in peak value or something

from __future__ import division
import numpy as np
from collections import namedtuple
import time
from multiprocessing import Pool


PDMResult = namedtuple ('PDMResult', 'thetas imin pmin mc_tmins '
                        'mc_pvalue mc_pmins mc_puncert'.split ())


def weighted_variance (x, wt):
    """Biased weighted sample variance per Wikipedia 
    using built-in functions"""

    wtavg = np.average(x, weights=wt)
    wtvar = np.average((x-wtavg)**2, weights=wt)
    
    return wtvar


def one_theta (t, x, wt, period, nbin, nshift, v_all):
    phase0 = t / period
    numer = denom = 0.

    for i in xrange (nshift):
        phase = (phase0 + float (i) / (nshift * nbin)) % 1.
        binloc = np.floor (phase * nbin).astype (np.int)

        for j in xrange (nbin):
            wh = np.where (binloc == j)[0]
            if wh.size < 3:
                continue

            numer += weighted_variance (x[wh], wt[wh]) * (wh.size - 1)
            denom += wh.size - 1

    return numer / (denom * v_all)

# multiprocessing can only deal with one input parameter
# parse the list here
def one_theta_feeder (data_list):
    
    (t, x, wt, period, nbin, nshift, v_all) = data_list ## map can only take a single argument
    result = one_theta(t, x, wt, period, nbin, nshift, v_all)

    return result

def pdm (t, x, u, periods, nbin, nshift=8, nsmc=256, numc=256, weights=False,
         nprocesses = 8):
    """Perform phase dispersion minimization.

    `t` - 1D array - time coordinate
    `x` - 1D array, same size as `t` - observed value
    `u` - 1D array, same size as `t` - uncertainty on observed value; same units as `x`
    `periods` - 1D array - set of candidate periods to sample; same units as `t`
    `nbin` - int - number of phase bins to construct
    `nshift` - int=8 - number of shifted binnings to sample to combact statistical flukes
    `nsmc` - int=256 - number of Monte Carlo shufflings to compute, to evaluate the
       significance of the minimal theta value.
    `numc` - int=256 - number of Monte Carlo added-noise datasets to compute, to evaluate
       the uncertainty in the location of the minimal theta value.

    Returns named tuple of:

    `thetas` - 1D array of values of theta statistic, same size as `periods`
    `imin` - index of smallest (best) value in `thetas`
    `pmin` - the `period` value with the smallest (best) `theta`
    `mc_tmins` - 1D array of size `nsmc` with Monte Carlo samplings of minimal
       theta values for shufflings of the data; assesses significance of the peak
    `mc_pvalue` - probability (between 0 and 1) of obtaining the best theta value
       in a randomly-shuffled dataset
    `mc_pmins` - 1D array of size `numc` with Monte Carlo samplings of best
       period values for noise-added data; assesses uncertainty of `pmin`
    `mc_puncert` - standard deviation of `mc_pmins`; approximate uncertainty
       on `pmin`.

    We don't do anything clever, so runtime scales at least as
      t.size * periods.size * nbin * nshift * (nsmc + numc + 1)."""

    t = np.asfarray (t)
    x = np.asfarray (x)
    u = np.asfarray (u)
    periods = np.asfarray (periods)
    t, x, u, periods = np.atleast_1d (t, x, u, periods)
    nbin = int (nbin)
    nshift = int (nshift)
    nsmc = int (nsmc)
    numc = int (numc)

    if t.ndim != 1:
        raise ValueError ('`t` must be <= 1D')

    if x.shape != t.shape:
        raise ValueError ('`t` and `x` arguments must be the same size')

    if u.shape != t.shape:
        raise ValueError ('`t` and `u` arguments must be the same size')

    if periods.ndim != 1:
        raise ValueError ('`periods` must be <= 1D')

    if nbin < 2:
        raise ValueError ('`nbin` must be at least 2')

    if nshift < 1:
        raise ValueError ('`nshift` must be at least 1')

    if nsmc < 0:
        raise ValueError ('`nsmc` must be nonnegative')

    if numc < 0:
        raise ValueError ('`numc` must be nonnegative')
        
    # We can finally get started!

    # allow weights or data uncertainties to be supplied
    if weights:
        wt = u
        u = wt ** -2
    else:
        wt = u ** -2
    v_all = weighted_variance (x, wt)

    thetas = np.empty (periods.shape)

    args = [None]*periods.size
    for i in xrange (periods.size):
        args[i] = (t, x, wt, periods[i], nbin, nshift, v_all)

    # do period search with worker processes    
    pool = Pool(nprocesses)
    thetas_list = pool.map(one_theta_feeder, args)
    thetas = np.array(thetas_list)

    imin = thetas.argmin ()
    pmin = periods[imin]

    # Now do the Monte Carlo jacknifing so that the caller can have some idea
    # as to the significance of the minimal value of `thetas`.

    mc_tmins = np.empty (nsmc)
    
    for i in xrange (nsmc):
        shuf = np.random.permutation (x.size)
        args = [None]*periods.size
        
        for j in xrange (periods.size):
            args[j] = (t, x[shuf], wt[shuf], periods[j], nbin, nshift, v_all)

        # do period search with worker processes    
        thetas_list = pool.map(one_theta_feeder, args)
        mc_thetas = np.array(thetas_list)
        mc_tmins[i] = np.array(thetas_list).min()

    mc_tmins.sort ()
    mc_pvalue = mc_tmins.searchsorted (thetas[imin]) / nsmc

    # Now add noise to assess the uncertainty of the period.

    mc_pmins = np.empty (numc)

    for i in xrange (numc):
        noised = np.random.normal (x, u)

        for j in xrange (periods.size):
            args[j] = (t, noised, wt, periods[j], nbin, nshift, v_all)

        # do period search with worker processes    
        thetas_list = pool.map(one_theta_feeder, args)
        mc_thetas = np.array(thetas_list)
        mc_pmins[i] = periods[mc_thetas.argmin ()]

    mc_pmins.sort ()
    mc_puncert = mc_pmins.std ()

    # don't forget to close the pool!!
    pool.terminate()
    pool.join()
    
    # All done.
    return PDMResult (thetas=thetas, imin=imin, pmin=pmin, mc_tmins=mc_tmins,
                      mc_pvalue=mc_pvalue, mc_pmins=mc_pmins,
                      mc_puncert=mc_puncert)
