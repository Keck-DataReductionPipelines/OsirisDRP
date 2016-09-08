pro CPlotWin_Menu_Axes_event, event

end

pro CPlotWin_Menu_Axes_Control_event, event

if event.value eq 'Cancel' then widget_control, event.top, /destroy $
else begin
	widget_control, event.top, get_uval=uval
	widget_control, uval.base_id, get_uval=main_uval
	self=*(main_uval.self_ptr)
	
	widget_control, uval.wids.xticks, get_value=xticks
	self->SetXTicks, xticks[0]
	widget_control, uval.wids.yticks, get_value=yticks
	self->SetYTicks, yticks[0]
	widget_control, uval.wids.xticklen, get_value=xticklen
	self->SetXTicklen, xticklen[0]
	widget_control, uval.wids.yticklen, get_value=yticklen
	self->SetYTicklen, yticklen[0]
	widget_control, uval.wids.xminor, get_value=xminor
	self->SetXMinor, xminor[0]
	widget_control, uval.wids.yminor, get_value=yminor
	self->SetYMinor, yminor[0]

	xgrid=widget_info(uval.wids.xgrid, /droplist_select)
	self->SetXGridstyle, xgrid
	ygrid=widget_info(uval.wids.ygrid, /droplist_select)
	self->SetYGridstyle, ygrid

	widget_control, uval.wids.xthick, get_value=xthick
	self->SetXThick, xthick[0]
	widget_control, uval.wids.ythick, get_value=ythick
	self->SetYThick, ythick[0]

	widget_control, uval.wids.xlabel, get_value=xlabel
	self->SetXLabel, xlabel

	widget_control, uval.wids.ylabel, get_value=ylabel
	self->SetYLabel, ylabel

	self->DrawPlot

	if event.value eq 'OK' then widget_control, event.top, /destroy
endelse 

end

pro CPlotWin_Menu_Axes, base_id

widget_control, base_id, get_uval=uval

self=*(uval.self_ptr)

linestyles=['Solid', $
	    'Dotted', $
	    'Dashed', $
	    'Dash Dot', $
	    'Dash Dot Dot Dot', $
	    'Long Dashes']


;make widgets
base=widget_base(/col, title='Format Axes', group_leader=base_id)

xticks=cw_field(base, title='X Ticks (0=Auto, 1=Suppress):', $
	value=self->GetXTicks(), /int, xs=3)
yticks=cw_field(base, title='Y Ticks (0=Auto, 1=Suppress):', $
	value=self->GetYTicks(), /int, xs=3)

xminor=cw_field(base, title='X Minor:', value=self->GetXMinor(), /int, xs=3)
yminor=cw_field(base, title='Y Minor:', value=self->GetYMinor(), /int, xs=3)

xticklen=cw_field(base, title='X Ticklength:', value=self->GetXTicklen(), $ 
	/floating, xs=3)
yticklen=cw_field(base, title='Y Ticklength:', value=self->GetYTicklen(), $
	/floating, xs=3)

xgrid=widget_droplist(base, title='X Tick Linestyle:', value=linestyles)
ygrid=widget_droplist(base, title='Y Tick Linestyle:', value=linestyles)

xthick=cw_field(base, title='X Tick Thickness:', value=self->GetXThick(), $ 
	/int, xs=3)
ythick=cw_field(base, title='Y Tick Thickness:', value=self->GetYThick(), $
	/int, xs=3)

xaxis_labelbase=widget_base(base, /row)
xlabel=cw_bgroup(xaxis_labelbase,['No','Yes'], set_value=0, /return_name,$
/exclusive, /row, label_left='Reverse X-axis labels:')

yaxis_labelbase=widget_base(base, /row)
ylabel=cw_bgroup(yaxis_labelbase,['No','Yes'], set_value=0, /return_name,$
/exclusive, /row, label_left='Reverse Y-axis labels:')

widget_control, xgrid, set_droplist_select=self->GetXGridstyle()
widget_control, ygrid, set_droplist_select=self->GetYGridstyle()

control_buttons=cw_bgroup(base, ['OK', 'Apply', 'Cancel'], /row, /return_name)

widget_control, base, /realize, set_uval= $
	{ wids: {base:base, $
		 xticks:xticks, $
		 yticks:yticks, $
		 xminor:xminor, $
		 yminor:yminor, $
		 xticklen:xticklen, $
		 yticklen:yticklen, $
		 xgrid:xgrid, $
		 ygrid:ygrid, $
	 	 xthick:xthick, $
		 ythick:ythick, $
                 xlabel:xlabel, $
                 ylabel:ylabel}, $
	 base_id:base_id}

uval.exist.axes=base
widget_control, base_id, set_uval=uval

xmanager, 'CPlotWin_Menu_Axes', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CPlotWin_Menu_Axes_Control', control_buttons, /just_reg, $
	/no_block

end
