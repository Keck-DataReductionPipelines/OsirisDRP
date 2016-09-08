; +
; NAME: ql_getfilename
;
; PURPOSE: pass in a path + filename and have returned only the filename
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

function ql_getfilename, path_n_filename

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

; find the length of the string
str_length=strlen(path_n_filename)

; extract the filename without the path
filename_only=strmid(path_n_filename,last_slash+1,str_length)

return, filename_only

end
