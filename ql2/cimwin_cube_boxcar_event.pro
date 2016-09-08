pro cimwin_cube_boxcar_event, event

; get uval
widget_control, event.top, get_uval=uval

; get self object
self=*(uval.self_ptr)

; get the boxcar size
widget_control, uval.wids.cube_slice_box, get_value=cube_slice_box

; make sure slice boxcar is within the limits
boxcar=0 > cube_slice_box < ((self->GetCurIm_s())[2]-1)

widget_control, uval.wids.cube_slice_box, set_value=boxcar

self->SetBoxcar, boxcar
self->SetResetZ, 0.
self->SetDoAutoScale, 0.
self->UpdateDispIm
self->DrawImage, /noerase

end

