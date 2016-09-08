pro cimwin_recalcstat_button_event, event

widget_control, event.top, get_uval=stat_uval
widget_control, stat_uval.base_id, get_uval=imwin_uval

; get the self pointer
ImWin_ptr=imwin_uval.self_ptr
ImWinObj=*ImWin_ptr

; update the box fields even if they were not registered yet
ImWinObj->UpdateStatRange

; recalculate the box statistics
ImWinObj->CalcStat, stat_uval.base_id

pmode=*imwin_uval.pmode_ptr

; make statistics the new pointing mode
ImWinObj->AddPntMode, 'stat'

; redraw the box if one previously exists
if (pmode[0].pointingmode ne 'box') then begin
    if (imwin_uval.box_pres) then begin
        ImWinObj->DrawBoxParams
        ; get the imwin_uval again
        widget_control, stat_uval.base_id, get_uval=imwin_uval
        ImWinObj->Draw_Box, imwin_uval.draw_box_p0, imwin_uval.draw_box_p1
    endif
endif
 
end
