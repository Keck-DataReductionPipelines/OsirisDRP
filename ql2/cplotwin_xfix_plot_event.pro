pro cplotwin_xfix_plot_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

widget_control, event.id, get_value=xfix_selected

; xfix_selected eq 0 if fixed plot is not set
; xfix_selected eq 1 if fixed plot is set

self->SetXFixPRange, xfix_selected


end
