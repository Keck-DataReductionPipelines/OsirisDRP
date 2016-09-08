pro cfitshedit_movedown_button_event, event
; move a line down one, swapping it with the line below

  ; get uval struct
  widget_control, event.top, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; get header
  hd=*(uval.hd_ptr)
  
  ; get selected line
  line=hd[uval.selected]
  ; move line below it to current position
  hd[uval.selected]=hd[uval.selected+1]
  ; move selected line to one position below
  hd[uval.selected+1]=line

  ; update header in uval
  ptr_free, uval.hd_ptr
  uval.hd_ptr=ptr_new(hd)

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; update selected item to one below
  CFitsHedit->SetSelected, event.top, uval.selected+1 

  ; update list in view
  CFitsHedit->UpdateList, event.top
end
