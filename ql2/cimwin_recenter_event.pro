pro cimwin_recenter_event, event

widget_control, event.top, get_uval=uval

; get self object
self=*uval.self_ptr

im_xs=self->GetDispIm_xs()
im_ys=self->GetDispIm_ys()

; reset the position of the image
uval.tv_p0=[im_xs/2, im_ys/2]

widget_control, event.top, set_uval=uval

;redraw image
self->DrawImage

end
