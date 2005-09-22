;-----------------------------------------------------------------------
; NAME:  bool_contains_nan
;
; PURPOSE: Checks if input contains NAN values.
;
; INPUT  :  in          : input variable 
;           mask        : an array containing indices where in is nan
;
; RETURN VALUE : 1 if input contains NAN values, 0 else
;
; STATUS : not tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_contains_nan, in, mask

   mask = where ( finite ( in, /NAN ), n )

   return, (n ne 0) ? 1 : 0
 
end
