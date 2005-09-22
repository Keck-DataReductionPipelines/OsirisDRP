
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: tellcor 
;
; PURPOSE: Accept the reduced standard cube, extract the telluric spectrum, 
;          interpolate over the standard's intrinsic absorption
;          features, and performs a telluric correction to the reduced cube.
;
; PARAMETERS IN RPBCONFIG.XML :
;
;   glitchid_COMMON___SlopeThresh  : Threshold used for individual channels
;					of slope (up and down) for each pix 
;   glitchid_COMMON___ChanThresh   : Threshold for the number of channels
;					a glitch needs to found to be
;					labeled in quality extension 
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; DATASET : contains the adjusted data. The number of valid pointers 
;           is not changed.
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : checked 
;
; DEBUG : nothing special
;
; MAIN ROUTINE : 
;
; SAVES : Nothing
;
; NOTES : 
;         
;
; STATUS : 
;
; HISTORY : 8.05.2005, created
;
; AUTHOR : Michael W. McElwain 
;
;-----------------------------------------------------------------------

FUNCTION tellcor_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'tellcor_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    binsize = float(Backbone->getParameter('tellcor_COMMON___BinSize'))	
    boxsize = float(Backbone->getParameter('tellcor_COMMON___BoxSize'))
    apradius = float(Backbone->getParameter('tellcor_COMMON___ApRadius'))

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    
    ; do the subtraction
    n_Dims = size( *DataSet.Frames(0))
    print, "Number of frames = ", nFrames
    print, "Size of each =", n_Dims

    for n = 0, (nFrames-1) do begin

	;;; Read in the image
	im = *DataSet.Frames[n]
	head = *DataSet.Headers[n]
        itime = float(SXPAR(head,"ITIME", /SILENT))

	;;; Divide up into quadrants
	;;; q1 q4
	;;; q2 q3
	q1 = im[0:1023,1024:2047]
	q2 = im[0:1023,0:1023]
	q3 = im[1024:2047,0:1023]
	q4 = im[1024:2047,1024:2047]

	;;; Rotate quadrants to q1 orientation
	q2 = rot(q2,90)
	q3 = rot(q3,180)
	q4 = rot(q4,270)
	;;; Divide up each quadrant into each 8 channel
	chan = fltarr(128,1024,32)

        for k=0, 7 do begin
            chan[*,*,k] = q2[(0+128*k):(127+128*k),*] ; Swapped channels so 2 & 4 are checked instead of 1 & 3
            chan[*,*,k+8] = q4[(0+128*k):(127+128*k),*] ; JEL 6/16/05
            chan[*,*,k+16] = q1[(0+128*k):(127+128*k),*]
            chan[*,*,k+24] = q3[(0+128*k):(127+128*k),*]
        endfor

	;;; Begin checking for glitches in each quadrant
	gl = fltarr(128,1024,32)
	du = fltarr(128,1024,32)
	dd = fltarr(128,1024,32)

	for i=0, 127 do begin
		for j=1, 1022 do begin
			for k=0, 15 do begin
				;;; difference from each pixel up and down
;				du[i,j,k] = abs(chan[i,j,k]) / abs(chan[i,j+1,k])
;				dd[i,j,k] = abs(chan[i,j,k]) / abs(chan[i,j-1,k])
                            du[i,j,k] = abs(chan[i,j,k] - chan[i,j+1,k])   ; Changed to check difference instead of ratio
                            dd[i,j,k] = abs(chan[i,j,k] - chan[i,j-1,k])   ; JEL 6/16/05
				;;; flag each pixel that is above the threshold
                            if ( (du[i,j,k] gt (slthresh/itime)) and (dd[i,j,k] gt (slthresh/itime)) ) then $
                              gl[i,j,k] = 1. else gl[i,j,k] = 0.
			endfor
			;;; flag bad pixels that occur at least in 5 channels
			flag = where(gl[i,j,0:15] eq 1.,cnt)
			if cnt ge chthresh then gl[i,j,*] = -1. 
		endfor
	endfor

	;;; Put glitch array channels back into quadrants
	r1 = [gl[*,*,0],gl[*,*,1],gl[*,*,2],gl[*,*,3],gl[*,*,4],$
		gl[*,*,5],gl[*,*,6],gl[*,*,7]]
	r3 = [gl[*,*,8],gl[*,*,9],gl[*,*,10],gl[*,*,11],gl[*,*,12],$
		gl[*,*,13],gl[*,*,14],gl[*,*,15]]
	r2 = [gl[*,*,16],gl[*,*,17],gl[*,*,18],gl[*,*,19],gl[*,*,20],$
		gl[*,*,21],gl[*,*,22],gl[*,*,23]]
	r4 = [gl[*,*,24],gl[*,*,25],gl[*,*,26],gl[*,*,27],gl[*,*,28],$
		gl[*,*,29],gl[*,*,30],gl[*,*,31]]

	;;; Rotate quadrants back to detector rotation
	r2 = rot(r2,270)
	r3 = rot(r3,180)
	r4 = rot(r4,90)

	;;; Put quadrants into detector-size array
	glt = fltarr(2048,2048)
	glt[0:1023,0:1023] = r2
	glt[0:1023,1024:2047] = r1
	glt[1024:2047,0:1023] = r3
	glt[1024:2047,1024:2047] = r4

	;;; Put glitch pixels into bad pixel ("quality") map
	for i=0, 2047 do begin
		for j=0, 2047 do begin
			if glt[i,j] eq -1. then (*DataSet.IntAuxFrames[n])[i,j] = 0.
		endfor	
	endfor


    endfor

    ; it is not neccessary to change the dataset pointer
    report_success, functionName, T

    RETURN, OK

END
