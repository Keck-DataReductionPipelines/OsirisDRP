pro CImWin_Stat_Base_event, event

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then $
    cimwin_stat_button_event, event
end
