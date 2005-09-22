;-----------------------------------------------------------------------
; NAME:  bool_is_struct
;
; PURPOSE: Check if input is a structure with n tags
;
; INPUT :  In    : input variable
;          [n=n] : number of tags
;
; OUTPUT : 1 if input is a structure (with n tags), otherwise 0
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_struct, In, n=n

   return, ( size(In,/Type) eq 8 ) ? $
              ( keyword_set(n) ? ( (n_tags(In) eq n) ? 1 : 0 ) : 1 ) : 0

END 
