pro cfitshedit_header_list_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval

CImWin_Obj=*(cimwin_uval.self_ptr)
CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

; for a click in the list, set new selected item, and update
; corresponding fields

; set selected item in uval
CFitsHedit->SetSelected, event.top, event.index

; update the fields in view with info from selected item
CFitsHedit->UpdateFields, event.top

end
