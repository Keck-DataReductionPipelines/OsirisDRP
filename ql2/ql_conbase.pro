;+
; NAME: ql_conbase
;
; PURPOSE: control base for qlook2
;
; CALLING SEQUENCE: ql_conbase, [filename,] xwin
;
; INPUTS:
;
; OPTIONAL INPUTS: filename is the path and filename of the file being
;                           displayed.
;
; OPTIONAL KEYWORD INPUTS: /xwin is used to determine window backing.
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 16DEC2002 - MWM: added comments.
;   2007-07-03  MDP: Fix multiple pointer leaks on startup.
;
;-

pro ql_conbase, filename=filename, current_os=current_os, xwin=xwin, configs=configs

; forces idl to keep track of winbacking if xwin is 1,
; otherwise it leaves it up to the window manager
if keyword_set(xwin) then win_backing=2 else win_backing=1

; gets the current directory
cd, '.', current=cur

;sets the font
if (!version.os_family eq 'unix') then begin
    font='-adobe-helvetica-bold-r-normal--17-120-100-100-p-92-iso8859-1'
endif else begin
    font=1
endelse

; get fonts
@ql_fonts.pro

; default window size
xsize=150
ysize=150

; definition of the pulldown menu structure
junk={cw_pdmenu_s, flags:0, name:''}

; description of the control widget menu in qlook2
ql_conmenu_desc=[{cw_pdmenu_s, 1, 'File'}, $
        {cw_pdmenu_s, 0, 'Open...'}, $
        {cw_pdmenu_s, 0, 'Select QL2 Setup'}, $
        {cw_pdmenu_s, 0, 'Select Color Table'}, $                 
        {cw_pdmenu_s, 1, 'Recent Files'}, $
        {cw_pdmenu_s, 0, 'None'}, $
        {cw_pdmenu_s, 0, 'None'}, $
        {cw_pdmenu_s, 0, 'None'}, $
        {cw_pdmenu_s, 2, 'None'}, $
        {cw_pdmenu_s, 0, 'Options...'}, $
        {cw_pdmenu_s, 0, 'Polling...'}, $
;        {cw_pdmenu_s, 0, 'Show Buffers...'}, $
        {cw_pdmenu_s, 0, 'Close All Windows'}, $
        {cw_pdmenu_s, 2, 'Quit'}, $
        {cw_pdmenu_s, 1, 'Math'}, $
        {cw_pdmenu_s, 2, 'Arithmetic...'}, $
;        {cw_pdmenu_s, 0, 'Arithmetic...'}, $
;        {cw_pdmenu_s, 2, 'Reduce...'}, $
        {cw_pdmenu_s, 3, 'Help'}, $
        {cw_pdmenu_s, 0, 'Online Help...'}, $
        {cw_pdmenu_s, 0, 'About...'}, $
        {cw_pdmenu_s, 0, 'Keyboard Shortcuts'}, $
        {cw_pdmenu_s, 2, 'Memory Usage'} $
       ]
; keeps track of the recent files used
recent_file_index=(where(ql_conmenu_desc.name eq 'Recent Files'))[0]+2
recent_file_list=ql_conmenu_desc[recent_file_index:recent_file_index+3].name

; creates the parent control base widget, with the menu bar and draw window
; as children
ql_conbase=widget_base(title='QL2v4.1', mbar=ql_conbase_mbar, $
                       /tlb_size_events, /tlb_kill_request_events, /col, $
                       resource_name='ql2_conbase')
ql_conmenu=cw_pdmenu(ql_conbase_mbar, ql_conmenu_desc, /mbar, /return_name, $
    /help)
ql_condraw=widget_draw(ql_conbase, xs=xsize, ys=ysize, retain=win_backing)

; instantiate a new cconfig object to be used for the duration of the ql2
cconfigs_obj=obj_new('cconfigs', wid_leader=ql_conbase)
cconfigs_ptr=ptr_new(cconfigs_obj)

; set the cconfig object configuration defaults
;configs_obj->SetPrintDefaults, self.ParentBaseId

; instantiate a new polling object to be used for the duration of the ql2
cpolling_obj=obj_new('cpolling', wid_leader=ql_conbase)
cpolling_ptr=ptr_new(cpolling_obj)

; allocate a pointer to an array that holds all the current opened imwins
current_cimwins=ptr_new()

; widget identification structure used in the control functions
wids={  base:ql_conbase, $
        menu:ql_conmenu, $
        draw:ql_condraw $
     }

exist={ options:0L, $
        polling:0L, $
        reduce:0L, $
        arithmetic:0L, $
        buffer_list:0L, $
        shortcuts:0L, $
        help:0L $
     }

; user values structure used in the control functions
uval={  wids:wids, $
        exist:exist, $
        current_os:current_os, $
        win_backing:win_backing, $
        xs:xsize, $
        ys:ysize, $
        printer_name: '', $
        font: font, $
        recent_file_list:recent_file_list, $
        recent_file_index:recent_file_index, $
        current_data_directory: cur, $
        last_file: '', $
        last_sky_file: '', $
        last_flat_file: '', $
        last_map_file: '', $
        got_handle:0L, $
        dragged_text: '', $
        activewin:0, $
        newwin:0, $
        newwin_active:1, $
        newwin_defaults:1, $
        unravel:0, $
        actwin_xs:0., $
        actwin_ys:0., $
        actwin_diagonal:0., $
        actwin_xbase_size:0., $
        actwin_ybase_size:0., $
        actwin_xpad:0., $
        actwin_ypad:0., $
        actwin_xscale:0., $
        actwin_yscale:0., $
        actwin_dispmin:0., $
        actwin_dispmax:0., $
        actwin_dispscl:'', $
        actwin_tv_p0:[0,0], $
        actwin_axesorder:indgen(3), $
        actwin_num_axes:0L, $
        actwin_zmin:0L, $
        actwin_zmax:0L, $
        actwin_collapse:0L, $
        actwin_wide:0, $
        actwin_dns:'', $
        actwin_cube_range:0L, $
        actwin_cube_range_min:0L, $
        actwin_cube_range_max:0L, $
        actwin_cube_curmin:0L, $
        actwin_cube_curmax:0L, $
        actwin_cube_slider:0., $
        actwin_cube_slice_box:0L, $
        new_image:0, $
        cconfigs_ptr:cconfigs_ptr, $
        cpolling_ptr:cpolling_ptr, $
        p_curwin:ptr_new(), $
		buffer_list: ptrarr(4), $ ; don't allocate! these just get lost...
        ;buffer_list: [ptr_new(12, /allocate_heap), $
                     ;ptr_new(13, /allocate_heap), $
                     ;ptr_new(14, /allocate_heap), $
                     ;ptr_new(15, /allocate_heap)], $
        memory_ptr:ptr_new(''), $
        buffer_lock:bytarr(4), $
        current_imwins:current_cimwins $
     }

; realizes widget hierarchies, sets conbase uval
widget_control, ql_conbase, set_uval=uval, /realize

; disable recent file menu options (since no files have been used yet)
; note - this may change because in the future, we may save
; recent files lists to disk in a data file.
widget_control, ql_conmenu+recent_file_index, sensitive=0
widget_control, ql_conmenu+recent_file_index+1, sensitive=0
widget_control, ql_conmenu+recent_file_index+2, sensitive=0
widget_control, ql_conmenu+recent_file_index+3, sensitive=0

; registers ql_conmenu with the event handler
xmanager, 'ql_conmenu', ql_conmenu, /just_reg, /no_block

;  registers resize events with the event handler
xmanager, 'ql_conbase_tlb', ql_conbase, /just_reg, /no_block

; if a config file is included then update the member variables
if keyword_set(configs) then begin
    if configs ne '' then begin
        ; load configuration structure
        config_valid=cconfigs_obj->CheckConfigFile(configs)
        if config_valid then begin
            cconfigs_obj->LoadConfigFile, configs
            cconfigs_obj->UpdateParams
        endif
    endif
endif

end
