;-------------------------------------------------------------------------
; NAME: euro3d_compliant
;
; PURPOSE: make cubes and images EURO3D compliant.
;          EURO3D compliant cubes/images have the wavelength axis as
;          the first axis. SINFONI compliant cubes and images have the
;          wavelength axis as the last axis.
;
; INPUT : aa     : cube or image or pointer to cube or image
;         [/REV] : makes a cube or image SINFONI compliant
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------
function euro3d_compliant, aa, REV=REV

   if ( bool_is_ptr ( aa ) ) then a = *aa else a = aa

   n_Dims = size ( a )

   if ( bool_is_cube ( a ) ) then begin

      if ( NOT keyword_set ( REV ) ) then $
         return, reform ( transpose ( reform ( a, n_Dims(1)*n_Dims(2), n_Dims(3) ) ), $
                   n_Dims(3), n_Dims(1), n_Dims(2) ) $
      else $
         return, reform ( transpose ( reform ( a, n_Dims(1), n_Dims(2)*n_Dims(3) ) ), $
                   n_Dims(2), n_Dims(3), n_Dims(1) )

   endif else begin

      return, transpose( a )

   end

end
