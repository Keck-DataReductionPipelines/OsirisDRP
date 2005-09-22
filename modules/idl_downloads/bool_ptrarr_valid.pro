;-----------------------------------------------------------------------
; NAME:  bool_ptrarr_valid
;
; PURPOSE: Check if input is a valid pointer array
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a valid pointer array, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_ptrarr_valid, In

   return, bool_is_ptrarr ( In ) ? ( ( total(ptr_valid(In)) eq size(In,/N_ELEMENTS) ) ? 1 : 0 ) : 0

END 
