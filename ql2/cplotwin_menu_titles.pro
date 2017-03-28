pro CPlotWin_Menu_Titles_event, event

end

pro CPlotWin_Menu_Titles_Control_event, event

if event.value eq 'Cancel' then widget_control, event.top, /destroy $
else begin
	widget_control, event.top, get_uval=uval
	widget_control, uval.base_id, get_uval=main_uval
	self=*(main_uval.self_ptr)
	
	widget_control, uval.wids.title, get_value=title
	self->SetTitle, title[0]
	widget_control, uval.wids.subtitle, get_value=subtitle
	self->SetSubTitle, subtitle[0]
	widget_control, uval.wids.xtitle, get_value=xtitle
	self->SetXTitle, xtitle[0]
	widget_control, uval.wids.ytitle, get_value=ytitle
	self->SetYTitle, ytitle[0]	
	widget_control, uval.wids.xmargin0, get_value=xmargin0
	widget_control, uval.wids.xmargin1, get_value=xmargin1
	self->SetXMargin, [xmargin0[0], xmargin1[0]]
	widget_control, uval.wids.ymargin0, get_value=ymargin0
	widget_control, uval.wids.ymargin1, get_value=ymargin1
	self->SetYMargin, [ymargin0[0], ymargin1[0]]
	widget_control, uval.wids.xcharsize, get_value=xcharsize
	self->SetXCharsize, xcharsize[0]
	widget_control, uval.wids.ycharsize, get_value=ycharsize
	self->SetYCharsize, ycharsize[0]

	self->DrawPlot

	if event.value eq 'OK' then widget_control, event.top, /destroy

endelse 

end

pro CPlotWin_Menu_Titles, base_id

widget_control, base_id, get_uval=uval

self=*(uval.self_ptr)

title=self->GetTitle()
subtitle=self->GetSubtitle()
xtitle=self->GetXtitle()
ytitle=self->GetYTitle()
xmargin=self->GetXMargin()
ymargin=self->GetYMargin()
xcharsize=self->GetXCharsize()
ycharsize=self->GetYCharsize()

;make widgets
base=widget_base(/col, title='Format Titles', group_leader=base_id)
title_box=cw_field(base, title='Title:', value=title, xs=16)
subtitle_box=cw_field(base, title='Subtitle:', value=subtitle, xs=16)
xtitle_box=cw_field(base, title='X Title:', value=xtitle, xs=16)
ytitle_box=cw_field(base, title='Y Title:', value=ytitle, xs=16)
xmargin_base=widget_base(base, /row)
xmargin0_box=cw_field(xmargin_base, title='X Margin:', value=xmargin[0], $
	xs=3, /int)
xmargin1_box=cw_field(xmargin_base, title=' , ', value=xmargin[1], $
	xs=3, /int)
ymargin_base=widget_base(base, /row)
ymargin0_box=cw_field(ymargin_base, title='Y Margin:', value=ymargin[0], $
	xs=3, /int)
ymargin1_box=cw_field(ymargin_base, title=' , ', value=ymargin[1], $
	xs=3, /int)
charsize_base=widget_base(base, /row)
xcharsize_box=cw_field(charsize_base, title='X Charsize:', value=xcharsize, $
	xs=3, /floating)
ycharsize_box=cw_field(charsize_base, title='Y Charsize:', value=ycharsize, $
	xs=3, /floating)

control_buttons=cw_bgroup(base, ['OK', 'Apply', 'Cancel'], /row, /return_name)

widget_control, base, /realize, set_uval= $
	{ wids: {base:base, $
		title:title_box, $
		subtitle:subtitle_box, $
		xtitle:xtitle_box, $
		ytitle:ytitle_box, $
		xmargin0:xmargin0_box, $
		ymargin0:ymargin0_box, $
		xmargin1:xmargin1_box, $
		ymargin1:ymargin1_box, $
		xcharsize:xcharsize_box, $
		ycharsize:ycharsize_box}, $
	 base_id:base_id}


uval.exist.titles=base
widget_control, base_id, set_uval=uval

xmanager, 'CPlotWin_Menu_Titles', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CPlotWin_Menu_Titles_Control', control_buttons, /just_reg, $
	/no_block

end
