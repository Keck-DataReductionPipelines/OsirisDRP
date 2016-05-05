# -*- coding: utf-8 -*-
"""
Functions for parsing and understanding DRFs.
"""
import os
import xml.etree.ElementTree as et

__all__ = ['expand_osiris_path']

def expand_osiris_path(path):
    """Expand an OSIRIS path which might contain environment variables."""
    path = os.path.normpath(os.path.expanduser(os.path.expandvars(path)))
    

class OsirisDRF(object):
    """A data reduction file for Osiris DRF"""
    def __init__(self, tree):
        super(OsirisDRF, self).__init__()
        self.tree = tree
        
    @classmethod
    def parse(cls, filename):
        """Parse an OSIRIS DRF"""
        return cls(et.parse(filename))
    
    @property
    def log_directory(self):
        """Check that the log directory exists."""
        return expand_osiris_path(self.tree.find("DRF").get('LogPath'))
    
    @property
    def output_directory(self):
        """Output directory"""
        return expand_osiris_path(self.tree.find("DRF/dataset").get("OutputDir"))
        
    @property
    def input_directory(self):
        """Input directory."""
        return expand_osiris_path(self.tree.find("DRF/dataset").get("InputDir"))
    
    def data_files(self):
        """A list of input data files."""
        dataset = self.tree.find("DRF/dataset")
        input_directory = dataset.get("InputDir")
        return [ expand_osiris_path(os.path.join(input_directory, fits.get("FileName")))
            for fits in dataset.findall("fits") ]
        
    def calibration_files(self):
        """A list of input calibration files."""
        return [ expand_osiris_path(module.get('CalibrationFile'))
            for module in self.tree.findall("DRF/module") if 'CalibrationFile' in module.attrib ]
        
    
    def files(self):
        """A list of all files."""
        return self.calibration_files() + self.data_files()
