; +
; NAME: cimwin_print_toggle_event
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

pro cimwin_print_toggle_event, event

;get uval
widget_control, event.top, get_uval=uval

uval.type=event.value

; where are we printing?
case uval.type of
    'File': begin
        widget_control, uval.fname_box, sensitive=1
        widget_control, uval.pname_box, sensitive=0
        end
    'Printer': begin
        widget_control, uval.fname_box, sensitive=0
        widget_control, uval.pname_box, sensitive=1
        end
endcase

widget_control, event.top, set_uval=uval

end
