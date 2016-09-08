pro CPlotWin_Gauss_Button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval
self=*base_uval.self_ptr
;base_uval.redraw=0L
;base_uval.draw_box=0
;base_uval.box_mode='none'
widget_control, uval.wids.base_id, set_uval=base_uval
widget_control, event.top, /destroy

self->DrawPlot
end
