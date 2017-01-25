pro cimwin_rotate_tlb_event, event

; get uval
widget_control, event.top, get_uval=uval

; if the event is from the polling object, then proceed 
; accordingly
if (tag_names(event, /structure_name) eq "WIDGET_KILL_REQUEST") then begin
    widget_control, event.top, /destroy
    return
endif 

end 
