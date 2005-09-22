;-----------------------------------------------------------------------
; NAME:  bool_contains_inf
;
; PURPOSE: Checks if input contains infinite values.
;
; INPUT  :  in         : input variable
;           mask       : an array containing indices where in is inf
;
; RETURN VALUE : 1 if input contains infinite values, 0 else
;
; STATUS : not tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_contains_inf, in, mask

   mask = where ( finite ( in, /INFINITY ), n )

   return, (n ne 0) ? 1 : 0

end
