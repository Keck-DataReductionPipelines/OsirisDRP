;-----------------------------------------------------------------------
; NAME:  bool_contains_finite
;
; PURPOSE: Checks if input contains finite values.
;          Input must be a variable
;
; INPUT  :  in         : input variable
;           mask       : an array containing indices where in is finite
;
; RETURN VALUE : 1 if input contains finite values, 0 else
;
; STATUS : not tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_contains_finite, in, mask

   mask = where ( finite ( in ), n )
 
   return, n ne 0 ? 1 : 0

end
