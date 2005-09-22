;-----------------------------------------------------------------------
; NAME:  strg
;
; PURPOSE: Delete blanks from a variable that is converted to string
;
; INPUT :  s  : input variable
;
; OUTPUT : the string converted and blank deleted variable
;
; STATUS : tested
;
; HISTORY : 11.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function strg, s

   return, strtrim(string(s),2)

end
