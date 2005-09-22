;-----------------------------------------------------------------------
; NAME:  bool_dim_match
;
; PURPOSE: Checks if the two inputs have the same dimensions. 
;          Note that ptrarr(10) and findgen(10) have the same dimension
;
; INPUT :  In1 : input 1
;          In2 : input 2
;
; OUTPUT : 1 if dimensions match, otherwise 0
;
; STATUS : not tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_dim_match, In1, In2

   s1 = size(In1) & s2 = size(In2)

   return, array_equal(s1(0:s1(0)),s2(0:s2(0)) )

end

