pro CImWin_Dim_List_event, event

widget_control, event.top, get_uval=uval
self=*uval.self_ptr
pmode=*uval.pmode_ptr

; the next few lines find which items are selected
list_ids=[uval.wids.xdim_list, uval.wids.ydim_list]
dims=[0, 1, 2]
other_list=(list_ids[where(list_ids ne event.id)])[0]
other_select=widget_info(other_list, /droplist_select)

; if both lists are the same, set the other to
; the first available selection
avail_dim=where(dims ne event.index)
if event.index eq other_select then begin 
	widget_control, other_list, set_droplist_select=avail_dim[0]
endif

; get last dim available for third axis
last_dim=avail_dim(where(avail_dim ne $
	widget_info(other_list, /droplist_select)))

; update AxesOrder
self=*uval.self_ptr
self->SetAxesOrder, [widget_info(list_ids[0], /droplist_select), $
	widget_info(list_ids[1], /droplist_select), $
	last_dim[0]]

; if a box is already drawn, then remove it
if pmode[0].pointingmode eq 'box' then begin
    if (uval.box_pres) then begin
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
    if ((uval.circ_strehl_pres) or (uval.circ_phot_pres)) then begin
        self->DrawCircleParams
        self->RemoveCircle
    endif
endif

; set all the uval box/circle parameters back to zero
uval.box_pres=0
uval.circ_strehl_pres=0
uval.circ_phot_pres=0
uval.diag_pres=0
uval.box_p0=[0,0]
uval.box_p1=[0,0]
uval.phot_circ_x=0
uval.phot_circ_y=0
uval.strehl_circ_x=0
uval.strehl_circ_y=0
uval.diagonal_box_p0=[0,0]
uval.diagonal_box_p1=[0,0]
widget_control, event.top, set_uval=uval

; reset Zmin and Zmax
self->SetResetZ, 1
self->UpdateDispIm

end
