#!/usr/bin/env python
import argparse
import os
import numpy as np
from astropy.io import fits
import glob
import astropy


parser = argparse.ArgumentParser()
parser.add_argument("inputfile",help="Input file(s), can have wildcard characters",type=str,nargs='+')
parser.add_argument("-m","--mask",help="filename of the bad pixel mask to apply (default: badpixelmask20170902_sigma50.fits.gz)")
parser.add_argument("-d","--deadpixels",help="filename of the dead pixel pixel mask to apply (default: bpm_deadpixels_null.fits.gz)")

args = parser.parse_args()

# imager INSTR='imag'
# spectrograph INSTR = 'spec'

#osiris_keywords = ['ITIME','TRUITIME','COADDS','INSTR','PA_SPEC','PA_IMAG','IFILTER','SFILTER','SSCALE']
osiris_imag_keywords = ['TARGNAME','DATE-OBS','UTC','ITIME','COADDS','PA_IMAG','IFILTER']
osiris_spec_keywords = ['TARGNAME','DATE-OBS','UTC','ITIME','COADDS','PA_SPEC','SFILTER','SSCALE']


for counter,tmp in enumerate(args.inputfile):
    hdr = fits.open(tmp)
    header = hdr[0].header
    if header['INSTR'] == 'imag':
        output = [str(header[i]) for i in osiris_imag_keywords]
        if counter == 0:
            print('FILENAME \t'+'\t'.join(osiris_imag_keywords))
    if header['INSTR'] == 'spec':
        output = [str(header[i]) for i in osiris_spec_keywords]
        if counter == 0:
            print('FILENAME \t'+'\t'.join(osiris_spec_keywords))
    output = '\t'.join(output)
    
    print(tmp+'\t'+output)
    