;+
; NAME:
;
;   QL_WRITECHECK
;
; PURPOSE:
;
;   This function checks for the existance of a file with the name that
;   is intended to be written. If it finds such a file, it interrogates
;   the user for whether to overwrite that file.  It returns 'Yes' or
;   'No' depending on whether or not the file write should proceed.
;
;
; CATEGORY:
;
;   Quicklook 2
;
; CALLING SEQUENCE:
;
;   result=ns_writecheck(error_dialog_parent, filename)
; 
; INPUTS:
;
;   ERROR_DIALOG_PARENT:  Widget ID to be parent of error dialog messages.
;
;   FILENAME:             Filename to check.
;
; OPTIONAL INPUTS:
;
;   None.
;
; KEYWORD PARAMETERS:
;
;   None.
;
; OUTPUTS:
;
;   A string is returned which is either 'Yes' or 'No' depending on
;   the status of the file with that name.
;
; OPTIONAL OUTPUTS:
;
;   None.
;
; COMMON BLOCKS:
;
;   None.
;
; SIDE EFFECTS:
;
;   None.
;
; RESTRICTIONS:
;
;   None.
;
; PROCEDURE:
;
;   Check name, and if a file exists, check to see if overwrite is okay.
;
; EXAMPLE:
;
;   result=ns_writecheck(error_dialog_parent, '~/data/example.fits')
;
; MODIFICATION HISTORY:
;
;   Feb 8, 2000: Jason Weiss -- Added this header, commented.
;   Mar 7, 2000: Jason Weiss -- Completely rewritten.
;-

function ql_writecheck, error_dialog_parent, filename

; get current dir
cd, current = olddir

; set default value
check_result='Yes'


; see if filename has invalid characters
test = str_sep(filename, ' ')
test = str_sep(test[0], '\')
test = str_sep(test[0], ';')
test = str_sep(test[0], '[')
test = str_sep(test[0], ']')
test = str_sep(test[0], '(')
test = str_sep(test[0], ')')
test = str_sep(test[0], "'")
test = str_sep(test[0], '"')
test = str_sep(test[0], '*')
test = str_sep(test[0], '&')
test = str_sep(test[0], '^')
test = str_sep(test[0], '|')
test = str_sep(test[0], '$')
test = str_sep(test[0], '!')
test = str_sep(test[0], '{')
test = str_sep(test[0], '}')
test = str_sep(test[0], '<')
test = str_sep(test[0], '>')
test = str_sep(test[0], '?')

if test[0] ne filename then begin
    wm = dialog_message('ERROR - Invalid filename.  Choose another.', $
                            /error, dialog_parent = error_dialog_parent)
    return, 'No'
endif

; if null filename, return 'NO'
IF filename eq '' THEN check_result='No' ELSE BEGIN

    ; break down name
    fdecomp, filename, disk, dir, name, qual

   ; make sure name is not empty i.e. filename is a directory
    if strcompress(name, /remove_all) eq '' then begin
        check_result = dialog_message([filename, 'is a directory!', $
          'Please enter a valid filename.'], dialog_parent=error_dialog_parent)
        return, 'No'
    endif

    ; check to see if directory exists
    dir_check=ql_file_search(dir)
    if dir_check[0] eq '' then begin
        ; could be just empty (ql_file_search will return null string for 
        ; existing empty directories)
 
        ; define error handling block
        catch, error_status
        ; what to do on error.
        if error_status ne 0 then begin
            check_result = dialog_message(['Cannot find directory!', dir, $
              'Create directory first'], dialog_parent=error_dialog_parent)
            return, 'No'
        endif            
        ; try to cd to directory...if the directory doesn't exist, 
        ; error will be handled by above if block.
        cd, dir
    endif
    
    ; check to see if file exists
    name_check=ql_file_search(filename)
    if name_check[0] ne '' then begin
        check_result = dialog_message([filename, 'exists.  Overwrite?'], $
              dialog_parent=error_dialog_parent, /question)
    endif
        
ENDELSE

; go back to old dir.
cd, olddir

RETURN, check_result

END
