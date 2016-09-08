;   2007-07-03  MDP: Fix multiple pointer leaks on startup.
;
pro cfitshedit_moveup_button_event, event
; move a line up, swapping it with the line above it

  ; get uval
  widget_control, event.top, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; get header
  hd=*(uval.hd_ptr)
  
  ; get selected line
  line=hd[uval.selected]
  ; move line above it to current position
  hd[uval.selected]=hd[uval.selected-1]
  ; move selected line to one position above
  hd[uval.selected-1]=line

  ; set header in uval
  ;;uval.hd_ptr=ptr_new(hd)
  *(uval.hd_ptr)=hd

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; update selected item to one above
  CFitsHedit->SetSelected, event.top, uval.selected-1 

  ; update list in view
  CFitsHedit->UpdateList, event.top

end
