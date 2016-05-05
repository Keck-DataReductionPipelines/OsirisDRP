# -*- coding: utf-8 -*-
"""
DRP Backbone based tests.
"""
import os
import glob
import subprocess
import shutil

__all__ = ['prepare_and_consume_queue_directory', 'prepare_queue_directory', 'consume_queue_directory']

def prepare_and_consume_queue_directory(queue_directory):
    """Prepare and consume an OSIRIS DRP queue directory."""
    prepare_queue_directory(queue_directory)
    consume_queue_directory(queue_directory)

def prepare_queue_directory(queue_directory):
    """Prepare the DRFs in a queue directory for testing"""
    for i, xml_filename in enumerate(glob.iglob(os.path.join(queue_directory, "*.xml"))):
        pipeline_file = os.path.splitext(os.path.basename(xml_filename))[0]
        if "." in pipeline_file:
            raise ValueError("XML DRF Filename contains '.' which is illegal. Filename: {0}".format(xml_filename))
        pipeline_filename = "{0:03d}.{1:s}.waiting".format(i+1, pipeline_file)
        pipeline_filepath = os.path.join(os.path.dirname(xml_filename), pipeline_filename)
        shutil.copy(xml_filename, pipeline_filepath)
    

def consume_queue_directory(queue_directory, test_directory=None, capture=False):
    """Run the DRP until it has consumed a single queue directory.
    
    The DRP is run by IDL in a subprocess using the python subprocess module.
    
    :param str queue_directory: The path to the queue directory with DRFs which should be consumed.
    :param str test_directory: Optionally, set the root directory for test code. By default, it will be set from the relevant OSIRIS environment variable, ``OSIRIS_ROOT``.
    :param bool capture: Should python capture the pipeline output. If set, output will be captured in python.
    
    """
    test_directory = test_directory or os.path.join(
        os.environ.get("OSIRIS_ROOT", "/usr/local/osiris/drs/"), "tests")
    
    if not queue_directory.endswith(os.path.sep):
        queue_directory += "/"
    if not os.path.isdir(queue_directory):
        raise IOError("The queue directory '{0}' does not exist".format(queue_directory))
    
    # Set up the subprocess to consume the queue directory.
    idl_startup_file = os.path.join(test_directory, "drpStartup.pro")
    args = ["idl", "-IDL_STARTUP", idl_startup_file, "-e", "drpTestSingle, '{0}'".format(queue_directory)]
    
    kwargs = {}
    if capture:
        kwargs['stdin'] = subprocess.PIPE
        kwargs['stdout'] = subprocess.PIPE
        kwargs['stderr'] = subprocess.PIPE
    
    # Run a subprocess IDL
    proc = subprocess.Popen(args, **kwargs)
    if capture:
        stdout, stderr = proc.communicate()
    else:
        proc.wait()
    
    return proc.returncode
    

