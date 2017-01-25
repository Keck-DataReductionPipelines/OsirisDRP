FUNCTION DIALOG_PRINT, dialog_parent=dialog_parent, type=type, $
	printer_name=printer_name, landscape=landscape, $
	init_file=init_file, init_printer=init_printer, $
	init_orient=init_orient, $
	file_dir=file_dir

if keyword_set(init_file) then ps_filename=init_file else $
	ps_filename=''
if keyword_set(init_printer) then printer_name=init_printer else $
	printer_name=''
if keyword_set(init_orient) then landscape=init_orient else $
	landscape=1
if not keyword_set(file_dir) then file_dir=''


topBase = WIDGET_BASE (TITLE = 'Print...', /COLUMN, /BASE_ALIGN_CENTER, $
       /FLOATING, /MODAL, GROUP_LEADER = dialog_parent)


base = WIDGET_BASE (topBase, /COLUMN)
two_base=widget_base(base, /row)
left_base=widget_base(two_base, /col)
right_base=widget_base(two_base, /col)
type_text=widget_label(left_base, Value='Print to:')
tnames=['File', 'Printer']
toggle=cw_bgroup(left_base, tnames, col=1, /exclusive, /return_index, $
   set_value=0)
spacer=widget_label(right_base, Value='Name')
file_base=widget_base(right_base, /row)
fname_box=cw_field(file_base, title='File Name:', value=ps_filename)
browse_button=widget_button(file_base, value='Browse')
pname_box=cw_field(right_base, title='Printer Name:', value=printer_name)
orient_names=['Portrait', 'Landscape']
orient=cw_bgroup(base, orient_names, set_value=landscape, /row, $
                /exclusive, /return_index)
bnames=['OK', 'CANCEL']
buttons=cw_bgroup(base, bnames, row=1, /return_name)


; Map to screen
;
WIDGET_CONTROL, topBase, /REALIZE

widget_control, pname_box, sensitive=0


value = ''
quit=0

while quit eq 0 do begin


    ; Get the event, without using XMANAGER
    ;
    event = widget_event(topBase)


    CASE (event.id) OF

	 
	orient: begin
		landscape=event.value
	end

	toggle: begin
		types=['File', 'Printer']
		type=types[event.value]
		widget_control, file_base, sensitive=(event.value eq 0)
		widget_control, pname_box, sensitive=(event.value eq 1)

	end

         ; Button widget events
         ;
         buttons: BEGIN

             IF (event.value EQ 'Cancel') THEN BEGIN
                WIDGET_CONTROL, topBase, /DESTROY
                RETURN, ''
             ENDIF else quit=1
		
             END

	browse_button: begin

		ps_filename=dialog_pickfile(/write, group=top_base, $
			path=file_dir, filter='*.ps', file=ps_filenmae)

		if ps_filename ne '' then begin
			widget_control, fname_box, set_value=ps_filename
		endif
			
	end

         ELSE: BEGIN
             retVal = ''
             END
    
    ENDCASE ; for type


endwhile

; Retrieve the text values
;
widget_control, pname_box, get_value=pname
printer_name=pname[0]

widget_control, fname_box, get_value=fname
ps_filename=fname[0]

retval=ps_filename

WIDGET_CONTROL, topBase, /DESTROY

RETURN, retval


END

