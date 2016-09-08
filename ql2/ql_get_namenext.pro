; +
; NAME: ql_get_namenext
;
; PURPOSE: gets the extension at the end of a filename 
;
; CALLING SEQUENCE: ql_get_namenext, filename
;
; INPUTS: 
;
; OPTIONAL INPUTS: filename of the file, without the path
;       
;
; OPTIONAL KEYWORD INPUTS: 
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 04JAN2005 - MWM: added comments.
; - 

function ql_get_namenext, filename

; find last '.'
dot_number = STRPOS(filename, '.', /REVERSE_SEARCH)
; if there is a dot
if dot_number ne -1 then $
  ; get everything before it
  new_string = STRMID(filename, 0, dot_number) $
; otherwise return null string
else new_string=''

; returns the extension
return, new_string

end
