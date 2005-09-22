;-----------------------------------------------------------------------
; NAME:  bool_is_cube
;
; PURPOSE: Check if input is a cube
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a cube, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_cube, In

   return, bool_is_heap ( In, n=3 )

END 
