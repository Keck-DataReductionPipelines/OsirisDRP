pro ql_conbase_resize_event, event

; get uval
widget_control, event.top, get_uval=uval

; if the event is from the polling object, then proceed 
; accordingly
if (tag_names(event, /structu) eq "WIDGET_TIMER") then begin 

    cpolling_ptr=uval.cpolling_ptr
    cpolling_obj=*cpolling_ptr

    cpolling_obj->PollServer

    polling_status=cpolling_obj->GetPollingStatus()

    if (polling_status eq 1.) then begin
        ; reset timer to run loop again
        widget_control, event.id, timer=0.5    
    endif

endif else begin

; find the new size of the window
;widbase_xsize = event.x
;widbase_ysize = event.y

; save the new conbase draw window size in the uval
    uval.xs=event.x
    uval.ys=event.y
    
    widget_control, event.top, set_uval=uval

   ; resize the conbase draw window
    widget_control, uval.wids.draw, draw_xsize=uval.xs
    widget_control, uval.wids.draw, draw_ysize=uval.ys

endelse

end 
