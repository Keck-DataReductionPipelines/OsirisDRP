; +
; NAME: cimwin_print_buttons_event
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

pro cimwin_print_buttons_event, event

; get uval
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=base_uval
widget_control, uval.pname_box, get_value=pname_box
widget_control, uval.fname_box, get_value=fname_box
valid_file='Yes'

; get the image data
self=*base_uval.self_ptr
;ImObj_ptr=self.p_ImObj
;ImObj=*ImObj_ptr
;im_ptr=ImObj->GetData()
;im=*im_ptr
;hd_ptr=ImObj->GetHeader()
;hd=*hd_ptr
;filename=ImObj->GetFilename()

; ok/cancel?
case event.value of
    0: begin
        case uval.type of
            'File': begin
                base_uval.ps_filename=fname_box[0] 
                widget_control, uval.base_id, set_uval=base_uval
                valid_file=ql_writecheck(uval.base_id, base_uval.ps_filename)
                ; if error from ns_writecheck
                if valid_file eq 'No' then begin
                    answer=dialog_message(['File Cannot Be', 'Written To.'], $
                                          /error, dialog_parent=event.top)
                    return
                endif else begin
                    ; make a ps of the current image
                    ;cimwin_ps_current, uval.base_id, /print
                    self->PsCurrent, uval.base_id, /FILE, /write

                    ;widget_control, uval.orient_id, get_value=orient
                    ;base_uval.print_type=uval.type
                    ;base_uval.print_orient=orient[0]
                    ;widget_control, uval.base_id, set_uval=base_uval
                    
                    
                    ;set_plot, 'ps'
                    ;device, filename=base_uval.ps_printfile
                    ;device, landscape=base_uval.print_orient
  
                    endelse

            end
            'Printer': begin
                base_uval.printer_name=pname_box[0]
                widget_control, uval.base_id, set_uval=base_uval
                self->PsCurrent, uval.base_id, /FILE, /print
            end
       endcase
    end
    1: uval.type='Cancel'
endcase

widget_control, event.top, /destroy

end
