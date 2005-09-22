;-----------------------------------------------------------------------
; NAME:  bool_is_bool
;
; PURPOSE: Check if input is bool, that means that input contains
;          only 1 and 0
;
; INPUT :  In  : input variable
;
; OUTPUT : 1 if input is bool, 0 else
;
; STATUS : untested
;
; HISTORY : 2.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_bool, In

   n=0L & m=0L

   if ( NOT bool_is_heap ( In ) ) then return, 0
   if ( bool_contains_nan ( In ) ) then return, 0
   if ( bool_contains_inf ( In ) ) then return, 0

   dummy = where ( In eq 0, n )
   dummy = where ( In eq 1, m )

   return,  ( size(In, /N_ELEMENTS) eq long(n)+long(m) ) ? 1 : 0

END 
