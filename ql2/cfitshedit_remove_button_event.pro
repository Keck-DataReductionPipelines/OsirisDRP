
pro cfitshedit_remove_button_event, event
; remove a line from the list

  ; get uval struct
  widget_control, event.top, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; get header
  hd=*(uval.hd_ptr)
  
  ; remove line from list
  new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:*]]
  
  ; update header in uval
  *(uval.hd_ptr)=new_hd

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; update selected position.  though it hasn't changed, do this anyway
  ; esp. for removing a line below reserved keywords
  CFitsHedit->SetSelected, event.top, uval.selected

  ; update list in view
  CFitsHedit->UpdateList, event.top

end
