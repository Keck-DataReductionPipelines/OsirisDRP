# -*- coding: utf-8 -*-
"""
Functions for parsing and understanding DRFs.
"""
import os
import xml.etree.ElementTree as et

__all__ = ['expand_osiris_path']

def expand_osiris_path(path):
    """Expand an OSIRIS path which might contain environment variables."""
    return os.path.normpath(os.path.expanduser(os.path.expandvars(path)))
    

class OsirisDRF(object):
    """A data reduction file for Osiris DRF"""
    def __init__(self, tree, expand=True):
        super(OsirisDRF, self).__init__()
        self.tree = tree
        self.expand = expand
        
    @classmethod
    def parse(cls, filename):
        """Parse an OSIRIS DRF"""
        return cls(et.parse(filename))
    
    @property
    def log_directory(self):
        """Check that the log directory exists."""
        path = self.tree.getroot().get('LogPath')
        if self.expand:
            path = expand_osiris_path(path)
        return path
    
    @property
    def output_directory(self):
        """Output directory"""
        path = self.tree.getroot().find("dataset").get("OutputDir")
        if self.expand:
            path = expand_osiris_path(path)
        return path
        
    @property
    def input_directory(self):
        """Input directory."""
        path = self.tree.getroot().find("dataset").get("InputDir")
        if self.expand:
            path = expand_osiris_path(path)
        return path
    
    def data_files(self):
        """A list of input data files."""
        dataset = self.tree.getroot().find("dataset")
        input_directory = dataset.get("InputDir")
        paths = [ os.path.join(input_directory, fits.get("FileName"))
            for fits in dataset.findall("fits") ]
        if self.expand:
            paths = [expand_osiris_path(path) for path in paths ]
        return paths
        
    def calibration_files(self):
        """A list of input calibration files."""
        paths = [ module.get('CalibrationFile')
            for module in self.tree.getroot().findall("module") if 'CalibrationFile' in module.attrib ]
        if self.expand:
            paths = [expand_osiris_path(path) for path in paths ]
        return paths
        
    
    def files(self):
        """A list of all files."""
        return self.calibration_files() + self.data_files()
