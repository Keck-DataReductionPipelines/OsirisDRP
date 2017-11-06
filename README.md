# Keck OSIRIS Data Reduction Pipeline

* [Release Notes for v4.0.0](#release-notes-for-v4.0.0)
* [Important Runtime Notes](#important-runtime-notes)
* [Installation](#installation)
* [Running the Pipeline](#running-the-pipeline)
* [Testing the Pipeline](#testing-the-pipeline)

## Release Notes for v4.1.0beta
**2017-08-10**
Major Updates
- Includes a new wavelength solution for data after May 2017. A shift in the wavelenth solution in May 2017 required a re-derivation of the solution. The new solution has an average offset between the observed and vacuum wavelength of OH lines of 0.07 +- 0.06 Angstroms in Kn3 35 mas.
- A preliminary bad pixel mask is available for data taken after 2016 (new spectrograph detector). This mask meant to be used as extension 2 in the raw fits files. Currently, the mask is not automatically applied by Keck. To apply it, use the following command in the raw spectra directory once the pipeline is installed (by default, it will use the new mask `badpixelmask2017.fits.gz`):
```
apply_mask.py *.fits
```

- A new keyword is available in the Scaled Sky Subtraction module called 'scale_fitted_lines_only'. To turn on the new behavior, the keyword should be set to YES (default is NO). This keyword will only scale only OH lines, not the rest of the spectrum as well. This setting greatly improves sky subtraction for the case where the science target fills the lenslets and there are no true sky locations.

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

### Options to install the pipeline

- [Using a python script](#installing-with-a-python-script) -- this is the simplest method for the most recent release
- [Manually install from github repository](#installing-from-source) -- useful if you want to use the latest pipeline development version

### Installing with a python script

- Download the installation script [install_osiris_drs.py](https://github.com/Keck-DataReductionPipelines/OsirisDRP/blob/release/scripts/install_osiris_drs.py)
- Run the script
```
chmod +x install_osiris_drs.py
./install_osiris_drs.py
```
- For more information and script options:
```
./install_osiris_drs.py --help
```

### Installing from source

Either clone or download the source from github (the [``develop``](https://github.com/Keck-DataReductionPipelines/OsirisDRP/tree/develop) branch has the latest development)

Set up the following environment variables (optional). The defaults should work for installations of IDL on Mac OS X and CFITSIO installed using [MacPorts][]:

- ``IDL_INCLUDE``: The IDL include directory. If you don't set ``IDL_INCLUDE``, it defaults to ``IDL_INCLUDE=/Applications/exelis/idl/external/include``
- ``CFITSIOLIBDIR``: The directory containing your installation of CFITSIO. If you don't set ``CFITSIOLIBDIR``, it will default to ``CFITSIOLIBDIR=/opt/local/lib``, which is correct for [MacPorts][].

Run the makefile from the top level of the OSIRIS DRP source code:

```
make all
```

You should see that the pipeline has been built correctly. Be sure you are using ``gmake`` (which on OS X is the only ``make``, so using ``make`` works.)

[MacPorts]: https://www.macports.org

### OSIRIS DRP Runtime Environment

The OSIRIS DRP requires various environment variables to find and run
the pipeline. Instructions are below for bash (should work for other
POSIX compliant shells) and c-shell. If you want to set up your
environment every time you start your shell (e.g. via ``.cshrc`` or
``.bashrc``), you can add the environment variable,
``OSIRIS_VERBOSE=0`` to silence the output of the setup
scripts. Otherwise, they will print useful messages about the setup of
your OSIRIS pipeline environment.

#### Environment Setup in Bash

To setup the OSIRIS environment, source the file
``scripts/osirisSetup.sh``, then run ``osirisSetup`` with the root
directory of your OSIRIS DRF installation. If your OSIRIS pipeline is
installed in ``/usr/local/osiris/drs/``, then you would do:

```
$ source scripts/osirisSetup.sh
To use the OSIRIS DRP, run osirisSetup /path/to/my/drp

$ osirisSetup /my/path/to/osiris/drp/
Setting OSIRIS_ROOT=/my/path/to/osiris/drp/
Adding /my/path/to/osiris/drp/scripts to your path.
Successfully setup OSIRIS DRP environment.
The DRP is in /my/path/to/osiris/drp/
```

You can change all of the relevant OSIRIS variables later by running
``osirisSetup`` again. ``osirisSetup`` will add
``$OSIRIS_ROOT/scripts`` to your environment's PATH variable by
default. To skip this step, run ``osirisSetup`` with ``-n``:

```
$ osirisSetup -n /my/path/to/osiris/drp/
Setting OSIRIS_ROOT=/my/path/to/osiris/drp/
Successfully setup OSIRIS DRP environment.
The DRP is in /my/path/to/osiris/drp/
```

You can add these lines to your ``.bashrc`` file or other startup profile if you want to set up the osiris environment variables for all of your shell sessions. Add lines like this to your profile:

```
OSIRIS_VERBOSE=0
source /my/path/to/osiris/drp/scripts/osirisSetup.sh
osirisSetup /my/path/to/osiris/drp
```


#### Environment Setup in CSH

To setup the OSIRIS environment, set the environment variable
``OSIRIS_ROOT`` to the root directory for the OSIRIS data reduction
pipeline. Then source the file ``scripts/osirisSetup.csh``.

```
$ setenv OSIRIS_ROOT /my/path/to/osiris/drp/

$ source scripts/osirisSetup.csh
Using OSIRIS_ROOT=/my/path/to/osiris/drp/
Successfully setup OSIRIS DRP environment.
The DRP is in /my/path/to/osiris/drp/
You might want to add /my/path/to/osiris/drp/scripts to your PATH.
```

You can add these lines to your ``.cshrc`` file or other startup profile if you want to set up the osiris environment variables for each of your shell sessions. Add lines like this to your profile:

```
set OSIRIS_VERBOSE=0
setenv OSIRIS_ROOT=/my/path/to/osiris/drp/
source ${OSIRIS_ROOT}/scripts/osirisSetup.csh
setenv PATH ${PATH}:${OSIRIS_ROOT}/scripts
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

If you run into problems, please re-read this README.md, then read INSTALLPROBLEMS.md for some common installation problems.
