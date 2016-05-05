# -*- coding: utf-8 -*-
import urllib2
from astropy.table import Table
import inspect
import os
import glob
import numpy as np

from .drf import OsirisDRF

def setup_test_data(test_directory):
    """
    This should be called in the fixture for each test. 
    """
    test_name = os.path.basename(os.path.normpath(test_directory))
    
    for xml_filename in glob.iglob(os.path.join(test_directory, "*.xml")):
        drf = OsirisDRF.parse(xml_filename)
        cal_files = drf.calibration_files()
        dat_files = drf.data_files()

        # Process the cal files first.
        # If it is a rec matrix, then download.
        # If it not a rec matrix, then just add it to the dat_files.
        for cc in range(len(cal_files)):
            # Figure out if this calib file is a rec matrix (should be in tests/calib)
            # or a normal dark, etc.
            try:
                calib_dir = 'tests/calib'
                cdx = cal_files[cc].index(calib_dir) + len(calib_dir) + 1
                file_to_fetch = cal_files[cc][cdx:]

                get_calib_file(file_to_fetch)
            except ValueError:
                # If we didn't find tests/calib in the filename, then this is just
                # a regular file to be downloaded like the rest. Just add it to
                # dat files for further processing.
                dat_files.append(cal_files[cc])
            
        # Loop through the data files and download them if we need to.
        for dd in range(len(dat_files)):
            # Find the file name (and sub-directories) relative to the tests/<test_mytest> directory.
            sdx = dat_files[dd].rindex(test_name) + len(test_name) + 1
            file_to_fetch = dat_files[dd][sdx:]
            
            get_test_file(test_name, file_to_fetch)

    return


def get_test_file(test_name, file_name, refresh=False):
    """
    Fetch a file for the specified test from a URL.
    The mapping between test name, file name, and URL is in the file
    map_file_urls.txt.
    """
    # Get directories.
    dir_testbones = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    dir_tests = os.path.dirname(dir_testbones)
    dir_this_test = dir_tests + '/' + test_name + '/'

    # Get the file name where we will deposit the file.
    file_save_name = dir_this_test + file_name

    if os.path.exists(file_save_name) and not refresh:
        return
    
    # Read the map
    map_file = dir_testbones + '/map_file_urls.txt'
    data_map = Table.read(map_file, format='ascii.commented_header')

    # Search for the requested filename
    idx = np.where((data_map['test_name'] == test_name) & (data_map['file_name'] == file_name))[0]

    if len(idx) > 1:
        print 'Found duplicate entries in map_file: {0:s}. '.format(map_file)
        print 'Using the first one. Duplicates are:'
        print data_map[idx]

    if len(idx) == 0:
        raise KeyError(file_name)

    file_url = data_map['file_url'][idx[0]]

    # Fetch the file from the specified URL
    print 'Downloading ' + file_name
    response = urllib2.urlopen(file_url)

    _out = open(file_save_name, 'w')
    _out.write(response.read())
    _out.close()

    return


def get_calib_file(file_name, refresh=False):
    """
    Fetch a file for the specified test from a URL.
    The mapping between test name, file name, and URL is in the file
    map_file_urls.txt.
    """
    # Get directories.
    dir_testbones = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    dir_tests = os.path.dirname(dir_testbones)
    dir_calib = dir_tests + '/calib/'

    # Get the file name where we will deposit the file.
    file_save_name = dir_calib + file_name

    if os.path.exists(file_save_name) and not refresh:
        return
    
    # Read the map
    map_file = dir_testbones + '/map_file_urls.txt'
    data_map = Table.read(map_file, format='ascii.commented_header')

    # Search for the requested filename
    idx = np.where((data_map['test_name'] == 'calib') & (data_map['file_name'] == file_name))[0]

    if len(idx) > 1:
        print 'Found duplicate entries in map_file: {0:s}. '.format(map_file)
        print 'Using the first one. Duplicates are:'
        print data_map[idx]

    if len(idx) == 0:
        raise KeyError(file_name)

    file_url = data_map['file_url'][idx[0]]

    # Fetch the file from the specified URL
    print 'Downloading ' + file_name
    response = urllib2.urlopen(file_url)

    _out = open(file_save_name, 'w')
    _out.write(response.read())
    _out.close()

    return
    
