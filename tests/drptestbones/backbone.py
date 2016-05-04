# -*- coding: utf-8 -*-
"""
DRP Backbone based tests.
"""
import os
import subprocess


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
    

