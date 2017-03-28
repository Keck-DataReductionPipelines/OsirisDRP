; +
; NAME: ql_conupdate_recent_file_list
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_conupdate_recent_file_list, conbase_id, filename
;
; INPUTS: conbase_id (long) - id of the control base 
;         filename (string) - path of the file to be opened
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS: 
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; - 

pro ql_conupdate_recent_file_list, conbase_id, filename, nfiles

; get conbase uval
widget_control, conbase_id, get_uval=uval

; shifts the recent file list array one space to the right
uval.recent_file_list=shift(uval.recent_file_list, 1)

; makes the first element in the recent file list the new filename
uval.recent_file_list[0]=filename

if arg_present(nfiles) then nfiles=nfiles else nfiles=3

; keeps the last 3 recent files in the recent file list
for i=0, nfiles do begin
        ; makes the menu unsensitive if there is no filename in the element
	if uval.recent_file_list[i] eq 'None' then sens=0 else sens=1
        ; updates the menu selections with the filenames
	widget_control, uval.wids.menu+uval.recent_file_index+i, $
		sensitive=sens, set_value=uval.recent_file_list[i] 
endfor

; sets conbase uval
widget_control, conbase_id, set_uval=uval

end
