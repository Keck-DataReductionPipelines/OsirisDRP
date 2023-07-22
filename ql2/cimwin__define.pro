;+
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
; REVISION HISTORY:
;       2002-12-18 - MWM: added comments.
;       2006-03-09 - Marshall Perrin:  Add axes plots, menu separators, and
; 						  'save to variable' feature.
;       2007-07-03 - MDP: Fixed multiple memory leaks on startup. Also started
; 			  to add support for FITS WCS (doesn't work yet)
;       2007-07-12 - MDP: WCS code works
;       2007-10-31 - MDP: Lots of redundant and/or convoluted code simplified.
; 			  Changing from Total DN to DN/s now
; 			      intelligently rescales the
; 			      min/max values by the exposure time,
;                             rather than re-autoscaling the image.
;                         Draw/Remove menu axes label now toggles.
;       2008-03-18 - MDP: Various bug fixes and improvements.
;                             (I know, such a useful log message...)
;       2017-09-07 - T.Do : fixed bug when displaying DN/s in the cube
;                           dividing by the itime when it is already
;                           in DN/s
;       2019-07-29 - jlyke : Handle upgraded imager detector pixel units (DN)
;                            Flip new OSIMG data for correct orientation
;       2020-04-10 - jlyke : Add changes to DispMin/Max per image
;                                stretch in UpdateDispIm
;                            Change indents on comments for easier reading
;       2020-04-15 - jlyke : Change sky correction in photometry as it
;                                was begin done twice

;-



; This is a helper routine that greatly simplifies some repetitive ugly code.
FUNCTION has_valid_cconfigs, conbase_uval, cconfigs
    if ptr_valid(conbase_uval.cconfigs_ptr) then begin
        if obj_valid(*conbase_uval.cconfigs_ptr) then begin
            if obj_isa(*conbase_uval.cconfigs_ptr, 'CConfigs') then begin
                cconfigs=*(conbase_uval.cconfigs_ptr)
				return, 1
			endif
		endif
	endif
	return, 0

end



; this is to check on the tags

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
    hd=*(im->GetHeader())
    im_extensions=im->GetN_Ext()
    endif else begin            ; if not, create new one
    im_ptr=ptr_new(/allocate_heap)
    min=0.0
    max=0.0
    im_xs=1
    im_ys=1
    im_zs=1
    hd=''
    im_extensions=0
endelse

; create new ptr for the display image
dispim_ptr=ptr_new(/allocate_heap)

; get window title
if keyword_set(title) then t=title else t='Image Window'

; if a parent for the new window is given, use it for a group leader
if keyword_set(ParentBaseId) then begin
    ParentId=ParentBaseId
    base=widget_base(title=t, group_leader=ParentBaseId, /col, $
                     mbar=cimwin_mbar, /tlb_size_events, $
                     /tlb_kill_request_events)
    widget_control, ParentId, get_uval=conbase_uval
	if has_valid_cconfigs(conbase_uval, cconfigs) then begin
        xsize=cconfigs->GetDrawXs()
        ysize=cconfigs->GetDrawYs()
    endif else begin ; get default window size
        if keyword_set(xs) then xsize=xs else xsize=512
        if keyword_set(ys) then ysize=ys else ysize=512
    endelse 
endif else begin
    base=widget_base(title=t, /col, mbar=cimwin_mbar, /tlb_size_events, $
                     /tlb_kill_request_events)
    ParentId=base
    ; get default window size
    if keyword_set(xs) then xsize=xs else xsize=512
    if keyword_set(ys) then ysize=ys else ysize=512
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

; figure out what the starting data unit is
if ptr_valid(conbase_uval.cconfigs_ptr) then begin
    if obj_valid(*conbase_uval.cconfigs_ptr) then begin
        if obj_isa(*conbase_uval.cconfigs_ptr, 'CConfigs') then begin
            cconfigs=*(conbase_uval.cconfigs_ptr)
            displayas=cconfigs->GetDisplayAsDN()
            cfgname=cconfigs->GetCfgName()
            ; use cfgname for OSIRIS as INSTRUME
            ; is not in headers and CURRINST is
            ; not controlled by instrument
            ; check to see if the header exists
            if (stregex(cfgname, 'OSIRIS') gt -1) then begin
               instr='OSIRIS'
            endif else begin
               if (hd[0] ne '') then begin
                  instr=strtrim(sxpar(hd,'CURRINST'),2)
               endif
            endelse
            if (instr eq 'OSIRIS') or (instr eq 'NIRC2') then begin                
                case displayas of
                        'As DN/s': datanum_val='DN/s'
                        'As Total DN': datanum_val='DN'
                        else: datanum_val=''
                endcase
            endif else begin
                datanum_val=''
            endelse
        endif
    endif else begin
        datanum_val=''
    endelse
endif else begin
    datanum_val=''
endelse

; check to see if there is an itime keyword
if (hd[0] ne '') then begin
   print, 'using TRUITIME keyword'
   itime = sxpar(hd, 'TRUITIME')
endif else begin
   print, 'no header found, setting itime=1'
    itime=1.
endelse

if ptr_valid(conbase_uval.cconfigs_ptr) then begin
    if obj_valid(*conbase_uval.cconfigs_ptr) then begin
        if obj_isa(*conbase_uval.cconfigs_ptr, 'CConfigs') then begin
            cconfigs=*(conbase_uval.cconfigs_ptr)
            if (naxis eq 3) then begin
                axes=*(cconfigs->GetAxesLabels3d()) 
            endif else begin
                axes=*(cconfigs->GetAxesLabels2d())
            endelse
        endif else begin
            axes=['AXIS 1', 'AXIS 2', 'AXIS 3']
        endelse
    endif else begin
        axes=['AXIS 1', 'AXIS 2', 'AXIS 3']    
    endelse
endif else begin
    axes=['AXIS 1', 'AXIS 2', 'AXIS 3']
endelse

; make a string array containing the extension names
self->MakeExtArr, im_extensions, ext_arr, ext_arr_ptr

; make the cimwin menu description
cimwin_desc=self->MenuDesc()

; widgets for the image window
menu=cw_pdmenu(cimwin_mbar, cimwin_desc, /return_name, /mbar, $
    font=ql_fonts.cimwin.menu)
draw=widget_draw(base, xs=xsize, ys=ysize, /motion_events, /button_events, $
    retain=win_backing, /keyboard_events)

;draw=widget_draw(base, xs=xsize, ys=ysize, /motion_events, /button_events, $
;    retain=win_backing)

top_base=widget_base(base, /col, ypad=0)
info_base=widget_base(top_base, /row, ypad=0)
wcs_base=widget_base(top_base, /row, ypad=0)
zoom_base=widget_base(top_base, /row, ypad=0)
stretch_base=widget_base(top_base, /row, ypad=0)

; cursor position info labels
x_label=widget_label(info_base, value='X:', font=ql_fonts.cimwin.x_label, xs=20)
x_pos_label=widget_label(info_base, value='0', xs=70, /align_left, $
    font=ql_fonts.cimwin.y_pos)
y_label=widget_label(info_base, value='Y:', xs=20, /align_left, $
    font=ql_fonts.cimwin.y_label)
y_pos_label=widget_label(info_base, value='0', xs=70, /align_left, $
    font=ql_fonts.cimwin.y_pos)
val_label=widget_label(info_base, value='Value:', xs=50, /align_left, $
    font=ql_fonts.cimwin.val_label)
val_val_label=widget_label(info_base, value='0', xs=90, /align_right, $
    font=ql_fonts.cimwin.val_val)

; DN/s or DN?
datanum_label=widget_label(info_base, value=datanum_val, xs=40, /align_right, $
    font=ql_fonts.cimwin.datanum_val)

info_geom=widget_info(info_base, /geometry)
min_wid_xsize=info_geom.xsize+(2*info_geom.xpad)

;MDP: WCS info labels
wcs_label = widget_label(wcs_base, value='WCS:', xs=50, /align_left, $
    font=ql_fonts.cimwin.val_label)
wcs_val_label=widget_label(wcs_base, value='no WCS present', xs=300, /align_right, $
    font=ql_fonts.cimwin.val_val)
; end MDP WCS addition

; zoom scale info labels
zoom_xscl_label=widget_label(zoom_base, value='XScale:', xsize=50, $
    font=ql_fonts.cimwin.zoom_xscl_label)
zoom_xscl_val_label=widget_label(zoom_base, value=string(format='(F6.3)', $
    xscl), xs=40, /align_right, font=ql_fonts.cimwin.zoom_xscl_val)
zoom_yscl_label=widget_label(zoom_base, value='YScale:', xs=50, $
    /align_left, font=ql_fonts.cimwin.zoom_yscl_label)
zoom_yscl_val_label=widget_label(zoom_base, value=string(format='(F6.3)', $
    yscl), xs=40, /align_right, font=ql_fonts.cimwin.zoom_yscl_val)
pmode_label=widget_label(zoom_base, value='Pointing Type:', xs=85, $
                         /align_left, font=ql_fonts.cimwin.val_label)
pmode_val_label=widget_label(zoom_base, value='none', xs=60, /align_right, $
    font=ql_fonts.cimwin.pmode_val)

zoom_geom=widget_info(zoom_base, /geometry)
min_wid_xsize=(zoom_geom.xsize+(2*zoom_geom.xpad)) > min_wid_xsize

; zooming with constant aspect ratio
topzoomminus_button=widget_button(stretch_base, value='-', $
                                  ys=25, xs=25, font=ql_fonts.cimwin.top_zoom_minus)
topzoomplus_button=widget_button(stretch_base, value='+', $
                                 ys=25, xs=25, font=ql_fonts.cimwin.top_zoom_plus)
topone2one_button=widget_button(stretch_base, value='1:1', $
                                 ys=25, xs=25, font=ql_fonts.cimwin.top_one2one)
topfit_button=widget_button(stretch_base, value='FIT', $
                                 ys=25, xs=25, font=ql_fonts.cimwin.top_zoom_fit)

; stretch info label and text boxes
stretch_min_box=cw_field(stretch_base, title="Min:", $
    value=string(min), xs=8, font=ql_fonts.cimwin.stretch_min_title, $
    /return_events, fieldfont=ql_fonts.cimwin.stretch_min_val)
stretch_max_box=cw_field(stretch_base, title="Max:", $
    value=string(max), xs=8, font=ql_fonts.cimwin.stretch_max_title, $
    /return_events, fieldfont=ql_fonts.cimwin.stretch_max_val)
stretch_apply_button=widget_button(stretch_base, value='Apply', $
    font=ql_fonts.cimwin.stretch_apply)

stretch_geom=widget_info(stretch_base, /geometry)
min_wid_xsize=(stretch_geom.xsize+(2*stretch_geom.xpad)) > min_wid_xsize

; button that expands the window
expand_button=widget_button(top_base, value='More', $
    font=ql_fonts.cimwin.expand)

; widget base that is initiated when the expansion button is pressed
bottom_base=widget_base(base, /col, map=0)

; creation of the extension list
extension_base=widget_base(bottom_base, /row, frame=2)
extension_list=widget_droplist(extension_base, value=ext_arr, title='Extension:', $
    font=ql_fonts.cimwin.extension_list)

collapse_list=widget_droplist(extension_base, value=['Median', 'Average'], title='Collapse', $
    font=ql_fonts.cimwin.collapse_list)

; creation of the scale base
scale_base=widget_base(bottom_base, /row, frame=2)
xbase=widget_base(scale_base, /col, frame=2)
; x display axis droplist
xdim_list=widget_droplist(xbase, value=axes[0:naxis-1], title='X:', $
    font=ql_fonts.cimwin.xdim_list)
; x zoom buttons
xzoom_buttons=cw_bgroup(xbase, [' - ', ' + ', '1:1', 'Fit'], /row, $
    /return_name, font=ql_fonts.cimwin.xzoom_buttons)

ybase=widget_base(scale_base, /col, frame=2)
; y display axis droplist
ydim_list=widget_droplist(ybase, value=axes[0:naxis-1], title='Y:', $
    font=ql_fonts.cimwin.ydim_list)
; y zoom buttons
yzoom_buttons=cw_bgroup(ybase, [' - ', ' + ', '1:1', 'Fit'], /row, $
    /return_name, font=ql_fonts.cimwin.yzoom_buttons)

panning_base=widget_base(scale_base, /col, frame=2)
; center_button
center_button=cw_bgroup(panning_base, ['Pan'], $
    /row, /nonexclusive, ysize=25, font=ql_fonts.cimwin.aspect_button)

; zoom box button
zbox_button=cw_bgroup(panning_base, ['Zoom Box'], $
        /row, /nonexclusive, ysize=25, font=ql_fonts.cimwin.zbox_button)

; recenter button
recenter_button=widget_button(panning_base, value='Recenter', $
                              font=ql_fonts.cimwin.recenter_button)

scale_geom=widget_info(scale_base, /geometry)
min_wid_xsize=(scale_geom.xsize+(2*scale_geom.xpad)) > min_wid_xsize


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
cube_lambda_label=widget_label(cube_current_base, value='  ', xs=40, $
    /align_right, font=ql_fonts.cimwin.cube_lambda_label)
cube_lambda_val=widget_label(cube_current_base, value='  ', $
    xs=40, /align_right, font=ql_fonts.cimwin.cube_lambda_val)
 
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
cube_slice_range_base=widget_base(cube_slice_base, /row)
cube_slice_slider=widget_slider(cube_slice_range_base, minimum=0, $
    maximum=((im_zs-1) > 1) , font=ql_fonts.cimwin.cube_slider, xs=114, /drag)
cube_slice_box=cw_field(cube_slice_range_base, title='Boxcar:', $
                        value=1, xs=5, $
                        font=ql_fonts.cimwin.cube_slice_box_title, $
                        fieldfont=ql_fonts.cimwin.cube_slice_box_value)
cube_slice_box_apply_button=widget_button(cube_slice_range_base, value='Apply', $
    font=ql_fonts.cimwin.cube_slice_box_apply)

; make an invisible base for the keyboard shortcuts
;invisible_base=widget_base(base, /row)
;i_menu=widget_button(invisible_base, value='', /menu)
;i_pan=widget_button(i_menu, value='pan', uvalue='pan', accelerator='Ctrl+p')

; if image is 2D (zsize=1), then don't map the cube controls
;widget_control, cube_base, map=(im_zs gt 1)

; if image is 2D (zsize=1), then make the cube controls insensitive
widget_control, cube_base, sensitive=(im_zs gt 1)

cube_geom=widget_info(cube_base, /geometry)
min_wid_xsize=(cube_geom.xsize+(2*cube_geom.xpad)) > min_wid_xsize

; disable depth plots for 2D images
depth_idx=(where(cimwin_desc.name eq 'Depth Plot'))[0]
;depth_id=menu+depth_idx-1 ; 070622 MWM
depth_id=menu+depth_idx+1
widget_control, depth_id, sensitive=(im_zs gt 1)

; disable unravel plots for 2D images
unravel_idx=(where(cimwin_desc.name eq 'Unravel'))[0]
unravel_id=menu+unravel_idx+1
widget_control, unravel_id, sensitive=(im_zs gt 1)

; disable the rotate function for 3D images
rotate_idx=(where(cimwin_desc.name eq 'Rotate'))[0]
rotate_id=menu+rotate_idx+1
widget_control, rotate_id, sensitive=(im_zs le 1)

; save location of 'Make Window Active' & Save as Cube on the menu bar
makewinact_idx=(where(cimwin_desc.name eq 'Make Window Active'))[0]
makewinact_id=menu+makewinact_idx+1

saveascube_idx=(where(cimwin_desc.name eq 'Save As Cube'))[0]
saveascube_id=menu+saveascube_idx+1
widget_control, saveascube_id, sensitive=(im_zs gt 1)

displayasdn_idx=(where(cimwin_desc.name eq 'As Total DN'))[0]
displayasdn_id=menu+displayasdn_idx+1
menu_drawaxes_idx=(where(cimwin_desc.name eq 'Draw Axes Labels'))[0]
menu_drawaxes_id=menu+menu_drawaxes_idx+1
scroll_slices_idx=(where(cimwin_desc.name eq 'Scroll through All Slices'))[0]
scroll_slices_id=menu+scroll_slices_idx+1


; find out if there is an itime keyword in the .fits header
widget_control, displayasdn_id, sensitive=1

; set slice range as active and disable other base
widget_control, cube_range_button, set_button=1
widget_control, cube_slice_slider, sensitive=0

init_ys=(get_widget_size(top_base))[1]+(get_widget_size(draw))[1]

; create a pointer to itself
temp_ptr=ptr_new(self, /allocate_heap)

; instantiate a new print object to be used for the duration of the cimwin
p_PrintObj=obj_new('cprint', wid_leader=base)

; instantiate a new digital filter object to be used for the duration of the cimwin
p_FilterObj=obj_new('cdfilter', winbase_id=base)

; instantiate a new fits header editor object to be used for the duration of the cimwin
p_FitsHeditObj=obj_new('cfitshedit', winbase_id=base, conbase_id=ParentBaseId)

; define the pointing mode structure
struct={CPntMode, $
        PointingMode:'', $
        Type:'' $
       }
pointing_mode=struct
; create a pointer to the pointing mode structure
pmode_ptr=ptr_new(pointing_mode, /allocate_heap)

; get the screen size
scr_size = get_screen_size()
scr_xsize = scr_size[0]
scr_ysize = scr_size[1]

; gets the current directory
cd, '.', current=current_dir

; keep track of wid get id's
wids={  base:base, $
        menu:menu, $
        xpos:x_pos_label, $
        ypos:y_pos_label, $
        val:val_val_label, $
        wcs:wcs_val_label, $ ; MDP
        datanum:datanum_label, $
        pmode:pmode_val_label, $
        depth_id:depth_id, $
        unravel_id:unravel_id, $
        makewinact_id:makewinact_id, $
        saveascube_id:saveascube_id, $
        displayasdn_id:displayasdn_id, $
	scroll_slices_id: scroll_slices_id, $
        menu_drawaxes_id: menu_drawaxes_id, $
        rotate_id:rotate_id, $
        stretch_min:stretch_min_box, $
        stretch_max:stretch_max_box, $
        zoom_xscl:zoom_xscl_val_label, $
        zoom_yscl:zoom_yscl_val_label, $
        extension_list:extension_list, $
        collapse_list:collapse_list, $
        xdim_list:xdim_list, $
        ydim_list:ydim_list, $
        pan_button:center_button, $
        topzoomminus_button:topzoomminus_button, $
        topzoomplus_button:topzoomplus_button, $
        topone2one_button:topone2one_button, $
        topfit_button:topfit_button, $
        xzoom_buttons:xzoom_buttons, $
        yzoom_buttons:yzoom_buttons, $
        draw:draw, $
        top_base:top_base, $
        expand_button:expand_button, $
        bottom_base:bottom_base, $
        cube_base:cube_base, $
        cube_curmin: cube_curmin_val, $
        cube_curmax: cube_curmax_val, $
        cube_curzs: cube_curzs_val, $
        cube_range_button: cube_range_button, $
        cube_single_button: cube_single_button, $
        cube_range_base: cube_range_limits_base, $
        cube_slice_base: cube_single_button_base, $
        cube_slice_box_base: cube_slice_range_base, $
        cube_range_min: cube_range_min_box, $
        cube_range_max: cube_range_max_box, $
        cube_slice_box: cube_slice_box, $
        cube_slider: cube_slice_slider, $
        center_button: center_button, $
        zbox_button: zbox_button, $
        cimwin_mbar:cimwin_mbar}

exist={ plot:0L, $
        print:0L, $
        statistics:0L, $
        photometry:0L, $
        strehl:0L, $
        gaussian:0L, $
        fitshedit:0L, $
        filterbrowse:0L, $
        movie:0L, $
        rotate:0L $
      }

; main window uval
uval={  self_ptr:temp_ptr, $
        wids:wids, $
        min_wid_xsize:min_wid_xsize, $
        exist:exist, $
        win_backing:win_backing, $
        current_dir:current_dir, $
        new_image:0L, $
        current_display_skip:0L, $
        xs:xsize, $
        ys:ysize, $
        init_xs:xscl, $
        init_ys:yscl, $
        scr_xsize:scr_xsize, $
        scr_ysize:scr_ysize, $
        last_winxs:xsize, $
        last_winys:ysize, $
        initial_xs:0, $
        zbox_mode:0, $
        draw_box:0, $
        pmode_ptr:pmode_ptr, $
        drawing_box:0, $
        drawing_diagonal_box:0, $
        ps_filename:'temp.ps', $
        printer_name:'', $
        print_orient:'', $
        print_type:'File', $
        log_scale:'no', $
        p_ext_arr:ext_arr_ptr, $
        box_pres: 0, $
        circ_phot_pres: 0, $
        circ_strehl_pres: 0, $
        diag_pres: 0, $
        box_p0: [0,0], $
        box_p1: [0,0], $
        diagonal_box_p0: [0,0], $
        diagonal_box_p1: [0,0], $
        draw_box_p0: [0,0], $
        draw_box_p1: [0,0], $
        draw_diagonal_box_p0: [0,0], $
        draw_diagonal_box_p1: [0,0], $
        zbox_p0: [0,0], $
        zbox_p1: [0,0], $
        draw_zbox_p0: [0,0], $
        draw_zbox_p1: [0,0], $
        phot_circ_x: 0, $
        phot_circ_y: 0, $
        strehl_circ_x: 0, $
        strehl_circ_y: 0, $
        draw_circ_x: 0, $
        draw_circ_y: 0, $
        box_mode:'none', $
        dragging_image:0, $
        wide:0, $
        tv_p0:tv_p0, $
        handle:[0,0], $
        filter_path:'', $
        xor_type: 10 }

; set the base uval to the uval structure defined
widget_control, base, set_uval=uval, /realize, ys=init_ys
widget_control, draw, get_value=index
widget_control, ydim_list, set_droplist_select=1
;widget_control, invisible_base, map=0
 
; get the initial xsize of the widget
widget_control, base, get_uval=uval
init_xsize = uval.xs
uval.initial_xs = init_xsize
widget_control, base, set_uval=uval

; calculate the initial window sizes
geom=widget_info(base, /geometry)
; add the y menu size to the y size
menu_geom=widget_info(menu, /geometry)
top_geom=widget_info(top_base, /geometry)
bottom_geom=widget_info(bottom_base, /geometry)

; determine cursor type based on platform
case !version.os_family of
    'unix':  widbase_ysize=geom.ysize+(4*geom.ypad)+menu_geom.ysize
    'Windows': widbase_ysize=geom.ysize-bottom_geom.ysize+(4*geom.ypad)+menu_geom.ysize-4
    'vms':
    'macos':
    else:
endcase

cimwin_resize_draw, base, geom.xsize, widbase_ysize

; register the image window events with the event handler
xmanager, 'CImWin_TLB', base, /just_reg, /no_block
; xmanager, 'CImWin_Accelerators', invisible_base, /just_reg, /no_block
xmanager, 'CImWin_Draw', draw, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_min_box, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_max_box, /just_reg, /no_block
xmanager, 'CImWin_Stretch_Button', stretch_apply_button, /just_reg, /no_block
xmanager, 'CImWin_Expand_Button', expand_button, /just_reg, /no_block
xmanager, 'CImWin_Menu', menu, /just_reg, /no_block
xmanager, 'CImWin_Ext_List', extension_list, /just_reg, /no_block
xmanager, 'CImWin_Collapse_List', collapse_list, /just_reg, /no_block
xmanager, 'CImWin_Dim_List', xdim_list, /just_reg, /no_block
xmanager, 'CImWin_Dim_List', ydim_list, /just_reg, /no_block
xmanager, 'CImWin_Zoom', topzoomminus_button, /just_reg, /no_block
xmanager, 'CImWin_Zoom', topzoomplus_button, /just_reg, /no_block
xmanager, 'CImWin_Zoom', topone2one_button, /just_reg, /no_block
xmanager, 'CImWin_Zoom', topfit_button, /just_reg, /no_block
xmanager, 'CImWin_Zoom', xzoom_buttons, /just_reg, /no_block
xmanager, 'CImWin_Zoom', yzoom_buttons, /just_reg, /no_block
xmanager, 'CImWin_Recenter', recenter_button, /just_reg, /no_block
xmanager, 'CImWin_Center', center_button, /just_reg, /no_block
xmanager, 'CImWin_Zbox', zbox_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Select', cube_range_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Select', cube_single_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Slice', cube_range_apply_button, /just_reg, /no_block
xmanager, 'CImWin_Cube_Slice', cube_slice_slider, /just_reg, /no_block
xmanager, 'CImWin_Cube_Boxcar', cube_slice_box_apply_button, /just_reg, /no_block

; initialize object variables
self.BaseId=base
self.DrawId=draw
self.xs=xsize
self.ys=ysize
self.ParentBaseId=ParentId
self.title=t
self.DispScale='linear'
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
self.p_PrintObj=ptr_new(p_PrintObj)
self.p_FilterObj=ptr_new(p_FilterObj)
self.p_FitsHeditObj=ptr_new(p_FitsHeditObj)
self.def_zmag=24.8
self.photometry_inner_an=10.
self.photometry_outer_an=20.
self.photometry_aper=5.
self.strehl_apsize=1.
self.movie_chan_start=0.
self.movie_chan_stop=0.
self.movie_mag=5
self.movie_xspat_bin=1
self.movie_yspat_bin=1
self.movie_bin_size=3.
self.movie_bin_step=10.
self.movie_min_value=-0.1
self.movie_max_value=1.1
self.boxcar=1
self.current_display='As DN/s'
;self.current_display_update=1.

if has_valid_cconfigs(conbase_uval, cconfigs) then begin
    self.dwidth=cconfigs->GetDiagonal()
    self.collapse=cconfigs->GetCollapse()
    self.current_display=cconfigs->GetDisplayAsDN()
endif else begin
	self.dwidth=10.
	self.collapse=0
        self.current_display='As DN/s'
endelse

if (itime ne 0) then self.def_itime = itime else begin
   print, 'no itime found, setting itime = 1'
   self.def_itime = 1.
endelse

widget_control, base, get_uval=uval
widget_control, uval.wids.collapse_list, set_droplist_select=self.collapse
widget_control, base, set_uval=uval

if (self.naxis eq 3) then begin
    self.axes_minmax=fltarr(3,2)
    self.axes_minmax[0,*]=[0,im_xs-1]
    self.axes_minmax[1,*]=[0,im_ys-1]
    self.axes_minmax[2,*]=[0,im_zs-1]
endif else begin
    self.axes_minmax=fltarr(3,2)
endelse

; set the cprint object print defaults
self->SetPrintDefaults, self.ParentBaseId

; set the cdfilter object filter defaults
self->SetDFilterDefaults, self.BaseId

; add the bottom level pointing mode
self->AddPntMode, 'filler'

return, 1

end

; Clean up member variables on exit.
pro CImWin::Cleanup
obj_destroy, *self.p_PrintObj
obj_destroy, *self.p_FilterObj
obj_destroy, *self.p_FitsHeditObj

end


function CImWin::MenuDesc

; define menu for window
junk={cw_pdmenu_s, flags:0, name:''}

cimwin_desc = [{cw_pdmenu_s, 1, 'File'}, $
               {cw_pdmenu_s, 0, 'Make Window Active'}, $
               {cw_pdmenu_s, 0, 'Inherit Active Window Params'}, $
               {cw_pdmenu_s, 0, 'View Fits Header'}, $
               {cw_pdmenu_s, 0, 'Make Movie'}, $
               {cw_pdmenu_s, 4, 'Save As 2D'}, $
               {cw_pdmenu_s, 0, 'Save As Cube'}, $
               {cw_pdmenu_s, 0, 'Save Cube to IDL variable'}, $
               {cw_pdmenu_s, 0, 'Save Image to IDL variable'}, $
               {cw_pdmenu_s, 0, 'Save Header to IDL variable'}, $
               {cw_pdmenu_s, 4, 'Print'}, $
               {cw_pdmenu_s, 2, 'Close'}, $
               {cw_pdmenu_s, 1, 'Display'}, $
               {cw_pdmenu_s, 0, 'Redisplay image'}, $
               {cw_pdmenu_s, 0, 'Rotate'}, $
               {cw_pdmenu_s, 4, 'Linear'}, $
               {cw_pdmenu_s, 0, 'Negative'}, $
               {cw_pdmenu_s, 0, 'HistEq'}, $
               {cw_pdmenu_s, 0, 'Logarithmic'}, $
               {cw_pdmenu_s, 0, 'Sqrt'}, $
               {cw_pdmenu_s, 0, 'AsinH'}, $
               {cw_pdmenu_s, 4, 'Position Angle'}, $
               {cw_pdmenu_s, 0, 'As Total DN'}, $
               {cw_pdmenu_s, 4, 'Draw Axes Labels'}, $
               {cw_pdmenu_s, 4, 'Go To Slice'}, $
               {cw_pdmenu_s, 2, 'Scroll through All Slices'}, $
               {cw_pdmenu_s, 1, 'Tools'}, $
               {cw_pdmenu_s, 0, 'Statistics'}, $
               {cw_pdmenu_s, 0, 'Photometry'}, $
               {cw_pdmenu_s, 0, 'Strehl'}, $
               {cw_pdmenu_s, 0, 'Peak Fit'}, $
               {cw_pdmenu_s, 2, 'Unravel'}, $
               {cw_pdmenu_s, 3, 'Plot'}, $
               {cw_pdmenu_s, 0, 'Depth Plot'}, $
               {cw_pdmenu_s, 0, 'Horizontal Cut'}, $
               {cw_pdmenu_s, 0, 'Vertical Cut'}, $
               {cw_pdmenu_s, 0, 'Diagonal Cut'}, $
               {cw_pdmenu_s, 0, 'Surface'}, $
               {cw_pdmenu_s, 2, 'Contour'} $
              ]

;cimwin_desc = [{cw_pdmenu_s, 1, 'File'}, $
;               {cw_pdmenu_s, 0, 'Make Window Active'}, $
;               {cw_pdmenu_s, 0, 'Inherit Active Window Params'}, $
;               {cw_pdmenu_s, 0, 'View Fits Header'}, $
;               {cw_pdmenu_s, 0, 'Make Movie'}, $
;               {cw_pdmenu_s, 4, 'Save As 2D'}, $
;               {cw_pdmenu_s, 0, 'Save As Cube'}, $
;               {cw_pdmenu_s, 0, 'Save Cube to IDL variable'}, $
;               {cw_pdmenu_s, 0, 'Save Image to IDL variable'}, $
;               {cw_pdmenu_s, 0, 'Save Header to IDL variable'}, $
;               {cw_pdmenu_s, 4, 'Print'}, $
;               {cw_pdmenu_s, 2, 'Close'}, $
;               {cw_pdmenu_s, 1, 'Display'}, $
;               {cw_pdmenu_s, 0, 'Redisplay image'}, $
;               {cw_pdmenu_s, 0, 'Rotate'}, $
;               {cw_pdmenu_s, 4, 'Linear'}, $
;               {cw_pdmenu_s, 0, 'Negative'}, $
;               {cw_pdmenu_s, 0, 'HistEq'}, $
;               {cw_pdmenu_s, 0, 'Logarithmic'}, $
;               {cw_pdmenu_s, 0, 'Sqrt'}, $
;               {cw_pdmenu_s, 4, 'Position Angle'}, $
;               {cw_pdmenu_s, 0, 'As Total DN'}, $
;               {cw_pdmenu_s, 4, 'Draw Axes Labels'}, $
;               {cw_pdmenu_s, 2, 'No Axes Labels'}, $
;               {cw_pdmenu_s, 1, 'Tools'}, $
;               {cw_pdmenu_s, 0, 'Statistics'}, $
;               {cw_pdmenu_s, 0, 'Photometry'}, $
;               {cw_pdmenu_s, 0, 'Strehl'}, $
;               {cw_pdmenu_s, 0, 'Peak Fit'}, $
;               {cw_pdmenu_s, 0, 'Unravel'}, $
;               {cw_pdmenu_s, 1, 'Digital Filter'}, $
;               {cw_pdmenu_s, 0, 'Load digital filter'}, $
;               {cw_pdmenu_s, 1, 'Apply digital filter'}, $
;               {cw_pdmenu_s, 0, 'None'}, $
;               {cw_pdmenu_s, 0, 'None'}, $
;               {cw_pdmenu_s, 0, 'None'}, $
;               {cw_pdmenu_s, 0, 'None'}, $
;               {cw_pdmenu_s, 2, 'None'}, $
;               {cw_pdmenu_s, 2, ''}, $
;               {cw_pdmenu_s, 2, ''}, $
;               {cw_pdmenu_s, 3, 'Plot'}, $
;               {cw_pdmenu_s, 0, 'Depth Plot'}, $
;               {cw_pdmenu_s, 0, 'Horizontal Cut'}, $
;               {cw_pdmenu_s, 0, 'Vertical Cut'}, $
;               {cw_pdmenu_s, 0, 'Diagonal Cut'}, $
;               {cw_pdmenu_s, 0, 'Surface'}, $
;               {cw_pdmenu_s, 2, 'Contour'} $
;              ]
 
return, cimwin_desc
end

pro CImWin::MakeExtArr, im_extensions, ext_arr, ext_arr_ptr

ext_arr=['Image']

if (im_extensions gt 0) then begin
    ext_cnt=im_extensions-1
    for i=0,ext_cnt do begin
        ext_index=i+1
        ext_id=strtrim(string(ext_index),2)
        tag_label= 'Extension ' +ext_id
        ext_arr=[[ext_arr], [tag_label]]
    endfor
endif
if arg_present(ext_arr_ptr) then ext_arr_ptr=ptr_new(ext_arr, /allocate_heap)

end


pro CImWin::AddPntMode, pmode

struct={CPntMode, $
        PointingMode:'', $
        Type:'' $
       }

case pmode of
    'pan': newstruct={CPntMode,'click','pan'}
    'peak fit': newstruct={CPntMode,'box','peak fit'}
    'unravel': newstruct={CPntMode,'box','unravel'}
    'stat': newstruct={CPntMode,'box','stat'}
    'zbox': newstruct={CPntMode,'box','zbox'}
    'depth': newstruct={CPntMode,'box','depth'}
    'horizontal': newstruct={CPntMode,'box','horizontal'}
    'vertical': newstruct={CPntMode,'box','vertical'}
    'diagonal': newstruct={CPntMode,'diag','diagonal'}
    'depth': newstruct={CPntMode,'box','depth'}
    'contour': newstruct={CPntMode,'box','contour'}
    'surface': newstruct={CPntMode,'box','surface'}
    'contour': newstruct={CPntMode,'box','contour'}
    'phot': newstruct={CPntMode,'aperture','phot'}
    'strehl': newstruct={CPntMode,'aperture','strehl'}
    'filler':newstruct={CPntMode,'filler','none'}
    else: newstruct={CPntMode,'',''}
endcase

widget_control, self.baseid, get_uval=winbase_uval

pnt_mode=*(winbase_uval.pmode_ptr)
; if the pointing mode already exists, then bring that wid forward
; **this should already happen** and move that pointing mode to the
; front of the array
exist=where(pnt_mode.type eq pmode)
exist=long(exist[0])
exist_index=exist
if (exist lt 0) then exist=0 else exist=1

n_modes=size(pnt_mode, /n_elements)

if (exist) then begin
    ; make a new pointing mode array
    npnt_mode={CPntMode,'',''}
    npnt_mode=newstruct
    cnt1=exist_index-1
    cnt2=exist_index+1
    print, npnt_mode
    for i=0,cnt1 do begin
        npnt_mode=[[npnt_mode],[pnt_mode[i]]]
        print, npnt_mode
    endfor
        for i=cnt2,n_modes-1 do begin
            npnt_mode=[[npnt_mode],[pnt_mode[i]]]
            print, npnt_mode
        endfor
endif else begin
    ; if the array is empty, then fill it with the pointing mode
    if (pnt_mode[0].pointingmode eq '') then begin
        npnt_mode=newstruct
    endif else begin
    ; else, add the new pointing mode and the old pointing modes 
    ; to the stack
        cnt=n_modes-1
        npnt_mode=newstruct
        for i=0,cnt do begin
            npnt_mode=[[npnt_mode],[pnt_mode[i]]]
        endfor
    endelse
endelse

*(winbase_uval.pmode_ptr)=npnt_mode

; update the widget display to reflect the new pointing mode
widget_control, winbase_uval.wids.pmode, set_value=npnt_mode[0].Type

if (npnt_mode[0].Type eq 'zbox') then begin
  widget_control, winbase_uval.wids.zbox_button, set_value=1
endif else begin
  widget_control, winbase_uval.wids.zbox_button, set_value=0
endelse

if (npnt_mode[0].Type eq 'pan') then begin
  widget_control, winbase_uval.wids.pan_button, set_value=1
endif else begin
  widget_control, winbase_uval.wids.pan_button, set_value=0
endelse

widget_control, self.baseid, set_uval=winbase_uval
print, 'final pnt_mode array'
print, *(winbase_uval.pmode_ptr)

end


pro CImWin::RmPntMode, pmode

struct={CPntMode, $
        PointingMode:'', $
        Type:'' $
       }

widget_control, self.baseid, get_uval=winbase_uval

pnt_mode=*(winbase_uval.pmode_ptr)
n_modes=size(pnt_mode, /n_elements)

; find the pointing mode in the stack and remove it
exist=where(pnt_mode.type eq pmode)
exist=long(exist[0])
exist_index=exist

if (exist eq 0) then begin
    if (n_modes gt 1) then begin
        cnt=n_modes-1
        npnt_mode={CPntMode,'',''}
        npnt_mode=pnt_mode[1]
        for i=2,cnt do begin
            npnt_mode=[[npnt_mode],[pnt_mode[i]]]
        endfor
    endif else begin
        npnt_mode={CPntMode,'filler','none'}
    endelse
endif else begin        
    npnt_mode={CPntMode,'',''}
    npnt_mode=pnt_mode[0]
    cnt1=exist_index-1
    cnt2=exist_index+1
    print, 'adding first element'
    print, npnt_mode
    print, 'exist= ', exist_index, 'cnt1 = ', cnt1, 'cnt2 = ', cnt2

    ; add the elements prior to the mode you remove
    for i=1,cnt1 do begin
        npnt_mode=[[npnt_mode],[pnt_mode[i]]]
    endfor

    ; add the elements after to the mode you remove
    for i=cnt2,n_modes-1 do begin
        npnt_mode=[[npnt_mode],[pnt_mode[i]]]
    endfor
endelse

*(winbase_uval.pmode_ptr)=npnt_mode

; update the label on the image window to reflect the current pointing
; mode
widget_control, winbase_uval.wids.pmode, set_value=npnt_mode[0].Type

if (npnt_mode[0].Type eq 'zbox') then begin
  widget_control, winbase_uval.wids.zbox_button, set_value=1
endif else begin
  widget_control, winbase_uval.wids.zbox_button, set_value=0
endelse

if (npnt_mode[0].Type eq 'pan') then begin
  widget_control, winbase_uval.wids.pan_button, set_value=1
endif else begin
  widget_control, winbase_uval.wids.pan_button, set_value=0
endelse

widget_control, self.baseid, set_uval=winbase_uval
print, *(winbase_uval.pmode_ptr)

end

pro CImWin::GetActiveWindowParams

widget_control, self.BaseId, get_uval=uval
widget_control, self.parentbaseid, get_uval=conbase_uval

; save the imwin draw dimensions 
conbase_uval.actwin_xs=uval.xs
conbase_uval.actwin_ys=uval.ys
conbase_uval.actwin_diagonal=self.dwidth

; save the imwin base dimensions 
actwin_base_info=widget_info(self.BaseId, /geometry)
conbase_uval.actwin_xbase_size=actwin_base_info.xsize
conbase_uval.actwin_ybase_size=actwin_base_info.ysize

conbase_uval.actwin_xpad=actwin_base_info.xpad
conbase_uval.actwin_ypad=actwin_base_info.ypad

; save the image zoom
conbase_uval.actwin_xscale=self.xscale
conbase_uval.actwin_yscale=self.yscale

; save the display minimum and maximum values
conbase_uval.actwin_dispmin=self.DispMin
conbase_uval.actwin_dispmax=self.DispMax

; save the image display scale
conbase_uval.actwin_dispscl=self.DispScale

; save the axes order
conbase_uval.actwin_axesorder=self.axesorder

; save the image tv_p0
conbase_uval.actwin_tv_p0=uval.tv_p0

; save the number of axes
conbase_uval.actwin_num_axes=self.naxis

; get the z min and max for the image
conbase_uval.actwin_zmin=self.ZMin
conbase_uval.actwin_zmax=self.ZMax

; get collapse value
conbase_uval.actwin_collapse=self.collapse

; get the expand button designation
conbase_uval.actwin_wide=uval.wide

; get the total DN or DN/s designation
conbase_uval.actwin_dns=self.current_display

; check to see if this is on range or slice, 0=slice, 1=range
slice=widget_info(uval.wids.cube_range_button, /button_set)
conbase_uval.actwin_cube_range=slice

widget_control, uval.wids.cube_range_min, get_value=range_min
widget_control, uval.wids.cube_range_max, get_value=range_max

conbase_uval.actwin_cube_range_min=range_min
conbase_uval.actwin_cube_range_max=range_max

widget_control, uval.wids.cube_curmin, get_value=curmin
widget_control, uval.wids.cube_curmax, get_value=curmax
widget_control, uval.wids.cube_slice_box, get_value=boxcar
widget_control, uval.wids.cube_slider, get_value=slide_val

conbase_uval.actwin_cube_curmin=curmin
conbase_uval.actwin_cube_curmax=curmax
conbase_uval.actwin_cube_slice_box=boxcar
conbase_uval.actwin_cube_slider=slide_val

widget_control, self.parentbaseid, set_uval=conbase_uval

end

pro CImWin::SetActiveWindowParams

widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; set the expand button
if (conbase_uval.actwin_wide eq 1) then begin
    uval.wide=1
    ; change label of expand button
    values=['More', 'Less']
    widget_control, uval.wids.expand_button, set_value=values[uval.wide]
    ; map hidden base
    widget_control, uval.wids.bottom_base, map=uval.wide
endif

; set the window dimensions
widget_control, uval.wids.draw, xsize=conbase_uval.actwin_xs
widget_control, uval.wids.draw, ysize=conbase_uval.actwin_ys
self.xs=conbase_uval.actwin_xs
self.ys=conbase_uval.actwin_ys
self.dwidth=conbase_uval.actwin_diagonal

new_base_xs=conbase_uval.actwin_xbase_size-(2*conbase_uval.actwin_xpad)
new_base_ys=conbase_uval.actwin_ybase_size-(2*conbase_uval.actwin_ypad)
widget_control, self.BaseId, xsize=new_base_xs, ysize=new_base_ys

; set the image zoom
self.xscale=conbase_uval.actwin_xscale
self.yscale=conbase_uval.actwin_yscale

; set the display minimum and maximum values
self.DispMin=conbase_uval.actwin_dispmin
self.DispMax=conbase_uval.actwin_dispmax

; set the image display scale
self.DispScale=conbase_uval.actwin_dispscl

; set the collapse value
self.collapse=conbase_uval.actwin_collapse
widget_control, uval.wids.collapse_list, set_droplist_select=self.collapse

if (im_zs gt 1) then begin
    self.NAxis=3
endif else begin
    self.NAxis=2
endelse

if (conbase_uval.actwin_num_axes ne self.NAxis) then begin
    if (conbase_uval.actwin_num_axes eq 2) then begin
        ; new image has 3 axes
        self.axesorder=[2,1,0]
        im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
        im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

        self.DispIm_xs=im_s[0]
        self.DispIm_ys=im_s[1]

        ; update cube params
        widget_control, uval.wids.cube_curzs, set_value=strtrim(im_s[2], 2)

        ; set the z limits on the displayed image
        self.Zmin=0
        self.Zmax=im_s[2]-1

        ; update current range limits
        widget_control, uval.wids.cube_range_min, set_value=strtrim(self.Zmin, 2)
        widget_control, uval.wids.cube_range_max, set_value=strtrim(self.Zmax, 2)
        widget_control, uval.wids.cube_curmin, set_value=strtrim(self.Zmin, 2)
        widget_control, uval.wids.cube_curmax, set_value=strtrim(self.Zmax, 2)
        widget_control, uval.wids.cube_range_button, set_button=conbase_uval.actwin_cube_range

        ; set slider max... if 2D, set max to 1 because it must be ne min
        widget_control, uval.wids.cube_slider, $
                        set_slider_max=((im_s[2]-1) > 1)
        widget_control, uval.wids.cube_slider, set_value=0

        z0=self.Zmin
        z1=self.Zmax

        case self.collapse of 
            0: begin
                ; median the collapsed cube
                reformed_im=reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1)
                im2=cmapply('USER:CMMEDIAN', reformed_im, 3)
            end
            1: begin
                ; average the collapsed cube
                im2=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)
            end
        endcase
    endif else begin
        ; new image has only 2 axes
        self.axesorder=[0,1,2]
        im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
        im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

        self.DispIm_xs=im_s[0]
        self.DispIm_ys=im_s[1]

        self.Zmin=0
        self.Zmax=0

        ; update cube params
        widget_control, uval.wids.cube_curzs, set_value=strtrim(im_s[2], 2)

        ; update current range limits
        widget_control, uval.wids.cube_range_min, set_value=strtrim(self.Zmin, 2)
        widget_control, uval.wids.cube_range_max, set_value=strtrim(self.Zmax, 2)
        widget_control, uval.wids.cube_curmin, set_value=strtrim(self.Zmin, 2)
        widget_control, uval.wids.cube_curmax, set_value=strtrim(self.Zmax, 2)
        widget_control, uval.wids.cube_range_button, set_button=conbase_uval.actwin_cube_range

        ; set slider max... if 2D, set max to 1 because it must be ne min
        widget_control, uval.wids.cube_slider, $
                        set_slider_max=((im_s[2]-1) > 1)
        widget_control, uval.wids.cube_slider, set_value=0

        z0=self.zmin
        z1=self.zmax
        
        im2=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)
    endelse
endif else begin
    ; save the axes order
    self.axesorder=conbase_uval.actwin_axesorder
    im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

    self.DispIm_xs=im_s[0]
    self.DispIm_ys=im_s[1]

    if (self.NAxis eq 3) then begin
        ; check to see if this is on range or slice, 0=range, 1=slice
        range=conbase_uval.actwin_cube_range
        ; set the z limits on the new image accordingly
        if (range) then begin
            ; range limits
            widget_control, uval.wids.cube_range_min, set_value=strtrim(conbase_uval.actwin_cube_range_min, 2)
            widget_control, uval.wids.cube_range_max, set_value=strtrim(conbase_uval.actwin_cube_range_max, 2)
            ; check the min range
            if (conbase_uval.actwin_cube_range_min gt im_s[2]) then begin
                self.zMin=im_s[2]-1 
                widget_control, uval.wids.cube_range_min, set_value=im_s[2]-1 
                widget_control, uval.wids.cube_curmin, set_value=strtrim(im_s[2]-1,2)
            endif else begin
                widget_control, uval.wids.cube_range_min, get_value=range_min
                self.zMin=range_min
            endelse
            ; check the max range
            if (conbase_uval.actwin_cube_range_max ge im_s[2]) then begin
                self.zMax=im_s[2]-1 
                widget_control, uval.wids.cube_range_max, set_value=im_s[2]-1
                widget_control, uval.wids.cube_curmax, set_value=strtrim(im_s[2]-1,2)
            endif else begin
                widget_control, uval.wids.cube_range_max, get_value=range_max 
                self.zMax=range_max
            endelse
            ; set slider max... if 2D, set max to 1 because it must be ne min
            widget_control, uval.wids.cube_slider, set_slider_max=((im_s[2]-1) > 1)
            if conbase_uval.actwin_cube_slider gt (im_s[2]-1) then begin
                slider_val=0.
            endif else begin
                slider_val=conbase_uval.actwin_cube_slider
            endelse
            widget_control, uval.wids.cube_slice_box, set_value=strtrim(conbase_uval.actwin_cube_slice_box < (im_s[2]-1),2)
            widget_control, uval.wids.cube_slider, set_value=strtrim(conbase_uval.actwin_cube_slider < (im_s[2]-1), 2)

            ; select the range button and unselect the slice button
            widget_control, uval.wids.cube_single_button, set_button=0
            ; disable slider, and the other base
            widget_control, uval.wids.cube_slider, sensitive=0
            widget_control, uval.wids.cube_slice_box_base, sensitive=0
            ; enable current base
            widget_control, uval.wids.cube_range_base, /sensitive
        endif else begin
            ; 0=slice
            widget_control, uval.wids.cube_single_button, set_button=1
            widget_control, uval.wids.cube_slice_box, set_value=strtrim(conbase_uval.actwin_cube_slice_box < (im_s[2]-1),2)
            widget_control, uval.wids.cube_range_button, set_button=strtrim(conbase_uval.actwin_cube_slider < (im_s[2]-1), 2)
            ; range limits
            widget_control, uval.wids.cube_range_min, set_value=strtrim(conbase_uval.actwin_cube_range_min, 2)
            widget_control, uval.wids.cube_range_max, set_value=strtrim(conbase_uval.actwin_cube_range_max, 2)
            ; slice limits 
            widget_control, uval.wids.cube_curmin, set_value=strtrim(conbase_uval.actwin_cube_curmin, 2)
            widget_control, uval.wids.cube_curmax, set_value=strtrim(conbase_uval.actwin_cube_curmax, 2)
            ; check the min range
            if (conbase_uval.actwin_cube_curmin gt im_s[2]) then begin
                self.zMin=im_s[2]-1 
                widget_control, uval.wids.cube_curmin, set_value=strtrim(im_s[2]-1,2)
            endif else begin
                widget_control, uval.wids.cube_curmin, get_value=curmin 
                self.zMin=curmin
            endelse
            ; check the max range
            if (conbase_uval.actwin_cube_curmax gt im_s[2]) then begin
                self.zMax=im_s[2]-1 
                widget_control, uval.wids.cube_curmax, set_value=strtrim(im_s[2]-1,2)
            endif else begin
                widget_control, uval.wids.cube_curmax, get_value=curmax 
                self.zMax=curmax
            endelse
            widget_control, uval.wids.cube_slider, set_slider_max=((im_s[2]-1) > 1)
            widget_control, uval.wids.cube_slider, set_value=strtrim(conbase_uval.actwin_cube_slider < (im_s[2]-1), 2)

            ; select the slice button and unselect the range button
            widget_control, uval.wids.cube_range_button, set_button=0
            ; disable other base
            widget_control, uval.wids.cube_range_base, sensitive=0
            ; enable slider, other base
            widget_control, uval.wids.cube_slider, /sensitive
            widget_control, uval.wids.cube_slice_box_base, /sensitive
        endelse

        ; update cube params
        widget_control, uval.wids.cube_curzs, set_value=strtrim(im_s[2], 2)
        ; update current range limits
        widget_control, uval.wids.cube_range_button, set_button=conbase_uval.actwin_cube_range

        ; set the z limits on the displayed image
        z0=self.Zmin
        z1=self.Zmax

        case self.collapse of 
            0: begin
                ; median the collapsed cube
                reformed_im=reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1)
                im2=cmapply('USER:CMMEDIAN', reformed_im, 3)
            end
            1: begin
                ; average the collapsed cube
                im2=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)
            end
        endcase
    endif else begin
        ; transpose image
        im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
        im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

        self.DispIm_xs=im_s[0]
        self.DispIm_ys=im_s[1]

        self.Zmin=0
        self.Zmax=0

        ; update cube params
        widget_control, uval.wids.cube_curzs, set_value=strtrim(im_s[2], 2)
        ; update current range limits
        widget_control, uval.wids.cube_range_min, set_value=strtrim(self.ZMin, 2)
        widget_control, uval.wids.cube_range_max, set_value=strtrim(self.ZMax, 2)
        widget_control, uval.wids.cube_curmin, set_value=strtrim(self.ZMin, 2)
        widget_control, uval.wids.cube_curmax, set_value=strtrim(self.ZMax, 2)
        widget_control, uval.wids.cube_range_button, set_button=conbase_uval.actwin_cube_range

        ; set slider max... if 2D, set max to 1 because it must be ne min
        widget_control, uval.wids.cube_slider, $
                        set_slider_max=((im_s[2]-1) > 1)
        widget_control, uval.wids.cube_slider, set_value=0

        ; 2d image
        z0=self.Zmin
        z1=self.Zmax
        im2=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)
    endelse
endelse

; set the image tv_p0, but make sure it doesn't go past the image's
; largest dimension
atv_p0=conbase_uval.actwin_tv_p0

if (atv_p0[0] gt im_xs) then atv_p0[0]=im_xs
if (atv_p0[1] gt im_ys) then atv_p0[1]=im_ys

uval.tv_p0=atv_p0

widget_control, self.BaseId, set_uval=uval

; current order of the image axes
self.CurIm_s=im_s

; the pointer of the displayed image is set equal to the transposed image
*self.p_DispIm=im2

; find out if the data is in DN or DN/s
self->SetCurrentDisplay, conbase_uval.actwin_dns

widget_control, self.BaseId, get_uval=imwin_uval
imwin_uval.current_display_skip=1
widget_control, self.BaseId, set_uval=imwin_uval

self->DisplayAsDN, /no_rescale

end

pro CImWin::ActiveParamsUpdate

widget_control, self.ParentBaseId, get_uval=conbase_uval

if ptr_valid(conbase_uval.p_curwin) then begin
    ; get the window parameters from the active window (set in the conbase uval)
    activewin_obj=*(conbase_uval.p_curwin)
    activewin_obj->GetActiveWindowParams

    ; set the active window parameters in this cimwin
    self->SetActiveWindowParams

    ; update the display
    self->UpdateImParam, self.p_ImObj
    self->UpdateText
    self->DrawImage
endif else begin
    ; print error message
    message='There is currently no active window.'
    answer=dialog_message(message, dialog_parent=self.baseid, /error)
    return
endelse

end

pro CImWin::UpdateImParam, p_ImObj

; get control base uval
widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

im_ptr=p_ImObj
im=*p_ImObj
im_zs=im->GetZS()

; handle data cubes
if has_valid_cconfigs(conbase_uval, cconfigs) then begin
            if (im_zs gt 1) then begin
                axes=*(cconfigs->GetAxesLabels3d()) 
            endif else begin
                axes=*(cconfigs->GetAxesLabels2d())
            endelse
endif else begin
    axes=['AXIS 1', 'AXIS 2', 'AXIS 3']
endelse

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

end

pro CImWin::UpdateZooms

widget_control, self.baseid, get_uval=uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

if (im_zs gt 1) then begin
    ; transpose image
    im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]
endif else begin
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]
endelse

; calculate the image zoom
imscale=(self.xs/float(im_s[0]))<(self.ys/float(im_s[1]))
self.xscale=imscale
self.yscale=imscale

;scl_label=string(imscale)
scl_label=string(format='(F6.3)', imscale)
 
widget_control, uval.wids.zoom_xscl, set_value=scl_label
widget_control, uval.wids.zoom_yscl, set_value=scl_label

end

pro CImWin::UpdateDispIm

widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; transpose image
im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

; if this is an unraveled cube, then transpose the unraveled locations
if ptr_valid(self.p_unraveled) then begin
    unraveled_locations=*(self.p_unraveled)
    new_locations=transpose(unraveled_locations, self.AxesOrder[0:self.NAxis-1])
    *(self.p_unraveled)=new_locations
endif

self.DispIm_xs=im_s[0]
self.DispIm_ys=im_s[1]

self.current_display_update=1.

; check to see if this is a slice event, 0=slice, 1=range
slice=widget_info(uval.wids.cube_range_button, /button_set)
if (slice eq 0) then begin
    ; make sure the boxcar is within the limits
    if (self.boxcar lt 1) then begin
        self.boxcar=1
        ; update the display
        widget_control, uval.wids.cube_slice_box, set_value=self.boxcar
    endif
    if (self.boxcar gt im_s[2]-1) then begin
        self.boxcar=im_s[2]-1
        ; update the display
        widget_control, uval.wids.cube_slice_box, set_value=self.boxcar
    endif
    ; smooth the data
    im=smooth(im,[1,1,self.boxcar], /edge_truncate)
endif

; reset Z if flag is set
if self.ResetZ eq 1 then begin
    ; reset Z to the previous min and max for this orientation    
    axes_order=self->GetAxesOrder()
    axes_minmax=self->GetAxesMinMax()

    self.ZMin=axes_minmax[axes_order[2],0]
    self.ZMax=axes_minmax[axes_order[2],1]

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

    ; send an event as if range button was hit
    widget_control, uval.wids.cube_range_button, /set_button
    ev={WIDGET_BUTTON, ID:uval.wids.cube_range_button, $
       TOP:self.BaseId, HANDLER:uval.wids.cube_range_button, $
       SELECT:1}
    widget_control, uval.wids.cube_range_button, send_event=ev
endif

if (im_zs gt 1) then begin
    ; collapse image
    z0=self.ZMin
    z1=self.ZMax
    case self.collapse of 
        0: begin
            ; median the collapsed cube
            reformed_im=reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1)
            im2 = cmapply('USER:CMMEDIAN', reformed_im, 3)

        end
        1: begin
            ; average the collapsed cube
            im2=total(reform(im[*, *, z0:z1], im_s[0], im_s[1], z1-z0+1), 3)/(z1-z0+1)
        end
    endcase
endif else begin
    im2=im
endelse

; flip image if needed to give a rotation from N=up, E=left
; only want to flip if we have an upgraded detector AND flip > 0
hxrg = sxpar(hd, 'HXRGVERS')
if (hxrg gt 0 ) then begin ; kwd is 0 if it is not in header
  ql2flip = sxpar(hd, 'QL2FLIP')
  if (ql2flip eq 0 ) then begin ; kwd is 0 if it is not in header
    ; image has not been flipped previously
    if has_valid_cconfigs(conbase_uval, cconfigs) then begin
      print, 'H2RG detector: getting image flip setting from config'
      flip=cconfigs->GetFlip()
      print, 'Flip is ', flip
    endif else begin
      flip=0
    endelse
    if ( flip gt 0 ) then begin
       im2=reverse(im2,flip)
    endif
  endif else begin
    print, 'H2RG detector, but QL2FLIP header keyword indicates previously flipped'
  endelse     
endif else begin
  print, 'Original detector: ignoring flip'
endelse

; check to see if you do the display as DN or total DN
; get the itime and coadds keywords from the config file, if possible

if has_valid_cconfigs(conbase_uval, cconfigs) then begin
   print, 'Getting itime, coadds keywords from config'
            itime_kw=cconfigs->GetItimeFitskw()
            coadds_kw=cconfigs->GetCoaddsFitskw()
endif else begin
   print, 'no valid config, using defaults for itime_kw and coadds_kw'
	itime_kw='TRUITIME'
	coadds_kw='COADDS'
endelse

; SPEC: H2 was DN/s, coadds ?, H2RG is DN/s with averaged coadds (2 coadds DN/s = 1 coadd DN/s)
; IMAG: H1 was DN/s, H2RG is DN, and coadds are added (2 coadds has 2x DN as 1 coadd)
if (hxrg gt 0 ) then begin
  if has_valid_cconfigs(conbase_uval, cconfigs) then begin
    print, 'Getting pixel units from config'
    pixelunits=cconfigs->GetPixelUnit()
  endif else begin
    print, 'no valid config, using DN/s for pixel units'
    pixelunits='DN/s'
  endelse
endif else begin
  print, 'Original detector: assuming pixel units = DN/s'
  pixelunits='DN/s'
endelse
print, 'pixelunits= ', pixelunits

itime=sxpar(hd, itime_kw)
coadds=sxpar(hd, coadds_kw)
print, 'itime= ', itime, ' coadds= ', coadds
; jlyke thinks there is no reason to multiply by coadds...
; fix im2 to be the correct displayed im
if (itime ne 0) then begin
    if (coadds ne 0) then begin
		; MDP reformat to reduce repetition
        if (self.current_display_update) then begin
	        case self.current_display of
                   'As Total DN': BEGIN
                      if ( pixelunits eq 'DN/s') then begin
                         ; im2=im2*itime*coadds
                         im2=im2*itime
                      endif
                   END
                   'As DN/s': BEGIN
                      if (pixelunits eq 'DN') then begin
                         im2=im2 ;/(itime*coadds)
                         im2=im2/itime
                      endif
                   END
	            else:
	        endcase
	        if (uval.current_display_skip ne 0) then begin
	            uval.current_display_skip=0
	            widget_control, self.BaseId, set_uval=uval
	        endif
	        self.current_display_update=0
        endif    
		; end MDP mods

		
    endif else begin
        print, ['ERROR: Could not find the coadds keyword.', $
                 'No manipulation of the data']
    endelse
endif else begin
    print, ['ERROR: Could not find the integration time keyword.', $
             'No manipulation of the data']
endelse

; automatically scales the image by computing the mean and scales the
; min and max values according to the standard deviation
if self.DoAutoScale eq 1 then begin
	print, "Autoscaling..."
    ; don't count the NaN values
    ; use the cconfigs values for the scale max and min, if possible
	if has_valid_cconfigs(conbase_uval, cconfigs) then begin
                im_max_con=cconfigs->GetImScaleMaxCon()
                im_min_con=cconfigs->GetImScaleMinCon()
        endif else begin
	 	im_max_con=5.
    	        im_min_con=-3.
	endelse
    meanval=moment(im2, sdev=im_std, /NAN)
    medianval=median(im2)
    maxval=max(im2)
    ; Set the DispMin/Max for each stretch
    ; jlyke 2020-04-10
    ; Images look best when the min value
    ; is smaller than the max value
    ; For the non-linear stretches, using the mean + variance seems
    ; better than using maxval or the mean + small factor * im_std
    case self.DispScale of
       'linear': begin
          self.DispMax=meanval[0]+im_max_con*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
       'negative': begin
          self.DispMax=meanval[0]+im_max_con*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
       'sqrt': begin
          self.DispMax=meanval[0]+im_std*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
       'asinh': begin
          self.DispMax=maxval/2.
          self.DispMax=meanval[0]+im_std*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
       'histeq':begin
          self.DispMax=meanval[0]+im_max_con*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
       'logarithmic':begin
          ; Logarithmic scaling algorithm borrowed from atv.pro
          self.DispMax=meanval[0]+im_std*im_std
          self.DispMin=meanval[0]+im_min_con*im_std
       end
    endcase

    ;self.DispMax=meanval[0]+im_max_con*im_std
    ;self.DispMin=meanval[0]+im_min_con*im_std
    print, 'the mean image value is ', strtrim(meanval[0],2)
    print, 'the median image value is ', strtrim(medianval,2)
    print, 'the standard deviation of the image value is ', strtrim(im_std,2)    
    self.DoAutoScale=0
    self->UpdateText
endif

; current order of the image axes
self.CurIm_s=im_s
; the pointer of the displayed image is set equal to the modified image
*self.p_DispIm=im2

end
 

pro CImWin::DrawImage, PS=ps, noerase=noerase

; get the imwin & conbase uvals
widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

im=*self.p_DispIm
pmode=*uval.pmode_ptr

; get dimensions of window
win_xs=float(self.xs)
win_ys=float(self.ys)

; get subimage (don't use whole image because it is too slow if image gets too
; big)
x0 = 0 > fix(uval.tv_p0[0]-(win_xs/(2.*self.XScale)))
y0 = 0 > fix(uval.tv_p0[1]-(win_ys/(2.*self.YScale)))

x1_tmp=fix(x0+1+win_xs/self.XScale)
if (x1_tmp lt 0) then begin
    x1=self.DispIm_xs-1
endif else begin
    x1=fix(x0+1+win_xs/self.XScale) < (self.DispIm_xs - 1)
endelse

y1_tmp=fix(y0+1+win_ys/self.YScale)
if (y1_tmp lt 0) then begin
    y1=self.DispIm_ys-1
endif else begin
    y1=fix(y0+1+win_ys/self.YScale) < (self.DispIm_ys - 1)
endelse

;x1=fix(x0+1+win_xs/self.XScale) < (self.DispIm_xs - 1)
;y1 = fix(y0+1+win_ys/self.YScale) < (self.DispIm_ys - 1)

if keyword_set(verbose) then begin ; MDP
print, 'x0 = ', x0
print, 'y0 = ', y0

print, 'win_xs = ', win_xs
print, 'win_ys = ', win_ys

print, 'xscale = ', self.XScale
print, 'yscale = ', self.YScale

print, 'win_xs/xscale = ', x0+1+win_xs/self.XScale
print, 'win_ys/yscale = ', y0+1+win_ys/self.YScale

print, 'dispim xs = ', self.DispIm_xs
print, 'dispim ys = ', self.DispIm_ys

print, 'x1 = ', x1
print, 'y1 = ', y1
endif ; MDP

new_xs=((x1-x0+1)*self.XScale) > 2 ; MDP

new_ys=((y1-y0+1)*self.YScale) > 2 ; MDP

im=congrid(im[x0:x1, y0:y1], new_xs, new_ys)

if not (keyword_set(ps)) then begin
    ; make window active
    save=!D.WINDOW
    wset, self.DrawIndex
endif

; clear window and draw new image
if not (keyword_set(noerase)) then erase 

; display the new image
case self.DispScale of
    'linear': begin
        dispim = bytscl(im,min=self.DispMin,max=self.DispMax)
	end
    'negative': begin
        dispim = 255-bytscl(im,min=self.DispMin,max=self.DispMax)
    end
    'sqrt': begin
        dispim = bytscl(sqrt(im-self.DispMin),min=0,max=sqrt(self.DispMax-self.DispMin))
    end
    'asinh': begin
        sdi = stddev(im)
        dispim = bytscl(asinh((im-self.DispMin)/(sdi)),min=0,max=asinh((self.DispMax-self.DispMin)/(sdi)))
    end
    'histeq':begin
        dispim = bytscl(hist_equal(im,minv=self.DispMin,maxv=self.DispMax))
    end
    'logarithmic':begin
	; Logarithmic scaling algorithm borrowed from atv.pro
        offset = self.DispMin - $
                 (self.DispMax - self.DispMin) * 0.01
        
        dispim = bytscl(alog10(im-offset),$
                        min=alog10(self.Dispmin - offset), $
                        max=alog10(self.Dispmax - offset))
    end
    
    else: begin
        dispim = bytscl(im)
    endelse
endcase

tvimage,/tv,dispim,win_xs/2-((uval.tv_p0[0]-x0)*self.XScale)-1, $
   win_ys/2-((uval.tv_p0[1]-y0)*self.YScale)-1

; set window uval
widget_control, self.BaseId, set_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

if self.drawaxes then begin 
	; compute the output position in pixels (needed for overplotting axes)
	 sz = size(dispim)
	 plotpos = [win_xs/2-((uval.tv_p0[0]-x0)*self.XScale)-1,$
 			win_ys/2-((uval.tv_p0[1]-y0)*self.YScale)-1,$
			win_xs/2-((uval.tv_p0[0]-x0)*self.XScale)-1+sz[1],$
			win_ys/2-((uval.tv_p0[1]-y0)*self.YScale)-1+sz[2]$
			]

	self->DrawAxesLabels,plotpos,x0,x1,y0,y1
endif

; draw the appropriate box and circle
self->DrawImageBox_n_Circles

conbase_uval.new_image=0
widget_control, self.ParentBaseId, set_uval=conbase_uval

if not (keyword_set(ps)) then begin
    ; make window active
    wset, save
endif

; update the WCS text
; This means if you change the wavelength scaling, range etc, 
; the display on screen will update.
; TODO make the coords used the middle of the FOV, not the corner...
self->UpdateWCSDisplay, 0, 0

end

;------------------------------------------------------------
; Code added by Marshall Perrin
; Code modified by Michael McElwain
; - code extracted to use config file keywords
; - code extended for 2D images
pro CImWin::DrawAxesLabels,position,x0,x1,y0,y1

widget_control, self.ParentBaseId, get_uval=conbase_uval
cconfigs=*(conbase_uval.cconfigs_ptr)

ImObj=*(self.p_ImObj)  ; MDP
im_ptr=ImObj->GetData()

imdata=*im_ptr
hd=*(ImObj->GetHeader())

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; transpose image
im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]

; see if there are 3 axes or just 2
if (self.naxis eq 3) then begin
    ; find which axis is the longest, and assume this is the wavelength axis
	wavelength_length= max(im_s, wavelength_index) ; MDP
    ; get the wavelength solution and plate scale
    p_wavesol=self->WaveSol(wavelength_length, unit=wavelength_unit)

    platescale_kw=cconfigs->GetPlateScalekw()
    platescale=sxpar(hd, platescale_kw, count=platescale_cnt)
    if ((*p_wavesol)[0] eq -1) then return
    if (platescale_cnt eq 0) then return
    
	; create arrays with the axes values for all three cube sides, 
	; in the same order as the actual data cube.
	; Also create tick interval arrays. 
	; Here we treat all three axes as the same, for simplicity, and 
	; below we will overwrite the appropriate parts of these arrays
	; with the wavelength axis info.
	;
	; These arrays are in the DISPLAY axes order, not the intrinsic axes order!
	; e.g. 
	;   0 - the axis is displayed for X
	;   1 - the axis is displayed for Y
	;   2 - the axis is collapsed or a slice is chosen

    axes_values = ptrarr(3)
    axes_values[0] = ptr_new(findgen(im_s[0])*float(platescale))
    axes_values[1] = ptr_new(findgen(im_s[1])*float(platescale))
    axes_values[2] = ptr_new(findgen(im_s[2])*float(platescale))
  	axes_tickintervals = replicate(float(platescale)*5., 3)
    axes_tickminor = replicate(10., 3)
	axes_units = replicate("Arcsec",3)
	; stick the wavelength axis in the appropriate axis
	*(axes_values[wavelength_index])= *p_wavesol

    ; now grab out the DISPLAYED x and y axes. 
	;x = *axes_values(self.axesorder[0])
    ;y = *axes_values(self.axesorder[1])
	x = *axes_values(0)
    y = *axes_values(1)


	; which axis DISPLAYED is wavelength?
	; This is NOT the intrinsic axis for wavelength in the datacube, it's the
	; displayed index, as descibed above.
	;displayed_wavelength_index = where(self.axesorder eq  wavelength_index)
	if wavelength_index le 1 then begin
		; if we have a wavelength axis, arrange for there to be about 
		; four wavelength ticks across it, with the tick spacing either a
		; multiple of 1 or 5 in the last digit.
		case wavelength_index of
			0: waverange=x[x1]-x[x0]
			1: waverange=y[y1]-y[y0]
		endcase
		sep = waverange / 4
		wavetick = 10.^round(alog10(sep))
		if waverange/wavetick gt 12 then wavetick *=5
		if waverange/wavetick lt 2 then wavetick /=2
		if alog10(wavetick) eq fix(alog10(wavetick)) then waveminor = 10 else waveminor=5

		axes_tickintervals[wavelength_index] = wavetick
		axes_tickminor[wavelength_index] = waveminor
		;waveunit = *(p_astr.cunit)[wavelength_index]
		;p_im = self->getImObj()
		;p_astr = (*p_im)->GetAstr(valid=astr_valid)
		;if ptr_valid(p_astr) then $
			;axes_units[wavelength_index] = strcompress(((*p_astr).cunit)[wavelength_index],/remove) else $
			;axes_units[wavelength_index] ="!7l!3m"
			axes_units[wavelength_index] = wavelength_unit
		if axes_units[wavelength_index] eq "um" then axes_units[wavelength_index] = "microns"
	endif 
 
	if has_valid_cconfigs(conbase_uval, cconfigs) then begin
		axes_titles=*( cconfigs->GetAxesLabels3d()) 
	endif else begin
		; default titles are OSIRIS format
		axes_titles = ["Wavelength", "Y", "X"]
	endelse
	; re-arrange axes titles to match the display order
	axes_titles = axes_titles[self.axesorder]

	for i=0L,self.naxis-1 do axes_titles[i] = axes_titles[i] + " ("+axes_units[i]+")"

   	
    	plot,[0],/nodata,/noerase,xrange=[x[x0],x[x1]],yrange=[y[y0],y[y1]],$
      /xs,/ys,position=position,/device,$
      xtitle=axes_titles[0],ytitle=axes_titles[1],$
      xtickinterval=axes_tickintervals[0],$
      ytickinterval=axes_tickintervals[1],$
      xminor=axes_tickminor[0], $
      yminor=axes_tickminor[1]
	
;    plot,[0],/nodata,/noerase,xrange=[x[x0],x[x1]],yrange=[y[y0],y[y1]],$
;      /xs,/ys,position=position,/device,$
;      xtitle=axes_titles[self.axesorder[0]],ytitle=axes_titles[self.axesorder[1]],$
;      xtickinterval=axes_tickintervals[self.axesorder[0]],$
;      ytickinterval=axes_tickintervals[self.axesorder[1]],$
;      xminor=axes_tickminor[self.axesorder[0]], $
;      yminor=axes_tickminor[self.axesorder[1]]
endif else begin
	; --- Display code for 2D images only ---
    ; get the platescale
    platescale_kw=cconfigs->GetPlateScalekw()
    platescale=sxpar(hd, platescale_kw, count=platescale_cnt)
    if (platescale_cnt eq 0) then return
    
    axes_values = ptrarr(3)
    axes_values[0] = ptr_new(findgen(im_s[0])*float(platescale))
    axes_values[1] = ptr_new(findgen(im_s[1])*float(platescale))
    axes_values[2] = ptr_new(findgen(im_s[2])*float(platescale))
    x = *axes_values(self.axesorder[0])
    y = *axes_values(self.axesorder[1])
    
    ; axes_titles=*(cconfigs->GetAxesLabels3d())
    axes_titles = ["X (arcsec)", "Y (arcsec)", "Z (arcsec)"]

    axes_tickintervals = [0.01,1,1]
    axes_tickminor = [5,10,10]
    
    
    plot,[0],/nodata,/noerase,xrange=[x[x0],x[x1]],yrange=[y[y0],y[y1]],$
      /xs,/ys,position=position,/device,$
      xtitle=axes_titles[self.axesorder[0]],ytitle=axes_titles[self.axesorder[1]],$
      xtickinterval=axes_tickintervals[self.axesorder[0]],$
      ytickinterval=axes_tickintervals[self.axesorder[1]],$
      xminor=axes_tickminor[self.axesorder[0]], $
      yminor=axes_tickminor[self.axesorder[1]]
endelse
ptr_free, axes_values
end


PRO CImWin::UpdateWCSDisplay, disp_x, disp_y
	; update astrometry printout   
	; arguments X and Y are a position in pixels in the displayed image.
	; HISTORY: Added by MDP, 2007-07-06
	; error checking added; MDP 2007-08-10
	

	p_ImObj = self->getImObj()
	if not ptr_valid(p_ImObj) then return
	if not obj_valid(*p_imObj) then return
	p_astr = (*p_ImObJ)->GetAstr(valid=astr_valid)

        if astr_valid then begin
		position = fltarr(3) ; contains the position in AXIS1, AXIS2, AXIS3 order
		position[self.axesorder[0]] = disp_x
		position[self.axesorder[1]] = disp_y
		position[self.axesorder[2]] = [self.zmin+self.zmax]/2.0 ; average Z value.
		
		case n_elements((*p_astr).ctype) of
		2: begin
			xy2ad, position[0], position[1], *(p_astr), ra, dec
			wcsstring = (adstring(ra, dec, 2))[0]
		end
		3: begin
			xyz2adl, position[0], position[1], position[2], *(p_astr), ra, dec, lambda, waveunit=wavelength_unit
			wcsstring = (adstring(ra, dec, 2))[0]+',     '+$
			strcompress(string(lambda),/remove_all)+" "+strcompress( wavelength_unit, /remove_all)
		end
		else: wcsstring="Invalid WCS Header"
		endcase
	endif else wcsstring="No WCS Present"

	widget_control, self.baseid, get_uval=uval
	widget_control, uval.wids.wcs, set_value=wcsstring

end

function CImWin::WaveSol, wavelength_length, axis=wavelength_index, unit=cunit;, axisname=axisname
; 2007-07-02 Modified by M. Perrin to include check for GMOS datacubes
;  also a minor speed increase on the for loop.
; 2007-07-06  Modified to use WCS astrometry structure rather than just
;  looking at the headers. This allows removal of above-mentioned GMOS code.
; 2007-10-18:  Output should always be in microns, either for OSIRIS default format
;   or WCS-compliant headers.

; find out if you can read in the fits headers
widget_control, self.ParentBaseId, get_uval=conbase_uval
 

; if you can, get the values for each of these keywords
; then calculate the wavelength solution accordingly
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr
hd_ptr=ImObj->GetHeader()
hd=*(hd_ptr)
astr_ptr=ImObj->GetAstr()

if ptr_valid(astr_ptr) then begin
	; Use WCS Astrometry Header to derive the wavelength solution
	im_s=([ImObj->GetXS(), ImObj->GetYS(), ImObj->GetZS()])
	; Assume the longest axis is wavelength
	; TODO do this better!! e.g. using CTYPE
	;
	; Wavelength Axes CTYPES from the FITS WCS standard:
	 wave_axes_types = ["FREQ", "ENER", "WAVN", "VRAD", "WAVE", "VOPT", "ZOPT", $
   		 "AWAV", "VELO", "BETA"]
	;Full_axis_names = ["Frequency", "Energy", "Wave Number", "Radial Velocity", "Wavelength", "Velocity", "Redshift", $
		;"Wavelength in Air", "Velocity", "Beta"]

	  for i = 0,n_elements(wave_axes_types)-1 do begin
		wavelength_index = (where( strmid((*astr_ptr).ctype,0,4) eq wave_axes_types[i], lambdact))[0]
		if lambdact eq 1 then break
	  endfor
	; if we haven't found the correct axis keyword, then guess that the longest axis
	; is the wavelength.
	if lambdact eq 0 then wavelength_length= max(im_s, wavelength_index) else wavelength_length=im_s[wavelength_index] ; MDP
	
	crpix = (*astr_ptr).crpix[wavelength_index]
	crval = (*astr_ptr).crval[wavelength_index]
	; allow EITHER CD or CDELT to specify the wavelength index. 
	; extast should properly handle all the various possiblities.
	cdelt = (*astr_ptr).cdelt[wavelength_index] * (*astr_ptr).cd[wavelength_index, wavelength_index]
	if tag_exist(*astr_ptr, "CUNIT") then cunit = (*astr_ptr).cunit[wavelength_index] else cunit = "micron"

endif else begin
	; use default OSIRIS keywords to derive the wavelength solution.
	cconfigs=*(conbase_uval.cconfigs_ptr)
    crpix_kw=cconfigs->GetArrayIndexkw()
    crval_kw=cconfigs->GetReferencekw()
    cdelt_kw=cconfigs->GetLinDispkw() 
    cunit_kw=cconfigs->GetUnitkw() 

    ; set default values for the header keywords in case they're
    ; net set
	wavelength_index = 1 ; OSIRIS default
	wavelength_length = imobj->GetXS() ; assuming wavelength axis is 1!
    if (crpix_kw eq '') then crpix_kw='CRPIX1'
    if (crval_kw eq '') then crval_kw='CRVAL1'
    if (cdelt_kw eq '') then cdelt_kw='CDELT1'
    if (cunit_kw eq '') then cunit_kw='CUNIT1'

	; check to make sure the keywords were in the header
	; if not, then return an error
	crpix=sxpar(hd, crpix_kw, count=crpix_cnt)
	if (crpix_cnt eq 0) then return, ptr_new(-1)
	
	crval=sxpar(hd, crval_kw, count=crval_cnt)
	if (crval_cnt eq 0) then return, ptr_new(-1)
	
	cdelt=sxpar(hd, cdelt_kw, count=cdelt_cnt)
	if (crpix_cnt eq 0) then return, ptr_new(-1)
	
	cunit=sxpar(hd, cunit_kw, count=cunit_cnt)
	if (cunit_cnt eq 0) then cunit='microns'
	
endelse
; if the wavelength solution is given in nm or Angstroms then
; change it over to microns for display purposes. 
if (strtrim(cunit,2) eq 'nm') then begin
    crval=crval/1000.
    cdelt=cdelt/1000.
	cunit = "microns"
endif
if (strtrim(cunit,2) eq 'angstroms') then begin
    crval=crval/10000.
    cdelt=cdelt/10000.
	cunit = "microns"
endif


; check to make sure crpix isn't greater than
; the length of the wavelength axis
if (crpix gt wavelength_length) then return, ptr_new(-1)
; MDP note: Technically speaking, the FITS WCS standard allows
; CRPIX values outside of the axis range, so this check is unnecessary.

; if the inputs are all valid, then compute the wavelength solution
start_wavelength=crval-(crpix-1)*cdelt
wave_solution = (start_wavelength+findgen(wavelength_length)*cdelt)
p_wavesol=ptr_new(wave_solution)

return, p_wavesol

end

pro CImWin::DrawImageBox_n_Circles

; get the imwin & conbase uvals
widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

im=*self.p_DispIm
pmode=*uval.pmode_ptr

; if zbox is the first item on the stack, then redraw the item in
; the next element of the stack
draw_item=pmode[0].pointingmode
if (pmode[0].type eq 'zbox') then begin
    draw_item=pmode[1].pointingmode
endif

; draw the appropriate box and circle
case draw_item of
    'box':  begin 
        if (conbase_uval.new_image eq 0) then begin
            if (uval.box_pres) then begin
                self->DrawBoxParams
                ; get the uval again
                widget_control, self.BaseId, get_uval=uval
                self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
            endif
        endif
    end
    'click': begin 
        if (conbase_uval.new_image eq 0) then begin
            ; redraw the box if it exists 
            if (pmode[0].type eq 'pan') then begin
                if (size(pmode, /n_elements) gt 1) then begin
                    case pmode[1].pointingmode of
                        'box':  begin 
                            if (pmode[1].type ne 'zbox') then begin
                                if (uval.box_pres) then begin
                                    self->DrawBoxParams
                                    ; get the uval again
                                    widget_control, self.BaseId, get_uval=uval
                                    self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                                endif
                            endif else begin
                                if (size(pmode, /n_elements) gt 2) then begin
                                    if (pmode[2].pointingmode eq 'box') then begin
                                        if (uval.box_pres) then begin
                                            self->DrawBoxParams
                                            ; get the uval again
                                            widget_control, self.BaseId, get_uval=uval
                                            self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1
                                        endif
                                    endif
                                endif
                            endelse
                        end
                        'aperture': begin
                            if ((pmode[1].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                                self->DrawCircleParams, circ_type='strehl'
                                widget_control, self.BaseId, get_uval=uval
                                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='strehl'
                            endif
                            if ((pmode[1].type eq 'phot') and (uval.circ_phot_pres)) then begin
                                self->DrawCircleParams, circ_type='phot'
                                widget_control, self.BaseId, get_uval=uval
                                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='phot'
                            endif
;                            if ((uval.circ_strehl_pres) or (uval.circ_phot_pres)) then begin
;                                self->DrawCircleParams
;                                ; get the uval again
;                                widget_control, self.BaseId, get_uval=uval
;                                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y
;                            endif
                        end     
                        'diag': begin
                            ; if this is not opening a new image, then
                            if (conbase_uval.new_image eq 0) then begin
                                self->DrawDiagonalBoxParams
                                ; get the uval again
                                widget_control, self.BaseId, get_uval=uval
                                if (uval.diag_pres) then begin
                                    self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
                                endif
                            endif
                        end
                        else:
                    endcase
                endif
            endif
        endif
    end
    'aperture': begin 
        ; if this is not opening a new image, then
        if (conbase_uval.new_image eq 0) then begin
            if ((pmode[0].type eq 'strehl') and (uval.circ_strehl_pres)) then begin
                self->DrawCircleParams, circ_type='strehl'
                widget_control, self.BaseId, get_uval=uval
                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='strehl'
            endif
            if ((pmode[0].type eq 'phot') and (uval.circ_phot_pres)) then begin
                self->DrawCircleParams, circ_type='phot'
                widget_control, self.BaseId, get_uval=uval
                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y, circ_type='phot'
            endif
;            if ((uval.circ_strehl_pres) or (uval.circ_phot_pres)) then begin 
;                self->DrawCircleParams
                ; get the uval again
;                widget_control, self.BaseId, get_uval=uval
;                self->DrawCircle, uval.draw_circ_x, uval.draw_circ_y
;            endif
        endif
    end
    'diag': begin 
        ; if this is not opening a new image, then
        if (conbase_uval.new_image eq 0) then begin
            self->DrawDiagonalBoxParams
            ; get the uval again
            widget_control, self.BaseId, get_uval=uval
            if (uval.diag_pres) then begin
                self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1
            endif
        endif
    end
    else: begin
    end
endcase

zbox_pos=-1
box_pos=where(pmode.pointingmode[*] eq 'box')
phot_pos=where(pmode.type[*] eq 'phot')
strehl_pos=where(pmode.type[*] eq 'strehl')
diag_pos=where(pmode.pointingmode[*] eq 'diag')

if (box_pos[0] ne -1) then begin
    if ((size(box_pos, /n_elements)) eq 1) then begin
        zbox_pos=where(pmode.type[box_pos] eq 'zbox')
    endif
endif

; if there is only one box mode and that happens to be zbox
; then you want to remove the box parameters from the uval
if ((box_pos[0] eq -1) or (zbox_pos[0] ne -1)) then begin
    ; remove the box parameters from the uval
    uval.box_p0=[0,0]
    uval.box_p1=[0,0]
    uval.draw_box_p0=[0,0]
    uval.draw_box_p1=[0,0]
    uval.box_pres=0
    widget_control, self.BaseId, set_uval=uval
endif

if (phot_pos[0] eq -1) then begin
    ; remove the photometry pointing mode
    uval.phot_circ_x=0
    uval.phot_circ_y=0
    uval.circ_phot_pres=0
    widget_control, self.BaseId, set_uval=uval
endif

if (strehl_pos[0] eq -1) then begin
    ; remove the strehl pointing mode
    uval.strehl_circ_x=0
    uval.strehl_circ_y=0
    uval.circ_strehl_pres=0
    widget_control, self.BaseId, set_uval=uval
endif

if (diag_pos[0] eq -1) then begin
    ; remove the diagonal box parameters from the uval
    uval.diagonal_box_p0=[0,0]
    uval.diagonal_box_p1=[0,0]
    uval.draw_diagonal_box_p0=[0,0]
    uval.draw_diagonal_box_p1=[0,0]
    uval.diag_pres=0
    widget_control, self.BaseId, set_uval=uval
endif

end

pro CImWin::FitsHedit, base_id

widget_control, base_id, get_uval=winbase_uval

; check to see if the editor exists
cfitshedit_obj=*(self.p_FitsHeditObj)
cfitshedit_obj->EditHeader, base_id

end

pro CImWin::MakeMovie, base_id

widget_control, base_id, get_uval=base_uval
widget_control, self.parentbaseid, get_uval=conbase_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr

; change the extension to .gif
path_filename=ImObj->GetPathFilename()
; find last '.'
dot_number = STRPOS(path_filename, '.', /REVERSE_SEARCH)
; if there is a dot
if dot_number ne -1 then begin
    ; get everything before it
    new_string=STRMID(path_filename, 0, dot_number)
    fname=new_string+'.gif' 
; otherwise return the current directory
endif else begin
    cd, '.', current=cur
    fname=cur+'/file.gif'
endelse

; find out how many channels there are in the Z direction
im_zs=ImObj->GetZS()
if (im_zs gt 1) then begin
    im_xs=ImObj->GetXS()
    im_ys=ImObj->GetYS()
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]
    ; make the chanstop eq the maximum in z
    self->SetMovieChanStop, im_s[2]-1
    ; make the binstep eq to num channels/100
    binstep=(im_s[2]-1)/100
    self->SetMovieBinStep, binstep
endif else begin
    message='Movies can onld be made with 3 dimensional images.'
    answer=dialog_message(message, dialog_parent=event.top, /error)
    return
endelse

; set up widgets
base=widget_base(TITLE = 'Make Movie', group_leader=base_id, /col, $
                   /tlb_kill_request_events)
moviebase=widget_base(base, /col, /base_align_right)
filename=widget_label(moviebase, value = ('Filename: '+ImObj->GetFilename()))
fileoutbase=widget_base(moviebase, /col, frame=2)
outbase=widget_base(fileoutbase, /row, ypad=0)
output_filename_box=cw_field(outbase, title='Output Fileame:', value=fname, xsize=50)
output_filename_button=widget_button(outbase, value='Choose path')

info = widget_info(filename, /geometry)
xs = info.xsize
ys = info.ysize

info=widget_info(moviebase, /geometry)
height=info.ysize
yoff=height + ys 

; Channel Start Position
chanstarbase=widget_base(moviebase, /row)
chanstarlabel=widget_label(chanstarbase, yoff = yoff, value = 'Channel Start (pixel):')
chanstartext=widget_text(chanstarbase, xoff = 220, yoff = yoff - 3, $
                       value = strtrim(self.movie_chan_start,2), xsize = 10, $
                       /editable)
; Channel Stop Position
chanstopbase=widget_base(moviebase, /row)
chanstoplabel=widget_label(chanstopbase, yoff = yoff + 50, value = 'Channel Stop (pixel):')
chanstoptext=widget_text(chanstopbase, xoff = 220, yoff = yoff + 47, $
                        value = strtrim(self.movie_chan_stop,2), xsize = 10, $
                        /editable)
; Magnification
magbase=widget_base(moviebase, /row)
maglabel=widget_label(magbase, yoff = yoff $
                          + 100, value = 'Magnification:')
magtext=widget_text(magbase, xoff = 220, yoff = yoff + 97, $
                        value = strtrim(self.movie_mag,2), xsize=10,$
                        /editable)

; Spatial Bin Size in X direction
xspatbinbase=widget_base(moviebase, /row)
xspatbinlabel=widget_label(xspatbinbase, yoff = yoff $
                          + 100, value = 'Spatial X Bin:')
xspatbintext=widget_text(xspatbinbase, xoff = 220, yoff = yoff + 97, $
                        value = strtrim(self.movie_xspat_bin,2), xsize=10,$
                        /editable)

; Spatial Bin Size in Y direction
yspatbinbase=widget_base(moviebase, /row)
yspatbinlabel=widget_label(yspatbinbase, yoff = yoff $
                          + 100, value = 'Spatial Y Bin:')
yspatbintext=widget_text(yspatbinbase, xoff = 220, yoff = yoff + 97, $
                        value = strtrim(self.movie_yspat_bin,2), xsize=10,$
                        /editable)

; Binsize
binsizebase=widget_base(moviebase, /row)
binsizelabel=widget_label(binsizebase, yoff = yoff $
                          + 100, value = 'Z Bin Size:')
binsizetext=widget_text(binsizebase, xoff = 220, yoff = yoff + 97, $
                        value = strtrim(self.movie_bin_size,2), xsize=10,$
                        /editable)

; Binstep
binstepbase=widget_base(moviebase, /row)
binsteplabel=widget_label(binstepbase, yoff = yoff $
                          + 150, value = 'Z Bin Step:')
binsteptext=widget_text(binstepbase, xoff = 220, yoff = yoff + 147, $
                        value = strtrim(self.movie_bin_step,2), xsize=10,$
                        /editable)
; Minval
minvalbase=widget_base(moviebase, /row)
minvallabel=widget_label(minvalbase, yoff = yoff $
                         + 200, value = 'Minimum Value:')
minvaltext=widget_text(minvalbase, xoff = 220, yoff = yoff + 197, $
                       value = strtrim(self.movie_min_value,2), xsize = 10, $
                       /editable)
; Maxval
maxvalbase=widget_base(moviebase, /row)
maxvallabel=widget_label(maxvalbase, yoff = yoff $
                         + 200, value = 'Maximum Value:')
maxvaltext=widget_text(maxvalbase, xoff = 220, yoff = yoff + 197, $
                       value = strtrim(self.movie_max_value,2), xsize = 10, $
                       /editable)

; Normalize
normbase=widget_base(moviebase, /row)
normalize=cw_bgroup(normbase,['No','Yes'], set_value=1, /return_name,$
/exclusive, /row, label_left='Normalize:')

; Smooth type
medavgbase=widget_base(moviebase, /row)
medavg=cw_bgroup(medavgbase,['Median','Average'], set_value=1, /return_name,$
/exclusive, /row, label_left='Smooth type:')

; Smooth with nearest neighbors
mednnbase=widget_base(moviebase, /row)
mednn=cw_bgroup(mednnbase,['No','Yes'], set_value=1, /return_name,$
/exclusive, /row, label_left='Smooth Nearest Neighbors:')

; .gif or .mpg?
typebase=widget_base(moviebase, /row)
filetype=cw_bgroup(typebase,['MPEG','GIF'], set_value=1, /return_name,$
/exclusive, /row, label_left='File type:')

; Close and Create buttons
buttonbase=widget_base(base, /row, /align_center)
closebutton=widget_button(buttonbase, value = 'Close')
createbutton=widget_button(buttonbase, value = 'Create Movie')

; set uval
wids = {base_id:base_id, $
        chanstar_id:chanstartext, $
        chanstop_id:chanstoptext, $
        mag_id:magtext, $
        xspatbin_id:xspatbintext, $
        yspatbin_id:yspatbintext, $
        binsize_id:binsizetext, $
        binstep_id:binsteptext, $
        minval_id:minvaltext, $
        maxval_id:maxvaltext, $ 
        norm_id:normalize, $
        smooth_id:medavg, $
        mednn_id:mednn, $
        filetype_id:filetype, $
        output_filename_id:output_filename_box $
	}

uval={base_id:base_id, $
      wids:wids $
     }

; realize widget
widget_control, base, /realize, set_uvalue=uval

; register the statistics events with xmanager
xmanager, 'CImWin_Makemovie_Base', base, /just_reg, /no_block, $
    cleanup='ql_subbase_death'
xmanager, 'CImWin_Makemovie_Parameters', chanstartext, /just_reg  , /no_block
xmanager, 'CImWin_Makemovie_Parameters', chanstoptext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', magtext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', xspatbintext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', yspatbintext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', binsizetext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', binsteptext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', minvaltext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Parameters', maxvaltext, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Button', closebutton, /just_reg, /no_block
xmanager, 'CImWin_Makemovie_Button', createbutton, /just_reg, /no_block

; register existence of base
base_uval.exist.movie=base
widget_control, base_id, set_uval=base_uval

end

pro CImWin::CreateMovie

widget_control, self.BaseId, get_uval=uval
widget_control, self.parentbaseid, get_uval=conbase_uval
widget_control, uval.exist.movie, get_uval=movie_uval

; get image object and data
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
imdata=*im_ptr

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()

; find out how many channels there are in the Z direction
if (im_zs gt 1) then begin
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]
endif else begin
    message='Movies can only be made with 3 dimensional images.'
    answer=dialog_message(message, dialog_parent=event.top, /error)
    return
endelse

; transpose image
im=transpose(imdata, self.AxesOrder[0:self.NAxis-1])
; truncate the z size to the parameters set for channel start and
; channel stop
im=im[*,*,self.movie_chan_start:self.movie_chan_stop]
; get the dimensions of the final cube
im_s=size(im, /Dimensions)

cubefits=ImObj->GetPathFilename()

; median the pixel values with the nearest neighbors
med_cube=fltarr(im_s[0],im_s[1],im_s[2])
med_cube=im
widget_control, movie_uval.wids.mednn_id, get_value=mednn_val
if (mednn_val) then begin
    for i = 1, im_s[0]-2 do begin
        for j = 1, im_s[1]-2 do begin
            for k = 1, im_s[2]-2 do begin
                near_neighbors = [im[i-1,j,k],im[i+1,j,k],im[i,j-1,k],$
                                  im[i,j+1,k],im[i,j,k-1],im[i,j,k+1]]
                med_cube[i,j,k] = median(near_neighbors)
            endfor 
        endfor 
    endfor 
endif

; normalize the data if set
widget_control, movie_uval.wids.norm_id, get_value=norm_val
if (norm_val eq 1) then begin 
    for z=0,im_s[2]-1 do begin
        c=max(med_cube[*,*,z])
        med_cube[*,*,z] = med_cube[*,*,z]/c
    endfor	
endif 

; calculate the # of binsteps
; med_cube=im[*,*,self.movie_chan_start:self.movie_chan_stop]
xbin=im_s[0]/float(self.movie_xspat_bin)
ybin=im_s[1]/float(self.movie_yspat_bin)
zbin=im_s[2]/float(self.movie_bin_step)
cnt=0.
kmed=0.

; smooth the data
widget_control, movie_uval.wids.smooth_id, get_value=smooth_val
if (smooth_val) then begin
    ; average the cube
    sm_cube=smooth(med_cube,[self.movie_xspat_bin,self.movie_yspat_bin,self.movie_bin_size], /edge_truncate)
endif else begin
    ; median the cube
    sm_cube=med_cube
    z_sz=(self.movie_chan_stop-self.movie_chan_start)
    tmparr=fltarr(z_sz)
    ; smooth in the z direction
    for i=0,im_s[0]-1 do begin
        for j=0,im_s[1]-1 do begin
            tmparr=reform(med_cube[i,j,*])
            sm_cube[i,j,*]=median(tmparr,[self.movie_bin_size])    
        endfor
    endfor
    for k=0,im_s[2]-1 do begin
        ; smooth in the x direction
        tmp_slice=reform(sm_cube[*,*,k])
        if ((self.movie_xspat_bin gt 1) and (self.movie_xspat_bin lt im_s[1])) then begin
            for j=0,im_s[1]-1 do begin
                tmp_line=reform(tmp_slice[*,j])
                sm_cube[*,j,k]=median(tmp_line,[self.movie_xspat_bin])
            endfor
        endif
        ; smooth in the y direction
        if ((self.movie_yspat_bin gt 1) and (self.movie_yspat_bin lt im_s[2])) then begin
            for i=0,im_s[0]-1 do begin
                tmp_column=reform(tmp_slice[i,*])
                sm_cube[i,*,k]=median(tmp_column,[self.movie_yspat_bin])
            endfor
        endif
    endfor
endelse

; normalize each slice if toggle is 1
movie_cube=sm_cube
for i=0,im_s[0]-1 do begin
    for j=0,im_s[1]-1 do begin
        while (kmed lt zbin) do begin
            movie_cube[*,*,cnt]=sm_cube[*,*,kmed]
            ; increase cnt to the next slice position
            cnt=cnt+1.
            ; step k ahead to the next bin position
            kmed=kmed+self.movie_bin_step
        endwhile
    endfor
endfor

; apply the movie magnification
xmag=im_s[0]*self.movie_mag
ymag=im_s[1]*self.movie_mag

; find the size of movie_cube
newim_s=size(movie_cube, /Dimensions)
en_movie_cube=fltarr(xmag,ymag,newim_s[2])
for i=0,newim_s[0]-1 do begin
    for j=0,newim_s[1]-1 do begin
        for k=0,newim_s[2]-1 do begin
            en_movie_cube[(i*self.movie_mag):(((i+1)*self.movie_mag)-1),$
                   (j*self.movie_mag):(((j+1)*self.movie_mag)-1),k]=movie_cube[i,j,k]
        endfor
    endfor
endfor

s=size(en_movie_cube, /Dimensions)
xsize=s[0]
ysize=s[1]
zsize=s[2]

widget_control, movie_uval.wids.output_filename_id, get_value=objectname

; check to see if you have permission to write to this path
path=ql_getpath(objectname)
permission=ql_check_permission(path)    
if (permission eq 1) then begin
    ; check to see what filetype is selected
    widget_control, movie_uval.wids.filetype_id, get_value=filetype_val
    if (filetype_val) then begin
        ; write a .gif
        for k=0,cnt-1 do begin
            bytim=bytscl(en_movie_cube[*,*,k], max=self.movie_max_value, min=self.movie_min_value)
            write_gif, objectname, bytim, /multiple
        endfor
        write_gif, objectname, /close
    endif else begin
        ; write a .mpg
        mpegID = MPEG_Open([xsize, ysize], Filename=objectname)
        ; write a .mpg
        image24=bytArr(3, xsize, ysize)
        tvlct, r, g, b, /Get
        ; Load the frames.
        for k=0,cnt do begin
            bytim=bytscl(en_movie_cube[*,*,k], max=self.movie_max_value, min=self.movie_min_value)
            image24[0,*,*] = r(bytim[*,*])
            image24[1,*,*] = g(bytim[*,*])
            image24[2,*,*] = b(bytim[*,*])
            mpeg_put, mpegID, Image=image24, Frame=k
        endfor
        ; Save the MPEG sequence. Be patient this will take several seconds.
        MPEG_Save, mpegID
        ; Close the MPEG sequence and file.
        MPEG_Close, mpegID
    endelse
endif else begin
    err=dialog_message(['Error writing movie.', 'Please check path and permissions.'],$
                       dialog_parent=base_id, /error)
endelse

end

pro CImWin::ReopenImage

; get window uval
widget_control, self.BaseId, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

; get the image data
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
im=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*(hd_ptr)

; sets the scale back to full collapsed range
self.ResetZ=1
self.DoAutoScale=1

im_zs=ImObj->GetZS()

if (im_zs le 1) then begin
    ; sets the axis back to the original order
    self->UpdateImParam, self.p_ImObj
endif else begin
    ; if the image is a cube, then open with the 2nd axis vs. the 3rd axis
    axesorder=[2,1,0]
    self->SetNAxis, 3
    self->SetAxesOrder, axesorder
    widget_control, uval.wids.xdim_list, set_droplist_select=axesorder[0]
    widget_control, uval.wids.ydim_list, set_droplist_select=axesorder[1]
    widget_control, uval.wids.cube_base, sensitive=1
    self->UpdateZooms
endelse

; resets the display scale
;self.DispScale='linear'

widget_control, self.BaseId, set_uval=uval

; check the config file to see if we're supposed to display as
; DN/s or Total DN

; MDP modified the following to remove lots of redundancy.
; "datanum_val" is what gets displayed to label the mouseover counts
if has_valid_cconfigs(conbase_uval, cconfigs) then begin
   des=cconfigs->GetDisplayAsDN()
   cfgname=cconfigs->GetCfgName()
   if (stregex(cfgname, 'OSIRIS') gt -1) then begin
     instr='OSIRIS'
   endif else begin
     if (hd[0] ne '') then begin
       instr=strtrim(sxpar(hd,'CURRINST'),2)
     endif
   endelse
   if (instr eq 'OSIRIS') or (instr eq 'NIRC2') then begin
     case des of
       'As DN/s': datanum_val='DN/s'
       'As Total DN': datanum_val='DN'
     else: datanum_val=''
     endcase
   endif else begin
     datanum_val=''
   endelse  
endif else begin
  des=['As DN/s'] ; default 
  datanum_val=''
endelse

if ((des ne 'As Total DN') and (des ne 'As DN/s')) then begin
    des=['As DN/s']
    datanum_val=''
endif

if (des eq 'As DN/s') then begin
    self->SetCurrentDisplay, 'As DN/s'
    ; update the units tag
    widget_control, uval.wids.datanum, set_value=datanum_val
endif else begin
    self->SetCurrentDisplay, 'As Total DN'
    ; update the units tag
    widget_control, uval.wids.datanum, set_value=datanum_val
endelse

; reopens the image
self->UpdateDispIm
self->DrawImage
end

pro CImWin::DisplayAsDN, no_rescale=no_rescale
	widget_control, self.BaseId, get_uval=cimwin_uval
	widget_control, self.ParentBaseId, get_uval=conbase_uval

	; find out the integration time
	ImObj_ptr=self.p_ImObj
	ImObj=*ImObj_ptr
	hd_ptr=ImObj->GetHeader()
	hd=*hd_ptr

	; get the itime and coadds keywords from the config file, if possible
	if has_valid_cconfigs(conbase_uval, cconfigs) then begin
	    itime_kw=cconfigs->GetItimeFitskw()
	    coadds_kw=cconfigs->GetCoaddsFitskw()
         endif else begin
            print, 'no valid config, using defaults for itime_kw and coadds_kw'            
	    itime_kw='TRUITIME' ; default
	    coadds_kw='COADDS'
	endelse

	itime=sxpar(hd, itime_kw, count=itime_count)
	coadds=sxpar(hd, coadds_kw, count=coadd_count)
	if itime_count eq 0 then begin
	    message=['ERROR: Could not find the coadds keyword.', $
                     'No manipulation of the data']
            ;; commented this out so that it can display images of
            ;; individual reads which do not have headers. 
            ;;answer=dialog_message(message, dialog_parent=self.BaseId, /error)

            ;; instead, print out to the terminal
            print, message
	endif
	if coadd_count eq 0 then begin
	    message=['ERROR Could not find the integration time keyword.', $
                     'No manipulation of the data']
            ;; commented this out so that it can display images of
            ;; individual reads which do not have headers. 
            
            ;; answer = dialog_message(message, dialog_parent = self.BaseId, /error)
            print, message
	endif

	print, "Integration time was ", itime
	; multiply the displayed im by the integration time
	im=*self.p_DispIm

        ; Are we updating? i.e. are we switching from DN/s to Total DN or vice versa?
        ; jlyke 2019 July 29 Unsure why all the cases--each one appears identical
        ; as a hedge, add a use_original_method varable and place in an if block
      use_original_method = 0 ; do not use original method
      if (use_original_method eq 1 ) then begin
        if (self.current_display_update) then begin
		print, "Converting data to format = "+self.current_display
		instr=sxpar(hd,'CURRINST', count=instr_count)
		case self.current_display of
	    'As Total DN': begin
			if instr_count ne 0 then begin
		    case strtrim(instr,2) of
			'OSIRIS': begin
				widget_control, cimwin_uval.wids.datanum, set_value='DN'
				im=im*itime*coadds
				*self.p_DispIm=im
				if (cimwin_uval.current_display_skip ne 0) then begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endif
			end
			'NIRC2': begin
				if (cimwin_uval.current_display_skip eq 0) then begin
				    widget_control, cimwin_uval.wids.datanum, set_value='DN'
				    im=im*itime*coadds
				    *self.p_DispIm=im
				endif else begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endelse
			end
			else: begin ; unknown INSTR keyword
				widget_control, cimwin_uval.wids.datanum, set_value=' '
				im=im*itime*coadds
				*self.p_DispIm=im
				if (cimwin_uval.current_display_skip ne 0) then begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endif
			end
		    endcase                    
		endif else begin ; no INSTR keyword present
		    ; assume the calculations are like OSIRIS
			widget_control, cimwin_uval.wids.datanum, set_value=' '
			im=im*itime*coadds
			*self.p_DispIm=im
			if (cimwin_uval.current_display_skip ne 0) then begin
			    cimwin_uval.current_display_skip=0
			    widget_control, self.BaseId, set_uval=cimwin_uval
			endif
		endelse
			self.dispmin =  self.dispmin*itime*coadds
			self.dispmax =  self.dispmax*itime*coadds
	    end
	    'As DN/s': begin
			if instr_count ne 0 then begin
		    case strtrim(instr,2) of
			'OSIRIS': begin
				if (cimwin_uval.current_display_skip eq 0) then begin
				    widget_control, cimwin_uval.wids.datanum, set_value='DN/s'
				    im=im/(itime*coadds)
				    *self.p_DispIm=im
				endif else begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endelse
			end
			'NIRC2': begin
				widget_control, cimwin_uval.wids.datanum, set_value='DN/s'
				im=im/(itime*coadds)
				*self.p_DispIm=im
				if (cimwin_uval.current_display_skip ne 0) then begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endif
			end
			else: begin ; unknown INSTR keyword
				if (cimwin_uval.current_display_skip eq 0) then begin
				    widget_control, cimwin_uval.wids.datanum, set_value='  '
				    im=im/(itime*coadds)
				    *self.p_DispIm=im
				endif else begin
				    cimwin_uval.current_display_skip=0
				    widget_control, self.BaseId, set_uval=cimwin_uval
				endelse
			end
		    endcase                    
		endif else begin ; no INSTR keyword present
		    ; assume the calculations are like OSIRIS
			if (cimwin_uval.current_display_skip eq 0) then begin
			    widget_control, cimwin_uval.wids.datanum, set_value='  '
			    im=im/(itime*coadds)
			    *self.p_DispIm=im
			endif else begin
			    cimwin_uval.current_display_skip=0
			    widget_control, self.BaseId, set_uval=cimwin_uval
			endelse
		endelse
			self.dispmin =  self.dispmin/(itime*coadds)
			self.dispmax =  self.dispmax/(itime*coadds)
	    end
	    else:
		endcase
		self.current_display_update=0
		 self.DoAutoScale=0
	    self->UpdateText
	endif else begin

		if NOT keyword_set(no_rescale) then begin
		
		; scales the image by computing the mean and scales the
		; min and max values according to the standard deviation
		; don't count the NaN values
		; use the cconfigs values for the scale max and min, if possible
		
			if has_valid_cconfigs(conbase_uval, cconfigs) then begin
			im_max_con=cconfigs->GetImScaleMaxCon()
			im_min_con=cconfigs->GetImScaleMinCon()
		    endif else begin
				im_max_con=5. ; defaults
			im_min_con=-3.
			endelse
		    meanval=moment(*self.p_DispIm, sdev=im_std, /NAN)
		    self.DispMax=meanval[0]+im_max_con*im_std
		    self.DispMin=meanval[0]+im_min_con*im_std
		    self.DoAutoScale=0
		    self->UpdateText
		endif
             endelse
        ;print, 'Using ORIGINAL method'

     endif else begin
        if (self.current_display_update) then begin
	  print, "Converting data to format = "+self.current_display
          case self.current_display of
	    'As Total DN': begin
		widget_control, cimwin_uval.wids.datanum, set_value='DN'
		im=im*itime*coadds
		*self.p_DispIm=im
		if (cimwin_uval.current_display_skip ne 0) then begin
		  cimwin_uval.current_display_skip=0
		  widget_control, self.BaseId, set_uval=cimwin_uval
		endif
		self.dispmin =  self.dispmin*itime*coadds
		self.dispmax =  self.dispmax*itime*coadds
	    end
	    'As DN/s': begin
		widget_control, cimwin_uval.wids.datanum, set_value='DN/s'
		im=im/(itime*coadds)
		*self.p_DispIm=im
		if (cimwin_uval.current_display_skip ne 0) then begin
		  cimwin_uval.current_display_skip=0
		  widget_control, self.BaseId, set_uval=cimwin_uval
		endif
		self.dispmin =  self.dispmin/(itime*coadds)
                self.dispmax =  self.dispmax/(itime*coadds)
             end
             else:
	endcase
	self.current_display_update=0
	self.DoAutoScale=0
	self->UpdateText
	endif else begin
          if NOT keyword_set(no_rescale) then begin
		
	    ; scales the image by computing the mean and scales the
	    ; min and max values according to the standard deviation
	    ; don't count the NaN values
	    ; use the cconfigs values for the scale max and min, if possible
		
	    if has_valid_cconfigs(conbase_uval, cconfigs) then begin
		im_max_con=cconfigs->GetImScaleMaxCon()
		im_min_con=cconfigs->GetImScaleMinCon()
	    endif else begin
		im_max_con=5. ; defaults
		im_min_con=-3.
	    endelse
            meanval=moment(*self.p_DispIm, sdev=im_std, /NAN)
	    self.DispMax=meanval[0]+im_max_con*im_std
            self.DispMin=meanval[0]+im_min_con*im_std
            self.DoAutoScale=0
            self->UpdateText
	  endif
       endelse
        ;print, 'Using NEW method'
      endelse ; use_original_method

 
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
; figure out how much information can fit into these fields
; Fix XScale
if (self.XScale lt 1e-9) then begin
    xscale=sigfig(self.XScale, 1, /scientific)
    widget_control, base_uval.wids.zoom_xscl, set_value=xscale[0]
endif
if ((self.XScale ge 1e-9) and (self.XScale lt 1e-3)) then begin
    xscale=sigfig(self.XScale, 2, /scientific)
    widget_control, base_uval.wids.zoom_xscl, set_value=xscale[0]
endif
if ((self.XScale ge 1e-3) and (self.XScale lt 1.)) then begin
    xscale=sigfig(self.XScale, 3)
    widget_control, base_uval.wids.zoom_xscl, set_value=xscale[0]
endif
if ((self.XScale ge 1.) and (self.XScale lt 1000.)) then begin
    xscale=sigfig(self.XScale, 5)
    widget_control, base_uval.wids.zoom_xscl, set_value=xscale[0]
endif
if (self.XScale ge 1000.) then begin
    xscale=sigfig(self.XScale, 2, /scientific)
    widget_control, base_uval.wids.zoom_xscl, set_value=xscale[0]
endif

; Fix YScale
if (self.YScale lt 1e-9) then begin
    yscale=sigfig(self.YScale, 1, /scientific)
    widget_control, base_uval.wids.zoom_yscl, set_value=yscale[0]
endif
if ((self.YScale ge 1e-9) and (self.YScale lt 1e-3)) then begin
    yscale=sigfig(self.YScale, 2, /scientific)
    widget_control, base_uval.wids.zoom_yscl, set_value=yscale[0]
endif
if ((self.YScale ge 1e-3) and (self.YScale lt 1.)) then begin
    yscale=sigfig(self.YScale, 3)
    widget_control, base_uval.wids.zoom_yscl, set_value=yscale[0]
endif
if ((self.YScale ge 1.) and (self.YScale lt 1000.)) then begin
    yscale=sigfig(self.YScale, 5)
    widget_control, base_uval.wids.zoom_yscl, set_value=yscale[0]
endif
if (self.YScale ge 1000.) then begin
    yscale=sigfig(self.YScale, 2, /scientific)
    widget_control, base_uval.wids.zoom_yscl, set_value=yscale[0]
endif

; Fix DispMin
; negative
if (self.DispMin le -10000.) then begin
    dispmin=sigfig(self.DispMin, 3, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin le -1.) and (self.DispMin gt -10000.)) then begin
    dispmin=sigfig(self.DispMin, 5)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin le -1e-3) and (self.DispMin gt -1.)) then begin
    dispmin=sigfig(self.DispMin, 3)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif 
if ((self.DispMin le -1e-9) and (self.DispMin gt -1e-3)) then begin
    dispmin=sigfig(self.DispMin, 2, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin le 0) and (self.DispMin gt -1e-9)) then begin
    dispmin=sigfig(self.DispMin, 1, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif

; positive
if ((self.DispMin lt 1e-9) and (self.DispMin gt 0)) then begin
    dispmin=sigfig(self.DispMin, 1, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin ge 1e-9) and (self.DispMin lt 1e-3)) then begin
    dispmin=sigfig(self.DispMin, 2, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin ge 1e-3) and (self.DispMin lt 1.)) then begin
    dispmin=sigfig(self.DispMin, 3)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if ((self.DispMin ge 1.) and (self.DispMin lt 10000.)) then begin
    dispmin=sigfig(self.DispMin, 5)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif
if (self.DispMin ge 10000.) then begin
    dispmin=sigfig(self.DispMin, 3, /scientific)
    widget_control, base_uval.wids.stretch_min, set_value=dispmin[0]
endif

; Fix DispMax
; negative
if (self.Dispmax le -1000.) then begin
    dispmax=sigfig(self.Dispmax, 3, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.Dispmax le -1.) and (self.Dispmax gt -10000.)) then begin
    dispmax=sigfig(self.Dispmax, 6)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.Dispmax le -1e-3) and (self.Dispmax gt -1.)) then begin
    dispmax=sigfig(self.Dispmax, 4)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.Dispmax le -1e-9) and (self.Dispmax gt -1e-3)) then begin
    dispmax=sigfig(self.Dispmax, 4, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.Dispmax le 0) and (self.Dispmax gt -1e-9)) then begin
    dispmax=sigfig(self.Dispmax, 4, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif

if ((self.DispMax lt 1e-9) and (self.DispMax gt 0)) then begin
    dispmax=sigfig(self.DispMax, 1, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.DispMax ge 1e-9) and (self.DispMax lt 1e-3)) then begin
    dispmax=sigfig(self.DispMax, 2, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.DispMax ge 1e-3) and (self.DispMax lt 1.)) then begin
    dispmax=sigfig(self.DispMax, 3)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if ((self.DispMax ge 1.) and (self.DispMax lt 10000.)) then begin
    dispmax=sigfig(self.DispMax, 5)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif
if (self.DispMax ge 10000.) then begin
    dispmax=sigfig(self.DispMax, 3, /scientific)
    widget_control, base_uval.wids.stretch_max, set_value=dispmax[0]
endif

end

pro CImWin::RemoveBox

self->DrawBoxParams
widget_control, self.BaseId, get_uval=uval
self->Draw_Box, uval.draw_box_p0, uval.draw_box_p1

end

pro CImWin::RemoveDiagonalBox

widget_control, self.BaseId, get_uval=uval
self->Draw_Diagonal_Box, uval.draw_diagonal_box_p0, uval.draw_diagonal_box_p1

end

pro CImWin::DrawBoxParams

widget_control, self.BaseId, get_uval=uval

; get box corners in pixels
new_x0=(uval.box_p0[0] < uval.box_p1[0])
new_x1=(uval.box_p0[0] > uval.box_p1[0])
new_y0=(uval.box_p0[1] < uval.box_p1[1])
new_y1=(uval.box_p0[1] > uval.box_p1[1])

; get dimensions of window
win_xs=self.xs
win_ys=self.ys

fin_x0=floor(win_xs/2.+(new_x0-uval.tv_p0[0])*self.XScale)
fin_x1=floor(win_xs/2.+(new_x1-uval.tv_p0[0]+1)*self.XScale)
fin_y0=floor(win_ys/2.+(new_y0-uval.tv_p0[1])*self.YScale)
fin_y1=floor(win_ys/2.+(new_y1-uval.tv_p0[1]+1)*self.YScale)

uval.draw_box_p0=[fin_x0, fin_y0]
uval.draw_box_p1=[fin_x1, fin_y1]

widget_control, self.BaseId, set_uval=uval

end 

pro CImWin::RemoveCompass

self->DrawCompassParams
widget_control, self.BaseId, get_uval=uval
self->Draw_Compass

end

pro CImWin::DrawCompassParams

widget_control, self.BaseId, get_uval=uval

; get box corners in pixels
new_x0=(uval.box_p0[0] < uval.box_p1[0])
new_x1=(uval.box_p0[0] > uval.box_p1[0])
new_y0=(uval.box_p0[1] < uval.box_p1[1])
new_y1=(uval.box_p0[1] > uval.box_p1[1])

; get dimensions of window
win_xs=self.xs
win_ys=self.ys

fin_x0=floor(win_xs/2.+(new_x0-uval.tv_p0[0])*self.XScale)
fin_x1=floor(win_xs/2.+(new_x1-uval.tv_p0[0]+1)*self.XScale)
fin_y0=floor(win_ys/2.+(new_y0-uval.tv_p0[1])*self.YScale)
fin_y1=floor(win_ys/2.+(new_y1-uval.tv_p0[1]+1)*self.YScale)

uval.draw_box_p0=[fin_x0, fin_y0]
uval.draw_box_p1=[fin_x1, fin_y1]

widget_control, self.BaseId, set_uval=uval

end 

pro CImWin::Draw_Compass, x, y
; draw a box in window to select a region

; get uval
widget_control, self.BaseId, get_uval=base_uval

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

widget_control, self.BaseId, set_uval=base_uval

end

pro CImWin::DrawDiagonalBoxParams

widget_control, self.BaseId, get_uval=uval

; get diagonal box corners in pixels
new_x0=uval.diagonal_box_p0[0]
new_y0=uval.diagonal_box_p0[1]
new_x1=uval.diagonal_box_p1[0]
new_y1=uval.diagonal_box_p1[1]

; get dimensions of window
win_xs=self.xs
win_ys=self.ys

fin_x0=floor(win_xs/2.+(new_x0-uval.tv_p0[0])*self.XScale)
fin_x1=floor(win_xs/2.+(new_x1-uval.tv_p0[0]+1)*self.XScale)
fin_y0=floor(win_ys/2.+(new_y0-uval.tv_p0[1])*self.YScale)
fin_y1=floor(win_ys/2.+(new_y1-uval.tv_p0[1]+1)*self.YScale)

uval.draw_diagonal_box_p0=[fin_x0, fin_y0]
uval.draw_diagonal_box_p1=[fin_x1, fin_y1]

widget_control, self.BaseId, set_uval=uval

end 

pro CImWin::Draw_Box, point0, point1
; draw a box in window to select a region

; get uval
widget_control, self.BaseId, get_uval=base_uval

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

widget_control, self.BaseId, set_uval=base_uval

end

pro CImWin::Draw_Diagonal_Box, point0, point1
; draw a box in window to select a region

; get uval
widget_control, self.BaseId, get_uval=base_uval

; save current window for wsetting later
save=!D.WINDOW

; activate main window
wset, self.DrawIndex

; set mask to [1,1,1,1,1,...]
mask = !d.n_colors - 1

; get corners
x0=float(point0[0])
y0=float(point0[1])
x1=float(point1[0])
y1=float(point1[1])

; calculate the slope and int of the line
m=float((y1-y0)/(x1-x0))
theta=atan(m)
b=y0-(m*x0)

; convert the diagonal width to screen pixs
s_xwidth=self.dwidth*self.xscale
s_ywidth=self.dwidth*self.yscale

; if the slope is greater than one, draw the box making
; vertical cuts
if (abs(m) gt 1) then begin
; calculate the 4 pts of the box, starting at the bottom
; left and going clockwise
    d_box_x0=x0
    d_box_y0=y0-s_ywidth
    d_box_x1=x0
    d_box_y1=y0+s_ywidth
    d_box_x2=x1
    d_box_y2=y1+s_ywidth
    d_box_x3=x1
    d_box_y3=y1-s_ywidth
endif else begin
; if the slope is less than one, draw the box making
; horizontal cuts
    d_box_x0=x0-s_xwidth
    d_box_y0=y0
    d_box_x1=x0+s_xwidth
    d_box_y1=y0
    d_box_x2=x1+s_xwidth
    d_box_y2=y1
    d_box_x3=x1-s_xwidth
    d_box_y3=y1
endelse

; find the starting and ending pts for the two lines
; parallel to this one
dx=cos((!Pi/2)-theta)*(s_xwidth/2.)
dy=sin((!Pi/2)-theta)*(s_ywidth/2.)

; set graphics to xor type
device, get_graphics=oldg, set_graphics=base_uval.xor_type

; draw diagonal box
plots, [d_box_x0, d_box_x1, d_box_x2, d_box_x3, d_box_x0], $
        [d_box_y0, d_box_y1, d_box_y2, d_box_y3, d_box_y0], /device, color=mask

;reset graphics
device, set_graphics=oldg

; reset current window
wset, save

widget_control, self.BaseId, set_uval=base_uval

end

pro CImWin::RemoveCircle, circ_type=circ_type

widget_control, self.BaseId, get_uval=cimwin_uval
self->DrawCircle, cimwin_uval.draw_circ_x, cimwin_uval.draw_circ_y, circ_type=circ_type

end

pro CImWin::DrawCircleParams, circ_type=circ_type

widget_control, self.BaseId, get_uval=cimwin_uval
pmode=*cimwin_uval.pmode_ptr

; get dimensions of window
win_xs=self.xs
win_ys=self.ys


if keyword_set(circ_type) then begin
    des=circ_type
endif else begin
    des=pmode[0].type
endelse

case des of 
    'phot': begin
        cimwin_uval.draw_circ_x=floor(win_xs/2.+(cimwin_uval.phot_circ_x-cimwin_uval.tv_p0[0]+0.5)*self.XScale)
        cimwin_uval.draw_circ_y=floor(win_ys/2.+(cimwin_uval.phot_circ_y-cimwin_uval.tv_p0[1]+0.5)*self.YScale)
    end
    'strehl': begin
        cimwin_uval.draw_circ_x=floor(win_xs/2.+(cimwin_uval.strehl_circ_x-cimwin_uval.tv_p0[0]+0.5)*self.XScale)
        cimwin_uval.draw_circ_y=floor(win_ys/2.+(cimwin_uval.strehl_circ_y-cimwin_uval.tv_p0[1]+0.5)*self.YScale)
    end
    else:
endcase

widget_control, self.BaseId, set_uval=cimwin_uval

end 


pro CImWin::DrawCircle, xpos, ypos, circ_type=circ_type
; draw a box in window to select a region

; get uval
widget_control, self.BaseId, get_uval=winbase_uval
pmode=*winbase_uval.pmode_ptr

; save current window for wsetting later
save=!D.WINDOW

; activate main window
wset, self.DrawIndex

; set mask to [1,1,1,1,1,...]
if !d.n_colors gt 256 then mask = 250 else mask = !d.n_colors - 1

; set graphics to xor type
device, get_graphics=oldg, set_graphics=winbase_uval.xor_type

; draw the aperture

if keyword_set(circ_type) then begin
    des=circ_type
endif else begin
    des=pmode[0].type
endelse

case des of 
    'phot': begin
        if (self.XScale eq self.YScale) then begin
            ; draw the aperture
            size = float(self.photometry_aper)*self.XScale
            tvcircle, size, xpos, ypos, color=mask
            ; draw the inner annulus
            if (self.photometry_inner_an ne self.photometry_aper) then begin
                size = float(self.photometry_inner_an)*self.XScale
                tvcircle, size, xpos, ypos, color=mask, lines=0, thick=1
            endif
            ; draw the outer annulus
            if (self.photometry_outer_an ne self.photometry_inner_an) then begin
                size = float(self.photometry_outer_an)*self.XScale
                tvcircle, size, xpos, ypos, color=mask, lines=0, thick=1
            endif
        endif else begin
            if (self.YScale gt self.XScale) then pos_angle=90 else pos_angle=0
            xcen=winbase_uval.draw_circ_x
            ycen=winbase_uval.draw_circ_y
            ;draw the aperture
            xsize = float(self.photometry_aper)*self.XScale
            ysize = float(self.photometry_aper)*self.YScale

            if (ysize gt xsize) then begin
                rmax=ysize
                rmin=xsize
            endif else begin
                rmax=xsize
                rmin=ysize
            endelse
            tvellipse, rmax, rmin, xcen, ycen, pos_angle, color=mask

            ;draw the inner annulus
            if (self.photometry_inner_an ne self.photometry_aper) then begin
                xsize = float(self.photometry_inner_an)*self.XScale
                ysize = float(self.photometry_inner_an)*self.YScale

                if (ysize gt xsize) then begin
                    rmax=ysize
                    rmin=xsize
                endif else begin
                    rmax=xsize
                    rmin=ysize
                endelse
                tvellipse, rmax, rmin, xcen, ycen, pos_angle, color=mask
            endif
        
            ;draw the outer annulus
            if (self.photometry_outer_an ne self.photometry_inner_an) then begin
                xsize = float(self.photometry_outer_an)*self.XScale
                ysize = float(self.photometry_outer_an)*self.YScale
        
                if (ysize gt xsize) then begin
                    rmax=ysize
                    rmin=xsize
                endif else begin
                    rmax=xsize
                    rmin=ysize
                endelse
                tvellipse, rmax, rmin, xcen, ycen, pos_angle, color=mask
            endif
            
        endelse
    end
    'strehl': begin
        if (self.XScale eq self.YScale) then begin
            ; draw the aperture
            size = float(self.strehl_apsize)*self.XScale
            tvcircle, size, xpos, ypos, color=mask
        endif else begin
            if (self.YScale gt self.XScale) then pos_angle=90 else pos_angle=0
            xcen=winbase_uval.draw_circ_x
            ycen=winbase_uval.draw_circ_y
            ;draw the aperture
            xsize = float(self.strehl_apsize)*self.XScale
            ysize = float(self.strehl_apsize)*self.YScale

            if (ysize gt xsize) then begin
                rmax=ysize
                rmin=xsize
            endif else begin
                rmax=xsize
                rmin=ysize
            endelse
            tvellipse, rmax, rmin, xcen, ycen, pos_angle, color=mask            
        endelse
    end
    else:
endcase

;reset graphics
device, set_graphics=oldg

; reset current window
wset, save

end

pro CImWin::MakeWinActive, base_id

widget_control, base_id, get_uval=winbase_uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

;ql_make_window_active, self.ParentBaseId, winbase_uval.self_ptr

; make the current active window inactive
if ptr_valid(conbase_uval.p_curwin) then begin
    old_active_win_ptr=conbase_uval.p_curwin
    old_active_win=*old_active_win_ptr
    old_active_win->MakeInactive
endif

; make this window active
conbase_uval.p_curwin=winbase_uval.self_ptr

self->MakeActive

widget_control, self.ParentBaseId, set_uval=conbase_uval

end
pro CImWin::MakeWinInactive, base_id

widget_control, base_id, get_uval=winbase_uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

; make the current active window inactive
if ptr_valid(conbase_uval.p_curwin) then begin
    old_active_win_ptr=conbase_uval.p_curwin
    old_active_win=*old_active_win_ptr
    old_active_win->MakeInactive
endif

; remove the active window id from the conbase uval
conbase_uval.p_curwin=ptr_new()

widget_control, self.ParentBaseId, set_uval=conbase_uval

end

pro CImWin::SaveAs2d, base_id

if (self.naxis eq 3) then begin
    im=*(self.p_DispIm)
    ImObj_ptr=self.p_ImObj
    ImObj=*ImObj_ptr
    hd_ptr=ImObj->GetHeader()
    hd=*hd_ptr
    filename=ImObj->GetPathFilename()
endif else begin
    ImObj_ptr=self.p_ImObj
    ImObj=*ImObj_ptr
    im_ptr=ImObj->GetData()
    im=*im_ptr
    hd_ptr=ImObj->GetHeader()
    hd=*hd_ptr
    filename=ImObj->GetPathFilename()
endelse

; get new filename
file=dialog_pickfile(/write, group=base_id, filter='*.fits*', file=filename)

; if cancel was not hit
if file ne '' then begin
    ; check the permissions on the path
    path=ql_getpath(file)
    permission=ql_check_permission(path)    
    if (permission eq 1) then begin
        ; write the image to disk
        writefits, file, im, hd
        ; reset image filename
        ImObj->SetFilename, file
        ; update window title
        widget_control, base_id, tlb_set_title=file
    endif else begin
        err=dialog_message(['Error writing .fits file.', 'Please check path and permissions.'],$
                           dialog_parent=base_id, /error)
    endelse
endif

end

pro CImWin::SaveAs, base_id

ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
im=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr
filename=ImObj->GetPathFilename()

; get new filename
file=dialog_pickfile(/write, group=base_id, filter='*.fits*', file=filename)

; if cancel was not hit
if file ne '' then begin
    ; check the permissions on the path
    path=ql_getpath(file)
    permission=ql_check_permission(path)    
    if (permission eq 1) then begin
        ; write the image to disk
        writefits, file, im, hd
        ; reset image filename
        ImObj->SetFilename, file
        ; update window title
        widget_control, base_id, tlb_set_title=file
    endif else begin
        err=dialog_message(['Error writing .fits file.', 'Please check path and permissions.'],$
                           dialog_parent=base_id, /error)
    endelse
endif

end
;----------------------------------------------------------------------
; Added by Marshall Perrin, based on code from Dave Fanning's 
; XSTRETCH.PRO
pro CImWin::SaveToVariable, base_id,thingname

case thingname of
    "Image": thing=*self.p_DispIm
    "Cube":thing=*((*(self.p_ImObj))->GetData())
    "Header":thing=*((*(self.p_ImObj))->GetHeader())
endcase

if keyword_set(image) then begin
    thingname="Image"
    thing=*self.p_DispIm
endif
if keyword_set(header) then begin
    thingname="Header"
    thing=*((*(self.p_ImObj))->GetHeader())    
endif

cancelled=0.

varname=TextBox(Title='Provide Main-Level Variable Name...', Group_Leader=base_id, $
         Label=thingname+' Variable Name: ', Cancel=cancelled, XSize=200, Value=thingname) 

; Dave Fanning says:
;
;; The ROUTINE_NAMES function is not documented in IDL,
;; so it may not always work. This capability has been
;; tested in IDL versions 5.3 through 5.6 and found to work.
;; People with IDL 6.1 and higher should use SCOPE_VARFETCH to
;; set main-level variables. I use the older, undocumented version
;; to stay compatible with more users.

if not cancelled then begin
    dummy=Routine_Names(varname, thing, Store=1)
endif

end

pro CImWin::Print, base_id

cprint_ptr=self.p_PrintObj
p_PrintObj=*cprint_ptr

; gets the current directory
cd, '.', current=current_dir

; get uval
widget_control, base_id, get_uval=base_uval


cancelled=p_PrintObj->DeviceSetup()

if not cancelled then begin
    self->DrawImage, /PS
endif else begin
    return
endelse

printing=p_PrintObj->getPrintDes()
if printing then begin
     p_PrintObj->PS2Printer
     p_PrintObj->setPrintDes, 0
 endif

p_PrintObj->DeviceCleanup

end


pro CImWin::SetPrintDefaults, conbase_id

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

pro CImWin::SetDFilterDefaults, base_id

widget_control, base_id, get_uval=base_uval

print, 'setting digital filter defaults'

cdfilter_ptr=self.p_FilterObj
p_FilterObj=*cdfilter_ptr

p_FilterObj->setImWinObj, base_uval.self_ptr
;p_FilterObj->setXOff, 0.50
;p_FilterObj->setYSize, 10.
;p_FilterObj->setYOff, 0.5
;p_FilterObj->setFilename, 'idl.ps'
;p_FilterObj->setInches, 1
;p_FilterObj->setColor, 1
;p_FilterObj->setBitsPerPixel, 8
;p_FilterObj->setEncapsulated, 0
;p_FilterObj->setIsolatin1, 0
;p_FilterObj->setDfiltererName, 'q6171'
;p_FilterObj->setLandscape, 0
;p_FilterObj->setDfilterDes, 0

end

pro CImWin::Rotate, base_id

widget_control, base_id, get_uval=base_uval

base=widget_base(/col, group_leader=base_id, title='Rotate', /tlb_kill_request_events)
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

base_uval.exist.rotate=base
widget_control, base_id, set_uval=base_uval

xmanager, 'CImWin_Rotate_TLB', base, /just_reg, /no_block, cleanup='ql_subbase_death'
xmanager, 'CImWin_Rotate', ok_button, /just_reg, /no_block
xmanager, 'CImWin_Rotate', close_button, /just_reg, /no_block


end

pro CImWin::Linear, base_id

self.DispScale='linear'
self->DrawImage

end

pro CImWin::Negative, base_id

self.DispScale='negative'
self->DrawImage

end

pro CImWin::HistEq, base_id

self.DispScale='histeq'
self->DrawImage

end

pro CImWin::Logarithmic, base_id, min=min
	; switch to log scaling, optionally setting the plot min as well
self.DispScale='logarithmic'

 	if n_elements(min) gt 0 then begin
		self.DispMin= min
		self->UpdateText
 	endif

self->DrawImage

end

pro CImWin::Sqrt, base_id

self.DispScale='sqrt'
self->DrawImage

end

pro CImWin::AsinH, base_id

self.DispScale='asinh'
self->DrawImage

end

pro CImWin::DispPA, base_id

widget_control, base_id, get_uval=uval
widget_control, self.ParentBaseId, get_uval=conbase_uval

; get the image object header
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
hd=*(ImObj->GetHeader())

; get the PA function from the configs file, if possible
if ptr_valid(conbase_uval.cconfigs_ptr) then begin
    if obj_valid(*conbase_uval.cconfigs_ptr) then begin
        if obj_isa(*conbase_uval.cconfigs_ptr, 'CConfigs') then begin
            cconfigs=*(conbase_uval.cconfigs_ptr)
            pa_function=cconfigs->GetCalcPA() 
        endif else begin
            pa_function=['osiris_calc_pa']
        endelse
    endif else begin
        pa_function=['osiris_calc_pa']
    endelse
endif else begin
    pa_function=['osiris_calc_pa']
endelse

pa=call_function(pa_function, hd) 

; set mask to [1,1,1,1,1,...]
;mask = !d.n_colors - 1
;mask = !p.color
; color index must be 8-bit
if !d.n_colors gt 256 then mask = 250 else mask = !d.n_colors - 1

; if error
if pa[0] eq -1 then begin
    answer=dialog_message(['Error finding header keywords.'], $
         /error, dialog_parent=base_id)
endif else begin
    ; find where to draw pa arrow
    geom=widget_info(uval.wids.draw, /geometry)
    l=(geom.xsize < geom.ysize)*0.40
    ; figure out if the frame is a spec or imager
    ;    outang_in_rad=(!pi/180)*pa[0]
    ;    x=(geom.xsize-(l*cos(outang_in_rad)))/2.0
    ;    y=(geom.ysize-(l*sin(outang_in_rad)))/2.0
    x=(geom.xsize)/2.0
    y=(geom.ysize)/2.0
    ; check to see if the image is rotated
    if (self.naxis eq 3) then begin
        case 1 of
            array_equal(self.axesorder,[2,1,0]): begin ; 2, 1, 0 is no rotation for 3D
                arrowpa = -pa
            end
            array_equal(self.axesorder,[1,2,0]): begin ; 1, 2, 0 is transposed for 3D
                arrowpa = -90-pa
            end
            else:begin
                    answer=dialog_message(['PA not available in this orientation.'], $
                                          /error, dialog_parent=base_id)
                return
            endelse
        endcase
   endif else begin
        ; 2D image
        case 1 of
            array_equal(self.axesorder,[0,1,2]): begin ; 0,1 is no rotation for 2D
                arrowpa = -pa
            end
            array_equal(self.axesorder,[1,0,2]): begin ; 1, 0 is transposed for 2D
                arrowpa = -90-pa
            end
            else:begin
                    answer=dialog_message(['PA not available in this orientation.'], $
                                          /error, dialog_parent=base_id)
                return
            endelse
        endcase
    endelse
    ; get window and set up drawing
    save=!D.WINDOW
    device, get_graphics=oldg, set_graphics=uval.xor_type
    wset, self.DrawIndex
    ; draw N and E arrows, +90 to make N up
    one_arrow, x, y, arrowpa[0]+90, 'N', arrowsize=[float(l), l/5.0, 35.0], $
      color=mask, charsize=3
    one_arrow, x, y, arrowpa[1]+90, 'E', arrowsize=[float(l), l/5.0, 35.0], $
      color=mask, charsize=3
    device, set_graphics=oldg
    wset, save
endelse

end

; MDP generalized version of too many repetitive routines
PRO CImWin::NewPlotWindow, base_id, type
	; validate input	
	valid_names = ['depth', 'horizontal', 'vertical', 'diagonal', 'surface', 'contour']
	if total(valid_names eq type) eq 0 then message, "INVALID PLOT TYPE: Don't know how to plot a '"+type+"' plot."
	
	; get image data
	widget_control, base_id, get_uval=base_uval
	im_ptr= (*self.p_ImObj)->GetData()
	
	; realize plot window
	plot_win=obj_new('CPlotWin', ParentBaseId=self.BaseId, $
	    p_DispIm=self.p_DispIm, p_Im=im_ptr, type=type, $
	    win_backing=base_uval.win_backing)
	
	; Store the information about the newly-created
	; CPlotWin object into the CImWin's uval.
	base_uval.exist.plot=plot_win->GetBaseId()
	base_uval.box_mode=type 
	widget_control, base_id, set_uval=base_uval
	
end



pro CImWin::Statistics, base_id

widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Statistics', group_leader=base_id, /col, $
                   /tlb_kill_request_events)
statbase=widget_base(base, /col, /base_align_right)
filename = widget_label(statbase, value = ('Filename: '+ImObj->GetFilename()))

xrangebase=widget_base(statbase, /row)
data_xmin_box=cw_field(xrangebase, title='X Range: ', xs=10, /return_events)
data_xmax_box=cw_field(xrangebase, title='to', xs=10, /return_events)

yrangebase=widget_base(statbase, /row)
data_ymin_box=cw_field(yrangebase, title='Y Range: ', xs=10, /return_events)
data_ymax_box=cw_field(yrangebase, title='to', xs=10, /return_events)

totpixbase=widget_base(statbase, /row)
totpixlabel = widget_label(totpixbase, value = 'Total pixels:')
totpixval = widget_label(totpixbase, value = '0', frame = 2, xsize =120, $
    /align_right)
meanbase=widget_base(statbase, /row)
meanlabel = widget_label(meanbase, value = 'Mean pixel value:')
meanval = widget_label(meanbase, value = '0', frame = 2, xsize =120, $
    /align_right)
medbase=widget_base(statbase, /row)
medlabel = widget_label(medbase, value = 'Median pixel value:')
medval = widget_label(medbase, value = '0', frame = 2, xsize = 120, $
    /align_right)
modebase=widget_base(statbase, /row)
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
recalc_button=widget_button(base, value="Recalculate Statistics")
close_button=widget_button(base, value='Close')

; set uval
wids = {base_id:base_id, $
        data_xmin:data_xmin_box, $
        data_xmax:data_xmax_box, $
        data_ymin:data_ymin_box, $
        data_ymax:data_ymax_box, $
        totpixval_id:totpixval, $
        meanval_id: meanval, $
        medval_id: medval, $
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
xmanager, 'CImWin_RecalcStat_Button', recalc_button, /just_reg, /no_block
xmanager, 'CImWin_Stat_Range', data_xmin_box, /just_reg, /no_block
xmanager, 'CImWin_Stat_Range', data_xmax_box, /just_reg, /no_block
xmanager, 'CImWin_Stat_Range', data_ymin_box, /just_reg, /no_block
xmanager, 'CImWin_Stat_Range', data_ymax_box, /just_reg, /no_block
xmanager, 'CImWin_Stat_Button', close_button, /just_reg, /no_block

; register existence of base
base_uval.exist.statistics=base
; set box mode
base_uval.box_mode='stat'

widget_control, base_id, set_uval=base_uval

end

pro CImWin::CalcStat, base_id
; this routine calcultaes the statistics of the selected region
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

    ; calculate total pixels
    totpix_calc=float(long(x1pix-x0pix+1)*long(y1pix-y0pix+1))
    totpix=strtrim(totpix_calc, 2)

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

    ; calculate total pixels
    totpix_calc=float(long(x1pix-x0pix+1)*long(y1pix-y0pix+1))
    totpix=strtrim(totpix_calc, 2)

    print, 'total counts ', strtrim(totpix_calc*meanv,2)
endelse

widget_control, uval.wids.data_xmin, set_value=x0pix
widget_control, uval.wids.data_xmax, set_value=x1pix
widget_control, uval.wids.data_ymin, set_value=y0pix
widget_control, uval.wids.data_ymax, set_value=y1pix
widget_control, uval.wids.totpixval_id, set_value=totpix
widget_control, uval.wids.meanval_id, set_value=meanv
widget_control, uval.wids.stddevval_id, set_value=std
widget_control, uval.wids.minval_id, set_value=min
widget_control, uval.wids.maxval_id, set_value=max
widget_control, uval.wids.varval_id, set_value=var
widget_control, uval.wids.medval_id, set_value=med

end

pro CImWin::UpdateStatRange

; get the imwin & conbase uvals
widget_control, self.BaseId, get_uval=cimwin_uval

if (cimwin_uval.exist.statistics ne 0) then begin
    widget_control, cimwin_uval.exist.statistics, get_uval=stat_uval

    im=*self.p_DispIm
    pmode=*cimwin_uval.pmode_ptr

    if (pmode[0].type ne 'stat') then begin
        ; get the box values from the cimwin uval
        xmin=cimwin_uval.box_p0[0]
        xmax=cimwin_uval.box_p1[0]
        ymin=cimwin_uval.box_p0[1]
        ymax=cimwin_uval.box_p1[1]
    endif else begin
        ; get values
        widget_control, stat_uval.wids.data_xmin, get_value=xmin
        widget_control, stat_uval.wids.data_xmax, get_value=xmax
        widget_control, stat_uval.wids.data_ymin, get_value=ymin
        widget_control, stat_uval.wids.data_ymax, get_value=ymax
    endelse

    ; handle x data input errors (e.g. strings)
    on_ioerror, xmin_error
    xmin=fix(xmin[0])
    goto, no_xmin_error
    xmin_error: xmin=0
    no_xmin_error:
    on_ioerror, xmax_error
    xmax=fix(xmax[0])
    goto, no_xmax_error
    xmax_error: xmax=0
    no_xmax_error:
    
    xmin_value=xmin < xmax
    xmax_value=xmin > xmax

    ; make array of two values
    x_newrange=[xmin_value, xmax_value]

    ; if the ranges are greater than the image size, then set the ranges
    ; equal to the size of the image
    if (xmin_value lt 0) then xmin_value=0
    if (xmax_value gt (self->GetDispIm_xs()-1)) then xmax_value=(self->GetDispIm_xs()-1)
    x_newrange=[xmin_value, xmax_value]

    ; reset field boxes
    widget_control, stat_uval.wids.data_xmin, set_value=x_newrange[0]
    widget_control, stat_uval.wids.data_xmax, set_value=x_newrange[1]

    ; handle y data box input errors (e.g. strings)
    on_ioerror, ymin_error
    ymin=fix(ymin[0])
    goto, no_ymin_error
    ymin_error: ymin=0
no_ymin_error:
    on_ioerror, ymax_error
    ymax=fix(ymax[0])
    goto, no_ymax_error
    ymax_error: ymax=0
no_ymax_error:

    ymin_value=ymin < ymax
    ymax_value=ymin > ymax

    ; make array of two values
    y_newrange=[ymin_value, ymax_value]

    ; if the ranges are greater than the image size, then set the ranges
    ; equal to the size of the image
    if (ymin_value lt 0) then ymin_value=0
    if (ymax_value gt (self->GetDispIm_ys()-1)) then ymax_value=(self->GetDispIm_ys()-1)
    y_newrange=[ymin_value, ymax_value]

    ; reset field boxes
    widget_control, stat_uval.wids.data_ymin, set_value=y_newrange[0]
    widget_control, stat_uval.wids.data_ymax, set_value=y_newrange[1]

    widget_control, cimwin_uval.exist.statistics, set_uval=stat_uval

    ; remove the previous box if it exists
    if (pmode[0].pointingmode eq 'box') then begin
        if (pmode[0].type ne 'zbox') then begin
            ; remove the previous box
            if (((cimwin_uval.box_p0[0] ne 0) and (cimwin_uval.box_p0[1] ne 0)) or $
                ((cimwin_uval.box_p1[0] ne 0) and (cimwin_uval.box_p1[1] ne 0))) then begin
                self->Draw_Box, cimwin_uval.draw_box_p0, cimwin_uval.draw_box_p1
            endif
        endif
    endif

    ; set min and max box values
    cimwin_uval.box_p0=[x_newrange[0],y_newrange[0]]
    cimwin_uval.box_p1=[x_newrange[1],y_newrange[1]]

    widget_control, stat_uval.base_id, set_uval=cimwin_uval
        
    ; redraw the box accordingly
    self->DrawBoxParams
    self->DrawImageBox_n_Circles

    if (pmode[0].type eq 'stat') then begin
        self->CalcStat, stat_uval.base_id
    endif
endif

end

pro CImWin::Photometry, base_id

widget_control, base_id, get_uval=base_uval
widget_control, self.parentbaseid, get_uval=conbase_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Photometry', group_leader=base_id, /col, $
                   /tlb_kill_request_events)
photbase=widget_base(base, /col, /base_align_right)
filename = widget_label(photbase, value = ('Filename: '+ImObj->Getfilename()))

info = widget_info(filename, /geometry)
xs = info.xsize
ys = info.ysize

xpositionbase=widget_base(photbase, /row)
xlabel = widget_label(xpositionbase, value = 'X position:', yoff=ysize)
xval = widget_label(xpositionbase, value = '0', frame = 2, xsize =120, $
                    yoff=ysize, /align_right)

info = widget_info(xlabel, /geometry)
ys2 = info.ysize + 10

ypositionbase=widget_base(photbase, /row)
ylabel = widget_label(ypositionbase, value = 'Y position:', yoff=ys+ys2)
yval = widget_label(ypositionbase, value = '0', frame = 2, xsize =120, $
    /align_right, yoff=ys+ys2)
magbase=widget_base(photbase, /row)
maglabel=widget_label(magbase, value = 'Magnitude:',  yoff = ys + 2*ys2)
magval=widget_label(magbase,value='0', frame=2, xsize=120, $
                    /align_right,  yoff = ys + 2*ys2)
obcntbase=widget_base(photbase, /row)
obcntlabel=widget_label(obcntbase, value = 'Raw Object Counts:',  $
                        yoff = ys + 3*ys2)
obcntval=widget_label(obcntbase,value='0', frame=2, xsize=120, $
                    /align_right,  yoff = ys + 3*ys2)
mskybase=widget_base(photbase, /row)
mskylabel=widget_label(mskybase, value = 'Mean Sky Value:',  yoff = ys + 4*ys2)
mskyval=widget_label(mskybase,value='0', frame=2, xsize=120, $
                    /align_right,  yoff = ys + 4*ys2)
corcntsbase=widget_base(photbase, /row)
corcntslabel=widget_label(corcntsbase, value = 'Corrected Counts:',  $
                          yoff = ys + 5*ys2)
corcntsval=widget_label(corcntsbase,value='0', frame=2, xsize=120, $
                    /align_right,  yoff = ys + 5*ys2)

line = widget_label(photbase, frame = 2, xsize = 310, xoff = 10, $
                    yoff = ys + 6*ys2, ysize = 2, value = '')

paramlabel = widget_label(photbase, xsize = 330, /align_center, $
                          value = 'Photometry parameters')
info=widget_info(photbase, /geometry)
height=info.ysize
yoff=height + ys + 7*ys2 + 20

zmagbase=widget_base(photbase, /row)
zmaglabel=widget_label(zmagbase, yoff = yoff, $
                         value = 'Zero Point:')
zmagtext=widget_text(zmagbase, xoff = 220, yoff = yoff - 3, $
                       value = strtrim(string(self.def_zmag),2), xsize = 10, $
                       /editable)
itimebase=widget_base(photbase, /row)
itimelabel=widget_label(itimebase, yoff = yoff + 50, value = 'Itime:')
itimetext=widget_text(itimebase, xoff = 220, yoff = yoff + 47, $
                        value = strtrim(string(self.def_itime),2), xsize = 10, $
                        /editable)

inanbase=widget_base(photbase, /row)
innerlabel=widget_label(inanbase, yoff = yoff + 100, value = 'Inner Sky An:')
inner_up=widget_button(inanbase, val='I+', yoff=yoff+97, xoff=140)
inner_down=widget_button(inanbase, val='I-', yoff=yoff+97, xoff=180)
innertext=widget_text(inanbase, xoff = 220, yoff = yoff + 97, $
                        value = strtrim(string(self.photometry_inner_an),2), xsize=10,$
                        /editable)

outanbase=widget_base(photbase, /row)
outerlabel=widget_label(outanbase, yoff = yoff + 150, value = 'Outer Sky An:')
outer_up=widget_button(outanbase, val='O+', yoff=yoff+147, xoff=140)
outer_down=widget_button(outanbase, val='O-', yoff=yoff+147, xoff=180)
outertext=widget_text(outanbase, xoff = 220, yoff = yoff + 147, $
                        value = strtrim(string(self.photometry_outer_an),2), xsize=10,$
                        /editable)

aperbase=widget_base(photbase, /row)
aperlabel=widget_label(aperbase, yoff = yoff + 200, value = 'Aperture (pix):')

aper_up=widget_button(aperbase, val='A+', yoff=yoff+197, xoff=140)
aper_down=widget_button(aperbase, val='A-', yoff=yoff+197, xoff=180)
apertext=widget_text(aperbase, xoff = 220, yoff = yoff + 197, $
                       value = strtrim(string(self.photometry_aper),2), xsize = 10, $
                       /editable)

buttonbase=widget_base(base, /row, /align_center)
close_button=widget_button(buttonbase, value = 'Close')
reactivate_button=widget_button(buttonbase, value = 'Reactivate')
calcbutton=widget_button(buttonbase, value = 'Calculate')

; set uval
wids = {base_id:base_id, $
        filename_id:filename, $
        reactivate_id:reactivate_button, $
        calc_id:calcbutton, $
        x_id:xval, $
        y_id:yval, $
        mag_id:magval, $
        obcnt_id:obcntval, $
        msky_id:mskyval, $
        corcnts_id:corcntsval, $
        zmag_id:zmagtext, $
        itime_id:itimetext, $
        inner_id:innertext, $
        outer_id:outertext, $
        aper_id:apertext $
       }

uval={base_id:base_id, $
      wids:wids $
     }

; realize widget
widget_control, base, /realize, set_uvalue=uval

; register the photometry events with xmanager
xmanager, 'CImWin_Photometry_Base', base, /just_reg, /no_block, $
    cleanup='ql_subbase_death'
xmanager, 'CImWin_Photometry_Parameters', zmagtext, /just_reg  , /no_block
xmanager, 'CImWin_Photometry_Parameters', itimetext, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Parameters', innertext, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Parameters', outertext, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Parameters', apertext, /just_reg, /no_block

xmanager, 'CImWin_Photometry_Button', close_button, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', reactivate_button, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', calcbutton, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', inner_up, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', inner_down, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', outer_up, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', outer_down, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', aper_up, /just_reg, /no_block
xmanager, 'CImWin_Photometry_Button', aper_down, /just_reg, /no_block

; register existence of base
base_uval.exist.photometry=base

widget_control, base_id, set_uval=base_uval

self->UpdatePhotometryText

end

pro CImWin::CalcPhot

widget_control, self.BaseId, get_uval=cimwin_uval

if self.def_itime eq 0 then self.def_itime=1

; get the image data
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr

;ql_aper, disp_im, cimwin_uval.phot_circ_x, cimwin_uval.phot_circ_y, flux, eflux, sky, skyerr, 1, self.photometry_aper, $
;  [self.photometry_inner_an, self.photometry_outer_an], [0,0], numaper_pix=numaper_pix, /FLUX, /EXACT

ql_aper, disp_im, cimwin_uval.phot_circ_x, cimwin_uval.phot_circ_y, flux, eflux, sky, skyerr, 1, self.photometry_aper, $
  [self.photometry_inner_an, self.photometry_outer_an], [0,0], NUMAPER_PIX=numaper_pix, /FLUX, BASE_ID=base_id

; jlyke 2020-04-15: ql_aper was sky-correcting data using the aperture
;                   area, then below we were sky correcting again
;                   using number of whole+partial pixels.
;                   I removed the sky-correction from ql_aper and
;                   changed the calc here: cor_counts=...

; calculate photometry parameters
if (numaper_pix gt 0) then begin
    counts=flux
    mean_sky=sky[0]
    ; jlyke - change noted above
    ;cor_counts=(flux-sky[0]*double(numaper_pix))
    cor_counts=(flux-sky[0]*!pi*self.photometry_aper*self.photometry_aper)
    ; check to see if the data is in DN or DN/s
    widget_control, cimwin_uval.wids.datanum, get_value=dntag
    case dntag of
        'DN/s': begin
            mag=self.def_zmag-2.5*alog10(double(cor_counts))            
        end
        'DN': begin
            mag=self.def_zmag-2.5*alog10(double(cor_counts)/self.def_itime)
        end
        else: begin
            ; assume the image is in DN
            mag=self.def_zmag-2.5*alog10(double(cor_counts))            
        endelse
    endcase
endif else begin
    message=['Error in computing the photometry.', 'The aperture may be outside the limits of the image.', $
             'Maybe there are not enough pixels in the sky annulus.']
    answer=dialog_message(message, dialog_parent=self.BaseId, /error)
    return
endelse    

; use Jason's ql_aperture photometry routine
;mag=ql_aperture(disp_im, cimwin_uval.phot_circ_x, cimwin_uval.phot_circ_y, $
;                self.photometry_aper, self.photometry_inner_an, self.photometry_outer_an, $
;                itime=self.def_itime, zmag=self.def_zmag, counts=counts, mean_sky=mean_sky, $
;                cor_counts=cor_counts)

; update the photometry labels
widget_control, cimwin_uval.exist.photometry, get_uval=phot_uval

; update each field with new member variable values
widget_control, phot_uval.wids.x_id, set_value=$
    string(format='(F11.3)', cimwin_uval.phot_circ_x)
widget_control, phot_uval.wids.y_id, set_value=$
    string(format='(F11.3)', cimwin_uval.phot_circ_y)
widget_control, phot_uval.wids.mag_id, set_value=$
    string(format='(F11.3)', mag)
widget_control, phot_uval.wids.obcnt_id, set_value=$
    string(format='(F15.3)', counts)
widget_control, phot_uval.wids.msky_id, set_value=$
    string(format='(F11.3)', mean_sky)
widget_control, phot_uval.wids.corcnts_id, set_value=$
    string(format='(F15.3)', cor_counts)

end

pro CImWin::UpdatePhotometryText
; this routine will update all the text fields displayed on the photometry gui

; get uval for wids
widget_control, self.BaseId, get_uval=base_uval
widget_control, base_uval.exist.photometry, get_uval=phot_uval

; update each field with new member variable values
widget_control, phot_uval.wids.zmag_id, set_value=$
    string(format='(F8.3)', self.def_zmag)
widget_control, phot_uval.wids.itime_id, set_value=$
    string(format='(F8.3)', self.def_itime)
widget_control, phot_uval.wids.inner_id, set_value=$
    string(format='(F8.3)', self.photometry_inner_an)
widget_control, phot_uval.wids.outer_id, set_value=$
    string(format='(F8.3)', self.photometry_outer_an)
widget_control, phot_uval.wids.aper_id, set_value=$
    string(format='(F8.3)', self.photometry_aper)

end

pro CImWin::UpdateStrehlText
; this routine will update all the text fields displayed on the strehl gui

; get uval for wids
widget_control, self.BaseId, get_uval=base_uval
widget_control, base_uval.exist.strehl, get_uval=strehl_uval

; update each field with new member variable values
widget_control, strehl_uval.wids.ap_size, set_value=$
    string(format='(F8.3)', self.strehl_apsize)

end

pro CImWin::UpdateMovieText
; this routine will update all the text fields displayed on the movie gui

; get uval for wids
widget_control, self.BaseId, get_uval=base_uval
widget_control, base_uval.exist.movie, get_uval=movie_uval

; update each field with new member variable values
widget_control, movie_uval.wids.chanstar_id, set_value=$
    string(format='(F8.3)', self.movie_chan_start)
widget_control, movie_uval.wids.chanstop_id, set_value=$
    string(format='(F8.3)', self.movie_chan_stop)
widget_control, movie_uval.wids.mag_id, set_value=$
    string(format='(F8.3)', self.movie_mag)
widget_control, movie_uval.wids.xspatbin_id, set_value=$
    string(format='(F8.3)', self.movie_xspat_bin)
widget_control, movie_uval.wids.yspatbin_id, set_value=$
    string(format='(F8.3)', self.movie_yspat_bin)
widget_control, movie_uval.wids.binsize_id, set_value=$
    string(format='(F8.3)', self.movie_bin_size)
widget_control, movie_uval.wids.binstep_id, set_value=$
    string(format='(F8.3)', self.movie_bin_step)
widget_control, movie_uval.wids.minval_id, set_value=$
    string(format='(F8.3)', self.movie_min_value)
widget_control, movie_uval.wids.maxval_id, set_value=$
    string(format='(F8.3)', self.movie_max_value)

end

pro CImWin::Strehl, base_id

widget_control, base_id, get_uval=base_uval
widget_control, self.parentbaseid, get_uval=conbase_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
hd=*(ImObj->GetHeader())

; set the strehl plot window sizes
x_size=256
y_size=256

; calculate the default strehl aperture size
camname=osiris_pscale(hd)
case camname of
    '0.020': begin
        pscl = 20e-3
        self.strehl_apsize=ROUND(0.5/float(pscl))
    end
    '0.035': begin
        pscl = 35e-3
        self.strehl_apsize=ROUND(0.5/float(pscl))        
    end
    '0.050': begin
        pscl = 50e-3
        self.strehl_apsize=ROUND(0.5/float(pscl))        
    end
    '0.100': begin
        pscl = 100e-3
        self.strehl_apsize=ROUND(0.5/float(pscl))        
    end
    else: self.strehl_apsize=5.
endcase

; Create widgets
base=widget_base(TITLE = 'Strehl Calculator', group_leader=base_id, /col, $
                   /tlb_kill_request_events)
strehlbase=widget_base(base, /col, /base_align_right)

infobase=widget_base(strehlbase, /row)
filename = widget_label(infobase, value = ('Filename: '+ImObj->GetFilename()))
aperture_size_label=widget_label(infobase, value='Aperture Size:', /align_right)
aperture_size_text=widget_text(infobase, value=strtrim(string(self.strehl_apsize),2), $
                               xsize = 10, /editable)
reactivate_button=widget_button(infobase, value = 'Reactivate')
calculate_button=widget_button(infobase, value = 'Calculate')


topdraw_base=widget_base(strehlbase, /row)
im=widget_draw(topdraw_base, xs=x_size, ys=y_size, $
                  retain=base_uval.win_backing)
psf_im=widget_draw(topdraw_base, xs=x_size, ys=y_size, $
                  retain=base_uval.win_backing)
label_base=widget_base(strehlbase, /row)
imfwhm_label = widget_label(label_base, value = 'IM FWHM:')
imfwhm_val = widget_label(label_base, value='0', frame=2, xsize=60, $
    /align_right)
imstrehl_label = widget_label(label_base, value = 'IM STREHL:')
imstrehl_val = widget_label(label_base, value='0', frame=2, xsize=60, $
    /align_right)

psf_imfwhm_label = widget_label(label_base, value = 'PSF FWHM:')
psf_imfwhm_val = widget_label(label_base, value='0', frame=2, xsize=60, $
    /align_right)
psf_imstrehl_label = widget_label(label_base, value = 'PSF STREHL:')
psf_imstrehl_val = widget_label(label_base, value='0', frame=2, xsize=60, $
    /align_right)

bottomdraw_base=widget_base(strehlbase, /row)
im_fit=widget_draw(bottomdraw_base, xs=x_size, ys=y_size, $
                  retain=base_uval.win_backing)
psf_fit=widget_draw(bottomdraw_base, xs=x_size, ys=y_size, $
                  retain=base_uval.win_backing)
button_base=widget_base(base, /row)
close_button=widget_button(base, value="Close")

; set the strehl routine uvals
wids={base_id:base_id, $
      im:0L, $
      ap_size:aperture_size_text, $
      reactivate_id:reactivate_button, $
      calc_id:calculate_button, $
      psf_im:0L, $
      im_fit:0L, $
      psf_fit:0L, $
      imfwhm:imfwhm_val, $
      imstrehl:imstrehl_val, $
      psf_imfwhm:psf_imfwhm_val, $
      psf_imstrehl:psf_imstrehl_val, $
      filename_id:filename}

uval={base_id:base_id, $
      wids:wids}

; realize widget
widget_control, base, /realize, set_uvalue=uval

xmanager, 'CImWin_Strehl_Base', base, /just_reg, /no_block, $
    cleanup='ql_subbase_death'
xmanager, 'CImWin_Strehl_Parameters', aperture_size_text, /just_reg  , /no_block
xmanager, 'CImWin_Strehl_Button', reactivate_button, /just_reg, /no_block
xmanager, 'CImWin_Strehl_Button', calculate_button, /just_reg, /no_block
xmanager, 'CImWin_Strehl_Button', close_button, /just_reg, /no_block

; register existence of base
base_uval.exist.strehl=base
widget_control, base_id, set_uval=base_uval 

; Realize widgets and assign window ids
widget_control, im, get_value=im_idx
widget_control, psf_im, get_value=psf_im_idx
widget_control, im_fit, get_value=im_fit_idx
widget_control, psf_fit, get_value=psf_fit_idx

widget_control, base, /realize, get_uval=uval
uval.wids.im=im_idx
uval.wids.psf_im=psf_im_idx
uval.wids.im_fit=im_fit_idx
uval.wids.psf_fit=psf_fit_idx
widget_control, base, /realize, set_uval=uval

end

pro CImWin::CalcStrehl

widget_control, self.BaseId, get_uval=base_uval
widget_control, self.parentbaseid, get_uval=conbase_uval

pos=[base_uval.phot_circ_x, base_uval.phot_circ_y]

; call the program that will calculate the strehl
strehl=osirisstrehl_ql2(self.BaseId, pos, photrad=self.strehl_apsize)

end

pro CImWin::Gaussian, base_id

; get the base uval
widget_control, base_id, get_uval=base_uval

; get image object
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr

; set up widgets
base = widget_base(TITLE = 'Peak Fit', group_leader=base_id, /col, $
                   /tlb_kill_request_events)
gaussbase=widget_base(base, /col, /base_align_right)
filename = widget_label(gaussbase, value = ('Filename: '+ImObj->GetFilename()))

xrangebase=widget_base(gaussbase, /row)
data_xmin_box=cw_field(xrangebase, title='X Range: ', xs=10, /return_events)
data_xmax_box=cw_field(xrangebase, title='to', xs=10, /return_events)

yrangebase=widget_base(gaussbase, /row)
data_ymin_box=cw_field(yrangebase, title='Y Range: ', xs=10, /return_events)
data_ymax_box=cw_field(yrangebase, title='to', xs=10, /return_events)

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
fitbase=widget_base(gaussbase, /row)
fit_list=widget_droplist(fitbase, value=['Gaussian', 'Lorentzian', 'Moffat'], title='Fit Type:')

control_base=widget_base(gaussbase, /row)
plot_button=widget_button(control_base, value="Display Peak Fit")
recalc_button=widget_button(control_base, value="Recalculate Peak Fit")
close_button=widget_button(base, value='Close')

; set the gaussian routine uvals
wids = {base_id:base_id, $
        data_xmin:data_xmin_box, $
        data_xmax:data_xmax_box, $
        data_ymin:data_ymin_box, $
        data_ymax:data_ymax_box, $
        xcenter_id: xcenter_val, $
        ycenter_id: ycenter_val, $
        xfwhm_id: xfwhm_val, $
        yfwhm_id: yfwhm_val, $
        minval_id: minval, $
        maxval_id: maxval, $
        fitlist_id:fit_list, $
        filename_id: filename}

exist={plotwin:0L}

plot_info = {raw_data_ptr:ptr_new(/allocate_heap), $
             fit_data_ptr:ptr_new(/allocate_heap), $
             x_arg_ptr:ptr_new(/allocate_heap), $
             y_arg_ptr:ptr_new(/allocate_heap), $
             plot_ang:30, $
             min:0, $
             max:0}

uval = {base_id:base_id, $
        wids:wids, $
        exist:exist, $
        plot_info:plot_info, $
        draw1_idx:0L, $
        draw2_idx:0L}

; realize widget
widget_control, base, /realize, set_uvalue=uval

xmanager, 'CImWin_Gauss_Base', base, /just_reg, /no_block, $
    cleanup='ql_subbase_death'
xmanager, 'CImWin_Gauss_Button', close_button, /just_reg, /no_block
xmanager, 'CImWin_RecalcGauss_Button', recalc_button, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Range', data_xmin_box, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Range', data_xmax_box, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Range', data_ymin_box, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Range', data_ymax_box, /just_reg, /no_block
xmanager, 'CImWin_Gauss_Plot', plot_button, /just_reg, /no_block
xmanager, 'CImWin_Fit_List', fit_list, /just_reg, /no_block

; register existence of base
base_uval.exist.gaussian=base
; set the base uval
widget_control, base_id, set_uval=base_uval

end

pro CImWin::CalcGauss, base_id, PLOT=plot
; this routine calculates the gaussian of the selected region

; clear math error status from previous operations
junk=check_math()

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

if ((xsize ge 5) and (ysize ge 5)) then begin

; create vectors to hold x and y arguments for plotting
    x_arg=indgen(xsize)+x0pix
    y_arg=indgen(ysize)+y0pix

; Clear error status from previous operations, and print error
; messages if an error exists:
    junk = check_math(/print)
; Disable automatic printing of subsequent math errors:!EXCEPT=0
    !EXCEPT=0

; get subimage
    array=im[x0pix:x1pix, y0pix:y1pix]
    ; perform statistics
    min=strtrim(min(array, max=max), 2)
    max=strtrim(max, 2)

    ; find out what type of fit we're doing
    case self.fit_type of 
        0: begin
            ; perform a gaussian fit
            yfit=gauss2dfit(array, coeff, x_arg, y_arg)
        end
        1: begin
            ; perform a lorentzian fit
            yfit=mpfit2dpeak(array, coeff, x_arg, y_arg, /lorentzian)
        end
        2: begin
            ; perform a moffat fit
            yfit=mpfit2dpeak(array, coeff, x_arg, y_arg, /moffat)
        end
    endcase

;    yfit=gauss2dfit(array, coeff, x_arg, y_arg)

; assume that no math errors occured during this calculation

    ; update values in gaussian widget ids
    widget_control, uval.wids.data_xmin, set_value=x0pix
    widget_control, uval.wids.data_xmax, set_value=x1pix
    widget_control, uval.wids.data_ymin, set_value=y0pix
    widget_control, uval.wids.data_ymax, set_value=y1pix
    widget_control, uval.wids.xcenter_id, set_value=strtrim(coeff[4], 2)
    widget_control, uval.wids.ycenter_id, set_value=strtrim(coeff[5], 2)
    widget_control, uval.wids.xfwhm_id, set_value=strtrim(coeff[2]*2.355, 2)
    widget_control, uval.wids.yfwhm_id, set_value=strtrim(coeff[3]*2.355, 2)
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
; if the plot widget exists, then update the plot
if (uval.exist.plotwin ne 0L) then begin
    self->GaussPlot, base_uval.exist.gaussian
endif

endif else begin
    message='Please select atleast a 5x5 box for peak fitting.'
    answer=dialog_message(message, dialog_parent=base_id, /error)
    return
endelse

end

pro CImWin::UpdateGaussRange

; get the imwin & conbase uvals
widget_control, self.BaseId, get_uval=cimwin_uval

if (cimwin_uval.exist.gaussian ne 0) then begin
    widget_control, cimwin_uval.exist.gaussian, get_uval=gauss_uval

    im=*self.p_DispIm
    pmode=*cimwin_uval.pmode_ptr

    if (pmode[0].type ne 'peak fit') then begin
        ; get the box values from the cimwin uval
        xmin=cimwin_uval.box_p0[0]
        xmax=cimwin_uval.box_p1[0]
        ymin=cimwin_uval.box_p0[1]
        ymax=cimwin_uval.box_p1[1]
    endif else begin
        ; get values
        widget_control, gauss_uval.wids.data_xmin, get_value=xmin
        widget_control, gauss_uval.wids.data_xmax, get_value=xmax
        widget_control, gauss_uval.wids.data_ymin, get_value=ymin
        widget_control, gauss_uval.wids.data_ymax, get_value=ymax
    endelse

    ; handle x data input errors (e.g. strings)
    on_ioerror, xmin_error
    xmin=fix(xmin[0])
    goto, no_xmin_error
    xmin_error: xmin=0
    no_xmin_error:
    on_ioerror, xmax_error
    xmax=fix(xmax[0])
    goto, no_xmax_error
    xmax_error: xmax=0
    no_xmax_error:
    
    xmin_value=xmin < xmax
    xmax_value=xmin > xmax

    ; make array of two values
    x_newrange=[xmin_value, xmax_value]

    ; if the ranges are greater than the image size, then set the ranges
    ; equal to the size of the image
    if (xmin_value lt 0) then xmin_value=0
    if (xmax_value gt (self->GetDispIm_xs()-1)) then xmax_value=(self->GetDispIm_xs()-1)
    x_newrange=[xmin_value, xmax_value]

    ; reset field boxes
    widget_control, gauss_uval.wids.data_xmin, set_value=x_newrange[0]
    widget_control, gauss_uval.wids.data_xmax, set_value=x_newrange[1]

    ; handle y data box input errors (e.g. strings)
    on_ioerror, ymin_error
    ymin=fix(ymin[0])
    goto, no_ymin_error
    ymin_error: ymin=0
no_ymin_error:
    on_ioerror, ymax_error
    ymax=fix(ymax[0])
    goto, no_ymax_error
    ymax_error: ymax=0
no_ymax_error:

    ymin_value=ymin < ymax
    ymax_value=ymin > ymax

    ; make array of two values
    y_newrange=[ymin_value, ymax_value]

    ; if the ranges are greater than the image size, then set the ranges
    ; equal to the size of the image
    if (ymin_value lt 0) then ymin_value=0
    if (ymax_value gt (self->GetDispIm_ys()-1)) then ymax_value=(self->GetDispIm_ys()-1)
    y_newrange=[ymin_value, ymax_value]

    ; reset field boxes
    widget_control, gauss_uval.wids.data_ymin, set_value=y_newrange[0]
    widget_control, gauss_uval.wids.data_ymax, set_value=y_newrange[1]

    widget_control, cimwin_uval.exist.gaussian, set_uval=gauss_uval

    ; remove the previous box if it exists
    if (pmode[0].pointingmode eq 'box') then begin
        if (pmode[0].type ne 'zbox') then begin
            ; remove the previous box
            if (((cimwin_uval.box_p0[0] ne 0) and (cimwin_uval.box_p0[1] ne 0)) or $
                ((cimwin_uval.box_p1[0] ne 0) and (cimwin_uval.box_p1[1] ne 0))) then begin
                self->Draw_Box, cimwin_uval.draw_box_p0, cimwin_uval.draw_box_p1
            endif
        endif
    endif

    ; set min and max box values
    cimwin_uval.box_p0=[x_newrange[0],y_newrange[0]]
    cimwin_uval.box_p1=[x_newrange[1],y_newrange[1]]

    widget_control, gauss_uval.base_id, set_uval=cimwin_uval

    ; redraw the box accordingly
    self->DrawBoxParams
    self->DrawImageBox_n_Circles

    if (pmode[0].type eq 'peak fit') then begin
        self->CalcGauss, gauss_uval.base_id
    endif
endif

end

pro CImWin::Unravel, base_id

widget_control, base_id, get_uval=uval

; get the what data is being displayed
xmin=uval.box_p0[0] < uval.box_p1[0]
xmax=uval.box_p0[0] > uval.box_p1[0]

ymin=uval.box_p1[1] < uval.box_p0[1]
ymax=uval.box_p0[1] > uval.box_p1[1]

xdata_range=[xmin, xmax]
ydata_range=[ymin, ymax]

zdata_range=[self.zmin, self.zmax]

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

; check to make sure the IM has 3 dimensions
; find out how many channels there are in the Z direction
if (im_zs gt 1) then begin
    im_s=([im_xs, im_ys, im_zs])[self.AxesOrder]
endif else begin
    message='Unraveled images can only be made with 3 dimensional images.'
    answer=dialog_message(message, dialog_parent=base_id, /error)
    return
endelse

; make the unraveled 2D image
xs=xdata_range[1]-xdata_range[0]+1
ys=ydata_range[1]-ydata_range[0]+1
zs=zdata_range[1]-zdata_range[0]+1

xdata_arr=dindgen(xs)+xmin
ydata_arr=dindgen(ys)+ymin


unravel_arr=fltarr(zs,xs*ys)
unravel_locations=fltarr(xs*ys, 2)

; place the individual straws into the 2D unraveled image
for j=0,ys-1 do begin
    for i=0,xs-1 do begin
        index=i+j*xs
        unravel_arr[*,index]=im[xdata_range[0]+i, ydata_range[0]+j, $ 
                                zdata_range[0]:zdata_range[1]]
        unravel_locations[index,0]=xdata_arr[i]
        unravel_locations[index,1]=ydata_arr[j]
    endfor
endfor

; make a cimage from the array
hd_ptr=ImObj->GetHeader()
hd=*(ImObj->GetHeader())
new_zs=1
n_ext=0
ext=0
; this should be the filename - .fits + _unraveled.fits'
filename=ImObj->GetFilename()
fname_next=ql_get_namenext(filename)
unraveled_name=fname_next+'_unraveled.fits'

; makes pointers to the data and header
data_ptr=ptr_new(unravel_arr)
sxaddpar, hd, 'naxis', 2
hd_ptr=ptr_new(hd)
; makes a new instance of the 'CImage' class with the 
; appropriate parameters
im=obj_new('CImage', filename=unraveled_name, data=data_ptr, $
           header=hd_ptr, xs=zs, ys=xs*ys, zs=new_zs, $
           n_ext=n_ext, ext=ext)
p_ImObj=ptr_new(im)

; checks to see if the object is valid, and makes sure that object
; is of the class 'CImage'
if obj_valid(im) then begin
    if obj_isa(im, 'CImage') then begin
            widget_control, self.ParentBaseId, get_uval=conbase_uval
            conbase_uval.unravel=1
            widget_control, self.ParentBaseId, set_uval=conbase_uval
            ql_display_new_image, self.ParentBaseId, p_ImObj, $
              ext
            ; get the most recently created image window
            widget_control, self.ParentBaseId, get_uval=conbase_uval
            cur_imwin_arr=*conbase_uval.current_imwins
            n_windows=n_elements(cur_imwin_arr)
            unravel_imwin_ptr=cur_imwin_arr(n_windows-1)
            
            ; set the unravel parameters in the unraveled image window
            ; member variables
            unravel_imwin=*unravel_imwin_ptr

            ; save the unraveled data ranges in the unraveled imwin
            unraveled_ptr=ptr_new(unravel_locations)
            unravel_imwin->SetUnravelLocations, unraveled_ptr

    endif else begin
        ; issues an error message if obj_isa fails
        message=['Error reading unraveled file:', $
                 ' Error creating CImage object']
        answer=dialog_message(message, dialog_parent=$
                              conbase_id)
        ptr_free, p_ImObj    
        obj_destroy, im    
    endelse
endif

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

; Plot peak fit surface in right window
wset, gauss_uval.draw2_idx
shade_surf, *gauss_uval.plot_info.fit_data_ptr, *gauss_uval.plot_info.x_arg_ptr, $
            *gauss_uval.plot_info.y_arg_ptr, az=gauss_uval.plot_info.plot_ang, $
            xstyle=1, ystyle=1, zstyle=1, $
            zrange=[gauss_uval.plot_info.min,gauss_uval.plot_info.max], $
            charsize=1.5, zticks=4, zminor=4, title="Peak Fit"

wset, save
end

pro CImWin::ZoomBox, base_id
; this routine takes the drawn box and zooms to that size

; get the widget uvals
widget_control, base_id, get_uval=base_uval

self=*base_uval.self_ptr
xscale=self->GetXScale()
yscale=self->GetYScale()
im=*(self.p_ImObj)
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
x0=base_uval.zbox_p0[0]
x1=base_uval.zbox_p1[0]
y0=base_uval.zbox_p0[1]
y1=base_uval.zbox_p1[1]

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

; find which vector is longer, then zoom to that size
zoom = ((win_xs/double(box_xs)) < (win_ys/double(box_ys)))
zoom = (zoom < 128d)

; set the new zoom scales
self->SetXScale, zoom
self->SetYScale, zoom

; CODE TO MAKE AN INDEPENDENT ASPECT RATIO ZOOM
;    x_zoom = win_xs/float(box_xs)
;    x_zoom = (x_zoom < 128)
;    y_zoom = win_ys/float(box_ys)
;    y_zoom = (y_zoom < 128)
    ; set the new zoom scales
;    self->SetXScale, x_zoom
;    self->SetYScale, y_zoom

widget_control, base_id, set_uval=base_uval

self->DrawImage
self->UpdateText

end

pro CImWin::LoadFilter, base_id

; get the base uval
widget_control, base_id, get_uval=base_uval

; get filter object
FilterObj_ptr=self->GetFilterObj()
FilterObj=*FilterObj_ptr

; call filter method to induce pickfile, which also saves 
;the filename and previous pathname to member variables
FilterObj->FilterBrowse

; update the cimwin digital filter menu with the pathname

filename=FilterObj->GetFilename()
if (filename ne '') then begin
    ; read that file
    FilterObj->LoadFilter, filename
endif

end

pro CImWin::ApplyFilter, filterid, filename

im=*self.p_ImObj
im_xs=self.DispIm_xs
im_ys=self.DispIm_ys
im_zs=self->GetZMax()
disp_im_ptr=self->GetDispIm()
disp_im=*disp_im_ptr
scl_im=bytscl(disp_im, min=self->GetDispMin(), max=self->GetDispMax())
win_xs=self->GetXS()
win_ys=self->GetYS()

FilterObj_ptr=self->GetFilterObj()
FilterObj=*FilterObj_ptr


im_data_ptr=im->GetData()
im_data=*im_data_ptr

; only filter if the image has 3 dimensions
if (self.NAxis eq 3) then begin
    FilterObj->ApplyFilter, filterid, filename
endif else begin
    error=dialog_message('The image must have 3 axes to perform a digital filter.',  /error, $
                         dialog_parent=self.BaseId)
endelse

; check to see what the difference is between im and disp_im
; i think what to do is do the operation on im, and then call
; self->SetDispIm(), newDispIm - calculated display image

; apply interpolated filter to data cube
; redraw the cube

end

pro CImWin::FilterPlot, winbase_id, filterid

widget_control, winbase_id, get_uval=base_uval
filter_no=1

plotwin_obj=*self.p_PlotWin

plotwin_obj->DrawFilterPlot, filterid, self.p_Plotwin

end

pro CImWin::DrawPlot, base_id, type
; this routine will take info about a plot from this object and set it in the
; plot window object.  it will then draw the plot

widget_control, base_id, get_uval=base_uval

plot_win=*(self.p_PlotWin)

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
plot_win->SetXData_Range, [x0pix, x1pix]
plot_win->SetYData_Range, [y0pix, y1pix]

; check to see if the fix plot axes is set
xfixed=plot_win->GetXFixPRange()
yfixed=plot_win->GetYFixPRange()

if (xfixed eq 0) then begin
    plot_win->SetXRange, [x0pix, x1pix]
    plot_win->SetResetRanges, 1
endif
if (yfixed eq 0) then begin
    plot_win->SetYRange, [y0pix, y1pix]
    plot_win->SetResetRanges, 1
endif

; depending on type (passed in), draw appropriate plot
case type of
    'depth':plot_win->DrawDepthPlot
    'horizontal':plot_win->DrawHorizontalPlot
    'vertical':plot_win->DrawVerticalPlot
    'contour':plot_win->DrawContourPlot
    'surface':plot_win->DrawSurfacePlot
    'gaussian': begin
        plot_win->Draw2DGaussian, base_id
    end
    else:
endcase

end

pro CImWin::DrawDiagonalPlot, base_id
; this routine will take info about a plot from this object and set it in the
; plot window object.  it will then draw the plot

widget_control, base_id, get_uval=base_uval

plot_win=*(self.p_PlotWin)

; get regions of plot
x0=base_uval.diagonal_box_p0[0]
x1=base_uval.diagonal_box_p1[0]
y0=base_uval.diagonal_box_p0[1]
y1=base_uval.diagonal_box_p1[1]

x0pix=(x1 < x0)
x1pix=(x1 > x0)
y0pix=(y1 < y0)
y1pix=(y1 > y0)

; set values in plot window object
plot_win->SetXData_Range, [x0pix, x1pix]
plot_win->SetYData_Range, [y0pix, y1pix]
plot_win->SetXRange, [x0pix, x1pix]
plot_win->SetYRange, [y0pix, y1pix]
plot_win->SetResetRanges, 1

plot_win->DrawDiagonalPlot

end

pro CImWin::SetSlice, slicenumber
	widget_control, self.BaseId, get_uval=uval
	; Switch to 'Slice' mode and display a particular slice
	; check it's within range limits
	widget_control, uval.wids.cube_range_min, get_value=minval
	widget_control, uval.wids.cube_range_max, get_value=maxval
	slice = minval > slicenumber < maxval
	; set the slider
   	widget_control, uval.wids.cube_slider, set_value=slice
	; create and send a fake event to switch to 'Slice' mode
   	widget_control, uval.wids.cube_single_button, set_button=1
	clickevent = {top: self.baseId, id: uval.wids.cube_single_button, handler: ""}
	cimwin_cube_select_event, clickevent
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CImWin::MakeActive
widget_control, self.BaseId, get_uval=cimwin_uval
; make current window active by adding *'s to title
widget_control, self.BaseID, tlb_set_title=('* Active Window -'+self.title+'*')
; update the menu label
widget_control, cimwin_uval.wids.makewinact_id, set_value='Make Window Inactive'
end

pro CImWin::MakeInactive
widget_control, self.BaseId, get_uval=cimwin_uval
; make current window inactive by removing *'s to title
widget_control, self.BaseID, tlb_set_title=(self.title)
; update the menu label
widget_control, cimwin_uval.wids.makewinact_id, set_value='Make Window Active'
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

function CImWin::GetDWidth
return, self.dwidth
end

pro CImWin::SetDWidth, dwidth
self.dwidth=dwidth
end

function CImWin::GetImObj
return, self.p_ImObj
end

pro CImWin::SetImObj, newImObj
	ptr_free, self.p_ImObj
self.p_ImObj=newImObj
end

function CImWin::GetPlotWin
return, self.p_PlotWin
end

pro CImWin::SetPlotWin, newPlotWin
	ptr_free,self.p_PlotWin
self.p_PlotWin=newPlotWin
end

function CImWin::GetFilterObj
return, self.p_FilterObj
end

pro CImWin::SetFilterObj, newFilterObj
	ptr_free,self.p_FilterObj
self.p_FilterObj=newFilterObj
end

function CImWin::GetFitsHeditObj
return, self.p_FitsHeditObj
end

pro CImWin::SetFitsHeditObj, newFitsHeditObj
	ptr_free,self.p_FitsHeditObj
self.p_FitsHeditObj=newFitsHeditObj
end

function CImWin::GetDispIm
return, self.p_DispIm
end

pro CImWin::SetDispIm, newDispIm
	ptr_free, self.p_DispIm
self.p_DispIm=newDispIm
end

function CImWin::GetTitle
return, self.title
end

pro CImWin::SetTitle, title
self.title=title
end

function CImWin::GetDoAutoScale
return, self.DoAutoScale
end

pro CImWin::SetDoAutoScale, newDoAutoScale
self.DoAutoScale=newDoAutoScale
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

function CImWin::GetCollapse
return, self.collapse
end

pro CImWin::SetCollapse, newCollapse
self.collapse=newCollapse
end

function CImWin::GetFitType
return, self.fit_type
end

pro CImWin::SetFitType, newFitType
self.fit_type=newFitType
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
self.NAxis=newNAxis
end

function CImWin::GetResetZ
return, self.ResetZ
end

pro CImWin::SetResetZ, newResetZ
self.ResetZ=newResetZ
end

function CImWin::GetAxesMinMax
return, self.axes_minmax
end

pro CImWin::SetAxesMinMax, newaxes_minmax
self.axes_minmax=newaxes_minmax
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

function CImWin::GetUnravelLocations
return, self.p_unraveled
end

pro CImWin::SetUnravelLocations, newUnravelLocations
self.p_unraveled=newUnravelLocations
end

function CImWin::GetDef_Zmag
return, self.Def_Zmag
end

pro CImWin::SetDef_Zmag, newDef_Zmag
self.Def_Zmag=newDef_Zmag
end

function CImWin::GetDefItime
return, self.Def_Itime
end

pro CImWin::SetDefItime, newDef_Itime
self.Def_Itime=newDef_Itime
end

function CImWin::GetPhotometryInnerAn
return, self.Photometry_Inner_An
end

pro CImWin::SetPhotometryInnerAn, newPhotometry_Inner_An
self.photometry_Inner_An=newPhotometry_Inner_An
end

function CImWin::GetPhotometryOuterAn
return, self.Photometry_Outer_An
end

pro CImWin::SetPhotometryOuterAn, newPhotometry_Outer_An
self.photometry_Outer_An=newPhotometry_Outer_An
end

function CImWin::GetPhotometryAper
return, self.Photometry_Aper
end

pro CImWin::SetPhotometryAper, newPhotometry_Aper
self.photometry_Aper=newPhotometry_Aper
end

function CImWin::GetStrehlApSize
return, self.strehl_apsize
end

pro CImWin::SetStrehlApSize, newstrehl_apsize
self.strehl_apsize=newstrehl_apsize
end

function CImWin::GetMovieChanStart
return, self.movie_chan_start
end

pro CImWin::SetMovieChanStart, newMovieChanStart
self.movie_chan_start=newMovieChanStart
end

function CImWin::GetMovieChanStop
return, self.movie_chan_stop
end

pro CImWin::SetMovieChanStop, newMovieChanStop
self.movie_chan_stop=newMovieChanStop
end

function CImWin::GetMovieMag
return, self.movie_mag
end

pro CImWin::SetMovieMag, newMovieMag
self.movie_mag=newMovieMag
end

function CImWin::GetMovieXSpatBin
return, self.movie_xspat_bin
end

pro CImWin::SetMovieXSpatBin, newMovieXSpatBin
self.movie_xspat_bin=newMovieXSpatBin
end

function CImWin::GetMovieYSpatBin
return, self.movie_yspat_bin
end

pro CImWin::SetMovieYSpatBin, newMovieYSpatBin
self.movie_yspat_bin=newMovieYSpatBin
end

function CImWin::GetMovieBinSize
return, self.movie_bin_size
end

pro CImWin::SetMovieBinSize, newMovieBinSize
self.movie_bin_size=newMovieBinSize
end

function CImWin::GetMovieBinStep
return, self.movie_bin_step
end

pro CImWin::SetMovieBinStep, newMovieBinStep
self.movie_bin_step=newMovieBinStep
end

function CImWin::GetMovieMinValue
return, self.movie_min_value
end

pro CImWin::SetMovieMinValue, newMovieMinValue
self.movie_min_value=newMovieMinValue
end

function CImWin::GetMovieMaxValue
return, self.movie_max_value
end

pro CImWin::SetMovieMaxValue, newMovieMaxValue
self.movie_max_value=newMovieMaxValue
end

function CImWin::GetBoxCar
return, self.boxcar
end

pro CImWin::SetBoxCar, newboxcar
self.boxcar=newboxcar
end

pro CImWin::Setdrawaxes, newdrawaxes
	;update menu text
	possiblelabels = ["Draw Axes Labels", "Remove Axes Labels"]
	widget_control, self.BaseId, get_uval=cimwin_uval
	widget_control, cimwin_uval.wids.menu_drawaxes_id, set_value=possiblelabels[newdrawaxes]
	;update the axes
	self.drawaxes=newdrawaxes
	self->DrawImage
end


function CImWin::GetCurrentDisplay
	return, self.current_display
end

pro CImWin::SetCurrentDisplay, new_current_display, update=update
	self.current_display=new_current_display
	; MDP addition - merged in SetCurrentDisplayUpdate
	; which used to be a seperate routine but was always
	; called immediately after this one, so we might as well merge them.
	self.current_display_update=keyword_set(update)

	widget_control, self.BaseId, get_uval=cimwin_uval
	; FIXME TODO wow the following seems completely wrong!! -MDP
	if (self.current_display eq 'As DN/s') then begin
	    ; update the menu label
	    widget_control, cimwin_uval.wids.displayasdn_id, set_value='As Total DN'
	endif else begin
	    ; update the menu label
	    widget_control, cimwin_uval.wids.displayasdn_id, set_value='As DN/s'
	endelse

end

pro CImWin::CancelScrollSlices
	self.scroll_slices_counter = 10000 ; so we're way above the allowed limit and the loop will end.
	widget_control, self.BaseId, get_uval=uval
	widget_control, uval.wids.scroll_slices_id, set_value='Scroll through All Slices'
end


pro CImWin::ScrollSlicesNext, timer_widget
	i = self.scroll_slices_counter
	widget_control, self.BaseId, get_uval=uval
	widget_control, uval.wids.cube_range_max, get_value=maxval & maxval = fix(maxval[0])
	if i le maxval then begin
  		widget_control, uval.wids.cube_slider, set_value=i
		self->SetZMin, i
        	self->SetZMax, i
        	; redraw
        	self->SetDoAutoScale, 0.
        	self->UpdateDispIm
        	self->DrawImage, /noerase
		; and after a short delay call the next one.
		self.scroll_slices_counter++
    		WIDGET_CONTROL, timer_widget, TIMER=0.1
	endif else begin
		widget_control, uval.wids.scroll_slices_id, set_value='Scroll through All Slices'
	endelse	
end

pro CImWin::ScrollSlicesStart, timer_widget
	widget_control, self.BaseId, get_uval=uval
	widget_control, uval.wids.scroll_slices_id, set_value='Cancel Scrolling through All Slices'
	widget_control, uval.wids.cube_slider, get_value=startindex
	self.scroll_slices_counter=startindex
	self->ScrollSlicesNext, timer_widget
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro cimwin__define

; No allocating of heap variables here!!
; allocate a new pointer for the instance of an image object
p_ImObj=ptr_new()
; allocate a pointer for the displayed image
p_DispIm=ptr_new()
; allocate a pointer for the plot window
p_PlotWin=ptr_new()
; make a instances of the cimwin objects
cprint_ptr=ptr_new()
cdfilter_ptr=ptr_new()
cfitshedit_ptr=ptr_new()
unraveled_locations_ptr=ptr_new()

        ; make a structure that will store information for an instance
        ; of the CImWin object
struct={CImWin, $
        ParentBaseId:0L, $      ; base id of window parent
        BaseId:0L, $            ; wid of window base
        DrawId:0L, $            ; wid of draw window
        DrawIndex:0L, $         ; index of draw window
        title:'', $             ; title of window
        DispScale:'', $         ; Scale for the display
        xs:0L, $                ; window xsize
        ys:0L, $                ; window ysize
        dwidth:1., $            ; width of the diagonal box
        p_ImObj:p_ImObj, $      ; pointer to image object
        p_PlotWin:p_PlotWin, $  ; pointer to Plot Window object
        p_PrintObj:cprint_ptr, $ ; pointer to the print object
        p_FilterObj:cdfilter_ptr, $ ; pointer to the filter object
        p_FitsHeditObj:cfitshedit_ptr, $ ;pointer to the fits header editor object
        XScale:1.d, $           ; X zoom factor
        YScale:1.d, $           ; Y zoom factor
        ZMin:0, $               ; Lower limit of slice
        ZMax:0, $               ; Upper limit of slice
        DispMin:0.0, $          ; Min val for color stretch
        DispMax:256.0, $        ; max val for color stretch
        collapse:0, $           ; value indicates cube collapse type
        fit_type:0, $      ; fit type: gauss, lorentzian, moffat 
        AxesOrder:indgen(3), $  ; Order of axes
        NAxis:2, $              ; Number of axes in image
		drawaxes:1, $			; label the axes in the plot [ADDED BY MARSHALL PERRIN]
        p_DispIm:p_DispIm, $    ; pointer to displayed image
        DoAutoScale:1, $        ; flag for doing autoscale
        ResetZ:0, $             ; flag for resetting slice
        axes_minmax:fltarr(3,2), $ ; array that holds the Z min and max for each axis
        DispIm_xs:1 , $         ; x size of image displayed
        DispIm_ys:1, $          ; y size of image displayed
        CurIm_s:[1, 1, 1], $    ; current dimensions of image
        p_unraveled:unraveled_locations_ptr, $ ; pointer to unraveled data paramters
        def_zmag:1.0, $         ; initial zmag for photometry
        def_itime:1.0, $        ; initial itime for photometry
        photometry_inner_an:1.0, $ ; initial inner annulus for photometry
        photometry_outer_an:2.0, $ ; initial outer annulus for photometry
        photometry_aper:1.0, $ ; initial aperture radius for photometry
        strehl_apsize:4.0, $   ; initial strehl aperture size (pix)
        movie_chan_start:0., $  ; movie starting channel 
        movie_chan_stop:0., $   ; movie stopping channel 
        movie_mag:0., $  ; movie magnification
        movie_xspat_bin:0., $  ; movie x spatial bin
        movie_yspat_bin:0., $  ; movie y spatial bin
        movie_bin_size:0., $    ; movie bin size
        movie_bin_step:0., $    ; movie bin step
        movie_min_value:0., $   ; movie minimum value
        movie_max_value:0., $    ; movie maximum value
        boxcar:1, $             ; set the boxcar size for 3d images
	scroll_slices_counter: 0, $  ;should we bail out from the scrolling?
        current_display:'', $    ; 'As Total DN' or 'As DN/s'
        current_display_update:1. $    ; Toggle to update DN or DN/s
       }

end
