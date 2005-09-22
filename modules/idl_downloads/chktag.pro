; Project     : SDAC
;
; Func Name   : CHKTAG
;
; Purpose     : Check for presence of a particular tag in a structure
;
; Explanation :
;
; Use         : check=chktag(stc,tag)
;
; Inputs      :
;               STC  = structure name
;               TAGS = tag name to check for;
; Opt. Inputs : None.
;
; Outputs     : 1 if present, 0 otherwise
;
; Opt. Outputs: None.
;
; Keywords    : RECUR = set to search recursively down nested structures
;
; Calls       : None.
;
; Common      : None.
;
; Restrictions: None.
;
; Side effects: None.
;
; Category    : 
;
; Prev. Hist. : None.
;
; Written     : DMZ (ARC) Oct 1993
;
; Modified    :
;
; Version     : 1.0
;-

function chktag,stc,tag,recur=recur

on_error,1

if (datatype(tag) ne 'STR') or (datatype(stc) ne 'STC') then begin
 message,'Usage ---> chk = chktag(structure,tag_name) ',/cont
 return,0b
endif
   
tags=tag_names(stc)
ntags=n_elements(tags)
look=where(strupcase(trim(tag)) eq tags,count)

if (count gt 0) then return,1b else begin
 if keyword_set(recur) then begin
  for i=0,ntags-1 do begin
   if (datatype(stc.(i)) eq 'STC') then begin
    if chktag(stc.(i),tag,recur=recur) then return,1b 
   endif
  endfor
 endif
endelse

return,0b
end
