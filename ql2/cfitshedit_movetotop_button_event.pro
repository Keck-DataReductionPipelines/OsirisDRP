;   2007-07-03  MDP: Fix multiple pointer leaks on startup.
pro cfitshedit_movetotop_button_event, event
; move a line to top of list, just below reserved keywords

  ; get uval structure
  widget_control, event.top, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; get header
  hd=*(uval.hd_ptr)

  ; copy selected line
  line=hd[uval.selected]
  ; form a new header, with line moved to top, after reserved keywords.
  ; remember to remove line from its original position
  new_hd=[hd[0:uval.num_reserved-1], line, $
          hd[uval.num_reserved:uval.selected-1], hd[uval.selected+1:*]]

  ; set new header in uval
  ptr_free,uval.hd_ptr
  uval.hd_ptr=ptr_new(new_hd)

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; set new selected line position to where line was moved
  CFitsHedit->SetSelected, event.top, uval.num_reserved 

  ; update list in view
  CFitsHedit->UpdateList, event.top

end
