# OSIRIS Full-DRP Tests

This directory implements full-DRP testing for the OSIRIS pipeline.

## Defining Tests

New tests are defined by a directory containing a DRF and an ``expected/`` folder. The directory strucutre should look like:

- ``tests/``
    - ``test_mynewtest/``
        - ``001.something.waiting`` DRF file to run through the pipeline. The DRF should leave outputs in this directory.
        - ``expected/``
            - ``myfitsfile.fits`` expceted output to be compared to pipeline output. The filename should match.

Note that any rectification matrices that are needed to run the test
should be downloaded into the $OSIRIS_ROOT/calib in advance of running
the test. 

## Running Tests

To run tests, use ``run_tests.sh``

The script will automatically discover all of the available test DRFs by looking for directories which start with ``test`` and have a DRF inside with the extension ``.waiting``.

The test script will first run all of the found DRFs through the pipeline, then it will use ``fitsdiff`` (from pyfits or astropy) to compare the output FITS files to the _expected_ versions, inside of an ``expected/`` folder.
