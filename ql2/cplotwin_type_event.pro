;+
; NAME: CPlotWin_Type_event
; 	Event handler for the "Plot type" box at the top of the CPlotWin window.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 2008-03-18 Marshall Perrin  Added documentation 
;-

pro CPlotWin_Type_event, event

widget_control, event.top, get_uval=base_uval
self=*(base_uval.self_ptr)
widget_control, self->GetParentBaseId(), get_uval=imwin_uval
CImWinObj=*(imwin_uval.self_ptr)

; find the selection type
dlist_selection=widget_info(event.id, /droplist_select)
type_list=*base_uval.type_list_ptr
selection=type_list[dlist_selection]

; find the old plot type
old_plottype=self->GetPlotType()

case selection of
	'Depth Plot': begin	; Depth Plot 
            self->ChangePlotType, 'depth'
	end
    'Horizontal Cut': begin	; Horizontal Cut 
            self->ChangePlotType, 'horizontal'
    end
        'Vertical Cut': begin 	; Vertical Cut
            self->ChangePlotType, 'vertical'
	end
	'Diagonal Cut': begin 	; Diagonal Cut
            self->ChangePlotType, 'diagonal'
        end
	'Surface Plot': begin 	; Surface Plot
            self->ChangePlotType, 'surface'
	end
	'Contour Plot': begin	; Contour Plot
            self->ChangePlotType, 'contour'
	end
	else:
endcase

end
