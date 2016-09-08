; +
; NAME: ql_getpath
;
; PURPOSE: pass in a path + filename and have returned only the path
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 01OCT2004 - MWM: wrote function
; -

function ql_getpath, path_n_filename

; determine searching technique based on platform
case !version.os_family of
	'unix': begin
            last_slash=strpos(path_n_filename, '/', /reverse_search)
	end
	'Windows':  begin
            last_slash=strpos(path_n_filename, '\', /reverse_search)
        end
	'vms':
	'macos':
	else: begin
		print, 'OS ', !version.os_family, 'not recognized.'
		exit
	end
endcase

; extract the path without the filename
path_only=strmid(path_n_filename,0,last_slash+1)

return, path_only

end
