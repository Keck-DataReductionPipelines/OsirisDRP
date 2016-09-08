pro cimwin_strehl_parameters_event, event

; event when user enters values in a field

widget_control, event.top, get_uval=strehlbase_uval
widget_control, strehlbase_uval.base_id, get_uval=imwin_uval

pmode=*imwin_uval.pmode_ptr
ImWinObj=*(imwin_uval.self_ptr)

; get old values
oldapsize=ImWinObj->GetStrehlApSize()

; get new values
widget_control, strehlbase_uval.wids.ap_size, get_val=ap_size

; remove the old circle
ImWinObj->RemoveCircle

; set the imwin member variables to the new values
ImWinObj->SetStrehlApSize, ap_size

; update the text in the widget
ImWinObj->UpdateStrehlText

; if in strehl mode, then redraw the circle
if (pmode[0].type eq 'strehl') then begin 
    ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
endif else begin
    if (pmode[0].type eq 'pan') then begin
        if (size(pmode, /n_elements) gt 1) then begin
            if (pmode[1].type eq 'strehl') then begin 
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    endif
endelse

end

