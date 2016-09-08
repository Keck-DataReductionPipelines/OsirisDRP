pro CPlotWin_Ydata_Set_event, event

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
widget_control, uval.wids.data_ymin, get_value=ymin
widget_control, uval.wids.data_ymax, get_value=ymax

; handle errors on user input (e.g. strings)
on_ioerror, ymin_error
ymin=fix(ymin[0])
goto, no_ymin_error
ymin_error: ymin=0
no_ymin_error:
on_ioerror, ymax_error
ymax=fix(ymax[0])
goto, no_ymax_error
ymax_error: ymax=0
no_ymax_error:

ymin_value=ymin < ymax
ymax_value=ymin > ymax

; make array of two values
y_newrange=[ymin_value, ymax_value]

; if the ranges are greater than the image size, then set the ranges
; equal to the size of the image
if (ymin_value lt 0) then ymin_value=0
if (ymax_value gt (imwin_self->GetDispIm_ys()-1)) then ymax_value=(imwin_self->GetDispIm_ys()-1)
y_newrange=[ymin_value, ymax_value]

; set new data range
self->SetYData_Range, y_newrange
; update the cimwin box
self->UpdateImWinBox

; reset field boxes
self->UpdateText

; if fix plot range button not pressed, set resetranges flag to 1
widget_control, uval.wids.data_y_fix_plot, get_value=fix_plot
self->SetResetRanges, (fix_plot[0] eq 0)

; redraw plot
self->DrawPlot

end
