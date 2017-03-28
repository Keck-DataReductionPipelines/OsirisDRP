pro CPlotWin_XRange_Set_event, event

widget_control, event.top, get_uval=uval

self=*(uval.self_ptr)

widget_control, uval.wids.plot_xmin, get_value=xmin
widget_control, uval.wids.plot_xmax, get_value=xmax

xmin=float(xmin[0])
xmax=float(xmax[0])

xdata_range=self->GetPlottedRange()

; verify the data range is within the limits
xmin=xdata_range[0] > xmin
xmax=xdata_range[1] < xmax

self->SetXRange, [(xmin < xmax), (xmax > xmin)]

self->DrawPlot

end
