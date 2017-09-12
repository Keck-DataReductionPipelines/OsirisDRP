; +
; NAME: ql_conmenu_event
;
; PURPOSE: event handler for the ql_conbase menu bar
;
; CALLING SEQUENCE: ql_conmenu_event, event
;
; INPUTS: event - can be any of these menu options
;         'Select Instrument Configuration': opens ql_inst_cfg
;         'Open...': opens ql_conopen
;         'Open in a New Window': opens ql_conopen
;	  'Options...': opens ql_conoptions
;         'Polling...': opens ql_conpolling
;	  'Show Buffers...': opens ql_buffer_list
;	  'Quit': opens ql_conquit
;	  'Reduce...' opens ql_conreduce
;	  'Arithmetic...': opens ql_math
;	  'Online Help...': N/A
;	  'About...': gives credits to the ql2 software developers
;         'Memory Usage': prints the memory usage for the user
;         filname from 'Recent Files'
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 17DEC2002 - MWM: added comments.
; - 

pro ql_conmenu_event, event

; get conbase uval
widget_control, event.top, get_uval=base_uval

; get menu selection
widget_control, event.id, get_value=selection

; switch statement that opens the appropriate program for a control base 
; menu selection.  for dialog boxes, check to see if the dialog already 
; exists.  if so, bring it to the top.  otherwise, create a new one.

case selection of
	'Open...': ql_conopen, event.top
        'Select QL2 Setup': ql_load_setup_cfg, event.top
        'Select Color Table': begin 
            xloadct, group=event.top, /modal
            ql_refresh_all, event.top
        end
	'Open in a New Window': ql_conopen, event.top, /new
	'Options...': if base_uval.exist.options eq 0L then $
		ql_conoptions, event.top $
		else widget_control, base_uval.exist.options, /show
        'Polling...': if (base_uval.exist.polling eq 0L) then $
		ql_conpolling, event.top $
		else widget_control, base_uval.exist.polling, /show
	'Show Buffers...': if base_uval.exist.buffer_list eq 0L then $
		ql_buffer_list, event.top $
		else widget_control, base_uval.exist.buffer_list, /show
        'Close All Windows': ql_closewindows, event.top
	'Quit': ql_conquit, event.top
	'Reduce...': if base_uval.exist.reduce eq 0L then $
		ql_conreduce, event.top $
		else widget_control, base_uval.exist.reduce, /show
	'Arithmetic...': if base_uval.exist.arithmetic eq 0L then ql_conmath, $
		event.top $
		else widget_control, base_uval.exist.arithmetic, /show
	'Online Help...': begin
            ; print error message
            message='Online help is not ready yet.'
            answer=dialog_message(message, dialog_parent=event.top, /error)
            print, "Not ready yet"
        end 
	'About...': answer=dialog_message(['Quicklook v4.1 2017-09-07', $
		'Maintained by OSIRIS Pipeline Working Group', 'osiris_info@keck.hawaii.edu', 'Originally: Michael McElwain, UCLA (2005)', $
                'mcelwain@astro.ucla.edu', 'Jason Weiss, UCLA (2001)', $
                'weiss@astro.ucla.edu'], $
		dialog_parent=event.top, /info, title='About Quicklook')
        'Keyboard Shortcuts': if base_uval.exist.shortcuts eq 0L then $
		ql_keyboardshortcuts, event.top $
		else widget_control, base_uval.exist.shortcuts, /show
        'Memory Usage': ql_conmemory, event.top
	else: begin  ; recent file menu
                ; selection variable will hold the name of the file
                ; to be reopened, since the user will select the filename
                ; from the one listed next to 'Recent Files...'.  Therefore,
                ; create a new image object from the filename, and open
                ; it.
		im=ql_create_cimage(event.id, selection)
		p_ImObj=ptr_new(im, /allocate_heap)
                ext=im->GetExt()
		ql_display_new_image, event.top, p_ImObj, ext
	endelse
endcase

end
