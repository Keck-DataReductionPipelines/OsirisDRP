pro cfitshedit_line_set_button_event, event

; event handler for when set button is hit.  must get values from
; fields and update header

  ; get uval struct
  widget_control, event.top, get_uval=uval
  ; get value in Name field
  widget_control, uval.wids.name, get_value=newname
  ; get value in value field
  widget_control, uval.wids.value, get_value=newvalue
  ; get value in comment field
  widget_control, uval.wids.comment, get_value=newcomment

  widget_control, uval.base_id, get_uval=cimwin_uval
  
  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())
  
  ; make sure the current name is in capitals
  up_newname=strtrim(STRUPCASE(newname),2)

  ; set new values in uval
  uval.curname=up_newname
  uval.curvalue=newvalue
  uval.curcomment=newcomment
  ; get desired datatype
  uval.curdatatype=widget_info(uval.wids.datatype, /droplist_select)

  ; set uval
  widget_control, event.top, set_uval=uval

  ; if the keyword already exists in the header and is not equal
  ; to 'COMMENT' or 'HISTORY', then just edit the keyword values
  keyword_exist=CFitsHedit->CheckKeyword(event.top, up_newname)

  case keyword_exist of
      0: begin
          ; otherwise, update the line in the fits header
          ; update selected line in header with new values (stored in uval)
          CFitsHedit->UpdateLine, event.top
      end
      1: begin
          ; add a history line
          CFitsHedit->UpdateCommentLine, event.top, 'HISTORY'
      end
      2: begin
          ; add a comment line
          CFitsHedit->UpdateCommentLine, event.top, 'COMMENT'
      end
      3: begin
          print, 'editing existing line'
          ; edit existing line
          CFitsHedit->UpdateLine, event.top, keyword_exist=1
      end
      else:
  endcase

end
