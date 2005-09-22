;-----------------------------------------------------------------------
; NAME:  bool_is_vector
;
; PURPOSE: Check if input is a vector
;
; INPUT :  In      : input variable
;          LEN=LEN : length of vector
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

FUNCTION bool_is_vector, In, LEN=LEN

   if ( keyword_set ( LEN ) ) then begin
      if ( bool_is_heap ( In, n=1 ) ) then begin
         if ( n_elements( In ) eq LEN ) then begin
            return, 1
         endif else return, 0
      endif else return, 0
   endif else return, bool_is_heap ( In, n=1 )

END 
