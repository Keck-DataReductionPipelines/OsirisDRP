pro cfitshedit_base_event, event
; base resize event handler.  adjust size of list

if (tag_names(event, /structure_name) eq 'WIDGET_BASE') then begin
    widget_control, event.top, get_uval=uval

      ; need to convert pixels to lines (for y) and chars for (x)
      ; widget_control, uval.wids.list, xsize=event.x
      ; widget_control, uval.wids.list, ysize=event.y

endif

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    widget_control, event.top, get_uval=uval
    widget_control, uval.base_id, get_uval=cimwin_uval    
    cimwin_uval.exist.fitshedit=0L
    widget_control, uval.base_id, set_uval=cimwin_uval
    widget_control, event.top, /destroy
endif


end
