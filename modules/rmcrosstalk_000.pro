
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: rmcrosstalk_000.pro
;
; PURPOSE: For each readout row, we measure the median value for each
; of the 32 channels and subtract the lowest of these medians. The
; purpose is to remove crosstalk caused by bright stars and residual
; gradients within the raw data.
;
; PARAMETERS IN RPBCONFIG.XML : None
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; DATASET : contains the adjusted data. The number of valid pointers 
;           is not changed.
;
; QUALITY BITS : all ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : 
;
; SAVES : Nothing
;
; NOTES :   - Input frames must be 2d.
;
; STATUS : not tested
;
; HISTORY : 6.15.2005, created
;
; AUTHOR : James Larkin
;
;-----------------------------------------------------------------------

FUNCTION rmcrosstalk_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'rmcrosstalk_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; do the subtraction
    n_Dims = size( *DataSet.Frames(0))

    for n = 0, (nFrames-1) do begin

	;;; Read in the image and header info.
	im = *DataSet.Frames[n]

	
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
        ;;; Value stores the median value of each channel (32) for
        ;;; every row (1024).
	value = fltarr(1024, 32)

        for i = 0, 1023 do begin
            for k=0, 7 do begin
		value[i,k+16] = median(q1[(0+128*k):(127+128*k),i])
		value[i,k+24] = median(q3[(0+128*k):(127+128*k),i])
		value[i,k+8] = median(q2[(0+128*k):(127+128*k),i])
		value[i,k] = median(q4[(0+128*k):(127+128*k),i])
            endfor
            ;;; For every row, calculate the lowest of the median
            ;;; values. Don't use the lower right and upper left quadrants
            value[i,0]=min(value[i,0:15])
       endfor

; Now subtract the value[i,0] from every pixel in row i of all 32 channels.
	for i=0, 1023 do begin
            q1[*,i]=q1[*,i]-value[i,0]
            q2[*,i]=q2[*,i]-value[i,0]
            q3[*,i]=q3[*,i]-value[i,0]
            q4[*,i]=q4[*,i]-value[i,0]
        endfor

	;;; Rotate quadrants back to detector rotation
	q2 = rot(q2,270)
	q3 = rot(q3,180)
	q4 = rot(q4,90)

        ;;; Set the original frame to the corrected values.
        (*DataSet.Frames[n])[0:1023,1024:2047]=q1
        (*DataSet.Frames[n])[0:1023,0:1023]=q2
        (*DataSet.Frames[n])[1024:2047,0:1023]=q3
	(*DataSet.Frames[n])[1024:2047,1024:2047]=q4


    endfor

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
