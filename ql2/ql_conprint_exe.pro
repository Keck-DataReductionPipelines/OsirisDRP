pro ql_conprint_exe, conbase_id, filename

widget_control, conbase_id, get_uval=uval

;check printer existence
lpq_command=strcompress('lpq -P'+uval.printer_name)
spawn, lpq_command, result

if result[0] eq '' then begin
    answer=dialog_message(['Printer queue: ', uval.printer_name, $
         'not found.'], dialog_parent=ns_display_base_id, /error)
endif else begin
    ; print it!
    print, 'Printing on ', uval.printer_name
    command=strcompress('lpr -P'+uval.printer_name+' '+filename)
    print, command
    spawn, command, result
    ; if error (actually, i don't think result is ever not '', but in case...)
    if result[0] ne '' then begin
        answer=dialog_message(result, dialog_parent=conbase_id, $
                                  /error)
    endif

endelse

; remove file
remove_command='\rm '+filename
spawn, remove_command

end
