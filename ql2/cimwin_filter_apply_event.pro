pro cimwin_filter_apply_event, event

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

; osiris k properties
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

; save the filter mapped onto the osiris grid
*filter_uval.plot_info.filter_data_ptr=filter_csamp

; get the image parameters

widget_control, event.top, set_uval=filter_uval

;plot, filter_data[0,*], filter_data[1,*]

; 2. do the matrix multiplication
; 3. display the new image

self=*base_uval.self_ptr
im=*(self->GetImObj())

end
