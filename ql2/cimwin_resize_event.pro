pro cimwin_resize_event, event

; get uval
widget_control, event.top, get_uval=uval

; find the new size of the window
widbase_xsize = event.x
widbase_ysize = event.y

cimwin_resize_draw, event.top, widbase_xsize, widbase_ysize

; get self object
self=*uval.self_ptr

self->DrawImage

end 

