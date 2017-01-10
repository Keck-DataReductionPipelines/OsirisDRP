---
layout: page
title: Rectify
permalink: /manual/rectify
---

The next step in the reduction process is to combine the wavelength solution with the backgroun subtracted images and then shift and combine the nod positions. If reducing Kband, be sure to use the merged wave_stack solution.  To do this we uncomment the following lines in the Driver.py file:

    redfiles = ["eps_" + file + ".fits" for file in obsfiles]
    Rectify.handle_rectification(maskname, redfiles,
        'lambda_solution_wave_stack_J_m130114_0443-0445.fits',
        band,
        waveops)

The output from this procedure produces four files for every slit.

| Filename                         | Content (units)                                                             |
|----------------------------------|-----------------------------------------------------------------------------|
| `[maskname]_[band]_[object]_eps.fits` | Signal () |
| `[maskname]_[band]_[object]_itime.fits` | Integration time  |
| `[maskname]_[band]_[object]_sig.fits` | Variance  ? |
| `[maskname]_[band]_{object}_snrs.fits` | Signal to noise () |

There is also four images without the “object” in the name. These four files contain the composit spectra with all spectra aligned spectrally and both beams combined. In the *eps.fits files, you will see two negative traces and one positive trace.  For a two position nod, the eps files is (A-B) +((B-A)shifted).

When extracting the emission from an object or measuring the position of an emission line, you should be accessing the *eps.fits files with the wavelength solution written into the WCS information.

