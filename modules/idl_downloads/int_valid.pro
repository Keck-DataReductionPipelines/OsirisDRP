;-----------------------------------------------------------------------
; NAME:  int_valid
;
; PURPOSE: Check where input is gt d_Min (see code)
;
; INPUT :  In  : input variable
;           n  : returns the number of valid elements in In
;  [MINV=MINV] : minimum value, default 1.d-10
;      [/NOVAL]: the same for the condition le MIN, that means not
;                valid elements 
;   [/ABSOLUT] : checked against the absolute value
;
; OUTPUT : returns an array of same length as In with elements equal
;          to 1 if input is valid/not valid, otherwise 0
;
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
; jlyke 2016 apr 04 chg d_Min to 1.d-20
; jlyke 2016 apr 06 chg d_Min to -1.d-20 to allow 0.0 values
;-----------------------------------------------------------------------

function int_valid, v, n, NOVAL=NOVAL, MINV=MINV, ABSOLUT=ABSOLUT

   ; intframe values must be greater/less than d_Min
   if ( keyword_set ( MINV ) ) then d_Min = MINV else d_Min = -1.d-20

   if ( keyword_set ( ABSOLUT ) ) then v = abs(v)

   dim = size(v)
   if ( dim(0) eq 0 ) then w=0 else w=intarr(dim(1:dim(0)))

   if ( keyword_set(NOVAL) ) then begin 
      mask = where(double(v) le d_Min,n)
      if ( n gt 0 ) then w(mask)=1
   endif else begin
      mask = where(double(v) gt d_Min,n)
      if ( n gt 0 ) then w(mask)=1
   end

   return, w

end
