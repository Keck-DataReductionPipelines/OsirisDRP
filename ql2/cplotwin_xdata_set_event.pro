pro CPlotWin_XData_Set_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

; remove the previous box if it exists
if (((imwin_uval.box_p0[0] ne 0) and (imwin_uval.box_p0[1] ne 0)) or $
    ((imwin_uval.box_p1[0] ne 0) and (imwin_uval.box_p1[1] ne 0))) then begin
    imwin_self->RemoveBox
endif

; get values
widget_control, uval.wids.data_xmin, get_value=xmin
widget_control, uval.wids.data_xmax, get_value=xmax

; handle errors on user input (e.g. strings)
on_ioerror, xmin_error
xmin=fix(xmin[0])
goto, no_xmin_error
xmin_error: xmin=0
no_xmin_error:
on_ioerror, xmax_error
xmax=fix(xmax[0])
goto, no_xmax_error
xmax_error: xmax=0
no_xmax_error:

xmin_value=xmin < xmax
xmax_value=xmin > xmax

; make array of two values
x_newrange=[xmin_value, xmax_value]

; if the ranges are greater than the image size, then set the ranges
; equal to the size of the image
if (xmin_value lt 0) then xmin_value=0
if (xmax_value gt (imwin_self->GetDispIm_xs()-1)) then xmax_value=(imwin_self->GetDispIm_xs()-1)
x_newrange=[xmin_value, xmax_value]

; reset field boxes
widget_control, uval.wids.data_xmin, set_value=x_newrange[0]
widget_control, uval.wids.data_xmax, set_value=x_newrange[1]

; set new data range
self->SetXData_Range, x_newrange
; update the cimwin box
self->UpdateImWinBox

; if fix plot range button not pressed, set resetranges flag to 1
widget_control, uval.wids.data_x_fix_plot, get_value=fix_plot
self->SetResetRanges, (fix_plot[0] eq 0)

; redraw plot
self->DrawPlot

end
