; +
; NAME: ql_file_browse_event
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_conoptions_control_event, event
;
; INPUTS: event (struct) - 
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
; NOTES: this module can be used by other modules to handle events for 
; hitting a browse button next to a filename cw_field.  Selection of a
; file from the pick file prints the name of the file selected in the
; text area of the cw_field adjacent to it.  NOTE: cw_field must
; exactly precede the browse button that calls this routine. 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 19DEC2002 - MWM: added comments.
; - 

pro ql_file_browse_event, event

; get conbase uval
widget_control, event.top, get_uval=uval

if (tag_exist(uval, 'path') eq 1) then path=uval.path else path='.' 

filename=dialog_pickfile(dialog_parent=event.id, filter='*.fits', $
	path=path, get_path=newpath, /read, /must_exist)

if filename ne '' then begin
	if (tag_exist(uval, 'path') eq 1) then $
		uval.path=newpath
	widget_control, event.id-3, set_value=filename
endif

; update conbase uval
widget_control, event.top, set_uval=uval

end
