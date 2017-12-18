# Keck OSIRIS Data Reduction Pipeline

* [Release Notes for v4.0.0](#release-notes-for-v4.0.0)
* [Important Runtime Notes](#important-runtime-notes)
* [Installation](#installation)
* [Running the Pipeline](#running-the-pipeline)
* [Testing the Pipeline](#testing-the-pipeline)

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

## Important Runtime Notes

**Cosmic Ray Module**
- We do not recommend running the cosmic ray module on data in 2016 or later, as it will introduce significant artifacts and reduce overall signal to noise. This is due to the fact that unresolved emission lines such as OH lines are now sharper on the detector. The cosmic ray module will tend to interpret this as a cosmic ray. To remove cosmic rays, we recommend combining data with the mosaic module with the MEANCLIP keyword if there are sufficient number of frames.
- The cosmic ray module may lead to artifacts in data before 2016 as well, but at a lesser level. We recommend checking on individual science cases.
- The pipeline team is investigating different cosmic ray modules for
a future release.
- More information is available in [Issue 49](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/49) or in the [wiki](https://github.com/Keck-DataReductionPipelines/OsirisDRP/wiki/Tests:-cosmic-ray-module).

**Old Modules**
- For data taken in 2016 onward, it is no longer necessary to run the following modules: Remove Cross Talk, Glitch Identification. It is fine to keep them in the DRF XML, these modules will automatically not run on the new data.

**Current Important OSIRIS Issues**

- For certain cases, there are flux artifacts: [Issue 20](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/20), [wiki link](https://github.com/Keck-DataReductionPipelines/OsirisDRP/wiki/Tests:-Quantified-Flux-Mis-assignment)
- Spatial rippling is seen in the integrate flux of sky lines spatially across the field: [Issue 21](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues/21)
- [2016-09-07 OSIRIS Hackathon report](https://drive.google.com/open?id=0B_YkzZoUSrX-YnpCRjVZRkRPWnM) on these and other issues from the most recent OSIRIS Hackathon

## Installation
### Prerequisites

To install and run the OSIRIS DRP, you will need the following:

- A working C compiler (e.g. ``gcc``)
- A copy of the compiled library cfitsio
- A working installation of IDL 7 or IDL 8 (the IDL binary directory should be in your ``PATH`` environment variable)
- Python dependencies (optional, for testing): pytest, astropy


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

Please check out the OSIRIS pipeline manual: <http://www2.keck.hawaii.edu/inst/osiris/OSIRIS_Manual_v2.3.pdf>

### Testing the Pipeline

To run the suite of tests on the pipeline, and you have ``pytest`` and ``astropy`` in your python environment:

```
make test
```

The first time you run the tests, data will be downloaded so it will take longer. If the tests pass, your pipeline is installed properly. You will see something like the following if the tests pass:

```
======================== 2 passed, 2 skipped in 41.77 seconds ===================
```


### Troubleshooting

If you run into problems, please re-read this [README.md](https://github.com/Keck-DataReductionPipelines/OsirisDRP), then read [INSTALLPROBLEMS.md](https://github.com/Keck-DataReductionPipelines/OsirisDRP/blob/master/INSTALLPROBLEMS.md) for some common installation problems.

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
