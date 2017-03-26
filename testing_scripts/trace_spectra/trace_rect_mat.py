import os
import numpy as np
import pylab as plt
from astropy.io import fits
import extractspectrum
from model_fits import fit_gaussian_peak
import fitter
import time
from scipy.ndimage import gaussian_filter1d,median_filter
from tqdm import tqdm

def trace_rect_example(rectfile='../../tests/calib/s150905_c003___infl_Kbb_035.fits'):
    # trace the rectification matrix. This is an example to show how it works
    if os.path.exists(rectfile):
        hdu = fits.open(rectfile)
        matrix = hdu[2].data
        print 'shape: ',np.shape(matrix)
        newslice = matrix[16,:,:]

        plt.clf()
        plt.subplot(2,1,1)
        plt.imshow(newslice,interpolation='nearest')
        
        #slicerange=[50,500]
        slicerange=[50,2047]
        print 'input shape: ',newslice.shape
        #newslice = newslice.transpose()
        #print 'transposed shape: ',newslice.shape
        lineprofile, fitparams, spectrum = extractspectrum.find_spatial_profile(newslice, 4,slicerange=slicerange)
        tfit, xlocation, ypeak_location,lineprofile, fitparams, spectrum = extractspectrum.trace_fit(newslice,4,slicerange=slicerange,threshold=0.0,return_spectrum=True)
        print fitparams
        plt.subplot(2,1,2)
        plt.plot(xlocation, ypeak_location)
        plt.xlim(0,2048)

def trace_rect(rectfile='../../tests/calib/s150905_c003___infl_Kbb_035.fits',outfile=None,
               width=4,slicerange=[0,2048]):
    '''
    This routine will go through a rectification matrix and trace the scans for each slice
    of the rect. matrix.

    NOTE: in order to map the slices of the rect matrix to spaxel location,
    use LensletMapping.xlsx

    OUTPUT
    ------
    outfile - file to store the output dictionary of the fit. The dictionary
    has keys of the form 'sliceN': (tfit,sampleLoc,peakLoc,lineProfile, fitParams, spectrum)

    Saved as a numpy npy file. To load use a = np.load(outfile), then b= a.items(0) to get the
    dictionary back
    HISTORY
    -------
    2017-03-25 - T. Do
    '''
    if os.path.exists(rectfile):
        hdu = fits.open(rectfile)
        # the slices for the rect matrix are in the second extension
        matrix = hdu[2].data # should be shaped (1216, 16, 2048)
        s = np.shape(matrix)
        outdict = {}

        if outfile is None:
            parts = os.path.split(rectfile)
            outfile = os.path.splitext(parts[-1])[0]+'_trace.npy'
        
        for i in tqdm(range(s[0])):
            newslice = matrix[i,:,:]
            output = extractspectrum.trace_fit(newslice,width=width,slicerange=slicerange,
                                               threshold=0.0)
            outdict['slice'+str(i)] = output

            if (i % 50) == 0:
                print("saving: "+outfile)                
                np.save(outfile,outdict)
        print("saving: "+outfile)
        np.save(outfile,outdict)
    
def trace_sky_kbb20():
    trace_sky(skyfile='raw/s160902_a004005.fits',ycenter=1089,slicewidth=8,
              darkfile='darks/s160902_a004002_combo_600s_Drk.fits',
              whitelightfile='raw/s160902_a004011.fits',
              whitelightdark='darks/s160902_a019007_combo_10s_Drk.fits')
    
def trace_sky_kbb50():
    trace_sky(skyfile='raw/s160902_a009006.fits',ycenter=1025,slicewidth=8,
              darkfile='darks/s160902_a004002_combo_600s_Drk.fits',
              whitelightfile='raw/s160902_a010018.fits',
              whitelightdark='darks/s160902_a019002_combo_1-5s_Drk.fits')
    
def trace_sky(skyfile='raw/s160902_a009004.fits',ycenter=1089,slicewidth=8,
              darkfile='darks/s160902_a004002_combo_600s_Drk.fits',
              whitelightfile='raw/s160902_a004014.fits',
              whitelightdark='darks/s160902_a019017_combo_50s_Drk.fits'):
    # trace the rectification matrix
    if os.path.exists(skyfile):
        hdu = fits.open(skyfile)
        im = hdu[0].data

        dark = fits.getdata(darkfile)
        im = im - dark
        
        newslice = im[ycenter-slicewidth:ycenter+slicewidth,:]
        newpeak = slicewidth
        width=6
        plt.clf()
        plt.subplot(3,1,1)
        time1 = time.time()
        plt.imshow(newslice,interpolation='nearest',origin='lower',vmin=0,vmax=3)
        plt.xlim(500,600)
        
        slicerange=[300,1825]
        print 'input shape: ',newslice.shape
        #newslice = newslice.transpose()
        #print 'transposed shape: ',newslice.shape
        #lineprofile, fitparams, spectrum = extractspectrum.find_spatial_profile(newslice, newpeak,slicerange=slicerange,width=width)
        #tfit, xlocation, ypeak_location = extractspectrum.trace_fit(newslice,newpeak,slicerange=slicerange,width=width)

        xlocation, sky_fitparams = extractspectrum.simple_trace_fit(newslice,slicerange=slicerange)
        ypeak_location = sky_fitparams[2,:]
        sky_fwhm = sky_fitparams[3,:]
        
        # save the locations in a file
        output = open('sky_trace.txt','w')
        for i in xrange(len(xlocation)):
            output.write('%f %f\n' % (xlocation[i],ypeak_location[i]))
        output.close()
                        
        plt.plot(xlocation, ypeak_location-0.5,'--',linewidth=3,color='black')
        
        plt.subplot(3,1,2)
        plt.plot(xlocation, ypeak_location,label='Sky Peak Position')
        plt.xlim(0,2048)
        

        # look at white light scans
        
        cal = fits.getdata(whitelightfile)
        cal_dark = fits.getdata(whitelightdark)

        cal = cal - cal_dark

        calslice = cal[ycenter-slicewidth:ycenter+slicewidth,:]
        #caltfit, calxlocation, calypeak_location = extractspectrum.trace_fit(calslice,newpeak,slicerange=slicerange,width=width)
        calxlocation, cal_fitparams = extractspectrum.simple_trace_fit(calslice,slicerange=slicerange)

        calypeak_location = cal_fitparams[2,:]
        cal_fwhm = cal_fitparams[3,:]
        
        plt.plot(calxlocation,calypeak_location,label='White Light Peak Location')
        plt.xlabel('X location (pix)')
        #plt.ylabel('Relative Y location (pix)')
        plt.legend(loc=3)
        plt.ylim(6,10)
        # save the locations in a file
        output = open('white_light_trace.txt','w')
        for i in xrange(len(xlocation)):
            output.write('%f %f\n' % (calxlocation[i],calypeak_location[i]))
        output.close()

        plt.subplot(3,1,3)
        #plt.plot(xlocation,sky_fwhm,label='Sky FWHM')
        #plt.plot(xlocation,cal_fwhm,label='White Light FWHM')
        smooth_peak_diff = median_filter(ypeak_location - calypeak_location,size=5)
        smooth_fwhm_diff = median_filter(sky_fwhm - cal_fwhm,size=5)
        plt.plot(xlocation,smooth_peak_diff,label='Peak Difference')
        plt.plot(xlocation,smooth_fwhm_diff,label='FWHM Difference')
        #plt.plot(xlocation,calypeak_location - ypeak_location)
        plt.ylabel('Difference (pix)')
        plt.xlabel('X location (pix)')
        print 'mean peak position difference (sky - cal)',np.mean(smooth_peak_diff),np.std(smooth_peak_diff)
        print 'mean FWHM difference (sky - cal)',np.mean(smooth_fwhm_diff),np.std(smooth_fwhm_diff)
        plt.xlim(0,2048)
        plt.ylim(-0.4,0.4)
        plt.legend()
        time2 = time.time()
        
        print 'time: ',time2-time1
        
def check_profile(skyfile='raw/s160902_a009004.fits',ycenter=1089,slicewidth=8,
                  darkfile='darks/s160902_a004002_combo_600s_Drk.fits',
                  whitelightfile='raw/s160902_a004014.fits',xpos = [501,1650],
                  whitelightdark='darks/s160902_a019017_combo_50s_Drk.fits'):
    # check the 1D profile
    if os.path.exists(skyfile):
        hdu = fits.open(skyfile)
        im = hdu[0].data

        dark = fits.getdata(darkfile)
        im = im - dark
        
        newslice = im[ycenter-slicewidth:ycenter+slicewidth,:]
        newpeak = slicewidth        
        print np.shape(newslice)
        
        s = np.shape(newslice)

        cal = fits.getdata(whitelightfile)
        cal_dark = fits.getdata(whitelightdark)

        cal = cal - cal_dark

        calslice = cal[ycenter-slicewidth:ycenter+slicewidth,:]

        
        xloc,yloc = np.loadtxt('sky_trace.txt',unpack=True)
        
        plt.clf()
        plt.subplot(2,1,1)
        plt.imshow(newslice,vmin=0,vmax=3.0,origin='lower',interpolation='nearest',
                   extent=(0,s[1],0,s[0]))
        plt.plot(xloc,yloc,'--',linewidth=3,color='black')
        plt.xlim(450,550)
        plt.subplot(2,1,2)
        yarr = np.arange(0,s[0])        


        print 'previous fit location: ',yloc[xloc == 501.0]
        for ind in xpos:
            tempcol = newslice[:,ind]
            tempcol = tempcol/tempcol.sum()
            tempcal = calslice[:,ind]
            tempcal = tempcal/tempcal.sum()
            peak_model_fit = fit_gaussian_peak(yarr,tempcol,guess=[0.0,1.0,9.0,1.0])
            cal_peak_model_fit = fit_gaussian_peak(yarr,tempcal,guess=[0.0,1.0,9.0,1.0])            
            print 'sky: ',peak_model_fit.parameters
            print 'cal: ',cal_peak_model_fit.parameters
            plt.plot(yarr,tempcol,label='Sky x='+str(ind))
            plt.plot(yarr,tempcal,label='White light x='+str(ind))
            plt.plot(yarr,peak_model_fit(yarr),'--')
            plt.plot(yarr,cal_peak_model_fit(yarr),'--')
        plt.legend()
        
def diff_frames(skyfile='raw/s160902_a009004.fits',
              darkfile='darks/s160902_a004002_combo_600s_Drk.fits',
              whitelightfile='raw/s160902_a004014.fits',
              whitelightdark='darks/s160902_a019017_combo_50s_Drk.fits'):
    # diff the single column sky and the single column white light scan
    hdu = fits.open(skyfile)
    im = hdu[0].data

    dark = fits.getdata(darkfile)
    im = im - dark

    hdu2 = fits.open(whitelightfile)
    whitelight = hdu2[0].data
    cal_dark = fits.getdata(whitelightdark)

    whitelight = whitelight - cal_dark
    scale = 1.0/100.0
    hdu[0].data = im - whitelight*scale
    hdu.writeto('sky_whitelight_diff.fits',clobber=True)
        
