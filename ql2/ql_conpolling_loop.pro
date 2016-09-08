pro ql_conpolling_loop_event, event

widget_control, event.top, get_uvalue=base_uval

filename=''
frame_ready=0
kill_ql=0

if base_uval.polling_info.on eq 1 then begin

	if base_uval.polling_info.get_filename_function ne '' then $
		filename=call_function( $
			base_uval.polling_info.get_filename_function)
	
	if base_uval.polling_info.frame_ready_function ne '' then $
		frame_ready=call_function( $
			base_uval.polling_info.frame_ready_function)
	
	if base_uval.polling_info.get_filename_function ne '' then $
		kill_ql=call_function( $
			base_uval.polling_info.kill_ql_function)

endif

widget_control, event.top, set_uvalue=base_uval, timer=base_uval.pollrate

end
