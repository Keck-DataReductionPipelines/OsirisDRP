pro cimwin_cube_slice_event, event

; get main uval for box id's
widget_control, event.top, get_uval=uval

; get self object
self=*(uval.self_ptr)

; if it is the range button
if tag_names(event, /structure_name) eq 'WIDGET_BUTTON' then begin

	; get range limits
	widget_control, uval.wids.cube_range_min, get_value=minval
	widget_control, uval.wids.cube_range_max, get_value=maxval

	; get image object
	im=*(self->GetImObj())

	; need error handling here	
	tempmin=0 > fix(minval[0]) < ((self->GetCurIm_s())[2]-1)
	tempmax=0 > fix(maxval[0]) < ((self->GetCurIm_s())[2]-1)

	minnum=tempmin < tempmax
	maxnum=tempmin > tempmax

	; reset values with properly formatted values
	widget_control, uval.wids.cube_range_min, set_value=strtrim(minnum, 2)
	widget_control, uval.wids.cube_range_max, set_value=strtrim(maxnum, 2)
        
        widget_control, uval.wids.cube_curmin, set_value=strtrim(minnum, 2)
        widget_control, uval.wids.cube_curmax, set_value=strtrim(maxnum, 2)
   
        ; set new limits in cube
        self->SetZMin, minnum
        self->SetZMax, maxnum

        ; set the limits for the axes range
        ; find out which axis is displayed in the z direction
        axes_order=self->GetAxesOrder()
        axes_minmax=self->GetAxesMinMax()

        axes_minmax[axes_order[2],*]=[minnum,maxnum]

        self->SetAxesMinMax, axes_minmax

        print, 'z max is ', maxnum
        print, 'new_image ', uval.new_image

        ; if this is not a new image, then update the displayed image
        ; if this is a new image, then it's already updated
        if (uval.new_image ne 1) then begin
            ; redraw
            ; self->SetDoAutoScale, 1.
            self->UpdateDispIm
        endif else begin
            uval.new_image=0
            widget_control, event.top, set_uval=uval
        endelse
        self->DrawImage
endif else begin ; slider event
	minnum=event.value
	maxnum=minnum

	; reset values with properly formatted values        
        widget_control, uval.wids.cube_curmin, set_value=strtrim(minnum, 2)
        widget_control, uval.wids.cube_curmax, set_value=strtrim(maxnum, 2)

        ; set new limits in cube
        self->SetZMin, minnum
        self->SetZMax, maxnum
        ; redraw
        self->SetDoAutoScale, 0.
        self->UpdateDispIm
        self->DrawImage, /noerase
endelse

end
