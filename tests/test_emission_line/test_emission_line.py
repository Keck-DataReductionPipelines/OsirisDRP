# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones.fetchdata import get_test_file

def test_emission_line(drf_queue):
    """Test FITS emission lines"""
    # Download the reference file to compare to.
    get_test_file('test_emission_line', 's150531_a025002_Kn5_035_ref.fits')
    
    consume_queue_directory(drf_queue)
    output_file = os.path.join(drf_queue, "s150531_a025002_Kn5_035.fits")
    expected_file = os.path.join(drf_queue, "s150531_a025002_Kn5_035_ref.fits")
    fits_osiris_allclose(output_file, expected_file)
