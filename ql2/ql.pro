; +
; NAME: ql
;
; PURPOSE: main ql program
;
; CALLING SEQUENCE: ql, [filename, /xwin]
;
; INPUTS: 
;
; OPTIONAL INPUTS: filename - the path and filename of the file being
;                             displayed.
; 
; OPTIONAL KEYWORD INPUTS: /xwin is used to determine window backing.
;
; EXAMPLE:
;
; NOTES: takes in params, sets win backing and directory search paths,
;         and launches ql base program
;
; PROCEDURES USED:
;
; REVISION HISTORY: 16DEC2002 - MWM: added comments.
; - 

pro ql, filename, xwin=xwin, configs=configs

; sets window backing to 0 if the switch is not turned on, used later
if not keyword_set(xwin) then xwin=0

; adds the reduce/ directory to the search path  
!path=!path+':reduce:'

; identify operating system
current_os=!version.os_family

; calls ql_conbase and passes the appropriate parameters
if n_params() lt 1 then $
	ql_conbase, current_os=current_os, xwin=xwin, configs=configs $
; if a filename is set, then pass that name to conbase for opening
else ql_conbase, filename=filename, current_os=current_os, xwin=xwin, configs=configs

end
