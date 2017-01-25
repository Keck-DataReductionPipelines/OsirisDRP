# -*- coding: utf-8 -*-

import inspect
import os

import pytest

from .fetchdata import setup_test_data
from .backbone import prepare_queue_directory

__all__ = ['drf_queue']

@pytest.fixture(scope="module")
def drf_queue(request):
    """Fixture for preparing the queue."""
    queue_directory = os.path.dirname(str(request.fspath))
    setup_test_data(queue_directory)
    prepare_queue_directory(queue_directory)
    return queue_directory
