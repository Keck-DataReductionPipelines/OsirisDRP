#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
This is a script to install the OSIRIS DRS Pipeline from v4.0 onwards.

It is heavily based on ``install_osiris_drs_v3.2.py``, the original OSIRIS
pipeline installer.


Author: Alexander Rudy (arrudy@ucsc.edu)
Date: May 6, 2016

"""

import sys, os
import glob
import stat
import logging
import argparse
import subprocess
import zipfile
import shutil

if sys.version_info[0] < 3:
    from urllib2 import urlopen
    input = raw_input
else:
    from urllib.request import urlopen

log = logging.getLogger("install_osiris_drs")
log.setLevel(logging.DEBUG)

# These constants are for the OSIRIS pipeline, which is on GitHub.
OSIRIS_DRS_URL = "https://github.com/Keck-DataReductionPipelines/OsirisDRP/archive/"
OSIRIS_DRS_VERSION = "4.0"
OSIRIS_DRS_FILES = ["develop.zip"]

# URLs and version numbers for software hosted at Keck.
OSIRIS_TOOLS_URL = "http://www2.keck.hawaii.edu/inst/osiris/tools/current/"
OSIRIS_ODRFGUI_VERSION = '2.3'
OSIRIS_OOPGUI_VERSION = '1.5'
OSIRIS_QUICKLOOK_VERSION = '2.2'
OSIRIS_QL_MANUAL_VERSION = '2.2'
OSIRIS_MANUAL_VERSION = '2.3'

OSIRIS_TOOLS_FILES = {
    "odrfgui_v%s.tar.gz" % OSIRIS_ODRFGUI_VERSION: "odrfgui", 
    "oopgui_v%s.tar.gz" % OSIRIS_OOPGUI_VERSION: "oopgui",
    "qlook2_v%s.tar.gz" % OSIRIS_QUICKLOOK_VERSION: "",
    "OSIRIS_Manual_v%s.pdf" % OSIRIS_MANUAL_VERSION: "",
    "qlook2_manual_v%s.pdf" % OSIRIS_QL_MANUAL_VERSION: "",
}

OSIRIS_DEFAULT_SOFTWARE_ROOT = os.path.join("/","usr","local", "osiris")

OSIRIS_LINKED_COMMANDS = {
    'oopgui' : os.path.join('oopgui','oopgui.bat'),
    'odrfgui' : os.path.join('odrfgui', 'odrfgui.bat'),
    'run_ql2' : os.path.join('ql2', 'run_ql2'),
    'run_sql2': os.path.join('ql2', 'run_sql2'),
    'run_oql2': os.path.join('ql2', 'run_oql2'),
}

def url_progress(request, destination, output=sys.stdout):
    """URL progress bar."""
    try:
        total_size = int(request.info().getheaders("Content-Length")[0])
    except:
        output.write("Can't determine file size. Downloading...\n")
        output.flush()
        with open(destination, 'w') as f:
            f.write(request.read())
    else:
        block_size = 2**12
        progress = 0
        with open(destination, 'w') as f:
            while True:
                buff = request.read(block_size)
                if not buff: break
                progress += len(buff)
                f.write(buff)
                _update_progress_bar(output, progress, total_size)
        _update_progress_bar(output, progress, total_size)
        output.write("\n")
        log.info("Downloaded %s", destination)
        
def _update_progress_bar(output, progress, total):
    """Update a progress bar."""
    status = r"%10d  [%3.2f%%]" % (progress, progress * 100. / total)
    status = status + chr(8)*(len(status)+1)
    output.write(status)
    output.flush()

def download_file(url, destination):
    """Download a file."""
    request = urlopen(url)
    url_progress(request, destination, output=sys.stdout)
    
def ask_for_value(prompt, default=None, validate=str, err_message=None):
    """Ask for a value"""
    result = None
    
    if default is None:
        prompt = "%s: " % prompt
    else:
        prompt = "%s [%s]: " % (prompt, default)
    
    while result is None:
        value = input(prompt)
        if value == "":
            result = default
        else:
            try:
                result = validate(value)
            except Exception as e:
                if err_message:
                    print(err_message)
                else:
                    print(str(e))
        
    return result
    
def validate_yes_no(value):
    """docstring for validate_yes_no"""
    value = value.lower()
    if value in ('y', 'ye', 'yes'):
        return True
    elif value in ('n', 'no'):
        return False
    raise ValueError("Can't understand input %s" % value)
    
def ask_yes_no(prompt, default=None, err_message=None):
    """Ask a yes or no question."""
    return ask_for_value(prompt, default, validate=validate_yes_no, err_message=err_message)
    
def validate_existing_path(value):
    """Validate a path which must exist."""
    path = os.path.normpath(os.path.expanduser(value))
    if not path.endswith(os.sep):
        path += os.sep
    if os.path.exists(path) and os.path.isdir(path):
        return path
    else:
        raise ValueError("Path doesn't exist.")
    
def ask_for_existing_path(prompt, default=None, err_message=None):
    """Ask the user for a path, which should already exist."""
    return ask_for_value(prompt, default, validate=validate_existing_path, err_message=err_message)
    
def validate_path(value):
    """Validate a path."""
    path = os.path.normpath(os.path.expanduser(value))
    if not path.endswith(os.sep):
        path += os.sep
    if os.path.exists(path):
        return path
    os.makedirs(path)
    if os.path.exists(path) and os.path.isdir(path):
        return path
    else:
        raise ValueError("Path doesn't exist.")
        
    

def ask_for_path(prompt, default=None, err_message=None):
    """Ask the user for a path, which might already exist."""
    return ask_for_value(prompt, default, validate=validate_path, err_message=err_message)


def download_tools_files(destination_directory):
    """Download all the tools files."""
    for filename in OSIRIS_TOOLS_FILES:
        if not os.path.exists(filename):
            log.info("Downloading %s", filename)
            download_file(OSIRIS_TOOLS_URL + filename, filename)
        else:
            log.debug("Not downloading %s, it seems to be here already.", filename)
    
def download_drp_files(destination_directory):
    """Download the DRP"""
    for filename in OSIRIS_DRS_FILES:
        if not os.path.exists(filename):
            log.info("Downloading %s", filename)
            download_file(OSIRIS_DRS_URL + filename, filename)
        else:
            log.debug("Not downloading %s, it seems to be here already.", filename)
        
    
def setup_logging(logfile="install_osiris_drs.log", stream_level=logging.INFO):
    """Set up the DRS log"""
    sh = logging.StreamHandler()
    sh.setFormatter(logging.Formatter("--> %(message)s"))
    sh.setLevel(stream_level)
    log.addHandler(sh)
    
    if os.path.exists(logfile):
        for i in range(9):
            if not os.path.exists(logfile + ".{:d}".format(i+1)):
                break
        os.rename(logfile, logfile + ".{:d}".format(i+1))
    fh = logging.FileHandler(logfile, mode='w')
    fh.setLevel(logging.DEBUG)
    log.addHandler(fh)
    
def validate_idl_include(value):
    """Validate that a given directory contains 'idl_export.h'"""
    path = validate_existing_path(value)
    if os.path.isfile(os.path.join(path, "idl_export.h")):
        return path
    raise ValueError("Couldn't find 'idl_export.h'")
    
def get_idl_include_path():
    """Get IDL settings"""
    path = os.path.realpath(subprocess.check_output(["which", "idl"]).rstrip())
    if os.path.exists(path):
        log.debug("Located IDL at '%s'", path)
        parts = path.split(os.path.sep)
        include_path = os.path.join("/",os.path.join(*parts[:-2]), "external", "include")
        if os.path.exists(include_path):
            log.debug("Found 'external/include' at %s", path)
            print("Enter your IDL include directory.")
            print("The default was determined from the \nlocation of the 'idl' command line binary.")
            include_path = ask_for_value("IDL include directory", default=include_path, validate=validate_idl_include)
            log.info("IDL include set to '%s'", include_path)
            return include_path
        else:
            log.debug("Didn't find 'external/include' at '%s'", include_path)
            
    
    print("Can't find your installation of IDL.")
    print("Please specify your IDL include directory")
    print("It is usually something like '/Applications/exelis/idl/external/include'")
    include_path = ask_for_value("IDL include directory", default=include_path, validate=validate_idl_include)
    log.info("IDL include set to '%s'", include_path)
    return include_path

def validate_cftisio_path(value):
    """Validate a path as being a valid CFITSIO path."""
    path = validate_existing_path(value)
    if len(glob.glob(os.path.join(path, "libcfitsio*"))) > 1:
        return path
    raise ValueError("Couldn't locate 'libcfitsio' in '%s'", path)
    
def get_cfitsio_path():
    """Get the path to CFITSIO"""
    print("Set the location of the CFITSIO library.")
    print("On many systems, this will be something like /usr/local/lib")
    cfitsio_path = ask_for_value("CFITSIO Library Location", validate=validate_cftisio_path)
    log.info("CFITSIO found at '%s'", cfitsio_path)
    return cfitsio_path
    
def get_pipeline_directory():
    """Get the pipeline install location."""
    print("Into which directory should the DRS be installed?")
    print("Press enter for the default.")
    drs_directory = ask_for_path("DRS Directory", default=os.path.join(OSIRIS_DEFAULT_SOFTWARE_ROOT, "drs"))
    log.info("Installing the DRS to '%s'", drs_directory)
    return drs_directory
    
def get_data_directory(install_directory):
    """Get the pipeline install location."""
    print("Where do you keep your OSIRIS data?")
    print("This is only used as the default directory for GUIs.")
    directory = ask_for_path("Data Directory", default=os.path.join("~", "osiris"))
    log.info("Setting data directory to '%s'", directory)
    return directory
    
def get_matrix_directory(install_directory):
    """Get the pipeline install location."""
    print("Where do you keep your rectification matricies?")
    print("If you have never downloaded recmats, the default is probably fine.")
    directory = ask_for_path("Calibration Directory", default=os.path.join(install_directory, "drs", "calib"))
    log.info("Storing recmats in '%s'", directory)
    return directory
    
def extract_zip_with_commonprefix(filename, destination_dir):
    """Extract a zipfile with a common prefix."""
    log.info("Unzipping %s", filename)
    zf = zipfile.ZipFile(filename)
    prefix = os.path.commonprefix(zf.namelist())
    for name in zf.namelist():
        zf.extract(name)
        npname = name[len(prefix):]
        if not os.path.isdir(os.path.join(destination_dir, npname)):
            shutil.move(name, os.path.join(destination_dir, npname))
    log.debug("Removing zip root %s", filename)
    shutil.rmtree(prefix)
    
def install_pipeline(directory):
    """Install the pipeline."""
    idl_include = get_idl_include_path()
    cfitsio_lib = get_cfitsio_path()
    download_drp_files(directory)
    os.environ["IDL_INCLUDE"] = idl_include
    os.environ["CFITSIOLIBDIR"] = cfitsio_lib
    for filename in OSIRIS_DRS_FILES:
        extract_zip_with_commonprefix(filename, os.path.join(directory, 'drs'))
    make('all', os.path.join(directory, 'drs'))
    
def configure_odrf(directory, data_directory, matrix_directory):
    """Configure ODRF"""
    import xml.etree.ElementTree as ET
    filename = os.path.join(directory, 'odrfgui', 'odrfgui_cfg.xml')
    tree = ET.parse(filename)
    root = tree.getroot()
    xml_set_paramvalue(root, 'DEFAULT_INPUT_DIR', data_directory)
    xml_set_paramvalue(root, 'DEFAULT_OUTPUT_DIR', data_directory)
    xml_set_paramvalue(root, 'DEFAULT_LOG_DIR', data_directory)
    xml_set_paramvalue(root, 'DRF_READ_PATH', data_directory)
    xml_set_paramvalue(root, 'DRF_WRITE_PATH', data_directory)
    xml_set_paramvalue(root, 'DRF_QUEUE_DIR', os.path.abspath(os.path.join(directory, 'drs', 'drf_queue')))
    xml_set_paramvalue(root, 'OSIRIS_DRP_BACKBONE_CONFIG_FILE', os.path.abspath(os.path.join(directory, 'drs', 'backbone', 'SupportFiles', 'RPBconfig.xml')))
    xml_set_paramvalue(root, 'OSIRIS_CALIB_ARCHIVE_DIR', os.path.abspath(matrix_directory))
    log.info("Configured ORDFGUI by changing '%s'", filename)
    tree.write(filename)
    
def xml_set_paramvalue(root, name, value, tag="File", comment=""):
    """docstring for xml_replace_paramvalue"""
    import xml.etree.ElementTree as ET
    
    node = root.find("*[@paramName='{0:s}']".format(name))
    if node is not None:
        print(node)
        node.set("value", value)
    else:
        ET.SubElement(root, tag, dict(paramName=name, value=value, desc=comment))
    
    
def install_tools(directory):
    """Install pipeline tools"""
    matrix_directory = get_matrix_directory(directory)
    data_directory = get_data_directory(directory)
    download_tools_files(directory)
    for filename, destination_dir in OSIRIS_TOOLS_FILES.items():
        destination_path = os.path.join(directory, destination_dir)
        if destination_path[-1] != os.path.sep:
            destination_path += os.path.sep
        if not os.path.exists(destination_path):
            os.mkdir(destination_path)
        if filename.endswith(".tar.gz"):
            subprocess.check_call(["tar","-C",destination_path, "-xzf", filename])
        elif os.path.abspath(os.path.realpath(filename)) != os.path.abspath(os.path.realpath(destination_path)):
            try:
                shutil.copy2(filename, destination_path)
            except shutil.Error:
                pass
    configure_odrf(directory, data_directory, matrix_directory)
    for script, src in OSIRIS_LINKED_COMMANDS.items():
        dst = os.path.join(directory, 'drs', 'scripts', script)
        if os.path.exists(dst):
            os.remove(dst)
        st = os.stat(src)
        os.chmod(src, st.st_mode | stat.S_IEXEC)
        os.symlink(os.path.abspath(src), os.path.abspath(dst))
    write_script(os.path.join(directory, 'drs', 'scripts', 'odrfgui'), ODRPGUI_SCRIPT)
    write_script(os.path.join(directory, 'drs', 'scripts', 'oopgui'), OOPGUI_SCRIPT)
    log.info(RECMAT_MESSAGE, dict(matrix_directory=os.path.abspath(matrix_directory), install_dir=os.path.abspath(directory)))
    
def write_script(dst, content):
    """docstring for write_script"""
    if os.path.exists(dst):
        os.remove(dst)
    with open(dst, 'w') as f:
        f.write(content)
    st = os.stat(dst)
    os.chmod(dst, st.st_mode | stat.S_IEXEC)
    
    
def make(command, directory):
    """Run 'make' and capture output."""
    log.info("From %s", directory)
    log.info("Running 'make {0}'".format(command))
    ps = subprocess.Popen(['make', command], cwd=os.path.abspath(directory), stderr=subprocess.STDOUT, stdout=subprocess.PIPE)
    stdout, stderr = ps.communicate()
    for line in stdout.splitlines():
        log.debug(line)
    if ps.returncode != 0:
        raise subprocess.CalledProcessError(ps.returncode, ['make', command], stdout)
    log.info("Build successful")
    return
    
def get_odrf_settings():
    """Get the settings for ODRFGUI"""
    print("In what directory do you want to store the extraction matrices?")
    print(" (The default is almost certainly fine here, unless you ")
    print("  already have some other directory full of extraction matrices.) ")
    print("Press enter for the default.")
    matrix_directory = ask_for_path("Extraction Matrix Directory", default=os.path.join(drs_directory, "calib"))
    log.info("Setting the matrix directory to '%s'", matrix_directory)
    
ODRPGUI_SCRIPT = """
cd ${OSIRIS_ROOT}../odrfgui && java -Djava.security.policy=java.policy.odrfgui -jar ./odrfgui.jar cfg=./odrfgui_cfg.xml
"""
OOPGUI_SCRIPT = """
cd ${OSIRIS_ROOT}../oopgui && java -Djava.security.policy=java.policy.oopgui -jar ./oopgui.jar cfg=./oopgui_cfg.xml
"""

INSTALL_HEADER = """

*********   OSIRIS DRS installation script  ********

 WARNING: This script has ONLY been tested on an Intel Mac
    
    Questions, comments, and bug reports to 
        osiris_info@keck.hawaii.edu  
    
*****************************************************   
    
  READ THIS FIRST:    
  To install the OSIRIS DRS, you need the following things 
   1) a working copy of IDL, with 'idl' located somewhere in your $PATH 
   2) the CFITSIO library. On a Mac, you can install this either 
      from source via Fink/MacPorts/HomeBrew, or get a binary as part of the 
      SciSoft distribution of astronomy software. 
   3) about 25 MB for the pipeline itself, plus 160 MB for each 
      extraction matrix, one per filter/pixel scale combination. 
 
This script will now ask you a few locations about where these things are 
located, after which it will download and install the software.
"""

INSTALL_POSTSCRIPT = """
*****************************************************   
    
OSIRIS Software Installed Successfully!

%(installed_software)s

"""

ENVIRONMENT_MESSAGE="""
 You should now add the following lines to your shell config files:
 
 For bash (or other POSIX shells):
   soruce %(osiris_setup_script)s.sh
   osirisSetup %(install_dir)s/drs
   export PATH=${PATH}:${OSIRIS_ROOT}/scripts

 For c-shell (csh/tcsh etc.):
   
   setenv OSIRIS_ROOT %(install_dir)s/drs
   source %(osiris_setup_script)s.csh
   setenv PATH ${PATH}:${OSIRIS_ROOT}/scripts

You can then type %(commands)s at your shell. 

"""

RECMAT_MESSAGE = """
Note that you will need to download the desired rectification matrices
from http://tkserver.keck.hawaii.edu/osiris/
(These are huge, 150 MB each, so they are not automatically downloaded.)
You should then install these files into the following directory: 
    %(matrix_directory)s
 
See the OSIRIS manual in %(install_dir)s for more info.
"""

ODRF_CONFIG_MESSAGE="""
You can further customize your directory path settings for ODRFGUI by editing 
the ODRFGUI config file, %(odrf_config)s See %(odrf_readme)s for more info.
    Good luck!
"""

def display_finished_info(otools, drs_directory):
    """Display the finished information."""
    installed = [" * Data Reduction System             (drs)"]
    if otools:
        installed += [" * OSIRIS Observation Planning GUI   (oopgui)"]
        installed += [" * OSIRIS Data Reduction File GUI    (odrfgui)"]
        installed += [" * Quicklook 2                       (ql2)"]
    
    log.info(INSTALL_POSTSCRIPT % dict(installed_software="\n".join(installed)))
    
    commands = ['run_odrp']
    if otools:
        commands += ['run_ql', 'oopgui', 'odrfgui']
    log.info(ENVIRONMENT_MESSAGE % dict(install_dir=os.path.abspath(drs_directory), osiris_setup_script=os.path.join(drs_directory, "drs", "scripts", "osirisSetup"),
        commands=", ".join(commands)))

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="OSIRIS Pipeline download and install script.")
    parser.add_argument("--drs-only", action='store_false', dest='otools', help="Only install the DRS")
    opt = parser.parse_args()
    setup_logging()
    log.info("Installing the OSIRIS Toolbox")
    log.info("Working in '%s'", os.getcwd())
    log.info(INSTALL_HEADER)
    drs_directory = get_pipeline_directory()
    install_pipeline(drs_directory)
    if opt.otools:
        install_tools(drs_directory)
    display_finished_info(opt.otools, drs_directory)

if __name__ == '__main__':
    sys.exit(main())