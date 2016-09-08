; +
; NAME: ql_openfile
;
; PURPOSE: open a new file
;
; CALLING SEQUENCE: ql_conopen, conbase_id, filename
;
; INPUTS: conbase_id (long) - widget id of the control base
;         filename
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
; REVISION HISTORY: 13JUL2004 - MWM: added comments.
;  2007-07-03 MDP: Removed/simplified some redundant code
; -

pro ql_openfile, conbase_id, file, extension, dir_polling=dir_polling

widget_control, conbase_id, get_uval=conbase_uval
message=''

if n_elements(extension) eq 0 then extension=0

    ; creates a cimage instance of the file saved as im, then makes a
    ; pointer to that image
im=ql_create_cimage(conbase_id, file, extension,message=message)
    p_ImObj=ptr_new(im)

; checks to see if the object is valid, and makes sure that object
; is of the class 'CImage'
if obj_valid(im) then begin
    if obj_isa(im, 'CImage') then begin
        ; update recent file list
        ql_conupdate_recent_file_list, conbase_id, file
        ; update list of open image buffers
        ql_update_buffer_list, conbase_id, p_ImObj
        ; get conbase uval
        widget_control, conbase_id, get_uval=uval
        ; checks the preset value newwin to see if qlook2
        ; is supposed to make a new window, then calls
        ; the display function

        if (uval.newwin eq 0) then begin
			; display in current window
            ql_display_new_image, conbase_id, p_ImObj, $
              p_WinObj=uval.p_curwin, extension
        endif else begin
			; display in a NEW window
            ql_display_new_image, conbase_id, p_ImObj, extension
        endelse
        
    endif else begin
        ; issues an error message if obj_isa fails
        message=['Error reading file:', $
                 ' Error creating CImage object']
        answer=dialog_message(message, dialog_parent=$
                              conbase_id)
        ptr_free, p_ImObj    
        obj_destroy, im    
    endelse
endif else begin
    ; issues an error message if obj_valid fails and not polling
    if (arg_present(dir_polling) ne 1) then begin
        if (message eq '') then begin
        message=['Error reading file:', $
                 ' Error creating object']
        endif
        answer=dialog_message(message, dialog_parent=conbase_id)
        ptr_free, p_ImObj    
    endif else begin
        dir_polling=0
    endelse
endelse

end
