
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

          ; lower left
           del[0]=median((*DataSet.Frames[n])[0:1023,127+128*i]-(*DataSet.Frames[n])[0:1023,128+128*i])
           del[1]=median((*DataSet.Frames[n])[0:1023,122+128*i]-(*DataSet.Frames[n])[0:1023,133+128*i])
           del[2]=median((*DataSet.Frames[n])[0:1023,117+128*i]-(*DataSet.Frames[n])[0:1023,138+128*i])
           del[3]=median((*DataSet.Frames[n])[0:1023,112+128*i]-(*DataSet.Frames[n])[0:1023,143+128*i])
           del[4]=median((*DataSet.Frames[n])[0:1023,107+128*i]-(*DataSet.Frames[n])[0:1023,148+128*i])
           d = median(del)
           if ( abs(d) lt maxdiff ) then $
             (*DataSet.Frames[n])[0:1023,0:(127+128*i)] = (*DataSet.Frames[n])[0:1023,0:(127+128*i)] - d

          ; upper right
           del[0]=median((*DataSet.Frames[n])[1024:2047,1151+128*i]-(*DataSet.Frames[n])[1024:2047,1152+128*i])
           del[1]=median((*DataSet.Frames[n])[1024:2047,1146+128*i]-(*DataSet.Frames[n])[1024:2047,1157+128*i])
           del[2]=median((*DataSet.Frames[n])[1024:2047,1141+128*i]-(*DataSet.Frames[n])[1024:2047,1162+128*i])
           del[3]=median((*DataSet.Frames[n])[1024:2047,1136+128*i]-(*DataSet.Frames[n])[1024:2047,1167+128*i])
           del[4]=median((*DataSet.Frames[n])[1024:2047,1131+128*i]-(*DataSet.Frames[n])[1024:2047,1172+128*i])
           d = median(del)
           if ( abs(d) lt maxdiff ) then $
             (*DataSet.Frames[n])[1024:2047,1024:(1151+128*i)] = (*DataSet.Frames[n])[1024:2047,1024:(1151+128*i)] - d
       end 

       ; Now adjust the lower left to the lower right quad
       del[0] = median((*DataSet.Frames[n])[1023,0:1023]-(*DataSet.Frames[n])[1024,0:1023])
       del[1] = median((*DataSet.Frames[n])[1022,0:1023]-(*DataSet.Frames[n])[1025,0:1023])
       del[2] = median((*DataSet.Frames[n])[1021,0:1023]-(*DataSet.Frames[n])[1026,0:1023])
       del[3] = median((*DataSet.Frames[n])[1020,0:1023]-(*DataSet.Frames[n])[1027,0:1023])
       del[4] = median((*DataSet.Frames[n])[1019,0:1023]-(*DataSet.Frames[n])[1028,0:1023])
       print, del
       d = median(del)
       print, "lower quad offset=",d,abs(d)
       if ( abs(d) lt maxdiff ) then begin
           print, "Adjusting lower quadrants"
           (*DataSet.Frames[n])[0:1023,0:1023] = (*DataSet.Frames[n])[0:1023,0:1023] - (d/2.0)
           (*DataSet.Frames[n])[1024:2047,0:1023] = (*DataSet.Frames[n])[1024:2047,0:1023] + (d/2.0)
       endif

       ; Adjust the upper left to the upper right
       del[0] = median((*DataSet.Frames[n])[1023,1024:2047]-(*DataSet.Frames[n])[1024,1024:2047])
       del[1] = median((*DataSet.Frames[n])[1022,1024:2047]-(*DataSet.Frames[n])[1025,1024:2047])
       del[2] = median((*DataSet.Frames[n])[1021,1024:2047]-(*DataSet.Frames[n])[1026,1024:2047])
       del[3] = median((*DataSet.Frames[n])[1020,1024:2047]-(*DataSet.Frames[n])[1027,1024:2047])
       del[4] = median((*DataSet.Frames[n])[1019,1024:2047]-(*DataSet.Frames[n])[1028,1024:2047])
       print, del
       d = median(del)
       print, "upper quad offset=",d,abs(d)
       if ( abs(d) lt maxdiff ) then begin
           print, "Adjusting upper quadrants"
           (*DataSet.Frames[n])[0:1023,1024:2047] = (*DataSet.Frames[n])[0:1023,1024:2047] - (d/2.0)
           (*DataSet.Frames[n])[1024:2047,1024:2047] = (*DataSet.Frames[n])[1024:2047,1024:2047] + (d/2.0)
       endif

       del = fltarr(11)
       ; Finally adjust the upper half to the lower half of the detector.
       del[0] = median((*DataSet.Frames[n])[0:2047,1020]-(*DataSet.Frames[n])[0:2047,1030])
       del[1] = median((*DataSet.Frames[n])[0:2047,1015]-(*DataSet.Frames[n])[0:2047,1035])
       del[2] = median((*DataSet.Frames[n])[0:2047,1010]-(*DataSet.Frames[n])[0:2047,1040])
       del[3] = median((*DataSet.Frames[n])[0:2047,1005]-(*DataSet.Frames[n])[0:2047,1045])
       del[4] = median((*DataSet.Frames[n])[0:2047,1000]-(*DataSet.Frames[n])[0:2047,1050])
       del[5] = median((*DataSet.Frames[n])[0:2047,995]-(*DataSet.Frames[n])[0:2047,1055])
       del[6] = median((*DataSet.Frames[n])[0:2047,990]-(*DataSet.Frames[n])[0:2047,1060])
       del[7] = median((*DataSet.Frames[n])[0:2047,985]-(*DataSet.Frames[n])[0:2047,1065])
       del[8] = median((*DataSet.Frames[n])[0:2047,980]-(*DataSet.Frames[n])[0:2047,1070])
       del[9] = median((*DataSet.Frames[n])[0:2047,975]-(*DataSet.Frames[n])[0:2047,1075])
       del[10] = median((*DataSet.Frames[n])[0:2047,970]-(*DataSet.Frames[n])[0:2047,1080])
       d = median(del)
       print, "upper & lower half offset=",d,abs(d)
       if ( abs(d) lt maxdiff ) then begin
           (*DataSet.Frames[n])[0:2047,0:1023] = (*DataSet.Frames[n])[0:2047,0:1023] - d/2.0
           (*DataSet.Frames[n])[0:2047,1024:2047] = (*DataSet.Frames[n])[0:2047,1024:2047] + d/2.0
       endif

    end

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
