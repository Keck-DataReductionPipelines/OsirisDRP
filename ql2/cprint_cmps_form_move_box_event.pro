pro CPrint_cmps_form_Move_Box_event, event

   ; This is the event handler that allows the user to "move"
   ; the plot box around in the page window. It will set the
   ; event handler back to "cmps_form_Box_Events" when it senses an
   ; "UP" draw button event and it will also turn cmps_form_Draw_Motion_Events
   ; OFF.

   ; Get the info structure out of the top-level base.

  Widget_Control, event.top, Get_UValue=info, /No_Copy

  self=*info.self_ptr

  whatButtonType = self->cmps_form_What_Button_Type(event)

  dpu = info.drawpixperunit

  ixmin = 0.
  iymin = 0.
  ixsize = info.devconfig.xsize
  iysize = info.devconfig.ysize
  self->cmps_form_draw_coords, dpu, ixmin, iymin, ixsize, iysize
  ; Now ixmin,iymin have the minimum values of x and y, in pixels
  ; ixsize and iysize are the size of the box, in pixels

  ixmax = info.xpagesize
  iymax = info.ypagesize
  self->cmps_form_draw_coords, dpu, ixmax, iymax
  ; ixmax and iymax are the max values of x and y, in pixels

  ; info.ideltx/y contains the offset of the lower left corner of the box,
  ; with respect to the mouse's position
  ixoff = event.x + info.ideltx
  iyoff = event.y + info.idelty

  ; Keep box inside the page
  if ixoff LT ixmin then ixoff = ixmin
  if iyoff LT iymin then iyoff = iymin
  if (ixoff+ixsize) GT ixmax then ixoff = ixmax - ixsize
  if (iyoff+iysize) GT iymax then iyoff = iymax - iysize

  IF whatButtonType EQ 'UP' THEN Begin

      ; When the button is "up" the moving event is over.  We reset the
      ; event function and update the information about the box's position
      
      Widget_Control, info.iddraw, Draw_Motion_Events=0, $ ; Motion events off
        Event_Pro='cprint_cmps_form_Box_Events' ; Change to normal processing
      
      self->cmps_form_real_coords, dpu, ixoff, iyoff, ixsize, iysize
      
      ; Update the info structure
      self->cmps_form_update_info, info, xoff=ixoff, yoff=iyoff
      ; Draw it
      self->cmps_form_draw_form, info
      
      ; Put the info structure back in the top-level base and RETURN
      Widget_Control, event.top, Set_UValue=info, /No_Copy
      Return

  ENDIF

   ; You come to this section of the code for all events except
   ; an UP button event. Most of the action in this event handler
   ; occurs here.

  self->cmps_form_real_coords, dpu, ixoff, iyoff, ixsize, iysize

  ; Simply draw the new box
  self->cmps_form_draw_box, ixsize, iysize, ixoff, iyoff, info

  ; Put the info structure back into the top-level base.
  Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************

