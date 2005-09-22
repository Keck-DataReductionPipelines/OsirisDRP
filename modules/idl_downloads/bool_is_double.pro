;-----------------------------------------------------------------------
; NAME:  bool_is_double
;
; PURPOSE: Check if input is double
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is double, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_double, In

   i_Type = size(In, /TYPE)
   return, i_Type eq 5

END 
