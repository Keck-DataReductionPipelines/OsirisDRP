from drizzle3D_modules import combine_frames_wcs
from drizzle3D_modules import combine_frames_findpo
from drizzle3D_modules import get_wcs
from drizzle3D_modules import get_ref_fitting
from drizzle3D_modules import get_ref_input
from drizzle3D_modules import get_ref_wcs
from drizzle3D_modules import is_not_number
from drizzle3D_modules import is_number
from drizzle3D_modules import header
from astropy.io import fits
import sys
import time

# python drizzle3D_fast.py directory, frame1, frame2...
# ...frame3.., option1(find_p or wcs or input), d_fine, option2(staking#), option3(average, median), option4(fracpixel)

# get input arguments
input_file = sys.argv

# check input argument format
for i in range(5):
    if is_not_number(input_file[-(i+1)]):
        raise ValueError('There should be 5 numbers by the end of commands')
if is_number(input_file[-6]):
    raise ValueError('There should be only 5 numbers by the end of commands')

# get input information
directory = input_file[1]+'/'  # directory of data cubes
d_orig = get_wcs(directory + input_file[2])[0]  # the size of the coarse grid in arcsec
fracpixel_input = float(input_file[-1])  # input fractional pixel
combine_type = float(input_file[-2])  # choose median or average
stacking_N = float(input_file[-3])  # choose to stacking per # of channels
d_fine = float(input_file[-4])  # arcsec ##the physical size of the fine grid, which must be smaller than d_orig
Number_of_files = len(input_file) - 7  # number of input files
find_position = float(input_file[-5])  # either wcs or auto-detection. if auto, need config file in the same directory.

print('The final pixel size is', d_fine)

# choose the fractional pixel value.
if fracpixel_input == -1:
    pixfrac = 0.7  # default is 0.7 based on Avila et al. 2015
    print("The default value of pixfrac is", pixfrac, "based on Avila et al. 2015")
elif 0 < fracpixel_input < 1:
    pixfrac = fracpixel_input  # it must be 0 to 1 ## the fractional size of drizzle patten
    print("the pixfrac value is (recommendation = 0.7) ", pixfrac)
else:
    raise ValueError('fractional pixel must be >0 and <1')

# determine the size of fine grid.
d_drizzle = pixfrac * d_orig

# print out the stacking number
if stacking_N == -1:
    print("The default number of channels for staking is", 10)
else:
    print("The number of channels for stacking is", stacking_N)

# print out the stacking type
if combine_type == -1:
    print("The default of stacking type is Average")
elif combine_type == 1:
    print("stacking type is Average")
elif combine_type == 2:
    print("stacking type is Median")
else:
    print("-1: default; 1: Average; 2: Median")

# obtain the reference point for the fine grid from all input files
starttotal = time.time()
if find_position == 2:
    print("Using WCS info to determine the relative positions of each frame")
    F_re_x_min, F_re_y_min, F_re_x_max, F_re_y_max = get_ref_wcs(input_file, Number_of_files)
    final_image, final_cover = combine_frames_wcs(input_file, d_orig, d_drizzle, d_fine, F_re_y_min, F_re_y_max,
                                                   F_re_x_min, F_re_x_max)
elif find_position == 3:
    F_re_x_min, F_re_y_min = 0, 0
    print('Using auto-detection to determine the relative positions of each frame. '
          'Warning: possibly not accurate enough')
    start = time.time()
    reference_po, F_re_x_max, F_re_y_max = get_ref_fitting(input_file, Number_of_files, d_orig)
    end = time.time()
    print("time for finding the reference positions:", round(end - start, 2), "seconds")
    final_image, final_cover = combine_frames_findpo(input_file, d_orig, d_drizzle, d_fine, reference_po, F_re_y_min,
                                                      F_re_y_max, F_re_x_min, F_re_x_max)
elif find_position == -1 or 1:
    F_re_x_min, F_re_y_min = 0, 0
    print('Using dither pattern as an input to determine the relative positions')
    start = time.time()
    reference_po, F_re_x_max, F_re_y_max = get_ref_input(input_file, Number_of_files, d_orig)
    end = time.time()
    print("time for getting the reference positions:", round(end - start, 2), "seconds")
    final_image, final_cover = combine_frames_findpo(input_file, d_orig, d_drizzle, d_fine, reference_po, F_re_y_min,
                                                      F_re_y_max, F_re_x_min, F_re_x_max)
else:
    raise ValueError('dither pattern (default) = 1, wcs = 2, auto-detection = 3')
endtotal = time.time()

hdul= header(final_image, d_fine, F_re_y_min, F_re_x_min, input_file)
hdul.writeto(directory + "drizzled_cube.fits", clobber=True)
print("time for all drizzling process:", round(endtotal - starttotal, 2), "seconds")
print("The size of the final drizzled data cube:", final_image.shape)
#fits.writeto(directory + "drizzled_cube.fits", final_image, clobber=True)
#fits.writeto(directory + "drizzled_weight.fits", final_weight, clobber=True)
fits.writeto(directory + "drizzled_cover.fits", final_cover, clobber=True)
