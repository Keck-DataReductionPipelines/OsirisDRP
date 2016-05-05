# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import prepare_and_consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones import fetchdata

@pytest.fixture()
def download_files():
    test_directory = os.path.dirname(__file__)
    
    fetchdata.setup_test_data(test_directory)

    return
    
def test_emission_line(download_files):
    """Test FITS emission lines"""
    
    queue_directory = os.path.dirname(__file__)
    prepare_and_consume_queue_directory(queue_directory)
    
    output_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035.fits")
    expected_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035_ref.fits")
    fits_osiris_allclose(output_file, expected_file)

    return
