;-----------------------------------------------------------------------
; NAME:  bool_is_heap
;
; PURPOSE: Check if input is a heap variable of dimension n
;
; INPUT :  In  : input variable
;           n  : dimension 
;
; OUTPUT : 1 if input is a heap variable of dim n, otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_heap, In, n=n

   return, ( size(In,/Type) ne 10 ) ? $
              ( keyword_set(n) ? ( (size(In))[0] eq n ? 1 : 0 ) : 1 ) : 0

END 
