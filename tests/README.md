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

## Writing New Tests

To write a new test, follow these instructions.

1. Make a new directory with a unique test name. For this example, we
will call it "mytest".
```sh
mkdir test_mytest
```

2. Copy ``test_emission_line.py`` as a template.
```sh
cp test_emission_line/test_emission_line.py test_mytest/test_mytest.py
```

3. Make an XML file to process raw data into the cube you will use for
testing. See ``test_emission_line/emission_line.xml`` as an
example. Note, you should try to name the .xml file to match the test
case name.

4. Check in all of your files into git.
```sh
git add test_mytest
git commit -m "Adding a new test: mytest"
```

5. Temporarily place all .fits files that are needed by the .xml file into the test
   directory. Any rectification matrices should be deposited into
   ``tests/calib/``. You should also create a reference cube that is
   the "write answer" that will be tested against.

   These ``*.fits`` files are large and should not be checked into the
   git repository. Instead, these files should be loaded onto a data
   server at Keck. See later steps for further instructions.

6. Modify ``test_mytest/test_mytest.py`` to (a) download the reference
   cube, (b) consume the queue to download all other files and process
   the XML file through the pipeline, (c) and make ``assert``
   comparisons (e.g ``compare_cube_allclose()``).

7. From the main OsirisDRP directory, run ``make test`` or use
   ``py.test tests/test_mytest``. The test should pass. 


## Uploading your test data files to Keck:

You will need to upload your data files to Keck so that other
people can download them and run the tests.

1. Tar and zip up all of your data files.

```sh
cd OsirisDRP/tests/
tar cvf test_mytest_data.tar test_mytest/*.fits
tar avf test_mytest_data.tar calib/your_new_rec_mat.fits
gzip test_mytest_data.tar
```

2. Drop your data into the Keck FTP site:

```sh
ftp ftp.keck.hawaii.edu

# USER: anonymous
# PASSWORD: your email address


cd incoming/OsirisDRP/tests/
bin
hash
put test_mytest_data.tar.gz

exit
```

3. Email the Keck OSIRIS master <osiris_info@keck.hawaii.edu> and let
   them know you have new test data to be uploaded. Include the name
   of your zip file.







