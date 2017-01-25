pro cimwin_makemovie_parameters_event, event

; event when user enters values in a field
widget_control, event.top, get_uval=movie_uval
widget_control, movie_uval.base_id, get_uval=imwin_uval

ImWinObj=*(imwin_uval.self_ptr)
; get image object
ImObj_ptr=ImWinObj->GetImObj()
ImObj=*ImObj_ptr

; get old values
oldchanstar=ImWinObj->GetMovieChanStart()
oldchanstop=ImWinObj->GetMovieChanStop()
oldbinsize=ImWinObj->GetMovieBinSize()
oldbinstep=ImWinObj->GetMovieBinStep()
oldminval=ImWinObj->GetMovieMinValue()
oldmaxval=ImWinObj->GetMovieMaxValue()

; get new values
widget_control, movie_uval.wids.chanstar_id, get_val=chanstar
widget_control, movie_uval.wids.chanstop_id, get_val=chanstop
widget_control, movie_uval.wids.mag_id, get_val=mag
widget_control, movie_uval.wids.xspatbin_id, get_val=xspatbin
widget_control, movie_uval.wids.yspatbin_id, get_val=yspatbin
widget_control, movie_uval.wids.binsize_id, get_val=binsize
widget_control, movie_uval.wids.binstep_id, get_val=binstep
widget_control, movie_uval.wids.minval_id, get_val=minval
widget_control, movie_uval.wids.maxval_id, get_val=maxval
widget_control, movie_uval.wids.norm_id, get_val=normval

; find out how many channels there are in the Z direction
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()
im_s=([im_xs, im_ys, im_zs])[ImWinObj->GetAxesOrder()]

; make sure the input parameters are valid
chanstop_low = (0 > chanstop) 
chanstop = (chanstop_low < (im_s[2]-1))
chanstar_low = (0 > chanstar) 
chanstar = (chanstar_low < chanstop)

; make sure the block size is between 1 and the smaller size of the 2
; shown dimensions
;small_side = im_s[0] < im_s[1]
;blocksize_low = (1 > blocksize) 
;blocksize = (blocksize_low < small_side)

; make sure the magnification is gt one, and an integer
mag=(1 > mag)

; make sure the spatial x bin is gt one, and less than the x maximum
; x size of the image
xspatbin_low=(1 > xspatbin[0])

if (xspatbin_low gt im_s[0]) then begin
    xspatbin=im_s[0] 
endif else begin
    xspatbin=xspatbin_low
endelse

; make sure the spatial y bin is gt one, and less than the y maximum
yspatbin_low=(1 > yspatbin[0])
if (yspatbin_low gt im_s[1]) then begin
    yspatbin=im_s[0] 
endif else begin
    yspatbin=yspatbin_low
endelse

; make sure the bin step is less between 0 and the length 
; of the z axis

binsize_low=(0 > binsize)
binsize=(binsize_low < (im_s[2]-1))

binstep_low=(0 > binstep)
binstep=(binstep_low < (im_s[2]-1))

; set the imwin member variables to the new values
ImWinObj->SetMovieChanStart, chanstar
ImWinObj->SetMovieChanStop, chanstop
ImWinObj->SetMovieMag, mag
ImWinObj->SetMovieXSpatBin, xspatbin
ImWinObj->SetMovieYSpatBin, yspatbin
ImWinObj->SetMovieBinSize, binsize
ImWinObj->SetMovieBinStep, binstep
ImWinObj->SetMovieMinValue, minval
ImWinObj->SetMovieMaxValue, maxval

; update the text in the widget
ImWinObj->UpdateMovieText

end
