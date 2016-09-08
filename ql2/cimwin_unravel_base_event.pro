pro CImWin_Unravel_Base_event, event

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then $
    cimwin_unravel_button_event, event

end
