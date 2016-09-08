pro CImWin_Photometry_Base_event, event

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    widget_control, event.top, get_uval=phot_uval
    widget_control, phot_uval.wids.base_id, get_uval=imwin_uval
    ImWinObj=*(imwin_uval.self_ptr)
    ImWinObj->RmPntMode, 'phot'
        ; if there is a circle drawn, then remove it
    if ((imwin_uval.phot_circ_x ne 0) and (imwin_uval.phot_circ_y ne 0)) then $
      ImWinObj->RemoveCircle
        ; draw the current pointing mode box/circle if present
    ImWinObj->DrawImageBox_n_Circles
    widget_control, event.top, /destroy
endif

end
