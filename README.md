# OSIRIS Data Reduction Pipeline

## Prerequisites

To install and run the OSIRIS DRP, you will need the following:

- A working C compiler (e.g. ``gcc``)
- A copy of the compiled library cfitsio
- A working installation of IDL

## Compiling a Local version of the DRP

Set up the following environment variables:

- ``IDL_INCLUDE``, which should point to something like ``/Applications/exelis/idl/external/include``
- ``CFITSIOLIBDIR``, which should point to the directory containing your installation of CFITSIO. For macports, that would be ``/opt/local/lib``.

Then you can run the makefile from the top level of the OSIRIS DRP source code:

```
    make all
```

and you should see that the pipeline has been built correctly. Be sure you are using ``gmake`` (which on OS X is the only ``make``, so using ``make`` works.)

## OSIRIS Environment

To setup the OSIRIS environment, source the file ``scripts/osirisSetup.sh``, then run ``osirisSetup`` with the root directory of your OSIRIS DRF installation. If your OSIRIS pipeline is installed in ``/usr/local/osiris/drs/``, then you would do:

```
    source scripts/osirisSetup.sh
    osirisSetup /usr/local/osiris/drs/
```

You can change all of the relevant OSIRIS variables later by running ``osirisSetup`` again.

## Troubleshooting

If you run into problems, please re-read this README.md, then read INSTALLPROBLEMS.md for some common installation problems.

