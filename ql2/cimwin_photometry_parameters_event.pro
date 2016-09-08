pro cimwin_photometry_parameters_event, event

; event when user enters values in a field

widget_control, event.top, get_uval=photbase_uval
widget_control, photbase_uval.base_id, get_uval=imwin_uval

pmode=*imwin_uval.pmode_ptr
ImWinObj=*(imwin_uval.self_ptr)

; get old values
oldzmag=ImWinObj->GetDef_Zmag()
olditime=ImWinObj->GetDefItime()
oldaper=ImWinObj->GetPhotometryAper()
oldinner=ImWinObj->GetPhotometryInnerAn()
oldouter=ImWinObj->GetPhotometryOuterAn()

; get new values
widget_control, photbase_uval.wids.zmag_id, get_val=def_zmag
widget_control, photbase_uval.wids.itime_id, get_val=def_itime
widget_control, photbase_uval.wids.inner_id, get_val=phot_inner
widget_control, photbase_uval.wids.outer_id, get_val=phot_outer
widget_control, photbase_uval.wids.aper_id, get_val=phot_aper

; check to make sure there's no errors

; remove the old circle
ImWinObj->RemoveCircle

; set the imwin member variables to the new values
ImWinObj->SetDef_Zmag, def_zmag
ImWinObj->SetDefItime, def_itime
ImWinObj->SetPhotometryAper, phot_aper

fphot_inner=float(phot_inner)
fphot_outer=float(phot_outer)

; make sure the inner photometry annulus is inside the outer one
; otherwise, ql_aper will fail and not be happy
if (fphot_inner ge fphot_outer) then begin
    phot_inner=strtrim(fphot_outer-1,2)
    widget_control, photbase_uval.wids.inner_id, set_val=phot_inner
endif

ImWinObj->SetPhotometryInnerAn, phot_inner
ImWinObj->SetPhotometryOuterAn, phot_outer

; update the text in the widget
ImWinObj->UpdatePhotometryText

; if in photometry mode, then redraw the circle
if (pmode[0].type eq 'phot') then begin 
    ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
endif else begin
    if (pmode[0].type eq 'pan') then begin
        if (size(pmode, /n_elements) gt 1) then begin
            if (pmode[1].type eq 'phot') then begin 
                ImWinObj->DrawCircle, imwin_uval.draw_circ_x, imwin_uval.draw_circ_y
            endif
        endif
    endif
endelse

end
