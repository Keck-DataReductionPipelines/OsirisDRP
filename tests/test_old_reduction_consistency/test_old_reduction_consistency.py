# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones.fetchdata import get_test_file

@pytest.fixture(scope='module')
def reference_file(request):
    """Download the reference file."""
    filename = 's150504_a028001_Kn3_035_ref.fits'
    get_test_file(request.module.__name__, filename)
    return filename
    
@pytest.mark.skip(reason="This test does not work yet")
def test_old_reduction_consistency(drf_queue, reference_file):
    """Test FITS emission lines"""
    consume_queue_directory(drf_queue)
    output_file = os.path.join(drf_queue, "s150531_a025002_Kn5_035.fits")
    expected_file = os.path.join(drf_queue, reference_file)
    fits_osiris_allclose(output_file, expected_file)

