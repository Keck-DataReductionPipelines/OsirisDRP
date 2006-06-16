
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME adjchan_000
;
; @PURPOSE Measure any dcs bias shifts between the 32 spectrograph
;          outputs and adjust to common level.
;
; @PARAMETERS None
;
; @CALIBRATION-FILES None
;
; @INPUT None
;
; @OUTPUT contains the adjusted data. The number of valid pointers 
;         is not changed.
;
; @@@QBITS  0th     : checked
;           1st-3rd : ignored
;
; @DEBUG nothing special
;
; @MAIN None
;
; @SAVES Nothing
;
; @@@@NOTES  - The inside bit is ignored.
;            - Input frames must be 2d.
;            - On June 5, 2006 changed it to only look prependicular
;              to spectra. JEL
;            - Also started checking the date of the observations. If
;              it is after May 18, 2006, then ignore the lowest
;              channel in the upper right quad. This includes marking
;              it as bad. This is done by checking the modified Julian
;              date against 53873 (May 18, 2006).
;
; @STATUS  not tested
;
; @HISTORY  5.29.2005, created
;
; @AUTHOR  James Larkin
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION adjchan_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'adjchan_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    n_Dims = size( *DataSet.Frames(0))
    ; Read the modified Julian date.
    jul_date = sxpar(*DataSet.Headers[0],"MJD-OBS", count=num)

    ; Accumulate the deltas for the upper and lower halfs of the detector
    del_upper = 0.0
    num_upper = 0.0
    del_lower = 0.0
    num_lower = 0.0

    for n = 0, (nFrames-1) do begin
        head = *DataSet.Headers[n]
        itime = float(SXPAR(head,"ITIME",/SILENT))
        maxdiff = 20.0/itime

                                ; Calculate and subtract the
                                ; difference between neighboring
                                ; channels. Only subtract if the
                                ; difference is less than 5
                                ; datanumbers when corrected back to
                                ; the total exposure time.
; For each channel boundary use 5 different sets of columns in order
; to find true background in the case that a spectrum spans the
; boundary.
        del = fltarr(5)
        for i = 0, 6 do begin
          ; lower right
            del[0]=median( (*DataSet.Frames[n])[1151+128*i,0:1023]-(*DataSet.Frames[n])[1152+128*i,0:1023])
            del[1]=median( (*DataSet.Frames[n])[1146+128*i,0:1023]-(*DataSet.Frames[n])[1157+128*i,0:1023])
            del[2]=median( (*DataSet.Frames[n])[1141+128*i,0:1023]-(*DataSet.Frames[n])[1162+128*i,0:1023])
            del[3]=median( (*DataSet.Frames[n])[1136+128*i,0:1023]-(*DataSet.Frames[n])[1167+128*i,0:1023])
            del[4]=median( (*DataSet.Frames[n])[1131+128*i,0:1023]-(*DataSet.Frames[n])[1172+128*i,0:1023])
            d = median(del)
            if ( abs(d) lt maxdiff ) then $
              (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] = (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] - d

          ; upper left
            del[0]=median((*DataSet.Frames[n])[127+128*i,1024:2047]-(*DataSet.Frames[n])[128+128*i,1024:2047])
            del[1]=median((*DataSet.Frames[n])[122+128*i,1024:2047]-(*DataSet.Frames[n])[133+128*i,1024:2047])
            del[2]=median((*DataSet.Frames[n])[117+128*i,1024:2047]-(*DataSet.Frames[n])[138+128*i,1024:2047])
            del[3]=median((*DataSet.Frames[n])[112+128*i,1024:2047]-(*DataSet.Frames[n])[143+128*i,1024:2047])
            del[4]=median((*DataSet.Frames[n])[107+128*i,1024:2047]-(*DataSet.Frames[n])[148+128*i,1024:2047])
            d = median(del)
            if ( abs(d) lt maxdiff ) then $
              (*DataSet.Frames[n])[0:(127+128*i),1024:2047] = (*DataSet.Frames[n])[0:(127+128*i),1024:2047] - d

        end
        for i = 0, 7 do begin
          ; lower left - check the ends with the
          ;    right quadrant so spectra
          ;    aren't compared.
            del[0]=median((*DataSet.Frames[n])[1018:1023,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1024:1029,(128*i):(127+128*i)])
            del[1]=median((*DataSet.Frames[n])[1012:1017,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1030:1035,(128*i):(127+128*i)])
            del[2]=median((*DataSet.Frames[n])[1006:1011,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1036:1041,(128*i):(127+128*i)])
            del[3]=median((*DataSet.Frames[n])[1000:1005,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1042:1047,(128*i):(127+128*i)])
            del[4]=median((*DataSet.Frames[n])[994:999,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1048:1053,(128*i):(127+128*i)])
            d = median(del)
            if ( abs(d) lt maxdiff ) then begin
                (*DataSet.Frames[n])[0:1023,(128*i):(127+128*i)] = (*DataSet.Frames[n])[0:1023,(128*i):(127+128*i)] - d
                del_lower = del_lower + d
                num_lower = num_lower + 1.0
            end


          ; upper right - check the ends with the
          ;    left quadrant so spectra
          ;    aren't compared.
            del[0]=median((*DataSet.Frames[n])[1024:1029,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1018:1023,(1024+128*i):(1151+128*i)])
            del[1]=median((*DataSet.Frames[n])[1030:1035,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1012:1017,(1024+128*i):(1151+128*i)])
            del[2]=median((*DataSet.Frames[n])[1036:1041,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1006:1011,(1024+128*i):(1151+128*i)])
            del[3]=median((*DataSet.Frames[n])[1042:1047,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1000:1005,(1024+128*i):(1151+128*i)])
            del[4]=median((*DataSet.Frames[n])[1048:1053,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[994:999,(1024+128*i):(1151+128*i)])
            d = median(del)
            if ( (jul_date ge 53873.0) and (i eq 0) ) then begin
                d = 0
                (*DataSet.IntAuxFrames[n])[1024:2047,1024:1151]=0 ; Flag the channel as bad
                print, "Lower channel in upper right quad is marked as bad..."
            end
            if ( abs(d) lt maxdiff ) then begin
                (*DataSet.Frames[n])[1024:2047,(1024+128*i):(1151+128*i)] = (*DataSet.Frames[n])[1024:2047,(1024+128*i):(1151+128*i)] - d
                del_upper = del_upper + d
                num_upper = num_upper + 1.0
            end
        end 

        if ( num_upper gt 0.0 ) then del_upper = del_upper / num_upper
        if ( num_lower gt 0.0 ) then del_lower = del_lower / num_lower

        (*DataSet.Frames[n])[0:2047,0:1023] = (*DataSet.Frames[n])[0:2047,0:1023] + del_lower
        (*DataSet.Frames[n])[0:2047,1024:2047] = (*DataSet.Frames[n])[0:2047,1024:2047] + del_upper

    end

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
