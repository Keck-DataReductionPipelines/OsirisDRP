# -*- coding: utf-8 -*-

import pytest
import os

from drptestbones.backbone import prepare_and_consume_queue_directory
from drptestbones.diff import fits_osiris_allclose

def test_emission_line():
    """Test FITS emission lines"""
    
    queue_directory = os.path.dirname(__file__)
    prepare_and_consume_queue_directory(queue_directory)
    
    output_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035.fits")
    expected_file = os.path.join(queue_directory, "s150531_a025002_Kn5_035_ref.fits")

    # testing that the new cube is similar to the reference
    fits_osiris_allclose(output_file, expected_file)
    
