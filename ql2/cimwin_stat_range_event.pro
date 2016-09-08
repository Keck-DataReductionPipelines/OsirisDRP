pro cimwin_stat_range_event, event

structure_name=tag_names(event, /structure_name)

update=0
if (structure_name eq 'WIDGET_BUTTON') then update=1 else $
if (structure_name eq 'WIDGET_TEXT_CH') then update=(event.ch eq 10)

if update then begin

    widget_control, event.top, get_uval=uval
    ; get the cimwin uval
    widget_control, uval.base_id, get_uval=cimwin_uval
    self=*(cimwin_uval.self_ptr)
    self->UpdateStatRange

endif

end
