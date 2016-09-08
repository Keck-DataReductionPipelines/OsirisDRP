; +
; NAME: ql_check_permission
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_check_permission, path
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
; REVISION HISTORY: 15APR2005 - MWM: wrote this function
; -

function ql_check_permission, path

; see if the path exists
path_exist=ql_file_search(path)
if (path_exist eq '') then begin
    print, 'The specified path does not exist.'    
    return, -1
endif

; set up a catch to make sure there isn't a problem when
; trying to write to the path
catch, error_status

;This statement begins the error handler:
if error_status ne 0 then begin
    print, 'Error index: ', error_status
    print, 'Error message: ', !ERROR_STATE.MSG
endif

if (error_status eq 0) then begin
   ; get the current directory
    cd, '.', current=cur   
    cd, path
 
    ; write a tmp file to the path
    tmp=fltarr(10,10)
    writefits, 'bdtmpfile12345678.fits', tmp

endif else begin
    print, 'There was a problem writing to the specified path.'
    cd, cur
    return, -1
endelse

; find out what operating system is running
case !version.os_family of
    'unix': rmcmd='rm -f '+path+'/bdtmpfile12345678.fits'
    'Windows': rmcmd='del '+path+'\bdtmpfile12345678.fits'
    'vms': rmcmd=''
    'macos': rmcmd='rm -f '+path+'/bdtmpfile12345678.fits'
    else:
endcase

; remove file if successfully written
spawn, rmcmd

; return to the current working directory
cd, cur

return, 1

end

