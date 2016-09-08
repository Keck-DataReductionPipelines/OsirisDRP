pro CImWin_Strehl_Button_event, event

widget_control, event.top, get_uval=strehl_uval
widget_control, strehl_uval.wids.base_id, get_uval=imwin_uval
ImWinObj=*(imwin_uval.self_ptr)

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin

    ; if there is a circle drawn, then remove it
    pmode=*imwin_uval.pmode_ptr
    if (pmode[0].pointingmode eq 'aperture') then begin
        if ((pmode[0].type eq 'strehl' and (imwin_uval.circ_strehl_pres)) or $
            ((pmode[0].type eq 'phot' and (imwin_uval.circ_phot_pres)))) then begin
            ImWinObj->RemoveCircle
        endif
    endif
    ; if the first element is a box, remove it since it will be redrawn
    if (pmode[0].pointingmode eq 'box') then begin
        if (imwin_uval.box_pres) then ImWinObj->RemoveBox
    endif

    ImWinObj->RmPntMode, 'strehl'
    ; draw the current pointing mode box/circle if present
    ImWinObj->DrawImageBox_n_Circles        
    widget_control, event.top, /destroy
    return
endif

widget_control, event.id, get_value=selection

case selection of
    'Reactivate': begin
        pmode=*imwin_uval.pmode_ptr
        ; if a box is already drawn, then remove it
        if pmode[0].pointingmode eq 'box' then begin
            if (imwin_uval.box_pres) then begin
                if pmode[0].type eq 'zbox' then begin
                    if (size(pmode, /n_elements) gt 1) then begin
                        if pmode[1].pointingmode eq 'box' then begin
                            ImWinObj->DrawImageBox_n_Circles                        
                        endif
                    endif
                endif else begin
                        ImWinObj->DrawImageBox_n_circles
               endelse
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (imwin_uval.diag_pres) then begin
                ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
            endif
        endif
        ; if a phot circle is already drawn, then remove it
        if (pmode[0].type eq 'phot') then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams, circ_type='phot'
                ; get the uval again
                widget_control, strehl_uval.wids.base_id, get_uval=imwin_uval
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
        ; redraw the strehl circle if one previously exists
        if (pmode[0].type ne 'strehl') then begin
            if (imwin_uval.circ_strehl_pres) then begin
                ImWinObj->DrawCircleParams, circ_type='strehl'
                ; get the uval again
                widget_control, strehl_uval.wids.base_id, get_uval=imwin_uval
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y, circ_type='strehl'
            endif
        endif
        ImWinObj->AddPntMode, 'strehl'
    end
    'Calculate': begin
        ImWinObj->CalcStrehl
    end
    'Close': begin
        pmode=*imwin_uval.pmode_ptr
        ; if there is a strehl circle drawn, then remove it
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                    ; if the second element is a circle, then remove it
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (imwin_uval.circ_strehl_pres)) then begin
                        ImWinObj->DrawCircleParams, circ_type='strehl'
                        ImWinObj->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (imwin_uval.circ_phot_pres)) then begin
                        ImWinObj->DrawCircleParams, circ_type='phot'
                        ImWinObj->RemoveCircle, circ_type='phot'
                    endif
                endif
                    ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (imwin_uval.diag_pres) then begin
                        ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif         
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl' and (imwin_uval.circ_strehl_pres)) or $
                ((pmode[0].type eq 'phot' and (imwin_uval.circ_phot_pres)))) then begin
                ImWinObj->DrawCircleParams
                ImWinObj->RemoveCircle
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (imwin_uval.diag_pres) then begin
                ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
            endif
        endif
        ; if the first element is a box, remove it since it will be redrawn
        if (pmode[0].pointingmode eq 'box') then begin
            if (imwin_uval.box_pres) then ImWinObj->RemoveBox
        endif
        ImWinObj->RmPntMode, 'strehl'
        ; draw the current pointing mode box/circle if present
        ImWinObj->DrawImageBox_n_Circles
        widget_control, event.top, /destroy
    end
end

end
