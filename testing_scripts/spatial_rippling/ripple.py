import pylab as py
from scipy import signal
import numpy as np
import pyfits
import math
import sys
from astropy.stats import sigma_clip
pi = math.pi


def ripplingMetric(file='s160711_a013002_Kbb_035_RMS.fits',row=10,gain=2.75,makePlot=False,minFpow=-2.0,
                   maxFpow=1.0,numF=1e5,title='line_integrate',sigma=3.0,itime=900.0):


    '''
    Output: (1) STD across selected row in image (electrons) (2) sqrt of mean in row (electrons) (3) ratio of 1 to 2
    (4) sigma clipped max - min difference across the row (flux) (5) mean in row (flux) (6) ratio of 4 to 5
    OPTIONAL: output plot of flux vs column value in that row and power spectrum in that row vs period (pixels)
    '''

    #Note on GAIN keyword is 2.75 for 2016 and later (new detector), change to 5.6 for old detector, pre 2016
    #####IMPORTANT^^^^^^*********

    #-file is the fits file that has already been integrated over the desired wavelength/channel range
    #-row is the row over which to test
    #-makePlot makes a plot that shows the integrated flux over row and the power spectrum over period
    #-min and maxFpow are the power index ranges for the power spectrum (in FREQUENCY)
    #-numF is the number of frequencies (or periods) tested in Lomb Scargle
    #-title is the title for the optional output plot
    #-sigma value for the sigma for the clipping used for the max min difference calculation
    #-itime is the integration time of the fits file in question, seconds

    
    datafile = pyfits.open(file)
    data = datafile[0].data

    rowVal = data[row,:]

    #compare std to sqrt of mean, in electron
    std_row = np.std(rowVal)*gain*itime #electrons
    sqrt_mean = math.sqrt(np.mean(rowVal*gain*itime)) #electrons

    #compare max - min to mean
    clipped = sigma_clip(rowVal,sigma=sigma)
    max_min = np.max(clipped)-np.min(clipped)
    mean_flux = np.mean(rowVal)

    
    if (makePlot==True):
        pixels = np.linspace(1.0,len(rowVal),len(rowVal))
        tfreq = 10**np.linspace(minFpow,maxFpow,numF)
    
        noZero = np.where(rowVal > 0.0)[0]
        rowVal = rowVal[noZero]
        pixels = pixels[noZero]

        pgram = signal.lombscargle(pixels,rowVal.byteswap().newbyteorder().astype('float64'),tfreq)

        py.clf()
        py.axes([0.1,0.7,0.85,0.25])
        py.plot(pixels,rowVal)
        py.xlabel('Pixels')
        py.ylabel('Integrated Flux')

        py.axes([0.1,0.12,0.85,0.45])
        py.plot(2*pi/tfreq,pgram)
        py.xscale('log')
        py.xlabel('Period (pixel)')

        py.savefig('../'+title+'_row'+str(row)+'.png')


    return std_row, sqrt_mean,std_row/sqrt_mean, max_min, mean_flux, max_min/mean_flux



def sumLine(filename,min_pixel,max_pixel,sumRow,outname):
    '''
    Output - RMS across entire image and RMS across chosen row
    '''

    #filename - path of file to import
    #min_ and max_pixel, limits, in pixels, to sum over
    #sumRow - individual row to test
    #outname - name of output .fits file with just integrated flux across chosen pixels
    
    file = pyfits.open(filename)
    data = file[0].data
    hdr = file[0].header
    sizeLambda = data.shape[2]

    min_image_lambda = hdr['CRVAL1']
    delta_lambda = hdr['CDELT1']

    if (min_pixel >= max_pixel):
        sys.exit("Max lambda needs to be greater than min lambda")

    if (min_pixel < 0):
        sys.exit("Selected minimum wavelength is off detector")

    if (max_pixel > sizeLambda):
        sys.exit("Selected maximum wavelength is off detector")

    onlyLine = data[:,:,min_pixel:max_pixel]
    sumLine = np.sum(onlyLine,axis=2)

    sumRowOnly = sumLine[:,sumRow]

    totalRMS = np.std(sumLine)
    rowRMS = np.std(sumRowOnly)

    sumLine = np.transpose(sumLine)
    pyfits.writeto(outname,sumLine,clobber=True)

    return totalRMS, rowRMS
