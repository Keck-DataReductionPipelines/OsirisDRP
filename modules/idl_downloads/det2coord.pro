;-----------------------------------------------------------------------
; NAME: det2coord
;
; PURPOSE: determine the coordinates of points on the sky that are
;          shifted by X and Y pixel in the FoV.
;
; INPUT :   md_Coords : matrix (2,number of coordinates) with the
;                       offsets in X and Y
;           d_Alpha   : Right ascencion for offset 0,0
;           d_Delta   : Declination for offset 0,0
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

function det2coord, md_XY, d_Alpha, d_Delta, d_Scale, d_PA

   COMMON APP_CONSTANTS

   functionName = 'det2coord.pro'

   n_Dims = size ( md_XY )

   vd_X = reform(md_XY(0,*)) / 3600. * d_Scale ; image offsets in degree
   vd_Y = reform(md_XY(1,*)) / 3600. * d_Scale

   md_Coords = dblarr(2,n_elements(vd_X))
   md_Coords(1,*) = d_Delta + ( vd_X * cos(d_PA) + vd_Y * sin(d_PA) )
   md_Coords(0,*) = d_Alpha - (- vd_X * sin(d_PA) + vd_Y * cos(d_PA)) / $
                    cos ( md_Coords(1,*) / !RADEG )

   return, md_Coords

end
