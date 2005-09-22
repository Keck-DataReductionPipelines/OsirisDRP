;-----------------------------------------------------------------------
; NAME:  bool_is_byte
;
; PURPOSE: Check if input is byte
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is byte, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_byte, In

   i_Type = size(In, /TYPE)
   return, i_Type eq 1

END 
