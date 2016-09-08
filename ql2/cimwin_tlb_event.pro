pro cimwin_tlb_event, event

; get uval
widget_control, event.top, get_uval=uval
thisEvent=tag_names(event, /structure_name)

case thisEvent of
    'WIDGET_KILL_REQUEST': begin
        cimwin_close, event.top
    end
    else: begin
        ; find the new size of the window
        cimwin_resize_draw, event.top, event.x, event.y

        ; get uval again because parameters changed
        widget_control, event.top, get_uval=uval

        ; get self object
        self=*uval.self_ptr
        self->DrawImage
    end
endcase

end 

