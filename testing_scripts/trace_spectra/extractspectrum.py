"""
==================================
MOSFIRE spectrum extraction

Modules for extracting point sources from MOSFIRE spectra

"""


import os
import numpy as npy
from astropy.io import fits
from pylab import *
import fitter as Fit
from scipy import stats
import model_fits
#from model_fits import fit_gaussian_peak
from astropy.modeling import models, fitting
def find_wavelength(fileName,y = None):
    '''
    Get the wavelengths corresponding to each pixel for a rectified MOSFIRE spectrum

    INPUT: fileName - fits file of the spectrum that is rectified by
    the pipeline, or the file with the wavelength solution if the y
    value is given.

    y - optional input to return the wavelength solution at a given y
    value.


    OUTPUT: array corresponding to the wavelength for each x value
    '''
    if os.path.isfile(fileName):
        hdulist = fits.open(fileName)
        header = hdulist[0].header
        xvals = np.arange(header['NAXIS1'])
        wavelengths = header['CRVAL1']+xvals*header['CD1_1']-(header['CRPIX1']-1)*header['CD1_1']
        return wavelengths
    else:
        print 'File does not exist: '+fileName


def find_spatial_profile(inputArr, startloc, width = 2, varImage = False,
                       order = 2,debug=False,threshold=9,simpleExtract = False,
                       extractMax = False, wavefile = None,slicerange=None):
    """ Collapse the spectrum so that we can compute spatial profile
    as a function of wavelength. The steps are as follows

    Starting from a given position along the spatial dimension,
    extract the closests few pixels, controlled by the 'width'
    keyword.

    Then, nomalize the light along the pixels along the spatial dimension

    Fit for the fraction of light in each pixel as a function of
    wavelength.

    Iteratively remove cosmic rays/bad pixels

    NOTE: right now, this routine does not use a variance image, which
    will be necessary to implement the 'optimal extraction' routine
    from Horne 1986

    INPUTS: inputArr - can be a string with a fits file, or an numpy
                       array with the spectrum image [y, x]
            startloc - location along the spatial direction (Y) to
                       center the extraction.
            wavefile - the fits file containing the wavelength solution
                       for the different locations in the detector. If
                       this is set, instead of returning fitParams, it
                       will return the weighted wavelength corresponding
                       to the input spectrum

    OPTIONAL INPUTS:
            threshold - threshold for the variance in which to clip
                        bad points

    KEYWORDS: extractMax - extract around the maximum index collapsed
    in the wavelength direction. Will ignore the 'startloc' input
    parameter in this case, replacing it with the max index


    OUTPUT:
          lineProfile - lineProfile with the fraction of light in each pixel
          fitParams - the fit parameters per wavelength channel (or wavelength
          corresponding to the input spectrum if 'wavefile' is used)
          spec - the final extracted spectrum

    HISTORY: 2013-08-27 - T. Do
    """

    # test to see if the input is a string, if it is, then assume it
    # is a fits file. Otherwise, assume that is a numpy array

    if type(inputArr) is str:
        hdulist = fits.open(inputArr)
        image = hdulist[0].data
    else:
        # copy the input array so we don't accidentially change it
        image = np.copy(inputArr)

    if wavefile is not None:
        wavehdu = fits.open(wavefile)
        waveSol = wavehdu[0].data

    varWidth = 10 # region before and after the current index to calculate the variance.


    if extractMax:
        medSlice = np.nanmedian(image,axis=1)
        startloc = np.nanargmax(medSlice)

    s = np.shape(image)
    startInd = startloc - width
    endInd =startloc +width
    if (startInd) < 0:
        startInd = 0
    if endInd >= s[0]:
        endInd = s[0]-1

    rawSlice = np.array(image[startInd:endInd,:])
    if wavefile is not None:
        waveSlice = waveSol[startInd:endInd,:]

    # if simpleExtract is given, then us sum the values
    if simpleExtract:
        return (np.zeros(endInd-startInd+1)+1.0/(endInd-startInd+1),[1],np.sum(rawSlice,axis=0))

    # normalize each slice

    sliceShape = np.shape(rawSlice)
    if debug:
        print 'starting total flux at 1300: ',np.sum(rawSlice[:,1300])
        print 'slice shape: ',np.shape(rawSlice)


    specSlice = rawSlice/np.sum(rawSlice,axis=0)
    mask = np.ones(sliceShape)
    mask[np.isfinite(specSlice)]= 0

    specSlice = np.ma.array(specSlice,mask=mask)
    #plot(specSlice[0,:])
    #plot(specSlice[3,:])

    #plot(specSlice[4,:])
    #ylim(0,1.1)
    if debug:
        clf()
        subplot(221)
        ylim(0,25)
        xlim(0,2500)

    xArr = np.arange(sliceShape[1])

    # initial polynomial fit to the profile
    fitParams = fit_spatial_profile_helper(specSlice,order = order)

    # ================ second iteration ===================
    # go back and remove all the bad pixels and cosmic rays
    stdev = np.ma.std(specSlice,axis=0)

    for i in np.arange(sliceShape[0]):
        # difference between observed and the fitted value
        row = np.copy(specSlice[i,:])
        rowDiff = specSlice[i,:] - np.polyval(fitParams[i,:],xArr)
        rowDiff = rowDiff.compressed()
        # only take a small window around the current point
        if i - varWidth < 0:
            startVarInd = 0
        else:
            startVarInd = i - varWidth

        if i + varWidth >= sliceShape[0]:
            endVarInd = sliceShape[0]-1
        else:
            endVarInd = i+varWidth


        variance = np.std(rowDiff[startVarInd:endVarInd])**2

        if debug:
            plot(rowDiff**2/variance)
            xlabel('x pixel')
            ylabel('rowDiff**2/variance')

        badPts = np.where(((rowDiff**2/variance) > threshold) & isfinite(rowDiff))[0]
        if i == 1:
            # save one of the bad pixels to test later
            if len(badPts) > 0:
                testBadInd = badPts[0]
                validBadPtTest = True
            else:
                validBadPtTest = False
        if debug:
            print specSlice[i,badPts]
            print 'variance: ',variance
            print 'n bad points: ', len(badPts)
            if len(badPts) > 1:
                print 'bad points:'
                print 'sum of profile at one of the bad points: ',badPts[1],specSlice[:,badPts[1]]

        row[badPts] = nan
        specSlice.mask[i,badPts] = 1
        specSlice.data[i,:] = row



    if debug:
        subplot(222)
        n, bins, patches = hist(rowDiff,bins=20,range=[np.median(rowDiff)-3*np.std(rowDiff),np.median(rowDiff)+3*np.std(rowDiff)])
        xlabel('Difference in Observed vs. Fitted Light Fraction')
        # check that all spatial locations are actually normalized

        subplot(223)

    fitParams = fit_spatial_profile_helper(specSlice,order = order,mkplots=debug)

    # ================ third iteration ===================
    # go back and remove all the bad pixels and cosmic rays

    if debug:
        print 'stdev :',stdev
    for i in np.arange(sliceShape[0]):
        # difference between observed and the fitted value
        rowDiff = specSlice[i,:] - np.polyval(fitParams[i,:],xArr)

        # only take a small window around the current point
        if i - varWidth < 0:
            startVarInd = 0
        else:
            startVarInd = i - varWidth

        if i + varWidth >= sliceShape[0]:
            endVarInd = sliceShape[0]-1
        else:
            endVarInd = i+varWidth


        variance = np.std(rowDiff[startVarInd:endVarInd])**2

        badPts = np.where((rowDiff**2/variance > threshold) & isfinite(rowDiff))[0]
        if len(badPts) > 0:
            specSlice.mask[i,badPts] = 1
            specSlice.data[i,badPts] = nan


    fitParams = fit_spatial_profile_helper(specSlice,order = order,mkplots=False)

    # now make an array of weights using the fitted polynomials
    lineProfile = np.ma.array(np.zeros(sliceShape))

    for j in np.arange(sliceShape[0]):
        lineProfile[j,:] = np.polyval(fitParams[j,:],xArr)

    # make everything positive
    lineProfile[lineProfile < 0] = 0

    # normalize the line profile
    lineProfile = lineProfile/np.ma.sum(lineProfile,axis=0)

    # return the line profile, fit, and weighted extracted spectrum
    extractedSpectrum = np.sum(rawSlice*lineProfile,axis=0)/np.sum(lineProfile,axis=0)
    if wavefile is not None:
        wavelengths = np.sum(waveSlice*lineProfile,axis=0)/np.sum(lineProfile,axis=0)

    if debug and validBadPtTest:
        print 'ending total of rawslice at test pixel: ',testBadInd, np.ma.sum(rawSlice[:,testBadInd])
        print 'spectrum at test pixel: ',rawSlice[:,testBadInd]
        print 'spectrum at test pixel - 1: ',rawSlice[:,testBadInd-1]
        print 'spectrum at test pixel + 1: ',rawSlice[:,testBadInd+1]
        print 'line profile at test pixel: ',lineProfile[:,testBadInd]
        print 'weights: ',np.ma.sum(lineProfile[:,testBadInd])
        print 'ending total flux at test pixel: ',extractedSpectrum[testBadInd]

    del image
    if wavefile is not None:
        return (lineProfile, wavelengths, extractedSpectrum)
    else:
        return (lineProfile, fitParams, extractedSpectrum)

def fit_spatial_profile_helper(inputArr,order = 2, mkplots = False):
    """ used by fitSpatialProfile to fit a polynomial to each spatial
    location for the detector.
    """
    inShape = np.shape(inputArr)
    #print type(inputArr)
    inX = np.arange(inShape[1])
    outParams = np.zeros((inShape[0],order+1))
    for i in np.arange(inShape[0]):
        if mkplots:
            plot(inX,inputArr[i,:])

        # take the median of 2 slices around the each point to get rid
        # of bad pixels
        if i - 2 >= 0:
            iStart = i - 2
        else:
            iStart = 0

        if i + 2 > inShape[0]:
            iEnd = inShape[0] - 1
        else:
            iEnd = i+2

        row = np.nanmedian(inputArr[iStart:iEnd,:],axis=0)
        goodPts = np.where(isfinite(row))[0]
        if len(goodPts) > 0:
            fitParams = np.ma.polyfit(inX[goodPts],row[goodPts],order)
            outParams[i,:]=fitParams

            if mkplots:
                print fitParams
                plot(inX,np.polyval(fitParams,inX))

                xlabel('x pixel')
                ylabel('Fraction of starlight in pixel')
                text(inX[goodPts[0]],np.polyval(fitParams,inX[goodPts[0]]),i)
    return outParams

def simple_trace_fit(inputArr,slicerange=None):
    '''
    Assume the input array only has a single line and do the trace
    with a Gaussian fit.

    '''
    s = np.shape(inputArr)
    if slicerange is not None:
        sampleLoc = np.arange(slicerange[0],slicerange[1])
    else:
        sampleLoc = np.arange(0,s[1])

    fitarr = np.zeros((4,len(sampleLoc)))
    yarr = np.arange(s[0])
    for i in xrange(len(sampleLoc)):
        ind = sampleLoc[i]
        tempcol = inputArr[:,ind]
        tempfit = fit_gaussian_peak(yarr,tempcol)
        fitarr[:,i] = tempfit.parameters

    return (sampleLoc, fitarr)


def trace_fit(inputArr,startloc = None,width=5,order=2,debug=False,slicerange=None,nsamples=25,
              xlim=None,return_spectrum=False,threshold=None):
    ''' Traces a spectrum across the detector and determine the best
    fit y values as a function of x.

    INPUTS: inputArr - either a numpy array or a FITS filename
            startloc - the y index to center the extraction for the slit

    KEYWORDS:
    threshold - a threshold for the flux. If no points are above or
         equal to the threshold, then do not fit that slice. (default: None)

    OUTPUT: (coefficients for polyfit, x position, y peak locations)
    '''
    if type(inputArr) is str:
        hdulist = fits.open(inputArr)
        image = hdulist[0].data
    else:
        # copy the input array so we don't accidentially change it
        image = np.copy(inputArr)

    if debug:
        clf()

    if startloc is None:
        # collapse the image across the x direction
        testSlice = np.median(inputArr,axis=1)

        # use the brightest point as the part to extract
        startloc = np.argmax(testSlice)

        if debug:
            subplot(2,1,1)
            plot(testSlice)
            print 'maximum at: '+str(startloc)

    # we don't need all the functions of fitSpatialProfile, but it
    # does give us the spatial profile of the line


    s = np.shape(image)

    startInd = startloc - width
    endInd =startloc +width
    if (startInd) < 0:
        startInd = 0
    if endInd >= s[0]:
        endInd = s[0]-1

    yArr = np.arange(startInd,endInd)

    lineProfile, fitParams, spectrum = find_spatial_profile(image,startloc,width=width,simpleExtract =True)

    if xlim is None:
        xlim = np.array([0,s[1]])

    if slicerange is not None:
        sampleLoc = np.arange(slicerange[0],slicerange[1])
    else:
        sampleLoc = np.arange(xlim[0],xlim[1],s[1]/nsamples)

    peakLoc = np.zeros(len(sampleLoc))

    # setup the fitting models
    g1 = models.Gaussian1D(amplitude=1.0,mean=3.0,stddev=1.0)
    amp = models.Const1D(0.0)
    peak_model = amp + g1
    fitter = fitting.LevMarLSQFitter()

    #peak_model_fit = fitter(peak_model,x,y)
    # the line profile from find_spatial_profile does not seem to work well, so
    # just use the whole slice

    lineProfile = image
    imshape = np.shape(image)
    yArr = np.arange(imshape[0])
    for i in arange(len(sampleLoc)):
        tempSlice = lineProfile[:,sampleLoc[i]]
        if threshold is not None:
            above_threshold = np.where(tempSlice >= threshold)[0]
            if len(above_threshold) > 0:
                offset = np.min(tempSlice)
                #guess = [offset, np.max(tempSlice)-offset,x[np.argmax(tempSlice)],1.0]
                peak_model.amplitude_0 = offset  # this is the offset
                peak_model.amplitude_1 = np.max(tempSlice)-offset # amplitude of Gaussian1D
                peak_model.mean_1 = yArr[np.argmax(tempSlice)] # location of peak of Gaussian1D
                peak_model.stddev_1 = 1.0
                gfit = fitter(peak_model,yArr,tempSlice)
                #gfit = model_fits.fit_gaussian_peak(yArr,tempSlice)
                peakLoc[i] = gfit.parameters[2]
        else:
            offset = np.min(tempSlice)
            #guess = [offset, np.max(tempSlice)-offset,x[np.argmax(tempSlice)],1.0]
            peak_model.amplitude_0 = offset  # this is the offset
            peak_model.amplitude_1 = np.max(tempSlice)-offset # amplitude of Gaussian1D
            peak_model.mean_1 = yArr[np.argmax(tempSlice)] # location of peak of Gaussian1D
            peak_model.stddev_1 = 1.0
            gfit = fitter(peak_model,yArr,tempSlice)
            #gfit = model_fits.fit_gaussian_peak(yArr,tempSlice)
            peakLoc[i] = gfit.parameters[2]
            #gfit = model_fits.fit_gaussian_peak(yArr,tempSlice)
            #peakLoc[i] = gfit.parameters[2]

    if debug:
        subplot(2,1,2)
        plot(sampleLoc,peakLoc,'bo')

    # fit a polynomial to the peaks
    tfit = np.polyfit(sampleLoc,peakLoc,order)

    if debug:
        plot(sampleLoc,np.polyval(tfit,sampleLoc))

    del image
    if return_spectrum:
        return (tfit,sampleLoc,peakLoc,lineProfile, fitParams, spectrum)
    else:
        return (tfit, sampleLoc, peakLoc)


def clipped_mean(arr,sig=2.0,maxiter=5,nconverge=0.02):
    ''' returns the clipped mean

    Does an interative sigma clipping. Clipping is done about the
    median, but the mean is returned. Based on the idl routine
    MEANCLIP.pro
    '''

    goodVal = np.where(np.isfinite(arr))[0]
    ct = len(goodVal)
    niter = 0
    lastct = 0
    #print goodVal

    while (niter < maxiter) and (ct > 0) and (float(np.abs(ct-lastct))/float(ct) > nconverge):
        #print niter
        lastct = np.copy(ct)
        skpix = arr[goodVal]
        #medVal = np.median(skpix)
        meanVal = np.mean(skpix)
        stdVal = np.std(skpix)
        niter += 1
        #print abs(skpix - medVal)
        #print sig*stdVal
        wsm = np.where((abs(skpix - meanVal) < sig*stdVal))[0]
        ct = len(wsm)
        if ct > 0:
            goodVal = wsm

    return meanVal

def rmcontinuum(wave,flux,order=2):
    '''
    Removes the continuum an normalize a spectrum by fitting a
    polynomial and dividing the spectrum by it.

    2014-02-20 - T. Do
    '''

    # only fit points that are finite and not zero
    goodPts = np.where((flux != 0) & isfinite(flux))[0]

    pFit = np.polyfit(wave[goodPts],flux[goodPts],order)

    return flux/np.polyval(pFit,wave)

def test_extract():
    rectfile = '../../tests/calib/s150905_c003___infl_Kbb_035.fits'
    hdu = fits.open(rectfile)
    matrix = hdu[2].data
    print 'shape: ',np.shape(matrix)
    newslice = matrix[0,:,:]


    lineProfile, fitParams, spectrum = find_spatial_profile(newslice,0,width=4,extractMax =True)
    print spectrum
    plt.clf()
    plt.plot(spectrum)
