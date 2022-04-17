## Release Notes for v6.0
**2022-04-12**
- Update to the manual including: discussion of new imager, new tables of sensitivities for imager and spectrograph, updates on how to observe with the TRICK NIR TT sensor, discussion of the new exposure time calculator, new discussion of the OSIRIS imager reduction pipeline KAI.
- The OSIRIS imager pipeline is now available as KAI in a seperate repository: [https://github.com/Keck-DataReductionPipelines/KAI](https://github.com/Keck-DataReductionPipelines/KAI)
- Updated installation instructions for Apple M1 architecture.


## Release Notes for v5.0
**2021-02-22**
- New wavelength solution for 2021. OSIRIS had to be opened for servicing in Dec. 2020, so new arc scans were taken in Jan 2021 and new wavelength solutions were created. Tests show that the average wavelength shift at Kn3 35 mas to be about -0.04+-0.07 Angstroms (based on comparisons with OH skylines). At Kn3 50 mas, the shift is on average: 0.38+-0.06 Angstroms. 

## Release Notes for v5.0beta
**2020-09-22**
- New wavelength solution for 2019 & 2020. Unlike data before 2019, there appears to be larger residual offsets in the wavelength solution between different plate scales. The smallest shift is at 50 mas and the grows larger for smaller plate scales. At Kn3 35 mas, the offset is about 0.3 Angstrom based on comparisons with OH sky lines. 
- Handle imager upgrade pixel units (DN) instead of DN/s
- The FITS files from the imager upgrade were flipped such that the images were not in an astronomical orientation.
- QL2 will now flip IMAGER images about the x-axis (IDL-> im=reverse(im,2)) for upgraded images only.  SPEC and DRP cubes are NOT flipped.
- Made a slight update to IDL_astro routine xy2ad.pro to handle WCS in OSIMG images.
- Other minor updates


## Release Notes for v4.2.0
**2018-05-07**
Major Updates
- Derived new wavelength solution for OSIRIS in March 2018, which was required because OSIRIS was opened. All users are recommended to use this version, especially those with data post March 2018.
- **Updated manual** - new installation instructions, wavelength solution, bad pixel mask info, updated information post-2016 detector upgrade are ongoing. Download [here](OSIRIS_Manual_v4.2.pdf)

## Release Notes for v4.1.0
**2017-11-07**
Major Updates
- Includes a new wavelength solution for data after May 2017. A shift in the wavelength solution (on average about 2.8 Angstroms offset) in May 2017 required a re-derivation of the solution. The new solution has an average offset between the observed and vacuum wavelength of OH lines of 0.07 +- 0.06 Angstroms in Kn3 35 mas.
- A preliminary bad pixel mask is available for data taken after 2016 (new spectrograph detector). The mask was computed from a series of darks. There is both a bad pixel mask of hot pixels (pixels with permanently elevated value) as well as a dead pixel mask (pixels with permanently low values). This mask meant to be used as extension 2 in the raw fits files. Currently, the mask is not automatically applied by Keck. To apply it, use the following command in the raw spectra directory once the pipeline is installed:
```
apply_mask.py *.fits
```
NOTE: this requires python installed with ``numpy`` and ``astropy`` packages. Tests show that using the bad pixel mask improves the SNR by about 10%.

- A new keyword is available in the Scaled Sky Subtraction module called ``scale_fitted_lines_only``. To turn on the new behavior, the keyword should be set to YES  and the ``Scale_K_Continuum`` should be set to NO:
```
scale_fitted_lines_only='YES'
Scale_K_Continuum='NO'
```
 This keyword will only scale only OH lines, not the rest of the spectrum as well. This setting greatly improves sky subtraction for the case where the science target fills the lenslets and there are no true sky locations. It may also help in other cases. Users are encouraged to try this option if they see large residuals in sky subtraction, or if the residual continuum is problematic.

- The cosmic ray module is now automatically turned off for all data with the new detector (see reasoning below). Cosmic rays represent about 1% of the bad pixels in a typical 15 minute exposure -- the majority are static bad pixels that should now be accounted for by the bad pixel mask.

## Release Notes for v4.0.0
**2017-01-23**

Major updates:
- Updates to the code in order to run the pipeline for the new detector (2016 data and newer).
- Installation has now been simplified (see below for install directions). Bash scripts have been included for those who would like to use bash shell.
- Test framework is now available to run tests of the pipeline (requires pytest module in python, see README in ''tests'' directory)
- Optimized algorithms for the construction of data cubes
- qlook2, odrfgui, and oopgui are now also included in the repository

Minor Updates:
- WCS bugs have been fixed.
- qlook2 fixes
  - units bug is fixed
  - fix initial autoscale to imager display
  - clean up startup scripts
