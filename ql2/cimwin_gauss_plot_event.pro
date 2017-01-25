pro cimwin_gaussplot_quit_event, event

widget_control, event.top, get_uval=gplot_uval
widget_control, gplot_uval.gauss_id, get_uval=gauss_uval
gauss_uval.exist.plotwin=0L
widget_control, gplot_uval.gauss_id, set_uval=gauss_uval

widget_control, event.top, /destroy

end

pro cimwin_zleft_button_event, event

; get widget uvals for all levels
widget_control, event.top, get_uval=uval
widget_control, uval.gauss_id, get_uval=gauss_uval
widget_control, gauss_uval.base_id, get_uval=base_uval

; change the plot angle in the uval
gauss_uval.plot_info.plot_ang=gauss_uval.plot_info.plot_ang-5

; update the uval
widget_control, uval.gauss_id, set_uval=gauss_uval

; call the plot routine
(*base_uval.self_ptr)->GaussPlot, uval.gauss_id

end

pro cimwin_zright_button_event, event

; get widget uvals for all levels
widget_control, event.top, get_uval=uval
widget_control, uval.gauss_id, get_uval=gauss_uval
widget_control, gauss_uval.base_id, get_uval=base_uval

; change the plot angle in the uval
gauss_uval.plot_info.plot_ang=gauss_uval.plot_info.plot_ang+5

; update the uval
widget_control, uval.gauss_id, set_uval=gauss_uval

; call the plot routine
(*base_uval.self_ptr)->GaussPlot, uval.gauss_id

end

pro cimwin_gauss_plot_event, event

widget_control, event.top, get_uval=gauss_uval
widget_control, gauss_uval.base_id, get_uval=base_uval

; if the gaussian plot widget does not exist, then create it 
if (gauss_uval.exist.plotwin eq 0L) then begin

    ; set the gauss plot window size
    x_size = 512
    y_size = 512

    ; Create widgets
    base = widget_base(TITLE = 'Peak Fit Plot', group_leader=event.top, /col)
    draw_base=widget_base(base, /row)
    draw1=widget_draw(draw_base, xs=x_size, ys=y_size, $
                      retain=base_uval.win_backing)
    draw2=widget_draw(draw_base, xs=x_size, ys=y_size, $
                      retain=base_uval.win_backing)
    button_base=widget_base(base, /row)
    zleft_button=widget_button(button_base, value="Rotate Left")
    zright_button=widget_button(button_base, value="Rotate Right")
    quit_button=widget_button(base, value="Quit")

    ; set_uval
    uval={gauss_id:event.top}

    ; Realize widgets and assign window id's
    widget_control, base, /realize
    widget_control, draw1, get_value=draw1_idx
    widget_control, draw2, get_value=draw2_idx

    ; Store the draw base id in the gauss window uval
    gauss_uval.draw1_idx=draw1_idx
    gauss_uval.draw2_idx=draw2_idx

    ; Update the gauss base uval
    widget_control, base, set_uval=uval
    widget_control, event.top, set_uval=gauss_uval

    xmanager, 'CImWin_GaussPlot_Quit', quit_button, /just_reg, /no_block
    xmanager, 'CImWin_ZLeft_Button', zleft_button, /just_reg, /no_block
    xmanager, 'CImWin_ZRight_Button', zright_button, /just_reg, /no_block

    ; register existence of base
    gauss_uval.exist.plotwin=base
    (*base_uval.self_ptr)->GaussPlot, event.top
    widget_control, uval.gauss_id, set_uval=gauss_uval

endif else begin
    ; or show the existing gaussian plot widget if it does exist
    widget_control, gauss_uval.exist.plotwin, /show
    (*base_uval.self_ptr)->GaussPlot, event.top

endelse

end
