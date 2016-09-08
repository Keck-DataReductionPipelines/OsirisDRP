pro cimwin_zbox_event, event

widget_control, event.top, get_uval=uval

ImWinObj=*(uval.self_ptr)

if (event.select eq 1) then begin 
  ImWinObj->AddPntMode, 'zbox'
endif else begin
    ImWinObj->RmPntMode, 'zbox'
endelse

end
