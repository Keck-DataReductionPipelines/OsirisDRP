;-------------------------------------------------------------------------
; NAME: make_dataset_euro3d_compliant
;
; PURPOSE: make cubes and images EURO3D compliant
;          EURO3D compliant cubes images have the wavelength axis as
;          the first axis. SINFONI compliant cubes and images have the
;          wavelength axis as the last axis.
;
; INPUT : DataSet  : DataSet pointer
;         nFrames  : number of dataset
;         [/REV]   : makes the cubes or images SINFONI compliant
;
; NOTES : Header keywords like CDELT, CRPIX or CRVAL are not changed.
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------
pro make_dataset_euro3d_compliant, DataSet, nFrames, REV=REV

   make_euro3d_compliant, DataSet.Frames, nFrames, REV=REV
   make_euro3d_compliant, DataSet.IntFrames, nFrames, REV=REV
   make_euro3d_compliant, DataSet.IntAuxFrames, nFrames, REV=REV

end
