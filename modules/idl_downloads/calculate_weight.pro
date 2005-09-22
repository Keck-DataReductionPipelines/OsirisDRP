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
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function intframe2noise, v, /REV

   if ( keyword_set ( REV ) ) then return, 1./(v*v) else return, 1./sqrt(v)

end
