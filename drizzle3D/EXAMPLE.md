# Example Usage

## System Info
- MacBook Pro Intel Core i7
- macOS Sierra version 10.12.6
- Python 3.6.1 |Anaconda custom (x86_64)


## go to the directory where you put the drizzle3D_fast.py and drizzle3D_modules.py

Chih-FandeMacBook-Pro-4:drizzle3D Geoff$ pwd
/Users/Geoff/GitHub/OsirisDRP/drizzle3D

## type following commands to perform the drizzling.

python drizzle3D_fast.py directory frame1 frame2 ... frameN option1 d_fine option2 option3 option4

- "directory" is the path where you put the data cubes (after sky substraction)

- "frame1 frame2 ... frameN" are the data cubes in the directory you want to drizzle

- "option1" choose which method to find the relative distance of each frame.
1: Using dither pattern as an input to determine the relative positions
2: Using WCS info to determine the relative positions of each frame
3: Using auto-detection to determine the relative positions of each frame

The default is -1, which use dither pattern as an input.

If users choose 1 (or -1), users need to supply a text file, config_input, in the same file directory. The coordinates show behind the frame name is in unit of arcsecond. Actually it is the dither pattern one used in observing. See an example below.
#######################################################################################
Chih-FandeMacBook-Pro-4:drizzle_file Geoff$ emacs config_input

# input info

# name x y (in arcsec)

contSub_Central_170517.fits 2.2547 1.673

contSub_Central_170518_new.fits 2.27815 1.65655

contSub_Central_170519.fits 2.35025 1.61245
#######################################################################################

If users choose 2, no action is needed

If users choose 3, users need to supply a text file, config, in the same file directory. The coordinates show behind the frame name are the pixel coordiates where every frame share the same feature. For example, if the target is a star, the x and y can be the pixel coorediate which has brightest intensity. The last number is the intensity at that pixel. See below.

#######################################################################################
Chih-FandeMacBook-Pro-4:drizzle_file Geoff$ emacs config

# input info

# name x y (in pixel coordiate) intensity

s180816_a003002_Kn3_100.fits 35 23 2651

s180816_a003003_Kn3_100.fits 35 23 2997

s180816_a003004_Kn3_100.fits 34 24 1434
#######################################################################################

- "d_fine" is the physical size of the fine grid (in the unit of arcsec) *no default value

- "option2" choose to stacking per # of channels. Ex: 30 means that the final drizzled cube will stacking every 30 channels. The default, -1, is to stack every 10 channels.

- "option3" choose how to stack channels.
1 (or default, -1): average
2: Median

- "option4" choose the fractional size of original pixel (value should >0 and <1). default is 0.7.

except drizzled_cube.fits, the drizzle3D_fast.py will also output drizzled_cover.fits

drizzled_cover.fits presents how much information from the coarse drop into each fine pixel. It is crucial to make sure that the area of interest (usually it is the brightest area in the center) is uniformly coverd with the info from coarse pixel. Thus, users need to check the RMS/median inside the area of interest. The value should < 0.2. See more detail in Avila et al. 2015



An example:

python drizzle3D_fast.py /Users/Geoff/drizzle_file contSub_Central_170517.fits contSub_Central_170518_new.fits contSub_Central_170519.fits -1 0.05 -1 -1 -1

Above command ask drizzle3D_fast.py to drizzle three files (contSub_Central_170517.fits, contSub_Central_170518_new.fits, and contSub_Central_170519.fits) inside the directory, /Users/Geoff/drizzle_file, into fine grid with 0.05'' per pixel. The method to find the position is using dither pattern (default) inside a text file, config_input. It stacking every 10 channels (default) in the output data cube. The stacking method is average (default). the fractional pixel is 0.7 (default).

