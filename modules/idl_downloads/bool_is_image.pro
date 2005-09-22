;-----------------------------------------------------------------------
; NAME:  bool_is_image
;
; PURPOSE: Check if input is an image
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is a image, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_image, In

   return, bool_is_heap ( In, n=2 )

END 
