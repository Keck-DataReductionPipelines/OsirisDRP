; +
; NAME: osiris_getfilename
;
; PURPOSE: 
;
; CALLING SEQUENCE: osiris_getfilename, conbase_id
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

function osiris_getfilename, conbase_id

; keywords used in this function
lastfile='slastfile'   ; keyword set to the path of the 
                      ; most recent written file

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

; the list of files needing to be opened
new_files_ptr=cconfigs_obj->GetNewFiles()
new_files=*new_files_ptr

if (error_status eq 0) then begin
    if (cpolling_obj->GetPollingStatus() eq 1) then begin
        ; check the last file keyword to get the filename
        server_file=show(cpolling_obj->GetServerName()+'.'+lastfile)
        ; make a new array with all the files to be opened
        if (new_files[0] eq '') then begin
            new_files=server_file
        endif else begin
            new_files=[[new_files], [server_file]]
        endelse
        *new_files_ptr=new_files
    endif
    return, new_files
endif else begin
    print, 'There was an error with the SHOW in GetFilename'
    return, 'error'
endelse

end
