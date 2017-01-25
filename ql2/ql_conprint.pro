;+
; NAME:
;
;   NS_PRINT_PLOT
;
; PURPOSE:
;
;   Provides interface for printing to a file or a printer.   
;
; CATEGORY:
;
;   Quicklook
;
; CALLING SEQUENCE:
;
;   ns_print_plot, ns_display_base_id
;
; INPUTS:
;
;   NS_DISPLAY_BASE_ID:  Widget ID of display base.
;
; OPTIONAL INPUTS:
;
;   None.
;
; KEYWORD PARAMETERS:
;
;   None.
;
; OUTPUTS:
;
;   None.
;
; OPTIONAL OUTPUTS:
;
;   None.
;
; COMMON BLOCKS:
;
;   None.
;
; SIDE EFFECTS:
;
;   Prints out image to printer.
;
; RESTRICTIONS:
;
;   Must be used with Quicklook
;
; PROCEDURE:
;
;   Setup GIU, handle events
;
; EXAMPLE:
;
;   ns_print_plot, ns_display_base_id
;
; MODIFICATION HISTORY:
;
;   Feb 8, 2000: Jason Weiss -- Added this header, commented.
;
;-

pro toggle_event, event

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

pro buttons_event, event

; get uval
widget_control, event.top, get_uval=uval
widget_control, uval.base_wid, get_uval=base_uval
widget_control, uval.pname_box, get_value=pname
widget_control, uval.fname_box, get_value=fname
valid_file='Yes'
; ok/cancel?
case event.value of
    0: begin
        case uval.type of
            'File': begin
                base_uval.ps_filename=fname[0] 
                valid_file=ns_writecheck(uval.base_wid, base_uval.ps_filename)
            end
            'Printer': base_uval.printer_name=pname[0]
       endcase
    end
    1: uval.type='Cancel'
endcase

; if error from ns_writecheck
if valid_file eq 'No' then begin
    answer=dialog_message(['File Cannot Be', 'Written To.'], /error, $
       dialog_parent=event.top)
endif else begin
    widget_control, uval.orient_id, get_value=orient
    base_uval.print_type=uval.type
    base_uval.print_orient=orient[0]
    widget_control, uval.base_wid, set_uval=base_uval
    widget_control, event.top, /destroy
    return
endelse

end

pro browse_button_event, event

; provide pickfile for file selection
widget_control, event.top, get_uval=uval
widget_control, uval.base_wid, get_uval=base_uval
filename=dialog_pickfile(path=base_uval.current_data_directory, $
                         group=event.id, filter='*.ps', /write)
widget_control, uval.fname_box, set_value=filename

end

pro ns_print_plot, ns_display_base_id

; get uval
widget_control, ns_display_base_id, get_uval=base_uval

; save old name
old_printer=base_uval.printer_name

; set up widgets
base=widget_base(/col, title='Print...', group_leader=ns_display_base_id)
two_base=widget_base(base, /row)
left_base=widget_base(two_base, /col)
right_base=widget_base(two_base, /col)
type_text=widget_label(left_base, Value='Print to:')
tnames=['File', 'Printer']
toggle=cw_bgroup(left_base, tnames, col=1, /exclusive, /return_name, $
   set_value=0)
spacer=widget_label(right_base, Value='Name')
file_base=widget_base(right_base, /row)
fname_box=cw_field(file_base, title='File Name:', value=base_uval.ps_filename)
browse_button=widget_button(file_base, value='Browse')
pname_box=cw_field(right_base, title='Printer Name:', value=base_uval.printer_name)
orient_names=['Portrait', 'Landscape']
orient=cw_bgroup(base, orient_names, set_value=base_uval.print_orient, /row, $
                /exclusive, /return_index)
bnames=['OK', 'CANCEL']
buttons=cw_bgroup(base, bnames, row=1)

; set uval
uval={pname_box:pname_box, $
      fname_box:fname_box, $
      orient_id:orient, $
      type:'File', $
      base_wid:ns_display_base_id}

;realize widgets
widget_control, base, /realize
widget_control, base, set_uval=uval
widget_control, pname_box, sensitive=0

xmanager, 'toggle', toggle, /just_reg
xmanager, 'buttons', buttons, /just_reg
xmanager, 'browse_button', browse_button, /just_reg
xmanager

end


; +
; NAME: ql_conprint_control_event
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_conprint_control_event, event
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
; NOTES: ql_conprint is listed below
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 30JAN2004 - MWM: original code written
; - 

pro ql_conprint_control_event, event

; get uval
widget_control, event.top, get_uval=uval
widget_control, uval.conbase_id, get_uval=conbase_uval
widget_control, uval.name, get_value=printer_name

; which button?
case event.value of
    0: begin  ; ok
        ; get name
        conbase_uval.printer_name=printer_name[0]
        widget_control, uval.conbase_id, set_uval=conbase_uval
        ql_conprint_exe, uval.conbase_id, conbase_uval.ps_printfile
        widget_control, event.top, /destroy
       end
    1: begin  ; cancel
        widget_control, event.top, /destroy
        return
       end
endcase

print, 'printing...'

end

; +
; NAME: ql_conprint
;
; PURPOSE: Provides interface for printing to a printer. 
;
; CALLING SEQUENCE: ql_conprint, parentbase_id
;
; INPUTS: conbase_id (long) - widget id of the control base
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
; NOTES: creates the printing widget.  the events are handled by
;        ql_conprint_control_event
; 
; PROCEDURES USED: Setup GUI, handle events
;
; REVISION HISTORY: 30JAN2004 - original code written
; - 

pro ql_conprint, conbase_id

; get conbase uval
widget_control, conbase_id, get_uval=base_uval

; make an options widget
base=widget_base(/col, title='Options', group_leader=conbase_id)

; save old name
old_printer=base_uval.printer_name

; create widgets
base=widget_base(/col, title='Print...', group_leader=conbase_id)
name=cw_field(base, title='Printer Name:', value=base_uval.printer_name)
bnames=['OK', 'CANCEL']
print_id=cw_bgroup(base, bnames, row=1)

; set up local uval
uval={name:name, $
      conbase_id:conbase_id}

; realize widget
widget_control, base, set_uval=uval, /realize
;widget_control, base, set_uval=uval

; register xmanager
xmanager, 'print_id', ql_conprint_control, /just_reg, /no_block

end
