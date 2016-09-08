pro ql_refresh_all, conbase_id

widget_control, conbase_id, get_uval=uval

; get the array of imwin pointers
if ptr_valid(uval.current_imwins) then begin
    current_imwins=*(uval.current_imwins)
    n_imwins=n_elements(current_imwins)

    for i=0,n_imwins-1 do begin
        imwin=*(current_imwins[i])
        imwin->DrawImage
    endfor
endif

end
