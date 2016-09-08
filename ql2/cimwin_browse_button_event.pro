; +
; NAME: cimwin_browse_button_event
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_conbase, [filename,] xwin
;
; INPUTS: 
;
; OPTIONAL INPUTS: filename is the path and filename of the file being
;                           displayed.    
;
; OPTIONAL KEYWORD INPUTS: /xwin is used to determine window backing.
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 16DEC2002 - MWM: added comments.
; - 

pro cimwin_browse_button_event, event

; provide pickfile for file selection
widget_control, event.top, get_uval=print_uval
widget_control, print_uval.base_id, get_uval=base_uval
filename=dialog_pickfile(path=print_uval.current_dir, $
                         group=event.id, filter='*.ps', /write)
widget_control, print_uval.fname_box, set_value=filename

end
