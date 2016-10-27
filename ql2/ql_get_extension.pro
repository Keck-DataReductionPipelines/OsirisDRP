; +
; NAME: ql_get_extension
;
; PURPOSE: gets the extension at the end of a filename 
;
; CALLING SEQUENCE: ql_get_extension, filename
;
; INPUTS: 
;
; OPTIONAL INPUTS: filename is the path and filename of the file
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
; REVISION HISTORY: 19DEC2002 - MWM: added comments.
; - 

function ql_get_extension, filename

; get length of string
length_of_string = STRLEN(filename)
; find last '.'
dot_number = STRPOS(filename, '.', /REVERSE_SEARCH)
; if there is a dot
if dot_number ne -1 then $
  ; get everything after it
  new_string = STRMID(filename, dot_number+1, length_of_string) $
; otherwise return null string
else new_string=''

; returns the extension
return, new_string

end
