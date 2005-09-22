;-----------------------------------------------------------------------
; NAME:  bool_ptr_cube
;
; PURPOSE: Check if input is a valid cube pointer
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a valid cube pointer, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_ptr_cube, In

   return, bool_ptr_valid ( In ) ? (bool_is_cube ( *In ) ? 1 : 0 ) : 0

END 
