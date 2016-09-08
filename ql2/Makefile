###############################################################################
#+
#  Module:	$KSSDIR/qlook2/Makefile
#
#  Revisions:   
#
#  Author:	Jason Weiss / Michael McElwain
#
#  Date:	2005/03/23
#
#  Description:	Makefile for Quicklook2
#-
###############################################################################

#  Include files.

INCLUDE	= 

#  C source and object files.
CFLAGS  = 

SOURCE	= 
OBJECT	= 

DIRS	= configs \
	  idl_downloads \
	  osiris

#  Files to make are ...
FILES	= 

#  Files to release are ...
RELFILES = run_iql2 \
           run_fql2 \
	   run_oql2 \
	   run_ql2 \
	   run_sql2

RELDAT   = 
RELPRO   = cconfigs__define.pro \
	   cdfilter__define.pro \
	   cfitshedit__define.pro \
	   cfitshedit_base_event.pro \
	   cfitshedit_find_button_event.pro \
	   cfitshedit_header_list_event.pro \
	   cfitshedit_insert_button_event.pro \
	   cfitshedit_line_set_button_event.pro \
	   cfitshedit_movedown_button_event.pro \
	   cfitshedit_movetobottom_button_event.pro \
	   cfitshedit_movetotop_button_event.pro \
	   cfitshedit_moveup_button_event.pro \
	   cfitshedit_quit_button_event.pro \
	   cfitshedit_remove_button_event.pro \
	   cfitshedit_save_button_event.pro \
	   cfitshedit_saveas_button_event.pro \
	   cimage__define.pro \
	   cimwin__define.pro \
	   cimwin_accelerators_event.pro \
	   cimwin_browse_button_event.pro \
	   cimwin_center_event.pro \
	   cimwin_close.pro \
	   cimwin_collapse_list_event.pro \
           cimwin_cube_boxcar_event.pro \
	   cimwin_cube_select_event.pro \
	   cimwin_cube_slice_event.pro \
	   cimwin_dim_list_event.pro \
	   cimwin_do_center.pro \
	   cimwin_do_zbox.pro \
	   cimwin_draw_event.pro \
	   cimwin_expand_button_event.pro \
	   cimwin_ext_list_event.pro \
	   cimwin_filter_apply_event.pro \
	   cimwin_filter_base_event.pro \
	   cimwin_filter_browse_event.pro \
	   cimwin_filter_button_event.pro \
	   cimwin_filter_display_event.pro \
	   cimwin_fit_list_event.pro \
	   cimwin_gauss_base_event.pro \
	   cimwin_gauss_button_event.pro \
	   cimwin_gauss_plot_event.pro \
	   cimwin_gauss_range_event.pro \
	   cimwin_independent_zoom_event.pro \
	   cimwin_makemovie_base_event.pro \
	   cimwin_makemovie_button_event.pro \
	   cimwin_makemovie_parameters_event.pro \
	   cimwin_menu_event.pro \
	   cimwin_photometry_base_event.pro \
	   cimwin_photometry_button_event.pro \
	   cimwin_photometry_parameters_event.pro \
	   cimwin_print_buttons_event.pro \
	   cimwin_print_toggle_event.pro \
	   cimwin_ps_current.pro \
	   cimwin_recalcgauss_button_event.pro \
	   cimwin_recalcstat_button_event.pro \
	   cimwin_recenter_event.pro \
	   cimwin_resize_draw.pro \
	   cimwin_resize_event.pro \
	   cimwin_rotate_event.pro \
	   cimwin_rotate_tlb_event.pro \
	   cimwin_shift_event.pro \
	   cimwin_stat_base_event.pro \
	   cimwin_stat_button_event.pro \
	   cimwin_stat_range_event.pro \
	   cimwin_strehl_base_event.pro \
	   cimwin_strehl_button_event.pro \
	   cimwin_strehl_parameters_event.pro \
           cimwin_stretch_button_event.pro \
	   cimwin_tlb_event.pro \
	   cimwin_unravel_base_event.pro \
	   cimwin_unravel_button_event.pro \
	   cimwin_zbox_event.pro \
	   cimwin_zoom_event.pro \
	   cmps_form.pro \
	   cplotwin__define.pro \
	   cplotwin_base_event.pro \
	   cplotwin_close.pro \
	   cplotwin_draw_event.pro \
	   cplotwin_dwidth_set_event.pro \
	   cplotwin_fit_list_event.pro \
	   cplotwin_gauss_button_event.pro \
	   cplotwin_menu_axes.pro \
	   cplotwin_menu_event.pro \
	   cplotwin_menu_line.pro \
	   cplotwin_menu_titles.pro \
	   cplotwin_print.pro \
	   cplotwin_recalcgauss_button_event.pro \
	   cplotwin_type_event.pro \
	   cplotwin_xdata_set_event.pro \
	   cplotwin_xfix_plot_event.pro \
	   cplotwin_xlog_set_event.pro \
	   cplotwin_xrange_set_event.pro \
	   cplotwin_ydata_set_event.pro \
	   cplotwin_yfix_plot_event.pro \
	   cplotwin_ylog_set_event.pro \
	   cplotwin_yrange_set_event.pro \
	   cpolling__define.pro \
	   cpolling_server_event.pro \
	   cprint__define.pro \
	   cprint_cmps_form_box_events.pro \
	   cprint_cmps_form_event.pro \
	   cprint_cmps_form_grow_box_event.pro \
	   cprint_cmps_form_move_box_event.pro \
	   cprint_cmps_form_null_events.pro \
	   cprint_cmps_form_num_events.pro \
	   cprint_cmps_form_predef_events.pro \
	   cprint_cmps_form_select_file_event.pro \
	   cw_label.pro \
	   cw_pdmenu.pro \
	   dialog_print.pro \
	   extast3.pro \
	   get_widget_size.pro \
	   iqlook2_startup.pro \
           fqlook2_startup.pro \
	   oqlook2_startup.pro \
	   osiris_effwave.pro \
	   osiris_getfilename.pro \
	   osiris_getfilename_serveronly.pro \
	   osiris_isframeready.pro \
	   osiris_isframeready_serveronly.pro \
	   osiris_openfiles.pro \
	   osiris_pscale.pro \
           osirispsf_ql2.pro \
	   osirispupil_ql2.pro \
	   osiris_spec_effwave.pro \
	   osirisstrehl_ql2.pro \
	   osiris_testserver.pro \
	   osiris_calc_pa.pro \
	   printa2ps.pro \
	   ql.pro \
	   ql_aper.pro \
	   ql_aperture.pro \
	   ql_buffer_list.pro \
	   ql_check_permission.pro \
	   ql_closewindows.pro \
	   ql_conbase.pro \
	   ql_conbase_cpoll_timer_event.pro \
	   ql_conbase_resize_event.pro \
	   ql_conbase_tlb_event.pro \
	   ql_conmath.pro \
	   ql_conmath_tlb_event.pro \
	   ql_conmemory.pro \
	   ql_conmenu_event.pro \
	   ql_conopen.pro \
	   ql_conoptions.pro \
           ql_conoptions_base_event.pro \
	   ql_conpolling.pro \
	   ql_conpolling_base_event.pro \
	   ql_conpolling_loop.pro \
	   ql_conprint.pro \
	   ql_conprint_exe.pro \
	   ql_conquit.pro \
	   ql_conreduce.pro \
	   ql_conreduce_tlb_event.pro \
	   ql_conupdate_recent_file_list.pro \
	   ql_create_cimage.pro \
	   ql_display_new_image.pro \
	   ql_file_browse_event.pro \
	   ql_file_search.pro \
	   ql_filename_box_event.pro \
	   ql_fonts.pro \
	   ql_get_extension.pro \
	   ql_get_namenext.pro \
	   ql_getfilename.pro \
	   ql_getpath.pro \
	   ql_imwinobj_add.pro \
	   ql_imwinobj_remove.pro \
	   ql_keyboardshortcuts.pro \
	   ql_keyboardshortcuts_tlb_event.pro \
	   ql_load_inst_cfg.pro \
	   ql_load_setup_cfg.pro \
	   ql_make_window_active.pro \
	   ql_openfile.pro \
	   ql_readfits.pro \
	   ql_refresh_all.pro \
	   ql_subbase_death.pro \
	   ql_update_buffer_list.pro \
	   ql_writecheck.pro \
	   qlook2_startup.pro \
	   qlook2_windows_startup.pro \
	   read_data.pro \
	   remed.pro \
	   rgb.pro \
	   sqlook2_startup.pro \
	   xyz2adl.pro \

PROSUB = qlook2

override SYSNAM = kss/qlook2/
override VERNUM = 2.2 

#  Include general make rules (use /etc if no environment variable).

include $(KROOT)/etc/config.mk
