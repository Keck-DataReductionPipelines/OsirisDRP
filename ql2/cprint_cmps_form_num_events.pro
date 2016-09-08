;
; cmps_form_NUMEVENTS
;
; Events sent to the numeric text field widgets are sent here.  We
; harvest the data values from the text field and update the screen.
;
pro CPrint_cmps_form_Num_Events, event

   ; If an event comes here, read the offsets and sizes from the
   ; form and draw the appropriately sized box in the draw widget.

Widget_Control, event.top, Get_UValue= info, /No_Copy

  self=*info.self_ptr

   ; Get current values for offset and sizes

Widget_Control, info.idxsize, Get_Value=xsize
Widget_Control, info.idysize, Get_Value=ysize
Widget_Control, info.idxoff, Get_Value=xoff
Widget_Control, info.idyoff, Get_Value=yoff

xsize = xsize[0]
ysize = ysize[0]
xoff = xoff[0]
yoff = yoff[0]

if info.preserve_aspect EQ 1 then begin
    if event.id EQ info.idysize then xsize = ysize / info.aspect $
    else                             ysize = xsize * info.aspect
endif

; Fold this information into the "info" structure
self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, xoff=xoff, yoff=yoff

; Update form and redraw sample box
self->cmps_form_draw_form, info

; Put the info structure back into the top-level base

Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************
