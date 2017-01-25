pro ql_closewindows, conbase_id

widget_control, conbase_id, get_uval=uval

if ptr_valid(uval.current_imwins) then begin
    ; get the array of imwin pointers
    current_imwins=*(uval.current_imwins)
    n_imwins=n_elements(current_imwins)

    for i=0,n_imwins-1 do begin
        imwin=*(current_imwins[i])
        curimwin_id=imwin->GetBaseId()
        cimwin_close, curimwin_id
    endfor
endif

end
