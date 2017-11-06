'''
Fitting code used by a variety of MOSFIRE applications.

Written in March 2011 by npk
'''
from scipy.special import erf
import scipy.optimize as optimize
import numpy as np
import pylab as pl
import nmpfit_mos as mpfit

# Following is to correct for old/new version of stsci python

## try: 
##     import pytools

## except ImportError: import stsci.tools.nmpfit as mpfit

import unittest

def xcor(a,b,lags):

    if len(a) != len(b):
        error("cross correlation (xcor) requires a and b "
                "to be of same length")
        raise Exception(
                "cross correlation (xcor) requires a and b "
                "to be of same length")
    cors = np.zeros(len(lags))

    a_pad = np.zeros(len(a)+len(lags))
    b_pad = np.zeros(len(b)+len(lags))

    st = np.argmin(np.abs(lags))
    a_pad[st:st+len(a)] = a
    b_pad[st:st+len(b)] = b

    for i in range(len(lags)):
        cors[i] = np.correlate(a_pad, np.roll(b_pad, lags[i]), 'valid')

    return cors

def xcor_peak(a, b, lags):
    '''Return the peak position in units of lags'''

    N = len(lags)
    xcs = xcor(a, b, lags)

    return lags[np.argmax(xcs)]




# TODO: Document mpfit_* functions
def mpfit_residuals(modelfun):

    def fun(param, fjac=None, x=None, y=None, error=None):
        '''Generic function'''
        model = modelfun(param, x)
        status = 0

        if error is None:
            return [status, y-model]

        return [status, (y-model)/error]

    return fun

def mpfit_do(residual_fun, # function returned from mpfit_residuals() above
        x, # input x
        y, # input y = f(x)
        parinfo, # initial parameter guess
        error=None,
        maxiter=20):

    #TODO : Document parinfo part

    fa = {"x": x, "y": y}
    if error is not None:
        fa["error"] = error

    lsf = mpfit.mpfit(residual_fun, parinfo=parinfo, functkw=fa, 
            quiet=1, maxiter=maxiter)

    return lsf

# MPFITPEAK
def gaussian(p, x):
    ''' gaussian model
    p[0] -- scale factor
    p[1] -- centroid
    p[2] -- sigma
    p[3] -- offset
    p[4] -- slope
    '''
    
    u = (x - p[1])/p[2]
    return p[0]*np.exp(-0.5*u*u) + p[3] + p[4]*x

def gaussian_residuals(p, fjac=None, x=None, y=None, error=None):

    model = gaussian(p, x)
    status = 0

    delt = y-model
    if error is None:
        return [status, delt]

    return [status, delt/error]

def multi_gaussian(p, x):
    N = p[0]
    sigma = p[1]
    offset = p[2]
    slope = p[3]

    y = np.zeros(len(x))
    j = 4
    for i in range(np.int(N)):
        y += gaussian([p[j], p[j+1], sigma, 0, 0], x)
        j+=2

    y += offset + slope*x

    return y


def multi_gaussian_residuals(p, fjac=None, x=None, y=None, error=None):

    model = multi_gaussian(p, x)
    status = 0
    delt = y - model
    if error is None:
        return [status, delt]

    return [status, delt]


def mpfitpeak(x, y, error=None):
    
    parinfo = [{"value": np.max(y), "fixed": 0, "name": "Peak Value",
                    'step': 10},
                {"value": x[np.argmax(y)], "fixed": 0, "name": "Centroid",
                    'step': .1},
                {"value": 1.1, "fixed": 0, "name": "Sigma",
                    'step': .1},
                {"value": np.min(y), "fixed": 0, "name": "Offset",
                    'step': 10},
                {"value": 0, "fixed": 0, "name": "Slope",
                    'step': 1e-5}]

    fa = {"x": x, "y": y}
    if error is not None: fa["error"] = error


    return mpfit.mpfit(gaussian_residuals, parinfo=parinfo, functkw=fa, quiet=1)
            
def mpfitpeaks(x, y, N, error=None):

    pars = [1, np.min(y), 0]
    parinfo = [ {"value": N, "fixed": 1, "name": "Number of Peaks",
                    "limited": [0, 0], "limits": [0, 0]},
                {"value": 1.6, "fixed": 0, "name": "Sigma",
                    "limited": [0, 0], "limits": [0, 0]},
                {"value": pars[1], "fixed": 0, "name": "Offset",
                    "limited": [0, 0], "limits": [0, 0]},
                {"value": pars[2], "fixed": 0, "name": "Slope",
                    "limited": [0, 0], "limits": [0, 0]}]
    
    for i in range(N):
        v = {"value": np.max(y)/2., "fixed": 0, "name": "Peak Value(%i)" % i,
                "limited": [1, 0], "limits": [0, 0]}
        pars.append(np.max(y))
        parinfo.append(v)

        v = {"value": x[np.argmax(y)], "fixed": 0, "name": "Centroid(%i)" % i}
        pars.append(x[np.argmax(y)])
        parinfo.append(v)

    fa = {"x": x, "y": y}
    if error is not None: fa["error"] = error
    return mpfit.mpfit(multi_gaussian_residuals, parinfo=parinfo, functkw=fa,
            quiet=1)

def slit_edge_fun(x, s):
    ''' The edge of a slit, convolved with a Gaussian, is well fit by 
    the error function. slit_edge_fun is a reexpression of the error 
    function in the classica gaussian "sigma" units'''
    sq2 = np.sqrt(2)
    sig = sq2 * s

    return np.sqrt(np.pi/2.) * s * erf(x/sig) 

def fit_bar_edge(p, x):
    ''' 
    Fitting function for a bar edge
    '''

    return p[0] + np.radians(4.2) * x

def fit_single(p, x):
    '''
    The fitting function used by do_fit_single. This is a single slit edge
    
    p[0] ---> Sigma
    p[1] ---> Horizontal offset
    p[2] ---> Multipicative offset
    p[3] ---> Additive offset
    '''
    return slit_edge_fun(x - p[1], p[0]) * p[2] + p[3]

def fit_pair(p, x):
    '''
    The fitting function ussed by "do_fit". The sum of two edge functions.

    p[0] ---> Sigma
    p[1] ---> Horizontal offset
    p[2] ---> Multipicative offset
    p[3] ---> Additive offset
    p[4] ---> Width of slit
    '''
    return slit_edge_fun(x - p[1], p[0]) * p[2] + p[3] - slit_edge_fun(x 
            - p[1] - p[4], p[0]) * p[2]

def fit_disjoint_pair(p,x):
    '''
    The fitting function ussed by "do_fit". The sum of two edge functions.

    p[0] ---> Sigma
    p[1] ---> Horizontal offset
    p[2] ---> Multipicative offset side 1
    p[3] ---> Multiplicative offset side 2
    p[4] ---> Additive offset
    p[5] ---> Width of slit
'''

    return slit_edge_fun(x - p[1], p[0]) * p[2] + p[4] - slit_edge_fun(x 
            - p[1] - p[5], p[0]) * p[3]



def residual(p, x, y, f):
    '''The square of residual is minimized by the least squares fit. 
    Formally this is (f(x | p) - y)**2'''
    return f(p, x) - y

def residual_wavelength(p, x, y):
    return residual(p, x, y, fit_wavelength_model)

def residual_single(p, x, y):
    '''Convenience funciton around residual'''
    return residual(p, x, y, fit_single)

def residual_pair(p, x, y):
    '''Convenience funciton around residual'''
    return residual(p, x, y, fit_pair)

def residual_disjoint_pair(p, x, y):
    '''Convenience funciton around residual'''
    return residual(p, x, y, fit_disjoint_pair)

def residual_bar_edge(p, x, y):
    return residual(p, x, y, fit_bar_edge)


def do_fit(data, residual_fun=residual_single):
    '''do_fit estimates parameters of fit_pair or fit_single.
    
    Use as follows:

    p0 = [0.5, 6, 1.1, 3, 1]
    ys = fit_single(p0, xs)
    lsf = do_fit(ys, residual_single)
    res = np.sum((lsf[0] - p0)**2)

    '''


    xs = np.arange(len(data))

    if residual_fun==residual_single:
        if data[0] > data[-1]:
            p0 = [0.5, len(data)/2., max(data), 0.0, 3.0]
        else:
            p0 = [0.5, len(data)/2., -max(data), 0.0, 3.0]
    elif residual_fun==residual_pair:
        p0 = [0.5, np.argmax(data), max(data), 0.0, 4.0]
    elif residual_fun==residual_disjoint_pair:
        width = 5
        p0 = [0.5, 
                np.argmin(data), 
                -np.ma.median(data[0:3]), 
                -np.ma.median(data[-4:-1]), 
                np.ma.median(data), 
                width]
    else:
        error("residual_fun not specified")
        raise Exception("residual_fun not specified")


    lsf = optimize.leastsq(residual_fun, p0, args=(xs, data), 
            full_output=True)

    return lsf




def do_fit_edge(xs, ys):

    p0 = [ys.mean()]

    return optimize.leastsq(residual_bar_edge, p0, args=(xs, ys))

def polyfit_clip(xs, ys, order, nsig=2.5):

    ff = np.poly1d(np.polyfit(xs, ys, order))
    sd = np.std(ys - ff(xs))

    r = np.abs(ys - ff(xs))
    ok = r < (sd * nsig)
    return np.polyfit(xs[ok], ys[ok], order)

def polyfit_sigclip(xs, ys, order, nmad=4):

    ok = np.ones(len(xs))>0.5

    for i in range(5):
        ff = np.poly1d(np.polyfit(xs[ok], ys[ok], order))
        sd = np.median(np.abs(ys[ok] - ff(xs[ok])))

        r = np.abs(ys - ff(xs))
        ok = r < (sd * nmad)

    return np.polyfit(xs[ok], ys[ok], order)

class TestFitFunctions(unittest.TestCase):

    def setUp(self):
        pass

    def test_do_fit(self):
        import random
        sa = self.assertTrue

        xs = np.arange(19)

        p0 = [0.5, 6, 1.1, 3, 1]
        ys = fit_single(p0, xs)
        lsf = do_fit(ys, residual_single)
        res = np.sum((fit_single(lsf[0],xs) - ys)**2)
        sa(res < 0.001)

    def test_do_fit2(self):
        sa = self.assertTrue
        p0 = [0.5, 6, 1.1, 3, 3]
        xs = np.arange(15)
        ys = fit_pair(p0, xs)

        lsf = do_fit(ys, residual_pair)
        res = np.sum((lsf[0] - p0)**2)
        sa(res < 0.001)


    def test_lhs_v_rhs(self):
        sa = self.assertTrue

        p0 = [0.5, 5, 1.1,.7,0]
        pn0 = [0.5, 5, -1.1,.7,0]
        xs = np.arange(25)
        ys = fit_single(p0, xs)
        lsf = do_fit(ys, residual_single)
        info(str(lsf[0]))

        ys = fit_single(pn0, xs)
        lsf = do_fit(ys, residual_single)
        info(str(lsf[0]))

if __name__ == '__main__':
    unittest.main()


def do_fit_wavelengths(pixels, lambdas, alphaguess, 
        sinbetaguess, gammaguess, deltaguess, band, pixel_y, error=None):

    ''' THIS HSOULD BE REMOVED'''

    bmap = {"Y": 6, "J": 5, "H": 4, "K": 3}
    order = bmap[band]

    
    parinfo = [
            {'fixed': 1, 'value': order, 'parname': 'order', 
                'limited': [0,0], 'limits': [0,0]},
            {'fixed': 1, 'value': pixel_y, 'parname': 'Y',
                'limited': [0,0], 'limits': [0,0]},
            {'fixed': 0, 'value': alphaguess, 'parname': 'alpha', 'step': 1e-5,
                'limited': [0,0], 'limits': [0,0]},
            {'fixed': 0, 'value': sinbetaguess, 'parname': 'sinbeta', 
                'step': 1e-5, 'limited': [0,0], 'limits': [30,50]},
            {'fixed': 0, 'value': gammaguess, 'parname': 'gamma','step': 1e-15,
                'limited': [1,1], 'limits': [0,20e-13]},
            {'fixed': 0, 'value': deltaguess, 'parname': 'delta', 'step': 1e-1,
                'limited': [1,1], 'limits': [0,2048]},
            ]

    fa = {"x": pixels, "y": lambdas}
    if error is not None:
        fa["error"] = error

    lsf = mpfit.mpfit(wavelength_residuals, parinfo=parinfo, functkw=fa, 
            quiet=1, maxiter=20)

    return lsf



