;-----------------------------------------------------------------------
; NAME:  bool_is_ptrarr
;
; PURPOSE: Check if input is a pointer array
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a pointer array, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_ptrarr, In

   return, ( size(In,/TYPE) eq 10 ) ? (size(In,/N_DIMENSIONS) eq 1 ? 1 : 0 ) : 0

END 
