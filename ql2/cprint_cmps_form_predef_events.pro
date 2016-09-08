; 
; Handle events to the drop-list widgets, which contain predefined
; configurations.
;
pro cprint_cmps_form_predef_events, event

  name = tag_names(event, /structure_name)
  if strupcase(name) NE 'WIDGET_DROPLIST' then return

   ; Get the info structure out of the top-level base
  Widget_Control, event.top, Get_UValue=info, /No_Copy

  self=*info.self_ptr

  Widget_Control, event.id, Get_UValue=thislist

  ; Pre-read the values from the text fields
  Widget_Control, info.idfilename, Get_Value=filename
  self->cmps_form_update_info, info, filename=filename

  case thislist of
      'PAPER':  info.paperindex = event.index   ; Paper change 
      'PREDEF': begin
          old_filename = info.devconfig.filename         ; Keep old filename
          info.devconfig = info.predefined(event.index)  ; New config
          info.paperindex = info.papersizes(event.index) ; New paper too
          if info.filechanged then $
            info.devconfig.filename = old_filename $
          else begin
              cd, current=thisdir
              l = strlen(thisdir)
              if strmid(info.devconfig.filename, 0, l) NE thisdir then $
                info.devconfig.filename = old_filename $
              else $
                info.devconfig.filename = filepath(info.devconfig.filename, $
                                                   root_dir=thisdir)
          endelse
      end
  endcase

  ; Be sure to select a pristine set of paper
  self->cmps_form_select_papersize, info.paperindex, xpagesize, ypagesize, $
    landscape=info.devconfig.landscape, inches=info.devconfig.inches
  info.xpagesize = xpagesize
  info.ypagesize = ypagesize

  widget_control, info.idpaperlist, set_droplist_select=info.paperindex

  ; Reset the drawpixperunit value
  convfactor = 1.0
  if info.devconfig.inches EQ 0 then convfactor = convfactor * 2.54
  info.marginsize = 0.25 * convfactor

  ; The conversion between length and pixels cannot always be set precisely,
  ; depending on the size of the paper
  dpp = 10.0 / convfactor  ; Desire 10 pixels per inch
  if dpp * info.xpagesize GT info.xpixwinsize OR $
    dpp * info.ypagesize GT info.ypixwinsize then $
    dpp = min( [ float(info.xpixwinsize-2)/info.xpagesize, $
                 float(info.ypixwinsize-2)/info.ypagesize ])
  info.drawpixperunit = dpp
  info.pixredraw = 1

  ; Update the info structure and draw it
  self->cmps_form_update_info, info, xoff=info.devconfig.xoff
  self->cmps_form_draw_form, info

  Widget_Control, event.top, Set_UValue=info, /No_Copy
  return
end

