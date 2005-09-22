;-----------------------------------------------------------------------
; NAME:  intframe2noise
;
; PURPOSE: Calculate noise values from the intframe values
;
; INPUT :  In  : input 
;          [/REV]: calculate from the noise values the weights
;
; OUTPUT : returns a variable of same dimension as In
;
; NOTES : intframe to noise: if an intframe value is less than 1.d-10
;                            its noise value is set to 0. 
;         noise to intframe: if an absolut noise value is less than 1.d-10
;                            its intframe value is set to 0. 
;
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function intframe2noise, v, REV=REV

   vv = v*0.

   if ( keyword_set ( REV ) ) then begin
      m = where(abs(v) gt 1.D-10, nm)
      if ( nm gt 0 ) then vv(m) = 1./(v(m)*v(m)) 
   endif else begin
      m = where(v gt 1.D-10, nm)
      if ( nm gt 0 ) then vv(m) = 1./sqrt(v(m))
   end

   return, vv

end
