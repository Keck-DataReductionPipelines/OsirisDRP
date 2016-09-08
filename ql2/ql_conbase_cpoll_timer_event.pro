pro ql_conbase_cpoll_timer_event, event

; get uval
widget_control, event.top, get_uval=uval

if (tag_names(event, /structure_name) eq "WIDGET_TIMER") then begin 
    
    cpolling_ptr=uval.cpolling_ptr
    cpolling_obj=*cpolling_ptr
    
    cpolling_obj->PollLoop
    
    polling_status=cpolling_obj->GetPollingStatus()
    dir_polling_status=cpolling_obj->GetDirectoryPollingStatus()
    
    if ((polling_status eq 1.) or (dir_polling_status eq 1.)) then begin
        ; reset timer to run loop again
        widget_control, event.id, timer=cpolling_obj->GetPollingRate()    
    endif
endif

end
