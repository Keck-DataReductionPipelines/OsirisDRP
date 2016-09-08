pro ql_keyboardshortcuts_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=conbase_uval
conbase_uval.exist.shortcuts=0L
widget_control, uval.wids.base_id, set_uval=conbase_uval
widget_control, event.top, /destroy

end

pro ql_keyboardshortcuts, conbase_id

widget_control, conbase_id, get_uval=conbase_uval

if !VERSION.RELEASE GE '6.1' then begin
    base=widget_base(TITLE = 'Keyboard Shortcuts', group_leader=conbase_id, /col, $
                     /tlb_kill_request_events)
    shortcutbase=widget_base(base, /col, /base_align_right)
    
    xsize=200

    ; label the widget
    pan=widget_label(shortcutbase, xoff = 220, yoff=0, $
                     value='Pan <p>', xsize = xsize)
    recenter=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Recenter <m>', xsize = xsize)
    zoom_box=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Zoom Box <z>', xsize = xsize)
    zoom_in=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                         value='Zoom In <i>', xsize = xsize)
    zoom_out=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Zoom Out <o>', xsize = xsize)
    redisplay=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                           value='Redisplay Image <r>', xsize = xsize)
    linear=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                        value='Linear Stretch <l>', xsize = xsize)
    negative=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Negative Stetch <n>', xsize = xsize)
    histeq=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                        value='HistEq Stretch <q>', xsize = xsize)
    statistics=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                            value='Statistics <s>', xsize = xsize)
    photometry=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                            value='Photometry <a>', xsize = xsize)
    strehl=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                        value='Strehl <t>', xsize = xsize)
    peakfit=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                         value='Peak Fit <f>', xsize = xsize)
    unravel=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                         value='Unravel <u>', xsize = xsize)
    depth=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                       value='Depth Plot <d>', xsize = xsize)
    horizontal=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                            value='Horizontal Cut <h>', xsize = xsize)
    vertical=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Vertical Cut <v>', xsize = xsize)
    diagonal=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                          value='Diagonal Cut <g>', xsize = xsize)
    surface=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                         value='Surface Plot <e>', xsize = xsize)
    contour=widget_label(shortcutbase, xoff = 220, yoff = 0, $
                         value='Contour Plot <c>', xsize = xsize)
    
    ; Close and Create buttons
    buttonbase=widget_base(base, /row, /align_center)
    closebutton=widget_button(buttonbase, value = 'Close')
    
    ; set uval
    wids = {base_id:conbase_id}
    
    uval={base_id:conbase_id, $
          wids:wids $
         }
    
    ; realize widget
    widget_control, base, /realize, set_uvalue=uval

    ; register the statistics events with xmanager
    xmanager, 'ql_keyboardshortcuts_tlb', base, /just_reg, /no_block, $
      cleanup='ql_subbase_death'
    xmanager, 'ql_keyboardshortcuts', closebutton, /just_reg, /no_block

    ; register existence of base
    conbase_uval.exist.shortcuts=base
    widget_control, uval.wids.base_id, set_uval=conbase_uval

endif else begin
    ; let the user know that keyboard shorcuts aren't supported work
    message=['Keyboard shortcuts are only supported',' in IDL v6.1 and greater.']
    answer=dialog_message(message, dialog_parent=conbase_id, /error)
    return
endelse

end


