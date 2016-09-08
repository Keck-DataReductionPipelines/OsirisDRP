pro cplotwin_yfix_plot_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

widget_control, event.id, get_value=yfix_selected

; yfix_selected eq 0 if fixed plot is not set
; yfix_selected eq 1 if fixed plot is set

self->SetYFixPRange, yfix_selected


end
