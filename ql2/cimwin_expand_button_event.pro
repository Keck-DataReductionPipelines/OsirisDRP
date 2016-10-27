pro cimwin_expand_button_event, event

widget_control, event.top, get_uval=uval

; change the value of wide flag
uval.wide=(uval.wide ne 1)

; change label of expand button
values=['More', 'Less']
widget_control, event.id, set_value=values[uval.wide]

; map hidden base
widget_control, uval.wids.bottom_base, map=uval.wide

; calculate the size of the imwin components
base_info=widget_info(event.top, /geometry)
menu_info=widget_info(uval.wids.menu, /geometry)
draw_info=widget_info(uval.wids.draw, /geometry)
top_info=widget_info(uval.wids.top_base, /geometry)
bottom_info=widget_info(uval.wids.bottom_base, /geometry)

; get the x size of the widget
widbase_xsize=draw_info.xsize+(2*base_info.xpad)

; get the y size of the widget
widbase_ysize=(menu_info.ysize+draw_info.ysize+top_info.ysize+ $
               (top_info.ypad))+(bottom_info.ysize+ $
               (2*bottom_info.ypad))*uval.wide+(6*base_info.ypad)
   
widget_control, event.top, set_uval=uval

cimwin_resize_draw, event.top, widbase_xsize, widbase_ysize

end
