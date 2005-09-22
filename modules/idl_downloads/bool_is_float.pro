;-----------------------------------------------------------------------
; NAME:  bool_is_float
;
; PURPOSE: Check if input is float
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is float, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_float, In

   i_Type = size(In, /TYPE)
   return, i_Type eq 4 

END 
