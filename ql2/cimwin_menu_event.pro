pro CImWin_Menu_event, event, selection=selection
; main menu event handler

widget_control, event.top, get_uval=uval


if keyword_set(selection) then begin
    selection=selection
endif else begin
    widget_control, event.id, get_value=selection
endelse

self=*uval.self_ptr

; Handle here the TIMER events used to implement the "scroll through all slices" feature
;  This is not really a menu event but this is a convenient spot to put the code. 
if (TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_TIMER') THEN BEGIN
    self->ScrollSlicesNext, event.id
	return
endif




pmode=*uval.pmode_ptr
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr

; call appropriate routine for menu selection
case selection of
    'Make Window Active': self->MakeWinActive, event.top
    'Make Window Inactive': self->MakeWinInactive, event.top
    'Inherit Active Window Params': self->ActiveParamsUpdate
    'View Fits Header': if uval.exist.fitshedit eq 0L then $
      						self->FitsHedit, event.top $
    					else widget_control, uval.exist.fitshedit, /show
    'Make Movie': begin
        ; check to see if the image is 3d, if not, then display error
        if ( ImObj->GetZS()  gt 1) then begin
            if uval.exist.movie eq 0L then $
              self->MakeMovie, event.top $
            else widget_control, uval.exist.movie, /show
        endif else begin
            message='Movies can onld be made with 3 dimensional images.'
            answer=dialog_message(message, dialog_parent=event.top, /error)
            return
        endelse
    end
    'Save As 2D': 		self->SaveAs2d, event.top
    'Save As Cube': 	self->SaveAs, event.top
    'Save Cube to IDL variable': 	self->SaveToVariable, event.top, "Cube"
    'Save Image to IDL variable': 	self->SaveToVariable, event.top, "Image"
    'Save Header to IDL variable': 	self->SaveToVariable, event.top, "Header"
    'Print': 	if uval.exist.print eq 0L then $
      				self->Print, event.top $
    			else widget_control, uval.exist.print, /show
    'Close': 	CImWin_Close, event.top
    'Redisplay image': self->ReopenImage
    ; if widget exists, bring it to the front
    'Rotate': 	if uval.exist.rotate eq 0L then $
      				self->Rotate, event.top $
    			else widget_control, uval.exist.rotate, /show
    'Linear': 	self->Linear, event.top
    'Negative': self->Negative, event.top
    'HistEq':	self->HistEq, event.top
    'Logarithmic':self->Logarithmic, event.top
    'Sqrt':		self->Sqrt, event.top
    'AsinH':	self->AsinH, event.top
    'Position Angle':self->DispPA, event.top
    'As Total DN': begin
        self->SetCurrentDisplay, 'As Total DN', /update
;        self->SetCurrentDisplayUpdate, 1
        self->DisplayAsDN
        self->DrawImage
    	end
    'As DN/s': begin
        self->SetCurrentDisplay, 'As DN/s', /update
;        self->SetCurrentDisplayUpdate, 1
        self->DisplayAsDN
        self->DrawImage
        end
    'Draw Axes Labels':	self->setdrawaxes,1
    'Remove Axes Labels':self->setdrawaxes,0
    'Go To Slice': begin
		; get a value
		;res = TextBox(Title='Select Slice Number...', Group_Leader=event.top, $
      		;Label='Enter the datacube slice to display: ', Cancel=cancelled, XSize=200, Value='0')

		; TODO asking for 'wavelength' only makes sense if the depth direction of the cube
		; is wavelength. So if we're rotated some other way, then don't allow that
		; option?
			lambda = self->wavesol(axis=waveaxis)
			lammin = min(*lambda, max=lammax)
			axesorder = self->GetAxesOrder()
			widget_control, uval.wids.cube_range_min, get_value=minval
			widget_control, uval.wids.cube_range_max, get_value=maxval
			if axesorder[2] eq waveaxis then  begin
				line0 = '0, droplist, Slice|Wavelength,label_left = Display:,tag=type'
				line1 = '0, float, ,label_left =        number:, width = 8,tag=number'
;;				line2 = '0, float, ,label_left = with redshift:, width = 8,tag=redshift'
				line2 = '0, label,  '

				line3 = '0, label, Specify wavelengths in microns, '
				;line4 = '0, label, and/or redshifts in km/sec. '
				line4 = '0, label,  '
				line5 = '0, label, Valid slice numbers = ['+string(minval, format="(I4)")+' - '+string(maxval,format="(I4)")+']'
				line6 = '0, label, Valid wavelength range = ['+sigfig(lammin, 4)+' - '+sigfig(lammax,4)+']'
				
				lines = [line0, line1, line2,line3, line4, line5,line6]
			endif else begin
				line0 = '0, droplist, Slice,label_left = Display:,tag=type'
				line1 = '0, float, ,label_left =   number:, width = 12,tag=number'
				line5 = '0, label, valid slice numbers = ['+string(minval, format="(I4)")+' - '+string(maxval,format="(I4)")+']'
				lines = [line0, line1, line5]
			endelse
				formdesc = [lines,'0, button, Go!, quit, tag=ok', $
		            '0, button, Cancel, quit,tag=cancelled']
					formresult = cw_form(formdesc, /column,  title = 'Quicklook2  -  Go To Slice')

		
	    IF formresult.cancelled THEN return
		case formresult.type of 
	    0: begin ; go to slice
		slice = formresult.number
		end
		1: begin ; go to wavelength
			lam = lammin > formresult.number < lammax
			dl = min( abs(*lambda-lam), wmin)
			slice = wmin
		end
		endcase
		;stop
		ptr_free,lambda

		; check it's within range limits
		slice = minval > fix(slice) < maxval
		; set the slider
    	widget_control, uval.wids.cube_slider, set_value=slice
		; create and send a fake event to switch to 'Slice' mode and redisplay
		; the image
    	widget_control, uval.wids.cube_single_button, set_button=1
		clickevent = {top: event.top, id: uval.wids.cube_single_button, handler: ""}
		cimwin_cube_select_event, clickevent
	  end
	'Scroll through All Slices': begin
		; create and send a fake event to switch to 'Slice' mode
		single_mode = widget_info(uval.wids.cube_single_button, /button_set)
		if (not single_mode) then begin
    			widget_control, uval.wids.cube_single_button, set_button=1
			clickevent = {top: event.top, id: uval.wids.cube_single_button, handler: ""}
			cimwin_cube_select_event, clickevent
		endif
		self->ScrollSlicesStart, event.id
	  end
	'Cancel Scrolling through All Slices': begin
		print, "Scrolling cancelled!"
		self->CancelScrollSlices
	  end

    'Statistics': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, then remove it 
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
        ; redraw the box if one previously exists
        if (pmode[0].pointingmode ne 'box') then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
        self->AddPntMode, 'stat'
        if uval.exist.statistics eq 0L then $
          self->Statistics, event.top $
        else widget_control, uval.exist.statistics, /show
        ; if a box is already drawn to the screen, then use it to do the
        ; initial calculation
        if (uval.box_pres) then begin
            self->CalcStat, event.top
        endif
    end
    'Photometry': begin
        widget_control, event.top, get_uval=uval
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
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
        ; if a strehl circle is already drawn, then remove it
        if (pmode[0].type eq 'strehl') then begin
            if (uval.circ_strehl_pres) then begin
                self->DrawCircleParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y
            endif
        endif
        ; redraw the photometry circle if one previously exists
        if (pmode[0].type ne 'phot') then begin
            if (uval.circ_phot_pres) then begin
                self->DrawCircleParams, circ_type='phot'
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='phot'
            endif
        endif
        ; add the pointing mode to the stack
        self->AddPntMode, 'phot'

        if uval.exist.photometry eq 0L then $
          self->Photometry, event.top $
        else widget_control, uval.exist.photometry, /show
    end
    'Strehl': begin
        widget_control, event.top, get_uval=uval
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
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
        ; if a phot circle is already drawn, then remove it        
        if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
            self->DrawCircleParams, circ_type='phot'
            self->RemoveCircle, circ_type='phot'
        endif
        ; redraw the strehl circle if one previously exists
        if (pmode[0].type ne 'strehl') then begin
            if (uval.circ_strehl_pres) then begin
                self->DrawCircleParams, circ_type='strehl'
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='strehl'
            endif
        endif
        self->AddPntMode, 'strehl'
        if uval.exist.strehl eq 0L then $
          self->Strehl, event.top $
        else widget_control, uval.exist.strehl, /show
    end
    'Peak Fit': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, then remove it
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        end
        ; redraw the box if one previously exists
        if (pmode[0].pointingmode ne 'box') then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
        self->AddPntMode, 'peak fit'
        if uval.exist.gaussian eq 0L then $
          self->Gaussian, event.top $
        else widget_control, uval.exist.gaussian, /show        
        ; if a box is already drawn to the screen, then use it to do the
        ; initial calculation
        if (uval.box_pres) then begin
            self->CalcGauss, event.top
        endif
    end
    'Unravel': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, remove it since it will be redrawn
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif 
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
        ; redraw the box if one previously exists
        if (pmode[0].pointingmode ne 'box') then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
        self->AddPntMode, 'unravel'
    end
    'Digital Filter': begin
        widget_control, event.top, get_uval=uval
        if uval.exist.filter eq 0L then $
          self->Digital_Filter, event.top $
        else widget_control, uval.exist.filter, /show
    end
    'Load digital filter': begin
        widget_control, event.top, get_uval=uval
        if uval.exist.filterbrowse eq 0L then $
          self->LoadFilter, event.top $
        else widget_control, uval.exist.filterbrowse, /show
    end
    'Display digital filter':begin
        widget_control, event.top, get_uval=uval
        self->AddPntMode, 'plot'
        if uval.exist.plot eq 0L then $
          self->FilterPlot, event.top, event.id $
        else begin
            widget_control, uval.exist.plot, /show, $
                            get_uval=plot_uval
            plot_obj=*(plot_uval.self_ptr)
            plot_obj->ChangePlotType, 'filter'
        endelse
    end
    'Load digital filter': begin
        widget_control, event.top, get_uval=uval
        if uval.exist.filterbrowse eq 0L then $
          self->LoadFilter, event.top $
        else widget_control, uval.exist.filterbrowse, /show   
    end
    
    ; if plot window exists, bring it to the front and set plot type
    'Depth Plot': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, remove it since it will be redrawn
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif 
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
        ; redraw the box if one previously exists
        if (pmode[0].pointingmode ne 'box') then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
        self->AddPntMode, 'depth'
        if uval.exist.plot eq 0L then begin
		  	; If there is not a plot window, then create one.
          	;self->DepthPlot, event.top $
          	self->NewPlotWindow, event.top, 'depth'
        endif else begin
		  	; If there is a plot window, bring it to front and do a Depth Plot
            widget_control, uval.exist.plot, /show, $
                            get_uval=plot_uval
            plot_obj=*(plot_uval.self_ptr)
            plot_obj->ChangePlotType, 'depth'
        endelse
        
        ; if a box is already drawn to the screen, then use it to do the
        ; initial calculation
        if (uval.box_pres) then begin
            self->DrawPlot, event.top, 'depth'                
        endif
    end
    'Horizontal Cut': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, remove it since it will be redrawn
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif 
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif 
        ; redraw the box if one previously exists
        if (pmode[0].pointingmode ne 'box') then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, event.top, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
        self->AddPntMode, 'horizontal'
        if uval.exist.plot eq 0L then  begin
            self->NewPlotWindow, event.top, 'horizontal'
        endif else begin
            widget_control, uval.exist.plot, /show, $
                            get_uval=plot_uval
            plot_obj=*(plot_uval.self_ptr)
            plot_obj->ChangePlotType, 'horizontal'
            plot_obj->DrawPlot
        endelse
        ; if a box is already drawn to the screen, then use it to do the
        ; initial calculation
        if (uval.box_pres) then begin
            self->DrawPlot, event.top, 'horizontal'                
        endif
    end
    'Vertical Cut': begin
        widget_control, event.top, get_uval=uval
        ; pan is the first element, then delete drawing accordingly
        if pmode[0].type eq 'pan' then begin
            ; check to see if a second pointing mode exists
            if (size(pmode, /n_elements) gt 1) then begin
                ; if the second element is a circle, remove it since it will be redrawn
                if pmode[1].pointingmode eq 'aperture' then begin
                    if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                        self->DrawCircleParams, circ_type='strehl'
                        self->RemoveCircle, circ_type='strehl'
                    endif
                    if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                        self->DrawCircleParams, circ_type='phot'
                        self->RemoveCircle, circ_type='phot'
                    endif
                endif
                ; if the second element is diagonal, then remove it
                if pmode[1].pointingmode eq 'diag' then begin
                    if (uval.diag_pres) then begin
                        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                    endif
                endif
            endif
        endif 
        ; if a circle is already drawn, then remove it
        if pmode[0].pointingmode eq 'aperture' then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                self->RemoveCircle, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                self->RemoveCircle, circ_type='phot'
            endif
        endif
        ; if a diagonal box is already drawn, then remove it
        if pmode[0].pointingmode eq 'diag' then begin
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
            ; redraw the box if one previously exists
            if (pmode[0].pointingmode ne 'box') then begin
                if (uval.box_pres) then begin
                    self->DrawBoxParams
                    ; get the uval again
                    widget_control, event.top, get_uval=uval
                    self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                endif
            endif
            self->AddPntMode, 'vertical'
            if uval.exist.plot eq 0L then begin
              self->NewPlotWindow, event.top, 'vertical'
            endif else begin
                widget_control, uval.exist.plot, /show, $
                  get_uval=plot_uval
                plot_obj=*(plot_uval.self_ptr)
                plot_obj->ChangePlotType, 'vertical'
            endelse
            ; if a box is already drawn to the screen, then use it to do the
            ; initial calculation
            if (uval.box_pres) then begin
                self->DrawPlot, event.top, 'vertical'                
            endif
        end
        'Diagonal Cut': begin
            widget_control, event.top, get_uval=uval
            ; pan is the first element, then delete drawing accordingly
            if pmode[0].type eq 'pan' then begin
                ; check to see if a second pointing mode exists
                if (size(pmode, /n_elements) gt 1) then begin
                    ; if the second element is a circle, remove it since it will be redrawn
                    if pmode[1].pointingmode eq 'aperture' then begin
                        if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                            self->DrawCircleParams, circ_type='strehl'
                            self->RemoveCircle, circ_type='strehl'
                        endif
                        if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                            self->DrawCircleParams, circ_type='phot'
                            self->RemoveCircle, circ_type='phot'
                        endif
                    endif
                endif
            endif  
            ; if a circle is already drawn, then remove it
            if pmode[0].pointingmode eq 'aperture' then begin
                if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                    self->DrawCircleParams, circ_type='strehl'
                    self->RemoveCircle, circ_type='strehl'
                endif
                if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                    self->DrawCircleParams, circ_type='phot'
                    self->RemoveCircle, circ_type='phot'
                endif
            endif
            ; if a box is already drawn, then remove it
            if (pmode[0].pointingmode eq 'box') then begin
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
                endif else begin
                    if pmode[0].type eq 'zbox' then begin
                        if (size(pmode, /n_elements) gt 1) then begin
                            if pmode[1].type eq 'diagonal' then begin
                                if (uval.diag_pres) then begin
                                    ; undraw, because it will draw again below
                                    self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, $
                                      uval.draw_diagonal_box_p1
                                endif
                            endif
                        endif
                    endif
                endelse
            endif
            ; redraw diagonal the box if one previously existed
            if (pmode[0].type ne 'diagonal') then begin 
                if (uval.diag_pres) then begin
                    self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                endif
            endif

            self->AddPntMode, 'diagonal'
            if uval.exist.plot eq 0L then $
              self->NewPlotWindow, event.top, 'diagonal' $
            else begin
                widget_control, uval.exist.plot, /show, $
                                get_uval=plot_uval
                plot_obj=*(plot_uval.self_ptr)
                plot_obj->ChangePlotType, 'diagonal'
            endelse
            ; if a box is already drawn to the screen, then use it to do the
            ; initial calculation
            if (uval.diag_pres) then begin
                self->DrawPlot, event.top, 'diagonal'                
            endif
        end
        'Surface': begin
            widget_control, event.top, get_uval=uval
            ; pan is the first element, then delete drawing accordingly
            if pmode[0].type eq 'pan' then begin
                ; check to see if a second pointing mode exists
                if (size(pmode, /n_elements) gt 1) then begin
                    ; if the second element is a circle, remove it since it will be redrawn
                    if pmode[1].pointingmode eq 'aperture' then begin
                        if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                            self->DrawCircleParams, circ_type='strehl'
                            self->RemoveCircle, circ_type='strehl'
                        endif
                        if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                            self->DrawCircleParams, circ_type='phot'
                            self->RemoveCircle, circ_type='phot'
                        endif
                    endif
                    ; if the second element is diagonal, then remove it
                    if pmode[1].pointingmode eq 'diag' then begin
                        if (uval.diag_pres) then begin
                            self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                        endif
                    endif
                endif
            endif
            ; if a circle is already drawn, then remove it
            if pmode[0].pointingmode eq 'aperture' then begin
                if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                    self->DrawCircleParams, circ_type='strehl'
                    self->RemoveCircle, circ_type='strehl'
                endif
                if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                    self->DrawCircleParams, circ_type='phot'
                    self->RemoveCircle, circ_type='phot'
                endif
            endif
            ; if a diagonal box is already drawn, then remove it
            if pmode[0].pointingmode eq 'diag' then begin
                if (uval.diag_pres) then begin
                    self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                endif
            endif
            ; redraw the box if one previously exists
            if (pmode[0].pointingmode ne 'box') then begin
                if (uval.box_pres) then begin
                    self->DrawBoxParams
                    ; get the uval again
                    widget_control, event.top, get_uval=uval
                    self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                endif
            endif
            self->AddPntMode, 'surface'
            if uval.exist.plot eq 0L then $
              self->NewPlotWindow, event.top, 'surface' $
            else begin
                widget_control, uval.exist.plot, /show, $
                  get_uval=plot_uval
                plot_obj=*(plot_uval.self_ptr)
                plot_obj->ChangePlotType, 'surface'
            endelse
            ; if a box is already drawn to the screen, then use it to do the
            ; initial calculation
            if (uval.box_pres) then begin
                self->DrawPlot, event.top, 'surface'                
            endif
        end
        'Contour': begin
            widget_control, event.top, get_uval=uval
            ; pan is the first element, then delete drawing accordingly
            if pmode[0].type eq 'pan' then begin
                ; check to see if a second pointing mode exists
                if (size(pmode, /n_elements) gt 1) then begin
                    ; if the second element is a circle, then remove it
                    if pmode[1].pointingmode eq 'aperture' then begin
                        if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                            self->DrawCircleParams, circ_type='strehl'
                            self->RemoveCircle, circ_type='strehl'
                        endif
                        if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                            self->DrawCircleParams, circ_type='phot'
                            self->RemoveCircle, circ_type='phot'
                        endif
                    endif
                    ; if the second element is diagonal, then remove it
                    if pmode[1].pointingmode eq 'diag' then begin
                        if (uval.diag_pres) then begin
                            self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                        endif
                    endif
                endif
            endif 
            ; if a circle is already drawn, then remove it
            if pmode[0].pointingmode eq 'aperture' then begin
                if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                    self->DrawCircleParams, circ_type='strehl'
                    self->RemoveCircle, circ_type='strehl'
                endif
                if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                    self->DrawCircleParams, circ_type='phot'
                    self->RemoveCircle, circ_type='phot'
                endif
            endif
            ; if a diagonal box is already drawn, then remove it
            if pmode[0].pointingmode eq 'diag' then begin
                if (uval.diag_pres) then begin
                    self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                endif
            endif
            ; redraw the box if one previously exists
            if (pmode[0].pointingmode ne 'box') then begin
                if (uval.box_pres) then begin
                    self->DrawBoxParams
                    ; get the uval again
                    widget_control, event.top, get_uval=uval
                    self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                endif
            endif
            self->AddPntMode, 'contour'
            if uval.exist.plot eq 0L then $
              self->NewPlotWindow, event.top, 'contour' $
            else begin
                widget_control, uval.exist.plot, /show, $
                  get_uval=plot_uval
                plot_obj=*(plot_uval.self_ptr)
                plot_obj->ChangePlotType, 'contour'
            endelse
            ; if a box is already drawn to the screen, then use it to do the
            ; initial calculation
            if (uval.box_pres) then begin
                self->DrawPlot, event.top, 'contour'                
            endif
        end
        
        else:  begin            ; Digital filter menu
          ; selection variable will hold the name of the file
          ; to be reopened, since the user will select the filename
          ; from the one listed next to 'Apply digital filter'.  Therefore,
          ; use the data file to filter the cube, and display the new image
          ; in the draw window.
            self->ApplyFilter, event.id, selection
        endelse
        
    endcase
    
end
