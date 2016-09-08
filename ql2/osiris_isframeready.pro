; +
; NAME: osiris_isframeready
;
; PURPOSE: 
;
; CALLING SEQUENCE: osiris_isframeready, conbase_id
;
; INPUTS:
;
; OPTIONAL INPUTS: 
;                  
;
; OPTIONAL KEYWORD INPUTS: 
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 09SEP2004 - MWM: wrote this function
; -

function osiris_isframeready, conbase_id

; keywords used in this function
frameready_kw='simagedone'    ; keyword set when a new image is
                             ; written to disk

; get the cpolling and cconfigs pointers
widget_control, conbase_id, get_uval=conbase_uval
cpolling_obj=*(conbase_uval.cpolling_ptr)
cconfigs_obj=*(conbase_uval.cconfigs_ptr)

; set up a catch to make sure there isn't a problem when
; trying to poll the server
catch, error_status

;This statement begins the error handler:
if error_status ne 0 then begin
    print, 'Error index: ', error_status
    print, 'Error message: ', !ERROR_STATE.MSG
endif

if (error_status eq 0) then begin
    if (cpolling_obj->GetPollingStatus() eq 1) then begin
        ; OSIRIS will open an image on server keyword transitions from 0 -> 1
        cur_imagedone=show(cpolling_obj->GetServerName()+'.'+frameready_kw)
        if (cconfigs_obj->GetTransition() eq 0) and (cur_imagedone eq 1) then begin
            cconfigs_obj->SetTransition, cur_imagedone
            return, cconfigs_obj->GetTransition()
        endif
        cconfigs_obj->SetTransition, cur_imagedone
    endif

    if (cpolling_obj->GetDirectoryPollingStatus() eq 1) then begin

        ; get the new files member variable to add the new ones to thisc
        ; existing list
        new_files_ptr=cconfigs_obj->GetNewFiles()
        new_files=*new_files_ptr

        ; Check to see if the polling directory has changed
;        file_check=(cpolling_obj->GetDirectoryName())
        file_check=(cpolling_obj->GetDirectoryName())+'/*.fits'
        newdir_arr=ql_file_search(file_check)
        newdir_cnt=n_elements(newdir_arr)-1

        ; get the old directory .fits listing
        olddir_arr_ptr=cconfigs_obj->GetDirArr()
        olddir_arr=*(olddir_arr_ptr)

        ; compare the two lists and find which items are new
        for i=0,newdir_cnt do begin        
            match=where(newdir_arr[i] eq olddir_arr[*])
            if (match eq -1) then begin
                if (new_files[0] eq '') then begin
                    new_files=newdir_arr[i]
                endif else begin
                    new_files=[[new_files], [newdir_arr[i]]]
                endelse
            endif
        endfor
        ; set the old directory array to the new directory array
         *(olddir_arr_ptr)=newdir_arr

        ; set the new files to open in the polling member variable
         *new_files_ptr=new_files

        if (new_files[0] ne '') then return, 1 

    endif
    
    ; return 0 if you haven't already returned
    return, 0

endif else begin
    print, 'There was an error with the SHOW in IsFrameReady'
    return, -1
endelse

end

