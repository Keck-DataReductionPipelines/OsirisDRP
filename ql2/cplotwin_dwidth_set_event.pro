pro CPlotWin_DWidth_Set_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=imwin_uval

; get plot window object
self=*(uval.self_ptr)
imwin_self=*(imwin_uval.self_ptr)

cimwin=*imwin_uval.self_ptr
pmode=*imwin_uval.pmode_ptr

if (pmode[0].pointingmode eq 'diag') then begin
    ; remove the previous diagonal box if it exists
    if (imwin_uval.diag_pres eq 1) then begin
        imwin_self->RemoveDiagonalBox
    endif
endif

; get values
widget_control, uval.wids.data_dwidth, get_value=dwidth

; handle errors on user input (e.g. strings)
on_ioerror, dwidth_error
dwidth=fix(dwidth[0])
goto, no_dwidth_error
dwidth_error: dwidth=0
no_dwidth_error:

; set new diagonal width
imwin_self->SetDWidth, dwidth

if (pmode[0].pointingmode eq 'diag') then begin
    ; update the cimwin diagonal box
    self->UpdateImWinDiagonalBox
endif

; redraw plot
self->DrawPlot

end
