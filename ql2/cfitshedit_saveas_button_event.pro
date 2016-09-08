pro cfitshedit_saveas_button_event, event

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

; get new filename
file=dialog_pickfile(/write, group=event.top, filter='*.fits', file=filename)

; if cancel was not hit
if file ne '' then begin
    ; check the permissions on the path
    path=ql_getpath(file)
    permission=ql_check_permission(path)    
    if (permission eq 1) then begin
        ; write the image to disk
        writefits, file, im, hd
        ; reset image filename
        ImObj->SetFilename, file
        ; update window title
        widget_control, uval.base_id, tlb_set_title=file
        ; set file not modified
        uval.modified=0
        ; set uval
        widget_control, event.top, set_uval=uval
        if (file eq filename) then begin
            print, 'file is equal to filename'
            ; update the header in the ImObj
            ImObj->SetHeader, uval.hd_ptr
        endif
    endif else begin
                err=dialog_message(['Error writing .fits header.', 'Please check path permissions.'], $
                                   dialog_parent=event.top, /error)
    endelse
endif

end
