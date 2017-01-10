---
layout: page
title: Long2pos Reductions
permalink: /manual/long2pos
---

A special driver is provided for long2pos reductions. The driver can also be generated automatically.

As s reminder, these observations are taken using a script which is run either from the command line (acq_long2pos) or via the background menu. The script produces different results depending on whether the long2pos mask was setup in science mode (only narrow slits) or in alignment mode (narrow and wide slits).

In the general case of a combination of narrow and wide slits, each run of the script generates 6 images, 3 for each of the two slits. We will refer to the two positions as position A and position C (position B is the intial position used only for alignment).

Depending on when your data was generated, you might find different Offset files in your directory. Files generated before June 10, 2015 use a different set of YOFFSET keywords than files generated after that date. Unfortunately, the set of keywords generated before June 10, 2015 is not compatible with the pipeline and must be updated: for this we provide a special set of instructions as part of as the driver file to automatically update the keywords.

For files generated before June 10, 2015, you will find 6 Offset files, named Offset_XXX_object_name_PosY.txt, where XXX can be -21, -14,-7, 7, 14 and 21, the object name is taken from the object keyword, and Y can be either A or C. Similar names are produced if the observations has the correct keywords, but in that case XXX will be one of -7, 0, or 7.

It is important to notice that the reduction described here is based on the assumption that proper arc lamps are obtained in the afternoon. Specifically, either a Ne or Ar calibration must be obtained with the long2pos mask executed in science mode, and not in alignment mode. In science mode the wide part of the slits is not present. If the slit was executed in alignment mode, the wide part of the slits would prevent a wavelength calibration.

Note that this also means that if you took your science data at night in long2pos_specphot mode, the mask name of your science file might be long2pos_specphot, rather than long2pos, and the arcs and flats might end up in the wrong subdirectory when the files are processed via mospy handle. In this case it will be necessary to copy Ar.txt, Ne.txt and Flat*.txt from the directory long2pos to your long2pos_specphot directory.

Let’s now look at the driver file.  The declaration "longslit =" is used to define the pixel boundaries of the long2pos observations. In general, it is correct and should not be changed. It might need to be updated in the future is a new long2pos mask is used. Note that it is important to specify ‘mode’=’long2pos’

The following section describes the rather long list of Offset files that we will use for the reduction.

For observations obtained before June 10, 2015, this section might look like this:

    obsfiles_posC_narrow = ['Offset_-21_HIP85871_PosC.txt', 'Offset_-7_HIP85871_PosC.txt']
    targetCnarrow = "HIP85871_posC_narrow"

    obsfiles_posA_narrow = ['Offset_7_HIP85871_PosA.txt', 'Offset_21_HIP85871_PosA.txt']
    targetAnarrow = "HIP85871_posA_narrow"

    obsfiles_posC_wide = ['Offset_-14_HIP85871_PosC.txt','Offset_-7_HIP85871_PosC.txt']
    targetCwide = "HIP85871_posC_wide"

    obsfiles_posA_wide = ['Offset_14_HIP85871_PosA.txt','Offset_21_HIP85871_PosA.txt']
    targetAwide = "HIP85871_posA_wide"

Files -21_PosC and -7_PosC are the A and B positions for the C pointing, files 7 and 21 are the A and B positions for the A pointing. For the wise slits, file 7_PosC is used as a sky (B) for the -14_PosC position, and file 21_PosA is used as a sky for the 14_PosA position. The target keywords must also be specified to avoid accidental overwrite of intermediate files.

For files obtained after June 10, 2015, the same section would look like this:

    obsfiles_posC_narrow = ['Offset_7_FS134_posC.txt','Offset_-7_FS134_PosC.txt']
    targetCnarrow = "FS134_posC_narrow"
    obsfiles_posA_narrow = ['Offset_7_FS134_posA.txt','Offset_-7_FS134_PosA.txt']
    targetAnarrow = "FS134_posA_narrow"
    obsfiles_posC_wide = ['Offset_0_FS134_posC.txt','Offset_-7_FS134_PosC.txt']
    targetCwide = "FS134_posC_wide"
    obsfiles_posA_wide = ['Offset_0_FS134_posA.txt','Offset_-7_FS134_PosA.txt']
    targetAwide = "FS134_posA_wide"

The first step is to produce a flat field.

    Flats.handle_flats('Flat.txt', maskname, band, flatops, longslit = longslit)

or

    Flats.handle_flats('Flat.txt', maskname, band, flatops,lampOffList='FlatThermal.txt', longslit=longslit)

Using argon (or neon) lines, we can now produce a wavelength calibration.

    Wavelength.imcombine(argon, maskname, band, waveops)
    Wavelength.fit_lambda_interactively(maskname, band, argon, waveops, longslit=longslit, argon=True)
    Wavelength.fit_lambda(maskname, band, argon, argon, waveops, longslit=longslit)
    Wavelength.apply_lambda_simple(maskname, band, argon, waveops, longslit=longslit, smooth=True)

While using the interactive fitting, note that there are two slits to fit.

The next section of the driver reduces the narrow slits. The optional line 

    IO.fix_long2pos_headers(obsfiles)

is ONLY necessary if your observations were taken before June 10, 2015. It is safe to leave this line on for a second run: the script will not modify the same files twice.

Rememeber to update the lambda_solution_wave_stack file: you can update this in the variable wavelength_file, which will be used by the following instructions.

The driver contains instructions on how to perform background subtraction and finally rectification, in a similar way as for a normal mask.

The resulting files are the same as in the standard reduction, but the main results are contained in:

    {object}_posA_narrow_{filter}_eps.fits

and 

    {object}_posC_narrow_{filter}_eps.fits

For the wide slits, since there is no AB pattern, we use the sky provided by one of the observations in the narrow slits, and we do not perform the final rectification.

In this case the final science results are contained in:

    bsub_{object}_posC_wide_{filter}_A-B.fits

and

    bsub_{object}_posA_wide_{filter}_A-B.fits


