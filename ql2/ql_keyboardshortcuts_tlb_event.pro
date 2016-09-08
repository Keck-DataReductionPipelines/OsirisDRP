pro ql_keyboardshortcuts_tlb_event, event

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    widget_control, event.top, /destroy
endif

end
