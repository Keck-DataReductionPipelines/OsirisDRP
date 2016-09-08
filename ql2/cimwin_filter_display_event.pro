pro cimwin_digital_filter_quit_event, event

widget_control, event.top, /destroy

end

pro cimwin_filter_display_event, event

widget_control, event.top, get_uval=filter_uval
widget_control, filter_uval.base_id, get_uval=base_uval
widget_control, filter_uval.wids.file, get_value=filename1

if (ql_file_search(filename1[0]))[0] ne '' then begin $
  openr, Unit, filename1[0], /GET_LUN
    i=0
    a=0.d
    b=0.d

    readf, Unit, a, b
    filter_data=[[a,b]]

    while not EOF(Unit) do begin
        readf, Unit, a, b
        filter_data=[[filter_data],[a,b]]
        i=i+1
    endwhile
endif else begin
    message='Could not find filter file: '+filter_file
endelse

; number of data lines read
n_data_samples=i

; interpolate the data
; make an array simulating the k spectral sampling per channel

; osiris properties
osiris_start_lambda=1.96  ; starting wavelength in microns
osiris_end_lambda=2.4
osiris_dispersion=0.00029    ; linear dispersion across the chip
n_osiris_slices= $        ; number of osiris slices = 1517
  floor((osiris_end_lambda-osiris_start_lambda)/osiris_dispersion)

k_sample=findgen(n_osiris_slices)*osiris_dispersion+osiris_start_lambda

filter_csamp=dblarr(2,n_osiris_slices)
filter_csamp[0,*]=k_sample[*]

for k=0.,n_osiris_slices-1 do begin
    if ((filter_csamp[0,k] lt filter_data[0,0]) OR $
        (filter_csamp[0,k] gt filter_data[0,n_data_samples-1])) then begin
        filter_csamp[1,k]=0
    endif else begin
        filter_csamp[1,k]=interpol(filter_data[1,*], filter_data[0,*], $
                             filter_csamp[0,k])
    endelse
endfor    

*filter_uval.plot_info.filter_csamplambda_ptr=filter_csamp[0,*]
*filter_uval.plot_info.filter_csamptrans_ptr=filter_csamp[1,*]

*filter_uval.plot_info.filter_lambda_ptr=filter_data[0,*]
*filter_uval.plot_info.filter_trans_ptr=filter_data[1,*]

widget_control, event.top, set_uval=filter_uval

dimensions=get_screen_size()

; set the filter plot window size
x_size = dimensions[0]/2
y_size = dimensions[1]/2

; Create widgets
base = widget_base(TITLE = 'Digital Filter Plot', group_leader=base_id, /col)
draw_base=widget_base(base, /row)
draw1=widget_draw(draw_base, xs=x_size, ys=y_size, retain=2)
button_base=widget_base(base, /row)
quit_button=widget_button(base, value="Quit")

; set_uval
uval={filterplot_id:event.top, $ 
      base_id:filter_uval.base_id}

; Realize widgets and assign window id's
widget_control, base, /realize
widget_control, draw1, get_value=draw1_idx

; Store the draw base id in the gauss window uval
filter_uval.draw1_idx = draw1_idx

; Update the digital filter uval

widget_control, event.top, set_uval=filter_uval
widget_control, filter_uval.base_id, set_uval=base_uval

xmanager, 'CImWin_Digital_Filter_Quit', quit_button, /just_reg, /no_block

(*base_uval.self_ptr)->FilterPlot, event.top

end
