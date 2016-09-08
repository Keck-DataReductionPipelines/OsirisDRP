; +
; NAME: osiris_testserver
;
; PURPOSE: 
;
; CALLING SEQUENCE: osiris_testserver, conbase_id
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
; REVISION HISTORY: 11SEP2004 - MWM: wrote this function
; -

function osiris_testserver, conbase_id

; keywords used in this function
lastalive_kw='lastalive'    ; keyword set to string when the server
                            ; was last alive

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
    testserver=show(cpolling_obj->GetServerName()+'.'+lastalive_kw)
    return, 0
endif else begin
    print, 'There was an error testing the server'
    return, -1
endelse

end
