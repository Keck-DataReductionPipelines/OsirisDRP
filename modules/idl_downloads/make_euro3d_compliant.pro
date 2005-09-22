;-------------------------------------------------------------------------
; NAME: make_euro3d_compliant
;
; PURPOSE: make cubes and images EURO3D compliant
;          EURO3D compliant cubes images have the wavelength axis as
;          the first axis. SINFONI compliant cubes and images have the
;          wavelength axis as the last axis.
;
; INPUT : p_Frames : input pointer or pointer array
;         nFrames  : number of datasets
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
pro make_euro3d_compliant, p_Frames, nFrames, REV=REV

   for i=0, nFrames-1 do $
      *p_Frames(i) = euro3d_compliant( *p_Frames(i), REV=keyword_set(REV) )

end
