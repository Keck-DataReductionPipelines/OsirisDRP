;-----------------------------------------------------------------------
; NAME:  data_valid
;
; PURPOSE: Check where data input is finite and not NAN
;
; INPUT :  In  : input 
;           n  : returns the number of finite and not-NAN elements in In
;
; OUTPUT : returns a variable with the same dimensions as In with elements equal
;          to 1 if input is valid/not valid, otherwise 0
;
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function data_valid, v, n

   dim = size(v)
   if ( dim(0) eq 0 ) then w=0 else w=indgen(dim(1:dim(0)))*0

   mask = where(finite(v),n)
   if ( n gt 0 ) then w(mask)=1

   return, w

end
