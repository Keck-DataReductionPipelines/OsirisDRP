pro cimwin_collapse_list_event, event

widget_control, event.top, get_uval=cimwin_uval
select_index=widget_info(event.id, /droplist_select)
self=*cimwin_uval.self_ptr
widget_control, self->GetParentBaseId(), get_uval=conbase_uval

self=*(cimwin_uval.self_ptr)

old_collapse=self->GetCollapse()

if (old_collapse ne select_index) then begin 
    self->SetCollapse, select_index
;   self->ReopenImage
    self->UpdateDispIm
    self->DrawImage
endif

end
