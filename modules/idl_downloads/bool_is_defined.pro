;-----------------------------------------------------------------------
; NAME:  bool_is_defined
;
; PURPOSE: Check if input is defined
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is defined 0 else
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_defined, In

   return, n_elements(In) eq 0 ? 0 : 1

END 
