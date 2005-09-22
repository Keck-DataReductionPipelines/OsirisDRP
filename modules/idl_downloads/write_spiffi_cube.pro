;-----------------------------------------------------------------------
; NAME:  write_spiffi_cube
;
; PURPOSE: writes a cube compatible to the SPIFFI format
;
; INPUT :  cube  : cube to write 
;          name  ; filename
;
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

pro write_spiffi_cube, name, cube

   mkhdr,h,cube
   sxaddpar,h,'BLANK',-1.E10
   sxaddpar,h,'CTYPE1','RA---TAN'
   sxaddpar,h,'CTYPE2','DEC--TAN'
   sxaddpar,h,'CTYPE3','WAVE'
   sxaddpar,h,'CRPIX1',16.5
   sxaddpar,h,'CRPIX2',16.5
   sxaddpar,h,'CRPIX3',1281
   sxaddpar,h,'CUNIT1','DEGREE'
   sxaddpar,h,'CUNIT2','DEGREE'
   sxaddpar,h,'CUNIT3','MICRON'
   sxaddpar,h,'CRVAL1',95.57
   sxaddpar,h,'CRVAL2',-53.4
   sxaddpar,h,'CRVAL3',2.2
   sxaddpar,h,'CDELT1',-6.94444444444e-05
   sxaddpar,h,'CDELT2',-6.94444444444e-05
   sxaddpar,h,'CDELT3',0.000245
   
   writefits, name, float(cube), h

end
