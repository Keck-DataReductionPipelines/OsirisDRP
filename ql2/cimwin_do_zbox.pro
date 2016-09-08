pro cimwin_do_zbox, base_id, select_val

widget_control, event.top, get_uval=uval

ImWinObj=*(uval.self_ptr)

if (event.select eq 1) then begin 
  ImWinObj->AddPntMode, 'zbox'
endif else begin
    ImWinObj->RmPntMode, 'zbox'
endelse

end

;widget_control, base_id, get_uval=uval

; get self object
;self=*uval.self_ptr

; make the appropriate changes to zoom box mode depending on select value
;uval.zbox_mode=select_val
;uval.draw_box=select_val
;if (select_val eq 1) then begin
;  uval.box_mode='zbox' 
;endif else begin
;    uval.box_mode=''
;    uval.redraw=0L
;endelse
;widget_control, base_id, set_uval=uval

;if (uval.draw_box eq 0) then begin
;  self->DrawImage
;;endif

;end
