
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME glitchid 
;
; @PURPOSE Identify glitches in raw OSIRIS frames and write out pixel
;          values into bad pixel map
;
; @@@PARAMETERS
;
;   glitchid_COMMON___SlopeThresh  : Threshold used for individual channels
;		          	     of slope (up and down) for each pix 
;   glitchid_COMMON___ChanThresh   : Threshold for the number of channels
;				     a glitch needs to found to be
;				     labeled in quality extension 
;
; @CALIBRATION-FILES None
;
; @INPUT Raw data
;
; @OUTPUT The dataset contains the adjusted data. The number of valid pointers 
;           is not changed.
;
; @@@QBITS  0th     : checked
;           1st-3rd : checked 
;
; @DEBUG nothing special
;
; @MAIN None
;
; @SAVES Nothing
;
; @@@@NOTES  - The inside bit is ignored.
;            - Input frames must be 2d.
;
; @STATUS  not tested
;
; @HISTORY  6.14.2005, created
;	    11.21.2005, modified with M. Perrin suggestions
;           06.17.2006, modified for ratio detection
	
; @AUTHOR  Shelley Wright 
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION glitchid_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'glitchid_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    slthresh = float(Backbone->getParameter('glitchid_COMMON___SlopeThresh'))	
    chthresh = float(Backbone->getParameter('glitchid_COMMON___ChanThresh'))

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

	;;; Rotate quadrants (q2,q4) to q1 orientation
	q2 = rotate(q2,3)
	q3 = rotate(q3,2)
	q4 = rotate(q4,1)
	
	;;; Divide up each quadrant into each 8 channel
	chan = fltarr(128,1024,32)

	for k=0, 7 do begin
		chan[0,0,k] = q2[(0+128*k):(127+128*k),*]  
                chan[0,0,k+8] = q4[(0+128*k):(127+128*k),*]
		chan[0,0,k+16] = q1[(0+128*k):(127+128*k),*]
		chan[0,0,k+24] = q3[(0+128*k):(127+128*k),*]
	endfor

	;;; Begin checking for glitches in each quadrant
	gl = fltarr(128,1024,32)
	du = fltarr(128,1024,32)
	dd = fltarr(128,1024,32)

	;;; changed for loop to M. Perrin's suggestions
;	du[*,[0,1023]]=0 ; avoid edge wrap
;	dd[*,[0,1023]]=0
;	wgl = where( (du gt (slthresh/itime)) and (dd gt slthresh/itime) , glcount)
;	if glcount gt 0 then gl[wgl]=1
;	wflag = where( rebin(total(gl,3),128,1024,16) gt chthresh, flagct)
;	if flagct gt 0 then gl[wflag]=1
        std = fltarr(16)
        compare = fltarr(1024,16)

        for i=0, 127 do begin
            ; Calculate the std for each of the outputs at this row.
            for k = 0, 15 do begin
                srt = sort(chan[i,*,k])
                sz = size(srt)
                q = srt[30:sz[1]-30]
                std[k] = stddev(chan[q])
                compare[*,k] = abs(chan[i,*,k])>3.0*std[k]
            end
            for j=1, 1022 do begin
                for k=0, 15 do begin
                                ;;; difference from each pixel up and down
;                             du[i,j,k] = abs(chan[i,j,k] - chan[i,j+1,k])
;                             dd[i,j,k] = abs(chan[i,j,k] - chan[i,j-1,k])
                             ;;; flag each pixel that is above the threshold
;                              if (((du[i,j,k]) gt (slthresh/itime)) and $
;				((dd[i,j,k]) gt (slthresh/itime))) then $
;				gl[i,j,k] = 1. else gl[i,j,k] = 0.
                            ;;; Switch to ratio detection
                    rat=abs(chan[i,j,k])/(compare[j+1,k]+compare[j-1,k])
                    if ( rat gt 1.0 ) then $
                      gl[i,j,k] = 1. else gl[i,j,k] = 0.
                endfor
                        ;;; flag bad pixels that occur at least in # channels
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
	r2 = rotate(r2,1)
	r3 = rotate(r3,2)
	r4 = rotate(r4,3)

	;;; Put quadrants into detector-size array
	glt = fltarr(2048,2048)
	glt[0:1023,0:1023] = r2
	glt[0:1023,1024:2047] = r1
	glt[1024:2047,0:1023] = r3
	glt[1024:2047,1024:2047] = r4

	;;; Put glitch pixels into bad pixel ("quality") map
	;for i=0, 2047 do begin
	;	for j=0, 2047 do begin
	;		if glt[i,j] eq -1. then (*DataSet.IntAuxFrames[n])[i,j] = 0.
 	;	endfor	
	;endfor

	wglitch = where(glt eq -1,glitchcount)
	if glitchcount gt 0 then begin
            (*DataSet.IntAuxFrames[n])[wglitch]=0
            (*DataSet.Frames[n])[wglitch]=0.0
        end

    endfor

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
