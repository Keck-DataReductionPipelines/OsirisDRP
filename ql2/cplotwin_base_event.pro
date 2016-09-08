pro CPlotWin_Base_event, event

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
    cplotwin_close, event.top
endif else if tag_names(event, /structure_name) eq 'WIDGET_BASE' then begin
    ; resize events
    widget_control, event.top, get_uval=uval
    widget_control, uval.base_id, get_uval=main_base_uval
    self=*(uval.self_ptr)

    menu_ysize=0
    fudge_factor=40

    widbase_xsize=event.x
    widbase_ysize=event.y

    ; get the screen x and y sizes 
    scr_xsize = main_base_uval.scr_xsize
    scr_ysize = main_base_uval.scr_ysize

    ; plot type menu
    plot_menu_ysize=(get_widget_size(uval.wids.plot_type_menu))[1]

    ; calculate the size of the controls
    cntrl_ysize=(get_widget_size(uval.wids.bottom_base))[1]+plot_menu_ysize+menu_ysize

    ; calculate the maximum ysize of the image
    max_yimsize = scr_ysize - cntrl_ysize

    ; calculate the size of the image
    im_xsize = widbase_xsize
    im_ysize = widbase_ysize - cntrl_ysize - fudge_factor

    ; put constraints on the xsize of the image
    im_xsize = (32 > im_xsize < scr_xsize)

    ; put constraints on the xsize of the base
    ;new_base_xs = (im_xsize > (1.4*uval.initial_xs))

    ; put constraints on the ysize of the image
    im_ysize = (32 > im_ysize < max_yimsize)
    ; put constraints on the ysize of the base
    new_base_ys = im_ysize + cntrl_ysize

    ; set the size of the draw window in the wids 
    widget_control, uval.wids.draw, xsize=im_xsize
    widget_control, uval.wids.draw, ysize=im_ysize

    ; set the size of the draw window in the uval
    uval.xs = im_xsize
    uval.ys = im_ysize

    ; set the size of the draw window in the instance
    self->SetXS, im_xsize
    self->SetYS, im_ysize

    ; update the uval settings
    widget_control, event.top, xsize=new_base_xs, ysize=new_base_ys
    widget_control, event.top, set_uvalue = uval

    ; redraw image
    self->DrawPlot
endif else begin
	; for any other events, just refresh the drawing (e.g. if a setting widget
	; gets changed, then we should refresh.)
    ; redraw image
	widget_control, event.top, get_uval=uval
    self=*(uval.self_ptr)


    self->DrawPlot
endelse


end
