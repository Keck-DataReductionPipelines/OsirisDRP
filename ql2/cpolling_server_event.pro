pro cpolling_server_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=base_uval

cpolling_ptr=base_uval.cpolling_ptr
cpolling_obj=*cpolling_ptr

cpolling_obj->PollServer

; reset timer to run loop again
widget_control, event.id, timer=0.5

end
