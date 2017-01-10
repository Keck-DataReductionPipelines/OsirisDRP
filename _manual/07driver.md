---
layout: page
title: The driver.py File
permalink: /manual/driver
---

The driver file controls all the pipeline steps, and in the drivers sub-directory, you will find a number of driver files: `Driver.py`, `K_Driver.py`, `Long2pos_driver.py`, and `Longslit_Driver.py`. The `Driver` and `K_Driver` will reduce your science data for bands Y,J, and H (this includes the sample data set). The K band requires a special approach because there are too few bright night-sky emission lines at the red end and so the `K_Driver` synthesizes arclamps and night sky lines. The `Long2pos_driver.py` handles `long2pos` and `long2pos_specphot` observations, while the `Longslit_driver.py` deals with observations of single objects using a longslit configuration.
 
The driver.py files included with the code download contains execution lines that are commented out. For this example, we will run the driver file one line at a time, but as you become familiar with the DRP process, you will develop your own driver file execution sequencing. Although in the future we hope to further automate the driver file, currently some steps require you to update the inputs with filenames created from previous steps. 

Below is a driver.py file:

    import os, time
    import MOSFIRE
    
    from MOSFIRE import Background, Combine, Detector, Flats, IO, Options, \
         Rectify
    from MOSFIRE import Wavelength
    
    import numpy as np, pylab as pl, pyfits as pf
    
    np.seterr(all="ignore")
    
    #Update the insertmaskname with the name of the mask
    #Update S with the filter band Y,J,H,or K
    maskname = 'insertmaskname'
    band = 'S'    
    
    flatops = Options.flat
    waveops = Options.wavelength
    
    obsfiles = ['Offset_1.5.txt', 'Offset_-1.5.txt']
    
    #Flats.handle_flats('Flat.txt', maskname, band, flatops)
    #Wavelength.imcombine(obsfiles, maskname, band, waveops)
    #Wavelength.fit_lambda_interactively(maskname, band, obsfiles,
        #waveops)
    #Wavelength.fit_lambda(maskname, band, obsfiles, obsfiles,
        #waveops)

    #Wavelength.apply_lambda_simple(maskname, band, obsfiles, waveops)
    #Background.handle_background(obsfiles,
        #'lambda_solution_wave_stack_H_m130429_0224-0249.fits',
        #maskname, band, waveops)

    redfiles = ["eps_" + file + ".fits" for file in obsfiles]
    #Rectify.handle_rectification(maskname, redfiles,
    #    "lambda_solution_wave_stack_H_m130429_0224-0249.fits",
    #    band, 
    #    "/scr2/npk/mosfire/2013apr29/m130429_0224.fits",
    #    waveops)
    #

To set up your driver file do the following:

1. Navigate to the desired output directory created by handle: `cd ~/Data/reducedMOSFIRE_DRP_MASK/2012sep10/H`
2. Copy the appropriate driver file: `cp ~/MosfireDRP-master/drivers/Driver.py .`  NOTE: If you are observing a K band mask you’ll want to copy the `K_driver.py` file over.
3. Edit driver.py (see bold text in driver file example)
    * Update maskname
    * Update band to be Y,J,H
    * Update the `Offset_#.txt` name. Handle creates offset files with names that are specific to the nod throw. The default driver file uses 1.5 arcsec offsets in the file name. 

In the sections that follow, we will describe the function and outputs of the commented lines found in the driver file starting with the creation of flats.

If you prefer to override the standard naming convention of the output files, you can specify

    target = “targetname” 

at the beginning of the driver file. If you do so, remember to also add target=target to both the Background and Rectify steps. Example:

    Background.handle_background(obsfiles,
        'lambda_solution_wave_stack_H_m150428_0091-0091.fits',
        maskname, band, waveops, target=target)









