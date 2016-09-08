pro cplotwin_recalcgauss_button_event, event

widget_control, event.top, get_uval=gauss_uval
widget_control, gauss_uval.base_id, get_uval=plotwin_uval

; get the self pointer
PlotWinObj=*(plotwin_uval.self_ptr)

; recalculate the gaussian fit
PlotWinObj->CalcGauss, event.top

end
