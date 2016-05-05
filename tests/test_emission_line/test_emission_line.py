# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import prepare_and_consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones.drf import OsirisDRF
from drptestbones import fetchdata

@pytest.fixture()
def download_files(scope='module'):
    queue_directory = os.path.dirname(__file__)
    test_name = os.path.basename(os.path.normpath(queue_directory))
    
    for i, xml_filename in enumerate(glob.iglob(os.path.join(queue_directory, "*.xml"))):
        pipeline_file = os.path.splitext(os.path.basename(xml_filename))[0]
        if "." in pipeline_file:
            raise ValueError("XML DRF Filename contains '.' which is illegal. Filename: {0}".format(xml_filename))
        drf = OsirisDRF.parse(xml_filename)
        cal_files = drf.calibration_files()
        dat_files = drf.data_files()

        # Loop through the data files and download them if we need to.
        for dd in range(len(dat_files)):
            # Find the file name (and sub-directories) relative to the tests/<test_mytest> directory.
            sdx = dat_files[dd].rindex(test_name) + len(test_name)
            file_to_fetch = dat_files[dd][sdx:]
            print file_to_fetch
            
            fetchdata.get_test_file(queue_directory, file_to_fetch)

download_files()

def test_emission_line(download_files):
    """Test FITS emission lines"""
    
    queue_directory = os.path.dirname(__file__)
    prepare_and_consume_queue_directory(queue_directory)
    
    output_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035.fits")
    expected_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035_ref.fits")
    fits_osiris_allclose(output_file, expected_file)
