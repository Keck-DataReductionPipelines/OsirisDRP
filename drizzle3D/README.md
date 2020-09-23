[11/5/2018]

Purpose of this code:
drizzle3D_fast.py is a code which used to perform the subpixel drizzling in order to recover the lost spatial information but still remain the coverage and S/N. It is especially useful for the users who use 0.1'' (100 mas) scale to observe the targets.

Note that drizzle3D_fast.py only takes the data cubes after processing the sky subtraction and before doing the mosaic function. That is to say, drizzle3D_fast.py provide another option on how to combine different data frames. Thus, users need to utilize the standardn OSIRIS DRP to process the data cubes until finishing the sky substraction. Then the drizzle3D_fast.py drizzle the data cubes which output from DRP and generate drizzled_cube.fits. To see more detail, please see example.md