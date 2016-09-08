pro CPlotWin_YRange_Set_event, event

widget_control, event.top, get_uval=uval

self=*(uval.self_ptr)

widget_control, uval.wids.plot_ymin, get_value=ymin
widget_control, uval.wids.plot_ymax, get_value=ymax

ymin=float(ymin[0])
ymax=float(ymax[0])

self->SetYRange, [(ymin < ymax), (ymax > ymin)]

self->DrawPlot

end
