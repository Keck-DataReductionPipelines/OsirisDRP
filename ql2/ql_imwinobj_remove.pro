pro ql_imwinobj_remove, conbase_id, imwin_ptr

widget_control, conbase_id, get_uval=conbase_uval
;tmp_arr=*(conbase_uval.current_imwins)
tmp_ptr=conbase_uval.current_imwins

if ptr_valid(tmp_ptr) then begin
    tmp_arr=*tmp_ptr

    n_modes=size(tmp_arr, /n_elements)
    
    exist=where(tmp_arr[*] eq imwin_ptr)
    exist_index=long(exist[0])
    
    if (exist_index ne -1) then begin
        nimwin_arr=tmp_arr[0]
        cnt1=exist_index-1
        cnt2=exist_index+1
        print, 'adding first element'
        print, nimwin_arr
        print, 'exist= ', exist_index, 'cnt1 = ', cnt1, 'cnt2 = ', cnt2


        if ((exist_index ne 0) and (n_elements(tmp_arr) gt 1)) then begin
            ; add the elements prior to the mode you remove
            for i=1,cnt1 do begin
                nimwin_arr=[[nimwin_arr],[tmp_arr[i]]]
            endfor

            ; add the elements after to the mode you remove
            for i=cnt2,n_modes-1 do begin
                nimwin_arr=[[nimwin_arr],[tmp_arr[i]]]
            endfor
            *(conbase_uval.current_imwins)=nimwin_arr
            widget_control, conbase_id, set_uval=conbase_uval
        endif else begin
            ptr_free, tmp_ptr
            nimwin_arr=ptr_new()
            conbase_uval.current_imwins=nimwin_arr
            widget_control, conbase_id, set_uval=conbase_uval
        endelse
    endif
endif

end
