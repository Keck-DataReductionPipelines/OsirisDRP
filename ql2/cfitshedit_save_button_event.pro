pro cfitshedit_save_button_event, event

; get uval struct
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval

CImWin_Obj=*(cimwin_uval.self_ptr)

; get image object
ImObj_ptr=CImWin_Obj->GetImObj()
ImObj=*ImObj_ptr

; get the image and header
filename=ImObj->GetPathFilename()
im_ptr=ImObj->GetData()
im=*im_ptr
hd=*(uval.hd_ptr)

; check the permissions on the path
path=ql_getpath(filename)
permission=ql_check_permission(path)    
if (permission eq 1) then begin
    ; write the image to disk
    writefits, filename, im, hd
    ; update the header in the ImObj
    ImObj->SetHeader, uval.hd_ptr
    ; set file not modified
    uval.modified=0
    ; set uval
    widget_control, event.top, set_uval=uval
endif else begin
                err=dialog_message(['Error writing .fits header.', 'Please check path permissions.'], dialog_parent=event.top, /error)
endelse

end
