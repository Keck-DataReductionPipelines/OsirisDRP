pro CImWin_Strehl_Base_event, event
if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then $
    cimwin_strehl_button_event, event
end
