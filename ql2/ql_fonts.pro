; +
; NAME: ql_fonts
;       this file is to be added to cimwin__define.pro by using an @ call
;
; PURPOSE: create a centrally located way to control the fonts used in ql2
;
; CALLING SEQUENCE: @ql_fonts
;
; INPUTS: 
;
; OPTIONAL INPUTS: 
;                  
; OPTIONAL KEYWORD INPUTS: 
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 24FEB2003 - MWM: added comments.
; - 

; determine font based on platform
case !version.os_family of
	'unix': begin
		font1='-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1'
	end
	'Windows': font1=1
	'vms':
	'macos':
	else: begin
		print, 'OS ', !version.os_family, 'not recognized.'
		exit
	end
endcase

ql_fonts={ $
           conbase:{$
                     status_label: font1 $
                   }, $
           cimwin:{ $
                    menu: font1, $
                    x_label: font1, $
                    x_pos: font1, $
                    y_label: font1, $
                    y_pos: font1, $
                    val_label: font1, $
                    val_val: font1, $
                    datanum_val: font1, $
                    pmode_val:font1, $
                    top_zoom_minus:font1, $
                    top_zoom_plus:font1, $
                    top_one2one:font1, $
                    top_zoom_fit:font1, $
                    zoom_xscl_label: font1, $
                    zoom_xscl_val: font1, $
                    zoom_yscl_label: font1, $
                    zoom_yscl_val: font1, $
                    stretch_min_title: font1, $
                    stretch_min_val: font1, $
                    stretch_max_title: font1, $
                    stretch_max_val: font1, $
                    stretch_apply: font1, $
                    expand: font1, $
                    extension_list: font1, $
                    collapse_list: font1, $
                    xdim_list: font1, $
                    xzoom_buttons: font1, $
                    ydim_list: font1, $
                    yzoom_buttons: font1, $
                    recenter_button: font1, $
                    center_button: font1, $
                    zbox_button: font1, $
                    aspect_button: font1, $
                    cube_curmin_label: font1, $
                    cube_curmin_val: font1, $
                    cube_curmax_label: font1, $
                    cube_curmax_val: font1, $
                    cube_curzs_label: font1, $
                    cube_curzs_val: font1, $
                    cube_lambda_label: font1, $
                    cube_lambda_val: font1, $
                    cube_range_button: font1, $
                    cube_range_min_title: font1, $
                    cube_range_min_value: font1, $
                    cube_range_max_title: font1, $
                    cube_range_max_value: font1, $
                    cube_range_apply: font1, $
                    cube_slice_box_title: font1, $
                    cube_slice_box_value: font1, $
                    cube_slice_box_apply: font1, $
                    cube_single_button: font1, $
                    cube_slider: font1 $
                  } $
         }

