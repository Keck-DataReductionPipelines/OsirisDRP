# OSIRIS Full-DRP Tests

This directory implements full-DRP testing for the OSIRIS pipeline.

## Defining Tests

New tests are defined by a directory containing a DRF and a python
test script compatable with the pytest framework. See
``test_emission_line`` for an example. The directory strucutre should look like:

- ``tests/``
    - ``test_mynewtest/``
        - ``mynewtest_drf.xml`` DRF file to run through the pipeline. 
        - ``myfitsfile.fits`` input data file for DRF processing
        - ``myfitsfile_dark.fits`` input dark file for DRF processing
        - ``myfitsfile_ref.fits`` expceted output to be compared to
          pipeline output. The filename should match except for the
          ``_ref.fits`` at the end.

Note that FITS files should NOT be checked into the git repository. Please place
any FITS files needed for the test into the
[data repository](https://www.dropbox.com/sh/potoqeiii149hii/AABD5oT8LRAhJeh-B4VXA5Kia?dl=0)
on DropBox. Your data files should be uploaded to
``tests/test_mynewtest/`` in the data repository. Any standard
rectification matrices should be uploaded to ``tests/calib/``.
Then modify tests/drptestbackbone/map_file_urls.txt to add an entry:

``<test_name> <file_name> <file_url>``

for each data file you need and

``calib <file_name> <file_url>``

for each rectification matrix. Then They will be
automatically downloaded when they are needed.


## Running Tests

To run tests, use ``py.test`` or ``make test``

