from astropy.io import fits
from numpy import *

def compare_spxl(name):
    """Open file, extract good and bad spectra and compute std for comparison."""
    
    data_compare=fits.open(name)

    data_compare_cube = data_compare[0].data

    data_compare_collapsed = mean(data_compare_cube,axis=2)


    #24,30 is bad
    #23,30 has peak flux and good spec
    #22,30 is good spec

    ratio_spec_bad = (data_compare_cube[24,30]/sum(data_compare_cube[24,30]))/(data_compare_cube[23,30]/sum(data_compare_cube[23,30])) #ratio between good and bad spaxel

    ratio_spec_good = (data_compare_cube[22,30]/sum(data_compare_cube[22,30]))/(data_compare_cube[23,30]/sum(data_compare_cube[23,30])) #ratio between good and good spaxel


    std_ratio_bad = std(ratio_spec_bad) #compute standard deviation in bad ratio spectrum
    std_ratio_good = std(ratio_spec_good) #compute standard deviation in good ratio spectrum




    data_compare.close

    return abs(std_ratio_bad-std_ratio_good),abs(std_ratio_bad-std_ratio_good) < 0.05

def compare_cubes(name1,name2):
    """Compares two data cubes."""
    
    print str(compare_spxl(name1)) + ' Original'
    print str(compare_spxl(name2)) + ' New pipeline results'

