pro ql_load_setup_cfg, display_base_id

; get uval
widget_control, display_base_id, get_uval=uval
configs=*(uval.cconfigs_ptr)

ql_filedir=getenv('QL_FILEDIR')
; get filename
path=strcompress(ql_filedir+'/configs', /remove_all)
file=dialog_pickfile(filter="*_cfg.pro", group=display_base_id, /read, $
                     path=path, /must_exist)

; if a file is selected
if file ne '' then begin
    ; load configuration structure
    config_valid=configs->CheckConfigFile(file)
    if config_valid then begin
        configs->LoadConfigFile, file
        configs->UpdateParams
    endif
endif

end
