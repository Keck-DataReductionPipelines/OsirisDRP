;-----------------------------------------------------------------------
; NAME:  bool_contains_neg
;
; PURPOSE: Checks if input contains negative values.
;
; INPUT  :  in          : input variable
;           mask        : an array containing indices where in is negative
;           [/SAMESIZE] : if set, mask has the same
;                                  dimensions as in with 1 where In is
;                                  negative and 1 where in is positive
;           [/POS]      : the same for checking if positive
;
; RETURN VALUE : 1 if input contains negative values, 0 else
;
; STATUS : not tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_contains_neg, in, mask, SAMESIZE = SAMESIZE, POS = POS

   if ( keyword_set( POS ) ) then mask1 = where ( in gt 0., n ) $
   else mask1 = where ( in lt 0., n )

   if ( keyword_set(SAMESIZE) ) then begin
      mask = in*0.
      if ( n gt 0 ) then mask(mask1) = 1
   endif else mask = mask1

   return, n gt 0 ? 1 : 0

end
