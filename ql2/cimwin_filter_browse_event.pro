pro cimwin_filter_browse_event, event

; get conbase uval
widget_control, event.top, get_uval=uval

if (tag_exist(uval, 'filter_path') eq 1) then path=uval.filter_path else path='.' 

filename=dialog_pickfile(dialog_parent=event.id, filter='*.dat', $
	path=path, get_path=newpath, /read, /must_exist)

if filename ne '' then begin
	if (tag_exist(uval, 'path') eq 1) then $
		uval.filter_path=newpath
	widget_control, event.id-3, set_value=filename
endif

; update conbase uval
widget_control, event.top, set_uval=uval

end
