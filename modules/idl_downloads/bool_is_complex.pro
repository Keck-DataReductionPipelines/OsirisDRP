;-----------------------------------------------------------------------
; NAME:  bool_is_complex
;
; PURPOSE: Check if input is complex
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is complex, otherwise 0
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_complex, In

   i_Type = size(In, /TYPE)
   return, i_Type eq 6 or i_Type eq 9

END 
