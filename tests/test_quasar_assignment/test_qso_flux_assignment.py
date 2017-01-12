# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones.fetchdata import get_test_file
from drptestbones.flux_assignment_compare_qso import compare_spxl

@pytest.fixture(scope='module')
def reference_file(request):
    """Download the reference file."""
    filename = 's160321_a002010_Hn3_100_ref.fits'
    #get_test_file(request.module.__name__, filename)
    return filename
    

def test_qso_flux_assignment(drf_queue, reference_file):
    """Test Quasar flux assignment"""
    consume_queue_directory(drf_queue)
    output_file = os.path.join(drf_queue, "s160321_a002010_Hn3_100.fits")
    expected_file = os.path.join(drf_queue, reference_file)
    #fits_osiris_allclose(output_file, expected_file)
    print compare_spxl(output_file)


