pro CPlotWin_YLog_Set_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

widget_control, event.id, get_value=ylog_selected

; ylog_selected eq 0 if log is not set
; ylog_selected eq 1 if log is set

self->SetYlog, ylog_selected
self->DrawPlot

end
