pro cimwin_accelerators_event, event 

widget_control, event.top, get_uval=uval
widget_control, event.id, get_value=selection

self=*uval.self_ptr
pmode=*uval.pmode_ptr
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
 
widget_control, event.id, get_value=accelerator 
print, 'Event on: ', accelerator 

case accelerator of
    'pan': begin
        ; add pan as a pointing mode
        self->AddPntMode, 'pan'
    end
endcase

;if (uvalue eq 'Quit') then begin 
;   WIDGET_CONTROL, event.top, /destroy 
;end 
 
end 
