pro ql_conpolling_control_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=base_uval

; get the cpolling object
cpolling_ptr=base_uval.cpolling_ptr
cpolling_obj=*cpolling_ptr

; get the cconfigs object
cconfigs_ptr=base_uval.cconfigs_ptr
cconfigs_obj=*cconfigs_ptr

; get server polling info
widget_control, uval.wids.polling_on, get_value=server_polling_on
widget_control, uval.wids.polling_server, get_value=server_name

; get directory polling info
widget_control, uval.wids.polling_directory_on, get_value=directory_polling_on
widget_control, uval.wids.polling_directory_box, get_value=directory

; get the polling interval
widget_control, uval.wids.polling_interval, get_value=server_interval

; which button was pressed?
case event.value of
    'OK': begin
        cpolling_obj->SetServerName, server_name[0]
        cpolling_obj->SetDirectoryName, directory[0]

        cpolling_obj->SetPollingRate, float(server_interval[0])
        
        if (server_polling_on eq 1) then begin
            cpolling_obj->SetPollingStatus, 1.
            testserver=cpolling_obj->TestServer()
            if (testserver eq -1) then begin
                cpolling_obj->ReportError, 'server'
            endif else begin
                cpolling_obj->StartTimer, uval.base_id
            endelse
        endif else begin
            cpolling_obj->SetPollingStatus, 0.
        endelse
        
        if (directory_polling_on eq 1) then begin
            cpolling_obj->SetDirectoryPollingStatus, 1.
                ; make sure this is a valid directory
            if (ql_file_search(directory[0]) eq '') then begin
                cpolling_obj->ReportError, 'directory'
            endif else begin
                cpolling_obj->StartTimer, uval.base_id
                newdir_arr=ql_file_search(directory[0]+'/*.fits')

                ; get the directory array pointer
                dir_arr_ptr=cconfigs_obj->GetDirArr()
                *dir_arr_ptr=newdir_arr
            endelse
        endif else begin
            cpolling_obj->SetDirectoryPollingStatus, 0.
        endelse                
    end
    'Apply': begin
        cpolling_obj->SetServerName, server_name[0]
        cpolling_obj->SetDirectoryName, directory[0]

        cpolling_obj->SetPollingRate, float(server_interval[0])
            
        if (server_polling_on eq 1) then begin
            cpolling_obj->SetPollingStatus, 1.
            testserver=cpolling_obj->TestServer()
            if (testserver eq -1) then begin
                cpolling_obj->ReportError, 'server'
            endif else begin
                cpolling_obj->StartTimer, uval.base_id
            endelse
        endif else begin
            cpolling_obj->SetPollingStatus, 0.
        endelse
        
        if (directory_polling_on eq 1) then begin
            cpolling_obj->SetDirectoryPollingStatus, 1.
            ; make sure this is a valid direcotry
            if (ql_file_search(directory[0]) eq '') then begin
                cpolling_obj->ReportError, 'directory'
            endif else begin
                cpolling_obj->StartTimer, uval.base_id
                newdir_arr=ql_file_search(directory[0]+'/*.fits')
                ; get the directory array pointer
                dir_arr_ptr=cconfigs_obj->GetDirArr()
                *dir_arr_ptr=newdir_arr
            endelse
        endif else begin
            cpolling_obj->SetDirectoryPollingStatus, 0.
        endelse                
        return
    end
    else:
endcase

base_uval.exist.polling=0L
widget_control, uval.base_id, set_uval=base_uval

widget_control, event.top, /destroy

end

pro ql_conpolling_select_directory_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=base_uval

; get the cpolling object
cpolling_ptr=base_uval.cpolling_ptr
cpolling_obj=*cpolling_ptr

; get the current directory
widget_control, uval.wids.polling_directory_box, get_value=box_path

directory=dialog_pickfile(/directory, dialog_parent=event.top, path=box_path)

; set box value to reflect the selected directory
widget_control, uval.wids.polling_directory_box, set_value=directory

end

pro ql_conpolling, conbase_id

widget_control, conbase_id, get_uval=base_uval
cpolling_obj=*(base_uval.cpolling_ptr)


base=widget_base(/col, title='Polling', group_leader=conbase_id, /tlb_kill_request_events)

; polling server widgets
server_base=widget_base(base, /col, frame=2)
polling_on_toggle=cw_bgroup(server_base, ['Off', 'On'], $
	label_left='Server Polling:', $
	set_value=cpolling_obj->GetPollingStatus(), $
	font=base_uval.font, /exclusive, /row)
polling_server_box=cw_field(server_base, title='Server Name:', font=base_uval.font, $
	value=cpolling_obj->GetServerName())

; polling directory widgets
directory_base=widget_base(base, /col, frame=2)
polling_directory_on_toggle=cw_bgroup(directory_base, ['Off', 'On'], $
	label_left='Directory Polling:', $
	set_value=cpolling_obj->GetDirectoryPollingStatus(), $
	font=base_uval.font, /exclusive, /row)
select_directory_base=widget_base(directory_base, /row, ypad=0)
polling_directory_box=cw_field(select_directory_base, title='Directory Name:', font=base_uval.font, $
	value=cpolling_obj->GetDirectoryName())
polling_directory_button=widget_button(select_directory_base, value='Choose directory')

; interval widgets
interval_base=widget_base(base, /col, frame=2)
polling_interval_box=cw_field(interval_base, title='Polling Interval:', $
	value=cpolling_obj->GetPollingRate(), font=base_uval.font)

control_buttons=cw_bgroup(base, ['OK', 'Apply', 'Cancel'], $
	font=base_uval.font, /row, /return_name)

wids={polling_on:polling_on_toggle, $
	polling_server:polling_server_box, $
	polling_interval:polling_interval_box, $
        polling_directory_on:polling_directory_on_toggle, $
	polling_directory_box:polling_directory_box, $
        polling_directory_button:polling_directory_button $
}

uval={base_id:conbase_id, wids:wids}
widget_control, base, set_uval=uval, /realize

xmanager, 'ql_conpolling_base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'ql_conpolling_control', control_buttons, /just_reg, /no_block
xmanager, 'ql_conpolling_select_directory', polling_directory_button, /just_reg, /no_block

base_uval.exist.polling=base
widget_control, conbase_id, set_uval=base_uval

end
