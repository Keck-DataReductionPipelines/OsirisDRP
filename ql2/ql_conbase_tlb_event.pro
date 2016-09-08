pro ql_conbase_tlb_event, event

; get uval
widget_control, event.top, get_uval=uval

; if the event is from the polling object, then proceed 
; accordingly
if (tag_names(event, /structure_name) eq "WIDGET_KILL_REQUEST") then begin
    ql_conquit, event.top
endif else begin
    ; save the new conbase draw window size in the uval
    uval.xs=event.x
    uval.ys=event.y
    widget_control, event.top, set_uval=uval

    ; resize the conbase draw window
    widget_control, uval.wids.draw, draw_xsize=uval.xs
    widget_control, uval.wids.draw, draw_ysize=uval.ys
endelse

end 
