pro CPlotWin_Draw_event, event

; get uval
widget_control, event.top, get_uval=uval
self=*(uval.self_ptr)

; for now, at least, disable this for contour and surface plots
if ((self->GetPlotType() eq "contour") or (self->GetPlotType() $
    eq "surface")) then begin
    ; display values on widget
    widget_control, uval.wids.xpos, set_value="n/a"
    widget_control, uval.wids.ypos, set_value="n/a"
    widget_control, uval.wids.val, set_value="n/a"
    return
endif

; get type of event
case event.type of 
    0: begin ; button press
        
    end
    1: begin ; button release
    end
    2: begin ; motion event

        ; size of characters in pixels
        charxs=6
        charys=10
    
        ; size of margins in units of charsize
        xmargin=self->GetXMargin()
        ymargin=self->GetYMargin()

        ; size of left and bottom margins in pixels
        xpix0=charxs*xmargin[0]
        ypix0=charys*ymargin[0]

        ; location of right end of plot window 
        xpix1=self->GetXS()-(charxs*xmargin[1])
        ypix1=self->GetYS()-(charys*ymargin[1])

        ; get plot ranges
        xplotrange=self->GetXRange()
        yplotrange=self->GetYRange()

        ; use (d-d0) = m(p-p0) where m=(d1-d0)/(p1-p0)
        ; p=event.x,y, d=what we want, the x,y pos in data units
        ; p0, p1=edges of plot area in pixels
        ; d0, d1=plot range in data units
        xslope=(xplotrange[1]-xplotrange[0])/(xpix1-xpix0)
        yslope=(yplotrange[1]-yplotrange[0])/(ypix1-ypix0)

        xplotpos=xslope*(event.x-xpix0)+xplotrange[0]
        yplotpos=yslope*(event.y-ypix0)+yplotrange[0]

        ; limit values by shown ranges
        xpos=(xplotrange[0] > (xplotpos) < xplotrange[1])
        ypos=(yplotrange[0] > (yplotpos) < yplotrange[1])

        ; get plot x, limited by data range
        datarange=self->GetPlottedRange()
        plotx= (datarange[0] > round(xpos) < datarange[1]) - datarange[0]

        ; get plot at location
        yval=(*(uval.plotval_ptr))[plotx]

        ; display values on widget
        ; check to see if there is a wavelength solution for this plot
        if ptr_valid(self->GetWavelengthSolution()) then begin
            widget_control, uval.wids.xpos, set_value=strtrim(xpos, 2)
            widget_control, uval.wids.ypos, set_value=strtrim(ypos, 2)
            ; add the wavelength position
            wavelength_solution=*(self->GetWavelengthSolution())
            wavelength_units=self->GetWavelengthUnits()
            if (wavelength_solution[0] ne -1) then begin
                wave_str=string(wavelength_solution[fix(plotx)], format='(F6.4)')
                yval=strtrim(yval,2)+' @ '+strtrim(wave_str,2)+' '$
                  +wavelength_units
                widget_control, uval.wids.val, set_value=strtrim(yval, 2)            
            endif else begin
                widget_control, uval.wids.val, set_value=strtrim(yval, 2)
            endelse
        endif else begin
            widget_control, uval.wids.xpos, set_value=strtrim(xpos, 2)
            widget_control, uval.wids.ypos, set_value=strtrim(ypos, 2)
            widget_control, uval.wids.val, set_value=strtrim(yval, 2)
        endelse
    end
                        ; motion events
    else: begin
        help, event, /struct
    end
endcase

end
