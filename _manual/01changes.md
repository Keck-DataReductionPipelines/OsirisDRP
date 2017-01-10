---
layout: page
title: Changes in Version 2016
permalink: /manual/changes
---

__Important Note__: The [Ureka package has been deprecated](http://ssb.stsci.edu/ureka/) as of April 26, 2016.  As a result, the MOSFIRE pipeline has migrated to a version which is not dependent on IRAF/PyRAF, but only on python packages.  It should work with any python install which provides the required packages and versions.

### New features

* DRP is no longer dependent on IRAF/PyRAF
    * The use of IRAF's `geoxytran`, `imcombine`, and `imarith` tasks have been replaced with python equivalents.
    * The DRP should now work with any python install which has the [required python packages](/manual/installing#Requirements)
* Improved slit tracing using a better thresholding algorithm
* An updated (and now web based) [instruction manual](http://keck-datareductionpipelines.github.io/MosfireDRP/)
* The DRP now performs optimal spectral extraction [Horne 1986](http://adsabs.harvard.edu/abs/1986PASP...98..609H) and outputs a 1D spectrum.  Please note that this is intended as a quick look tool, not for final science use.
* The `handle` step now writes `filelist.txt` which contains a list of all the files processed by `handle` instead of printing that output to the screen.  The file also contains messages for files not categorized for processing explaining why.  In addition, `handle` now no longer writes list files with no content.  This is intended to make it easier to quickly see what files are available for reduction.


### Improvements and bug fixes

* Changed dependence on `pylab` to `matplotlib.pyplot`
* Uses `astropy.io.fits` instead of `pyfits` when available
* Adjust log messages to send more to DEBUG instead of INFO.  Leads to less clutter in messages visible to user.


## Changes in Version 2015A

### New features

* Reduction of long2pos and long2pos_specphot
* Reduction of longslit data
* Automatic generation of driver file
* Logging and diagnostic information on screen and on disk
* Package-style installation as a Ureka sub-package
* Support for Ureka 1.5.1

### Improvements and bug fixes

* Fix incorrect determination of the slit parameters which prevented the use of large slits
* Fix incorrect determination of the average wavelength dispersion for the long2pos mode
* Added ability of specifying the output name of the files
* Improved robustness of non-interactive wavelength solution, added possibilty of switching from interactive to non-interactive during the reduction, added k-sigma clipping of the sky or arc lines
* Fixed the problem with the interactive wavelength window not closing at the end of the fit
* Fixed the problem with the interactive fitting window showing up empty on the first fit (no need to use the x key to unzoom)
* Added procedure to fix the header of old images acquired with an outdated version of long2pos
* Disabled cosmic ray rejection for the case of less than 5 exposures
* There is no need to specify one of the observations in Rectify: Rectify will use the first of the files listed in the Offset files.
