# -*- coding: utf-8 -*-
import urllib2
from astropy.table import Table
import inspect
import os
import numpy as np

def setup_test_data(test_directory):
    """
    This should be called in the fixture for each test. 
    """
    test_name = os.path.basename(os.path.normpath(test_directory))
    
    for i, xml_filename in enumerate(glob.iglob(os.path.join(test_directory, "*.xml"))):
        pipeline_file = os.path.splitext(os.path.basename(xml_filename))[0]
        if "." in pipeline_file:
            raise ValueError("XML DRF Filename contains '.' which is illegal. Filename: {0}".format(xml_filename))
        drf = OsirisDRF.parse(xml_filename)
        cal_files = drf.calibration_files()
        dat_files = drf.data_files()

        # Loop through the data files and download them if we need to.
        for dd in range(len(dat_files)):
            # Find the file name (and sub-directories) relative to the tests/<test_mytest> directory.
            sdx = dat_files[dd].rindex(test_name) + len(test_name) + 1
            file_to_fetch = dat_files[dd][sdx:]
            print 'Downloading ' + file_to_fetch
            
            fetchdata.get_test_file(test_name, file_to_fetch)

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
    response = urllib2.urlopen(file_url)

    _out = open(file_save_name, 'w')
    _out.write(response.read())
    _out.close()

    return
    
