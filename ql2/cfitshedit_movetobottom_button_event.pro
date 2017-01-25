pro cfitshedit_movetobottom_button_event, event
; move a line to the bottom of the list, just above END keyword

  ; get uval struct
  widget_control, event.top, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; get header
  hd=*(uval.hd_ptr)

  ; copy the selected line
  line=hd[uval.selected]
  ; make a new header, with line moved to bottom, just above END
  ; remember to remove line from original position
  new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:n_elements(hd)-2], $
                                    line, hd[n_elements(hd)-1]]
  ; set new header in uval
  ptr_free,uval.hd_ptr
  uval.hd_ptr=ptr_new(new_hd)

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; set selected line to where line was moved
  CFitsHedit->SetSelected, event.top, n_elements(hd)-2

  ; update list in view
  CFitsHedit->UpdateList, event.top

end
