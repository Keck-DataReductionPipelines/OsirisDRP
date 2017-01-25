pro CImWin_Stretch_Button_event, event

structure_name=tag_names(event, /structure_name)

update=0
if (structure_name eq 'WIDGET_BUTTON') then update=1 else $
if (structure_name eq 'WIDGET_TEXT_CH') then update=(event.ch eq 10)

if update then begin

    widget_control, event.top, get_uval=uval

; get values
    widget_control, uval.wids.stretch_min, get_value=min
    widget_control, uval.wids.stretch_max, get_value=max

; get self object
    self=*uval.self_ptr

; set min and max values
    self->SetDispMin, min
    self->SetDispMax, max

; redraw image
self->DrawImage

endif

end
