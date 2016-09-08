; +
; NAME: cprint__define 
;
; PURPOSE: 
;
; CALLING SEQUENCE: 
;                   
; INPUTS:  
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS: 
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 28MAY2004 - MWM: edited header
; - 

function CPrint::Init, printer_name=pname, wid_leader=wid_lead

; set filename
if keyword_set(pname) then printer=pname else printer='q6171'
if keyword_set(wid_lead) then wid=wid_lead else wid=0L 

print, 'initializing print object'

; set values of members of object
self.wid_leader=wid
self.xsize=7.5
self.xoff=0.50
self.ysize=10.
self.yoff=0.5
self.filename='idl.ps'
self.inches=1
self.color=1
self.bits_per_pixel=8
self.encapsulated=0
self.isolatin1=0
self.landscape=0
self.printer_name=printer
self.print_des=0

return, 1

end


; Convert from inches and centimeters to WIDGET_DRAW pixels 
pro CPrint::cmps_form_draw_coords, drawpixperunit, xoff, yoff, xsize, ysize

  if n_elements(xoff) GT 0 then xoff   = xoff  * drawpixperunit + 1
  if n_elements(yoff) GT 0 then yoff   = yoff  * drawpixperunit + 1
  if n_elements(xsize) GT 0 then xsize = xsize * drawpixperunit
  if n_elements(ysize) GT 0 then ysize = ysize * drawpixperunit

  return
end

; Perform the opposite conversion of cmps_form_DRAW_COORDS
pro CPrint::cmps_form_real_coords, drawpixperunit, xoff, yoff, xsize, ysize

  if n_elements(xoff) GT 0 then xoff   = (xoff-1) / drawpixperunit
  if n_elements(yoff) GT 0 then yoff   = (yoff-1) / drawpixperunit
  if n_elements(xsize) GT 0 then xsize = xsize / drawpixperunit
  if n_elements(ysize) GT 0 then ysize = ysize / drawpixperunit

  return
end

; Calculate a list of vertices to be plotted as a box in the 
; draw widget.
function cprint::cmps_form_PlotBox_Coords, xsize, ysize, xoff, yoff, drawpixperunit

   ; This function converts sizes and offsets to appropriate
   ; Device coordinates for drawing the PLOT BOX on the PostScript
   ; page. The return value is a [2,5] array.

returnValue = IntArr(2,5)
xs = xsize
ys = ysize
xof = xoff
yof = yoff
self->cmps_form_draw_coords, drawpixperunit, xof, yof, xs, ys

; Add one because we do for the page outline
xcoords = Round([xof, xof+xs, xof+xs, xof, xof]) + 1
ycoords = Round([yof, yof, yof+ys, yof+ys, yof]) + 1

returnValue(0,*) = xcoords
returnValue(1,*) = ycoords

return, returnValue
end ;*******************************************************************

; Convert between the IDL-form of PS coordinates (including the 
; strange definition of YOFFSET and XOFFSET) to a more
; "human-readable" form where the Xoffset and YOFFSET always refer to
; the lower-left hand corner of the output
pro cprint::cmps_form_conv_pscoord, info, xpagesize, ypagesize, $
      toidl=toidl, tohuman=tohuman

  if info.landscape EQ 1 then begin
      ixoff=info.xoff 
      iyoff=info.yoff
      if keyword_set(tohuman) then begin
          info.yoff = ixoff
          info.xoff = xpagesize - iyoff
      endif else if keyword_set(toidl) then begin
          info.xoff = iyoff
          info.yoff = xpagesize - ixoff
      endif
  endif
  return
end

; Return names of paper sizes
function CPrint::cmps_form_papernames

  return, ['Letter','Legal','Tabloid','Ledger','Executive','Monarch', $
            'Statement','Folio','Quarto','C5','B4','B5','Dl','A0','A1', $
            'A2','A3','A4','A5','A6']
end

; Select a paper size based on number or string.  Returns x and 
; y page sizes, accouting for the units of measurement and the
; orientation of the page.
pro CPrint::cmps_form_select_papersize, papertype, xpagesize, ypagesize, $
      inches=inches, landscape=landscape, index=index

;           Letter Legal Tabloid Ledger Executive Monarch Statement Folio
  xpaper = [612.,  612,  792,    792,   540,      279,    396,      612, $
$;          Quarto C5  B4  B5  Dl  A0   A1   A2   A3  A4  A5  A6
	    610,   459,729,516,312,2380,1684,1190,842,595,420,297]

;           Letter Legal Tabloid Ledger Executive Monarch Statement Folio
  ypaper = [792.,  1008, 1224,   1224,  720,      540,    612,      936, $
$;          Quarto C5  B4   B5  Dl  A0   A1   A2   A3   A4  A5  A6
	    780,   649,1032,729,624,3368,2380,1684,1190,842,595,421]
  names  = self->cmps_form_papernames()

  sz = size(papertype)
  tp = sz(sz(0) + 1)
  if tp GT 0 AND tp LT 6 then begin
      index = fix(papertype)
  endif else if tp EQ 7 then begin
      index = where(strupcase(papertype) EQ strupcase(names), ict)
      if ict EQ 0 then index = 0
  endif else $
    index = 0

  index = index(0)

  xpagesize = xpaper(index) / 72.  ; Convert to inches
  ypagesize = ypaper(index) / 72.
  xpagesize = xpagesize(0)
  ypagesize = ypagesize(0)
  if NOT keyword_set(inches) then begin
      xpagesize = xpagesize * 2.54
      ypagesize = ypagesize * 2.54
  endif
  if keyword_set(landscape) then begin
      temp = xpagesize
      xpagesize = ypagesize
      ypagesize = temp
  endif
  
  return
end

; cmps_form_LOAD_CONFIGS
;
; Loads a set of default configurations into the output variables,
;
;   CONFIGNAMES - array of names for configurations.
;
;   CONFIGS - array of cmps_form_INFO structures, each with a separate
;             configuration in it, and corresponding to the
;             configuration name.
;
; Intended as an intelligent default when no other is specified.
;
pro CPrint::cmps_form_load_configs, defaultpaper, configs

  ; This is the default paper size, when none is given
  defaultpaper = 'Letter'

  ; Here is how the cmps_form_INFO structure is defined.  Refer to it
  ; when creating new structures.
  template = { cmps_form_INFO, $
               xsize:0.0, $     ; The x size of the plot
               xoff:0.0, $      ; The x offset of the plot
               ysize:0.0, $     ; The y size of the plot
               yoff:0.0, $       ; The y offset of the plot
               filename:'', $   ; The name of the output file
               printname:'', $  ; The print name of the output file
               inches:0, $       ; Inches or centimeters?
               color:0, $       ; Color on or off?
               bits_per_pixel:0, $ ; How many bits per image pixel?
               encapsulated:0,$ ; Encapsulated or regular PostScript?
	       isolatin1:0,$    ; Encoding is not ISOLATIN1
               landscape:0 }    ; Landscape or portrait mode?

  pctemplate = { cmps_form_CONFIG,  $
                 config:{cmps_form_INFO},  $
                 configname: '', $    ; Name of configuration
                 papersize: '' }      ; Size of paper for configuration
                 
  
  ; Set of default configurations (no ISOLATIN1 encoding)
  ;   1.  7x5    inch color plot region in portrait
  ;   2.  7.5x10 inch centered color plot region, covering almost whole
  ;                   portrait page (0.5 inch margins)
  ;   3.  10x7.5 inch centered color plot region, covering almost whole
  ;                   landscape page (0.5 inch margins)
  ;   4.  7x5    inch gray plot region in portrait (IDL default config)
  configs = [{cmps_form_CONFIG, config:$
              {cmps_form_INFO, 7.0, 0.75, 5.0, 5.0, self.filename, self.printer_name, 1, 1, 8, 0, 0, 0},$
              configname:'Half Portrait (color)', papersize:defaultpaper}, $
             {cmps_form_CONFIG, config:$
              {cmps_form_INFO, 7.5, 0.50, 10., 0.5, self.filename, self.printer_name, 1, 1, 8, 0, 0, 0},$
              configname:'Full Portrait (color)', papersize:defaultpaper}, $
             {cmps_form_CONFIG, config:$
              {cmps_form_INFO, 10., 0.50, 7.5, 10.5,self.filename, self.printer_name, 1, 1, 8, 0, 0, 1},$
              configname:'Full Landscape (color)', papersize:defaultpaper}, $
             {cmps_form_CONFIG, config:$
              {cmps_form_INFO, 18., 1.5, 26.7, 1.5, self.filename, self.printer_name, 0, 1, 8, 0, 0, 0},$
              configname:'A4 Portrait (color)', papersize:'A4'}, $
             {cmps_form_CONFIG, config:$
              {cmps_form_INFO, 26.7, 1.5, 18.,28.2039,self.filename,self.printer_name, 0,1, 8, 0, 0, 1},$
              configname:'A4 Landscape (color)', papersize:'A4'}, $
             {cmps_form_CONFIG, config:$
              {cmps_form_INFO, 17.78,1.91,12.70,12.70,self.filename,self.printer_name, 0,1, 4, 0, 0, 0},$
              configname:'IDL Standard', papersize:defaultpaper} ]


  return
end

; 
; cmps_form_Update_Info
;
; This procedure modifies an "info" structure, according to new
; specifications about the PS configuration.  This is the central
; clearing house for self-consistent modification of the info structure.
;
; INPUTS
;   info    - info structure to be modified
;   keywords- IDL keywords are contain information is folded
;             into the "info" structure.
;             Valid keywords are:
;                XSIZE, YSIZE, 
;                XOFF, YOFF    - size and offset of plotting region in
;                                "human" coordinates.  This is the
;                                natural size as measured from the
;                                lower-left corner of the page in its
;                                proper orientation (not the IDL
;                                definition!).  These are the same
;                                values that are printed in the form's
;                                Size and Offset fields.
;                INCHES        - whether dimensions are in inches or
;                                centimeters (1=in, 0=cm)
;                COLOR         - whether output is color (1=y, 0=n)
;                BITS_PER_PIXEL- number of bits per pixel (2,4,8)
;                ENCAPSULATED  - whether output is EPS (1=EPS, 0=PS)
;                LANDSCAPE     - whether output is portrait or
;                                landscape (1=land, 0=port)
;                FILENAME      - output file name (with respect to
;                                current directory)
;
pro CPrint::cmps_form_update_info, info, set=set, _EXTRA=newdata

  if n_elements(newdata) GT 0 then $
    names = Tag_Names(newdata)
  set   = keyword_set(set)
  centerfactor = 1.0

  FOR j=0, N_Elements(names)-1 DO BEGIN
      
      case strupcase(names(j)) of
          'XSIZE':       info.devconfig.xsize    = float(newdata.xsize)
          'YSIZE':       info.devconfig.ysize    = float(newdata.ysize)
          'XOFF':        info.devconfig.xoff     = float(newdata.xoff)
          'YOFF':        info.devconfig.yoff     = float(newdata.yoff)
          'INCHES':      BEGIN
              inches   = fix(newdata.inches)
              if inches NE 0 then inches = 1
              if set NE 1 then begin
                  convfactor = 1.0
                  if info.devconfig.inches EQ 0 AND inches EQ 1 then $
                    convfactor = 1.0/2.54 $ ; centimeters to inches
                  else if info.devconfig.inches EQ 1 AND inches EQ 0 then $
                    convfactor = 2.54 ; inches to centimeters

                  info.devconfig.xsize = info.devconfig.xsize * convfactor
                  info.devconfig.ysize = info.devconfig.ysize * convfactor
                  info.devconfig.xoff  = info.devconfig.xoff  * convfactor
                  info.devconfig.yoff  = info.devconfig.yoff  * convfactor
                  info.xpagesize       = info.xpagesize       * convfactor
                  info.ypagesize       = info.ypagesize       * convfactor
                  info.marginsize      = info.marginsize      * convfactor
                  info.drawpixperunit  = info.drawpixperunit  / convfactor
                    
              endif
                  
              info.devconfig.inches = inches
          end
          
          'LANDSCAPE':   begin
              landscape= fix(newdata.landscape)
              if landscape NE 0 then landscape = 1
              
              if landscape NE info.devconfig.landscape AND $
                set NE 1 then begin
                  temp = info.xpagesize
                  info.xpagesize = info.ypagesize
                  info.ypagesize = temp
                  
                  ; Since the margins are bound to be way out of wack,
                  ; we could recenter here.
                  
                  xsize = info.devconfig.xsize
                  ysize = info.devconfig.ysize

                  centerfactor = 2.0
                  
                  ; We will have to redraw the reserve pixmap
                  info.pixredraw = 1
                  
              endif 
              
              info.devconfig.landscape = landscape
          end
          
          'COLOR':       begin
              info.devconfig.color    = fix(newdata.color)
              if info.devconfig.color        NE 0 then info.devconfig.color = 1
          end
          'ENCAPSULATED':  begin
              info.devconfig.encapsulated = fix(newdata.encapsulated)
              if info.devconfig.encapsulated NE 0 then $
                info.devconfig.encapsulated = 1
          end
          'ISOLATIN1': begin
              info.devconfig.isolatin1 = fix(newdata.isolatin1)
              if info.devconfig.isolatin1 NE 0 then $
                info.devconfig.isolatin1 = 1
          end
          'BITS_PER_PIXEL': begin
              bpp = fix(newdata.bits_per_pixel)
              if bpp LT 1              then bpp = 2
              if bpp GT 2 AND bpp LT 4 then bpp = 4
              if bpp GT 4 AND bpp LT 8 then bpp = 8
              if bpp GT 8              then bpp = 8
              info.devconfig.bits_per_pixel = bpp
          end
          'FILENAME': begin
              if string(newdata.filename) NE info.devconfig.filename then $
                info.filechanged = 1
              info.devconfig.filename = string(newdata.filename)
          end
          'PRINTNAME': begin
              if string(newdata.printname) NE info.devconfig.printname then $
                info.printerchanged = 1
              info.devconfig.printname = string(newdata.printname)
          end
          
      endcase
  endfor
  
  ; Now check the sizes and offsets, to be sure they are same for the 
  ; particular landscape/portrait and inch/cm settings that have been
  ; chosen.
  pgwid = info.xpagesize
  pglen = info.ypagesize
  pgmar = info.marginsize

  if set NE 1 then begin
      info.devconfig.xsize = (pgmar) > info.devconfig.xsize < (pgwid-2.*pgmar)
      info.devconfig.ysize = (pgmar) > info.devconfig.ysize < (pglen-2.*pgmar)
      info.devconfig.xoff  = (pgmar) > info.devconfig.xoff  < (pgwid-info.devconfig.xsize - pgmar)
      info.devconfig.yoff  = (pgmar) > info.devconfig.yoff  < (pglen-info.devconfig.ysize - pgmar)
      if info.devconfig.xsize + info.devconfig.xoff GT (pgwid-pgmar) then $
        info.devconfig.xoff = (pgwid - info.devconfig.xsize) / centerfactor
      if info.devconfig.ysize + info.devconfig.yoff GT (pglen-pgmar) then $
        info.devconfig.yoff = (pglen - info.devconfig.ysize) / centerfactor
  endif

  ; Preserve aspect ratio if necessary
  if (info.preserve_aspect EQ 1) then begin
      sizeratio = info.aspect / (info.ypagesize / info.xpagesize)
      if (sizeratio GE 1) then $
        info.devconfig.xsize = info.devconfig.ysize / info.aspect $
      else $
        info.devconfig.ysize = info.devconfig.xsize * info.aspect
  endif

  return
end


; HEADER: pro CPrint::cmps_form_draw_box
; Draw the "sample" box in the draw widget.  If necessary, also
; redraws the backing reserve pixmap.

pro CPrint::cmps_form_draw_box, xsize, ysize, xoff, yoff, info

  ; First order of business is to make a new reserve pixmap, if
  ; necessary.

  if info.pixredraw EQ 1 then begin
      
      ; Operate on the pixmap first
      wset, info.idpixwid
      erase
      ; Make background ...
      tv, replicate(info.bkgcolor, info.xpixwinsize, info.ypixwinsize)
      ; ... and page outline
      coords = self->cmps_form_plotbox_coords(info.xpagesize, info.ypagesize, $
                                      0.,0., info.drawpixperunit)
      plots, coords(0,*), coords(1,*), /device, color=info.pagecolor

      info.pixredraw = 0
  endif

  ; Now, we transfer the reserve pixmap to the screen

  wset, info.idwid
  device, copy=[0, 0, info.xpixwinsize, info.ypixwinsize, 0, 0, $
                info.idpixwid]

  ; Finally we overlay the plot region
  coords = self->cmps_form_plotbox_coords(xsize, ysize, xoff, yoff,info.drawpixperunit)
  plots, coords(0,*), coords(1,*), color=info.boxcolor, /device

  return
end


; HEADER: cmps_form_draw_form
; Update the widget elements of the cmps_form form, using the INFO structure.
; If the NOBOX keyword is set, then the draw widget is not updated.

pro CPrint::cmps_form_draw_form, info, nobox=nobox

  ; Draw the DRAW widget if needed
  if NOT keyword_set(nobox) then $
    self->cmps_form_draw_box, info.devconfig.xsize, info.devconfig.ysize, $
    info.devconfig.xoff, info.devconfig.yoff, info

  ; Update the numeric text fields
  xsizestr = strtrim(string(info.devconfig.xsize, format='(F6.2)'), 2)
  ysizestr = strtrim(string(info.devconfig.ysize, format='(F6.2)'), 2)
  xoffstr  = strtrim(string(info.devconfig.xoff, format='(F6.2)'), 2)
  yoffstr  = strtrim(string(info.devconfig.yoff, format='(F6.2)'), 2)

  widget_control, info.idxsize, set_value=xsizestr
  widget_control, info.idysize, set_value=ysizestr
  widget_control, info.idxoff, set_value=xoffstr
  widget_control, info.idyoff, set_value=yoffstr

  widget_control, info.idaspect, set_button=(info.preserve_aspect EQ 1)

  ; Set EPS (encapsulated ps) buttons
  Widget_Control, info.idencap, Set_Button=(info.devconfig.encapsulated EQ 1)

   ; Set color buttons.
  Widget_Control, info.idcolor, Set_Button=(info.devconfig.color EQ 1)

  ; Set inch/cm buttons.
  Widget_Control, info.idinch, Set_Button=(info.devconfig.inches EQ 1)
  Widget_Control, info.idcm,   Set_Button=(info.devconfig.inches EQ 0)

  ; Set bits_per_pixel buttons.
  Widget_Control, info.idbit2, Set_Button=(info.devconfig.bits_per_pixel EQ 2)
  Widget_Control, info.idbit4, Set_Button=(info.devconfig.bits_per_pixel EQ 4)
  Widget_Control, info.idbit8, Set_Button=(info.devconfig.bits_per_pixel EQ 8)
  Widget_Control, info.idbitbase, Sensitive=(info.devconfig.color EQ 1)

  ; Set encoding button
  widget_control, info.idisolatin1, Set_Button=(info.devconfig.isolatin1 EQ 1)

  ; Set default filename.
  Widget_Control, info.idfilename, Get_Value=wfilename
  if string(wfilename(0)) NE info.devconfig.filename then begin
      Widget_Control, info.idfilename, Set_Value=info.devconfig.filename
      ; Put caret at end of pathname text so that filename itself is visible
      Widget_Control, info.idfilename, $
        Set_Text_Select=[ strlen(info.devconfig.filename), 0 ]
  endif

  ; Set default printername.
  Widget_Control, info.idprintername, Get_Value=wprintname
  if string(wprintname(0)) NE info.devconfig.printname then begin
      Widget_Control, info.idprintername, Set_Value=info.devconfig.printname
      ; Put caret at end of pathname text so that filename itself is visible
      Widget_Control, info.idprintername, $
        Set_Text_Select=[ strlen(info.devconfig.printname), 0 ]
  endif
  

  ; Set protrait/landscape button.
  Widget_Control, info.idland, Set_Button=(info.devconfig.landscape EQ 1)
  Widget_Control, info.idport, Set_Button=(info.devconfig.landscape EQ 0)

  ; Set Paper
  pn = self->cmps_form_papernames()
  xp = strtrim(string(info.xpagesize, format='(F10.2)'),2)
  yp = strtrim(string(info.ypagesize, format='(F10.2)'),2)
  un = 'in'
  if NOT info.devconfig.inches then un = 'cm'

  paperlab = string(pn(info.paperindex), xp, un, yp, un, $
                      format='("   Paper: ",A0," (",A0,A0," x ",A0,A0,")   ")')
  Widget_Control, info.idpaperlabel, set_value=paperlab
  
  return
end


function CPrint::cmps_form_what_button_type, event

   ; Checks event.type to find out what kind of button
   ; was clicked in a draw widget. This is NOT an event handler.

type = ['DOWN', 'UP', 'MOTION', 'SCROLL']
return, type(event.type)
end ;*******************************************************************

function CPrint::cmps_form_what_button_pressed, event

   ; Checks event.press to find out what kind of button
   ; was pressed in a draw widget.  This is NOT an event handler.

button = ['NONE', 'LEFT', 'MIDDLE', 'NONE', 'RIGHT']
return, button(event.press)
end ;*******************************************************************

function CPrint::cmps_form_what_button_released, event

   ; Checks event.release to find out what kind of button
   ; was released in a draw widget.  This is NOT an event handler.

button = ['NONE', 'LEFT', 'MIDDLE', 'NONE', 'RIGHT']
return, button(event.release)
end ;*******************************************************************

Function cprint::cmps_form, xoffset, yoffset, Cancel=cancelButton, Help=help, $
     XSize=xsize, YSize=ysize, XOffset=xoff, YOffset=yoff, $
     Inches=inches, Color=color, Bits_Per_Pixel=bits_per_pixel, $
     Encapsulated=encapsulated, Landscape=landscape, Filename=filename, $
     Defaults=defaults, LocalDefaults=localDefaults, Initialize=initialize, $
     select=select, parent=parent, $
     Create=createButton, NoCommon=nocommon, PaperSize=paperSize, $
     button_names=buttons, button_sel=button_sel, $
     PreDefined=predefined, DefaultPaper=defaultpaper, $
     aspect=aspect, preserve_aspect=preserve_aspect, $
     xpagesize=xpagesize, ypagesize=ypagesize, pagebox=pagebox, $
     Printer_name=printer_name, Printdes=printdes

   ; If the Help keyword is set, print some help information and return

  IF Keyword_Set(help) THEN BEGIN
      Doc_Library, 'cmps_form'
      RETURN, 0
  ENDIF

  ; Load default setups via a common block, if they are available
  if n_elements(predefined) EQ 0 then begin
      common cmps_form_configs, cmps_form_default_papersize, $
        cmps_form_stdconfigs
      if n_elements(cmps_form_stdconfigs) GT 0 then $
        predefined = cmps_form_stdconfigs
  endif

  ; If the user has not set up a common block, then get some pre
  if n_elements(predefined) EQ 0 then $
    self->cmps_form_load_configs, cmps_form_default_papersize, predefined

  ; Transfer to local copies so that we don't overwrite
  confignames = predefined(*).configname
  configs     = predefined(*).config
  configs     = configs(*) ;; IDL 5.5 will make a 1xN array -- collapse it now
  papernames  = predefined(*).papersize
  if n_elements(defaultpaper) EQ 0 $
    AND n_elements(cmps_form_default_papersize) GT 0 then $
    defaultpaper = cmps_form_default_papersize
  if n_elements(defaultpaper) EQ 0 then $
    defaultpaper = 'Letter'

  papersizes = intarr(n_elements(papernames))

  ; If localdefaults exist, then enter them into a new first entry of 
  ; the configuration list
  if n_elements(localDefaults) NE 0 then begin
      configs     = [ configs(0), configs ]
      confignames = [ 'Local',    confignames ]
      papernames  = [defaultpaper, papernames ]
      papersizes  = [ 0,          papersizes ]

      names = Tag_Names(localdefaults)
      for j=0, n_elements(names)-1 do $
        dummy = execute('configs(0).' +names(j)+ ' = localdefaults.' +names(j))
  endif


  ; Generate a new entry at the beginning, which will be the initial, 
  ; default configuration.
  configs     = [ configs(0), configs ]
  confignames = [ 'Default',  confignames ]
  papernames  = [defaultpaper, papernames ]
  papersizes  = [ 0,          papersizes ]

  filechanged = 0
  defaultset = 0
  if n_elements(defaults) NE 0 then begin
      defaultset = 1
      names = Tag_Names(defaults)
      for j=0, n_elements(names)-1 do begin
          dummy = execute('configs(0).' +names(j)+ ' = defaults.' +names(j))
          if strupcase(names(j)) EQ 'FILENAME' then filechanged = 1
      endfor
  endif

  ; Next, enter in the keyword defaults
  IF NOT defaultset OR N_ELEMENTS(inches) GT 0 then begin
      if n_elements(inches) EQ 0 then inches = 1
      configs(0).inches    = keyword_set(inches)
  endif
  IF NOT defaultset OR n_elements(landscape) GT 0 then $
    configs(0).landscape = keyword_set(landscape)
  if NOT defaultset OR n_elements(color) GT 0 then $
    configs(0).color = keyword_set(color)
  if NOT defaultset OR n_elements(encapsulated) GT 0 then $
    configs(0).encapsulated = keyword_set(encapsulated)

  if NOT defaultset OR n_elements(bits_per_pixel) GT 0 then begin
      if n_elements(bits_per_pixel) EQ 0 then bpp = 8 else bpp = bits_per_pixel
      if bpp LT 1              then bpp = 2
      if bpp GT 2 AND bpp LT 4 then bpp = 4
      if bpp GT 4 AND bpp LT 8 then bpp = 8
      if bpp GT 8              then bpp = 8
      configs(0).bits_per_pixel = bpp
  endif
  
  IF N_ELements(filename) EQ 0 THEN BEGIN
      if NOT filechanged then begin
          CD, Current=thisDir
          filename = Filepath(self.filename, Root_Dir=thisDir)
          filechanged = 0
          configs(0).filename = filename
      endif
  ENDIF else begin
      configs(0).filename = filename
      filechanged = 1
  endelse

  ; Get the size of the page, based on the papersize keyword
  if n_elements(paperSize) GT 1 then begin
      xpagesize = float(paperSize(0))
      ypagesize = float(paperSize(1))
      pind = 0
  endif else begin
      if n_elements(paperSize) EQ 0 then papersize = defaultpaper
      self->cmps_form_select_papersize, papersize, xpagesize, ypagesize, $
        landscape=configs(0).landscape, inches=configs(0).inches, index=pind
  endelse
  
  convfactor = 1.0
  if configs(0).inches EQ 0 then convfactor = convfactor * 2.54
  defmarginsize = 1.50 * convfactor   ; 1 1/2 inch margins default
  
  if N_Elements(marginsize) EQ 0 then $
    marginsize    = 0.25 * convfactor ; 1/4 inch margins "minimum"

  ; "Unconvert" the configuration xoff, yoff, etc. into human-readable format,
  ; which is also the format of the keywords xoff and yoff passed to cmps_form()

  nconfigs = n_elements(configs)
  for j = 0, nconfigs-1 do begin
      self->cmps_form_select_papersize, papernames(j), tmpxpg, tmpypg, $
        landscape=configs(j).landscape, inches=configs(j).inches, $
        index=pind

      papersizes(j) = pind
      tmpc = configs(j)
      self->cmps_form_conv_pscoord, tmpc, tmpxpg, tmpypg, /tohuman
      configs(j) = tmpc
  endfor

  if n_elements(aspect) GT 0 then aspect = aspect(0) > .001
  if n_elements(ysize) GT 0 then ysize = ysize(0)
  if n_elements(xsize) GT 0 then xsize = xsize(0)
  if n_elements(xsize) GT 0 AND n_elements(ysize) GT 0 then $
    aspect = ysize / (xsize > (ysize*0.001)) $
  else if n_elements(xsize) GT 0 AND n_elements(aspect) GT 0 then $
    ysize = xsize * aspect $
  else if n_elements(ysize) GT 0 AND n_elements(aspect) GT 0 then $
    xsize = ysize / aspect

  ; Compute an intelligent default X and Y size, if they aren't given
  pageaspect = xpagesize / ypagesize

  if NOT defaultset then begin 
    if n_elements(xsize) EQ 0 AND n_elements(ysize) EQ 0 then begin
        if n_elements(aspect) EQ 0 then begin
            IF !D.Window NE -1 THEN $
              aspect = Float(!D.X_VSize) / !D.Y_VSize $
            ELSE $
              aspect = 1.0
        endif

        if aspect GT 1.0 then BEGIN
            configs(0).xsize = xpagesize-2.0*marginsize
            configs(0).ysize = configs(0).xsize / aspect
        endif else begin
            configs(0).ysize = ypagesize-2.0*marginsize
            configs(0).xsize = configs(0).ysize * aspect
        endelse
    endif
    if n_elements(xsize) EQ 0 then $
      configs(0).xsize = 7.0 * convfactor
    if n_elements(ysize) EQ 0 then $
      configs(0).ysize = 5.0 * convfactor
    if n_elements(xoff)  EQ 0 then $
      configs(0).xoff  = (xpagesize-configs(0).xsize) / 2.0
    if n_elements(yoff)  EQ 0 then $
      configs(0).yoff  = (ypagesize-configs(0).ysize) / 2.0
  
    configs(0).xsize = marginsize>configs(0).xsize<(xpagesize-2.*marginsize)
    configs(0).ysize = marginsize>configs(0).ysize<(ypagesize-2.*marginsize)
    configs(0).xoff  = marginsize>configs(0).xoff <(xpagesize-configs(0).xsize)
    configs(0).yoff  = marginsize>configs(0).yoff <(ypagesize-configs(0).ysize)
  endif

  if keyword_set(preserve_aspect) then begin
      if n_elements(xsize) EQ 0 then xsize = configs(0).xsize
      if n_elements(ysize) EQ 0 then ysize = configs(0).ysize
      aspect = ysize / (xsize > (ysize*0.001))
  endif

  if n_elements(xsize) GT 0 then configs(0).xsize = xsize
  if n_elements(ysize) GT 0 then configs(0).ysize = ysize
  if n_elements(xoff)  GT 0 then configs(0).xoff  = xoff
  if n_elements(yoff)  GT 0 then configs(0).yoff  = yoff
  if n_elements(aspect) EQ 0 then aspect = configs(0).ysize / configs(0).xsize

  ; Return the initialized information, if that's all they were asking
  ; for.  Must convert back to "IDL" coordinates.
  IF Keyword_Set(initialize) THEN BEGIN
      sel = 0
      if n_elements(select) GT 0 then begin
          selen = strlen(select)
          wh = where(strupcase(strmid(confignames,0,selen)) EQ $
                     strupcase(select), ct)
          if ct GT 0 then sel = wh(0)
      endif
      self->cmps_form_select_papersize, papernames(sel), tmpxpg, tmpypg, $
        landscape=configs(sel).landscape, inches=configs(sel).inches
      tmpc = configs(sel)
      xpagesize = tmpxpg & ypagesize = tmpypg
      pagebox = [(0-tmpc.xoff)/tmpc.xsize, $
                 (0-tmpc.yoff)/tmpc.ysize, $
                 (xpagesize-tmpc.xoff)/tmpc.xsize, $
                 (ypagesize-tmpc.yoff)/tmpc.ysize ]
      self->cmps_form_conv_pscoord, tmpc, tmpxpg, tmpypg, /toidl
      return, tmpc
  endif

   ; This program cannot work if the graphics device is already set
   ; to PostScript. So if it is, set it to the native OS graphics device.
   ; Remember to set it back later.

  IF !D.Name EQ 'PS' THEN BEGIN

      oldName = 'PS'
      thisDevice = Byte(!Version.os_family)
      thisDevice = StrUpCase( thisDevice(0:2) )
      IF thisDevice EQ 'MAC' OR thisDevice EQ 'WIN' THEN Set_Plot, thisDevice $
      ELSE Set_Plot, 'X'

  ENDIF ELSE oldName = !D.Name

   ; Check for optional offset parameters and give defaults if not passed

  Device, Get_Screen_Size=screenSize
  IF N_Elements(xoffset) EQ 0 THEN xoffset = (screenSize(0) - 600) / 2.
  IF N_Elements(yoffset) EQ 0 THEN yoffset = (screenSize(1) - 400) / 2.
  
  ; The draw widget will have the following dimensions
  xpixwinsize = 174
  ypixwinsize = 174    ; Hopefully will fit 11" x 17" sized paper

  ; The conversion between length and pixels cannot always be set precisely,
  ; depending on the size of the paper
  dpp = 10.0 / convfactor  ; Desire 10 pixels per inch
  if dpp * xpagesize GT xpixwinsize OR dpp * ypagesize GT ypixwinsize then $
    dpp = min( [ float(xpixwinsize-2)/xpagesize, $
                 float(ypixwinsize-2)/ypagesize ])

  ; Start building the widgets
  thisRelease = StrMid(!Version.Release, 0, 1)
  if thisRelease EQ '5' AND n_elements(parent) GT 0 THEN $
    extra_modal = {Modal:1, Group_Leader:parent(0) }
  tlb0 = Widget_Base(Title='Configure PostScript Parameters', Column=1, $
                     XOffset=xoffset, YOffset=yoffset, TLB_Frame_Attr=9, $
                     _EXTRA=extra_modal, /tlb_kill_request_events)

   ; Sub-bases for layout
  tlb = Widget_Base(tlb0, Column=1, Align_Center=1, frame=1)

  sizebase = Widget_Base(tlb, Row=1,  Align_Center=1)

  numbase = Widget_Base(sizebase, Column=1)

      numsub1 = Widget_Base(numbase, Row=1)

         junk = Widget_Label(numsub1, Value=' Units: ')
             junksub = Widget_Base(numsub1, Row=1, /Exclusive)
                inch = Widget_Button(junksub, Value='Inches', UValue='INCHES')
                cm = Widget_Button(junksub, Value='Centimeters', $
                   UValue='CENTIMETERS')

      numsub2 = Widget_Base(numbase, Row=1, event_pro='cprint_cmps_form_Num_Events')

         xbase = Widget_Base(numsub2, Column=1, Base_Align_Right=1)
           x1base = Widget_Base(xbase, Row=1)
             junk   = Widget_Label(x1base, Value='XSize: ')
             xsizew = Widget_Text(x1base, Scr_XSize=60, /Editable, $
                                  Value='')

           x2base = Widget_Base(xbase, Row=1)
             junk  = Widget_Label(x2base, Value='XOffset: ')
             xoffw = Widget_Text(x2base, Scr_XSize=60, /Editable, $
                                 Value='')

         ybase = Widget_Base(numsub2, Column=1, Base_Align_Right=1)
           y1base = Widget_Base(ybase, Row=1)
             junk   = Widget_Label(y1base, Value='YSize: ')
             ysizew = Widget_Text(y1base, Scr_XSize=60, /Editable, $
                      Value='')

           y2base = Widget_Base(ybase, Row=1)
             junk  = Widget_Label(y2base, Value='YOffset: ')
             yoffw = Widget_Text(y2base, Scr_XSize=60, /Editable, $
                                 Value='')

     paperw = Widget_Label(numbase, $
       Value='                                        ' )
     dummy = widget_base(numbase, column=1, /nonexclusive)
     aspectw = widget_button(dummy, value='Preserve Aspect', uvalue='ASPECT')

   drawbase = Widget_Base(sizebase, Row=1, frame=1)

   draw = Widget_Draw(drawbase, XSize=xpixwinsize, YSize=ypixwinsize, $
                      event_pro='cprint_cmps_form_Box_Events', $ 
                      Button_Events=1, retain=2)

   opttlb  = Widget_Base(tlb, Row=1, align_center=1, xpad=20)

   orientbase = Widget_Base(opttlb, Column=1, base_align_center=1)

   junk = Widget_Label(orientbase, Value='Orientation: ')
      junkbase = Widget_Base(orientbase, Column=1, /Frame, /Exclusive)
         land = Widget_Button(junkbase, Value='Landscape', UValue='LANDSCAPE')
         port = Widget_Button(junkbase, Value='Portrait', UValue='PORTRAIT')

   optbase = Widget_Base(opttlb, Column=1, /NonExclusive, frame=1)
     colorbut  = widget_button(optbase, Value='Color Output', $
                 uvalue='COLOR')
     encap     = Widget_Button(optbase, Value='Encapsulated (EPS)', $
                           uvalue='ENCAPSULATED')
     isolatin1 = widget_button(optbase, Value='ISOLatin1 Encoding', $
                 UValue='ISOLATIN1')

;   bitslabel = Widget_Label(opttlb, Value='   Color Bits:')

   bitsw = Widget_Base(opttlb, Column=1, /Exclusive, /frame)

      bit2 = Widget_Button(bitsw, Value='2 Bit Color', UValue='BITS2')
      bit4 = Widget_Button(bitsw, Value='4 Bit Color', UValue='BITS4')
      bit8 = Widget_Button(bitsw, Value='8 Bit Color', UValue='BITS8')

   filenamebase = Widget_Base(tlb, Column=1, Align_Center=1)
   fbase = Widget_Base(filenamebase, Row=1)
   textlabel = Widget_Label(fbase, Value='Filename: ')

       ; Set up text widget with an event handler that ignores any event.

   filenamew = Widget_Text(fbase, /Editable, Scr_XSize=200,  $
      Value=self.printer_name, event_pro='cprint_cmps_form_null_events')
   filenameb = widget_button(fbase, value='Choose...', $
                             event_pro='cprint_cmps_form_select_file_event')
           but = widget_button(fbase, value='Create PS File', $
                               uvalue='ACCEPT')


   ; ** NEW CODE **
   pbase = widget_base(filenamebase, /row)
   textlabel = widget_label(pbase, Value='Printer Name: ')
   printernamew = Widget_Text(pbase, /Editable, Scr_XSize=165,  $
      Value='', event_pro='cprint_cmps_form_null_events')
;   printernameb = widget_button(pbase, value='Choose...', $
;                             event_pro='cprint_cmps_form_select_file_event')
                  print = Widget_Button(pbase, Value='Print File', UValue='PRINT')
   

   ; This is a base for selection of predefined configurations and paper sizes
   predefbase = Widget_Base(tlb0, row=1, /align_center, frame=1)
   junk = widget_label(predefbase, value='Predefined:')
   predlist = widget_droplist(predefbase, value=confignames, $
                          event_pro='cprint_cmps_form_predef_events', UValue='PREDEF')
   junk = widget_label(predefbase, value='    Paper Sizes:')
   paplist = widget_droplist(predefbase, value=self->cmps_form_papernames(),$
                          event_pro='cprint_cmps_form_predef_events', UValue='PAPER')
   
   actionbuttonbase = Widget_Base(tlb0, /row)
   cancel = Widget_Button(actionbuttonbase, Value='Cancel', UValue='CANCEL', scr_xsize=590, $
                         /align_center)


   ; Modify the color table 
   ; Get the colors in the current color table
   TVLct, r, g, b, /Get

   ; Modify color indices N_Colors-2, N_Colors-3 and N_Colors-4 for
   ; drawing colors

   ; The number of colors in the session can be less then the
   ; number of colors in the color vectors on PCs (and maybe other
   ; computers), so take the smaller value. (Bug fix?)
   ncol = !D.N_Colors < N_Elements(r)
   red = r
   green = g
   blue=b
   red(ncol-4:ncol-2) = [70B, 0B, 255B]
   green(ncol-4:ncol-2) = [70B, 255B, 255B]
   blue(ncol-4:ncol-2) = [70B, 0B, 0B]

   ; Load the newly modified colortable
   TVLct, red, green, blue

   ; Create a reserve pixmap for keeping backing store
   owin = !d.window
   Window, /Free, XSize=xpixwinsize, YSize=ypixwinsize, /Pixmap
   pixwid = !D.Window

   ; Create a handle.  This will hold the result after the widget finishes
   ptr = Handle_Create()

   ; create a pointer to this object for reference in event handlers
   temp_ptr=ptr_new(self, /allocate_heap)

   info = { $
            self_ptr:temp_ptr, $
            devconfig: configs(0), $
            iddraw: draw, $
            idpixwid: pixwid, $
            idwid: pixwid, $
            idtlb: tlb0, $
            idxsize: xsizew, $
            idysize: ysizew, $
            idxoff: xoffw, $
            idyoff: yoffw, $
            idfilename: filenamew, $
            idprintername: printernamew, $
            idinch: inch, $
            idcm: cm, $
            idcolor: colorbut, $
            idbitbase: bitsw, $
            idbit2: bit2, $
            idbit4: bit4, $
            idbit8: bit8, $
            idisolatin1: isolatin1, $
            idencap: encap, $
            idland: land, $
            idport: port, $
            idpaperlabel: paperw, $
            idaspect: aspectw, $
            idpaperlist: paplist, $
            xpagesize: xpagesize, $
            ypagesize: ypagesize, $
            paperindex: pind, $
            marginsize: marginsize, $
            xpixwinsize: xpixwinsize, $
            ypixwinsize: ypixwinsize, $
            drawpixperunit: dpp, $
            filechanged: filechanged, $
            pixredraw: 1, $
            imousex: 0.0, $
            imousey: 0.0, $
            ideltx: 0.0, $
            idelty: 0.0, $
            pagecolor: ncol-2, $
            boxcolor: ncol-3, $
            bkgcolor: ncol-4, $
            red: r, $
            green: g, $
            blue: b, $
            ptrresult: ptr, $
            predefined: configs, $
            papersizes: papersizes, $
            defaultpaper: defaultpaper, $
            aspect: aspect, $
            preserve_aspect: keyword_set(preserve_aspect) $
          }
   
   self->cmps_form_draw_form, info, /nobox
   Widget_Control, tlb0, /Realize
   Widget_Control, draw, Get_Value=wid
   widget_control, self.wid_leader, get_uval=cimwin_uval
   cimwin_uval.exist.print=tlb0
   widget_control, self.wid_leader, set_uval=cimwin_uval
 
   info.idwid = wid

   ;; Make sure the current info is consistent
   self->cmps_form_update_info, info
   ; Draw the remaining widgets
   widget_control, paplist, Set_DropList_Select=pind
   self->cmps_form_draw_form, info

   ; Store the info structure in the top-level base

   Widget_Control, tlb0, Set_UValue=info, /No_Copy

   ; Set this widget program up as a modal or blocking widget. What this means
   ; is that you will return to the line after this XManager call when the
   ; widget is destroyed.

   thisRelease = StrMid(!Version.Release, 0, 1)
   if thisRelease EQ '4' then $
     xmanager_modal = {Modal:1}
   XManager, 'cprint_cmps_form', tlb0, _extra=xmanager_modal

   ; Get the formInfo structure from the pointer location.

   Handle_Value, ptr, formInfo, /No_Copy

   ; Make sure the user didn't click a close button.

   IF N_Elements(formInfo) EQ 0 THEN Begin
       Handle_Free, ptr
       RETURN, 0
   EndIF

   ; Strip the CANCEL field out of the formInfo structure so the
   ; cancelButton flag can be returned via the CANCEL keyword and the
   ; formInfo structure is suitable for passing directly to the DEVICE
   ; procedure through its _Extra keyword.

   cancelButton = formInfo.cancel
   createButton = formInfo.create
   IF NOT cancelButton THEN begin
       xpagesize = formInfo.xpagesize
       ypagesize = formInfo.ypagesize
       printdes = formInfo.printdes
       filename = formInfo.filename
       paperindex  = formInfo.paperindex
       if n_elements(buttons) GT 0 then $
         button_sel = forminfo.buttonname
       formInfo = formInfo.result 
       
       papersize = self->cmps_form_papernames()
       papersize = papersize(paperindex)
       pagebox = [(0-formInfo.xoff)/formInfo.xsize, $
                  (0-formInfo.yoff)/formInfo.ysize, $
                 (xpagesize-formInfo.xoff)/formInfo.xsize, $
                 (ypagesize-formInfo.yoff)/formInfo.ysize ]
       self->cmps_form_conv_pscoord, formInfo, xpagesize, ypagesize, /toidl
   endif else $
     formInfo = 0

   ; Free up the space allocated to the pointers and the data

   Handle_Free, ptr

   if owin GE 0 then wset, owin
   Set_Plot, oldname

   RETURN, formInfo
END ;*******************************************************************


function CPrint::CreateFormInfoStruct


s={cmps_form_INFO, $
        xsize:self.xsize, $     ; The x size of the plot
        xoff:self.xoff, $       ; The x offset of the plot
        ysize:self.ysize, $     ; The y size of the plot
        yoff:self.yoff, $       ; The y offset of the plot
        filename:self.filename, $ ; The name of the output file
        printname:self.printer_name, $         ; The print name of the output file
        inches:self.inches, $   ; Inches or centimeters?
        color:self.color, $     ; Color on or off?
        bits_per_pixel:self.bits_per_pixel, $ ; How many bits per image pixel?
        encapsulated:self.encapsulated,$ ; Encapsulated or regular PostScript?
        isolatin1:self.isolatin1,$ ; Encoding is not ISOLATIN1
        landscape:self.landscape } ; Landscape or portrait mode?

return, s
end

function CPrint::DeviceSetup

; Call CMPS to configure the print device

formInfo = self->CMPS_FORM(CANCEL=cancelled, $
                     BUTTON_NAMES=['Create PS File'],$
                     DEFAULTS=self->CreateFormInfoStruct(),$
                     PARENT=self.wid_leader, $
                     FILENAME=self.filename, $
                     PRINTDES=printdes)
        
if not cancelled then begin
    self.xsize=formInfo.xsize
    self.xoff=formInfo.xoff
    self.ysize=formInfo.ysize
    self.yoff=formInfo.yoff
    self.filename=formInfo.filename
    self.inches=formInfo.inches
    self.color=formInfo.color
    self.bits_per_pixel=formInfo.bits_per_pixel
    self.encapsulated=formInfo.encapsulated
    self.isolatin1=formInfo.isolatin1
    self.landscape=formInfo.landscape

    ; Set up the PS print device
    set_plot, 'ps'
    device, _Extra=formInfo
endif

return, cancelled

end

pro CPrint::DeviceCleanup

; Clean up the PS print device
device, /close

case !version.os_family of 
	'unix':set_plot, 'X'
	'Windows':set_plot, 'WIN'
	'MacOS':set_plot, 'MAC'
	'VMS':set_plot, 'X'
	else:
endcase
end

pro CPrint::PS2Printer

print, 'ps2printer'

; check operating system and make case statement
case !version.os_family of 
	'unix':self->UnixPrint
	'Windows':self->WindowsPrint
	'MacOS':self->MacOSPrint
	'VMS':self->VMSPrint
	else:
endcase

end

pro CPrint::UnixPrint

;check printer existence
lpq_command=strcompress('lpq -P'+ self.printer_name)
spawn, lpq_command, result

if result[0] eq '' then begin
    answer=dialog_message(['Printer queue: ', self.printer_name, $
                                     'not found.'], dialog_parent=wid_leader, /error)
endif else begin
    ; print it!
    print, 'Printing on ', self.printer_name
    command=strcompress('lpr -P'+ self.printer_name+' '+self.filename)
    print, command
    spawn, command, result
    ; if error (actually, i don't think result is ever not '', but in case...)
    if result[0] ne '' then begin
        answer=dialog_message(result, dialog_parent=wid_leader, /error)
    endif
endelse

end

pro CPrint::WindowsPrint

print, 'Printing in Windows'

;cmd = 'prfile32/q/- '+self.filename
cmd = 'prfile32 '+self.filename
cmd = 'Start C:\"Program Files"\printfile\prfile32.exe /q '+'"'+self.filename+'"'
spawn, cmd, result

end


pro CPrint::MacOSPrint

print, 'MacOS printing not supported'

end


pro CPrint::VMSPrint

print, 'VMS printing not supported'

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CPRINT ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function CPrint::GetWidLeader
return, self.wid_leader
end

pro CPrint::SetPrinterName, printer_name
self.printer_name=printer_name
end

function CPrint::GetPrinterName
return, self.printer_name
end

pro CPrint::SetOrientation, orientation
self.orientation=orientation
end

function CPrint::GetOrientation
return, self.orientation
end

pro CPrint::SetXSize, xsize
self.xsize=xsize
end

function CPrint::GetXSize
return, self.xsize
end

pro CPrint::SetXOff, xoff
self.xoff=xoff
end

function CPrint::GetXOff
return, self.xoff
end

pro CPrint::SetYSize, ysize
self.ysize=ysize
end

function CPrint::GetYSize
return, self.ysize
end

pro CPrint::SetYOff, yoff
self.yoff=yoff
end

function CPrint::GetYSize
return, self.yoff
end

pro CPrint::SetFilename, filename
self.filename=filename
end

function CPrint::GetFilename
return, self.filename
end

pro CPrint::SetInches, inches
self.inches=inches
end

function CPrint::GetInches
return, self.inches
end

pro CPrint::SetColor, color
self.color=color
end


function CPrint::GetColor
return, self.color
end

pro CPrint::SetBitsPerPixel, bits
self.bits_per_pixel=bits
end

function CPrint::GetBitsPerPixel
return, self.bits_per_pixel
end

pro CPrint::SetEncapsulated, enc
self.encapsulated=enc
end

function CPrint::GetEncapsulated
return, self.encapsulated
end

pro CPrint::SetIsoLatin1, iso
self.isolatin1=iso
end

function CPrint::GetIsoLatin1
return, self.isolatin1
end

pro CPrint::SetLandscape, land
self.landscape=land
end

function CPrint::GetLandscape
return, self.landscape
end

pro CPrint::SetPrintDes, printdes
self.print_des=printdes
end

function CPrint::GetPrintDes
return, self.print_des
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CPRINT ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro cprint__define

; create a structure that holds an instance's information 
struct={cprint, $
        wid_leader:0L, $             ; base leader for obj
        xsize:0.0, $                 ; The x size of the plot
        xoff:0.0, $                  ; The x offset of the plot
        ysize:0.0, $                 ; The y size of the plot
        yoff:0.0, $                  ; The y offset of the plot
        filename:'', $               ; The name of the output file
        inches:0, $                  ; Inches or centimeters?
        color:0, $                   ; Color on or off?
        bits_per_pixel:0, $          ; How many bits per image pixel?
        encapsulated:0,$             ; Encapsulated or regular PostScript?
        isolatin1:0,$                ; Encoded with ISOLATIN1?
        landscape:0, $               ; Landscape or portrait mode?
        printer_name:'', $           ; printer name
        print_des:0 $               ; print designation (1 for print)
       }

end
