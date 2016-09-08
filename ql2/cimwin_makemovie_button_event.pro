pro CImWin_MakeMovie_Button_event, event

widget_control, event.top, get_uval=movie_uval
widget_control, event.id, get_value=selection
widget_control, movie_uval.wids.base_id, get_uval=imwin_uval
ImWinObj=*(imwin_uval.self_ptr)

case selection of
    'Create Movie': begin
        ; check to see which IDL version is being used
        if (!version.release ge '6.1') then begin
            ImWinObj->CreateMovie
        endif else begin 
            message='Movies can only be made with IDL v6.1 and greater.'
            answer=dialog_message(message, dialog_parent=event.top, /error)
        endelse
    end
    'Close': begin
        ; remove the movie wid from the conbase
        widget_control, event.top, /destroy
    end
endcase

end
