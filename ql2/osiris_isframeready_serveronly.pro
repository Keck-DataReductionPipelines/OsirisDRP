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
; OSIRIS will open an image on transitions from 0 -> 1
    cur_imagedone=show(cpolling_obj->GetServerName()+'.'+frameready_kw)

    if (cconfigs_obj->GetTransition() eq 0) and (cur_imagedone eq 1) then begin
        cconfigs_obj->SetTransition, cur_imagedone
        return, cconfigs_obj->GetTransition()
    endif

    cconfigs_obj->SetTransition, cur_imagedone
    return, 0
endif else begin
    print, 'There was an error with the SHOW in IsFrameReady'
    return, -1
endelse

end

