pro ql_filename_box_event, event

; this module can be shared by other modules.  calling modules must have 
; a uval associated with event.top (the top level parent of the box) with
; the following members:
;	 wids.base_id : the widget_id of the conbase
;		inbox : 0 if cursor not in box, id of box if cursor is in box


if tag_names(event, /structure_name) eq 'WIDGET_TRACKING' then begin
	widget_control, event.top, get_uval=uval
	widget_control, uval.wids.base_id, get_uval=base_uval

	uval.inbox=(event.enter*event.id)

	if base_uval.got_handle ne 0 and uval.inbox ne 0 then $
		widget_control, uval.inbox, set_value=base_uval.dragged_text

	base_uval.got_handle=0L

	widget_control, uval.wids.base_id, set_uval=base_uval
	widget_control, event.top, set_uval=uval

endif

end

