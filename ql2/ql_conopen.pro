; +
; NAME: ql_conopen
;
; PURPOSE: lets the user pick a filename from a directory, makes a pointer
; to that filename, and then calls ql_display_new_image
;
; CALLING SEQUENCE: ql_conopen, parentbase_id
;
; INPUTS: conbase_id (long) - widget id of the control base
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 17DEC2002 - MWM: added comments.
; -

pro ql_conopen, conbase_id

; get conbase uval
widget_control, conbase_id, get_uvalue=win_uval

; store old current data directory
new_path=win_uval.current_data_directory

; check to make sure that the current data directory exists
tst=ql_file_search(win_uval.current_data_directory, dir=1)

if (tst eq '') then begin
    cd, current=cur
    win_uval.current_data_directory=cur
endif

; sets the last file picked to the current data directory
win_uval.last_file=win_uval.current_data_directory
if (win_uval.current_os = 'WIN') then win_uval.last_file=''

; lets you pick a file from the directory
path_file=dialog_pickfile(dialog_parent=conbase_id, $
                     path=win_uval.current_data_directory, $
                     filter='*.fits', get_path=new_path, $
                     file=win_uval.last_file)

; make sure a file was selected, and cancel wasn't pressed
if path_file ne '' then begin

    ; check the permissions on the path+filename
    check_read=file_test(path_file, /read)

    if (check_read eq 1) then begin
        ; make sure the user specified a file
        filename=ql_getfilename(path_file)

        if ((filename ne '') and ((ql_file_search(path_file))[0] ne '')) then begin
            ; make the new path_file with the result from find_search
            path_file=(ql_file_search(path_file))[0]
            print, 'the path_file name is ', path_file
            ; store filename
            win_uval.last_file=path_file
            ; set default pickfile directory to directory selected file was in
            win_uval.current_data_directory=new_path
            ; update conbase uval
            widget_control, conbase_id, set_uval=win_uval
            ; check to see if the FITS to open has any extensions
            fits_info, path_file, n_ext=n_ext_check, /silent
            if (n_ext_check gt 0) then begin
                extension=0
                ql_openfile, conbase_id, path_file, extension
            endif else begin
                ql_openfile, conbase_id, path_file
            endelse
        endif else begin
            message=['Please make sure you select a valid filename.']
            answer=dialog_message(message, dialog_parent=conbase_id, /error)
            ql_conopen, conbase_id
        endelse
    endif else begin
            message=['Please make sure you have read permissions on this file.']
            answer=dialog_message(message, dialog_parent=conbase_id, /error)        
    endelse
endif

; keep track of the memory history


end
