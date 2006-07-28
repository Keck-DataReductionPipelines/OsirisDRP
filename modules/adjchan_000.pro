
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
;            - Bad channel was fixed on June 27, 2006, so added check
;              if Julian date is after 53913.
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

    print, 'Number of frames = ', nFrames
    for n = 0, (nFrames-1) do begin
        head = *DataSet.Headers[n]
        itime = float(SXPAR(head,"ITIME",/SILENT))
        maxdiff = 20.0/itime
        print, 'Maximum allowed offset= ', maxdiff
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
        d = fltarr(7)
        for i = 0, 6 do begin
          ; lower right
            del[0]=median( (*DataSet.Frames[n])[1151+128*i,0:1023]-(*DataSet.Frames[n])[1152+128*i,0:1023])
            del[1]=median( (*DataSet.Frames[n])[1146+128*i,0:1023]-(*DataSet.Frames[n])[1157+128*i,0:1023])
            del[2]=median( (*DataSet.Frames[n])[1141+128*i,0:1023]-(*DataSet.Frames[n])[1162+128*i,0:1023])
            del[3]=median( (*DataSet.Frames[n])[1136+128*i,0:1023]-(*DataSet.Frames[n])[1167+128*i,0:1023])
            del[4]=median( (*DataSet.Frames[n])[1131+128*i,0:1023]-(*DataSet.Frames[n])[1172+128*i,0:1023])
            d[i] = median(del)
;            val = median( (*DataSet.Frames[n])[(1131+128*i):(1151+128*i),0:1023] )
;            d(i)=median( (*DataSet.Frames[n])[(1141+128*i):(1151+128*i),0:1023]-(*DataSet.Frames[n])[(1152+128*i):(1162+128*i),0:1023])
;            if ( (abs(d[i]) lt maxdiff) and (abs(val/d[i]) lt 4.0)  ) then begin
;            print, ' lower right, i =', i, ' delta =', d(i)
            if ( abs(d[i]) gt maxdiff ) then begin
                d(i) = 0.0
            end
        end

        for i = 0, 6 do begin
            (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] = (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] - d[i]
        end

        for i = 0, 6 do begin
          ; upper left
            del[0]=median((*DataSet.Frames[n])[127+128*i,1024:2047]-(*DataSet.Frames[n])[128+128*i,1024:2047])
            del[1]=median((*DataSet.Frames[n])[122+128*i,1024:2047]-(*DataSet.Frames[n])[133+128*i,1024:2047])
            del[2]=median((*DataSet.Frames[n])[117+128*i,1024:2047]-(*DataSet.Frames[n])[138+128*i,1024:2047])
            del[3]=median((*DataSet.Frames[n])[112+128*i,1024:2047]-(*DataSet.Frames[n])[143+128*i,1024:2047])
            del[4]=median((*DataSet.Frames[n])[107+128*i,1024:2047]-(*DataSet.Frames[n])[148+128*i,1024:2047])
            d[i] = median(del)
;            val = median( (*DataSet.Frames[n])[(107+128*i):(127+128*i),1024:2047] )
;            d(i)=median( (*DataSet.Frames[n])[(117+128*i):(127+128*i),0:1023]-(*DataSet.Frames[n])[(128+128*i):(138+128*i),0:1023])
;            if ( (abs(d[i]) lt maxdiff) and (abs(val/d[i]) lt 4.0)  ) then begin
;            print, ' upper left, i =', i, ' delta =', d
            if ( abs(d[i]) gt maxdiff ) then begin
                d(i) = 0.0
            end
        end
        for i = 0, 6 do begin
            (*DataSet.Frames[n])[0:(127+128*i),1024:2047] = (*DataSet.Frames[n])[0:(127+128*i),1024:2047] - d[i]
        end

;        for i = 0, 7 do begin
        for i = 0, 6 do begin
          ; lower left - check the ends with the
          ;    right quadrant so spectra
          ;    aren't compared.
;            del[0]=median((*DataSet.Frames[n])[1018:1023,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1024:1029,(128*i):(127+128*i)])
;            del[1]=median((*DataSet.Frames[n])[1012:1017,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1030:1035,(128*i):(127+128*i)])
;            del[2]=median((*DataSet.Frames[n])[1006:1011,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1036:1041,(128*i):(127+128*i)])
;            del[3]=median((*DataSet.Frames[n])[1000:1005,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1042:1047,(128*i):(127+128*i)])
;            del[4]=median((*DataSet.Frames[n])[994:999,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1048:1053,(128*i):(127+128*i)])
;            d = median(del)
;            val = median( (*DataSet.Frames[n])[994:1023,(128*i):(127+128*i)] )
;            if ( (abs(d) lt maxdiff) and (abs(val/d) lt 4.0)  ) then begin
            d[0] = median((*DataSet.Frames[n])[0:1023,(0+128*i):(127+128*i)]-(*DataSet.Frames[n])[0:1023,(128+128*i):(255+128*i)])
            print, ' lower left, i =', i, ' delta =', d[0]
            if ( abs(d[0]) lt maxdiff ) then begin
                (*DataSet.Frames[n])[0:1023,0:(127+128*i)] = (*DataSet.Frames[n])[0:1023,0:(127+128*i)] - d[0]
                del_lower = del_lower + d[0]
                num_lower = num_lower + 1.0
            end


          ; upper right - check the ends with the
          ;    left quadrant so spectra
          ;    aren't compared.
;            del[0]=median((*DataSet.Frames[n])[1024:1029,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1018:1023,(1024+128*i):(1151+128*i)])
;            del[1]=median((*DataSet.Frames[n])[1030:1035,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1012:1017,(1024+128*i):(1151+128*i)])
;            del[2]=median((*DataSet.Frames[n])[1036:1041,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1006:1011,(1024+128*i):(1151+128*i)])
;            del[3]=median((*DataSet.Frames[n])[1042:1047,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1000:1005,(1024+128*i):(1151+128*i)])
;            del[4]=median((*DataSet.Frames[n])[1048:1053,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[994:999,(1024+128*i):(1151+128*i)])
;            d = median(del)
            d[0] = median((*DataSet.Frames[n])[1024:2047,(1024+128*i):(1151+128*i)]-(*DataSet.Frames[n])[1024:2047,(1152+128*i):(1279+128*i)])
            if ( (jul_date ge 53873.0) and (i eq 0) and (jul_date le 53913.0) ) then begin
                d[0] = 0
                (*DataSet.IntAuxFrames[n])[1024:2047,1024:1151]=0 ; Flag the channel as bad
                print, "Lower channel in upper right quad is marked as bad..."
            end
;            val = median( (*DataSet.Frames[n])[1024:1053,(1024+128*i):(1151+128*i)] )
;            if ( (abs(d) lt maxdiff) and (abs(val/d) lt 4.0)  ) then begin
            print, ' upper right, i =', i, ' delta =', d[0]
            if ( abs(d[0]) lt maxdiff ) then begin
                (*DataSet.Frames[n])[1024:2047,1024:(1151+128*i)] = (*DataSet.Frames[n])[1024:2047,1024:(1151+128*i)] - d[0]
                print, ' upper right, i =', i, ' delta =', d[0]
                del_upper = del_upper + d[0]
                num_upper = num_upper + 1.0
            end
        end 

        ; For temporary use, match left and right lower quadrants
        d[0] = median((*DataSet.Frames[n])[923:1023,0:1023]-(*DataSet.Frames[n])[1024:1124,0:1023])
        if ( abs(d[0]) lt maxdiff ) then begin
            (*DataSet.Frames[n])[0:1023,0:1023] = (*DataSet.Frames[n])[0:1023,0:1023] - d[0]/2.0
            (*DataSet.Frames[n])[1024:2047,0:1023] = (*DataSet.Frames[n])[1024:2047,0:1023] + d[0]/2.0
        end

        ; For temporary use, match left and right upper quadrants
        d[0] = median((*DataSet.Frames[n])[923:1023,1024:2047]-(*DataSet.Frames[n])[1024:1124,1024:2047])
        if ( abs(d[0]) lt maxdiff ) then begin
            (*DataSet.Frames[n])[0:1023,1024:2047] = (*DataSet.Frames[n])[0:1023,1024:2047] - d[0]/2.0
            (*DataSet.Frames[n])[1024:2047,1024:2047] = (*DataSet.Frames[n])[1024:2047,1024:2047] + d[0]/2.0
        end


        ; Match upper and lower quadrants
        if ( (jul_date ge 53873.0) and (i eq 0) and (jul_date le 53913.0) ) then begin
            del[0]=median((*DataSet.Frames[n])[0:1023,1023]-(*DataSet.Frames[n])[0:1023,1025])
            del[1]=median((*DataSet.Frames[n])[0:1023,1022]-(*DataSet.Frames[n])[0:1023,1026])
            del[2]=median((*DataSet.Frames[n])[0:1023,1021]-(*DataSet.Frames[n])[0:1023,1027])
            del[3]=median((*DataSet.Frames[n])[0:1023,1020]-(*DataSet.Frames[n])[0:1023,1028])
            del[4]=median((*DataSet.Frames[n])[0:1023,1019]-(*DataSet.Frames[n])[0:1023,1029])
            d[0] = median(del)
            print, ' upper and lower halves, using left side only, delta =', d[0]
        endif else begin
            del[0]=median((*DataSet.Frames[n])[0:2047,1023]-(*DataSet.Frames[n])[0:2047,1025])
            del[1]=median((*DataSet.Frames[n])[0:2047,1022]-(*DataSet.Frames[n])[0:2047,1026])
            del[2]=median((*DataSet.Frames[n])[0:2047,1021]-(*DataSet.Frames[n])[0:2047,1027])
            del[3]=median((*DataSet.Frames[n])[0:2047,1020]-(*DataSet.Frames[n])[0:2047,1028])
            del[4]=median((*DataSet.Frames[n])[0:2047,1019]-(*DataSet.Frames[n])[0:2047,1029])
            d[0] = median(del)
            print, ' upper and lower halves, using left side only, delta =', d[0]
        end
;        if ( num_upper gt 0.0 ) then del_upper = del_upper / num_upper
;        if ( num_lower gt 0.0 ) then del_lower = del_lower / num_lower
;        print, ' del_upper ', del_upper, ' del_lower =', del_lower
;        if ( abs(d) lt 3.0*abs(del_lower - del_upper) ) then begin 
        (*DataSet.Frames[n])[0:2047,0:1023] = (*DataSet.Frames[n])[0:2047,0:1023] - d[0]/2.0
        (*DataSet.Frames[n])[0:2047,1024:2047] = (*DataSet.Frames[n])[0:2047,1024:2047] + d[0]/2.0
;        endif else begin
;            (*DataSet.Frames[n])[0:2047,0:1023] = (*DataSet.Frames[n])[0:2047,0:1023] + del_lower
;            (*DataSet.Frames[n])[0:2047,1024:2047] = (*DataSet.Frames[n])[0:2047,1024:2047] + del_upper
;        end

    end

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
