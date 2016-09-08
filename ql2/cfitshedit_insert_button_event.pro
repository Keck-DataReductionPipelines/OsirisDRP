pro cfitshedit_insert_button_event, event
; inserts a new line into header with a "blank" template
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval

CImWin_Obj=*(cimwin_uval.self_ptr)
CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())
  ; get header
  hd=*(uval.hd_ptr)

  ; make a new line template
  newline="KEYWORD = '                  ' /                               "
  ; add to header at selected location
  new_hd=[hd[0:uval.selected-1], newline, hd[uval.selected:*]]
  
  ; update header in uval
  ptr_free,uval.hd_ptr
  uval.hd_ptr=ptr_new(new_hd)

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; update selected position.  though it hasn't changed, do this anyway
  ; esp. for inserting a line above END
  CFitsHedit->SetSelected, event.top, uval.selected

  ; update list in view
  CFitsHedit->UpdateList, event.top

end
