; +
; NAME: ql_display_new_image
;
; PURPOSE: to display a new image, called from ql_buffer_list.pro,
;          ql_conmath.pro, ql_openfile.pro, and ql_conreduce.pro
;
; CALLING SEQUENCE: ql_display_new_image, parentbase_id, p_ImObj,
;                   p_WinObj=p_WinObj
;
; INPUTS:  conbase_id (long) - widget id of the control base
;          p_ImObj - pointer to the image object
;          p_WinObj - pointer to an existing window where the image
;                     will be opened
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY:
;          2003-02-24 - MWM: added comments.
;          2020-04-10 - jlyke: Change indents on comments for easier
;                                    reading
;                              Add call to UpdateDispIm in the
;                                    activeparams_set if block to
;                                    preserve the image flip (OSIMG)
;          2024-05-08 - Tuan Do - added ability to recongize non-OSIRIS instruments
;                       that have their spatial axes first (e.g. JWST NIRSpec).
; -

pro ql_display_new_image, conbase_id, p_ImObj, p_WinObj=p_WinObj, extension

; get control base uval
widget_control, conbase_id, get_uval=uval

if (ptr_valid(uval.p_curwin) eq 0) then begin
    current_actwin=ptr_new()
endif else begin
    current_actwin=uval.p_curwin
endelse

; write the memory usage and commit the change
help, /memory, output=current_memory
if ptr_valid(uval.memory_ptr) then begin
    memory_arr=*uval.memory_ptr
    memory_arr=[[memory_arr],[current_memory]]
    *uval.memory_ptr=memory_arr
endif else begin
    uval.memory_ptr=ptr_new(current_memory)
endelse
widget_control, conbase_id, set_uval=uval
widget_control, conbase_id, get_uval=uval

; image is set to the image stored in the memory location of the pointer
im=*p_ImObj

; used to make a new window if the p_WinObj keyword is not set
make_new_win=1

; construct the image title
if (extension ne 0) then begin
    filename=im->GetFilename()
    ext_str=string(extension)
    title=filename+' - Extension '+strtrim(ext_str,2)
endif else begin
    title=im->GetFilename()
endelse

; get the header
hd=*(im->GetHeader())

if ptr_valid(p_WinObj) then begin
    if keyword_set(p_WinObj) then begin
        ; checks to see if the object is valid, and makes sure that object
        ; is of the class 'CImWin'
        if obj_valid(*p_WinObj) then begin
            if obj_isa(*p_WinObj, 'CImWin') then begin
                ; copies the pointer p_WinObj to imwin_obj
                imwin_obj=*p_WinObj
                im_obj=*p_ImObj
                ; destroys the old image object
                obj_destroy, *(imwin_obj->GetImObj())
                ; removes the unravel ptr if there is one
                p_unraveled=imwin_obj->GetUnravelLocations()
                if ptr_valid(p_unraveled) then  ptr_free, p_unraveled
                ; updates the accessor functions for the window
                imwin_obj->SetTitle, title
                imwin_obj->UpdateTitleBar
                imwin_obj->SetImObj, p_ImObj
                make_new_win=0
                ; update the menu -  make the digital filter and depth plot
                ; sensitive if the image has 3 axes, and insensitive if there
                ; are any other number of axes
                winbase_id=imwin_obj->GetBaseId()
                widget_control, winbase_id, get_uval=winbase_uval
                im_xs=im->GetXs()
                im_ys=im->GetYs()
                im_zs=im->GetZs()
                ; check for the data display, figure out what the starting data unit is
				datanum_val='' ; default ; MDP - remove lots of redundant else clauses!
                if ptr_valid(uval.cconfigs_ptr) then begin
                    if obj_valid(*uval.cconfigs_ptr) then begin
                        if obj_isa(*uval.cconfigs_ptr, 'CConfigs') then begin
                            cconfigs=*(uval.cconfigs_ptr)
                            displayas=cconfigs->GetDisplayAsDN()
                            ; check to see if the header exists
                            instr=strtrim(sxpar(hd,'CURRINST'),2)
                            if (instr eq 'OSIRIS') or (instr eq 'NIRC2') then begin
                                case displayas of
                                    'As DN/s': datanum_val='DN/s'
                                    'As Total DN': datanum_val='DN'
                                    else: 
                                endcase
                            endif 
                        endif 
                    endif 
		endif ; endif for if ptr_valid(uval.cconfigs_ptr)
                widget_control, winbase_uval.wids.datanum, set_value=datanum_val
      
                if (im_zs gt 1) then begin
					; if this is an IMAGE CUBE
                    widget_control, winbase_id, get_uval=winbase_uval
                    widget_control, winbase_uval.wids.depth_id, sensitive=1
                    widget_control, winbase_uval.wids.unravel_id, sensitive=1
                    widget_control, winbase_uval.wids.saveascube_id, sensitive=1
                    widget_control, winbase_uval.wids.rotate_id, sensitive=0

                    ; update the dimension droplist
                    axes=['AXIS 1', 'AXIS 2', 'AXIS 3'] ; default
                    if ptr_valid(uval.cconfigs_ptr) then begin
                        if obj_valid(*uval.cconfigs_ptr) then begin
                            if obj_isa(*uval.cconfigs_ptr, 'CConfigs') then begin
                                cconfigs=*(uval.cconfigs_ptr)
                                axes=*(cconfigs->GetAxesLabels3d()) 
                            endif 
                        endif 
                     endif

                    ;; check to see the fits header which axis is the
                    ;; spatial and which are the spectral dimension.
                    ;; OSIRIS has [wavelenght, ra, dec], but most
                    ;; other IFUs use [ra, dec, wavelength] - T. Do
                    dim1 = sxpar(hd, 'CTYPE1')
                    if dim1 eq 'RA---TAN' then begin
                       print, 'The file '+filename+' has RA as its first axis. This is likely  not OSIRIS data. Loading axess order [0,1,2] instead.'
                       axesorder = [0, 1, 2]
                    endif else begin
                       axesorder = [2, 1, 0]
                    endelse
                    
                    ;; axesorder=[2, 1, 0]
                    
                    widget_control, winbase_uval.wids.xdim_list, set_value=axes[0:2]
                    widget_control, winbase_uval.wids.ydim_list, set_value=axes[0:2]
                    widget_control, winbase_id, set_uval=winbase_uval

                    ; set the axes min/max
                    axes_minmax=fltarr(3,2)
                    axes_minmax[0,*]=[0,im_xs-1]
                    axes_minmax[1,*]=[0,im_ys-1]
                    axes_minmax[2,*]=[0,im_zs-1]
                    imwin_obj->SetAxesMinMax, axes_minmax

                    ; if plot window exists, update that menu too
                    if (winbase_uval.exist.plot ne 0L) then begin
                        widget_control, winbase_uval.exist.plot, get_uval=plot_uval
		        ; TODO FIXME this is all screwed up, and when you open a
                        ; new image with a plot already open, sometimes bad
			; things happen. DEBUG LATER!!!
			; MDP it seems ridiculous to destroy the old
			; type_list_ptr only to imediately re-create it here.
			; Also, it's crashing.
                        ; make a new type list
;MDP	                        type_list=['Horizontal Cut', $
;MDP	                                   'Vertical Cut', $
;MDP	                                   'Diagonal Cut', $
;MDP	                                   'Depth Plot', $
;MDP	                                   'Surface Plot', $
;MDP	                                   'Contour Plot']
;MDP	                        widget_control, plot_uval.wids.plot_type_menu, $
;MDP	                                        set_value=type_list
;MDP	                        ; update the type list in the plotwin uval
;MDP							ptr_free,plot_uval.type_list_ptr
;MDP                        plot_uval.type_list_ptr=ptr_new(type_list)
                        plot=*plot_uval.self_ptr
                        plot_type=plot->GetPlotType() 
                        widget_control, winbase_uval.exist.plot, set_uval=plot_uval
                        ; update the image pointer and displayed image pointer
                        dispim_ptr=imwin_obj->GetDispIm()
                        im=*(imwin_obj->GetImObj())
                        im_data_ptr=im->GetData()
                        plot->SetP_DispIm, dispim_ptr 
                        plot->SetP_Im, im_data_ptr
                        ; update the image size
                        im_xs=im->GetXS()
                        im_ys=im->GetYS()
                        im_zs=im->GetZS()
                        imwin_obj->SetCurIm_s, [im_xs, im_ys, im_zs]
			; this line will erase the plot, and 
			; draw a new one using the params from imwin_uval
                        plot->ChangePlotType, plot_type ; MDP - moved this line to call it AFTER setting the new data.

                        ; reset the data range drawn plot
                        ; plot->SetXRange, [0, 0]
                        ; plot->SetYRange, [0, 0]
                        ; plot->SetXData_Range, [0, 0]
                        ; plot->SetYData_Range, [0, 0]
                        ; plot->SetResetRanges, 1
                        ; remove the wavelength solution ptr
                        wavesol_ptr=plot->GetWavelengthSolution()
                        ptr_free, wavesol_ptr
                        ; set the plot type to the old selection on the list
                        plottype=plot->GetPlotType()
			; MDP I believe the following code does nothing, since
			; droplist_select never gets used again.
;                        case plottype of
;                            'horizontal': droplist_select=0
;                            'vertical': droplist_select=1
;                            'diagonal': droplist_select=2
;                            'depth': droplist_select=3
;                            'surface': droplist_select=4
;                            'contour': droplist_select=5
;                            else:
;                        endcase

                    endif
                endif else begin
					; if this is a 2D IMAGE, NOT A CUBE
                    widget_control, winbase_id, get_uval=winbase_uval
                    widget_control, winbase_uval.wids.depth_id, sensitive=0
                    widget_control, winbase_uval.wids.unravel_id, sensitive=0
                    widget_control, winbase_uval.wids.saveascube_id, sensitive=0
                    widget_control, winbase_uval.wids.rotate_id, sensitive=1
                    
                    ; update the dimension droplist
                    axes=['AXIS 1', 'AXIS 2', 'AXIS 3'] ; default
                    if ptr_valid(uval.cconfigs_ptr) then begin
                        if obj_valid(*uval.cconfigs_ptr) then begin
                            if obj_isa(*uval.cconfigs_ptr, 'CConfigs') then begin
                                cconfigs=*(uval.cconfigs_ptr)
                                axes=*(cconfigs->GetAxesLabels3d()) 
                            endif 
                        endif 
                    endif 
                    axesorder=[0, 1, 2]
                    widget_control, winbase_uval.wids.xdim_list, set_value=axes[0:1]
                    widget_control, winbase_uval.wids.ydim_list, set_value=axes[0:1]
                    widget_control, winbase_id, set_uval=winbase_uval

                    ; set the axes min/max
                    axes_minmax=fltarr(3,2)
                    imwin_obj->SetAxesMinMax, axes_minmax

                    ; if plot window exists, update that menu too
                    if (winbase_uval.exist.plot ne 0L) then begin
                        widget_control, winbase_uval.exist.plot, get_uval=plot_uval
                        type_list=['Horizontal Cut', $
                                   'Vertical Cut', $
                                   'Diagonal Cut', $
                                   'Surface Plot', $
                                   'Contour Plot']
                        widget_control, plot_uval.wids.plot_type_menu, $
                          set_value=type_list
                        plot_uval.type_list_ptr=ptr_new(type_list)
                        ; change the menu selection if it were previously depth
                        plot=*plot_uval.self_ptr
                        if (plot->GetPlotType() eq 'depth') then plot->ChangePlotType, 'horizontal'
                        widget_control, winbase_uval.exist.plot, set_uval=plot_uval
                        ; update the image pointer and displayed image pointer
                        dispim_ptr=imwin_obj->GetDispIm()
                        im=*(imwin_obj->GetImObj())
                        im_data_ptr=im->GetData()
                        plot->SetP_DispIm, dispim_ptr 
                        plot->SetP_Im, im_data_ptr
                        ; update the image size
                        im_xs=im->GetXS()
                        im_ys=im->GetYS()
                        im_zs=im->GetZS()
                        imwin_obj->SetCurIm_s, [im_xs, im_ys, im_zs]
                        ; reset the data range drawn plot
                        ; plot->SetXRange, [0, 0]
                        ; plot->SetYRange, [0, 0]
                        ; plot->SetXData_Range, [0, 0]
                        ; plot->SetYData_Range, [0, 0]
                        ; plot->SetResetRanges, 1
                        ; remove the wavelength solution ptr
                        wavesol_ptr=plot->GetWavelengthSolution()
                        ptr_free, wavesol_ptr                        
                        ; set the plot type to the old selection on the list
                        plottype=plot->GetPlotType()
                        case plottype of
                            'horizontal': droplist_select=0
                            'vertical': droplist_select=1
                            'diagonal': droplist_select=2
                            'surface': droplist_select=3
                            'contour': droplist_select=4
                            else:
                        endcase
                    endif
                endelse
                ; set new_image to 1 so that draw image knows not to redraw
                ; the in the new window
                uval.new_image=1
                ; update the extension droplist if there is an extension
                im_extensions=im_obj->GetN_Ext()
				; MDP note: It doesn't appear that ext_arr_ptr is used anywhere?
                imwin_obj->MakeExtArr, im_extensions, ext_arr; , ext_arr_ptr ; MEMORY LEAK!
                *(winbase_uval.p_ext_arr)=ext_arr
                widget_control, winbase_uval.wids.extension_list, set_value=ext_arr
                ; renews the unravel ptr 
                p_unraveled=imwin_obj->GetUnravelLocations()
                ptr_free, p_unraveled
                ; save the new uval parameters
                widget_control, conbase_id, set_uval=uval
                widget_control, winbase_id, set_uval=winbase_uval
            endif ; if obj_isa(*p_WinObj, 'CImWin')
        endif ; if obj_valid(*p_WinObj)
    endif; if keyword_set(p_WinObj)
endif ; if ptr_valid(p_WinObj)

; if the window is not specified (p_WinObj=p_WinObj), then make a new
; window for the new image
if (make_new_win eq 1) then begin $
    ; make a new instance of the CImWin class
    imwin_obj=obj_new('CImWin', ParentBaseId=conbase_id, $
                   title=title, p_ImObj=p_ImObj, $
                   win_backing=uval.win_backing)

    ; make a pointer to the new image window
    widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
    p_WinObj=imwin_uval.self_ptr
    ql_imwinobj_add, conbase_id, p_WinObj
endif

; if the option 'make new windows active' is set or the pointer
; to the window was set with the call, then put the new image in the
; specified window

if ((uval.newwin_active eq 1) or (ptr_valid(uval.p_curwin) eq 0)) then begin
    ; if this is an unraveled cube, don't make the window active
    if (uval.unravel eq 0) then begin
        ql_make_window_active, conbase_id, p_WinObj
    endif else begin
        widget_control, conbase_id, get_uval=uval
        uval.unravel=0
        widget_control, conbase_id, set_uval=uval
    endelse
endif else begin
    if ((uval.newwin_active eq 0) and (uval.newwin eq 0) and (make_new_win eq 0)) then begin
        ql_make_window_active, conbase_id, p_WinObj
    endif
endelse

; get the active window parameters
widget_control, conbase_id, get_uval=uval
if ptr_valid(current_actwin) then begin
    ; checks to see if the object is valid, and makes sure that object
    ; is of the class 'CImWin'
    if obj_valid(*current_actwin) then begin
        if obj_isa(*current_actwin, 'CImWin') then begin
            activewin_obj=*current_actwin
            activewin_obj->GetActiveWindowParams
        endif
    endif
endif

; if designated, replace the image window parameters with the active
; window parameters
activeparams_set=0

if (uval.newwin_defaults eq 1) then begin
    if (ptr_valid(current_actwin)) then begin
        ; checks to see if the object is valid, and makes sure that object
        ; is of the class 'CImWin'
        if obj_valid(*current_actwin) then begin
            if obj_isa(*current_actwin, 'CImWin') then begin
                imwin_obj->SetResetZ, 0
                imwin_obj->SetActiveWindowParams
                activeparams_set=1
            endif 
        endif 
    endif 
endif

; reset the draw parameters
widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
imwin_uval.box_pres=0
imwin_uval.circ_strehl_pres=0
imwin_uval.circ_phot_pres=0
imwin_uval.diag_pres=0
imwin_uval.box_p0=[0,0]
imwin_uval.box_p1=[0,0]
imwin_uval.diagonal_box_p0=[0,0]
imwin_uval.diagonal_box_p1=[0,0]
imwin_uval.draw_box_p0=[0,0]
imwin_uval.draw_box_p1=[0,0]
imwin_uval.draw_diagonal_box_p0=[0,0]
imwin_uval.draw_diagonal_box_p1=[0,0]
imwin_uval.phot_circ_x=0
imwin_uval.phot_circ_y=0
imwin_uval.strehl_circ_x=0
imwin_uval.strehl_circ_y=0
imwin_uval.draw_circ_x=0
imwin_uval.draw_circ_y=0
widget_control, imwin_obj->GetBaseId(), set_uval=imwin_uval
; set the extension droplist value
widget_control, imwin_uval.wids.extension_list, set_droplist_select=extension

; update the display in the window
; tell the window this is a new image
if (uval.newwin eq 1) then begin
    widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
    imwin_uval.new_image=1
    widget_control, imwin_obj->GetBaseId(), set_uval=imwin_uval
endif

if (activeparams_set) then begin
    ; get the correct axis orientation
    axesorder=imwin_obj->GetAxesOrder()
    im_zs=im->GetZS()
    if (im_zs le 1) then begin
        imwin_obj->SetNAxis, 2
        if (axesorder[2] ne 2) then begin
            axesorder=indgen(3)
            imwin_obj->SetAxesOrder, axesorder
            imwin_obj->UpdateImParam, p_ImObj
            widget_control, imwin_uval.wids.cube_base, sensitive=0
        endif else begin
            widget_control, imwin_uval.wids.xdim_list, set_droplist_select=axesorder[0]
            widget_control, imwin_uval.wids.ydim_list, set_droplist_select=axesorder[1]
            widget_control, imwin_uval.wids.cube_base, sensitive=0
        endelse
    endif else begin
        imwin_obj->SetNAxis, 3
        imwin_obj->SetAxesOrder, axesorder
        widget_control, imwin_uval.wids.xdim_list, set_droplist_select=axesorder[0]
        widget_control, imwin_uval.wids.ydim_list, set_droplist_select=axesorder[1]
        widget_control, imwin_uval.wids.cube_base, sensitive=1
     endelse
    imwin_obj->UpdateText
    ; jlyke added UpdateDispIm 2020-Apr-09 to preserve image flip if needed
    imwin_obj->UpdateDispIm
    imwin_obj->DrawImage
endif else begin
    im_zs=im->GetZS()
    if (im_zs gt 1) then begin
        widget_control, imwin_uval.wids.cube_base, sensitive=1
        widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
        ;; if the image is a cube, then open with the 2nd axis vs. the 3rd axis

        ;; check to see the fits header which axis is the
        ;; spatial and which are the spectral dimension.
        ;; OSIRIS has [wavelenght, ra, dec], but most
        ;; other IFUs use [ra, dec, wavelength] - T. Do
        dim1 = sxpar(hd, 'CTYPE1')
        if dim1 eq 'RA---TAN' then begin
           print, 'The file '+filename+' has RA as its first axis. This is likely  not OSIRIS data. Loading axess order [0,1,2] instead.'
           axesorder = [0, 1, 2]
        endif else begin
           axesorder = [2, 1, 0]
        endelse

        ;axesorder=[2,1,0]
        imwin_obj->SetNAxis, 3
        imwin_obj->SetAxesOrder, axesorder
        widget_control, imwin_uval.wids.xdim_list, set_droplist_select=axesorder[0]
        widget_control, imwin_uval.wids.ydim_list, set_droplist_select=axesorder[1]
        widget_control, imwin_uval.wids.cube_base, sensitive=1
    endif else begin
        ; if image is 2D (zsize=1), then make the cube controls insensitive
        imwin_obj->SetNAxis, 2
        imwin_obj->UpdateImParam, p_ImObj
        widget_control, imwin_uval.wids.cube_base, sensitive=0
        widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
        widget_control, imwin_uval.wids.cube_range_button, set_button=1
        widget_control, imwin_uval.wids.cube_slice_box, set_value=1
        widget_control, imwin_obj->GetBaseId(), set_uval=imwin_uval
        imwin_obj->SetBoxCar, 1
    endelse
    imwin_obj->SetResetZ, 1
    imwin_obj->SetDoAutoScale, 1
    imwin_obj->UpdateZooms
    imwin_obj->UpdateDispIm
    ; check the config file to see if we're supposed to display as
    ; DN/s or Total DN
    if ptr_valid(uval.cconfigs_ptr) then begin
        if obj_valid(*uval.cconfigs_ptr) then begin
            if obj_isa(*uval.cconfigs_ptr, 'CConfigs') then begin
                cconfigs=*(uval.cconfigs_ptr)
                des=cconfigs->GetDisplayAsDN() 
            endif else begin
                des=['As DN/s']
            endelse
        endif else begin
            des=['As DN/s']
        endelse
    endif else begin
        des=['As DN/s']
    endelse

    if ((des ne 'As Total DN') and (des ne 'As DN/s')) then begin
        des=['As DN/s']
    endif

    if (des eq 'As DN/s') then begin
        imwin_obj->SetCurrentDisplay, 'As DN/s'
        widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
        imwin_uval.current_display_skip=1
        widget_control, imwin_obj->GetBaseId(), set_uval=imwin_uval
    endif else begin
        imwin_obj->SetCurrentDisplay, 'As Total DN',/update
        ;imwin_obj->SetCurrentDisplayUpdate, 1 ; MDP redundant
    endelse
endelse

; update the feature filenames
widget_control, imwin_obj->GetBaseId(), get_uval=imwin_uval
im_obj=*(imwin_obj->GetImObj())

if (imwin_uval.exist.statistics ne 0L) then begin
widget_control, imwin_uval.exist.statistics, get_uval=stat_uval
widget_control, stat_uval.wids.filename_id, set_value='Filename: '+im_obj->GetFilename()

endif

; see if the itime keyword exists here
if hd[0] ne '' then begin
    itime=sxpar(hd, 'TRUITIME')
    imwin_obj->SetDefItime, itime
endif else begin
    itime=1.
    imwin_obj->SetDefItime, itime
endelse

; if so, set the member variable
if (imwin_uval.exist.photometry ne 0L) then begin
widget_control, imwin_uval.exist.photometry, get_uval=phot_uval
widget_control, phot_uval.wids.filename_id, set_value='Filename: '+im_obj->GetFilename()
widget_control, phot_uval.wids.itime_id, set_val=strtrim(itime,2)
endif

if (imwin_uval.exist.strehl ne 0L) then begin
widget_control, imwin_uval.exist.strehl, get_uval=strehl_uval
widget_control, strehl_uval.wids.filename_id, set_value='Filename: '+im_obj->GetFilename()
endif

if (imwin_uval.exist.gaussian ne 0L) then begin
widget_control, imwin_uval.exist.gaussian, get_uval=gauss_uval
widget_control, gauss_uval.wids.filename_id, set_value='Filename: '+im_obj->GetFilename()
endif

; i don't think you want to change the .fits header filename, unless
; the user reopens the header for the newly displayed image

;if (imwin_uval.exist.fitshedit ne 0L) then begin
;widget_control, imwin_uval.exist.fitshedit, get_uval=fits_uval
;widget_control, fits_uval.wids.filename, set_value='Filename: '+im_obj->GetFilename()
;endif

if (imwin_uval.exist.plot ne 0L) then begin
widget_control, imwin_uval.exist.plot, get_uval=plot_uval
widget_control, plot_uval.wids.filename_id, set_value='Filename: '+im_obj->GetFilename()
endif 

; do not to update the plot window.  instead just leave the previously displayed plot
; update the plot window if it exists
;if (imwin_uval.exist.plot ne 0L) then begin
;    widget_control, imwin_uval.exist.plot, get_uval=plot_uval
;    plot=*plot_uval.self_ptr
;    widget_control, plot_uval.wids.plot_type_menu, set_droplist_select=droplist_select
;    plot->DrawPlot
;endif

end
