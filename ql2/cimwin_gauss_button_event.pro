pro CImWin_Gauss_Button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval
self=*base_uval.self_ptr
; remove the gaussian pointing mode
; if the box exists then remove it
pmode=*base_uval.pmode_ptr
if (pmode[0].pointingmode eq 'box') then begin
    if (base_uval.box_pres) then self->RemoveBox
endif

; check to see if pan is the first element
if pmode[0].type eq 'pan' then begin
    ; check to see if a second pointing mode exists
    if (size(pmode, /n_elements) gt 1) then begin
        ; if the second element is a circle, remove it since it will be redrawn
        if pmode[1].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl' and (uval.circ_strehl_pres)) or $
                ((pmode[0].type eq 'phot' and (uval.circ_phot_pres)))) then begin
                self->DrawCircleParams
                self->RemoveCircle
            endif
        endif
        ; if stat is the second element, then erase the box since it won't be
        ; erased otherwise
        if (pmode[1].type eq 'peak fit') then begin
            if (base_uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, uval.wids.base_id, get_uval=base_uval
                self->Draw_Box, base_uval.draw_box_p0, base_uval.draw_box_p1
            endif
        endif
    endif
endif else begin    
    ; if the first element is a circle, remove it since it will be redrawn
    if (pmode[0].pointingmode eq 'aperture') then begin
        if ((pmode[0].type eq 'strehl' and (base_uval.circ_strehl_pres)) or $
            ((pmode[0].type eq 'phot' and (base_uval.circ_phot_pres)))) then begin
            self->RemoveCircle
        endif
    endif
endelse

self->RmPntMode, 'peak fit'

; draw the current pointing mode box/circle if present
self->DrawImageBox_n_Circles

widget_control, event.top, /destroy

end
