pro CImWin_Independent_Zoom_event, event

; get setting of button
widget_control, event.handler, get_value=set
widget_control, event.top, get_uval=uval

; set value in uval
uval.independent_zoom=set[0]

widget_control, event.top, set_uval=uval


end
