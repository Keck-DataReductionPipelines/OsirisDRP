;-----------------------------------------------------------------------
; NAME:  bool_is_scalar
;
; PURPOSE: Check if input is a scalar
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a scalar, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_scalar, In

   return, (size(In))(0) eq 0

END 
