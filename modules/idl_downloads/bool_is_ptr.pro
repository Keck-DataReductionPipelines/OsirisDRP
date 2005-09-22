;-----------------------------------------------------------------------
; NAME:  bool_is_ptr
;
; PURPOSE: Check if input is a pointer
;
; INPUT :  In  : input 
;
; OUTPUT : 1 if input is a pointer, otherwise 0
;
; STATUS : tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_ptr, In

   return, (size ( In, /type ) eq 10 ) ? ( (size ( IN, /N_DIMENSIONS ) eq 0) ? 1 : 0 ) : 0

END 
