# Keck OSIRIS Spectroscopic Data Reduction Pipeline

* [Release Notes for v6.0](#release-notes-for-v6.0)
* [Important Runtime Notes](#important-runtime-notes)
* [Installation](#installation)
* [Running the Pipeline](#running-the-pipeline)
* [Testing the Pipeline](#testing-the-pipeline)
* [Citing the Pipeline](#citing-the-pipeline)

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

**Previous Release Notes**

For older release notes see: RELEASE_NOTES.md

## Important Runtime Notes

**Cosmic Ray Module**
- We do not recommend running the cosmic ray module on data in 2016 or later, as it will introduce significant artifacts and reduce overall signal to noise. This is due to the fact that unresolved emission lines such as OH lines are now sharper on the detector. The cosmic ray module will tend to interpret this as a cosmic ray. To remove cosmic rays, we recommend combining data with the mosaic module with the MEANCLIP keyword if there are sufficient number of frames.
- The cosmic ray module may lead to artifacts in data before 2016 as well, but at a lesser level. We recommend checking on individual science cases.
- The pipeline team is investigating different cosmic ray modules for
a future release.
- More information is available in [Issue 49](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/49) or in the [wiki](https://github.com/Keck-DataReductionPipelines/OsirisDRP/wiki/Tests:-cosmic-ray-module).

**Bad pixel mask**
A preliminary bad pixel mask is available for data taken after 2016 (new spectrograph detector). The mask was computed from a series of darks. There is both a bad pixel mask of hot pixels (pixels with permanently elevated value) as well as a dead pixel mask (pixels with permanently low values). This mask meant to be used as extension 2 in the raw fits files. Currently, the mask is not automatically applied by Keck. To apply it, use the following command in the raw spectra directory once the pipeline is installed:
```
apply_mask.py *.fits
```

NOTE: this requires python installed with ``numpy`` and ``astropy`` packages. Tests show that using the bad pixel mask improves the SNR by about 10%.

**Old Modules**
- For data taken in 2016 onward, it is no longer necessary to run the following modules: Remove Cross Talk, Glitch Identification. It is fine to keep them in the DRF XML, these modules will automatically not run on the new data.

**Current Important OSIRIS Issues**

- For certain cases, there are flux artifacts: [Issue 20](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/20), [wiki link](https://github.com/Keck-DataReductionPipelines/OsirisDRP/wiki/Tests:-Quantified-Flux-Mis-assignment)
- Spatial rippling is seen in the integrate flux of sky lines spatially across the field: [Issue 21](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/21)
- [2016-09-07 OSIRIS Hackathon report](https://drive.google.com/open?id=0B_YkzZoUSrX-YnpCRjVZRkRPWnM) on these and other issues from the most recent OSIRIS Hackathon

## Citing the Pipeline 

Please cite [Lyke et al. (2017)](https://ui.adsabs.harvard.edu/abs/2017ascl.soft10021L/abstract) and [Lockhart et al. (2019)](https://ui.adsabs.harvard.edu/abs/2019AJ....157...75L/abstract) if you use this pipeline in a publication. 

## Installation
### Prerequisites

To install and run the OSIRIS DRP, you will need the following:

- A working C compiler (e.g. ``gcc``)
- A copy of the compiled library cfitsio
- A working installation of IDL 7 or IDL 8 (the IDL binary directory should be in your ``PATH`` environment variable)
- Python dependencies (optional, for testing): pytest, astropy
- If using a computer with Apple M1 ARM chips, see [INSTALLPROBLEMS.md](https://github.com/Keck-DataReductionPipelines/OsirisDRP/blob/master/INSTALLPROBLEMS.md) for a workaround.
- ODRFGUI: Java version 17 (newer versions of Java are likely to run into issues when running the GUI)


### Installing from source

Either clone or download the source from github, choose either the master branch or the develop branch.
 - the [``master``](https://github.com/Keck-DataReductionPipelines/OsirisDRP) branch as the latest official release.
 - the [``develop``](https://github.com/Keck-DataReductionPipelines/OsirisDRP/tree/develop) branch has the latest development

Set up the following environment variables to compile the code (you can remove these variables after compiling). The defaults should work for installations of IDL on Mac OS X and CFITSIO installed using [MacPorts][]:

- ``IDL_INCLUDE``: The IDL include directory. If you don't set ``IDL_INCLUDE``, it defaults to ``IDL_INCLUDE=/Applications/exelis/idl/external/include``
- ``CFITSIOLIBDIR``: The directory containing your installation of CFITSIO. If you don't set ``CFITSIOLIBDIR``, it will default to ``CFITSIOLIBDIR=/opt/local/lib``, which is correct for [MacPorts][].

Run the makefile from the top level of the OSIRIS DRP source code:

```
make all
```

You should see that the pipeline has been built correctly. Be sure you are using ``gmake`` (which on OS X is the only ``make``, so using ``make`` works.)

[MacPorts]: https://www.macports.org

### Setup OSIRIS DRP Runtime Environment

The OSIRIS DRP requires various environment variables to find and run
the pipeline. Instructions are below for bash (should work for other
POSIX compliant shells) and c-shell. If you want to set up your
environment every time you start your shell (e.g. via ``.cshrc`` or
``.bashrc``), you can add the environment variable,
``OSIRIS_VERBOSE=0`` to silence the output of the setup
scripts. Otherwise, they will print useful messages about the setup of
your OSIRIS pipeline environment.

#### Environment Setup in Bash

You can add these lines to your ``.bashrc`` file or other startup profile if you want to set up the osiris environment variables for all of your shell sessions. Add these lines to your profile:

```
OSIRIS_VERBOSE=0
source /my/path/to/osiris/drp/scripts/osirisSetup.sh
osirisSetup /my/path/to/osiris/drp
```

Remember if your IDL binary is not in your path, you should also add it to your ``.bashrc`` file, for example:

```
export PATH=$PATH:/Applications/exelis/idl/bin
```

#### Environment Setup in CSH

You can add these lines to your ``.cshrc`` file or other startup profile if you want to set up the osiris environment variables for each of your shell sessions. Add these lines to your profile:

```
set OSIRIS_VERBOSE=0
setenv OSIRIS_ROOT=/my/path/to/osiris/drp/
source ${OSIRIS_ROOT}/scripts/osirisSetup.csh
setenv PATH ${PATH}:${OSIRIS_ROOT}/scripts
```

Remember if your IDL binary is not in your path, you should also add it to your ``.cshrc`` file, for example:

```
setenv PATH ${PATH}:/Applications/exelis/idl/bin
```

### Running the Pipeline

To run the pipeline, use ``run_odrp``. If you don't want the pipeline
to open a new xterm window, call ``run_odrp -n``.

Please check out the OSIRIS pipeline manual: OSIRIS_Manual_v5.pdf in this directory.


### OOPGUI &  ODRFGUI settings

To set the default directories for the guis, you can edit the following two files:

* ``odrfgui/odrfgui_cfg.xml``
* ``oopgui/oopgui_cfg.xml``

### Troubleshooting

If you run into problems, please re-read this [README.md](https://github.com/Keck-DataReductionPipelines/OsirisDRP), then read [INSTALLPROBLEMS.md](https://github.com/Keck-DataReductionPipelines/OsirisDRP/blob/master/INSTALLPROBLEMS.md) for some common installation problems. Please post an issue on the issue page if you have problems not addressed in the above documents or in the manual. 

OSIRIS DRP Project Contributors
============================

Project Coordinators
--------------------
* Jim Lyke (@jlyke-keck)
* Tuan Do (@followthesheep)

Alphabetical list of contributors
---------------------------------
* Anna Boehle (@aboehle)
* Randy Campbell
* Sam Chappell
* Devin Chu
* Mike Fitzgerald (@astrofitz)
* Tom Gasawy
* Christof Iserlohe
* Alfred Krabbe
* James Larkin
* Jim Lyke (@jlyke-keck)
* Kelly Lockhart
* Jessica Lu
* Etsuko Mieda
* Mike McElwain
* Marshall Perrin
* Alex Rudy (@alexrudy)
* Breann Sitarski
* Andrey Vayner
* Greg Walth
* Jason Weiss
* Tommer Wizanski
* Shelley Wright

(If you have contributed to the OSIRIS pipeline and your name is missing,
please send an email to the coordinators, or
If you have contributed to the OSIRIS pipeline and your name is missing,
please send an email to the coordinators, or
open a pull request for this [page](https://github.com/Keck-DataReductionPipelines/OsirisDRP/edit/master/AUTHORS.rst>)
in the [OsirisDRP repository](https://github.com/Keck-DataReductionPipelines/OsirisDRP>)
