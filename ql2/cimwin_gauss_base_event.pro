pro CImWin_Gauss_Base_event, event
if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then $
    cimwin_gauss_button_event, event
end
