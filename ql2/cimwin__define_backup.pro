; +
; NAME: cimwin__define 
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
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; - 

function CImWin::Init, ParentBaseId=ParentBaseId, title=title, xs=xs, ys=ys, $
	xscale=xscale, yscale=yscale, p_ImObj=p_ImObj, win_backing=win_backing

; get fonts
@ql_fonts.pro

; if there is a pointer to an image object, get info from it
if keyword_set(p_ImObj) then begin
	im_ptr=p_ImObj
	im=*p_ImObj
	min=im->GetMinVal()
	max=im->GetMaxVal()
	im_xs=im->GetXS()
	im_ys=im->GetYS()
	im_zs=im->GetZS()
endif else begin  ; if not, create new one
	im_ptr=ptr_new(/allocate_heap)
	min=0.0
	max=0.0	
	im_xs=1
	im_ys=1
	im_zs=1
endelse

; create new ptr for the display image
dispim_ptr=ptr_new(/allocate_heap)

; get window title
if keyword_set(title) then t=title else t='Image Window'

; get default window size
if keyword_set(xs) then xsize=xs else xsize = 256
if keyword_set(ys) then ysize=ys else ysize = 256

; if a parent for the new window is given, use it for a group leader
if keyword_set(ParentBaseId) then begin
	ParentId=ParentBaseId
	base=widget_base(title=t, group_leader=ParentBaseId, /col, $
		mbar=cimwin_mbar, /tlb_size_events)
endif else begin
	base=widget_base(title=t, /col, mbar=cimwin_mbar, /tlb_size_events)
	ParentId=base
endelse

; calculate zooming scale
imscale=(xsize/float(im_xs))<(ysize/float(im_ys))
if keyword_set(xscale) then xscl=xscale else xscl=imscale
if keyword_set(yscale) then yscl=yscale else yscl=xscl

; get window backing store value (IDL must control backing store for some
; versions/OS's of xwin)
if not keyword_set(win_backing) then win_backing=1

; get center pixel of image (use center instead of lower left because images
; should be centered in draw window, unless dragged) in data coords
tv_p0=[im_xs/2, im_ys/2]

; handle data cubes
axes=['AXIS 1', 'AXIS 2', 'AXIS 3']
axesorder=[0, 1, 2]
if (im_zs gt 1) then begin
	naxis=3
	zmin=0
	zmax=im_zs-1
endif else begin
	naxis=2
	zmin=0
	zmax=0
endelse

; define menu for window
junk={cw_pdmenu_s, flags:0, name:''}
cimwin_desc = [ {cw_pdmenu_s, 1, 'File'}, $
		{cw_pdmenu_s, 0, 'Save As'}, $
		{cw_pdmenu_s, 0, 'Print'}, $
		{cw_pdmenu_s, 2, 'Close'}, $
		{cw_pdmenu_s, 1, 'Display'}, $
		{cw_pdmenu_s, 0, 'Redraw'}, $
		{cw_pdmenu_s, 0, 'Rotate'}, $
		{cw_pdmenu_s, 0, 'Shift'}, $
		{cw_pdmenu_s, 2, 'Negative'}, $
		{cw_pdmenu_s, 1, 'Tools'}, $
		{cw_pdmenu_s, 0, 'Statistics'}, $
		{cw_pdmenu_s, 0, 'Photometry'}, $
		{cw_pdmenu_s, 0, 'Strehl'}, $
		{cw_pdmenu_s, 0, 'Gaussian Fit'}, $
                {cw_pdmenu_s, 2, 'Digital Filter'}, $
		{cw_pdmenu_s, 3, 'Plot'}, $		
		{cw_pdmenu_s, 0, 'Depth Plot'}, $
		{cw_pdmenu_s, 0, 'Horizontal Cut'}, $
		{cw_pdmenu_s, 0, 'Vertical Cut'}, $
		{cw_pdmenu_s, 0, 'Surface'}, $
		{cw_pdmenu_s, 2, 'Contour'} $
	      ]

; widgets for the image window
menu=cw_pdmenu(cimwin_mbar, cimwin_desc, /return_name, /mbar, $
	font=ql_fonts.cimwin.menu)
draw=widget_draw(base, xs=xsize, ys=ysize, /motion_events, /button_events, $
	retain=win_backing)
top_base=widget_base(base, /col, ypad=0)
info_base=widget_base(top_base, /row, ypad=0)
zoom_base=widget_base(top_base, /row, ypad=0)
stretch_base=widget_base(top_base, /row, ypad=0)

; cursor position info labels
x_label=widget_label(info_base, value='X:', font=ql_fonts.cimwin.x_label)
x_pos_label=widget_label(info_base, value='0', xs=40, /align_right, $
	font=ql_fonts.cimwin.y_pos)
y_label=widget_label(info_base, value='Y:', xs=20, /align_right, $
	font=ql_fonts.cimwin.y_label)
y_pos_label=widget_label(info_base, value='0', xs=40, /align_right, $
	font=ql_fonts.cimwin.y_pos)
val_label=widget_label(info_base, value='Value:', xs=50, /align_right, $
	font=ql_fonts.cimwin.val_label)
val_val_label=widget_label(info_base, value='0', xs=100, /align_right, $
	font=ql_fonts.cimwin.val_val)

; zoom scale info labels
zoom_xscl_label=widget_label(zoom_base, value='XScale:', $
	font=ql_fonts.cimwin.zoom_xscl_label)
zoom_xscl_val_label=widget_label(zoom_base, value=string(format='(F6.3)', $
	xscl), xs=70, /align_right, font=ql_fonts.cimwin.zoom_xscl_val)
zoom_yscl_label=widget_label(zoom_base, value='YScale:', xs=50, $
	/align_right, font=ql_fonts.cimwin.zoom_yscl_label)
zoom_yscl_val_label=widget_label(zoom_base, value=string(format='(F6.3)', $
	yscl), xs=70, /align_right, font=ql_fonts.cimwin.zoom_yscl_val)

; stretch info label and text boxes
stretch_min_box=cw_field(stretch_base, title="Min:", $
	value=string(min), xs=8, font=ql_fonts.cimwin.stretch_min_title, $
	/return_events, fieldfont=ql_fonts.cimwin.stretch_min_val)
stretch_max_box=cw_field(stretch_base, title="Max:", $
	value=string(max), xs=8, font=ql_fonts.cimwin.stretch_max_title, $
	/return_events, fieldfont=ql_fonts.cimwin.stretch_max_val)
stretch_apply_button=widget_button(stretch_base, value='Apply', $
	font=ql_fonts.cimwin.stretch_apply)

; button that expands the window
expand_button=widget_button(top_base, value='More', $
	font=ql_fonts.cimwin.expand)

; widget base that is initiated when the expansion button is pressed
bottom_base=widget_base(base, /col, map=0)

; creation of the scale base
scale_base=widget_base(bottom_base, /row, frame=2)
xbase=widget_base(scale_base, /col, frame=2)
; x display axis droplist
xdim_list=widget_droplist(xbase, value=axes[0:naxis-1], title='X:', $
	font=ql_fonts.cimwin.xdim_list)
; x zoom buttons
xzoom_buttons=cw_bgroup(xbase, [' - ', '1:1', 'Fit', ' + '], /row, $
	/return_name, font=ql_fonts.cimwin.xzoom_buttons)

ybase=widget_base(scale_base, /col, frame=2)
; y display axis droplist
ydim_list=widget_droplist(ybase, value=axes[0:naxis-1], title='Y:', $
	font=ql_fonts.cimwin.ydim_list)
; y zoom buttons
yzoom_buttons=cw_bgroup(ybase, [' - ', '1:1', 'Fit', ' + '], /row, $
	/return_name, font=ql_fonts.cimwin.yzoom_buttons)
; nonexclusive button that can be pressed to make independent zooms
independent_zoom_button=cw_bgroup(bottom_base, ['Independent Aspect Ratio'], $
	/row, /nonexclusive, font=ql_fonts.cimwin.aspect_button)

recenter_base=widget_base(scale_base, /col, frame=2)

; center_button
center_button=cw_bgroup(recenter_base, ['Pan'], $
	/row, /nonexclusive, font=ql_fonts.cimwin.aspect_button)

; zoom box button
zbox_button=cw_bgroup(recenter_base, ['Zoom Box'], $
        /row, /nonexclusive, font=ql_fonts.cimwin.zbox_button)

; recenter button
recenter_button=widget_button(recenter_base, value='Recenter', $
        font=ql_fonts.cimwin.recenter_button)

; slicing controls for the data cube, will be desensitized if the data
; is not a cube
cube_base=widget_base(bottom_base, /col, frame=2, ypad=0)
cube_current_base=widget_base(cube_base, /row, ypad=0)

; current z slice info 
cube_curmin_label=widget_label(cube_current_base, value='ZMin:', $
	font=ql_fonts.cimwin.cube_curmin_label)
cube_curmin_val=widget_label(cube_current_base, value='0', xs=40, $
	/align_right, font=ql_fonts.cimwin.cube_curmin_val)
cube_curmax_label=widget_label(cube_current_base, value='ZMax:', xs=40, $
	/align_right, font=ql_fonts.cimwin.cube_curmax_label)
cube_curmax_val=widget_label(cube_current_base, value=strtrim(im_zs-1, 2), $
	xs=40, /align_right, font=ql_fonts.cimwin.cube_curmax_val)
cube_curzs_label=widget_label(cube_current_base, value='ZSize:', xs=40, $
	/align_right, font=ql_fonts.cimwin.cube_curzs_label)
cube_curzs_val=widget_label(cube_current_base, value=strtrim(im_zs-1), $
	xs=40, /align_right, font=ql_fonts.cimwin.cube_curzs_val)

; changing the slice range info
cube_range_base=widget_base(cube_base, /row, frame=1)
cube_range_button_base=widget_base(cube_range_base, /row, /exclusive)
cube_range_button=widget_button(cube_range_button_base, $
	value='Range:', font=ql_fonts.cimwin.cube_range_button)
cube_range_limits_base=widget_base(cube_range_base, /row)
cube_range_min_box=cw_field(cube_range_limits_base, title='Z Min:', $
	value=0, xs=5, font=ql_fonts.cimwin.cube_range_min_title, $
	fieldfont=ql_fonts.cimwin.cube_range_min_value)
cube_range_max_box=cw_field(cube_range_limits_base, title='Z Max:', $
	value=strtrim(im_zs-1, 2), xs=5, $
	font=ql_fonts.cimwin.cube_range_max_title, $
	fieldfont=ql_fonts.cimwin.cube_range_max_value)
cube_range_apply_button=widget_button(cube_range_limits_base, value='Apply', $
	font=ql_fonts.cimwin.cube_range_apply)

; single slice slider
cube_slice_base=widget_base(cube_base, /row, frame=1)
cube_single_button_base=widget_base(cube_slice_base, /row, /exclusive)
cube_single_button=widget_button(cube_single_button_base, $
	value='Slice:', font=ql_fonts.cimwin.cube_single_button)
cube_slice_slider=widget_slider(cube_slice_base, minimum=0, $
	maximum=((im_zs-1) > 1) , font=ql_fonts.cimwin.cube_slider, xs=200, /drag)

; if image is 2D (zsize=1), then don't map the cube controls
;widget_control, cube_base, map=(im_zs gt 1)

; if image is 2D (zsize=1), then make the cube controls insensitive
widget_control, cube_base, sensitive=(im_zs gt 1)

; disable depth plots for 2D images
depth_idx=(where(cimwin_desc.name eq 'Depth Plot'))[0]
widget_control, menu+depth_idx+1, sensitive=(im_zs gt 1)

; set slice range as active and disable other base
widget_control, cube_range_button, set_button=1
widget_control, cube_slice_slider, sensitive=0

init_ys=(get_widget_size(top_base))[1]+(get_widget_size(draw))[1]

; create a pointer to itself
temp_ptr=ptr_new(self, /allocate_heap)

; get the screen size
scr_size = get_screen_size()
scr_xsize = scr_size[0]
scr_ysize = scr_size[1]


; gets the current directory
cd, '.', current=current_dir

; keep track of wid get id's
wids={  xpos:x_pos_label, $
	ypos:y_pos_label, $
	val:val_val_label, $
	stretch_min:stretch_min_box, $
	stretch_max:stretch_max_box, $
	zoom_xscl:zoom_xscl_val_label, $
	zoom_yscl:zoom_yscl_val_label, $
	xdim_list:xdim_list, $
	ydim_list:ydim_list, $
        pan_button:center_button, $
	xzoom_buttons:xzoom_buttons, $
	yzoom_buttons:yzoom_buttons, $
	draw:draw, $
	top_base:top_base, $
	bottom_base:bottom_base, $
	cube_curmin: cube_curmin_val, $
	cube_curmax: cube_curmax_val, $
	cube_curzs: cube_curzs_val, $
	cube_range_button: cube_range_button, $
	cube_single_button: cube_single_button, $
	cube_range_base: cube_range_limits_base, $
	cube_slice_base: cube_single_button_base, $
	cube_range_min: cube_range_min_box, $
	cube_range_max: cube_range_max_box, $
	cube_slider: cube_slice_slider, $
        center_button: center_button, $
        zbox_button: zbox_button, $
        rotate_wid:0L, $
        zoom_wid:0L, $
	shift_wid:0L, $
	plot_wid:0L}

exist={ plot:0L, $
	statistics:0L, $
        gaussian:0L, $
        filter:0L}

; main window uval 
uval={  self_ptr:temp_ptr, $
	wids:wids, $
	exist:exist, $
	win_backing:win_backing, $
        current_dir:current_dir, $
	xs:xsize, $
	ys:ysize, $
        scr_xsize:scr_xsize, $
        scr_ysize:scr_ysize, $
	last_winxs:xsize, $
	last_winys:ysize, $
        initial_xs:0, $
	redraw:0L, $
        pan_mode:0, $
        zbox_mode:0, $
	draw_box:0, $
	drawing_box:0, $
        ps_filename:'temp.ps', $
        printer_name:'', $
        print_orient:'', $
        print_type:'File', $
        log_scale:'no', $
	box_p0: [0,0], $
	box_p1: [1,1], $
	draw_box_p0: [0,0], $
	draw_box_p1: [1,1], $
	box_mode:'none', $
	dragging_image:0, $
	wide:0, $
	tv_p0:tv_p0, $
	handle:[0,0], $
	independent_zoom:0, $
	xor_type: 10 }

; set the base uval to the uval structure defined
widget_control, base, set_uval=uval, /realize, ys=init_ys
widget_control, draw, get_value=index
widget_control, ydim_list, set_droplist_select=1

; get the initial xsize of the widget
widget_control, base, get_uval=uval
init_xsize = uval.xs
uval.initial_xs = init_xsize
widget_control, base, set_uval=uval

; register the image window events with the event handler
xmanager, 'CImWin_Resize', base, /just_reg, /no_block
xmanager, 'CImWin_Draw', draw, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_min_box, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_max_box, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_apply_button, /just_reg, /no_block
xmanager, 'CImWin_Expand_Button', expand_button, /just_reg, /no_block
xmanager, 'CImWin_Menu', menu, /just_reg, /no_block
xmanager, 'CImWin_Dim_List', xdim_list, /just_reg, /no_block
xmanager, 'CImWin_Dim_List', ydim_list, /just_reg, /no_block
xmanager, 'CImWin_Zoom', xzoom_buttons, /just_reg, /no_block
xmanager, 'CImWin_Zoom', yzoom_buttons, /just_reg, /no_block
xmanager, 'CImWin_Recenter', recenter_button, /just_reg, /no_block
xmanager, 'CImWin_Center', center_button, /just_reg, /no_block
xmanager, 'CImWin_Zbox', zbox_button, /just_reg, /no_block
xmanager, 'CImWin_Independent_Zoom', independent_zoom_button, /just_reg, $
	  /no_block
xmanager, 'CImWin_Cube_Select', cube_range_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Select', cube_single_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Slice', cube_range_apply_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Slice', cube_slice_slider, /just_reg, /no_block


; initialize object variables
self.BaseId=base
self.DrawId=draw
self.xs=xsize
self.ys=ysize
self.ParentBaseId=ParentId
self.title=t
self.DrawIndex=index
self.p_ImObj=im_ptr
self.p_DispIm=dispim_ptr
self.XScale=xscl
self.YScale=yscl
self.DispMin=min
self.DispMax=max
self.ZMin=zmin
self.ZMax=zmax
self.NAxis=naxis
self.AxesOrder=axesorder
self.ResetZ=1
self.DoAutoScale=1
self.DispIm_xs=im_xs
self.DispIm_ys=im_ys
self.CurIm_s=[im_xs, im_ys, im_zs]
return, 1

end

pro CImWin::UpdateImParam, p_ImObj

; get control base uval
widget_control, self.BaseId, get_uval=uval

	im_ptr=p_ImObj
	im=*p_ImObj
	im_zs=im->GetZS()

print, im_zs, ' z axis size'

; handle data cubes
axes=['AXIS 1', 'AXIS 2', 'AXIS 3']
axesorder=[0, 1, 2]
if (im_zs gt 1) then begin
	self.naxis=3
	self.zmin=0
	self.zmax=im_zs-1
endif else begin
	self.naxis=2
	self.zmin=0
	self.zmax=0
    endelse

widget_control, uval.wids.xdim_list, set_value=axes[0:self.naxis-1]
widget_control, uval.wids.ydim_list, set_value=axes[0:self.naxis-1]
widget_control, uval.wids.ydim_list, set_droplist_select=1
self.AxesOrder=axesorder

; set the instance pointer to the new image pointer
self.p_ImObj=p_ImObj

print, self.naxis, ' number of axes'

end

pro CImWin::UpdateDispIm

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; transpose image
im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

self.DispIm_xs=im_s[0]
self.DispIm_ys=im_s[1]

; reset Z if flag is set
if self.ResetZ eq 1 then begin
	self.ZMin=0
	self.ZMax=im_s[2]-1
	widget_control, self.BaseId, get_uval=uval
	uval.tv_p0=[im_s[0]/2, im_s[1]/2]	
	widget_control, self.BaseId, set_uval=uval

	; update cube params
	widget_control, uval.wids.cube_curzs, set_value=strtrim(im_s[2], 2)
        
        ; update current range limits
        widget_control, uval.wids.cube_range_min, set_value=strtrim(self.ZMin, 2)
        widget_control, uval.wids.cube_range_max, set_value=strtrim(self.ZMax, 2)

	; set slider max... if 2D, set max to 1 because it must be ne min
	widget_control, uval.wids.cube_slider, $
		set_slider_max=((im_s[2]-1) > 1)
	widget_control, uval.wids.cube_slider, set_value=0

	self.ResetZ=0

	; send an event as if slice range was hit
	widget_control, uval.wids.cube_range_button, /set_button
	ev={WIDGET_BUTTON, ID:uval.wids.cube_range_button, $
		TOP:self.BaseId, HANDLER:uval.wids.cube_range_button, $
		SELECT:1}
        widget_control, uval.wids.cube_range_button, send_event=ev 
endif

; collapse image
z0=self.ZMin
z1=self.ZMax
im=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)

; automatically scales the image by computing the mean and scales the
; min and max values according to the standard deviation
if self.DoAutoScale eq 1 then begin
	meanval=moment(im, sdev=im_std)
	self.DispMax=meanval[0]+5*im_std
	self.DispMin=meanval[0]-3*im_std
	self.DoAutoScale=0
	self->UpdateText
endif

; current order of the image axes
self.CurIm_s=im_s
; the pointer of the displayed image is set equal to the transposed image
*self.p_DispIm=im

end

pro CImWin::DrawImage

; get window uval
widget_control, self.BaseId, get_uval=uval

im=*self.p_DispIm

; stretch data
im=bytscl(im, min=self.DispMin, max=self.DispMax)

; get dimensions of window
win_xs=self.xs
win_ys=self.ys

; get subimage (don't use whole image because it is too slow if image gets too
; big)
x0 = 0 > fix(uval.tv_p0[0]-(win_xs/(2.*self.XScale)))
y0 = 0 > fix(uval.tv_p0[1]-(win_ys/(2.*self.YScale)))
x1 = fix(x0+1+win_xs/self.XScale) < (self.DispIm_xs - 1)
y1 = fix(y0+1+win_ys/self.YScale) < (self.DispIm_ys - 1)
im=congrid(im[x0:x1, y0:y1], (x1-x0+1)*self.XScale, (y1-y0+1)*self.YScale)

; make window active
save=!D.WINDOW
wset, self.DrawIndex

; clear window and draw new image
erase

; display the new image
tv, im, win_xs/2-((uval.tv_p0[0]-x0)*self.XScale)-1, $
	win_ys/2-((uval.tv_p0[1]-y0)*self.YScale)-1


; if a box was drawn, draw it again
if uval.draw_box eq 1 then begin
    ; get box corners in pixels
    new_x0=(uval.box_p0[0] < uval.box_p1[0])
    new_x1=(uval.box_p0[0] > uval.box_p1[0])
    new_y0=(uval.box_p0[1] < uval.box_p1[1])
    new_y1=(uval.box_p0[1] > uval.box_p1[1])

    fin_x0=floor(win_xs/2.+((new_x0-uval.tv_p0[0])*self.XScale)-2)
    fin_x1=floor(win_xs/2.+((new_x1-uval.tv_p0[0]+1)*self.XScale)-2)
    fin_y0=floor(win_ys/2.+((new_y0-uval.tv_p0[1])*self.YScale)-2)
    fin_y1=floor(win_ys/2.+((new_y1-uval.tv_p0[1]+1)*self.YScale)-2)
    
    uval.draw_box_p0=[fin_x0, fin_y0]
    uval.draw_box_p1=[fin_x1, fin_y1]
    
    widget_control, self.BaseId, set_uval=uval

    self->Draw_Box, self.BaseId, uval.draw_box_p0, uval.draw_box_p1
endif else begin
    ; set the uval
    widget_control, self.BaseId, set_uval=uval
endelse

; make window active
wset, save


end

pro CImWin::RedrawBase

; resize base... resize window controls should be added...
widget_control, self.BaseId, xs=self.xs, ys=self.ys+140
widget_control, self.DrawId, xs=self.xs, ys=self.ys
self->DrawImage

end

pro CImWin::UpdateText
; this routine will update all the text fields displayed on the gui

; get uval for wids
widget_control, self.BaseId, get_uval=base_uval

; update each field with new member variable values
widget_control, base_uval.wids.zoom_xscl, set_value=$
	string(format='(F6.3)', self.XScale)
widget_control, base_uval.wids.zoom_yscl, set_value=$
	string(format='(F6.3)', self.YScale)
widget_control, base_uval.wids.stretch_min, set_value=$
	string(format='(f8.3)', self.DispMin)
widget_control, base_uval.wids.stretch_max, set_value=$
	string(format='(f8.3)', self.DispMax)

end


pro CImWin::Draw_Box, base_id, point0, point1
; draw a box in window to select a region

; get uval
widget_control, base_id, get_uval=base_uval

; save current window for wsetting later
save=!D.WINDOW

; activate main window
wset, self.DrawIndex

; set mask to [1,1,1,1,1,...]
mask = !d.n_colors - 1

; get corners
x0=point0[0]
x1=point1[0]
y0=point0[1]
y1=point1[1]

; get min x,y and max x,y
x0pix=(x1 < x0)
x1pix=((x1 > x0)+1)
y0pix=(y1 < y0)
y1pix=((y1 > y0)+1)

; set graphics to xor type
device, get_graphics=oldg, set_graphics=base_uval.xor_type

; draw box
plots, [x0pix, x0pix, x1pix, x1pix, x0pix], $
        [y0pix, y1pix, y1pix, y0pix, y0pix], /device, color=mask

;reset graphics
device, set_graphics=oldg

; reset current window
wset, save

widget_control, base_id, set_uval=base_uval

end

pro CImWin::SaveAs, base_id

ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
im=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr
filename=ImObj->GetFilename()

; get new filename
file=dialog_pickfile(/write, group=base_id, filter='*.fits', file=filename)

; if cancel was not hit

if file ne '' then begin
	; write the image to disk
	writefits, file, im, hd

	; reset image filename
	ImObj->SetFilename, file

	; update window title
	widget_control, base_id, tlb_set_title=file
endif

end

pro CImWin::Print, base_id

ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
im=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr
filename=ImObj->GetFilename()


; gets the current directory
cd, '.', current=current_dir

; get uval
widget_control, base_id, get_uval=base_uval

; set up widgets
base=widget_base(/col, title='Print...', group_leader=base_id)
two_base=widget_base(base, /row)
left_base=widget_base(two_base, /col)
right_base=widget_base(two_base, /col)
type_text=widget_label(left_base, Value='Print to:')
tnames=['File', 'Printer']
toggle=cw_bgroup(left_base, tnames, col=1, /exclusive, /return_name, $
   set_value=0)
spacer=widget_label(right_base, Value='Name')
file_base=widget_base(right_base, /row)
fname_box=cw_field(file_base, title='File Name:', value=base_uval.ps_filename)
browse_button=widget_button(file_base, value='Browse')
pname_box=cw_field(right_base, title='Printer Name:', value=base_uval.printer_name)
orient_names=['Portrait', 'Landscape']
orient=cw_bgroup(base, orient_names, set_value=base_uval.print_orient, /row, $
                /exclusive, /return_index)
bnames=['OK', 'CANCEL']
buttons=cw_bgroup(base, bnames, row=1)

; set uval
uval={pname_box:pname_box, $
      fname_box:fname_box, $
      current_dir:current_dir, $
      orient_id:orient, $
      type:'File', $
      base_id:base_id}

;realize widgets
widget_control, base, /realize
widget_control, base, set_uval=uval
widget_control, pname_box, sensitive=0

xmanager, 'cimwin_print_toggle', toggle, /just_reg
xmanager, 'cimwin_print_buttons', buttons, /just_reg
xmanager, 'cimwin_browse_button', browse_button, /just_reg

end

pro CImWin::PsCurrent, base_id, FILE=filename, WRITE=write, PICK=pick, PRINT=print

print, 'PS Current'
print, filename
widget_control, base_id, get_uval=base_uval

; get the image data
ImObj_ptr=self->GetImObj()
title=self->GetTitle()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr
im_filename=ImObj->GetFilename()
write_filename=base_uval.ps_filename

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; transpose image
im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

; if pick is set then get filename with pickfile
; if print is not set then check that the filename is ok to write.  
; if print is set, then set check_result to yes, since
;    it is always ok to overwrite uval.ps_printfile
if (keyword_set(write)) then check_result='Yes' else begin
    if (keyword_set(pick)) then begin
        filename=dialog_pickfile(group=base_id, $
            path=base_uval.current_dir, filter='*.ps')
    endif
    check_result=ql_writecheck(base_id, write_filename)
endelse

if check_result eq 'Yes' then begin

    ; start postscript file
    set_plot, 'PS'
    device, filename=write_filename

    self->DrawImage

    ; close the file and set the display back to the screen
    device, /CLOSE
    set_plot, 'X'

    ; print the file to the printer if that keyword is set
        if (keyword_set(print)) then begin

            print, 'printing to printer'
            print, base_uval.printer_name
            
            set_plot, 'printer'

            self->DrawImage

            device, /close
            set_plot, 'X'

            ;check printer existence
;            lpq_command=strcompress('lpq -P'+base_uval.printer_name)
;            spawn, lpq_command, result

;            if result[0] eq '' then begin
;                answer=dialog_message(['Printer queue: ', base_uval.printer_name, $
;                                       'not found.'], dialog_parent=self.base_id, /error)
;            endif else begin
                                ; print it!
;                print, 'Printing on ', base_uval.printer_name
;                command=strcompress('lpr -P'+base_uval.printer_name+' '+)
;                print, command
;                spawn, command, result
                                ; if error (actually, i don't think
                                ; result is ever not '', but in case...)
;                if result[0] ne '' then begin
;                    answer=dialog_message(result, dialog_parent=self.base_id, $
;                                          /error)
;                endif

;            endelse
;    spawn, '\mv ' + uval.ps_printfile + filename
;endif

        endif

        endif
    end


pro CImWin::Rotate, base_id

widget_control, base_id, get_uval=base_uval

base=widget_base(/col, group_leader=base_id, title='Rotate')
rot_labels=['0'+string("260B), '90'+string("260B), '180'+string("260B), $
	'270'+string("260B)]
rot_buttons=cw_bgroup(base, rot_labels, /row, label_left='Rotate', $
	/exclusive, set_value=0)
flip_buttons=cw_bgroup(base, ['No', 'Yes'], /row, label_left='Flip', $
	set_value=0, /exclusive)
ok_button=widget_button(base, value='OK')
close_button=widget_button(base, value='Close')

widget_control, base, /realize, set_uval={base_id:base_id, rot:rot_buttons, $
	flip:flip_buttons}

base_uval.wids.rotate_wid=base
widget_control, base_id, set_uval=base_uval

xmanager, 'CImWin_Rotate', ok_button, /just_reg, /no_block
xmanager, 'CImWin_Rotate', close_button, /just_reg, /no_block

end

pro CImWin::Shift, base_id

widget_control, base_id, get_uval=base_uval

base=widget_base(/col, group_leader=base_id, title='Shift')
xshift_box=cw_field(base, value='0', title='Shift in X direction:')
yshift_box=cw_field(base, value='0', title='Shift in Y direction:')
ok_button=widget_button(base, value='OK')
close_button=widget_button(base, value='Close')

widget_control, base, /realize, set_uval={base_id:base_id, yshift:yshift_box, $
	xshift:xshift_box}

base_uval.wids.shift_wid=base
widget_control, base_id, set_uval=base_uval

xmanager, 'CImWin_Shift', ok_button, /just_reg, /no_block
xmanager, 'CImWin_Shift', close_button, /just_reg, /no_block

end

pro CImWin::Negative, base_id

widget_control, base_id, get_uval=base_uval

print, 'place negative code here'

end

pro CImWin::DepthPlot, base_id

; get uval
widget_control, base_id, get_uval=base_uval

; get image data
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()

; get pointer to plot object
; set curent plot mode to depth
; realize widget

; realize plot window
plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	p_DispIm=self.p_DispIm, p_Im=im_ptr, type='depth', $
	win_backing=base_uval.win_backing)

; set pointer in self
self.p_PlotWin=ptr_new(plot_win)

widget_control, base_id, get_uval=base_uval

; get plot window base id
base_uval.wids.plot_wid=plot_win->GetBaseId()
; set box mode
base_uval.box_mode='depth'
widget_control, base_id, set_uval=base_uval

end

pro CImWin::HorizontalCut, base_id

widget_control, base_id, get_uval=base_uval

; get data 
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()

; realize plot window
plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	p_DispIm=self.p_DispIm, p_Im=im_ptr, type='horizontal', $
	win_backing=base_uval.win_backing)

self.p_PlotWin=ptr_new(plot_win)

widget_control, base_id, get_uval=base_uval

; get plot window id
base_uval.wids.plot_wid=plot_win->GetBaseId()
; set box mode
base_uval.box_mode='horizontal'
widget_control, base_id, set_uval=base_uval

end

pro CImWin::VerticalCut, base_id

widget_control, base_id, get_uval=base_uval

;get data
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()

; realize plot window
plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	p_DispIm=self.p_DispIm, p_Im=im_ptr, type='vertical', $
	win_backing=base_uval.win_backing)

self.p_PlotWin=ptr_new(plot_win)

widget_control, base_id, get_uval=base_uval

; get plot window id
base_uval.wids.plot_wid=plot_win->GetBaseId()
; set box mode
base_uval.box_mode='vertical'
widget_control, base_id, set_uval=base_uval

end

pro CImWin::Surface, base_id

widget_control, base_id, get_uval=base_uval

; get image data
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()

; realize plot window
plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	p_DispIm=self.p_DispIm, p_Im=im_ptr, type='surface', $
	win_backing=base_uval.win_backing)

self.p_PlotWin=ptr_new(plot_win)

widget_control, base_id, get_uval=base_uval

; get plot window id
base_uval.wids.plot_wid=plot_win->GetBaseId()
; set box mode
base_uval.box_mode='surface'
widget_control, base_id, set_uval=base_uval

end

pro CImWin::Contour, base_id

widget_control, base_id, get_uval=base_uval

; get image data
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()

; realize plot window
plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	p_DispIm=self.p_DispIm, p_Im=im_ptr, type='contour', $
	win_backing=base_uval.win_backing)

self.p_PlotWin=ptr_new(plot_win)

widget_control, base_id, get_uval=base_uval

; get plot window id
base_uval.wids.plot_wid=plot_win->GetBaseId()
; set box mode
base_uval.box_mode='contour'
widget_control, base_id, set_uval=base_uval

end

pro CImWin::Statistics, base_id

widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Statistics', group_leader=base_id, /col)
statbase=widget_base(base, /col, /base_align_right)
filename = widget_label(statbase, value = ('Filename: '+ImObj->GetFilename()))
meanbase=widget_base(statbase, /row)
meanlabel = widget_label(meanbase, value = 'Mean pixel value:')
meanval = widget_label(meanbase, value = '0', frame = 2, xsize =120, $
	/align_right)
medbase=widget_base(statbase, /row)
medlabel = widget_label(medbase, value = 'Median pixel value:')
medval = widget_label(medbase, value = '0', frame = 2, xsize = 120, $
	/align_right)
modebase=widget_base(statbase, /row)
;modelabel = widget_label(modebase, value = 'Mode pixel value:')
;modeval = widget_label(modebase, value = '0', frame = 2, xsize =120, $
;	/align_right)
stddevbase=widget_base(statbase, /row)
stddevlabel = widget_label(stddevbase, value = 'Standard deviation:')
stddevval = widget_label(stddevbase, value = '0', frame = 2, xsize =120, $
	/align_right)
varbase=widget_base(statbase, /row)
varlabel = widget_label(varbase, value = 'Variance:')
varval = widget_label(varbase, value = '0', frame = 2, xsize =120, $
	/align_right)
minbase=widget_base(statbase, /row)
minlabel = widget_label(minbase, value = 'Minimum pixel value:')
minval = widget_label(minbase, value = '0', frame = 2, xsize =120, $
	/align_right)
maxbase=widget_base(statbase, /row)
maxlabel = widget_label(maxbase, value = 'Maximum pixel value:')
maxval = widget_label(maxbase, value = '0', frame = 2, xsize =120, $
	/align_right)
close_button=widget_button(base, value='Close')


; set uval
wids = {base_id:base_id, $
	meanval_id: meanval, $
	medval_id: medval, $
;	modeval_id: modeval, $
	stddevval_id: stddevval, $
	varval_id: varval, $
	minval_id: minval, $
	maxval_id: maxval, $
        filename_id: filename}
uval={base_id:base_id, wids:wids}

; realize widget
widget_control, base, /realize, set_uvalue=uval

; register the statistics events with xmanager
xmanager, 'CImWin_Stat_Base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CImWin_Stat_Button', close_button, /just_reg, /no_block

; register existence of base
base_uval.exist.statistics = base
; set box mode
base_uval.box_mode='stat'

widget_control, base_id, set_uval=base_uval

end

pro CImWin::CalcStat, base_id
; this routine calculates the statistics of the selected region
; corners of the box are set in uval

; get the widget uvals
widget_control, base_id, get_uval=base_uval
widget_control, base_uval.exist.statistics, get_uval=uval

; get displayed image data
im=*(self.p_DispIm)

; get corners of box
x0=base_uval.box_p0[0]
x1=base_uval.box_p1[0]
y0=base_uval.box_p0[1]
y1=base_uval.box_p1[1]

x0pix=(x1 < x0)
x1pix=((x1 > x0))
y0pix=(y1 < y0)
y1pix=((y1 > y0))


if (x0pix eq x1pix) and (y0pix eq y1pix) then begin

    ; perform statistics on a single pixel
    meanv=strtrim(im[x0,y0],2)
    std='not available'
    var='not available'
    min=strtrim(im[x0,y0],2)
    med=strtrim(im[x0,y0],2)
    max=strtrim(im[x0,y0],2)

endif else begin

    ; get subimage
    array=im[x0pix:x1pix, y0pix:y1pix]

    ; perform statistics
    meanv=strtrim(mean(array), 2)
    std=strtrim(stddev(array), 2)
    var=strtrim(variance(array), 2)
    min=strtrim(min(array, max=max), 2)
    med=strtrim(median(array), 2)
    max=strtrim(max, 2)

endelse


; set the computed values in statistics widget
widget_control, uval.wids.meanval_id, set_value=meanv
widget_control, uval.wids.stddevval_id, set_value=std
widget_control, uval.wids.minval_id, set_value=min
widget_control, uval.wids.maxval_id, set_value=max
widget_control, uval.wids.varval_id, set_value=var
widget_control, uval.wids.medval_id, set_value=med


end

pro CImWin::Gaussian, base_id

; get the base uval
widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Gaussian Fit', group_leader=base_id, /col)
gaussbase=widget_base(base, /col, /base_align_right)
filename = widget_label(gaussbase, value = ('Filename: '+ImObj->GetFilename()))
xcenter_base=widget_base(gaussbase, /row)
xcenter_label = widget_label(xcenter_base, value = 'X center:')
xcenter_val = widget_label(xcenter_base, value = '0', frame = 2, xsize =120, $
	/align_right)
ycenter_base=widget_base(gaussbase, /row)
ycenter_label = widget_label(ycenter_base, value = 'Y center:')
ycenter_val = widget_label(ycenter_base, value = '0', frame = 2, xsize =120, $
	/align_right)
xfwhm_base=widget_base(gaussbase, /row)
xfwhm_label = widget_label(xfwhm_base, value = 'X FWHM:')
xfwhm_val = widget_label(xfwhm_base, value = '0', frame = 2, xsize =120, $
	/align_right)
yfwhm_base=widget_base(gaussbase, /row)
yfwhm_label = widget_label(yfwhm_base, value = 'Y FWHM:')
yfwhm_val = widget_label(yfwhm_base, value = '0', frame = 2, xsize =120, $
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
    plot_button=widget_button(control_base, value="Display Gaussian Fit")
close_button=widget_button(base, value='Close')

; set the gaussian routine uvals
wids = {base_id:base_id, $
        xcenter_id: xcenter_val, $
        ycenter_id: ycenter_val, $
        xfwhm_id: xfwhm_val, $
        yfwhm_id: yfwhm_val, $
        minval_id: minval, $
        maxval_id: maxval, $
        filename_id: filename}

plot_info = {raw_data_ptr:ptr_new(/allocate_heap), $
             fit_data_ptr:ptr_new(/allocate_heap), $
             x_arg_ptr:ptr_new(/allocate_heap), $
             y_arg_ptr:ptr_new(/allocate_heap), $
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

xmanager, 'CImWin_Gauss_Base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CImWin_Gauss_Button', close_button, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Plot', plot_button, /just_reg, /no_block
; register existence of base
base_uval.exist.gaussian = base
; set box mode
base_uval.box_mode='gauss'

; set the base uval
widget_control, base_id, set_uval=base_uval

end

pro CImWin::CalcGauss, base_id, PLOT=plot
; this routine calculates the gaussian of the selected region

; get the widget uvals
widget_control, base_id, get_uval=base_uval
widget_control, base_uval.exist.gaussian, get_uval=uval

; get displayed image data
im=*(self.p_DispIm)

; get corners of box
x0=base_uval.box_p0[0]
x1=base_uval.box_p1[0]
y0=base_uval.box_p0[1]
y1=base_uval.box_p1[1]

; make sure you have the upper and lower box values correct
x0pix=(x1 < x0)
x1pix=((x1 > x0))
y0pix=(y1 < y0)
y1pix=((y1 > y0))

; find the sizes of the box
xsize=x1pix-x0pix+1
ysize=y1pix-y0pix+1

; create vectors to hold x and y arguments for plotting
x_arg=indgen(xsize)+x0pix  
y_arg=indgen(ysize)+y0pix

; get subimage
array=im[x0pix:x1pix, y0pix:y1pix]
yfit=gauss2dfit(array, coeff, x_arg, y_arg)

; perform statistics
min=strtrim(min(array, max=max), 2)
max=strtrim(max, 2)

; update values in gaussian widget ids
widget_control, uval.wids.xcenter_id, set_value=strtrim(coeff[4], 2)
widget_control, uval.wids.ycenter_id, set_value=strtrim(coeff[5], 2)
widget_control, uval.wids.xfwhm_id, set_value=strtrim(coeff[2], 2)
widget_control, uval.wids.yfwhm_id, set_value=strtrim(coeff[3], 2)
widget_control, uval.wids.minval_id, set_value=min
widget_control, uval.wids.maxval_id, set_value=max

; update the gaussian plot information
*uval.plot_info.x_arg_ptr=x_arg
*uval.plot_info.y_arg_ptr=y_arg
*uval.plot_info.raw_data_ptr=array
*uval.plot_info.fit_data_ptr=yfit
uval.plot_info.min=min
uval.plot_info.max=max

; set the gaussian uval
widget_control, base_uval.exist.gaussian, set_uval=uval

end

pro CImWin::GaussPlot, gauss_id

widget_control, gauss_id, get_uval=gauss_uval

; Plot raw data surface in left window 
save=!d.window
wset, gauss_uval.draw1_idx
surface, *gauss_uval.plot_info.raw_data_ptr, *gauss_uval.plot_info.x_arg_ptr, $
         *gauss_uval.plot_info.y_arg_ptr, az=gauss_uval.plot_info.plot_ang, $
         xstyle=1, ystyle=1, zstyle=1, $
         zrange=[gauss_uval.plot_info.min, gauss_uval.plot_info.max], $
         charsize=1.5, zticks=4, zminor=4, TITLE="Raw Data"

; Plot Gaussian fit surface in right window
wset, gauss_uval.draw2_idx
shade_surf, *gauss_uval.plot_info.fit_data_ptr, *gauss_uval.plot_info.x_arg_ptr, $
            *gauss_uval.plot_info.y_arg_ptr, az=gauss_uval.plot_info.plot_ang, $
            xstyle=1, ystyle=1, zstyle=1, $
            zrange=[gauss_uval.plot_info.min,gauss_uval.plot_info.max], $
            charsize=1.5, zticks=4, zminor=4, title="Gaussian Fit"

wset, save
end

pro CImWin::ZoomBox, base_id
; this routine takes the drawn box and zooms to that size

; get the widget uvals
widget_control, base_id, get_uval=base_uval
;widget_control, base_uval.exist.gaussian, get_uval=uval

self=*base_uval.self_ptr
xscale=self->GetXScale()
yscale=self->GetYScale()
im=*(self->GetImObj())
im_xs=self->GetDispIm_xs()
im_ys=self->GetDispIm_ys()
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr
scl_im=bytscl(disp_im, min=self->GetDispMin(), max=self->GetDispMax())
win_xs=self->GetXS()
win_ys=self->GetYS()

; get displayed image data
im=*(self.p_DispIm)

; get corners of box
x0=base_uval.box_p0[0]
x1=base_uval.box_p1[0]
y0=base_uval.box_p0[1]
y1=base_uval.box_p1[1]

; make sure you have the upper and lower box values correct
x0pix=(x1 < x0)
x1pix=((x1 > x0))
y0pix=(y1 < y0)
y1pix=((y1 > y0))

; find the center of the box
x_center=fix((x0pix+x1pix)/2)
y_center=fix((y0pix+y1pix)/2)

;center the image at the center of the box
base_uval.tv_p0[0]=0 > x_center < (im_xs-1)
base_uval.tv_p0[1]=0 > y_center < (im_ys-1)

; find the box x and y sizes
box_xs=((x1pix-x0pix) > 0)+1
box_ys=((y1pix-y0pix) > 0)+1

if base_uval.independent_zoom eq 0 then begin
    ; find which vector is longer, then zoom to that size
    zoom = ((win_xs/float(box_xs)) < (win_ys/float(box_ys)))
    zoom = (zoom < 128)

    ; set the new zoom scales
    self->SetXScale, zoom
    self->SetYScale, zoom
endif else begin
    x_zoom = win_xs/float(box_xs)
    x_zoom = (x_zoom < 128)
    y_zoom = win_ys/float(box_ys)
    y_zoom = (y_zoom < 128)
    ; set the new zoom scales
    self->SetXScale, x_zoom
    self->SetYScale, y_zoom
endelse

; set values in the widget
;widget_control, base_uval.wids.xpos, set_value=strtrim(fix(x), 2)
;widget_control, base_uval.wids.ypos, set_value=strtrim(fix(y), 2)
;widget_control, base_uval.wids.val, set_value=strtrim(disp_im[x, y], 2)

;cancel the draw box
;base_uval.draw_box=0
;base_uval.box_mode='none'
;base_uval.redraw=0

; erase the draw box when you redraw the zoomed image
;base_uval.draw_box=0

widget_control, base_id, set_uval=base_uval

self->DrawImage
self->UpdateText

; find the sizes of the box
;xsize=x1pix-x0pix+1
;ysize=y1pix-y0pix+1

end

pro CImWin::Digital_Filter, base_id

; get the base uval
widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self->GetImObj()

ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Digital Filter', group_leader=base_id, /col)
filterbase=widget_base(base, /col, /base_align_right)
filename = widget_label(filterbase, value = ('Apply filter on file: '+ImObj->GetFilename()))
getfile_base=widget_base(filterbase, /row)
file_box=cw_field(getfile_base, value='', title='Digital Filter Filename:', xs=36)
browse_button=widget_button(getfile_base, value='Browse')
bottom_base=widget_base(base, /row)
display_filter_button=widget_button(bottom_base, value='Display digital filter')
apply_digital_filter_button=widget_button(bottom_base, value='Apply digital filter')
remove_digital_filter_button=widget_button(bottom_base, value='Remove digital filter')
filter_selection_base=widget_base(base, /row)
filter_options=cw_bgroup(filter_selection_base, ['Z', 'J', 'H', 'K'], /exclusive)
close_button=widget_button(bottom_base, value='Close')

; set the digital filter routine uvals
wids={base_id:base_id, $
        file:file_box}
plot_info={filter_lambda_ptr:ptr_new(/allocate_heap), $
           filter_trans_ptr:ptr_new(/allocate_heap)}
uval={base_id:base_id, $
        draw1_idx:0L, $
        wids:wids, $
        plot_info:plot_info}
        
; realize widget
widget_control, base, /realize, set_uvalue=uval

xmanager, 'CImWin_Filter_Base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CImWin_Filter_Browse', browse_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Display', display_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Apply', apply_digital_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Remove', remove_digital_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Button', close_button, /just_reg, /no_block
; register existence of base
base_uval.exist.filter = base

; set the base uval
widget_control, base_id, set_uval=base_uval

end


pro CImWin::FilterPlot, filter_id

widget_control, filter_id, get_uval=filter_uval

; Plot raw data surface in left window 
save=!d.window
wset, filter_uval.draw1_idx 

plot, *filter_uval.plot_info.filter_lambda_ptr, *filter_uval.plot_info.filter_trans_ptr, $
      title='Filter Plot with Interpolated Plot Superimposed'

; Plot Gaussian fit surface in right window
;wset, filter_uval.draw2_idx

;wset, save
end

pro CImWin::ApplyFilter, filter_id

widget_control, filter_id, get_uval=filter_uval
widget_control, filter_uval.base_id, get_uval=base_uval

self=*base_uval.self_ptr
im=*(self->GetImObj())
im_xs=self->GetDispIm_xs()
im_ys=self->GetDispIm_ys()
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr
scl_im=bytscl(disp_im, min=self->GetDispMin(), max=self->GetDispMax())
win_xs=self->GetXS()
win_ys=self->GetYS()

; check to see what the difference is between im and disp_im
; i think what to do is do the operation on im, and then call
; self->SetDispIm(), newDispIm - calculated display image

; apply interpolated filter to data cube
; redraw the cube

im=*self.p_DispIm

self->DrawImage, event.top

end

pro CImWin::Digital_Filter, base_id

; get the base uval
widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self->GetImObj()

ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Digital Filter', group_leader=base_id, /col)
filterbase=widget_base(base, /col, /base_align_right)
filename = widget_label(filterbase, value = ('Apply filter on file: '+ImObj->GetFilename()))
getfile_base=widget_base(filterbase, /row)
file_box=cw_field(getfile_base, value='', title='Digital Filter Filename:', xs=36)
browse_button=widget_button(getfile_base, value='Browse')
bottom_base=widget_base(base, /row)
display_filter_button=widget_button(bottom_base, value='Display digital filter')
apply_digital_filter_button=widget_button(bottom_base, value='Apply digital filter')
remove_digital_filter_button=widget_button(bottom_base, value='Remove digital filter')
filter_selection_base=widget_base(base, /row)
;filter_options=cw_bgroup(filter_selection_base, ['Z', 'J', 'H', 'K'], /exclusive)
close_button=widget_button(bottom_base, value='Close')

; set the digital filter routine uvals
wids={base_id:base_id, $
        file:file_box}
plot_info={filter_lambda_ptr:ptr_new(/allocate_heap), $
           filter_trans_ptr:ptr_new(/allocate_heap), $
           filter_csamplambda_ptr:ptr_new(/allocate_heap), $
           filter_csamptrans_ptr:ptr_new(/allocate_heap)}
uval={base_id:base_id, $
        draw1_idx:0L, $
        wids:wids, $
        plot_info:plot_info}
        
; realize widget
widget_control, base, /realize, set_uvalue=uval

xmanager, 'CImWin_Filter_Base', base, /just_reg, /no_block, $
	cleanup='ql_subbase_death'
xmanager, 'CImWin_Filter_Browse', browse_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Display', display_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Apply', apply_digital_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Remove', remove_digital_filter_button, /just_reg, /no_block
xmanager, 'CImWin_Filter_Button', close_button, /just_reg, /no_block
; register existence of base
base_uval.exist.filter = base

; set the base uval
widget_control, base_id, set_uval=base_uval

end


pro CImWin::FilterPlot, filter_id

;======================================================
; MAKING THE COLOR TABLES
;======================================================

r=INDGEN(256) 
g=INDGEN(256)
b=INDGEN(256)

r=[0, 255, 255, 0, 66, 66, 66, 66, 0, 255]
g=[0, 0, 255, 0, 0, 66, 0, 0, 255, 255]
b=[0, 0, 0, 255, 255, 255, 255, 99, 0, 255]

tvlct, r, g, b

widget_control, filter_id, get_uval=filter_uval

; Plot raw data surface in left window 
save=!d.window
wset, filter_uval.draw1_idx 

plot, *filter_uval.plot_info.filter_lambda_ptr, *filter_uval.plot_info.filter_trans_ptr, $
      title='Filter Plot with Interpolated Plot Superimposed', xtitle='Wavelength (!7l!3m)', $
      ytitle='Multiplication Factor'

oplot, *filter_uval.plot_info.filter_csamplambda_ptr, *filter_uval.plot_info.filter_csamptrans_ptr, $
       color=3

; Plot Gaussian fit surface in right window
;wset, filter_uval.draw2_idx

;wset, save
end

pro CImWin::ApplyFilter, filter_id

widget_control, filter_id, get_uval=filter_uval
widget_control, filter_uval.base_id, get_uval=base_uval

self=*base_uval.self_ptr
im=*(self->GetImObj())
im_xs=self->GetDispIm_xs()
im_ys=self->GetDispIm_ys()
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr
scl_im=bytscl(disp_im, min=self->GetDispMin(), max=self->GetDispMax())
win_xs=self->GetXS()
win_ys=self->GetYS()

; check to see what the difference is between im and disp_im
; i think what to do is do the operation on im, and then call
; self->SetDispIm(), newDispIm - calculated display image

; apply interpolated filter to data cube
; redraw the cube

im=*self.p_DispIm

self->DrawImage, event.top

end

pro CImWin::DrawPlot, base_id, type
; this routine will take info about a plot from this object and set it in the
; plot window object.  it will then draw the plot

widget_control, base_id, get_uval=base_uval

; get regions of plot
x0=base_uval.box_p0[0]
x1=base_uval.box_p1[0]
y0=base_uval.box_p0[1]
y1=base_uval.box_p1[1]

x0pix=(x1 < x0)
x1pix=(x1 > x0)
y0pix=(y1 < y0)
y1pix=(y1 > y0)

; set values in plot window object
plot_win=*(self.p_PlotWin)
plot_win->SetXData_Range, [x0pix, x1pix]
plot_win->SetYData_Range, [y0pix, y1pix]
plot_win->SetXRange, [x0pix, x1pix]
plot_win->SetYRange, [y0pix, y1pix]
plot_win->SetResetRanges, 1

; depending on type (passed in), draw appropriate plot
case type of 
	'depth':plot_win->DrawDepthPlot
	'horizontal':plot_win->DrawHorizontalPlot
	'vertical':plot_win->DrawVerticalPlot
	'contour':plot_win->DrawContourPlot
	'surface':plot_win->DrawSurfacePlot
	else:
endcase

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CImWin::MakeActive
; make current window active by adding *'s to title
	widget_control, self.BaseID, tlb_set_title=('*'+self.title+'*')
end

pro CImWin::MakeInactive
	widget_control, self.BaseID, tlb_set_title=(self.title)
end

pro CImWin::UpdateTitleBar
	widget_control, self.BaseID, tlb_set_title=self.title
end

function CImWin::GetParentBaseId
	return, self.ParentBaseId
end

function CImWin::GetBaseId
	return,  self.BaseId
end

function CImWin::GetDrawId
	return, self.DrawId
end

function CImWin::GetDrawIndex
	return, self.DrawIndex
end

function CImWin::GetTitle
	return, self.title
end

function CImWin::GetXS 
	return, self.xs
end

pro CImWin::SetXS, newxs
	self.xs=newxs
end

function CImWin::GetYS
	return, self.ys
end

pro CImWin::SetYS, newys
	self.ys=newys
end

function CImWin::GetImObj
	return, self.p_ImObj
end

pro CImWin::SetImObj, newImObj
	self.p_ImObj=newImObj
end

function CImWin::GetDispIm
	return, self.p_DispIm
end

pro CImWin::SetDispIm, newDispIm
	self.p_DispIm=newDispIm
end

function CImWin::GetTitle
	return, self.title
end

pro CImWin::SetTitle, title
	self.title=title
end

function CImWin::GetXScale
	return, self.XScale
end

pro CImWin::SetXScale, newXScale
	self.XScale=newXScale
end

function CImWin::GetYScale
	return, self.YScale
end

pro CImWin::SetYScale, newYScale
	self.YScale=newYScale
end

function CImWin::GetZMin
	return, self.ZMin
end

pro CImWin::SetZMin, newZMin
	self.ZMin=newZMin
end

function CImWin::GetZMax
	return, self.ZMax
end

pro CImWin::SetZMax, newZMax
	self.ZMax=newZMax
end

function CImWin::GetDispMin
	return, self.DispMin
end

pro CImWin::SetDispMin, newDispMin
	self.DispMin=newDispMin
end

function CImWin::GetDispMax
	return, self.DispMax
end

pro CImWin::SetDispMax, newDispMax
	self.DispMax=newDispMax
end

function CImWin::GetAxesOrder
	return, self.AxesOrder
end

pro CImWin::SetAxesOrder, newAxesOrder
	self.AxesOrder=newAxesOrder
end

function CImWin::GetNAxis
	return, self.NAxis
end

pro CImWin::SetNAxis, newNAxis
	self.NAxis=newNAxend

function CImWin::GetResetZ
	return, self.ResetZ
end

pro CImWin::SetResetZ, newResetZ
	self.ResetZ=newResetZ
end

function CImWin::GetDispIm_xs
	return, self.DispIm_xs
end

pro CImWin::SetDispIm_xs, newDispIm_xs
	self.DispIm_xs=newDispIm_xs
end

function CImWin::GetDispIm_ys
	return, self.DispIm_ys
end

pro CImWin::SetDispIm_ys, newDispIm_ys
	self.DispIm_ys=newDispIm_ys
end

function CImWin::GetCurIm_s
	return, self.CurIm_s
end

pro CImWin::SetCurIm_s, newCurIm_s
	self.CurIm_s=newCurIm_s
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro cimwin__define
        ; allocate a new pointer for the instance of an image object
	p_ImObj=ptr_new(/allocate_heap)
        ; allocate a pointer for the displayed image
	p_DispIm=ptr_new(/allocate_heap)
        ; allocate a pointer for the plot window
	p_PlotWin=ptr_new(/allocate_heap)
        ; allocate a pointer for the printer object
        p_PrintObj=ptr_new(/allocate_heap)

        ; make a structure that will store information for an instance
        ; of the CImWin object
	struct={CImWin, $
		ParentBaseId:0L, $		; base id of window parent
		BaseId:0L, $			; wid of window base
		DrawId:0L, $			; wid of draw window
		DrawIndex:0L, $			; index of draw window
		title:'', $			; title of window
		xs:0L, $			; window xsize
		ys:0L, $			; window ysize
		p_ImObj:p_ImObj, $		; pointer to image object
		p_PlotWin:p_PlotWin, $		; pointer to Plot Window obj
                p_PrintObj:p_PrintObj, $        ; pointer to Print obj
		XScale:1.0, $			; X zoom factor
		YScale:1.0, $			; Y zoom factor
		ZMin:0, $			; Lower limit of slice
		ZMax:0, $			; Upper limit of slice
		DispMin:0.0, $			; Min val for color stretch
		DispMax:256.0, $		; max val for color stretch
		AxesOrder:indgen(3), $		; Order of axes
		NAxis:2, $			; Number of axes in image
		p_DispIm:p_DispIm, $		; pointer to displayed image
		DoAutoScale:1, $		; flag for doing autoscale
		ResetZ:0, $			; flag for resetting slice
		DispIm_xs:1, $			; x size of image displayed
		DispIm_ys:1, $			; y size of image displayed
		CurIm_s:[1, 1, 1] $		; current dimensions of image
		}  
end
