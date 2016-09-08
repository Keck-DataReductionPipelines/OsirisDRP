;
; Handle events sent to any of the button elements of the form.
;
pro cprint_cmps_form_event, event

   ; This is the main event handler for cmps_form. It handles
   ; the exclusive buttons on the form. Other events on the form
   ; will have their own event handlers.

   ; Get the name of the event structure

name = Tag_Names(event, /Structure_Name)

if name eq 'WIDGET_KILL_REQUEST' then begin
    ; Get the info structure out of the top-level base
    Widget_Control, event.top, Get_UValue=info, /No_Copy

    formInfo = {cancel:1, create:0, printdes:0, filename:''}
    goto, FINISH_DESTROY

endif


   ; Get the User Value of the Button
  Widget_Control, event.id, Get_UValue=thisButton

   ; If name is NOT "WIDGET_BUTTON" or this is not a button
   ; selection event, RETURN.
  nonexclusive = ( thisButton EQ 'ISOLATIN1' OR $
                   thisButton EQ 'COLOR' OR $
                   thisButton EQ 'ENCAPSULATED' OR $
                   thisButton EQ 'ASPECT' )

  IF name NE 'WIDGET_BUTTON' OR $
     (NOT nonexclusive AND event.select NE 1)  THEN Return

   ; Get the info structure out of the top-level base
  Widget_Control, event.top, Get_UValue=info, /No_Copy

  self=*info.self_ptr

  redraw_form = 0
  redraw_box = 0

  ; Pre-read the values from the text fields
  Widget_Control, info.idxsize, Get_Value=xsize
  Widget_Control, info.idysize, Get_Value=ysize
  Widget_Control, info.idxoff, Get_Value=xoff
  Widget_Control, info.idyoff, Get_Value=yoff
  Widget_Control, info.idfilename, Get_Value=filename
  widget_control, info.idprintername, get_value=printname
  self->cmps_form_update_info, info, filename=filename
  self->cmps_form_update_info, info, printname=printname

   ; Respond appropriately to whatever button was selected
  CASE thisButton OF

      'INCHES': Begin
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, inches=1
          redraw_form = 1
      end
          
      'CENTIMETERS': Begin
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, inches=0
          redraw_form = 1
      End
      
      'COLOR': Begin
          self->cmps_form_update_info, info, color=(1-info.devconfig.color)
          redraw_form = 1
      End

      'BITS2': Begin
          self->cmps_form_update_info, info, bits_per_pixel=2
          redraw_form = 1
      End

      'BITS4': Begin
          self->cmps_form_update_info, info, bits_per_pixel=4
          redraw_form = 1
      End

      'BITS8': Begin
          self->cmps_form_update_info, info, bits_per_pixel=8
          redraw_form = 1
      End

      'ISOLATIN1': Begin
          self->cmps_form_update_info, info, isolatin1=(1-info.devconfig.isolatin1)
       End

      'ASPECT': begin
          if info.preserve_aspect EQ 0 then $
            info.aspect = info.devconfig.ysize / info.devconfig.xsize
          info.preserve_aspect = (1 - info.preserve_aspect)
      end

      'LANDSCAPE': Begin
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, landscape=1
          redraw_form = 1
          redraw_box = 1
      End

      'PORTRAIT': Begin
          self->cmps_form_update_info, info, landscape=0
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          redraw_form = 1
          redraw_box = 1
      End

      'ENCAPSULATED': Begin
          self->cmps_form_update_info, info, encapsulated=(1-info.devconfig.encapsulated)
      End

      'ACCEPT': Begin

         ; The user wants to accept the information in the form.
         ; The procedure is to gather all the information from the
         ; form and then fill out a formInfo structure variable
         ; with the information. The formInfo structure is stored
         ; in a pointer. The reason for this is that we want the
         ; information to exist even after the form is destroyed.

         ; Gather the information from the form

          Widget_Control, info.idfilename, Get_Value=filename
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, filename=filename
          widget_control, event.id, get_value=buttonname

          formInfo = { $
                       cancel:0, $            ; CANCEL flag
                       create:0, $            ; CREATE flag
                       buttonname: buttonname, $
                       xpagesize:info.xpagesize, $
                       ypagesize:info.ypagesize, $
                       paperindex:info.paperindex, $
                       result:info.devconfig, $; Results are ready-made
                       printdes:0, $
                       filename:filename $
                     }

          goto, FINISH_DESTROY
      End

      'CREATE': Begin

          Widget_Control, info.idfilename, Get_Value=filename
          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, filename=filename

          formInfo = { $
                       cancel:0, $            ; CANCEL flag
                       create:1, $            ; CREATE flag
                       buttonname: 'Create File', $ 
                       xpagesize:info.xpagesize, $
                       ypagesize:info.ypagesize, $
                       paperindex:info.paperindex, $
                       result:info.devconfig, $; Results are ready-made
                       printdes:0, $
                       filename:filename $
                     }
          goto, FINISH_DESTROY


      End

      'PRINT': Begin

          widget_Control, info.idfilename, get_Value=filename
          widget_control, info.idprintername, get_value=printer_name

          self->cmps_form_update_info, info, xsize=xsize, ysize=ysize, $
            xoff=xoff, yoff=yoff
          self->cmps_form_update_info, info, filename=filename
          self->SetPrintDes, 1
          self->SetPrinterName, printer_name

          print, 'filename is', filename
          print, 'printer name is', printer_name
          
          formInfo = { $
                       cancel:0, $            ; CANCEL flag
                       create:1, $            ; CREATE flag
                       buttonname: 'Create File', $ 
                       xpagesize:info.xpagesize, $
                       ypagesize:info.ypagesize, $
                       paperindex:info.paperindex, $
                       result:info.devconfig, $ ; Results are ready-made
                       printdes:1, $
                       filename:filename $
                     }
          
          goto, FINISH_DESTROY

      End
     
      'CANCEL': Begin
          ; The user wants to cancel out of this form. We need a way to
          ; do that gracefully. Our method here is to set a "cancel"
          ; field in the formInfo structure.
          formInfo = {cancel:1, create:0, printdes:0, filename:filename}

          goto, FINISH_DESTROY
      End

  ENDCASE

  if redraw_form EQ 1 then $
    self->cmps_form_draw_form, info, nobox=(1-redraw_box)

   ; Put the info structure back into the top-level base if the
   ; base is still in existence.

  If Widget_Info(event.top, /Valid) THEN $
    Widget_Control, event.top, Set_UValue=info, /No_Copy
  return


  ; We only reach this stage if we are ending the cmps_form widget
  ; These commands store the results, restore colors, and destroy
  ; the form widget.
  FINISH_DESTROY:

  ; Put the formInfo structure into the location pointer
  ; to by the pointer
  Handle_Value, info.ptrresult, formInfo, /Set, /No_Copy

  ; Delete the pixmap window
  WDelete, info.idpixwid

  ; Restore the user's color table
  TVLct, info.red, info.green, info.blue

  self=*info.self_ptr
  widget_control, event.top, get_uval=uval
  widget_control, self->GetWidLeader(), get_uval=base_uval    
  base_uval.exist.print=0L
  widget_control, self->GetWidLeader(), set_uval=base_uval

  ; Destroy the cmps_form widget program
  Widget_Control, event.top, /Destroy

  return

END ;*******************************************************************
