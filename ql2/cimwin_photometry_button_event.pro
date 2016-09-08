pro CImWin_Photometry_Button_event, event

widget_control, event.top, get_uval=phot_uval
widget_control, phot_uval.wids.base_id, get_uval=imwin_uval
widget_control, event.id, get_value=selection

ImWinObj=*(imwin_uval.self_ptr)

case selection of
    'I+': begin
        if ImWinObj->GetPhotometryInnerAn() lt ImWinObj->GetPhotometryOuterAn() then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->RemoveCircle
            endif
            widget_control, phot_uval.wids.inner_id, get_val=phot_inner
            widget_control, phot_uval.wids.outer_id, get_val=phot_outer
            if ((phot_inner+1) lt phot_outer) then begin
                phot_inner=phot_inner+1
            endif
            ImWinObj->SetPhotometryInnerAn, phot_inner
            ImWinObj->UpdatePhotometryText
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    end
    'I-': begin
        if ImWinObj->GetPhotometryInnerAn() gt ImWinObj->GetPhotometryAper() then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->RemoveCircle
            endif
            widget_control, phot_uval.wids.inner_id, get_val=phot_inner
            phot_inner=phot_inner-1
            ImWinObj->SetPhotometryInnerAn, phot_inner
            ImWinObj->UpdatePhotometryText
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    end
    'O+': begin
        if (imwin_uval.circ_phot_pres) then begin
            ImWinObj->RemoveCircle
        endif
        widget_control, phot_uval.wids.outer_id, get_val=phot_outer
        phot_outer=phot_outer+1
        ImWinObj->SetPhotometryOuterAn, phot_outer
        ImWinObj->UpdatePhotometryText
        if (imwin_uval.circ_phot_pres) then begin
            ImWinObj->DrawCircleParams
            ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
        endif
    end
    'O-': begin
        if ImWinObj->GetPhotometryOuterAn() gt ImWinObj->GetPhotometryInnerAn() then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->RemoveCircle
            endif
            widget_control, phot_uval.wids.outer_id, get_val=phot_outer
            widget_control, phot_uval.wids.inner_id, get_val=phot_inner
            if ((phot_outer-1) gt phot_inner) then begin
                phot_outer=phot_outer-1
            endif
            ImWinObj->SetPhotometryOuterAn, phot_outer
            ImWinObj->UpdatePhotometryText
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    end
    'A+': begin
        if ImWinObj->GetPhotometryAper() lt ImWinObj->GetPhotometryInnerAn() then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->RemoveCircle
            endif
            widget_control, phot_uval.wids.aper_id, get_val=phot_aper
            phot_aper=phot_aper+1
            ImWinObj->SetPhotometryAper, phot_aper
            ImWinObj->UpdatePhotometryText
            if (imwin_uval.circ_phot_pres) then begin          
                ImWinObj->DrawCircleParams
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    end
    'A-': begin
        if ImWinObj->GetPhotometryAper() gt 1 then begin        
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->RemoveCircle
            endif
            widget_control, phot_uval.wids.aper_id, get_val=phot_aper
            phot_aper=phot_aper-1
            ImWinObj->SetPhotometryAper, phot_aper
            ImWinObj->UpdatePhotometryText
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    end
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
        ; redraw the photometry circle if one previously exists
        if (pmode[0].type ne 'phot') then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams, circ_type='phot'
                ; get the uval again
                widget_control, phot_uval.wids.base_id, get_uval=imwin_uval
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y, circ_type='phot'
            endif
        endif
        ; redraw the photometry circle if one previously exists
        if (pmode[0].type ne 'phot') then begin
            if (imwin_uval.circ_phot_pres) then begin
                ImWinObj->DrawCircleParams
                ; get the uval again
                widget_control, phot_uval.wids.base_id, get_uval=imwin_uval
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
        ImWinObj->AddPntMode, 'phot'
    end
    'Calculate': begin
        ImWinObj->CalcPhot
    end
    'Close': begin
        ; if there is a circle drawn, then remove it
        pmode=*imwin_uval.pmode_ptr
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
        ImWinObj->RmPntMode, 'phot'
        ; draw the current pointing mode box/circle if present
        ImWinObj->DrawImageBox_n_Circles
        widget_control, event.top, /destroy
    end
endcase

end
