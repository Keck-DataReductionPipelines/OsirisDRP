#!/usr/bin/env python
import argparse
import os
import numpy as np
from astropy.io import fits
import glob
import astropy

def apply_mask(infile,maskfile,deadpixelfile,outfile):
    '''
    Apply a bad pixel mask to the third extension of a file

    Inputs
    ------
    infile - input file name of raw
    maskfile - mask file name (9 = good, 0 = bad)
    deadpixelfile - file with dead pixels (1 = good, 0 = bad)
    outfile - output file name, can be same as input (will
    overwrite)

    '''

    if os.path.exists(infile):
        hdu = fits.open(infile)
        mask = fits.getdata(maskfile)
        deadpixels = fits.getdata(deadpixelfile)
        mask = mask*deadpixels
        mask = np.array(mask,dtype='uint8')
        hdu[2].data = mask
        hdu[0].header['BPM'] = (maskfile, 'Bad pixel mask applied')
        hdu[0].header['DEADPIX'] = (deadpixelfile, 'Dead pixel mask applied')        
        print("writing: "+outfile)
        ver = float(astropy.__version__.split('.')[0])
        if ver < 2:
            hdu.writeto(outfile,clobber=True)
        else:
            hdu.writeto(outfile,overwrite=True)

parser = argparse.ArgumentParser()
parser.add_argument("inputfile",help="Input file(s), can have wildcard characters",type=str,nargs='+')
parser.add_argument("-m","--mask",help="filename of the bad pixel mask to apply (default: badpixelmask20170902_sigma50.fits.gz)")
parser.add_argument("-d","--deadpixels",help="filename of the dead pixel pixel mask to apply (default: bpm_deadpixels_null.fits.gz)")

args = parser.parse_args()

if args.mask is None:
    directory = os.getenv('OSIRIS_ROOT', './')
    bpm = os.path.join(directory,'data/badpixelmask20170902_sigma50.fits.gz')
else:
    bpm = args.mask

if args.deadpixels is None:
    directory = os.getenv('OSIRIS_ROOT', './')
    deadpixelfile = os.path.join(directory,'data/bpm_deadpixels_null.fits.gz')
else:
    deadpixelfile = args.deadpixels

if os.path.exists(bpm):
    print("bad pixel mask found: "+bpm)
else:
    print("bad pixel mask not found: "+bpm)
    
if os.path.exists(deadpixelfile):
    print("dead pixel mask found: "+deadpixelfile)
else:
    print("dead pixel mask not found: "+deadpixelfile)

print("using mask: "+bpm)
print("using dead pixel mask: "+deadpixelfile)

print(args.inputfile)

for tmp in args.inputfile:
    print("applying bad pixel mask to "+tmp)
    apply_mask(tmp,bpm,deadpixelfile,tmp)
    
