pro cimwin_cube_select_event, event

; get uval
widget_control, event.top, get_uval=uval

; which button was pressed?
widget_control, event.id, get_value=button_name

if button_name eq 'Range:' then begin
    ; unselect other button
    widget_control, uval.wids.cube_single_button, set_button=0
    ; disable slider, and the other base
    widget_control, uval.wids.cube_slider, sensitive=0
    widget_control, uval.wids.cube_slice_box_base, sensitive=0
    ; enable current base
    widget_control, uval.wids.cube_range_base, /sensitive
    ev=event
endif else begin                ; 'Single Slice'
    ; unselect other button
    widget_control, uval.wids.cube_range_button, set_button=0
    ; disable other base
    widget_control, uval.wids.cube_range_base, sensitive=0
    ; enable slider, other base
    widget_control, uval.wids.cube_slider, /sensitive
    widget_control, uval.wids.cube_slice_box_base, /sensitive

    ; create event to be sent to cimwin_cube_slice_event
    widget_control, uval.wids.cube_slider, get_value=slide_val
    ev={WIDGET_SLIDER, ID:uval.wids.cube_slider, TOP:event.top, $
        HANDLER:event.handler, VALUE:slide_val, DRAG:0}
endelse 

; send an event over to cimwin_cube_slice_event
widget_control, uval.wids.cube_slider, send_event=ev

end

