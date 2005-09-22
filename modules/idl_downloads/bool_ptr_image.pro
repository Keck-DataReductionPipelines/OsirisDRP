;-----------------------------------------------------------------------
; NAME:  bool_ptr_image
;
; PURPOSE: Check if input is a valid image pointer
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a pointer to a cube variable, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_ptr_image, In

   return, bool_ptr_valid ( In ) ? (bool_is_image ( *In ) ? 1 : 0 ) : 0

END 
