; 
; Buttondown events sent to this procedure at first.  This is sets up
; the initial move/drag elements and hands off the events to the more
; specialized procedures cmps_form_grow_box and cmps_form_move_box above.
;
pro CPrint_cmps_form_Box_Events, event

  ; Get info structure out of TLB
  Widget_Control, event.top, Get_UValue=info, /No_Copy
  self=*info.self_ptr

  whatButtonType = self->cmps_form_What_Button_Type(event)
  IF whatButtonType NE 'DOWN' THEN begin
      widget_control, event.top, set_uvalue=info, /no_copy
      Return
  endif

  whatButtonPressed = self->cmps_form_What_Button_Pressed(event)

  dpu = info.drawpixperunit
  ixmin = 0.
  iymin = 0.
  ixsize = info.devconfig.xsize
  iysize = info.devconfig.ysize
  self->cmps_form_draw_coords, dpu, ixmin, iymin, ixsize, iysize
  ixmax = info.xpagesize
  iymax = info.ypagesize
  self->cmps_form_draw_coords, dpu, ixmax, iymax
  ixoff = info.devconfig.xoff
  iyoff = info.devconfig.yoff
  self->cmps_form_draw_coords, dpu, ixoff, iyoff

  if event.x LT ixmin OR event.x GT ixmax $
    OR event.y LT iymin OR event.y GT iymax then begin
      widget_control, event.top, set_uvalue=info, /no_copy
      return
  endif
  
  CASE whatButtonPressed OF
      
      'RIGHT': Begin
          
         ; Resize the plot box interactively. Change the event handler
         ; to cmps_form_Grow_Box. All subsequent events will be handled by
         ; cmps_form_Grow_Box until an UP event is detected. Then you will
         ; return to this event handler. Also, turn motion events ON.
          
          Widget_Control, event.id, Event_Pro='cprint_cmps_form_Grow_Box_event', $
            Draw_Motion_Events=1
          
          self->cmps_form_draw_box, 1./dpu, 1./dpu, ixoff, iyoff, info
          
          info.imousex = event.x
          info.imousey = event.y
          
      End
      
      'LEFT': Begin
          
         ; Resize the plot box interactively. Change the event handler
         ; to cmps_form_Move_Box. All subsequent events will be handled by
         ; cmps_form_Move_Box until an UP event is detected. Then you will
         ; return to this  event handler. Also, turn motion events ON.


         ; Only move the box if the cursor is inside the box.
         ;If it is NOT, then RETURN.

          if event.x LT ixoff OR event.x GT (ixoff+ixsize) OR $
            event.y LT iyoff OR event.y GT (iyoff+iysize) then begin 
              
              Widget_Control, event.top, Set_UValue=info, /No_Copy
              Return
          ENDIF
          
       ; Relocate the event handler and turn motion events ON.

          Widget_Control, event.id, Event_Pro='cprint_cmps_form_Move_Box_event', $
            Draw_Motion_Events=1
          
          ; ideltx and idelty contain the offset of the lower left 
          ; corner of the plot region with respect to the mouse.
          info.ideltx  = ixoff - event.x
          info.idelty  = iyoff - event.y
          
      End

      ELSE:                     ; Middle button ignored in this program

  ENDCASE

   ; Put the info structure back into the top-level base

  Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************
