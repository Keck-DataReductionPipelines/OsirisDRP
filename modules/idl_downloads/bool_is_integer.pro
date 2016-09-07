;-----------------------------------------------------------------------
; NAME:  bool_is_integer
;
; PURPOSE: Check if input is integer
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is integer, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_integer, In

   i_Type = size(In, /TYPE)
   return, i_Type eq 2

END 
