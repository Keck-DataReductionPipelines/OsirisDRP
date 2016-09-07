
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME rmcrosstalk_000.pro
;
; @PURPOSE For each readout row, we measure the median value for each
;          of the 32 channels and subtract the lowest of these medians. The
;          purpose is to remove crosstalk caused by bright stars and residual
;          gradients within the raw data.
;
; @PARAMETERS None
;
; @CALIBRATION-FILES None
;
; @INPUT Raw images
;
; @OUTPUT the dataset contains the adjusted data. The number of valid pointers 
;         is not changed.
;
; @QBITS all ignored
;
; @DEBUG nothing special
;
; @MAIN ROUTINE None
;
; @SAVES Nothing
;
; @NOTES Input frames must be 2d.
;
; @STATUS not tested
;
; @HISTORY 6.15.2005, created
;          6.20.2006 - added check that there is a channel causing the
;                      crosstalk
;          4.06.2016 - modified so algorithm is not run on data from
;                      new H2RG detector (A. Boehle)
;
; @AUTHOR James Larkin and Shelley Wright
;
; @END
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
    n_Dims = size( *DataSet.Frames[0])

    ; update for detector upgrade to H2RG:
    ; check Julian date of data: if after Jan. 1st, 2016, 
    ; then remove crosstalk is not run because data is from new H2RG detector.
    ; read in header of first frame to get MJD
    jul_date = sxpar(*DataSet.Headers[0], "MJD-OBS", count=num)
    if (jul_date ge 57388.0) then begin
        print, 'Remove crosstalk not performed: data is from H2RG detector.'
        drpLog, 'Remove crosstalk not performed: data is from H2RG detector.', /DRF, DEPTH=1
    endif else begin

    for n = 0, (nFrames-1) do begin

	;;; Divide up into quadrants
	;;; q1 q4
	;;; q2 q3
	q1 = (*DataSet.Frames[n])[0:1023,1024:2047]
	q2 = (*DataSet.Frames[n])[0:1023,0:1023]
	q3 = (*DataSet.Frames[n])[1024:2047,0:1023]
	q4 = (*DataSet.Frames[n])[1024:2047,1024:2047]

	;;; Rotate quadrants to q1 orientation
	q2 = rotate(q2,3)
	q3 = rotate(q3,2)
	q4 = rotate(q4,1)
        ;;; Value stores the median value of each channel (32) for
        ;;; every row (1024).
	value = fltarr(1024, 32)
	refer = fltarr(1024, 32)
        temparr = fltarr(128,4)

        for i = 1, 1023 do begin
            for k=0, 7 do begin
                value[i,k+16] = median(q1[(0+128*k):(127+128*k),i]-q1[(0+128*k):(127+128*k),i-1]) ;*0.95
                value[i,k+24] = median(q3[(0+128*k):(127+128*k),i]-q3[(0+128*k):(127+128*k),i-1]) ;*0.95
                value[i,k+8]  = median(q2[(0+128*k):(127+128*k),i]-q2[(0+128*k):(127+128*k),i-1]) ;*0.95
                value[i,k]    = median(q4[(0+128*k):(127+128*k),i]-q4[(0+128*k):(127+128*k),i-1]) ;*0.95
                refer[i,k+16] = median(q1[(0+128*k):(127+128*k),i]) ;*0.95
                refer[i,k+24] = median(q3[(0+128*k):(127+128*k),i]) ;*0.95
                refer[i,k+8]  = median(q2[(0+128*k):(127+128*k),i]) ;*0.95
                refer[i,k]    = median(q4[(0+128*k):(127+128*k),i]) ;*0.95
            endfor
            ;;; For every row, calculate the lowest in an absolute
            ;;; sense of the median values.
            vls = value[i,0:15]
            srt = sort(abs(vls))
            cross = (vls[srt[7]]+vls[srt[6]])/2.0
;            cross = median(vls)
            ;;; Make sure there is a large value that is causing the
            ;;; crosstalk. It should be at least 50 times larger and
            ;;; of the same sign as the crosstalk.
            if ( cross gt 0.0 ) then begin ; Positive crosstalk
                mx = max(refer[i,*])
                value[i,0] = 0.0 ; Default is to subtract nothing.
                if (mx gt 50.0*cross) then begin
                    value[i,0] = cross ; Valid crosstalk.
                end
            endif else begin    ; Negative crosstalk
                mx = min(refer[i,*])
                value[i,0] = 0.0 ; Default is to subtract nothing.
                if (mx lt 50.0*cross) then begin
                    value[i,0] = cross ; Valid crosstalk.
                end
            end
            q1[*,i]=q1[*,i]-value[i,0]
            q2[*,i]=q2[*,i]-value[i,0]
            q3[*,i]=q3[*,i]-value[i,0]
            q4[*,i]=q4[*,i]-value[i,0]
        endfor
        
; Now subtract the value[i,0] from every pixel in row i of all 32 channels.
;        for i=0, 1023 do begin
;            q1[*,i]=q1[*,i]-value[i,0]
;            q2[*,i]=q2[*,i]-value[i,0]
;            q3[*,i]=q3[*,i]-value[i,0]
;            q4[*,i]=q4[*,i]-value[i,0]
;        endfor
        
        ;;; Rotate quadrants back to detector rotation
        q2 = rotate(q2,1)
        q3 = rotate(q3,2)
        q4 = rotate(q4,3)
        
        ;;; Set the original frame to the corrected values.
        (*DataSet.Frames[n])[0:1023,1024:2047]=q1
        (*DataSet.Frames[n])[0:1023,0:1023]=q2
        (*DataSet.Frames[n])[1024:2047,0:1023]=q3
        (*DataSet.Frames[n])[1024:2047,1024:2047]=q4
        
    endfor
    
  endelse


    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
