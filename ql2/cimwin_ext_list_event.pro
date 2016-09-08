pro cimwin_ext_list_event, event

widget_control, event.top, get_uval=cimwin_uval

select_index=widget_info(event.id, /droplist_select)

print, select_index

ext_arr=*(cimwin_uval.p_ext_arr)
selection=ext_arr[select_index]

self=*(cimwin_uval.self_ptr)
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr

; checks to see if the menu selection starts with 'Extension'
ext_check=strmid(selection,0,9)

if (ext_check eq 'Extension') then begin
    ext_no=strmid(selection,10,3)
    conbase_id=self->GetParentBaseId()
    filename=ImObj->GetPathFilename()
    ext_int=fix(ext_no)
    ql_openfile, conbase_id, filename, ext_int
    return
endif else begin
    conbase_id=self->GetParentBaseId()
    filename=ImObj->GetPathFilename()
    ql_openfile, conbase_id, filename
endelse

end
