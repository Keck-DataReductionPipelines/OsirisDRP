;+
; NAME: ql_update_buffer_list
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_update_buffer_list, conbase_id, image object pointer
;
; INPUTS: conbase_id (long) - id of the control base 
;         p_ImObj (string) - path of the file to be opened
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS: 
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES: BUGGY
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; 	2007-07-03		MDP: added check for pointer validity
; 					I suspect I may have broken this feature in the
; 					course of fixing the memory leaks...
;- 

pro ql_update_buffer_list, conbase_id, p_ImObj

; get conbase uval
widget_control, conbase_id, get_uval=base_uval

; make a temporary list that holds the current buffer list
temp_list=base_uval.buffer_list
wh=where(base_uval.buffer_lock eq 0)
if (wh[0] ne -1) then begin
	temp_list[wh]=shift(base_uval.buffer_list[wh], 1)
	if ptr_valid(base_uval.buffer_list[wh[n_elements(wh)-1]]) then begin ; MDP
		if obj_valid(*(base_uval.buffer_list[wh[n_elements(wh)-1]])) then begin
			obj_destroy, *(base_uval.buffer_list[wh[0]])
		endif ;else ptr_free, base_uval.buffer_list[wh[0]] ; if it's not an object just free it...
	endif
	temp_list[wh[0]]=p_ImObj
	base_uval.buffer_list=temp_list
        ; update conbase uval
	widget_control, conbase_id, set_uval=base_uval
endif

end
