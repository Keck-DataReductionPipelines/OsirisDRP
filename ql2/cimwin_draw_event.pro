pro CImWin_Draw_event, event

widget_control, event.top, get_uval=uval

self=*uval.self_ptr
pmode=*uval.pmode_ptr
xscale=self->GetXScale()
yscale=self->GetYScale()
im=*(self->GetImObj())
im_xs=self->GetDispIm_xs()
im_ys=self->GetDispIm_ys()
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr
scl_im=bytscl(disp_im, min=self->GetDispMin(), max=self->GetDispMax())
win_xs=self->GetXS()
win_ys=self->GetYS()

if !version.release ge '6.0' then begin
; check to see if this is a keyboard event
if ((event.type eq 5) or (event.type eq 6)) then begin
    ; make sure it is a press
    if (event.press) then begin
        ; find out which button was pressed
        key=string(event.ch)
        case key of
            'p': begin
                ; pan
                self->AddPntMode, 'pan'
            end
            'm': begin
                ; recenter
                im_xs=self->GetDispIm_xs()
                im_ys=self->GetDispIm_ys()
                ; reset the position of the image
                uval.tv_p0=[im_xs/2, im_ys/2]
                widget_control, event.top, set_uval=uval 
                widget_control, event.top, get_uval=uval 
                self->DrawImage
            end
            'z': begin
                ; zoom box
                self->AddPntMode, 'zbox'
            end
            'i': begin
                ; zoom in
                ; get current scales
                cur_xscl=self->GetXScale()
                cur_yscl=self->GetYScale()
                self->SetXScale, cur_xscl*2.d			
                self->SetYScale, cur_yscl*2.d			
                ; update window text
                self->UpdateText
                ; redraw image
                self->DrawImage
            end
 
            'o': begin
                ; zoom out
                ; get current scales
                cur_xscl=self->GetXScale()
                cur_yscl=self->GetYScale()
                self->SetXScale, cur_xscl/2.d
                self->SetYScale, cur_yscl/2.d			
                ; update window text
                self->UpdateText
                ; redraw image
                self->DrawImage
            end
            'r': begin
                ; redisplay image
                self->ReopenImage
            end
            'l': begin
                ; linear stretch
                self->Linear, event.top
            end
            'Z': begin
                ; logarithmic stretch, with bottom=zero
                self->Logarithmic, event.top, min=0.0
			end
            'n': begin
                ; negative stretch
                self->Negative, event.top
            end
            'q': begin
                ; histeq stretch
                self->HistEq, event.top
            end
            's': begin
                ; statistics
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Statistics'
            end
            'a': begin
                ; aperture photometry
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Photometry'
            end
            't': begin
                ; strehl
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Strehl'
            end
            'f': begin
                ; fit (peak)
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Peak Fit'
            end
            'u': begin
                ; unravel
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Unravel'
            end
            'd': begin
                ; depth plot
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Depth Plot'
            end
            'h': begin
                ; horizontal plot
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Horizontal Cut'
            end
            'v': begin
                ; vertical plot
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Vertical Cut'
            end
            'g': begin
                ; diagonal plot
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Diagonal Cut'
            end
            'e': begin
                ; surface plot
                widget_control, event.top, get_uval=uval
                cimwin_menu_event, event, selection='Surface'
            end
            'c': begin
                ; contour plot
                cimwin_menu_event, event, selection='Contour'
            end
            'G': begin ; pick a slice, any slice...
                cimwin_menu_event, event, selection='Go To Slice'
            end
			; next/prev slices
			'-': begin
				widget_control, uval.wids.cube_slider, get_value=res
				res-=1
				; check it's within range limits
				widget_control, uval.wids.cube_range_min, get_value=minval
				widget_control, uval.wids.cube_range_max, get_value=maxval
				res = minval > res < maxval
				widget_control, uval.wids.cube_slider, set_value=res
				clickevent = {top: event.top, id: uval.wids.cube_single_button, handler: ""}
				cimwin_cube_select_event, clickevent
			end
		'+': begin
				widget_control, uval.wids.cube_slider, get_value=res
				res+=1
				; check it's within range limits
				widget_control, uval.wids.cube_range_min, get_value=minval
				widget_control, uval.wids.cube_range_max, get_value=maxval
				res = minval > res < maxval
				widget_control, uval.wids.cube_slider, set_value=res
				clickevent = {top: event.top, id: uval.wids.cube_single_button, handler: ""}
				cimwin_cube_select_event, clickevent

				widget_control, uval.wids.cube_slider, get_value=res
				widget_control, uval.wids.cube_slider, set_value=(res+1)
			end


			'=': begin
				widget_control, uval.wids.cube_slider, get_value=res
				res+=1
				; check it's within range limits
				widget_control, uval.wids.cube_range_min, get_value=minval
				widget_control, uval.wids.cube_range_max, get_value=maxval
				res = minval > res < maxval
				widget_control, uval.wids.cube_slider, set_value=res
				clickevent = {top: event.top, id: uval.wids.cube_single_button, handler: ""}
				cimwin_cube_select_event, clickevent

				widget_control, uval.wids.cube_slider, get_value=res
				widget_control, uval.wids.cube_slider, set_value=(res+1)
			end

 
            else: begin
            end
        endcase
    endif
endif
endif
  

; -- check to see if the image data has been resized for display.  if
;    yes, then calculate the x and y position of the mouse in data
;    coordinates
x = 0 > fix(uval.tv_p0[0] + ((event.x-win_xs/2.)/xscale)) < $
  (im_xs-1)
y = 0 > fix(uval.tv_p0[1] + ((event.y-win_ys/2.)/yscale)) < $
  (im_ys-1)

; Motion event: Update the X, Y, and Val labels.

; check to see if this is an unraveled cube
p_unraveled=self->GetUnravelLocations()
if ptr_valid(p_unraveled) then begin
    ; set values in the widget
    unraveled_locations=*(p_unraveled)
    ; get the axes order
    axesorder=self->GetAxesOrder()
    if (axesorder[0] eq 0) then begin
        xval=strtrim(fix(x),2)
        yval=strtrim(fix(y),2)+'  ('+strtrim(fix(unraveled_locations[y,0]),2)+','+ $
             strtrim(fix(unraveled_locations[y,1]),2)+')'
    endif else begin
        xval=strtrim(fix(x),2)+'  ('+strtrim(fix(unraveled_locations[x,0]),2)+','+ $
             strtrim(fix(unraveled_locations[x,1]),2)+')'
        yval=strtrim(fix(y),2)
    endelse
    widget_control, uval.wids.xpos, set_value=xval
    widget_control, uval.wids.ypos, set_value=yval
    ; check to see if the data type is a byte, then fix before making string
    sz_val=size(disp_im[x,y])
    if (sz_val[1] eq 1) then begin
        val=fix(disp_im[x,y])
        widget_control, uval.wids.val, set_value=strtrim(val, 2)
    endif else begin
        widget_control, uval.wids.val, set_value=strtrim(disp_im[x, y], 2)
    endelse
endif else begin
    ; set values in the widget
    widget_control, uval.wids.xpos, set_value=strtrim(fix(x), 2)
    widget_control, uval.wids.ypos, set_value=strtrim(fix(y), 2)

    ; check to see if the data type is a byte, then fix before making string
    sz_val=size(disp_im[x,y])
    if (sz_val[1] eq 1) then begin
        val=fix(disp_im[x,y])
        widget_control, uval.wids.val, set_value=strtrim(val, 2)
    endif else begin
        widget_control, uval.wids.val, set_value=strtrim(disp_im[x, y], 2)
    endelse

	self->UpdateWCSDisplay,x,y
	
endelse

if (self->GetParentBaseId() ne self->GetBaseId()) then begin
    widget_control, self->GetParentBaseId(), get_uval=conbase_uval
    widget_control, conbase_uval.wids.draw, get_value=index

    ; if a click on image, and in pan mode
    if (event.type eq 0) and (pmode[0].type eq 'pan') then begin
        uval.tv_p0[0]=0 > x < (im_xs-1)
        uval.tv_p0[1]=0 > y < (im_ys-1)
        widget_control, event.top, set_uval=uval
        self->DrawImage
    endif

    ; if click on image, and in photometry mode
    if (event.type eq 0) and (pmode[0].type eq 'phot') then begin
        ; remove the previous photometry circle if it exists
        if (uval.circ_phot_pres) then self->RemoveCircle
        uval.phot_circ_x=x
        uval.phot_circ_y=y
        uval.circ_phot_pres=1
        widget_control, event.top, set_uval=uval
        self->DrawImageBox_n_Circles
        self->CalcPhot
    endif

    ; if click on image, and in strehl mode
    if (event.type eq 0) and (pmode[0].type eq 'strehl') then begin
        ; remove the previous circle if it exists
        if (uval.circ_strehl_pres) then self->RemoveCircle
        uval.strehl_circ_x=x
        uval.strehl_circ_y=y
        uval.circ_strehl_pres=1
        widget_control, event.top, set_uval=uval
        self->DrawImageBox_n_Circles
        self->CalcStrehl
    endif

    ; if click to start drawing a box
    if (event.type eq 0) and (pmode[0].pointingmode eq 'box') then begin
        if (pmode[0].type ne 'zbox') then begin
            ; remove the previous box
             if (uval.box_pres) then begin
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
            uval.drawing_box=1
            uval.box_p0=[x, y]
            uval.box_p1=[x, y]
            uval.draw_box_p0=[event.x, event.y]
            uval.draw_box_p1=[event.x, event.y]
            self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            widget_control, event.top, set_uval=uval
        endif else begin
            uval.drawing_box=1
            uval.zbox_p0=[x, y]
            uval.zbox_p1=[x, y]
            uval.draw_zbox_p0=[event.x, event.y]
            uval.draw_zbox_p1=[event.x, event.y]
            self->Draw_Box, uval.draw_zbox_p0, uval.draw_zbox_p1
            widget_control, event.top, set_uval=uval            
        endelse
    endif

    ; drawing box while moving mouse
    if (uval.drawing_box eq 1) and (event.type eq 2) then begin
        if (pmode[0].type ne 'zbox') then begin
            if (event.x ne uval.draw_box_p1[0]) or $          
              (event.y ne uval.draw_box_p1[1]) then begin
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                uval.box_p1=[x,y]
                uval.draw_box_p1=[event.x, event.y]
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                widget_control, event.top, set_uval=uval
            endif
        endif else begin
            if (event.x ne uval.draw_zbox_p1[0]) or $          
              (event.y ne uval.draw_zbox_p1[1]) then begin
                self->Draw_Box, uval.draw_zbox_p0, uval.draw_zbox_p1
                uval.zbox_p1=[x,y]
                uval.draw_zbox_p1=[event.x, event.y]
                self->Draw_Box, uval.draw_zbox_p0, uval.draw_zbox_p1
                widget_control, event.top, set_uval=uval
            endif
        endelse
    endif
    
    ; if release after drawing a box
    if (event.type eq 1) and (pmode[0].pointingmode eq 'box') then begin
        if (pmode[0].type ne 'zbox') then begin
            self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            uval.drawing_box=0
            uval.box_p1=[x, y]
            print, 'box endpoint is ', x, ' ', y

            ; calculate locations of resized box corners
            new_x0=(uval.box_p0[0] < uval.box_p1[0])
            new_x1=(uval.box_p0[0] > uval.box_p1[0])
            new_y0=(uval.box_p0[1] < uval.box_p1[1])
            new_y1=(uval.box_p0[1] > uval.box_p1[1])
            
            fin_x0=floor(win_xs/2.+((new_x0-uval.tv_p0[0])*xscale))
            fin_x1=floor(win_xs/2.+((new_x1-uval.tv_p0[0]+1)*xscale))
            fin_y0=floor(win_ys/2.+((new_y0-uval.tv_p0[1])*yscale))
            fin_y1=floor(win_ys/2.+((new_y1-uval.tv_p0[1]+1)*yscale))
            
            uval.draw_box_p0=[fin_x0, fin_y0]
            uval.draw_box_p1=[fin_x1, fin_y1]
            uval.box_pres=1
            widget_control, event.top, set_uval=uval
        
            self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
        endif else begin
            ; remove the current zbox
            self->Draw_Box, uval.draw_zbox_p0, uval.draw_zbox_p1

            uval.drawing_box=0
            uval.zbox_p1=[x, y]
            print, 'box endpoint is ', x, ' ', y

            ; calculate locations of resized box corners
            new_x0=(uval.zbox_p0[0] < uval.zbox_p1[0])
            new_x1=(uval.zbox_p0[0] > uval.zbox_p1[0])
            new_y0=(uval.zbox_p0[1] < uval.zbox_p1[1])
            new_y1=(uval.zbox_p0[1] > uval.zbox_p1[1])
            
            fin_x0=floor(win_xs/2.+((new_x0-uval.tv_p0[0])*xscale))
            fin_x1=floor(win_xs/2.+((new_x1-uval.tv_p0[0]+1)*xscale))
            fin_y0=floor(win_ys/2.+((new_y0-uval.tv_p0[1])*yscale))
            fin_y1=floor(win_ys/2.+((new_y1-uval.tv_p0[1]+1)*yscale))
            
            uval.draw_zbox_p0=[fin_x0, fin_y0]
            uval.draw_zbox_p1=[fin_x1, fin_y1]

            widget_control, event.top, set_uval=uval
        endelse

        widget_control, event.top, get_uval=uval
        case pmode[0].type of
            'stat':self->CalcStat, event.top
            'peak fit':self->CalcGauss, event.top
            'unravel': begin
                self->Unravel, event.top
                ; remove the unravel pointing mode
                ; if the box exists then remove it
                pmode=*uval.pmode_ptr
                if (pmode[0].pointingmode eq 'box') then begin
                    if (uval.box_pres) then self->RemoveBox
                endif
                ; if the first element is a circle, remove it since it will be redrawn
                if (pmode[0].pointingmode eq 'aperture') then begin
                    if ((pmode[0].type eq 'strehl' and (uval.circ_strehl_pres)) or ((pmode[0].type eq 'phot' and (uval.circ_phot_pres)))) then begin
                        self->RemoveCircle
                    endif
                endif
                self->RmPntMode, 'unravel'
                ; draw the current pointing mode box/circle if present
                self->DrawImageBox_n_Circles
                end
            'zbox':self->ZoomBox, event.top
            else:self->DrawPlot, event.top, pmode[0].type
        endcase
        ; get uval again, in case it has changed during the
        ; execution of the self->procedure in
        ; the case statement above
        widget_control, event.top, get_uval=uval

    endif

    ; if click to start drawing a diagonal box
    if (event.type eq 0) and (pmode[0].pointingmode eq 'diag') then begin
        ; remove the previous box
        if (uval.diag_pres) then begin
            self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
        endif
        uval.drawing_diagonal_box=1
        uval.diagonal_box_p0=[x, y]
        uval.diagonal_box_p1=[x, y]
        uval.draw_diagonal_box_p0=[event.x, event.y]
        uval.draw_diagonal_box_p1=[event.x, event.y]
        widget_control, event.top, set_uval=uval
    endif

    ; drawing diagonal box while moving mouse
    if (uval.drawing_diagonal_box eq 1) and (event.type eq 2) then begin
        if (event.x ne uval.draw_diagonal_box_p1[0]) or $          
          (event.y ne uval.draw_diagonal_box_p1[1]) then begin
            ; remove the previous diagonal box
            self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            uval.diagonal_box_p1=[x,y]
            uval.draw_diagonal_box_p1=[event.x, event.y]
            ; draw the new diagonal box
            self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            widget_control, event.top, set_uval=uval
        endif
    endif 

    ; if release after drawing a diagonal box
    if (event.type eq 1) and (pmode[0].pointingmode eq 'diag') then begin
        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
        uval.drawing_diagonal_box=0
        uval.diagonal_box_p1=[x, y]
        print, 'box endpoint is ', x, ' ', y
        
        ; calculate locations of resized box corners
        new_x0=uval.diagonal_box_p0[0]
        new_x1=uval.diagonal_box_p1[0]
        new_y0=uval.diagonal_box_p0[1]
        new_y1=uval.diagonal_box_p1[1]
        
        fin_x0=floor(win_xs/2.+((new_x0-uval.tv_p0[0])*xscale))
        fin_x1=floor(win_xs/2.+((new_x1-uval.tv_p0[0]+1)*xscale))
        fin_y0=floor(win_ys/2.+((new_y0-uval.tv_p0[1])*yscale))
        fin_y1=floor(win_ys/2.+((new_y1-uval.tv_p0[1]+1)*yscale))

        uval.draw_diagonal_box_p0=[fin_x0, fin_y0]
        uval.draw_diagonal_box_p1=[fin_x1, fin_y1]
        uval.diag_pres=1
        
        widget_control, event.top, set_uval=uval

        self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
        self->DrawDiagonalPlot, event.top
    endif
endif


    ; update zoom window
if !D.Name ne 'PS' then begin
    save=!D.WINDOW
    wset, index
endif

; find the subset of the original image that you want to place in the
; zoomed window

; number of elements included in the zoomed image (should be
; an odd number)
nelements=15.

conwin_x0= 0 > (x-((nelements-1)/2.))
conwin_x1= (x+((nelements-1)/2.)) < (im_xs-1)
conwin_y0= 0 > (y-((nelements-1)/2.))
conwin_y1= (y+((nelements-1)/2.)) < (im_ys-1)
   
; if the cursor moves beyond edge of conwin window, erase conwin window
if (conwin_x0 lt ((nelements-1)/2.)) or (conwin_x1 lt (x+((nelements-1)/2.))) $
  or (conwin_y0 lt ((nelements-1)/2.)) or $
  (conwin_y1 lt (y+((nelements-1)/2.))) then erase

; keep a fixed scale to the zoomed image
scale_x=double(conbase_uval.xs/(15.))
scale_y=double(conbase_uval.ys/(15.))

; # of pixels on each axis (elements * pixels/element)
x_congrid_limit=(conwin_x1-conwin_x0+1)*scale_x
y_congrid_limit=(conwin_y1-conwin_y0+1)*scale_y

; tv the image to the conbase zoom window
tv, congrid(scl_im[conwin_x0:conwin_x1, conwin_y0:conwin_y1], $
            x_congrid_limit, y_congrid_limit), $
    scale_x*(((nelements-1)/2.)-x+conwin_x0), scale_y*(((nelements-1)/2.)-y+conwin_y0)        
    
; plot grid on top
plot, [0, nelements], [0, nelements], /nodata, xticklen=1.0, $
      yticklen=1.0, xticks=5, yticks=5, xminor=1, yminor=1, charsize=0.01, $
      color=255*256L*256L, /noerase, xgridstyle=1, ygridstyle=1

if !D.Name ne 'PS' then begin
    wset, save
endif
    
widget_control, self->GetParentBaseId(), set_uval=conbase_uval

; make sure draw widget has mouse focus - so that when we mouse over
; it, the keyboard commands automatically become live. 
; MDP 2007-08-10
widget_control, uval.wids.draw, /sensitive, /input_focus


end


