;+
; NAME: ql_conquit
;
; PURPOSE: quits ql2 and destroys all widgets
;
; CALLING SEQUENCE: ql_conquit, parentbase_id
;
; INPUTS: conbase_id (long) - widget id of the control base
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
; NOTES: called by ql_conmenu_event
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; 					2007-10  MDP: Slight code cleanup and better garbage
; 					collection using 'heap_free'
;- 

pro ql_conquit, conbase_id

widget_control, conbase_id, get_uval=conbase_uval

exit_question=0        

if ptr_valid(conbase_uval.cconfigs_ptr) then begin
    if obj_valid(*conbase_uval.cconfigs_ptr) then begin
        if obj_isa(*conbase_uval.cconfigs_ptr, 'CConfigs') then begin
            configs=*(conbase_uval.cconfigs_ptr)
            exit_question=configs->GetExitQuestion()
        endif 
    endif
endif 

if (exit_question) then begin
    ; check to see if the user wants to quit IDL
    message='Do you want to exit IDL?'
    answer=dialog_message(message, /question)
    if (answer eq 'Yes') then begin
        ; quits idl and returns back to the operating system
        exit
    endif else begin
        ; idl quits QL2 and cleans up the widgets
		heap_free, conbase_uval ; this destroys conbase_uval and all its contents
        heap_gc
        ; destroy the conbase widgets
        widget_control, conbase_id, /destroy
    endelse
endif else begin
    exit
endelse

end
