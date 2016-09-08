; +
; NAME: ql_conoptions_control_event
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
; NOTES: ql_conoptions is listed below
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; - 

pro ql_conoptions_control_event, event

; get options base uvals
widget_control, event.top, get_uval=uval

;  gets the control base uval
widget_control, uval.wids.base_id, get_uval=base_uval
; get open in a new window designation from the options base
widget_control, uval.wids.newwin, get_value=newwin_value
; gets the make new window designation from the options base
widget_control, uval.wids.newwin_active, get_value=newwin_active_value
; gets the new window defaults from the options base
widget_control, uval.wids.newwin_defaults, get_value=newwin_defaults_value

; which button was pressed?
case event.value of
    'OK' : begin
        ; sets the control base new window user value
        base_uval.newwin=newwin_value
        ; sets the control base new window active user value
        base_uval.newwin_active=newwin_active_value
        ; sets the control base new window defaults value
        base_uval.newwin_defaults=newwin_defaults_value
    end
    'Apply' : begin
        ; sets the control base new window user value
        base_uval.newwin=newwin_value
        ; sets the control base new window active user value
        base_uval.newwin_active=newwin_active_value
        ; sets the control base new window defaults value
        base_uval.newwin_defaults=newwin_defaults_value
        ; updates the control base user values 
        widget_control, uval.wids.base_id, set_uval=base_uval
        return
    end
    else:
endcase

; will destroy the conoptions base next, so reset the window
; designation in the conbase user values to 0L
base_uval.exist.options=0L

; updates the control base user values 
widget_control, uval.wids.base_id, set_uval=base_uval

; destroys the options widget
widget_control, event.top, /destroy

end

; +
; NAME: ql_conoptions
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_conoptions, parentbase_id
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
; NOTES: creates the options widget.  the events are handled by 
;        ql_conoptions_control_event
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; - 

pro ql_conoptions, conbase_id

; get conbase uval
widget_control, conbase_id, get_uval=base_uval

; make an options widget
base=widget_base(/col, title='Options', group_leader=conbase_id, /tlb_kill_request_events)

; make a radio button group to determine whether to open images in a
; new window
newwin_toggle=cw_bgroup(base, ['No', 'Yes'], $
	label_left='Open New Images in a New Window?', $
        ; sets the current button value and sets the font from conbase
	set_value=base_uval.newwin, $
	font=base_uval.font, /exclusive, /row)

; make a radio button group to determine whether new windows are active
newwin_active_toggle=cw_bgroup(base, ['No', 'Yes'], $ 
	label_left='Make New Windows Active?', $
        ; sets window activity and sets the font from conbase
	set_value=base_uval.newwin_active, $
	font=base_uval.font, /exclusive, /row)

; make a radio button group to determine whether or not to use
; previous image parameters as the new defaults
newwin_defaults_toggle=cw_bgroup(base, ['No', 'Yes'], $ 
	label_left='Open New Images With Current Active Image Parameters?',$
        ; sets window activity and sets the font from conbase
	set_value=base_uval.newwin_defaults, $
	font=base_uval.font, /exclusive, /row)

; make a group of buttons to control widget exiting
control_buttons=cw_bgroup(base, ['OK', 'Apply', 'Cancel'], font=font, /row, $
                         /return_name)

; widget identification structure used in the control options function 
wids={base_id:conbase_id, newwin:newwin_toggle, $
	newwin_active:newwin_active_toggle, $
        newwin_defaults:newwin_defaults_toggle}

; user values structure used in the control options functions
uval={base_id:conbase_id, $
      wids:wids}

; realizes widget hierarchies, sets options base uval
widget_control, base, set_uval=uval, /realize

; registers ql_conoptions_control_event with the event handler
xmanager, 'ql_conoptions_base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'ql_conoptions_control', control_buttons, /just_reg, /no_block

; sets the control base options equal to the option base id, that way
; the base can be referred to from the control base
base_uval.exist.options=base

; updates the control base uval
widget_control, conbase_id, set_uval=base_uval

end

