pro osiris_openfiles, filenames, conbase_id

; get the cconfigs pointers
widget_control, conbase_id, get_uval=conbase_uval
cconfigs_obj=*(conbase_uval.cconfigs_ptr)
dir_polling=1

new_files=*(cconfigs_obj->GetNewFiles())

if new_files[0] ne '' then begin
    n_new_files=n_elements(new_files)
    for i=0,n_new_files-1 do begin
        widget_control, conbase_id, get_uval=win_uval
        ; store filename
        win_uval.last_file=new_files[i]
        ; update conbase uval
        widget_control, conbase_id, set_uval=win_uval
        ; check to see if the FITS to open has any extensions
        fits_info, new_files[i], n_ext=n_ext_check, /silent
        if (n_ext_check ne 0) then begin
            extension=0
            ql_openfile, conbase_id, new_files[i], extension, dir_polling=dir_polling
        endif else begin
            ql_openfile, conbase_id, new_files[i], dir_polling=dir_polling
        endelse
        if (dir_polling eq 1) then begin
            ; remove this file from the configs new files array
            cconfigs_obj->RemoveNewFile, new_files[i]
        endif
    endfor
endif

end
