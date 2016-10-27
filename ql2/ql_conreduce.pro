pro reduce_quit_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval
base_uval.exist.reduce=0L
widget_control, uval.wids.base_id, set_uval=base_uval

widget_control, event.top, /destroy

end

pro savefile_event, event

widget_control, event.top, get_uval=uval
widget_control, event.id, get_value=savefile
uval.savefile=savefile[0]
widget_control, uval.wids.savefile_dir_base, sensitive=savefile[0]
widget_control, uval.wids.savefile_root_base, sensitive=savefile[0]
widget_control, event.top, set_uval=uval

end

pro usedead_event, event

widget_control, event.top, get_uval=uval
widget_control, event.id, get_value=usedead
uval.usedead=usedead[0]
widget_control, uval.wids.deadpix_base, sensitive=usedead[0]
widget_control, event.top, set_uval=uval

end

pro reduce_serial_event, event

widget_control, event.top, get_uval=uval
widget_control, event.id, get_value=serial
uval.serial=serial[0]
widget_control, uval.wids.display_reduced_base, sensitive=serial[0]
widget_control, event.top, set_uval=uval

end

function get_nextfile, filename

; get current filename
;print, 'filename = ', filename
nextfile=''

if filename ne "" then begin
	; get previous filename
	fdecomp, filename, disk, dir, name, qual
	byte_name=byte(name)    ; convert to byte string array to decrement
	sz_byte_name=size(byte_name)
	; increment last
	byte_name[sz_byte_name[1]-1]=byte_name[sz_byte_name[1]-1]+1 

	i=1

	; check to see if new number is actually 1 more than previous...this
	; is to prevent error on incrementing numbers that end in 9
	while (i lt sz_byte_name[1]) do begin
        	if (byte_name[sz_byte_name[1]-i] eq 58) then begin 
            		byte_name[sz_byte_name[1]-i]=48 ; make it a 0
            		; then increment digit to the left
            		byte_name[sz_byte_name[1]-(i+1)] = $
				byte_name[sz_byte_name[1]-(i+1)]+1
        	endif
        i=i+1
    	endwhile

;	print, byte_name
;	print, string(byte_name)

	nextfile=strcompress(disk+dir+string(byte_name)+'.'+qual, /remove_all)

endif

return, nextfile

end

pro reduce_button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

widget_control, uval.wids.obj_box, get_value=objfile
objfile=objfile[0]
widget_control, uval.wids.sky_box, get_value=skyfile
skyfile=skyfile[0]
widget_control, uval.wids.flat_box, get_value=flatfile
flatfile=flatfile[0]
widget_control, uval.wids.dead_box, get_value=deadfile
deadfile=deadfile[0]
widget_control, uval.wids.remove_noise, get_value=noise_flag
noise_flag=noise_flag[0]
widget_control, uval.wids.display_reduced_toggle, get_value=display
uval.display=display[0]
widget_control, uval.wids.savefile_dir_box, get_value=savefile_dir
savefile_dir=savefile_dir[0]

if (uval.savefile eq 1) then begin
	spawn, 'ls '+savefile_dir+'/.*', res
	if res[0] eq '' then begin
		message=[savefile_dir+' does not exist.', $
			'Do you wish to create directory?']
		answer=dialog_message(message, dialog_parent=event.id, $
			/question)
		if answer eq 'Yes' then $
			spawn, 'mkdir '+savefile_dir $
		else return
	endif
endif

if (objfile ne '') and (skyfile ne '') and (flatfile ne '') then begin
	if ((ql_file_search(skyfile))[0] ne '') then sky=readfits(skyfile) $
		else begin
		message='Could not find sky file: '+skyfile
		answer=dialog_message(message, dialog_parent=event.id, /error)
		return
	endelse
	if ((ql_file_search(flatfile))[0] ne '') then flat=readfits(flatfile) $
		else begin
		message='Could not find flat file: '+flatfile
		answer=dialog_message(message, dialog_parent=event.id, /error)
		return
	endelse
	if (uval.usedead eq 1) then begin
		if ((ql_file_search(deadfile))[0] ne '') then begin
			dead=readfits(deadfile) 
			base_uval.last_map_file=deadfile
		endif else begin
			message=['Could not find dead pixel file: '+deadfile, $
				 'Skipping use of dead pixel map.']
			answer=dialog_message(message, $
				dialog_parent=event.id, /warning)
			dead=fltarr((size(sky))[1], (size(sky))[2])
		endelse
	endif else dead=fltarr((size(sky))[1], (size(sky))[2])

	base_uval.last_sky_file=skyfile
	base_uval.last_flat_file=flatfile
	
	stop_serial=1
	objfound=1

	repeat begin

		if (objfound eq 1 ) then begin
			if ((ql_file_search(objfile))[0] ne '') $
				then obj=readfits(objfile, obj_hdr) $
			else begin
			  message='Could not find object file: '+objfile
			  answer=dialog_message(message, $
				dialog_parent=event.id, /error)
			  objfound=0
			endelse
		endif
			
		if (objfound eq 1) then begin
			final=reduce_algorithm(obj, sky, flat, dead, $
				remove_pattern_flag=noise_flag)
			
			if (uval.savefile eq 1) then begin	
				fdecomp, objfile, disk, dir, name, qual
				widget_control, uval.wids.savefile_root_box, $
					get_value=prefix
				filename=strcompress(savefile_dir+prefix[0]+ $
					name+'.'+qual, /remove_all)
				sxaddpar, obj_hdr, 'HISTORY', $
					'Sky Subtracted, file='+skyfile
				sxaddpar, obj_hdr, 'HISTORY', $
					'Flat Fielded, file='+flatfile
				sxaddpar, obj_hdr, 'HISTORY', $
					'Dead Pixel Correction, file='+deadfile
				if (noise_flag eq 1 ) then $ 
				  sxaddpar, obj_hdr, 'HISTORY', $
					'Correlation Noise Removed'
                                ; check the permissions on the path
                                path=ql_getpath(file)
                                permission=ql_check_permission(path)    
                                if (permission eq 1) then begin
                                    ; write the image to disk
                                    writefits, file, im, hd
                                    ; reset image filename
                                    ImObj->SetFilename, file
                                    ; update window title
                                    widget_control, base_id, tlb_set_title=file
                                endif else begin
                                    err=dialog_message(['Error writing .fits file.', 'Please check path permissions.'], $
                                                       dialog_parent=base_id, /error)
                                endelse
				writefits, filename, final, obj_hdr
			endif else filename=objfile
			if (uval.display eq 1) or (uval.serial eq 0) then $
				display_reduced, event.top, final, filename, $
					obj_hdr

		endif

		if (uval.serial eq 1) then begin
			nextfile=get_nextfile(objfile)
			message=['Reduce '+nextfile+'?', $
	'(Press NO to Skip File, Press CANCEL to Stop Serial Reduction.)'] 
			answer=dialog_message(message, /question, /cancel, $
				dialog_parent=event.id)
			case answer of 
				'Yes': begin	
					objfile=nextfile
					objfound=1
					stop_serial=0
				end
				'No': begin
					objfile=nextfile
					objfound=0
					stop_serial=0
				end
				'Cancel': stop_serial=1
			endcase
		endif
		
	endrep until (stop_serial eq 1)

endif else begin
	answer=dialog_message(['Reduction requires all four files.', $
		'(Object, Sky, Flat Field, and Dead Pixel Map.)'], $
		dialog_parent=event.id, /error)
endelse

end

pro display_reduced, reduce_id, final, filename, hd

widget_control, reduce_id, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

imsize=size(final)
data_ptr=ptr_new(final, /allocate_heap)
hd_ptr=ptr_new(hd, /allocate_heap)
im=obj_new('CImage', filename=filename, data=data_ptr, header=hd_ptr, $
	xs=imsize[1], ys=imsize[2])

if obj_isa(im, 'CImage') then begin
	ql_display_new_image, uval.wids.base_id, im
endif else begin
	message=['Error in reduction:', $
		' Error creating CImage object']
	answer=dialog_message(message, dialog_parent=$
		conbase_id)
endelse

end

pro savefile_browse_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

filename=dialog_pickfile(dialog_parent=event.id, path=uval.path, $
	get_path=newpath, /write, /directory)

if filename ne '' then begin
	uval.path=newpath
	base_uval.current_data_directory=newpath
	widget_control, event.id-3, set_value=filename
endif

widget_control, uval.wids.base_id, set_uval=base_uval
widget_control, event.top, set_uval=uval

end

pro ql_conreduce, conbase_id

widget_control, conbase_id, get_uval=base_uval

main_reduce_base=widget_base(/col, title='Reduce Image', $
	group_leader=conbase_id, /tlb_kill_request_events)
reduce_base=widget_base(main_reduce_base, /col, frame=2, /base_align_right)
reduce_obj_base=widget_base(reduce_base, /row)
obj_box=cw_field(reduce_obj_base, title='Object:', font=base_uval.font, $
	value=base_uval.last_file, xs=40)
obj_browse=widget_button(reduce_obj_base, value='Browse', font=base_uval.font)

reduce_sky_base=widget_base(reduce_base, /row)
sky_box=cw_field(reduce_sky_base, title='Sky:', font=base_uval.font, $
	value=base_uval.last_sky_file, xs=40)
sky_browse=widget_button(reduce_sky_base, value='Browse', font=base_uval.font)

reduce_flat_base=widget_base(reduce_base, /row)
flat_box=cw_field(reduce_flat_base, title='Flat:', font=base_uval.font, $
	value=base_uval.last_flat_file, xs=40)
flat_browse=widget_button(reduce_flat_base, value='Browse', $
	font=base_uval.font)

reduce_dead_base=widget_base(reduce_base, /row)
dead_box=cw_field(reduce_dead_base, title='Dead Pixel Map:', $
	font=base_uval.font, value=base_uval.last_map_file, xs=40)
dead_browse=widget_button(reduce_dead_base, value='Browse', $
	font=base_uval.font)

usedead_toggle=cw_bgroup(reduce_base, ['No', 'Yes'], font=base_uval.font, $
	/exclusive, /return_index, set_value=0, /row, $
	label_left='Use Dead Pixel Map?')

remove_noise=cw_bgroup(reduce_base, ['No', 'Yes'], /row, font=base_uval.font, $
	/exclusive, /return_index, set_value=0, $
	label_left='Remove Correlated Noise Pattern?')

reduce_savefile_base=widget_base(main_reduce_base, frame=2, /col)

savefile=cw_bgroup(reduce_savefile_base, ['No', 'Yes'], /row, set_value=0, $
	/exclusive, /return_index, font=base_uval.font, $
	label_left='Automatically Save Reduced File to Disk?')

savefile_dir_base=widget_base(reduce_savefile_base, /row)
savefile_dir_box=cw_field(savefile_dir_base, title='Directory:', xs=45, $
	value=base_uval.current_data_directory, font=base_uval.font)
savefile_dir_browse=widget_button(savefile_dir_base, value='Browse', $
	font=base_uval.font)

savefile_root_base=widget_base(reduce_savefile_base, /row)
savefile_root_box=cw_field(savefile_root_base, font=base_uval.font, xs=10, $
	title='Reduced File Root Prefix:', value='red_')

reduce_serial=cw_bgroup(reduce_savefile_base, ' ', /nonexclusive, $
	font=base_uval.font, /return_index, set_value=0, $
	label_left='Reduce Serial:', /row)

display_reduced_base=widget_base(reduce_savefile_base, /row)
display_reduced_toggle=cw_bgroup(display_reduced_base, ['No', 'Yes'], /row, $
	font=base_uval.font, /exclusive, /return_index, set_value=1, $
	label_left='Display Each Reduced File?')

reduce_button=widget_button(main_reduce_base, xs=500, value='Reduce', $
	font=base_uval.font)
reduce_quit=widget_button(main_reduce_base, xs=500, value='Quit', $
	font=base_uval.font)

wids={base_id:conbase_id, $
      obj_box:obj_box, $
      sky_box:sky_box, $
      flat_box:flat_box, $
      dead_box:dead_box, $
      remove_noise:remove_noise, $
      savefile_dir_base:savefile_dir_base, $
      deadpix_base:reduce_dead_base, $
      savefile_dir_box:savefile_dir_box, $
      savefile_root_base:savefile_root_base, $
      savefile_root_box:savefile_root_box, $
      display_reduced_base:display_reduced_base, $
      display_reduced_toggle:display_reduced_toggle}
uval={base_id:conbase_id:, $
      wids:wids, $
      serial:0, $
      display:1, $
      savefile:0, $
      usedead:0, $
      path:base_uval.current_data_directory, inbox:0L}

widget_control, main_reduce_base, /realize, set_uval=uval
widget_control, reduce_dead_base, sensitive=0
widget_control, savefile_dir_base, sensitive=0
widget_control, savefile_root_base, sensitive=0
widget_control, display_reduced_base, sensitive=0

; set tracking events on text box of cw_field for dragging of names
widget_control, obj_box+2, /tracking_events
widget_control, sky_box+2, /tracking_events
widget_control, flat_box+2, /tracking_events
widget_control, dead_box+2, /tracking_events


base_uval.exist.reduce=reduce_base
widget_control, conbase_id, set_uval=base_uval

xmanager, 'ql_conreduce_tlb', main_reduce_base, /just_reg, /no_block, $
          cleanup='ql_subbase_death'
xmanager, 'savefile', savefile, /just_reg, /no_block
xmanager, 'reduce_serial', reduce_serial, /just_reg, /no_block
xmanager, 'usedead', usedead_toggle, /just_reg, /no_block
xmanager, 'savefile_browse', savefile_dir_browse, /just_reg, /no_block
xmanager, 'ql_file_browse', obj_browse, /just_reg, /no_block
xmanager, 'ql_file_browse', sky_browse, /just_reg, /no_block
xmanager, 'ql_file_browse', flat_browse, /just_reg, /no_block
xmanager, 'ql_file_browse', dead_browse, /just_reg, /no_block
xmanager, 'ql_filename_box', obj_box, /just_reg, /no_block
xmanager, 'ql_filename_box', sky_box, /just_reg, /no_block
xmanager, 'ql_filename_box', flat_box, /just_reg, /no_block
xmanager, 'ql_filename_box', dead_box, /just_reg, /no_block

xmanager, 'reduce_button', reduce_button, /just_reg, /no_block
xmanager, 'reduce_quit', reduce_quit, /just_reg, /no_block

end
