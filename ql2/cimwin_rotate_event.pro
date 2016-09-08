pro CImWin_Rotate_event, event

widget_control, event.top, get_uval=uval

widget_control, event.id, get_value=button_name
widget_control, uval.base_id, get_uval=base_uval

case button_name of
    'OK': begin
        widget_control, uval.rot, get_value=rot
        widget_control, uval.flip, get_value=flip
        self=*base_uval.self_ptr
        pmode=*base_uval.pmode_ptr
        ImObj_ptr=self->GetImObj()
        ImObj=*ImObj_ptr
        im_ptr=ImObj->GetData()
        im=*im_ptr
        naxis=self->GetNAxis()
        if (naxis eq 3) then begin
            case rot[0] of
                0: rot=0.
                1: rot=90.
                2: rot=180.
                3: rot=270.
            endcase
            ; unable to rotate 3 dimensional images
            ; print error message
            message=['Unable to rotate 3 dimensional images.',$
                     'Please rotate using the droplists on bottom control panel.']
            answer=dialog_message(message, dialog_parent=event.top, /error)
            return
            ; t3d, /reset, ROT=[rot, 0, 0]
            ; im=convert_coord(im[0], im[1], im[2], /t3d)
        endif else begin
            im=rotate(im, rot[0])
            ; if this is an unraveled cube, then remove the unraveled locations
            p_unraveled=self->GetUnravelLocations()
            if ptr_valid(p_unraveled) then ptr_free, p_unraveled
            if (flip[0] ne 0) then begin
                im=reverse(im, 1)
            endif
        endelse
        ; erase all the circles and boxes, and set the box_p0
        ; and box_p1 back to zero
        if (rot[0] ne 0) then begin
            ; if a box is already drawn, then remove it
            if pmode[0].pointingmode eq 'box' then begin
                if (base_uval.box_pres) then begin
                    if pmode[0].type eq 'zbox' then begin
                        if (size(pmode, /n_elements) gt 1) then begin
                            if pmode[1].pointingmode eq 'box' then begin
                                self->DrawImageBox_n_Circles                        
                            endif
                        endif
                    endif else begin
                        self->DrawImageBox_n_circles
                    endelse
                endif
            endif
            ; if a circle is already drawn, then remove it
            if pmode[0].pointingmode eq 'aperture' then begin
                if ((pmode[0].type eq 'strehl' and (base_uval.circ_strehl_pres)) or $
                     ((pmode[0].type eq 'phot' and (base_uval.circ_phot_pres)))) then begin
                    self->DrawCircleParams
                    self->RemoveCircle
                endif
            endif
            if pmode[0].pointingmode eq 'diag' then begin
            ; if a diagonal box already exists then erase it
                if (base_uval.diag_pres) then begin
                    self->Draw_Diagonal_Box, base_uval.draw_diagonal_box_p0, base_uval.draw_diagonal_box_p1
                endif
            endif
            ; set all the uval box/circle parameters back to zero
            base_uval.box_pres=0
            base_uval.circ_strehl_pres=0
            base_uval.circ_phot_pres=0
            base_uval.diag_pres=0
            base_uval.box_p0=[0,0]
            base_uval.box_p1=[0,0]
            base_uval.phot_circ_x=0
            base_uval.phot_circ_y=0
            base_uval.strehl_circ_x=0
            base_uval.strehl_circ_y=0
            base_uval.diagonal_box_p0=[0,0]
            base_uval.diagonal_box_p1=[0,0]

            widget_control, uval.base_id, set_uval=base_uval
        endif
	*im_ptr=im
	ImObj->SetData, im_ptr
        self->SetDispIm, im_ptr
        self->UpdateDispIm
        self->DrawImage
    end
    'Close': begin
        widget_control, event.top, /destroy 
    end
endcase

end
