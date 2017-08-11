#!/usr/bin/env python
import argparse
import os
import numpy as np
from astropy.io import fits
import glob


def apply_mask(infile,maskfile,outfile):
    '''
    Apply a bad pixel mask to the third extension of a file

    Inputs
    ------
    infile - input file name of raw
    maskfile - mask file name
    outfile - output file name, can be same as input (will
    overwrite)

    '''

    if os.path.exists(infile):
        hdu = fits.open(infile)
        mask = fits.getdata(maskfile)
        mask = np.array(mask,dtype='uint8')
        hdu[2].data = mask
        print("writing: "+outfile)
        hdu.writeto(outfile,overwrite=True)

parser = argparse.ArgumentParser()
parser.add_argument("inputfile",help="Input file(s), can have wildcard characters",type=str,nargs='+')
parser.add_argument("-m","--mask",help="filename of the bad pixel mask to apply (default: badpixelmask2017.fits.gz)")

args = parser.parse_args()

if args.mask is None:
    directory = os.getenv('OSIRIS_ROOT', './')
    bpm = os.path.join(directory,'data/badpixelmask2017.fits.gz')
else:
    bpm = args.mask

if os.path.exists(bpm):
    print("bad pixel mask found: "+bpm)
else:
    print("bad pixel mask not found: "+bpm)

print("using mask: "+bpm)
print(args.inputfile)

for tmp in args.inputfile:
    print("applying bad pixel mask to "+tmp)
    apply_mask(tmp,bpm,tmp)
    
