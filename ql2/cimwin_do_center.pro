pro cimwin_do_center, base_id, select_val

widget_control, base_id, get_uval=uval

; get self object
self=*uval.self_ptr

; make the appropriate changes to pan box mode depending on select value
uval.pan_mode=select_val

; check to see if a box mode is on.  if so, undo it and erase the
; drawn box
;if (uval.draw_box eq 1) then begin 
;    uval.draw_box=0
;    widget_control, event.top, set_uval=uval
;    self->DrawImage
;endif


widget_control, base_id, set_uval=uval

end
