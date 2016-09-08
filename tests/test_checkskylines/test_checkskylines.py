# -*- coding: utf-8 -*-

import pytest
import os
import glob

from drptestbones.backbone import consume_queue_directory
from drptestbones.diff import fits_osiris_allclose
from drptestbones.fetchdata import get_test_file

from drptestbones.checkSkylines import checkSkylines


def test_skyline(drf_queue):
    """Test FITS sky lines"""
    consume_queue_directory(drf_queue)
    output_file = os.path.join(drf_queue, "s160711_a013002_Kbb_035.fits")
    expected_file = os.path.join(drf_queue, "s160711_a013002_Kbb_035_ref.fits")
    rms_fits = os.path.join(drf_queue,'s160711_a013002_Kbb_035_RMS.fits')

    totalRMS,lineRMS = checkSkylines(output_file,2071,2075,41,rms_fits)
    fractRMS = lineRMS/totalRMS

    fits_osiris_allclose(output_file, expected_file)
    assert ((fractRMS > 0.97) & (fractRMS <= 1.0))

