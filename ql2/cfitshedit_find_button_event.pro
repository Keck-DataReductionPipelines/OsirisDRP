pro cfitshedit_find_button_event, event

; get uval struct
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval  
CImWin_Obj=*(cimwin_uval.self_ptr)
CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

; get value in Name field
widget_control, uval.wids.find_field, get_value=find_keyword

; make sure the current name is in capitals
up_find_keyword=strtrim(STRUPCASE(find_keyword),2)

; find where the keyword exists in the header 
keyword_exist=CFitsHedit->CheckKeyword(event.top, up_find_keyword)

case keyword_exist of 
    1: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    2: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    3: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    else: begin
        message=['The keyword '+up_find_keyword+' does not exist in this header.']
        answer=dialog_message(message, dialog_parent=event.top, /error)
    end
endcase


;if (keyword_exist eq 3) then begin
;    widget_control, event.top, get_uval=uval
;    index=LONG(uval.keyword_exist_index)
;    CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
;    CFitsHedit->UpdateList, event.top
;endif else begin
;    message=['The keyword '+up_find_keyword+' does not exist in this header.']
;    answer=dialog_message(message, dialog_parent=event.top, /error)
;endelse

end
