pro CImWin_Shift_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=base_uval

widget_control, event.id, get_value=button_name

if button_name eq 'OK' then begin
	widget_control, uval.xshift, get_value=xshift
	widget_control, uval.yshift, get_value=yshift
	self=*base_uval.self_ptr
	ImObj_ptr=self->GetImObj()
	ImObj=*ImObj_ptr
	im_ptr=ImObj->GetData()
	im=*im_ptr
	im=shift(im, fix(xshift[0]), fix(yshift[0]))
	*im_ptr=im
	ImObj->SetData, im_ptr
	ImObj->UpdateStretchedData
	self->DrawImage
endif

base_uval.wids.shift_wid=0L
widget_control, uval.base_id, set_uval=base_uval

widget_control, event.top, /destroy 

end
