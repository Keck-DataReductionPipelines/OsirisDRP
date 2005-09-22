;----------------------------------------------------------------------------
; NAME:  get_kwd
;
; PURPOSE: get a keyword from a pointer to a header
;
; INPUT : p_Header       : pointer or pointer array with the headers
;         n_Sets         : (integer) number of valid headers in pointerarray
;         s_Kwd          : (string) name of the keyword
;         [/NOCONTINUE]  : if a keyword occurs more than once, stop
;                          after first encounter
;
; OUTPUT : returns the values of a keyword as a vector
;
; ON ERROR : returns ERR_UNKNOWN 
;
; STATUS : untested
;
; HISTORY : 18.10.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------
function get_kwd, p_Header, n_Sets, s_Kwd, NOCONTINUE=NOCONTINUE

   vb = sxpar ( *p_Header(0), s_Kwd, NOCONTINUE=keyword_set(NOCONTINUE), count=n )
   if ( n ne 1 ) then $
      return, error ('FAILURE (get_kwd.pro): Keyword '+strg(s_Kwd)+' not found or multiply defined.') $
   else vb = [vb]

   for i=1, n_Sets-1 do begin
      Kwd = sxpar ( *p_Header(i), s_Kwd, NOCONTINUE=keyword_set(NOCONTINUE), count=n )
      if ( n ne 1 ) then $
         return, error ('FAILURE (get_kwd.pro): Keyword '+strg(s_Kwd)+' not found or multiply defined.') $ 
      else vb = [vb,Kwd]
   end

   return, vb

end

