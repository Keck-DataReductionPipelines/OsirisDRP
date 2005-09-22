;-----------------------------------------------------------------------
; NAME:  bool_is_struct
;
; PURPOSE: Check if input is a string
;
; INPUT :  In    : input variable
;
; OUTPUT : 1 if input is a string, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_string, In

   return, size(In,/Type) eq 7 

END 
