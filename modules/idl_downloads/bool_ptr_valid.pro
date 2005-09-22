;-----------------------------------------------------------------------
; NAME:  bool_ptr_valid
;
; PURPOSE: Check if input is a valid pointer
;
; INPUT :  In     : input pointer
;          [/ARR] : check additionally if input is a valid pointer array 
;
; OUTPUT : 1 if true, otherwise 0 
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_ptr_valid, In, ARR=ARR
 
   ret_val =  bool_is_ptr ( In ) ? ( ( ptr_valid ( In ) eq 1 ) ? 1 : 0) : 0

   if ( keyword_set ( ARR ) ) then ret_val = ret_val or bool_ptrarr_valid ( In )

   return, ret_val

END 
