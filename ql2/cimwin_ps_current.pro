;+
; NAME:
;
;   NS_PS_CURRENT
;
; PURPOSE:
;
;   This routine creates a postscript file of the current image.
;
;
; CATEGORY:
;
;   Quicklook
;
; CALLING SEQUENCE:
;
;   ns_ps_current, ns_display_base_id, [filename=filename], [/pick], [/print] 
;
; INPUTS:
;
;   NS_DISPLAY_BASE_ID:   The widget id of the display base
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;   FILENAME:             The name of the file to write the postscript to.
;
;   PICK:                 When this keyword is set, the filename is
;                         chosen interactively using the DIALOG_PICKFILE
;                         widget
;
;   PRINT:                When this keyword is set, the image is sent
;                         directly to the printer.
;
; OUTPUTS:
;
;   None.
;
; OPTIONAL OUTPUTS:
;
;   None.
;
; COMMON BLOCKS:
;
;   None.
;
; SIDE EFFECTS:
;
;   Prints the image to a file or a printer.
;
; RESTRICTIONS:
;
;   Must be used with Quicklook.
;
; PROCEDURE:
;
;   Get filename, determine where to print, then print.
;
; EXAMPLE:
;
;  To print to a file called FILE:
;     ns_ps_current, ns_display_base_id, filename=FILE
;
; MODIFICATION HISTORY:
;
;   Feb 9, 2000: Jason Weiss -- Added this header.
;
;-

;; THIS SHOULD BE A CLASS METHOD.  SIMILAR TO WHAT YOU WOULD GET FOR
;; GAUSSIAN FITTING OR THE STATISTICS CALCULATION!!!

pro cimwin_ps_current, cimwin_base_id, FILE=filename, PRINT=print, PICK=pick

; -- get the display uvalue
widget_control, cimwin_base_id, get_uvalue=uval

; get the image data
self=*uval.self_ptr
ImObj_ptr=self.p_ImObj
ImObj=*ImObj_ptr
im_ptr=ImObj->GetData()
im=*im_ptr
hd_ptr=ImObj->GetHeader()
hd=*hd_ptr
filename=ImObj->GetPathFilename()
title=ImObj->GetTitle()

; if pick is set then get filename with pickfile
; if print is not set then check that the filename is ok to write.  
; if print is set, then set check_result to yes, since
;    it is always ok to overwrite uval.ps_printfile
if (keyword_set(print)) then check_result='Yes' else begin
    if (keyword_set(pick)) then begin
        filename=dialog_pickfile(group=cimwin_base_id, $
            path=uval.current_dir, filter='*.ps')
    endif
    check_result=ql_writecheck(cimwin_base_id, filename)
endelse

if check_result eq 'Yes' then begin

    ; start postscript file
    set_plot, 'PS'
    device, filename=uval.ps_filename

    ; copy the image data with the min/max cut off and log scaling if 
    ; necessary

    disp_min = ImObj->GetDispMin()
    disp_max = ImObj->GetDispMax()

    print, disp_min, disp_max

    disp_im = im > disp_min
    disp_im = disp_im < disp_max
    if uval.log_scale eq 'yes' then begin
        disp_im = alog(disp_im)
    endif

    ; make the aspect ratio of the printed image correspond to the data
    s = size(im)
    ratio = float(s[2]) / float(s[1])
    xs=5
    ys = xs * ratio

    device, /inches, xs=xs, ys=ys

    ; plot the pixel values along the edge then print the image to the ps file
    plot, [0,s(1)], [0,s(2)], pos=[0,0,s(1),s(2)], xticks=3, yticks=3, $
      xticklen=-0.01, yticklen=-0.01, $
      /nodata, /noerase, title=title, xtitle='pixels', ytitle='pixels', $
      xstyle=1, ystyle=1
    tvscl, disp_im, 0,0 , xs=xs, ys=ys, /inches 

    ; close the file and set the display back to the screen
    device, /CLOSE
    set_plot, 'X'

    ; print the file if that keyword is set
    ;    if (keyword_set(print)) then begin
           ; goto ns_print routine -- JLW
    ;        ns_print, ns_display_base_id 
    ;    endif else begin
    ;        spawn, '\mv ' + uval.ps_printfile + filename
    ;    endelse

endif


end

