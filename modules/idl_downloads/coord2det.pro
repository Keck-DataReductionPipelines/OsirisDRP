;-----------------------------------------------------------------------
; NAME: coord2det
;
; PURPOSE: determine offsets used for mosaicing from coordinates
;
; INPUT :   md_Coords : matrix (2,number of coordinates) with the coordinates
;                       right ascencion and declination or X/Y offsets
;           d_Scale   : scale in arcsec per spatial element
;           d_PA      : position angle in radian
;
; OUTPUT : matrix with offsets
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS else OK
;
; NOTES : 
;
; STATUS : untested
;
; HISTORY : 25.8.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function coord2det, md_Coords, d_Scale, d_PA

   COMMON APP_CONSTANTS

   functionName = 'coord2det.pro'

   ; coordinates are right ascencion and declination in degrees
   vd_DDec =  reform( md_Coords(1,0) - md_Coords(1,*) ) * 3600. / d_Scale
   vd_DRA  =  reform( md_Coords(0,0) - md_Coords(0,*) ) * 3600. / d_Scale * $
              cos ( reform(md_Coords(1,*)) * !pi/180. )

   md_Offsets = dblarr(2,n_elements(vd_DDec))
   md_Offsets(0,*) = -1.*(vd_DRA * sin(d_PA) + vd_DDec * cos(d_PA))
   md_Offsets(1,*) =      vd_DRA * cos(d_PA) - vd_DDec * sin(d_PA)

   return, md_Offsets

end
