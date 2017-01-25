pro cimwin_resize_draw, imwin_id, imwin_nxsize, imwin_nysize

; get uval
widget_control, imwin_id, get_uval=uval
base_info=widget_info(imwin_id, /geometry)
menu_info=widget_info(uval.wids.menu, /geometry)

; adjust the size of the imwin widget to account for the
; widget padding
imwin_nxsize=(imwin_nxsize-(2*base_info.xpad))
imwin_nysize=(imwin_nysize-(6*base_info.ypad)-menu_info.ysize)

; get the screen x and y sizes 
scr_xsize = uval.scr_xsize
scr_ysize = uval.scr_ysize

; calculate the size of the controls
top_info=widget_info(uval.wids.top_base, /geometry)
bottom_info=widget_info(uval.wids.bottom_base, /geometry)

cntrl_ysize=(top_info.ysize+(2*top_info.ypad)) +  $    
  (bottom_info.ysize+(2*bottom_info.ypad))*uval.wide

; calculate the maximum ysize of the draw window
max_yimsize = scr_ysize - cntrl_ysize

; calculate the size of the draw window
im_xsize = imwin_nxsize
im_ysize = imwin_nysize - cntrl_ysize

; calculate the minimum xsize of the base, by finding the largest
; part of the control base

; put constraints on the xsize of the base
new_base_xs = (im_xsize > uval.min_wid_xsize)
; put constraints on the xsize of the image
im_xsize = (new_base_xs > im_xsize < scr_xsize)

; put constraints on the ysize of the image
im_ysize = (32 > im_ysize < max_yimsize)
; put constraints on the ysize of the base
new_base_ys = im_ysize + cntrl_ysize

; update the size of the draw window
widget_control, uval.wids.draw, xsize=im_xsize
widget_control, uval.wids.draw, ysize=im_ysize

; set the size of the draw window in the uval
uval.xs=im_xsize
uval.ys=im_ysize

; set the size of the draw window in the instance
cimwin=*uval.self_ptr
cimwin->SetXS, im_xsize
cimwin->SetYS, im_ysize

; save the size of the current image window for the next zoom calculation
uval.last_winxs=im_xsize
uval.last_winys=im_ysize

; update the uval settings
widget_control, imwin_id, xsize=new_base_xs, ysize=new_base_ys
widget_control, imwin_id, set_uvalue=uval

end
