pro ql_buffer_list_close_button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

; remove id from list of widgets that are alive
base_uval.exist.buffer_list=0L

widget_control, uval.wids.base_id, set_uval=base_uval
widget_control, event.top, /destroy

end

pro ql_buffer_list_populate, base_id

widget_control, base_id, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

save=!D.WINDOW

; go through each image, if valid, display
for idx=0, n_elements(uval.win_idx)-1 do begin
	; determine if valid image
	im=*(base_uval.buffer_list[idx])
	if obj_valid(im) then begin
		if obj_isa(im, 'CImage') then begin
			im_xs=im->GetXS()
			im_ys=im->GetYS()			
			imscale=(uval.win_xs/float(im_xs)) < $
				(uval.win_ys/float(im_ys))
			wset, uval.win_idx[idx]
			tvscl, congrid(*(im->GetData()), $
				im_xs*imscale, im_ys*imscale)
		endif
	endif
endfor

wset, save

end

pro ql_buffer_list_draw_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval

save=!D.WINDOW

; which window was clicked
which_win=where(uval.wids.draws eq event.id)

; double click
if event.clicks eq 2 then begin
	im=*(base_uval.buffer_list[which_win])
	if obj_valid(im) then begin
		if obj_isa(im, 'CImage') then begin
			; right double click -> open in current active window
			if event.press eq 4 then begin
				ql_display_new_image, uval.wids.base_id, $
					base_uval.buffer_list[which_win], $
					p_WinObj=base_uval.p_curwin
			endif else begin
			; left/middle double click -> open in a new window
				ql_display_new_image, uval.wids.base_id, $
					base_uval.buffer_list[which_win]
			endelse
		endif
	endif
endif else begin
	if event.press ne 0 then begin
	mask=!d.n_colors-1
	; set graphics to xor type
	device, set_graphics=6

	; shift and click -> add to selection
	; make current click only selection
	if event.modifiers ne 1 then begin
		which_selected=where(uval.selected eq 1)
		if which_selected[0] ne -1 then begin
			for idx=0,n_elements(which_selected)-1 do begin
				wset, uval.win_idx[which_selected[idx]]
				plots, [0, 1, 1, 0, 0], [0, 0, 1, 1, 0], $
					color=mask, /normal, thick=5
				uval.selected[which_selected[idx]]=0
			endfor
		endif
	endif	 

	if uval.selected[which_win] ne 1 then begin
		wset, uval.win_idx[which_win]
		plots, [0, 1, 1, 0, 0], [0, 0, 1, 1, 0], $
			color=mask, /normal, thick=5
	endif

	uval.selected[which_win]=1

	device, set_graphics=3
	endif
endelse

wset, save

widget_control, event.top, set_uval=uval

end

pro ql_buffer_list, conbase_id

widget_control, conbase_id, get_uval=base_uval

thumb_xs=128
thumb_ys=128

base=widget_base(/col, group_leader=conbase_id, title='Buffer List', $
                 /tlb_kill_request_events) 
draw1=widget_draw(base, xs=thumb_xs, ys=thumb_ys, /button_events)
draw2=widget_draw(base, xs=thumb_xs, ys=thumb_ys, /button_events)
draw3=widget_draw(base, xs=thumb_xs, ys=thumb_ys, /button_events)
draw4=widget_draw(base, xs=thumb_xs, ys=thumb_ys, /button_events)
close_button=widget_button(base, value='Dismiss', font=base_uval.font)

wids={base_id:conbase_id, draws:[draw1, draw2, draw3, draw4]}

widget_control, base, /realize

widget_control, draw1, get_value=idx1
widget_control, draw2, get_value=idx2
widget_control, draw3, get_value=idx3
widget_control, draw4, get_value=idx4

win_idx=[idx1, idx2, idx3, idx4]
uval={base_id:conbase_id, $
      wids:wids, $
      win_idx:win_idx, $
      win_xs:thumb_xs, $
      win_ys:thumb_ys, $
      selected:bytarr(n_elements(wids.draws))}

widget_control, base, set_uval=uval

xmanager, 'ql_buffer_list_tlb', base, /just_reg, /no_block, $
          cleanup='ql_subbase_death'
xmanager, 'ql_buffer_list_close_button', close_button, /just_reg, /no_block
xmanager, 'ql_buffer_list_draw', draw1, /just_reg, /no_block
xmanager, 'ql_buffer_list_draw', draw2, /just_reg, /no_block
xmanager, 'ql_buffer_list_draw', draw3, /just_reg, /no_block
xmanager, 'ql_buffer_list_draw', draw4, /just_reg, /no_block

base_uval.exist.buffer_list=base

widget_control, conbase_id, set_uval=base_uval

ql_buffer_list_populate, base

end
