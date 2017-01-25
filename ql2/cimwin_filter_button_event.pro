pro CImWin_Filter_Button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval
self=*base_uval.self_ptr

widget_control, event.top, /destroy
base_uval.exist.filter=0L
widget_control, uval.wids.base_id, set_uval=base_uval
self->DrawImage

end
