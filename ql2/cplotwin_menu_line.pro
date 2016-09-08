pro CPlotWin_Menu_Line_event, event

end

pro CPlotWin_Menu_Line_Control_event, event

if event.value eq 'Cancel' then widget_control, event.top, /destroy $
else begin
	widget_control, event.top, get_uval=uval
	widget_control, uval.base_id, get_uval=main_uval
	self=*(main_uval.self_ptr)
	
	psym=widget_info(uval.wids.psym, /droplist_select)
	widget_control, uval.wids.psym_options, get_value=psym_options

	; if connect, multiply by -1
	if psym_options[0] eq 1 then psym=psym*(-1)
	
	if abs(psym) eq 8 then psym=10

	self->SetPsym, psym

	widget_control, uval.wids.symsize, get_value=symsize
	self->SetSymsize, symsize[0]

	linestyle=widget_info(uval.wids.linestyle, /droplist_select)
	self->SetLinestyle, linestyle

	widget_control, uval.wids.thick, get_value=thick
	self->SetThick, thick[0]

	self->DrawPlot

	if event.value eq 'OK' then widget_control, event.top, /destroy

endelse 

end

pro CPlotWin_Menu_Line, base_id

widget_control, base_id, get_uval=uval

self=*(uval.self_ptr)


linestyles=['Solid', $
	    'Dotted', $
	    'Dashed', $
	    'Dash Dot', $
	    'Dash Dot Dot Dot', $
	    'Long Dashes']

psym_list=['None', $
	   'Plus Sign (+)', $
	   'Asterisk (*)', $
	   'Period (.)', $
	   'Diamond', $
	   'Triangle', $
	   'Square', $
	   'X', $
	   'Histogram']

psym=self->GetPsym()

connect=0
if psym le 0 then connect=1

;make widgets
base=widget_base(/col, title='Format Line', group_leader=base_id)
psym=widget_droplist(base, title='Plot Symbols:', value=psym_list)
psym_options=cw_bgroup(base, ['Connect Points?'], /col, $
	/nonexclusive, set_value=[connect])
linestyle_menu=widget_droplist(base, title='Linestyle:', $
	value=linestyles)
linethick=cw_field(base, title='Line Thickness:', value=self->GetThick(), $
	xs=3, /floating)
symsize_box=cw_field(base, title='Symbol Size:', value=self->GetSymsize(), $
	xs=3, /floating)


control_buttons=cw_bgroup(base, ['OK', 'Apply', 'Cancel'], /row, /return_name)

widget_control, linestyle_menu, set_droplist_select=self->GetLinestyle()

widget_control, base, /realize, set_uval= $
	{ wids: {base:base, $
		linestyle:linestyle_menu, $
		thick:linethick, $
		psym:psym, $
		psym_options:psym_options, $
		symsize:symsize_box}, $
	 base_id:base_id}

uval.exist.line=base
widget_control, base_id, set_uval=uval

xmanager, 'CPlotWin_Menu_Line', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CPlotWin_Menu_Line_Control', control_buttons, /just_reg, $
	/no_block

end
