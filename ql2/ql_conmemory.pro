; +
; NAME: ql_conmemory
;
; PURPOSE: writes the memory usage history to a file
;
; CALLING SEQUENCE: ql_conmemory, parentbase_id
;
; INPUTS: conbase_id (long) - widget id of the control base
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
; NOTES: called by ql_conmenu_event
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 30JUN2005 - MWM: wrote procedure
; - 

pro ql_conmemory, conbase_id

widget_control, conbase_id, get_uval=uval

memory_usage=*uval.memory_ptr
memory_length=n_elements(memory_usage)

; open a file in the user's home directory to output the memory usage
; store old current data directory
new_path=uval.current_data_directory

; sets the last file picked to the current data directory
uval.last_file=uval.current_data_directory
if (uval.current_os = 'WIN') then uval.last_file=''

; lets you pick a file from the directory
path_file=dialog_pickfile(dialog_parent=conbase_id, $
                     path=uval.current_data_directory, $
                     get_path=new_path, $
                     file=uval.last_file, /write)

; make sure a file was selected, and cancel wasn't pressed
if path_file ne '' then begin
    ; check to see if the file exists
    check_read1=file_test(path_file)
    if (check_read1) then begin
        ; check the permissions on the path+filename
        check_read2=file_test(path_file, /write)
        if (check_read2) then begin
            get_lun, u
            openu, u, path_file
            ; write the contents to this file
            for i=0,memory_length-1 do begin
                printf, u, memory_usage[i]
            endfor
            free_lun, u
        endif else begin
            message=['Please make sure you have write permissions on this file.']
            answer=dialog_message(message, dialog_parent=conbase_id, /error)        
            return
        endelse
    endif else begin
        path=ql_getpath(path_file)
        ; check to make sure the directory exists
        check_read3=file_test(path, /directory, /write)
        if (check_read3) then begin
            get_lun, u
            openw, u, path_file
            ; write the contents to this file
            for i=0,memory_length-1 do begin
                printf, u, memory_usage[i]
            endfor
            free_lun, u            
        endif else begin
            message=['Please make sure you have write permissions on this directory.']
            answer=dialog_message(message, dialog_parent=conbase_id, /error)        
            return
        endelse
    endelse
endif

end
