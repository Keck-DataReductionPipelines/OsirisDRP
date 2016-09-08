pro ql_load_inst_cfg, display_base_id

; get uval
widget_control, display_base_id, get_uval=uval

print, 'ql_load_inst_cfg'

; get filename
;path=strcompress(uval.qlook_dir+'/config', /remove_all)
;file=dialog_pickfile(filter="*_cfg.pro", group=display_base_id, /read, $
;                     path=path, /must_exist)
; if a file is selected
;if file ne '' then begin
    ; get structure
;	ret=ns_inst_cfg(file, error_flag=error, $
;		display_base_id=display_base_id)
;	if error eq 0 then begin
        ; if structure retrieved correctly, set in uval
	;	uval.inst_cfg=ret
	;	uval.platescale=ret.platescale
;        ns_extract_fits_info, display_base_id
;	endif
;endif

; set uval
;widget_control, display_base_id, set_uval=uval

end
