;+
; NAME: cplotwin__define
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 27MAY2005 - MWM: wrote this header.
; 	2006-03-10. Store/restore !p.multi in addition to window id.
; 				M.Perrin
; 	2007-06-28	M. Perrin: Added code to check for GMOS format data cubes.
; 	2007-07-03	MDP: Fix multiple pointer leaks on startup.
; 				and on every plot, from the wavelength solution
;   2007-10-31  MDP: axes labels for contour plots. Rearranged and improved
;   			labelling for cplotwin options. 
;   			TODO: add Y axis label for DN/second vs DN. 
;   			TODO: add option to average or total when extracting from the
;   			cube
;-

function CPlotWin::Init, ParentBaseId=ParentBaseId, title=title, xs=xs, $
    ys=ys, p_DispIm=p_DispIm, p_Im=p_Im, type=type, $
    win_backing=win_backing

; get window title
if keyword_set(title) then t=title else t='Plot Window'

; get default window size
if keyword_set(xs) then xsize=xs else xsize = 540
if keyword_set(ys) then ysize=ys else ysize = 300

; if a parent for the new window is given, use it for a group leader
if keyword_set(ParentBaseId) then begin
    ParentId=ParentBaseId
    base=widget_base(title=t, group_leader=ParentBaseId, /col, $
       mbar=cplotwin_mbar, /tlb_size_events, /tlb_kill_request_events)
endif else begin
    base=widget_base(title=t, /col, mbar=cplotwin_mbar, /tlb_size_events, $
                    /tlb_kill_request_events)
    ParentId=base
endelse

; instantiate a new print object to be used for the duration of the cplotwin
p_PrintObj=obj_new('cprint', wid_leader=base)

if not keyword_set(p_DispIm) then p_DispIm=ptr_new(fltarr(1,1))
if not keyword_set(p_Im) then p_Im=ptr_new(fltarr(1,1))

if not keyword_set(type) then type='horizontal'

if not keyword_set(win_backing) then win_backing=1

; define menu for window
junk={cw_pdmenu_s, flags:0, name:''}
cplotwin_desc = [ {cw_pdmenu_s, 1, 'File'}, $
       {cw_pdmenu_s, 0, 'Save Plot As...'}, $
       {cw_pdmenu_s, 0, 'Save Plot Data to IDL variable...'}, $
       {cw_pdmenu_s, 0, 'Print...'}, $
       {cw_pdmenu_s, 2, 'Close'}, $
       {cw_pdmenu_s, 1, 'Display'}, $
       {cw_pdmenu_s, 2, 'Redraw'}, $
       {cw_pdmenu_s, 1, 'Tools'}, $
       {cw_pdmenu_s, 0, 'Median'}, $
       {cw_pdmenu_s, 2, 'Line Fit'}, $
       {cw_pdmenu_s, 3, 'Format'}, $
       {cw_pdmenu_s, 0, 'Titles...'}, $
       {cw_pdmenu_s, 0, 'Axes...'}, $
       {cw_pdmenu_s, 2, 'Line...'} $
          ]

; get the conbase id
widget_control, ParentId, get_uval=imwin_uval
imwin_obj=*imwin_uval.self_ptr
ImObj=*(imwin_obj->GetImObj())

; make the depth plot insensitive if the display image is 2
; dimensional
if (imwin_obj->GetNAxis() lt 3) then begin
    type_list=['Horizontal Cut', $
       'Vertical Cut', $
       'Diagonal Cut', $
       'Surface Plot', $
       'Contour Plot']
endif else begin
    type_list=['Horizontal Cut', $
               'Vertical Cut', $
               'Diagonal Cut', $
               'Depth Plot', $
               'Surface Plot', $
               'Contour Plot']
endelse

combine_list = [ 'Average', 'Median', 'Total' ]

; widgets
menu=cw_pdmenu(cplotwin_mbar, cplotwin_desc, /return_name, /mbar)
rowbase = widget_base(base, row=1)
plot_type_menu=widget_droplist(rowbase, title='Plot Type:', value=type_list)
hideable_rowbase = widget_base(rowbase, row=1,space=0) ; only base widgets can be hidden...
combine_type_menu=widget_droplist(hideable_rowbase, title='calc using:', value=combine_list)
filename = widget_label(base, value = ('Filename: '+ImObj->Getfilename()))
draw=widget_draw(base, xs=xsize, ys=ysize, /motion_events, /button_events, $
    retain=win_backing)
bottom_base=widget_base(base, /col)
info_base=widget_base(bottom_base, /row)

x_label=widget_label(info_base, value='X:')
x_pos_label=widget_label(info_base, value='0', xs=70)
y_label=widget_label(info_base, value='Y:')
y_pos_label=widget_label(info_base, value='0', xs=70)
val_label=widget_label(info_base, value='Plot at X:')
val_val_label=widget_label(info_base, value='0', xs=200, /align_left)

plot_base=widget_base(bottom_base, /col, frame=2)
plot_label=widget_label(plot_base, value='PLOT AXES', /align_left)
plot_x_base=widget_base(plot_base, /row)
plot_xmin_box=cw_field(plot_x_base, title='X Range:  ', xs=10)
plot_xmax_box=cw_field(plot_x_base, title=' to ', xs=10)
plot_x_set_button=widget_button(plot_x_base, value='SET')
data_x_fix_plot=cw_bgroup(plot_x_base, 'Fix', /nonexclusive)
plot_x_log=cw_bgroup(plot_x_base, 'Log', /nonexclusive)
plot_y_base=widget_base(plot_base, /row)
plot_ymin_box=cw_field(plot_y_base, title='Y Range:  ', xs=10)
plot_ymax_box=cw_field(plot_y_base, title=' to ', xs=10)
plot_y_set_button=widget_button(plot_y_base, value='SET')
data_y_fix_plot=cw_bgroup(plot_y_base, 'Fix', /nonexclusive)
plot_y_log=cw_bgroup(plot_y_base, 'Log', /nonexclusive)


data_base=widget_base(bottom_base, /col, frame=2)
data_label=widget_label(data_base, value='INPUT DATA FROM CUBE', /align_left)
data_x_base=widget_base(data_base, /row)
data_xmin_box=cw_field(data_x_base, title='X Region: ', xs=10)
data_xmax_box=cw_field(data_x_base, title=' to ', xs=10)
data_x_set_button=widget_button(data_x_base, value='SET')
data_y_base=widget_base(data_base, /row)
data_ymin_box=cw_field(data_y_base, title='Y Region: ', xs=10)
data_ymax_box=cw_field(data_y_base, title=' to ', xs=10)
data_y_set_button=widget_button(data_y_base, value='SET')
data_width_base=widget_base(data_base, /row)
data_width_box=cw_field(data_width_base, title='Diagonal Width: ', value=imwin_obj->GetDWidth(), xs=10)
data_width_set_button=widget_button(data_width_base, value='SET')


; create a pointer to itself
temp_ptr=ptr_new(self)
; set this pointer in the imwin member variable
imwin_obj->SetPlotWin, temp_ptr

; create a pointer to hold plot values
plotval_ptr=ptr_new(/allocate)

; keep track of tlb widget id's
wids={  xpos:x_pos_label, $
        ypos:y_pos_label, $
        filename_id:filename, $
        val:val_val_label, $
        plot_type_menu:plot_type_menu, $
        combine_type_menu:combine_type_menu, $
        data_xmin:data_xmin_box, $
        data_xmax:data_xmax_box, $
        data_x_fix_plot:data_x_fix_plot, $
        data_ymin:data_ymin_box, $
        data_ymax:data_ymax_box, $
        data_y_fix_plot:data_y_fix_plot, $
        data_dwidth:data_width_box, $
        plot_xmin:plot_xmin_box, $
        plot_xmax:plot_xmax_box, $
        plot_x_log:plot_x_log, $
        plot_ymin:plot_ymin_box, $
        plot_ymax:plot_ymax_box, $
        plot_y_log:plot_y_log, $
        bottom_base:bottom_base, $
    draw:draw}

; keep track of children widgets
exist={ print:0L, $
        gaussian:0L, $
        titles:0L, $
        axes:0L, $
        line:0L}

; main window uval
uval={  self_ptr:temp_ptr, $
        plotval_ptr:plotval_ptr, $
        base_id:ParentId, $
        wids:wids, $
        exist:exist, $
        type_list_ptr:ptr_new(type_list), $
        xs:xsize, $
        ys:ysize, $
        redraw:0L, $
        draw_box:0, $
        drawing_box:0, $
        box_p0: [0,0], $
        box_p1: [1,1], $
        draw_box_p0: [0,0], $
        draw_box_p1: [1,1], $
        box_mode:'none', $
        xor_type: 6 }

widget_control, base, set_uval=uval, /realize
widget_control, draw, get_value=index

widget_control, ParentId, get_uval=win_uval
win_uval.exist.plot=base
widget_control, ParentId, set_uval=win_uval

xmanager, 'CPlotWin_Base', base, /just_reg, /no_block, $
    cleanup='ql_subbase_death'
xmanager, 'CPlotWin_Type', plot_type_menu, /just_reg, /no_block
xmanager, 'CPlotWin_Draw', draw, /just_reg, /no_block
xmanager, 'CPlotWin_Menu', menu, /just_reg, /no_block
xmanager, 'CPlotWin_XData_Set', data_x_set_button, /just_reg, /no_block
xmanager, 'CPlotWin_YData_Set', data_y_set_button, /just_reg, /no_block
xmanager, 'CPlotWin_DWidth_Set', data_width_set_button, /just_reg, /no_block
xmanager, 'CPlotWin_XFix_Plot', data_x_fix_plot, /just_reg, /no_block
xmanager, 'CPlotWin_YFix_Plot', data_y_fix_plot, /just_reg, /no_block
xmanager, 'CPlotWin_XRange_Set', plot_x_set_button, /just_reg, /no_block
xmanager, 'CPlotWin_YRange_Set', plot_y_set_button, /just_reg, /no_block
xmanager, 'CPlotWin_XLog_Set', plot_x_log, /just_reg, /no_block
xmanager, 'CPlotWin_YLog_Set', plot_y_log, /just_reg, /no_block

self.BaseId=base
self.DrawId=draw
self.DrawIndex=index
self.xs=xsize
self.ys=ysize
self.ParentBaseId=ParentId
self.MainTitle=t
self.DrawIndex=index
ptr_free, self.p_DispIm, self.p_Im, self.p_PrintObj
self.p_DispIm=p_DispIm
self.p_Im=p_Im
self.p_PrintObj=ptr_new(p_PrintObj)
self.PlotType=type
self.XData_Max=1
self.YData_Max=1

; set plot param defaults
self.xlog=0
self.ylog=0
self.xfix_prange=0
self.yfix_prange=0
self.xrange=[0,1]
self.yrange=[0,1]
self.xcharsize=1.0
self.ycharsize=1.0
self.charthick=1
self.xgridstyle=0
self.ygridstyle=0
self.linestyle= 0
self.xmargin=[10, 10]
self.ymargin=[4, 4]
self.xminor=5
self.yminor=5
self.psym=10
self.xstyle=1
self.ystyle=1
self.subtitle=''
self.symsize=1.0
self.thick=1.0
self.xthick=1.0
self.ythick=1.0
self.xticklen=0.02
self.yticklen=0.02
self.xticks=0
self.yticks=0
self.title=''
self.xtitle='X (pixels)'
self.ytitle='Y'
self.wavelength_units='microns'

; inherit the cimwin box parameters if they exist
if (imwin_uval.box_pres eq 1) then begin
    self.xdata_range=[imwin_uval.draw_box_p0[0], imwin_uval.draw_box_p1[0]]
    self.ydata_range=[imwin_uval.draw_box_p0[1], imwin_uval.draw_box_p1[1]]
endif else begin
    self.xdata_range=[0,1]
    self.ydata_range=[0,1]
endelse

; set the cprint object print defaults
self->SetPrintDefaults, imwin_obj->GetParentBaseId()

; set type menu to selected type
self->ChangePlotType, type

return, 1

end


pro CPlotWin::Cleanup
	message, 'Cleaning up CPlotWin pointers',/info
	; MWM : Fixed to make sure the ID is valid
	if widget_info(self.BaseId, /valid_id) then begin
		widget_control, self.BaseId, get_uval=uval
		obj_destroy, *self.p_PrintObj
		ptr_free,  self.p_PrintObj, self.x_plot_data, self.y_plot_data, self.wavelength_solution
		ptr_free, uval.type_list_ptr, uval.plotval_ptr
	endif
end


pro CPlotWin::DrawDepthPlot

	widget_control, self.ParentBaseId, get_uval=win_uval
	win_obj=*(win_uval.self_ptr)

	; get data
	im=*(self.p_Im)
	im=transpose(temporary(im), (win_obj->GetAxesOrder())[0:win_obj->GetNAxis()-1])
	im_s=win_obj->GetCurIm_s()
	self.xdata_max=im_s[0]-1
	self.ydata_max=im_s[1]-1

	self->UpdateText

	zs=im_s[2]

	; disable for 2D images
	if zs eq 1 then return


	; how should we combine the images?
	widget_control, self.BaseId, get_uval=uval
	combine_mode=widget_info(uval.wids.combine_type_menu, /droplist_select)
	combine_list = [ 'Average', 'Median', 'Total' ]

	x=indgen(zs)
	slice =im[self.xdata_range[0]:self.xdata_range[1], self.ydata_range[0]:self.ydata_range[1], *] 
	case combine_list[combine_mode] of
	'Total': begin 
		y=total(total(slice, 2), 1)	
	end
	'Average': begin 
		y=total(total(slice, 2), 1) /  total(total(finite(slice), 2), 1)
	end
	'Median': begin 
		szs =size(slice)
		slice = reform(slice, szs[1]*szs[2], szs[3])
		y = median(slice, dim=1)
	end
	endcase

	;y=[total(total(slice, 2), 1) / $
		   ;(float(((self.ydata_range[1]-self.ydata_range[0]) > 1) * $
		   ;((self.xdata_range[1]-self.xdata_range[0]) > 1)))]

	; resets ranges if plot type has been changed
	if (self.ResetRanges eq 1) then begin
		if (self.xfix_prange eq 0) then begin
			; check to see if slice is selected
			set=widget_info(win_uval.wids.cube_single_button, /button_set)
			if (set) then begin
				widget_control, win_uval.wids.cube_curmin, get_value=xmin
				widget_control, win_uval.wids.cube_curmax, get_value=xmax
				self.xrange=[xmin, xmax]
			endif else begin
				self.xrange=[win_obj->GetZMin(), win_obj->GetZmax()]
			endelse
		endif
		if (self.yfix_prange eq 0) then begin
			ymin=min(y, max=ymax)
			self.yrange[0]=ymin-(ymax-ymin)*0.05
			self.yrange[1]=ymax+(ymax-ymin)*0.05
		endif
		self.ResetRanges=0
		self->UpdateText
	endif

	; don't wset when printing
	if !D.Name ne 'PS' then begin
		save=!D.window
		wset, self.DrawIndex
	endif
	savemulti=!p.multi & !p.multi=0

	; plot the data
	plot, x, y, $
	  title=self.title, subtitle=self.subtitle, $
	  linestyle=self.linestyle, thick=self.thick, $
	  psym=self.psym, symsize=self.symsize, xlog=self.xlog, $
	  ylog=self.ylog, color=rgb(255, 255, 255), background=0, $
	  xrange=self.xrange, xmargin=self.xmargin, xticks=self.xticks, xstyle=self.xstyle, $
	  xticklen=self.xticklen, xthick=self.xthick, xminor=self.xminor, xtickformat='(A1)', $
	  yrange=self.yrange, ymargin=self.ymargin, yticks=self.yticks, ystyle=self.ystyle, $
	  yticklen=self.yticklen, ythick=self.ythick, yminor=self.yminor, ytickformat='(A1)'

	; put the x-axis labels in the right position
	axis, xaxis=self.xlabel, xmargin=self.xmargin, $
	  xrange=self.xrange, xticks=self.xticks, xstyle=self.xstyle, $
	  xtitle=self.xtitle, xticklen=self.xticklen, xthick=self.xthick, $
	  xminor=self.xminor, xlog=self.xlog, xcharsize=self.xcharsize, xgrid=self.xgridstyle, xtick_get=xtick

	; put the y-axis labels in the right position
	axis, yaxis=self.ylabel, ymargin=self.ymargin, $
	  yrange=self.yrange, yticks=self.yticks, ystyle=self.ystyle, $
	  ytitle=self.ytitle, yticklen=self.yticklen, ythick=self.ythick, $
	  yminor=self.yminor, ylog=self.ylog, ycharsize=self.ycharsize, ygrid=self.ygridstyle, ytick_get=ytick

	; this will determine if the data is a cube, and then plot the 
	; wavelength solution if there are sufficient .fits header
	; keywords to do so
	self->PlotWaveSolAxis, xtick, ytick

	; save the x, y plot information
	if ptr_valid(self.x_plot_data) then begin
		*(self.x_plot_data)=x
	endif else begin
		self.x_plot_data=ptr_new(x)
	endelse

	if ptr_valid(self.y_plot_data) then begin
		*(self.y_plot_data)=y
	endif else begin
		self.y_plot_data=ptr_new(y)
	endelse

	if !D.Name ne 'PS' then wset, save
	!p.multi = savemulti

	; save plot values in uval
	*(uval.plotval_ptr)=y
	widget_control, self.BaseId, set_uval=uval

	; update plotted range
	self.plottedrange=[0, zs-1]

end

function CPlotWin::WavelengthFormat, xtick
if ptr_valid(self.wavelength_solution) then begin
    wavelength_solution=*(self.wavelength_solution)
    cnt=n_elements(xtick)
    tick_values=strarr(cnt)
    for i=0,cnt-1 do begin
        str=string(wavelength_solution[xtick[i]], format='(F6.4)')
        tick_values[i]=strtrim(str,2)
    endfor
    return, tick_values
endif else begin
    return, -1
endelse

end

pro CPlotWin::PlotWaveSolAxis, xtick, ytick

widget_control, self.ParentBaseId, get_uval=cimwin_uval
win_obj=*cimwin_uval.self_ptr

; determine if the the wavelength axis is being displayed in plot

if (win_obj->GetNAxis() eq 3) then begin
    ; get data
    im=*(self.p_Im)
    im_s=win_obj->GetCurIm_s()

    ; TODO check to see if this is an OSIRIS file (no OSIRIS keyword?)

    ; find which axis is the longest, and assume this is the wavelength axis
	; TODO improved way of determining wavelength axis (e.g. from header
	; keywords)
    wavelength_length=im_s[0] > im_s[1] > im_s[2] 
    wavelength_index=where(im_s[*] eq wavelength_length)

    ; Is the horizontal axis of the plot also the wavelength axis?
	; If so, then add wavelength axis labels, if available.
	plottypes= ['depth', 'horizontal', 'vertical','diagonal']
	horizaxes= [2, 0, 1, 2] ; which cube axis is the horizontal axis in the plot?
	whichtype = where(self.plottype eq plottypes, matchct)
	if matchct eq 1 then if wavelength_index eq horizaxes[whichtype[0]] then begin
	    ; determine the wavelength solution from the fits keywords
        self->WaveSol, wavelength_length
        if ptr_valid(self.wavelength_solution) then begin
            wave_solution=*(self.wavelength_solution)
            if (wave_solution[0] ne -1) then begin
                ; plot the wavelength solution as the top axis
                tick_values=self->WavelengthFormat(xtick)
                if (self.xlabel) then wave_label=0. else wave_label=1.
                axis, xaxis=wave_label, xtitle='Wavelength (micron)', xrange=self.xrange, $
                      xstyle=self.xstyle, charsize=self.xcharsize, $
                      xticks=n_elements(tick_values)-1, xtickv=xtick, $
                      xtickname=tick_values
            endif
        endif
	endif

	; Do we need to call one of the special plot type routines?
    case self.PlotType of
        'surface': self->DrawSurfacePlot
        'contour': self->DrawContourPlot
        else:
    endcase
endif

end

pro CPlotWin::WaveSol, wavelength_length
	; take a wavelength solution from the ImWin and store
	; it here for CPlotWin. Optionally return the wavelength length.
	widget_control, self.ParentBaseId, get_uval=imwin_uval
	p_wavesol=  (*imwin_uval.self_ptr) ->Wavesol(wavelength_length)
	self->SetWavelengthSolution, p_wavesol
	
end

pro CPlotWin::DrawFilterPlot, filter_ptr
	; get plot data
	filter_data=*filter_ptr
	print, 'Drawing the filter plot'
end

pro CPlotWin::DrawHorizontalPlot

; get data
im=*(self.p_DispIm)

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

self->UpdateText

x=indgen(self.xdata_range[1]-self.xdata_range[0]+1)+self.xdata_range[0]
y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], self.ydata_range[0]:self.ydata_range[1]], $
       (self.xdata_range[1]-self.xdata_range[0]+1), (self.ydata_range[1]-self.ydata_range[0]+1)), 2) / $
       (float(self.ydata_range[1]-self.ydata_range[0]+1) > 1)]

if (self.ResetRanges eq 1) then begin
    if (self.xfix_prange eq 0) then begin
        self.xrange=self.xdata_range
    endif
    if (self.yfix_prange eq 0) then begin
        ymin=min(y, max=ymax)
        self.yrange[0]=ymin-(ymax-ymin)*0.05
        self.yrange[1]=ymax+(ymax-ymin)*0.05
    endif
    self.ResetRanges=0
    self->UpdateText
endif

; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
    wset, self.DrawIndex
endif
savemulti = !p.multi & !p.multi=0

; plot the data
plot, x, y, $
  title=self.title, subtitle=self.subtitle, $
  linestyle=self.linestyle, thick=self.thick, $
  psym=self.psym, symsize=self.symsize, xlog=self.xlog, $
  ylog=self.ylog, color=rgb(255, 255, 255), background=0, $
  xrange=self.xrange, xmargin=self.xmargin, xticks=self.xticks, xstyle=self.xstyle, $
  xticklen=self.xticklen, xthick=self.xthick, xminor=self.xminor, xtickformat='(A1)', $
  yrange=self.yrange, ymargin=self.ymargin, yticks=self.yticks, ystyle=self.ystyle, $
  yticklen=self.yticklen, ythick=self.ythick, yminor=self.yminor, ytickformat='(A1)'

; put the x-axis labels in the right position
axis, xaxis=self.xlabel, xmargin=self.xmargin, $
  xrange=self.xrange, xticks=self.xticks, xstyle=self.xstyle, $
  xtitle=self.xtitle, xticklen=self.xticklen, xthick=self.xthick, $
  xminor=self.xminor, xlog=self.xlog, xcharsize=self.xcharsize, xgrid=self.xgridstyle, xtick_get=xtick

; put the y-axis labels in the right position
axis, yaxis=self.ylabel, ymargin=self.ymargin, $
  yrange=self.yrange, yticks=self.yticks, ystyle=self.ystyle, $
  ytitle=self.ytitle, yticklen=self.yticklen, ythick=self.ythick, $
  yminor=self.yminor, ylog=self.ylog, ycharsize=self.ycharsize, ygrid=self.ygridstyle, ytick_get=ytick
  
; this will determine if the data is a cube, and then plot the 
; wavelength solution if there are sufficient .fits header
; keywords to do so
self->PlotWaveSolAxis, xtick, ytick

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti

; save plot values in uval
widget_control, self.BaseId, get_uval=uval
*(uval.plotval_ptr)=y
widget_control, self.BaseId, set_uval=uval

; update plotted range
self.plottedrange=self.xdata_range

end

pro CPlotWin::DrawVerticalPlot

; get data
im=*(self.p_DispIm)

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

self->UpdateText

x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
       self.ydata_range[0]:self.ydata_range[1]], $
       (self.xdata_range[1]-self.xdata_range[0]+1), $
       (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
       (float(self.xdata_range[1]-self.xdata_range[0]+1) > 1)]

if (self.ResetRanges eq 1) then begin
    if (self.xfix_prange eq 0) then begin
        self.xrange=self.ydata_range
    endif
    if (self.yfix_prange eq 0) then begin
        ymin=min(y, max=ymax)
        self.yrange[0]=ymin-(ymax-ymin)*0.05
        self.yrange[1]=ymax+(ymax-ymin)*0.05
    endif
    self.ResetRanges=0
    self->UpdateText
endif

; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
    wset, self.DrawIndex
endif
savemulti = !p.multi & !p.multi=0

; plot the data
plot, x, y, $
  title=self.title, subtitle=self.subtitle, $
  linestyle=self.linestyle, thick=self.thick, $
  psym=self.psym, symsize=self.symsize, xlog=self.xlog, $
  ylog=self.ylog, color=rgb(255, 255, 255), background=0, $
  xrange=self.xrange, xmargin=self.xmargin, xticks=self.xticks, xstyle=self.xstyle, $
  xticklen=self.xticklen, xthick=self.xthick, xminor=self.xminor, xtickformat='(A1)', $
  yrange=self.yrange, ymargin=self.ymargin, yticks=self.yticks, ystyle=self.ystyle, $
  yticklen=self.yticklen, ythick=self.ythick, yminor=self.yminor, ytickformat='(A1)'

; put the x-axis labels in the right position
axis, xaxis=self.xlabel, xmargin=self.xmargin, $
  xrange=self.xrange, xticks=self.xticks, xstyle=self.xstyle, $
  xtitle=self.xtitle, xticklen=self.xticklen, xthick=self.xthick, $
  xminor=self.xminor, xlog=self.xlog, xcharsize=self.xcharsize, xgrid=self.xgridstyle, xtick_get=xtick

; put the y-axis labels in the right position
axis, yaxis=self.ylabel, ymargin=self.ymargin, $
  yrange=self.yrange, yticks=self.yticks, ystyle=self.ystyle, $
  ytitle=self.ytitle, yticklen=self.yticklen, ythick=self.ythick, $
  yminor=self.yminor, ylog=self.ylog, ycharsize=self.ycharsize, ygrid=self.ygridstyle, ytick_get=ytick

; this will determine if the data is a cube, and then plot the 
; wavelength solution if there are sufficient .fits header
; keywords to do so
self->PlotWaveSolAxis, xtick, ytick

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti

; save plot values in uval
widget_control, self.BaseId, get_uval=uval
*(uval.plotval_ptr)=y
widget_control, self.BaseId, set_uval=uval

; update plotted range
self.plottedrange=self.ydata_range

end

pro CPlotWin::DrawDiagonalPlot

; get data
im=*(self.p_DispIm)

; get the cimwin obj
widget_control, self.ParentBaseId, get_uval=cimwin_uval
cimwin=*(cimwin_uval.self_ptr)
dwidth=cimwin->GetDWidth()

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

ixe1 = self.xdata_range[0]
iye1 = self.ydata_range[0]
ixe2 = self.xdata_range[1]
iye2 = self.ydata_range[1]
del_y = abs(iye2-iye1)
del_x = abs(ixe2-ixe1)
hw1 = dwidth/2
hw2 = dwidth-hw1

; if line has zero length, make simple plot
; else, do diagonal plot
if ((abs(ixe1-ixe2) le 1) and (abs(iye1-iye2) le 1)) then begin
    x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
    y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
                       self.ydata_range[0]:self.ydata_range[1]], $
                    (self.xdata_range[1]-self.xdata_range[0]+1), $
                    (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
       (float(self.xdata_range[1]-self.xdata_range[0]+1) > 1)]
    
    if (self.ResetRanges eq 1) then begin
        if (self.xfix_prange eq 0) then begin
            self.xrange=self.ydata_range
        endif
        if (self.yfix_prange eq 0) then begin
            ymin=min(y, max=ymax)
            self.yrange[0]=ymin-(ymax-ymin)*0.05
            self.yrange[1]=ymax+(ymax-ymin)*0.05
        endif
        self.ResetRanges=0
        self->UpdateText
    endif
    
    ; don't wset when printing
    if !D.Name ne 'PS' then begin
        save=!D.window
        wset, self.DrawIndex
    endif
	savemulti = !p.multi & !p.multi=0

    ; plot the data
    plot, x, y, $
      title=self.title, subtitle=self.subtitle, $
      linestyle=self.linestyle, thick=self.thick, $
      psym=self.psym, symsize=self.symsize, xlog=self.xlog, $
      ylog=self.ylog, color=rgb(255, 255, 255), background=0, $
      xrange=self.xrange, xmargin=self.xmargin, xticks=self.xticks, xstyle=self.xstyle, $
      xticklen=self.xticklen, xthick=self.xthick, xminor=self.xminor, xtickformat='(A1)', $
      yrange=self.yrange, ymargin=self.ymargin, yticks=self.yticks, ystyle=self.ystyle, $
      yticklen=self.yticklen, ythick=self.ythick, yminor=self.yminor, ytickformat='(A1)'

    ; put the x-axis labels in the right position
    axis, xaxis=self.xlabel, xmargin=self.xmargin, $
      xrange=self.xrange, xticks=self.xticks, xstyle=self.xstyle, $
      xtitle=self.xtitle, xticklen=self.xticklen, xthick=self.xthick, $
      xminor=self.xminor, xlog=self.xlog, xcharsize=self.xcharsize, xgrid=self.xgridstyle, xtick_get=xtick

    ; put the y-axis labels in the right position
    axis, yaxis=self.ylabel, ymargin=self.ymargin, $
      yrange=self.yrange, yticks=self.yticks, ystyle=self.ystyle, $
      ytitle=self.ytitle, yticklen=self.yticklen, ythick=self.ythick, $
      yminor=self.yminor, ylog=self.ylog, ycharsize=self.ycharsize, ygrid=self.ygridstyle, ytick_get=ytick

    ; this will determine if the data is a cube, and then plot the 
    ; wavelength solution if there are sufficient .fits header
    ; keywords to do so
    self->PlotWaveSolAxis, xtick, ytick
endif else begin
    ; vertical line
    if(ixe1 eq ixe2) then begin     
        if(iye1 lt iye2) then begin
            i = 0
            v_siz = iye2 - iye1
            cut = fltarr(v_siz)
            p_axis = fltarr(v_siz)
            xmin=(ixe1-hw1)>0
            xmax=(ixe1+hw2)<(im_s[1]-1)
            for j = iye1, iye2-1 do  begin
                cut[i] = mean(im[xmin:xmax, j])
                p_axis[i] = j
                i = i + 1
            endfor
        endif else begin
            i = 0
            v_siz = iye1 - iye2
            cut = fltarr(v_siz)
            p_axis = fltarr(v_siz)
            xmin=(ixe1-hw1)>0
            xmax=(ixe1+hw2)<(im_s[1]-1)
            for j = iye1-1, iye2, -1 do  begin
                cut[i] = mean(im[xmin:xmax, j])
                p_axis[i] = j
                i = i + 1
            end
        endelse
        self.xtitle = 'y pixels'
    ; horizontal line
    endif else if(iye1 eq iye2) then begin  
        if(ixe1 lt ixe2) then begin
            i = 0
            v_siz = ixe2 - ixe1
            cut = fltarr(v_siz)
            p_axis = fltarr(v_siz)
            ymin=(iye1-hw1)>0
            ymax=(iye1+hw2)<(im_s[2]-1)
            for j = ixe1, ixe2-1 do  begin
                cut[i] = mean(im[j,ymin:ymax])
                p_axis[i] = j
                i = i + 1
            end
        endif else begin
            i = 0
            v_siz = ixe1 - ixe2
            cut = fltarr(v_siz)
            p_axis = fltarr(v_siz)
            ymin=(iye1-hw1)>0
            ymax=(iye1+hw2)<(im_s[2]-1)
            for j = ixe1-1, ixe2, -1 do  begin
                cut[i] = mean(im[j,ymin:ymax] )
                p_axis[i] = j
                i = i + 1
            end
        endelse
        self.xtitle = 'x pixels'
    ; non-orthoganal cases
    endif else begin
        slope=float(iye2 - iye1)/float(ixe2 - ixe1)
        const = long(iye2 - slope*ixe2)
        
        print, strtrim(ixe1,2), ' ', strtrim(ixe2,2), ' ', strtrim(iye1,2), ' ', strtrim(iye2,2)
        print, ' the slope of these points is ', strtrim(slope,2)

        ; if the slope is gt 1 use y axis
        if (abs(slope) gt 1.0) then begin                     
            if(iye1 lt iye2) then begin
                i = 0
                v_siz = iye2 - iye1
                cut = fltarr(v_siz)
                p_axis = fltarr(v_siz)
                for j = iye1, iye2-1 do  begin
                    xmin=(floor((j-const)/slope)-hw1)>0
                    xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
                    cut[i]=mean(im[xmin:xmax, j])
                    p_axis[i] = j
                    i = i + 1
                end
            endif else begin
                i = 0
                v_siz = iye1 - iye2
                cut = fltarr(v_siz)
                p_axis = fltarr(v_siz)
                for j = iye1-1, iye2, -1 do  begin
                    xmin=(floor((j-const)/slope)-hw1)>0
                    xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
                    cut[i]=mean(im[xmin:xmax, j])
                    p_axis[i] = j
                    i = i + 1
                end
            endelse
            self.xtitle = 'y pixels'
        ; else use x axis
        endif else begin 
            ; change the plot parameters
            if(ixe1 lt ixe2) then begin
                i = 0
                v_siz = ixe2 - ixe1
                cut = fltarr(v_siz)
                p_axis = fltarr(v_siz)
                for j = ixe1, ixe2-1 do  begin
                    ymin=(floor((j*slope+const)-hw1))>0
                    ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
                    cut[i]=mean(im[j, ymin:ymax])
                    p_axis[i] = j
                    i = i + 1
                end
            endif else begin
                i = 0
                v_siz = ixe1 - ixe2
                cut = fltarr(v_siz)
                p_axis = fltarr(v_siz)
                for j = ixe1-1, ixe2, -1 do  begin
                    ymin=(floor((j*slope+const)-hw1))>0
                    ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
                    cut[i]=mean(im[j, ymin:ymax])
                    p_axis[i] = j
                    i = i + 1
                end
            endelse
            self.xtitle = 'x pixels'
        endelse
    endelse
    
    max = max(cut,min=min)
    lmax = max(p_axis,min=lmin)
    max=max+0.02*(max-min)
    min=min-0.02*(max-min) 

    print, 'diagonal cut max', strtrim(lmax,2), 'diagonal cut min', strtrim(lmin,2)

    self.xrange=[lmin,lmax]
    self.yrange=[min,max]

    self->UpdateText

    x=p_axis
    y=cut

    ; don't wset when printing
    if !D.Name ne 'PS' then begin
        save=!D.window
        wset, self.DrawIndex
    endif
	savemulti = !p.multi & !p.multi=0

    ; plot the data
    plot, p_axis, cut, $
      title=self.title, subtitle=self.subtitle, $
      linestyle=self.linestyle, thick=self.thick, $
      psym=self.psym, symsize=self.symsize, xlog=self.xlog, $
      ylog=self.ylog, color=rgb(255, 255, 255), background=0, $
      xrange=self.xrange, xmargin=self.xmargin, xticks=self.xticks, xstyle=self.xstyle, $
      xticklen=self.xticklen, xthick=self.xthick, xminor=self.xminor, xtickformat='(A1)', $
      yrange=self.yrange, ymargin=self.ymargin, yticks=self.yticks, ystyle=self.ystyle, $
      yticklen=self.yticklen, ythick=self.ythick, yminor=self.yminor, ytickformat='(A1)'

    ; put the x-axis labels in the right position
    axis, xaxis=self.xlabel, xmargin=self.xmargin, $
      xrange=self.xrange, xticks=self.xticks, xstyle=self.xstyle, $
      xtitle=self.xtitle, xticklen=self.xticklen, xthick=self.xthick, $
      xminor=self.xminor, xlog=self.xlog, xcharsize=self.xcharsize, xgrid=self.xgridstyle, xtick_get=xtick

    ; put the y-axis labels in the right position
    axis, yaxis=self.ylabel, ymargin=self.ymargin, $
      yrange=self.yrange, yticks=self.yticks, ystyle=self.ystyle, $
      ytitle=self.ytitle, yticklen=self.yticklen, ythick=self.ythick, $
      yminor=self.yminor, ylog=self.ylog, ycharsize=self.ycharsize, ygrid=self.ygridstyle, ytick_get=ytick

    ; this will determine if the data is a cube, and then plot the 
    ; wavelength solution if there are sufficient .fits header
    ; keywords to do so
    self->PlotWaveSolAxis, xtick, ytick
endelse

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti

; save plot values in uval
widget_control, self.BaseId, get_uval=uval
*(uval.plotval_ptr)=y
widget_control, self.BaseId, set_uval=uval

; update plotted range
self.plottedrange=self.ydata_range

end

pro CPlotWin::DrawContourPlot

; get data
im=*(self.p_DispIm)

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

if (self.ResetRanges eq 1) then begin
    if (self.xfix_prange eq 0) then begin
        self.xrange=self.xdata_range
    endif
    if (self.yfix_prange eq 0) then begin
        self.yrange=self.ydata_range
    endif
    self.ResetRanges=0
endif

self->UpdateText


; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
	savemulti = !p.multi & !p.multi=0
    wset, self.DrawIndex
endif

; get the corners of the box
x0=self.xdata_range[0]
x1=self.xdata_range[1]
y0=self.ydata_range[0]
y1=self.ydata_range[1]

; do error checking to make sure the user selects an appropriate box
if (abs(x0-x1) lt 3) or (abs(y0-y1) lt 3) then begin
    if ((x0+x1+y0+y1) ne 0) then begin
        wm = dialog_message('ERROR - Invalid data selection.  A contour plot must have at least 2 elements in each direction.', $
                            /error, dialog_parent=self.baseid)
    endif
endif else begin
	; compute X and Y coordinates for labeling the axes of the contour plot
	xx = indgen( 1+self.xdata_range[1]-self.xdata_range[0])+self.xdata_range[0]
	yy = indgen( 1+self.ydata_range[1]-self.ydata_range[0])+self.ydata_range[0]

    contour, $
      im[self.xdata_range[0]:self.xdata_range[1], $
         self.ydata_range[0]:self.ydata_range[1]], $
		xx,yy,$
		 xrange = self.xdata_range, yrange=self.ydata_range, $
        ;  xrange=self.xrange, yrange=self.yrange, $
      xstyle=self.xstyle, ystyle=self.ystyle, $
      title=self.title, subtitle=self.subtitle, $
      xtitle=self.xtitle, ytitle=self.ytitle, $
      xcharsize=self.xcharsize, ycharsize=self.ycharsize, $
      xmargin=self.xmargin, ymargin=self.ymargin, $
      thick=self.thick, $
      xgrid=self.xgridstyle, ygrid=self.ygridstyle, $
      xticks=self.xticks, yticks=self.yticks, $
      xticklen=self.xticklen, yticklen=self.yticklen, $
      xthick=self.xthick, ythick=self.ythick, $
      xminor=self.xminor, yminor=self.yminor, $
      xlog=self.xlog, ylog=self.ylog, color=rgb(255, 255, 255), background=0

endelse

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti


end

pro CPlotWin::DrawSurfacePlot

; get data
im=*(self.p_DispIm)

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

if (self.ResetRanges eq 1) then begin
    if (self.xfix_prange eq 0) then begin
        self.xrange=self.xdata_range
    endif
    if (self.yfix_prange eq 0) then begin    
        self.yrange=self.ydata_range
    endif
    self.ResetRanges=0
endif

self->UpdateText

; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
	savemulti = !p.multi & !p.multi=0
    wset, self.DrawIndex
endif

; get the corners of the box
x0=self.xdata_range[0]
x1=self.xdata_range[1]
y0=self.ydata_range[0]
y1=self.ydata_range[1]

; do error checking to make sure the user selects an appropriate box
if ((x0-x1) eq 0) or ((y0-y1) eq 0) then begin
    if ((x0+x1+y0+y1) ne 0) then begin
        wm = dialog_message('ERROR - Invalid data selection.  A surface plot must have at least 2 elements in each direction.', $
                            /error, dialog_parent=self.baseid)
    endif

endif else begin

    shade_surf, $
                im[self.xdata_range[0]:self.xdata_range[1], $
                   self.ydata_range[0]:self.ydata_range[1]], $
               ;   xrange=self.xrange, yrange=self.yrange, $
    xstyle=self.xstyle, ystyle=self.ystyle, $
      title=self.title, subtitle=self.subtitle, $
      xtitle=self.xtitle, ytitle=self.ytitle, $
      xcharsize=self.xcharsize, ycharsize=self.ycharsize, $
      xmargin=self.xmargin, ymargin=self.ymargin, $
      linestyle=self.linestyle, thick=self.thick, $
      xgrid=self.xgridstyle, ygrid=self.ygridstyle, $
      xticks=self.xticks, yticks=self.yticks, $
      xticklen=self.xticklen, yticklen=self.yticklen, $
      xthick=self.xthick, ythick=self.ythick, $
      xminor=self.xminor, yminor=self.yminor, $
      xlog=self.xlog, ylog=self.ylog, color=rgb(255, 255, 255), background=0
endelse

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti

end

pro CPlotWin::Draw2DGaussian, base_id

widget_control, base_id, get_uval=winbase_uval
widget_control, winbase_uval.exist.gaussian, get_uval=gauss_uval

; get data
im=*(self.p_DispIm)

im_s=size(im)
self.XData_Max=im_s[1]-1
self.YData_Max=im_s[2]-1

if (self.ResetRanges eq 1) then begin
    if (self.xfix_prange eq 0) then begin
        self.xrange=self.xdata_range
    endif
    if (self.yfix_prange eq 0) then begin
        self.yrange=self.ydata_range
    endif
    self.ResetRanges=0
endif

self->UpdateText

; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
	savemulti = !p.multi & !p.multi=0
    wset, self.DrawIndex
endif

surface, *gauss_uval.plot_info.fit_data_ptr, *gauss_uval.plot_info.x_arg_ptr, $
  *gauss_uval.plot_info.y_arg_ptr, az=gauss_uval.plot_info.plot_ang, $
  xrange=self.xrange, yrange=self.yrange, $
  xstyle=self.xstyle, ystyle=self.ystyle, $
  title=self.title, subtitle=self.subtitle, $
  xtitle=self.xtitle, ytitle=self.ytitle, $
  xcharsize=self.xcharsize, ycharsize=self.ycharsize, $
  xmargin=self.xmargin, ymargin=self.ymargin, $
  linestyle=self.linestyle, thick=self.thick, $
  xgrid=self.xgridstyle, ygrid=self.ygridstyle, $
  xticks=self.xticks, yticks=self.yticks, $
  xticklen=self.xticklen, yticklen=self.yticklen, $
  xthick=self.xthick, ythick=self.ythick, $
  xminor=self.xminor, yminor=self.yminor

;            zrange=[gauss_uval.plot_info.min,gauss_uval.plot_info.max], $
;             charsize=1.5, zticks=4, zminor=4, title="Gaussian Fit"

if !D.Name ne 'PS' then wset, save
!p.multi = savemulti

end


pro CPlotWin::PlotGaussian, base_id, median=median

; create the 1 dimensional gaussian widget
; get the base uval
widget_control, base_id, get_uval=plotbase_uval

; get image object
imwin_base=self.ParentBaseId
widget_control, imwin_base, get_uval=imwin_uval

ImWinObj_ptr=imwin_uval.self_ptr
ImWinObj=*ImWinObj_ptr

ImObj_ptr=ImWinObj->GetImObj()
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'PlotWin Line Fit', group_leader=base_id, /col)
gaussbase=widget_base(base, /col, /base_align_right)
median_base=widget_base(gaussbase, /row)
median_label = widget_label(median_base, value = 'Median:')
median_val = widget_label(median_base, value = '0', frame = 2, xsize =120, $
                           /align_right)
amplitude_base=widget_base(gaussbase, /row)
amplitude_label = widget_label(amplitude_base, value = 'Amplitude:')
amplitude_val = widget_label(amplitude_base, value = '0', frame = 2, xsize =120, $
                           /align_right)
xcenter_base=widget_base(gaussbase, /row)
xcenter_label = widget_label(xcenter_base, value = 'X center:')
xcenter_val = widget_label(xcenter_base, value = '0', frame = 2, xsize =120, $
                           /align_right)
xfwhm_base=widget_base(gaussbase, /row)
xfwhm_label = widget_label(xfwhm_base, value = 'X FWHM:')
xfwhm_val = widget_label(xfwhm_base, value = '0', frame = 2, xsize =120, $
                         /align_right)
minbase=widget_base(gaussbase, /row)
minlabel = widget_label(minbase, value = 'Minimum pixel value:')
minval = widget_label(minbase, value = '0', frame = 2, xsize =120, $
                      /align_right)
maxbase=widget_base(gaussbase, /row)
maxlabel = widget_label(maxbase, value = 'Maximum pixel value:')
maxval = widget_label(maxbase, value = '0', frame = 2, xsize =120, $
                      /align_right)
control_base=widget_base(gaussbase, /row)
; negative_fit_button
fit_list=widget_droplist(control_base, value=['Gaussian', 'Lorentzian', 'Moffat'], title='Fit Type:')
recalc_button=widget_button(control_base, value="Line Fit")
median_button=widget_button(control_base, value="Median Fit")
close_button=widget_button(base, value='Close')

; set the gaussian routine uvals
wids = {base_id:base_id, $
        median_id: median_val, $
        amplitude_id: amplitude_val, $
        xcenter_id: xcenter_val, $
        xfwhm_id: xfwhm_val, $
        minval_id: minval, $
        maxval_id: maxval, $
        fitlist_id:fit_list}
plot_info = {raw_data_ptr:ptr_new(), $
             fit_data_ptr:ptr_new(), $
             x_arg_ptr:ptr_new(), $
             y_arg_ptr:ptr_new(), $
             plot_ang:30, $
             min:0, $
             max:0}
uval = {base_id:base_id, $
        wids:wids, $
        plot_info:plot_info, $
        draw1_idx:0L, $
        draw2_idx:0L}

; realize widget
widget_control, base, /realize, set_uvalue=uval

if keyword_set(median) then begin
    self->CalcMedian, base
endif else begin
    self->CalcGauss, base
endelse

xmanager, 'CPlotWin_Gauss_Base', base, /just_reg, /no_block, $
  cleanup='ql_subbase_death'
xmanager, 'CPlotWin_RecalcGauss_Button', recalc_button, /just_reg, /no_block
xmanager, 'CPlotWin_Median_Button', median_button, /just_reg, /no_block
xmanager, 'CPlotWin_Gauss_Button', close_button, /just_reg, /no_block
xmanager, 'CPlotWin_Fit_List', fit_list, /just_reg, /no_block

; register existence of base
plotbase_uval.exist.gaussian=base

; set the base uval
widget_control, base_id, set_uval=plotbase_uval

end

pro CPlotWin::CalcGauss, base

	widget_control, base, get_uval=gauss_uval
	widget_control, self.ParentBaseId, get_uval=win_uval
	win_obj=*(win_uval.self_ptr)

	; get data
	im=*(self.p_DispIm)

	case self.PlotType of
	'depth': begin ; Depth Plot
			; get a different image, 
			im=*(self.p_Im)
			im=transpose(temporary(im), (win_obj->GetAxesOrder())[0:win_obj->GetNAxis()-1])
			im_s=win_obj->GetCurIm_s()
			zdata_range=[self.xrange[0],self.xrange[1]-1]
			zs=im_s[2]        
			
			; disable for 2D images
			if zs eq 1 then return

			x=indgen(zdata_range[1]-zdata_range[0]+1)+zdata_range[0]
			y=[total(total(im[self.xdata_range[0]:self.xdata_range[1], $
							  self.ydata_range[0]:self.ydata_range[1], $
							  self.xrange[0]:self.xrange[1]-1], $
						   2), 1) / $
			   (float(((self.ydata_range[1]-self.ydata_range[0]) > 1) * $
					  ((self.xdata_range[1]-self.xdata_range[0]) > 1)))]
		end
		'horizontal': begin    ; Horizontal Cut
			x=indgen(self.xdata_range[1]-self.xdata_range[0]+1)+self.xdata_range[0]
			y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
							   self.ydata_range[0]:self.ydata_range[1]], $
							(self.xdata_range[1]-self.xdata_range[0]+1), $
							(self.ydata_range[1]-self.ydata_range[0]+1)), 2) / $
			   (float(self.ydata_range[1]-self.ydata_range[0]) > 1)]
	 end
	 'vertical': begin  ; Vertical Cut
			x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
			y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
		       self.ydata_range[0]:self.ydata_range[1]], $
		       (self.xdata_range[1]-self.xdata_range[0]+1), $
		       (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
		       (float(self.xdata_range[1]-self.xdata_range[0]) > 1)]
	    end
	    'diagonal': begin  ; Diagonal Cut
		; get the cimwin obj
		widget_control, self.ParentBaseId, get_uval=cimwin_uval
		cimwin=*(cimwin_uval.self_ptr)
		dwidth=cimwin->GetDWidth()

		im_s=size(im)
		self.XData_Max=im_s[1]-1
		self.YData_Max=im_s[2]-1

		ixe1 = self.xdata_range[0]
		iye1 = self.ydata_range[0]
		ixe2 = self.xdata_range[1]
		iye2 = self.ydata_range[1]
		del_y = abs(iye2-iye1)
		del_x = abs(ixe2-ixe1)
		hw1 = dwidth/2
		hw2 = dwidth-hw1

			; if line has zero length, make simple plot
			; else, do diagonal plot
			if ((abs(ixe1-ixe2) le 1) and (abs(iye1-iye2) le 1)) then begin
		    x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
		    y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
				       self.ydata_range[0]:self.ydata_range[1]], $
				    (self.xdata_range[1]-self.xdata_range[0]+1), $
				    (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
		       (float(self.xdata_range[1]-self.xdata_range[0]+1) > 1)]
		endif else begin
		    ; vertical line
		    if(ixe1 eq ixe2) then begin     
			if(iye1 lt iye2) then begin
			    i = 0
			    v_siz = iye2 - iye1
			    cut = fltarr(v_siz)
			    p_axis = fltarr(v_siz)
			    xmin=(ixe1-hw1)>0
			    xmax=(ixe1+hw2)<(im_s[1]-1)
			    for j = iye1, iye2-1 do  begin
				cut[i] = mean(im[xmin:xmax, j])
				p_axis[i] = j
				i = i + 1
			    endfor
			endif else begin
		    i = 0
		    v_siz = iye1 - iye2
		    cut = fltarr(v_siz)
		    p_axis = fltarr(v_siz)
		    xmin=(ixe1-hw1)>0
		    xmax=(ixe1+hw2)<(im_s[1]-1)
		    for j = iye1-1, iye2, -1 do  begin
			cut[i] = mean(im[xmin:xmax, j])
			p_axis[i] = j
			i = i + 1
		    end
		endelse
		    ; horizontal line
		    endif else if(iye1 eq iye2) then begin  
			if(ixe1 lt ixe2) then begin
			    i = 0
			    v_siz = ixe2 - ixe1
			    cut = fltarr(v_siz)
			    p_axis = fltarr(v_siz)
			    ymin=(iye1-hw1)>0
			    ymax=(iye1+hw2)<(im_s[2]-1)
			    for j = ixe1, ixe2-1 do  begin
				cut[i] = mean(im[j,ymin:ymax])
				p_axis[i] = j
				i = i + 1
			    end
			endif else begin
			    i = 0
			    v_siz = ixe1 - ixe2
			    cut = fltarr(v_siz)
			    p_axis = fltarr(v_siz)
			    ymin=(iye1-hw1)>0
			    ymax=(iye1+hw2)<(im_s[2]-1)
			    for j = ixe1-1, ixe2, -1 do  begin
				cut[i] = mean(im[j,ymin:ymax] )
				p_axis[i] = j
				i = i + 1
			    end
			endelse
			self.xtitle = 'x pixels'
		    ; non-orthoganal cases
		    endif else begin
			slope=float(iye2 - iye1)/float(ixe2 - ixe1)
			const = long(iye2 - slope*ixe2)
		
			; if the slope is gt 1 use y axis
			if (abs(slope) gt 1.0) then begin                     
			    if(iye1 lt iye2) then begin
				i = 0
				v_siz = iye2 - iye1
				cut = fltarr(v_siz)
				p_axis = fltarr(v_siz)
				for j = iye1, iye2-1 do  begin
				    xmin=(floor((j-const)/slope)-hw1)>0
				    xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
				    cut[i]=mean(im[xmin:xmax, j])
				    p_axis[i] = j
				    i = i + 1
				end
			    endif else begin
				i = 0
				v_siz = iye1 - iye2
				cut = fltarr(v_siz)
				p_axis = fltarr(v_siz)
				for j = iye1-1, iye2, -1 do  begin
			    xmin=(floor((j-const)/slope)-hw1)>0
			    xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
			    cut[i]=mean(im[xmin:xmax, j])
			    p_axis[i] = j
			    i = i + 1
			end
			    endelse
			; else use x axis
			endif else begin 
			    ; change the plot parameters
			    if(ixe1 lt ixe2) then begin
				i = 0
				v_siz = ixe2 - ixe1
				cut = fltarr(v_siz)
				p_axis = fltarr(v_siz)
				for j = ixe1, ixe2-1 do  begin
				    ymin=(floor((j*slope+const)-hw1))>0
				    ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
				    cut[i]=mean(im[j, ymin:ymax])
				    p_axis[i] = j
				    i = i + 1
				end
			    endif else begin
				i = 0
				v_siz = ixe1 - ixe2
				cut = fltarr(v_siz)
				p_axis = fltarr(v_siz)
				for j = ixe1-1, ixe2, -1 do  begin
				    ymin=(floor((j*slope+const)-hw1))>0
				    ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
				    cut[i]=mean(im[j, ymin:ymax])
				    p_axis[i] = j
				    i = i + 1
				end
			    endelse
			    self.xtitle = 'x pixels'
			endelse
		    endelse
		    x=p_axis
		    y=cut    
		endelse
	    end
	    'surface': begin   ; Surface Plot
		print, 'surface 2d gauss fit not supported'
		return
	    end
	    'contour': begin   ; Contour Plot
		print, 'contour 2d gauss fit not supported'
		return
	    end
		else:
	endcase

	self->DrawPlot

	; find out what type of fit we're doing
	case self.fit_type of 
		    0: begin
			; perform a gaussian fit
			yfit=gaussfit(x, y, coeff)
		    end
		    1: begin
			; perform a lorentzian fit
			yfit=mpfitpeak(x, y, coeff, /lorentzian)
		    end
		    2: begin
			; perform a moffat fit
			yfit=mpfitpeak(x, y, coeff, /moffat)
		    end
	endcase

	; calculate a 1D gaussian fit to the data
	; yfit=gaussfit(x, y, coeff)

	; calculate the min and max pixels in the draw box
	min=strtrim(min(y, max=max), 2)
	max=strtrim(max, 2)

	; don't wset when printing
	if !D.Name ne 'PS' then begin
	    save=!D.window
		savemulti = !p.multi & !p.multi=0
	    wset, self.DrawIndex
	endif

	oplot, x, yfit

	if !D.Name ne 'PS' then wset, save
	!p.multi = savemulti

	; update values in gaussian widget ids
	widget_control, gauss_uval.wids.median_id, set_value='N/A'
	widget_control, gauss_uval.wids.amplitude_id, set_value=strtrim(coeff[0], 2)
	widget_control, gauss_uval.wids.xfwhm_id, set_value=strtrim(coeff[2]*2.355, 2)
	widget_control, gauss_uval.wids.minval_id, set_value=min
	widget_control, gauss_uval.wids.maxval_id, set_value=max

	widget_control, gauss_uval.wids.xcenter_id, set_value=strtrim(coeff[1], 2)

	; check to see if there is a wavelength solution for this plot
	if ptr_valid(self->GetWavelengthSolution()) then begin
	    ; add the wavelength position
	    wavelength_solution=*(self->GetWavelengthSolution())
	    wavelength_units=self->GetWavelengthUnits()
	    if (wavelength_solution[0] ne -1) then begin
			wave_str=string(wavelength_solution[fix(coeff[1])], format='(F6.4)')
			xval=strtrim(coeff[1],2)+' @ '+strtrim(wave_str,2)+' '
			widget_control, gauss_uval.wids.xcenter_id, set_value=strtrim(xval, 2)            
	    endif else begin
		xval=strtrim(coeff[1],2)
		widget_control, gauss_uval.wids.xcenter_id, set_value=strtrim(xval, 2)
	    endelse
	endif else begin
	    xval=strtrim(coeff[1],2)
	    widget_control, gauss_uval.wids.xcenter_id, set_value=strtrim(xval, 2)
	endelse

end

pro CPlotWin::CalcMedian, base

widget_control, base, get_uval=gauss_uval
widget_control, self.ParentBaseId, get_uval=win_uval
win_obj=*(win_uval.self_ptr)

; get data
im=*(self.p_DispIm)

case self.PlotType of
    'depth': begin ; Depth Plot
        ; get a different image 
        im=*(self.p_Im)
        im=transpose(temporary(im), (win_obj->GetAxesOrder())[0:win_obj->GetNAxis()-1])
        im_s=win_obj->GetCurIm_s()
        zdata_range=[self.xrange[0],self.xrange[1]-1]
        zs=im_s[2]        
        
        ; disable for 2D images
        if zs eq 1 then return

        x=indgen(zdata_range[1]-zdata_range[0]+1)+zdata_range[0]
        y=[total(total(im[self.xdata_range[0]:self.xdata_range[1], $
                          self.ydata_range[0]:self.ydata_range[1], $
                          self.xrange[0]:self.xrange[1]-1], $
                       2), 1) / $
           (float(((self.ydata_range[1]-self.ydata_range[0]) > 1) * $
                  ((self.xdata_range[1]-self.xdata_range[0]) > 1)))]
    end
    'horizontal': begin    ; Horizontal Cut
        x=indgen(self.xdata_range[1]-self.xdata_range[0]+1)+self.xdata_range[0]
        y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
                           self.ydata_range[0]:self.ydata_range[1]], $
                        (self.xdata_range[1]-self.xdata_range[0]+1), $
                        (self.ydata_range[1]-self.ydata_range[0]+1)), 2) / $
           (float(self.ydata_range[1]-self.ydata_range[0]) > 1)]
    end
    'vertical': begin  ; Vertical Cut
        x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
        y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
               self.ydata_range[0]:self.ydata_range[1]], $
               (self.xdata_range[1]-self.xdata_range[0]+1), $
               (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
               (float(self.xdata_range[1]-self.xdata_range[0]) > 1)]
    end
    'diagonal': begin  ; Diagonal Cut
        ; get the cimwin obj
        widget_control, self.ParentBaseId, get_uval=cimwin_uval
        cimwin=*(cimwin_uval.self_ptr)
        dwidth=cimwin->GetDWidth()

        im_s=size(im)
        self.XData_Max=im_s[1]-1
        self.YData_Max=im_s[2]-1

        ixe1 = self.xdata_range[0]
        iye1 = self.ydata_range[0]
        ixe2 = self.xdata_range[1]
        iye2 = self.ydata_range[1]
        del_y = abs(iye2-iye1)
        del_x = abs(ixe2-ixe1)
        hw1 = dwidth/2
        hw2 = dwidth-hw1

        ; if line has zero length, make simple plot
        ; else, do diagonal plot
        if ((abs(ixe1-ixe2) le 1) and (abs(iye1-iye2) le 1)) then begin
            x=indgen(self.ydata_range[1]-self.ydata_range[0]+1)+self.ydata_range[0]
            y=[total(reform(im[self.xdata_range[0]:self.xdata_range[1], $
                               self.ydata_range[0]:self.ydata_range[1]], $
                            (self.xdata_range[1]-self.xdata_range[0]+1), $
                            (self.ydata_range[1]-self.ydata_range[0]+1)), 1) / $
               (float(self.xdata_range[1]-self.xdata_range[0]+1) > 1)]
        endif else begin
            ; vertical line
            if(ixe1 eq ixe2) then begin     
                if(iye1 lt iye2) then begin
                    i = 0
                    v_siz = iye2 - iye1
                    cut = fltarr(v_siz)
                    p_axis = fltarr(v_siz)
                    xmin=(ixe1-hw1)>0
                    xmax=(ixe1+hw2)<(im_s[1]-1)
                    for j = iye1, iye2-1 do  begin
                        cut[i] = mean(im[xmin:xmax, j])
                        p_axis[i] = j
                        i = i + 1
                    endfor
                endif else begin
            i = 0
            v_siz = iye1 - iye2
            cut = fltarr(v_siz)
            p_axis = fltarr(v_siz)
            xmin=(ixe1-hw1)>0
            xmax=(ixe1+hw2)<(im_s[1]-1)
            for j = iye1-1, iye2, -1 do  begin
                cut[i] = mean(im[xmin:xmax, j])
                p_axis[i] = j
                i = i + 1
            end
        endelse
            ; horizontal line
            endif else if(iye1 eq iye2) then begin  
                if(ixe1 lt ixe2) then begin
                    i = 0
                    v_siz = ixe2 - ixe1
                    cut = fltarr(v_siz)
                    p_axis = fltarr(v_siz)
                    ymin=(iye1-hw1)>0
                    ymax=(iye1+hw2)<(im_s[2]-1)
                    for j = ixe1, ixe2-1 do  begin
                        cut[i] = mean(im[j,ymin:ymax])
                        p_axis[i] = j
                        i = i + 1
                    end
                endif else begin
                    i = 0
                    v_siz = ixe1 - ixe2
                    cut = fltarr(v_siz)
                    p_axis = fltarr(v_siz)
                    ymin=(iye1-hw1)>0
                    ymax=(iye1+hw2)<(im_s[2]-1)
                    for j = ixe1-1, ixe2, -1 do  begin
                        cut[i] = mean(im[j,ymin:ymax] )
                        p_axis[i] = j
                        i = i + 1
                    end
                endelse
                self.xtitle = 'x pixels'
            ; non-orthoganal cases
            endif else begin
                slope=float(iye2 - iye1)/float(ixe2 - ixe1)
                const = long(iye2 - slope*ixe2)
        
                ; if the slope is gt 1 use y axis
                if (abs(slope) gt 1.0) then begin                     
                    if(iye1 lt iye2) then begin
                        i = 0
                        v_siz = iye2 - iye1
                        cut = fltarr(v_siz)
                        p_axis = fltarr(v_siz)
                        for j = iye1, iye2-1 do  begin
                            xmin=(floor((j-const)/slope)-hw1)>0
                            xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
                            cut[i]=mean(im[xmin:xmax, j])
                            p_axis[i] = j
                            i = i + 1
                        end
                    endif else begin
                        i = 0
                        v_siz = iye1 - iye2
                        cut = fltarr(v_siz)
                        p_axis = fltarr(v_siz)
                        for j = iye1-1, iye2, -1 do  begin
                    xmin=(floor((j-const)/slope)-hw1)>0
                    xmax=(floor((j-const)/slope)+hw2)<(im_s[1]-1)        
                    cut[i]=mean(im[xmin:xmax, j])
                    p_axis[i] = j
                    i = i + 1
                end
                    endelse
                ; else use x axis
                endif else begin 
                    ; change the plot parameters
                    if(ixe1 lt ixe2) then begin
                        i = 0
                        v_siz = ixe2 - ixe1
                        cut = fltarr(v_siz)
                        p_axis = fltarr(v_siz)
                        for j = ixe1, ixe2-1 do  begin
                            ymin=(floor((j*slope+const)-hw1))>0
                            ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
                            cut[i]=mean(im[j, ymin:ymax])
                            p_axis[i] = j
                            i = i + 1
                        end
                    endif else begin
                        i = 0
                        v_siz = ixe1 - ixe2
                        cut = fltarr(v_siz)
                        p_axis = fltarr(v_siz)
                        for j = ixe1-1, ixe2, -1 do  begin
                            ymin=(floor((j*slope+const)-hw1))>0
                            ymax=(floor((j*slope+const)+hw2))<(im_s[2]-1)        
                            cut[i]=mean(im[j, ymin:ymax])
                            p_axis[i] = j
                            i = i + 1
                        end
                    endelse
                    self.xtitle = 'x pixels'
                endelse
            endelse
            x=p_axis
            y=cut    
        endelse
    end
    'surface': begin   ; Surface Plot
        print, 'surface 2d median not supported'
        return
    end
    'contour': begin   ; Contour Plot
        print, 'contour 2d median not supported'
        return
    end
        else:
endcase

self->DrawPlot

; find out what type of fit we're doing
y_median=median(y)
yfit_sz=size(x, /n_elements)
yfit=fltarr(yfit_sz)+y_median

; calculate the min and max pixels in the draw box
min=strtrim(min(y, max=max), 2)
max=strtrim(max, 2)

; don't wset when printing
if !D.Name ne 'PS' then begin
    save=!D.window
    wset, self.DrawIndex
endif

oplot, x, yfit

if !D.Name ne 'PS' then wset, save

; update values in gaussian widget ids
widget_control, gauss_uval.wids.median_id, set_value=strtrim(y_median,2)
widget_control, gauss_uval.wids.amplitude_id, set_value='N/A'
widget_control, gauss_uval.wids.xcenter_id, set_value='N/A'
widget_control, gauss_uval.wids.xfwhm_id, set_value='N/A'
widget_control, gauss_uval.wids.minval_id, set_value=min
widget_control, gauss_uval.wids.maxval_id, set_value=max

end

pro CPlotWin::SaveAs, base_id

	widget_control, self.ParentBaseId, get_uval=imwin_uval
	imwin=*(imwin_uval.self_ptr)
 
	ImObj_ptr=imwin->GetImObj()
	ImObj=*ImObj_ptr
	filename=ImObj->GetPathFilename()

	; change the filename, so you don't overwrite the file
	filename_next=ql_get_namenext(filename)
	new_filename=filename_next+'_plot.fits'

	; get new filename
	file=dialog_pickfile(/write, group=base_id, filter='*.fits', file=new_filename)

; if cancel was not hit
if file ne '' then begin
    ; check the permissions on the path
    path=ql_getpath(file)
    permission=ql_check_permission(path)    
    if (permission eq 1) then begin
        ; make an data array from the plotted image
        x=*(self.x_plot_data)
        y=*(self.y_plot_data)
        z=-1.

        x_size=size(x, /dimensions)
        y_size=size(y, /dimensions)

        ; check to see if there is a wavelength solution for this plot
        if (imwin->GetNAxis() eq 3) then begin
            ; get data
            im=*(self.p_Im)
            im=transpose(temporary(im), (imwin->GetAxesOrder())[0:imwin->GetNAxis()-1])
            im_s=imwin->GetCurIm_s()

            ; check to see if this is an OSIRIS file (no OSIRIS keyword?)

            ; find which axis is the longest, and assume this is the wavelength axis
            wavelength_length=im_s[0] > im_s[1] > im_s[2] 
            wavelength_index=where(im_s[*] eq wavelength_length)

            ; find out if this axis is being plotted 
			plottypes= ['depth', 'horizontal', 'vertical','diagonal']
			horizaxes= [2, 0, 1, 2]
			whichtype = where(self.plottype eq plottypes, matchct)
			if matchct eq 1 then if wavelength_index eq horizaxes[whichtype[0]] then begin
			    ; determine the wavelength solution from the fits keywords
            	self->WaveSol, wavelength_length
                if ptr_valid(self.wavelength_solution) then begin
                    wave_solution=*(self.wavelength_solution)
                    if (wave_solution[0] ne -1) then begin
                        z=wave_solution
                    endif
                endif
			endif

        ; write out the file with the wavelength solution, if it exists
        ; otherwise, just write out the 2 axes of the plot
        if (z[0] gt -1) then begin
            z_size=size(z, /dimensions)
            if ((x_size eq y_size) and (x_size eq z_size)) then begin
                im=fltarr(3,x_size)
                im[0,*]=x
                im[1,*]=y
                im[2,*]=z
                ; write the image to disk
                writefits, file, im, hd
            endif else begin
                if (x_size eq y_size) then begin
                    im=fltarr(3,x_size)
                    im[0,*]=x
                    im[1,*]=y
                    ; write the image to disk
                    writefits, file, im, hd
                endif else begin
                    ; issue error message
                    message=['Error writing .fits file.', 'Please check array size.']
                    answer=dialog_message(message, dialog_parent=baseid, /error)
                endelse
            endelse
        endif else begin
            if (x_size eq y_size) then begin
                im=fltarr(2,x_size)
                im[0,*]=x
                im[1,*]=y
                ; write the image to disk
                writefits, file, im, hd
            endif else begin
                ; issue error message
                message=['Error writing .fits file.', 'Please check array size.']
                answer=dialog_message(message, dialog_parent=baseid, /error)
            endelse
        endelse
    endif else begin
        message=['Error writing .fits file.', 'Please check path permissions.']
        answer=dialog_message(message, dialog_parent=baseid, /error)
    endelse
endif

end
;----------------------------------------------------------------------
; Added by Marshall Perrin, based on code from Dave Fanning's 
; XSTRETCH.PRO
pro CPlotWin::SaveToVariable, base_id
	; THis routine saves the X and Y plot data into top-level IDL variables.


	x=*(self.x_plot_data)
    y=*(self.y_plot_data)
	cancelled=0.

	varname=TextBox(Title='Provide Main-Level Variable Name...', Group_Leader=base_id, $
                  Label='Enter Variable base name (will have "_x" and "_y" appended): ', Cancel=cancelled, XSize=200, Value=thingname) 

	; Dave Fanning says:
	;
	;; The ROUTINE_NAMES function is not documented in IDL,
	;; so it may not always work. This capability has been
	;; tested in IDL versions 5.3 through 5.6 and found to work.
	;; People with IDL 6.1 and higher should use SCOPE_VARFETCH to
	;; set main-level variables. I use the older, undocumented version
	;; to stay compatible with more users.
	
	if not cancelled then begin
	    dummy=Routine_Names(varname+"_x", x, Store=1)
	    dummy=Routine_Names(varname+"_y", y, Store=1)
	endif
	
end

pro CPlotWin::Print, base_id
	
	cprint_ptr=self.p_PrintObj
	p_PrintObj=*cprint_ptr
	
	; gets the current directory
	cd, '.', current=current_dir
	
	; get uval
	widget_control, base_id, get_uval=base_uval
	
	cancelled=p_PrintObj->DeviceSetup()
	
	if not cancelled then begin
		self->DrawPlot
		p_PrintObj->DeviceCleanup
	endif
	
	printing=p_PrintObj->getPrintDes()
	if printing then begin
	     p_PrintObj->PS2Printer
	     p_PrintObj->setPrintDes, 0
	endif
	
end


pro CPlotWin::SetPrintDefaults, conbase_id

	widget_control, conbase_id, get_uval=conbase_uval
	
	print, 'setting print defaults'
	
	cprint_ptr=self.p_PrintObj
	p_PrintObj=*cprint_ptr
	
	p_PrintObj->setXSize, 7.5
	p_PrintObj->setXOff, 0.50
	p_PrintObj->setYSize, 10.
	p_PrintObj->setYOff, 0.5
	p_PrintObj->setFilename, 'idl.ps'
	p_PrintObj->setInches, 1
	p_PrintObj->setColor, 1
	p_PrintObj->setBitsPerPixel, 8
	p_PrintObj->setEncapsulated, 0
	p_PrintObj->setIsolatin1, 0
	p_PrintObj->setPrinterName, 'q6171'
	p_PrintObj->setLandscape, 0
	p_PrintObj->setPrintDes, 0
	
end

pro CPlotWin::UpdateText
	
	widget_control, self.BaseID, get_uval=base_uval
	
	im=*(self.p_Im)
	
	; verify data range within limits
	xdata_min=0 > self.xdata_range[0]
	xdata_max=self.xdata_range[1] < self.xdata_max
	ydata_min=0 > self.ydata_range[0]
	ydata_max=self.ydata_range[1] < self.ydata_max
	
	xdata_min=xdata_min < xdata_max
	ydata_min=ydata_min < ydata_max
	
	self.xdata_range=[xdata_min, xdata_max]
	self.ydata_range=[ydata_min, ydata_max]
	
	; fix the ydata min
	; negative
	if (self.yrange[0] le -10000.) then begin
	    plot_ymin=sigfig(self.yrange[0], 3, /scientific)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] le -1.) and (self.yrange[0] gt -10000.)) then begin
	    plot_ymin=sigfig(self.yrange[0], 7)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] le -1e-3) and (self.yrange[0] gt -1.)) then begin
	    plot_ymin=sigfig(self.yrange[0], 3)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] le -1e-9) and (self.yrange[0] gt -1e-3)) then begin
	    plot_ymin=sigfig(self.yrange[0], 5)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] le 0) and (self.yrange[0] gt -1e-9)) then begin
	    plot_ymin=sigfig(self.yrange[0], 1, /scientific)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	
	; positive
	if ((self.yrange[0] lt 1e-9) and (self.yrange[0] gt 0)) then begin
	    plot_ymin=sigfig(self.yrange[0], 1, /scientific)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] ge 1e-9) and (self.yrange[0] lt 1e-3)) then begin
	    plot_ymin=sigfig(self.yrange[0], 2, /scientific)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] ge 1e-3) and (self.yrange[0] lt 1.)) then begin
	    plot_ymin=sigfig(self.yrange[0], 3)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if ((self.yrange[0] ge 1.) and (self.yrange[0] lt 1000.)) then begin
	    plot_ymin=sigfig(self.yrange[0], 5)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	if (self.yrange[0] ge 10000.) then begin
	    plot_ymin=sigfig(self.yrange[0], 3, /scientific)
	    widget_control, base_uval.wids.plot_ymin, set_value=plot_ymin[0]
	endif
	
	; fix the ydata max
	; negative
	if (self.yrange[1] le -10000.) then begin
	    plot_ymax=sigfig(self.yrange[1], 3, /scientific)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] le -1.) and (self.yrange[1] gt -10000.)) then begin
	    plot_ymax=sigfig(self.yrange[1], 7)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] le -1e-3) and (self.yrange[1] gt -1.)) then begin
	    plot_ymax=sigfig(self.yrange[1], 3)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] le -1e-9) and (self.yrange[1] gt -1e-3)) then begin
	    plot_ymax=sigfig(self.yrange[1], 5)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] le 0) and (self.yrange[1] gt -1e-9)) then begin
	    plot_ymax=sigfig(self.yrange[1], 1, /scientific)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	
	; positive
	if ((self.yrange[1] lt 1e-9) and (self.yrange[1] gt 0)) then begin
	    plot_ymax=sigfig(self.yrange[1], 1, /scientific)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] ge 1e-9) and (self.yrange[1] lt 1e-3)) then begin
	    plot_ymax=sigfig(self.yrange[1], 2, /scientific)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] ge 1e-3) and (self.yrange[1] lt 1.)) then begin
	    plot_ymax=sigfig(self.yrange[1], 3)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if ((self.yrange[1] ge 1.) and (self.yrange[1] lt 10000.)) then begin
	    plot_ymax=sigfig(self.yrange[1], 5)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	if (self.yrange[1] ge 10000.) then begin
	    plot_ymax=sigfig(self.yrange[1], 3, /scientific)
	    widget_control, base_uval.wids.plot_ymax, set_value=plot_ymax[0]
	endif
	
	widget_control, base_uval.wids.data_xmin, $
	    set_value=strtrim(self.xdata_range[0], 2)
	widget_control, base_uval.wids.data_xmax, $
	    set_value=strtrim(self.xdata_range[1], 2)
	widget_control, base_uval.wids.data_ymin, $
	    set_value=strtrim(self.ydata_range[0], 2)
	widget_control, base_uval.wids.data_ymax, $
	    set_value=strtrim(self.ydata_range[1], 2)
	
	widget_control, base_uval.wids.plot_xmin, $
	    set_value=string(format='(F8.3)', self.xrange[0])
	widget_control, base_uval.wids.plot_xmax, $
	    set_value=string(format='(F8.3)', self.xrange[1])
	
end

pro CPlotWin::UpdateImWinBox

widget_control, self.BaseID, get_uval=base_uval
widget_control, base_uval.base_id, get_uval=imwin_uval

; verify data range within limits
xdata_min=0 > self.xdata_range[0]
xdata_max=self.xdata_range[1] < self.xdata_max
ydata_min=0 > self.ydata_range[0]
ydata_max=self.ydata_range[1] < self.ydata_max

xdata_min=xdata_min < xdata_max
ydata_min=ydata_min < ydata_max

; redrawn box in the cimwin
imwin_uval.box_p0[0]=xdata_min
imwin_uval.box_p0[1]=ydata_min
imwin_uval.box_p1[0]=xdata_max
imwin_uval.box_p1[1]=ydata_max
widget_control, base_uval.Base_Id, set_uval=imwin_uval
(*(imwin_uval.self_ptr))->DrawBoxParams
(*(imwin_uval.self_ptr))->DrawImageBox_n_Circles

end

pro CPlotWin::UpdateImWinDiagonalBox

widget_control, self.BaseID, get_uval=base_uval
widget_control, base_uval.base_id, get_uval=imwin_uval

; verify data range within limits
;xdata_min=0 > self.xdata_range[0]
;xdata_max=self.xdata_range[1] < self.xdata_max
;ydata_min=0 > self.ydata_range[0]
;ydata_max=self.ydata_range[1] < self.ydata_max

;xdata_min=xdata_min < xdata_max
;ydata_min=ydata_min < ydata_max

; redrawn box in the cimwin
;imwin_uval.box_p0[0]=xdata_min
;imwin_uval.box_p0[1]=ydata_min
;imwin_uval.box_p1[0]=xdata_max
;imwin_uval.box_p1[1]=ydata_max
;widget_control, base_uval.Base_Id, set_uval=imwin_uval
(*(imwin_uval.self_ptr))->DrawImageBox_n_Circles

end

pro CPlotWin::UpdateTitleBar
    widget_control, self.BaseID, tlb_set_title=self.MainTitle
end

pro CPlotWin::ChangePlotType, type
	
	imwin_base=self.ParentBaseId
	widget_control, imwin_base, get_uval=imwin_uval
	widget_control, self.BaseId, get_uval=uval
	
	ImWin_ptr=imwin_uval.self_ptr
	ImWinObj=*(ImWin_ptr)
	pmode=*imwin_uval.pmode_ptr
	
	old_plottype=self.PlotType
	
	self.ResetRanges=1
	self.PlotType=type
	
	; set the dropdown list to match the selected new plot type
	shortnames = ['depth', 'horizontal', 'vertical', 'diagonal', 'surface', 'contour']
	longnames = ['Depth Plot','Horizontal Cut','Vertical Cut','Diagonal Cut','Surface Plot','Contour Plot']
	
	wtype = where(shortnames eq type, matchct)
	if matchct ne 1 then message, "I don't know about plot type "+type
	if not ptr_valid(uval.type_list_ptr) then message, "Unexpected null pointer! uval.type_list_ptr"
	widget_control, uval.wids.plot_type_menu, $
		set_droplist_select=(where(*uval.type_list_ptr eq (longnames[wtype])[0]  ))[0]
	widget_control, imwin_base, set_uval=imwin_uval
	
	; Update whether or not the 'calc using' droplist is shown
	if type eq 'depth' then widget_control, uval.wids.combine_type_menu, map=1 else widget_control, uval.wids.combine_type_menu, map=0

	; Draw where the plot's pixels are on the main image window
	ImWinObj->DrawPlot, imwin_base, type
	
	; update the pointing modes
	if (old_plottype ne type) then begin
	    ; leave the diagonal pointing mode on the stack
	    if ((type ne 'diagonal') and (old_plottype ne 'diagonal')) then begin
	        ImWinObj->RmPntMode, old_plottype
	    endif
	endif
	; update drawing on screen
	; pan is the first element, then delete drawing accordingly
	if pmode[0].type eq 'pan' then begin
	    ; check to see if a second pointing mode exists
	    if (size(pmode, /n_elements) gt 1) then begin
	        ; if the second element is a box, remove it since it will be redrawn
	        if (pmode[1].pointingmode eq 'box') then begin
	            if (pmode[1].type ne 'zbox') then begin
	                ; remove the previous box
	                if (imwin_uval.box_pres) then begin
	                    ImWinObj->Draw_Box, imwin_uval.draw_box_p0, imwin_uval.draw_box_p1
	                endif
	            endif
	        endif
	        ; if the second element is a circle, remove it since it will be redrawn
	        if pmode[1].pointingmode eq 'aperture' then begin
	            if ((pmode[1].type eq 'strehl') and (imwin_uval.circ_strehl_pres)) then begin
	                ImWinObj->DrawCircleParams, circ_type='strehl'
	                ImWinObj->RemoveCircle, circ_type='strehl'
	            endif
	            if ((pmode[1].type eq 'phot') and (imwin_uval.circ_phot_pres)) then begin
	                ImWinObj->DrawCircleParams, circ_type='phot'
	                ImWinObj->RemoveCircle, circ_type='phot'
	            endif
	        endif
	        ; if the second element is diagonal, then remove it
	        if pmode[1].pointingmode eq 'diag' then begin
	            if (imwin_uval.diag_pres) then begin
	                ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
	            endif
	        endif
	    endif
	endif 
	; if a circle is already drawn, then remove it
	if pmode[0].pointingmode eq 'aperture' then begin
	    if ((pmode[0].type eq 'strehl') and (imwin_uval.circ_strehl_pres)) then begin
	        ImWinObj->DrawCircleParams, circ_type='strehl'
	        ImWinObj->RemoveCircle, circ_type='strehl'
	    endif
	    if ((pmode[0].type eq 'phot') and (imwin_uval.circ_phot_pres)) then begin
	        ImWinObj->DrawCircleParams, circ_type='phot'
	        ImWinObj->RemoveCircle, circ_type='phot'
	    endif
	endif
	; if a diagonal box is already drawn, then remove it
	if pmode[0].pointingmode eq 'diag' then begin
	    if (imwin_uval.diag_pres) then begin
	        ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
	    endif
	endif
	; if a box is drawn then remove it
	if (pmode[0].pointingmode eq 'box') then begin
	    if (pmode[0].type ne 'zbox') then begin
	        ; remove the previous box
	        if (imwin_uval.box_pres) then begin
	            ImWinObj->Draw_Box, imwin_uval.draw_box_p0, imwin_uval.draw_box_p1
	        endif
	    endif
	endif

	; redraw the box if one previously exists
	if type eq 'diagonal' then begin
	    if (imwin_uval.diag_pres) then begin
	        ImWinObj->Draw_Diagonal_Box, imwin_uval.draw_diagonal_box_p0, imwin_uval.draw_diagonal_box_p1
	    endif
    endif else begin
		; all other plot types draw a regular box.
        if (imwin_uval.box_pres) then begin
            ImWinObj->DrawBoxParams
            ; get the uval again
            widget_control, imwin_base, get_uval=imwin_uval
            ImWinObj->Draw_Box, imwin_uval.draw_box_p0, imwin_uval.draw_box_p1
        endif
	endelse
	
	ImWinObj->AddPntMode, type
	
	; get the new pointing mode
	;widget_control, imwin_base, get_uval=imwin_uval
	;pmode=*imwin_uval.pmode_ptr
	
end

pro CPlotWin::DrawPlot

	widget_control, self.BaseId, get_uval=uval
	widget_control, self.ParentBaseId, get_uval=imwin_uval
	
	imwin=*(imwin_uval.self_ptr)
	ImObj=*(imwin->GetImObj())
	
	widget_control, uval.wids.filename_id, set_value='Filename: '+ImObj->GetFilename()
	
	case self.PlotType of
	    'depth': self->DrawDepthPlot
	    'horizontal': self->DrawHorizontalPlot
	    'vertical': self->DrawVerticalPlot
	    'diagonal': self->DrawDiagonalPlot
	    'surface': self->DrawSurfacePlot
	    'contour': self->DrawContourPlot
	        else:
	endcase
	
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CPLOTWIN WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


function CPlotWin::GetParentBaseId
    return, self.ParentBaseId
end

function CPlotWin::GetBaseId
    return,  self.BaseId
end

function CPlotWin::GetDrawId
    return, self.DrawId
end

function CPlotWin::GetDrawIndex
    return, self.DrawIndex
end

function CPlotWin::GetXS
    return, self.xs
end

pro CPlotWin::SetXS, newxs
    self.xs=newxs
end

function CPlotWin::GetYS
    return, self.ys
end

pro CPlotWin::SetYS, newys
    self.ys=newys
end

function CPlotWin::GetMainTitle
    return, self.MainTitle
end

pro CPlotWin::SetMainTitle, title
    self.MainTitle=title
end

function CPlotWin::GetP_DispIm
    return, self.p_DispIm
end

pro CPlotWin::SetP_DispIm, p_DispIm
    self.p_DispIm=p_DispIm
end

function CPlotWin::GetP_Im
    return, self.p_Im
end

pro CPlotWin::SetP_Im, p_Im
    self.p_Im=p_Im
end

function CPlotWin::GetPlottedRange
    return, self.PlottedRange
end

pro CPlotWin::SetPlottedRange, PlottedRange
    self.PlottedRange=PlottedRange
end

function CPlotWin::GetXdata_range
    return, self.xdata_range
end

pro CPlotWin::SetXdata_range, xdata_range
    self.xdata_range=xdata_range
end

function CPlotWin::GetYdata_range
    return, self.ydata_range
end

pro CPlotWin::SetYdata_range, ydata_range
    self.ydata_range=ydata_range
end

function CPlotWin::GetResetRanges
    return, self.ResetRanges
end

pro CPlotWin::SetResetRanges, resetranges
    self.ResetRanges=resetranges
end

function CPlotWin::GetPlotType
    return, self.PlotType
end

pro CPlotWin::SetPlotType, plottype
    self.PlotType=plottype
end

function CPlotWin::GetFitType
	return, self.fit_type
end

pro CPlotWin::SetFitType, newFitType
	self.fit_type=newFitType
end


function CPlotWin::GetXlog
    return, self.xlog
end

pro CPlotWin::SetXlog, xlog
    self.xlog=xlog
end

function CPlotWin::GetXFixPRange
    return, self.xfix_prange
end

pro CPlotWin::SetXFixPRange, xfix_prange
    self.xfix_prange=xfix_prange
end

function CPlotWin::GetYFixPRange
    return, self.yfix_prange
end

pro CPlotWin::SetYFixPRange, yfix_prange
    self.yfix_prange=yfix_prange
end

function CPlotWin::GetYlog
    return, self.ylog
end

pro CPlotWin::SetYlog, ylog
    self.ylog=ylog
end

function CPlotWin::GetGaussian
    return, self.gaussian
end

pro CPlotWin::SetGaussian, gaussian
    self.gaussian=gaussian
end

function CPlotWin::GetXcharsize
    return, self.xcharsize
end

pro CPlotWin::SetXcharsize, xcharsize
    self.xcharsize=xcharsize
end

function CPlotWin::GetYcharsize
    return, self.ycharsize
end

pro CPlotWin::SetYcharsize, ycharsize
    self.ycharsize=ycharsize
end

function CPlotWin::GetCharthick
    return, self.charthick
end

pro CPlotWin::SetCharthick, charthick
    self.charthick=charthick
end

function CPlotWin::GetXgridstyle
    return, self.xgridstyle
end

pro CPlotWin::SetXgridstyle, xgridstyle
    self.xgridstyle=xgridstyle
end

function CPlotWin::GetYgridstyle
    return, self.ygridstyle
end

pro CPlotWin::SetYgridstyle, ygridstyle
    self.ygridstyle=ygridstyle
end

function CPlotWin::GetLinestyle
    return, self.linestyle
end

pro CPlotWin::SetLinestyle, linestyle
    self.linestyle=linestyle
end

function CPlotWin::GetXmargin
    return, self.xmargin
end

pro CPlotWin::SetXmargin, xmargin
    self.xmargin=xmargin
end

function CPlotWin::GetYmargin
    return, self.ymargin
end

pro CPlotWin::SetYmargin, ymargin
    self.ymargin=ymargin
end

function CPlotWin::GetXminor
    return, self.xminor
end

pro CPlotWin::SetXminor, xminor
    self.xminor=xminor
end

function CPlotWin::GetYminor
    return, self.yminor
end

pro CPlotWin::SetYminor, yminor
    self.yminor=yminor
end

function CPlotWin::GetPsym
    return, self.psym
end

pro CPlotWin::SetPsym, psym
    self.psym=psym
end

function CPlotWin::GetXrange
    return, self.xrange
end

pro CPlotWin::SetXrange, xrange   
	self.xrange=xrange
end

function CPlotWin::GetYrange
    return, self.yrange
end

pro CPlotWin::SetYrange, yrange
    self.yrange=yrange
end

function CPlotWin::GetXstyle
    return, self.xstyle
end

pro CPlotWin::SetXstyle, xstyle
    self.xstyle=xstyle
end

function CPlotWin::GetYstyle
    return, self.ystyle
end

pro CPlotWin::SetYstyle, ystyle
    self.ystyle=ystyle
end

function CPlotWin::GetSubtitle
    return, self.subtitle
end

pro CPlotWin::SetSubtitle, subtitle
    self.subtitle=subtitle
end

function CPlotWin::GetSymsize
    return, self.symsize
end

pro CPlotWin::SetSymsize, symsize
    self.symsize=symsize
end

function CPlotWin::GetThick
    return, self.thick
end

pro CPlotWin::SetThick, thick
    self.thick=thick
end

function CPlotWin::GetXthick
    return, self.xthick
end

pro CPlotWin::SetXthick, xthick
    self.xthick=xthick
end

function CPlotWin::GetYthick
    return, self.ythick
end

pro CPlotWin::SetYthick, ythick
    self.ythick=ythick
end

function CPlotWin::GetXlabel
    return, self.xlabel
end

pro CPlotWin::SetXlabel, xlabel
    self.xlabel=xlabel
end

function CPlotWin::GetYlabel
    return, self.ylabel
end

pro CPlotWin::SetYlabel, ylabel
    self.ylabel=ylabel
end

function CPlotWin::GetXticklen
    return, self.xticklen
end

pro CPlotWin::SetXticklen, xticklen
    self.xticklen=xticklen
end

function CPlotWin::GetYticklen
    return, self.yticklen
end

pro CPlotWin::SetYticklen, yticklen
    self.yticklen=yticklen
end

function CPlotWin::GetXticks
    return, self.xticks
end

pro CPlotWin::SetXticks, xticks
    self.xticks=xticks
end

function CPlotWin::GetYticks
    return, self.yticks
end

pro CPlotWin::SetYticks, yticks
    self.yticks=yticks
end

function CPlotWin::GetTitle
    return, self.title
end

pro CPlotWin::SetTitle, title
    self.title=title
end

function CPlotWin::GetXtitle
    return, self.xtitle
end

pro CPlotWin::SetXtitle, xtitle
    self.xtitle=xtitle
end

function CPlotWin::GetYtitle
    return, self.ytitle
end

pro CPlotWin::SetYtitle, ytitle
    self.ytitle=ytitle
end

function CPlotWin::GetWavelengthSolution
    return, self.wavelength_solution
end

pro CPlotWin::SetWavelengthSolution, p_wavesol
	ptr_free, self.wavelength_solution
    self.wavelength_solution=p_wavesol
end

function CPlotWin::GetWavelengthUnits
    return, self.wavelength_units
end

pro CPlotWin::SetWavelengthUnits, wavelength_units
    self.wavelength_units=wavelength_units
end

function CPlotWin::GetXPlotData
    return, self.x_plot_data
end

pro CPlotWin::SetXPlotData, p_xplot
    self.x_plot_data=p_xplot
end

function CPlotWin::GetYPlotData
    return, self.y_plot_data
end

pro CPlotWin::SetYPlotData, p_yplot
    self.y_plot_data=p_yplot
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CPLOTWIN WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro cplotwin__define

struct={CPlotWin, $
        ParentBaseId:0L, $
        BaseId:0L, $
        DrawId:0L, $
        DrawIndex:0L, $
        MainTitle:'', $
        xs:0L, $
        ys:0L, $
        p_DispIm:ptr_new(), $
        p_Im:ptr_new(), $
        p_PrintObj:ptr_new(), $
        xdata_range:[0,1], $
        ydata_range:[0,1], $
        xdata_max:0, $
        ydata_max:0, $
        PlottedRange:[0,1], $
        ResetRanges:0, $
        PlotType:'', $
        fit_type:0, $
        xlog:0, $
        ylog:0, $
        xfix_prange:0, $
        yfix_prange:0, $
        gaussian:0, $
        xcharsize:1.0, $
        ycharsize:1.0, $
        charthick:1, $
        xgridstyle:0, $
        ygridstyle:0, $
        linestyle: 0, $
        xmargin:[10, 3], $
        ymargin:[4, 2], $
        xminor: 5, $
        yminor: 5, $
        psym:0, $
        xrange:[0.,1.], $
        yrange:[0.,1.], $
        xstyle:1, $
        ystyle:1, $
        subtitle:'X vs. Y', $
        symsize:1.0, $
        thick:1.0, $
        xthick:1.0, $
        ythick:1.0, $
        xlabel:0, $
        ylabel:0, $
        xticklen:0.02, $
        yticklen:0.02, $
        xticks:0, $
        yticks:0, $
        title:'Quicklook Plot', $
        xtitle:'X (pixels)', $
        ytitle:'Y', $
        wavelength_solution:ptr_new(), $
        wavelength_units:'microns', $
        x_plot_data:ptr_new(), $
        y_plot_data:ptr_new()}
end
