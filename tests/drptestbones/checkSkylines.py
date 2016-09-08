import pyfits
import sys
import numpy as np

def checkSkylines(filename,min_lambda,max_lambda,sumRow,outname):

    file = pyfits.open(filename)
    data = file[0].data
    hdr = file[0].header
    sizeLambda = data.shape[2]

    min_image_lambda = hdr['CRVAL1']
    delta_lambda = hdr['CDELT1']

    min_pixel = int(round((min_lambda - min_image_lambda) / delta_lambda))
    max_pixel = int(round((max_lambda - min_image_lambda) / delta_lambda))

    if (min_pixel >= max_pixel):
        sys.exit("Max lambda needs to be greater than min lambda")

    if (min_pixel < 0):
        sys.exit("Selected minimum wavelength is off detector")

    if (max_pixel > sizeLambda):
        sys.exit("Selected maximum wavelength is off detector")

    onlyLine = data[:,:,min_pixel:max_pixel]

    sumLine = np.sum(onlyLine,axis=2)

    sumRowOnly = sumLine[:,sumRow]

    totalRMS = np.std(sumLine)
    rowRMS = np.std(sumRowOnly)


    pyfits.writeto(outname,sumLine,clobber=True)

    return totalRMS, rowRMS
