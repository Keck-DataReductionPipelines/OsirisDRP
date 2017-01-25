pro CPrint_cmps_form_Grow_Box_event, event

   ; This event handler is summoned when a RIGHT button is clicked
   ; in the draw widget. It allows the user to draw the outline of a
   ; box with the mouse. It will continue drawing the new box shape
   ; until an UP event is detected. Then it will set the event handler
   ; back to cmps_form_Box_Events and turn cmps_form_Draw_Motion_Events to OFF.

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

  ; Keep box inside the page
  if event.x LT ixmin then event.x = ixmin
  if event.x GT ixmax then event.x = ixmax
  if event.y LT iymin then event.y = iymin
  if event.y GT iymax then event.y = iymax

  ; Decide on which corner is the lower left (it's arbitrary)
  ixoff  = min([info.imousex, event.x])
  iyoff  = min([info.imousey, event.y])
  ixsize = max([info.imousex, event.x]) - ixoff
  iysize = max([info.imousey, event.y]) - iyoff

  ;; Enforce the aspect ratio
  if info.preserve_aspect EQ 1 then begin
      sizeratio = info.aspect / (info.ypagesize / info.xpagesize)
      if (sizeratio GE 1) then ixsize = iysize / info.aspect $
      else iysize = ixsize * info.aspect
      if info.imousex GT event.x then ixoff = info.imousex - ixsize
      if info.imousey GT event.y then iyoff = info.imousey - iysize
  endif

  IF whatButtonType EQ 'UP' THEN Begin

      ; When the button is "up" the moving event is over.  We reset the
      ; event function and update the information about the box's position

      Widget_Control, info.iddraw, Draw_Motion_Events=0, $ ; Motion events off
        Event_Pro='cprint_cmps_form_Box_Events' ; Change to normal processing

      self->cmps_form_real_coords, dpu, ixoff, iyoff, ixsize, iysize

      ; Update the info structure
      self->cmps_form_update_info, info, xoff=ixoff, yoff=iyoff, $
        xsize=ixsize, ysize=iysize
      ; Draw it
      self->cmps_form_draw_form, info

      ; Put the info structure back in the top-level base and RETURN
      Widget_Control, event.top, Set_UValue=info, /No_Copy
      Return
      
  ENDIF

   ; This is the portion of the code that handles all events except for
   ; UP button events. The bulk of the work is done here. Basically,
   ; you need to erase the old box and draw a new box at the new
   ; location. Just keep doing this until you get an UP event.

  self->cmps_form_real_coords, dpu, ixoff, iyoff, ixsize, iysize

  ; Simply draw the new box
  self->cmps_form_draw_box, ixsize, iysize, ixoff, iyoff, info

  ; Put the info structure back in the top-level base.
  Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;*******************************************************************

