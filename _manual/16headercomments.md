---
layout: page
title: A Word About Header Comments
permalink: /manual/headercomments
---

Files produced by the DRP have a series of information in the FITS header that helps users determine the pedigree of files involved in the reduction. Since many files go into reductions, FITS headers are enormous and some documentation about them is useful.

The derived product FITS headers are organized as follows. The header of the first science file in the ‘A’ frame goes directly into the header. As the rest of the ‘A’ frames go into the header, the new keyword is checked against the current header. If the value of the keyword is different, a new keyword is added with the key postpended by _img### where ### is the file number. A special keyword called imfno### is created showing the full path to the file in the data reduction set. An example is shown below:

![Screenshot](image9.png "ds9 output of the FITS header. Note that the first "A" frame file is located in /scr2/mosfire/2013nov26/m131126_0135.fits. The second file (#137) has a similar path. The keywords which follow from file #137 have different values than those in file #135 and are thus named KEY_img###.")

ds9 output of the FITS header. Note that the first "A" frame file is located in /scr2/mosfire/2013nov26/m131126_0135.fits. The second file (#137) has a similar path. The keywords which follow from file #137 have different values than those in file #135 and are thus named KEY_img###.
