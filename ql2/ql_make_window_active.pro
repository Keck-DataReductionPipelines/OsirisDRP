; +
; NAME: ql_make_window_active
;
; PURPOSE: 
;
; CALLING SEQUENCE: ql_make_window_active, conbase_id, p_WinObj
; 
; INPUTS:  conbase_id (long) - widget id of the control base, 
;                              p_WinObj is the pointer to an existing
;                              window where the image will be opened
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
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 24FEB2003 - MWM: added comments.
; - 

pro ql_make_window_active, conbase_id, p_WinObj

; get the uval of the control base
widget_control, conbase_id, get_uval=base_uval
if ptr_valid(base_uval.p_curwin) then begin
    ; stores the value of the old window pointer
    old_winObj=*base_uval.p_curwin
    ; checks to make sure the object is valid
    if obj_valid(old_winObj) then $
      ; checks to make sure the object is of the class 'CImWin'
      if obj_isa(old_winObj, 'CImWin') then $
      ; calls the accessor function to make this window inactive
      old_winObj->MakeInactive
endif
; get the self ptr from the win object
WinObj=*(p_WinObj)
winbase_id=WinObj->GetBaseid()
widget_control, winbase_id, get_uval=cimwin_uval
; sets the current window pointer in the conbase uval
base_uval.p_curwin=cimwin_uval.self_ptr
; stores the dereferenced pointer to the window
winObj=*p_WinObj
; makes the window active
winObj->MakeActive
widget_control, conbase_id, set_uval=base_uval
end
