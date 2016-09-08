pro CPlotWin_XLog_Set_event, event


widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

widget_control, event.id, get_value=xlog_selected

; xlog_selected eq 0 if log is not set
; xlog_selected eq 1 if log is set

self->SetXlog, xlog_selected
self->DrawPlot

end
