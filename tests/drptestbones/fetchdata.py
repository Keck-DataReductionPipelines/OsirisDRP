import urllib2
from astropy.table import Table
import inspect
import os
import numpy as np

def get_test_file(test_name, file_name):
    """
    Fetch a file for the specified test from a URL.
    The mapping between test name, file name, and URL is in the file
    map_file_urls.txt.
    """
    # Get directories.
    dir_testbones = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    dir_tests = os.path.dirname(dir_testbones)
    dir_this_test = dir_tests + '/' + test_name + '/'
    
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

    # Get the file name where we will deposit the file.
    file_save_name = dir_this_test + file_name

    # Fetch the file from the specified URL
    response = urllib2.urlopen(file_url)

    _out = open(file_save_name, 'w')
    _out.write(response.read())
    _out.close()

    return
    
