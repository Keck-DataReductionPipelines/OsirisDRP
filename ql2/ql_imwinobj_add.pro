pro ql_imwinobj_add, conbase_id, imwin_ptr

widget_control, conbase_id, get_uval=conbase_uval
tmp_ptr=conbase_uval.current_imwins

if ptr_valid(tmp_ptr) then begin
    ; checks to see if the object is valid, and makes sure that object
    ; is of the class 'CImWin'
    tmp_arr=*tmp_ptr
    if obj_valid(*tmp_arr[0]) then begin
        if obj_isa(*tmp_arr[0], 'CImWin') then begin
            ntmp_arr=[[tmp_arr],[imwin_ptr]]
            ntmp_ptr=ptr_new(ntmp_arr)
        endif
    endif 
endif else begin
    ntmp_ptr=ptr_new(imwin_ptr)
endelse

ptr_free, tmp_ptr
conbase_uval.current_imwins=ntmp_ptr
widget_control, conbase_id, set_uval=conbase_uval

end
