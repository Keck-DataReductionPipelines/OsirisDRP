# OSIRIS Data Reduction Pipeline

## Prerequisites

To install and run the OSIRIS DRP, you will need the following:

- A working C compiler (e.g. ``gcc``)
- A copy of the compiled library cfitsio
- A working installation of IDL

## Compiling a Local version of the DRP

Set up the following environment variables if the defaults won't work for your installation. The defaults should work for installations of IDL on Mac OS X and CFITSIO installed using [MacPorts][]:

- ``IDL_INCLUDE``: The IDL include directory. If you don't set ``IDL_INCLUDE``, it defaults to ``IDL_INCLUDE=/Applications/exelis/idl/external/include``
- ``CFITSIOLIBDIR``: The directory containing your installation of CFITSIO. If you don't set ``CFITSIOLIBDIR``, it will default to ``CFITSIOLIBDIR=/opt/local/lib``, which is correct for [MacPorts][].

Then you can run the makefile from the top level of the OSIRIS DRP source code:

```
make all
```

and you should see that the pipeline has been built correctly. Be sure you are using ``gmake`` (which on OS X is the only ``make``, so using ``make`` works.)

[MacPorts]: https://www.macports.org

## OSIRIS Environment

The OSIRIS DRP requires that you set various environment variables to that it knows how to find and run the pipeline. Instructions are below for bash (should work for other POSIX compliant shells) and CSH.

### Environment Setup in Bash

To setup the OSIRIS environment, source the file ``scripts/osirisSetup.sh``, then run ``osirisSetup`` with the root directory of your OSIRIS DRF installation. If your OSIRIS pipeline is installed in ``/usr/local/osiris/drs/``, then you would do:

```
$ source scripts/osirisSetup.sh
To use the OSIRIS DRP, run osirisSetup /path/to/my/drp
$ osirisSetup /my/path/to/osiris/drp/
Setting OSIRIS_ROOT=/my/path/to/osiris/drp/
Adding /my/path/to/osiris/drp/scripts to your path.
Successfully setup OSIRIS DRP environment.
The DRP is in /my/path/to/osiris/drp/
```

You can change all of the relevant OSIRIS variables later by running ``osirisSetup`` again. ``osirisSetup`` will by default add ``$OSIRIS_ROOT/scripts`` to your environment's PATH variable. To skip this step, run ``osirisSetup`` with ``-n``:

```
$ osirisSetup -n /my/path/to/osiris/drp/
```

### Environment Setup in CSH

To setup the OSIRIS environment, set the environment variable ``OSIRIS_ROOT`` to the root directory for the OSIRIS data reduction pipeline. Then source the file ``scripts/osirisSetup.csh``.

```
$ setenv OSIRIS_ROOT /my/path/to/osiris/drp/
$ source scripts/osirisSetup.csh
Using OSIRIS_ROOT=/my/path/to/osiris/drp/
Successfully setup OSIRIS DRP environment.
The DRP is in /my/path/to/osiris/drp/
You might want to add /my/path/to/osiris/drp/scripts to your PATH.
```

## Running the Pipeline

Please check out the OSIRIS pipeline manual: <http://www2.keck.hawaii.edu/inst/osiris/OSIRIS_Manual_v2.3.pdf>

## Troubleshooting

If you run into problems, please re-read this README.md, then read INSTALLPROBLEMS.md for some common installation problems.

