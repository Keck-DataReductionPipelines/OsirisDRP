; +
; NAME: CImWin_Close
;
; PURPOSE: close the image window for a particular instance
;
; CALLING SEQUENCE: CImWin_Close, base_id
;
; INPUTS: base_id, id of the image window base that you want to close
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
; REVISION HISTORY: 24FEB2003 - MWM: added comments.
; - 

pro CImWin_Close, base_id
; routine for destroying of base... additional cleanup in ql_subbase_death.pro

widget_control, base_id, get_uval=uval
self=*uval.self_ptr
conbase_id=self->GetParentBaseId()
widget_control, conbase_id, get_uval=conbase_uval

; if the window is the active window, then remove its id from conbase
if (uval.self_ptr eq conbase_uval.p_curwin) then begin
    ptr_free, conbase_uval.p_curwin
    conbase_uval.p_curwin=ptr_new()
endif

; remove the ptr from the conbase stack
ql_imwinobj_remove, conbase_id, uval.self_ptr

; destroy image object only when it leaves image buffer
obj_destroy, *(self->GetImObj())
ptr_free, uval.self_ptr
; destroy object
obj_destroy, self
; destroy widget
;heap_gc, /verbose

heap_gc

widget_control, conbase_id, set_uval=conbase_uval
widget_control, base_id, /destroy

end
