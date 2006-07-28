
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME combframes
;
; @PURPOSE Takes multiple frames and merges them into a "super frame".
;          It assumes that each of the frames is virtually identical
;          like darks or skies. Each of the 32 channels is treated
;          individually and is adjusted to match the others in
;          level. The final combination is done by medianing the valid
;          pixels at each location.
;
; @@@PARAMETERS
;
; @CALIBRATION-FILES None
;
; @INPUT Raw data
;
; @OUTPUT The dataset contains the final frame. numframes is set to 1
;          after routine.
;
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
; @HISTORY  July 8, 2006
	
; @AUTHOR  James Larkin 
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION combframes_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'combframes_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    
    ; do the subtraction
    n_Dims = size( *DataSet.Frames(0))
    print, "Number of frames = ", nFrames
    print, "Size of each =", n_Dims
    if ( n_Dims(0) ne 2 ) then  $
      return, error ('Error, frames must be 2 dimensional')
    if ( n_Dims(1) ne 2048 ) then $
      return, error ('Error, x-dim must be 2048')
    if ( n_Dims(2) ne 2048 ) then $
      return, error ('Error, y-dim must be 2048')

    if ( nFrames lt 2 ) then $
      return, error ('Combframes requires at least 2 frames.')

    ; Create an average frame to determine the offset levels
    avg = fltarr(2048,2048)
    num = fltarr(2048,2048)
    for n = 0, (nFrames - 1) do begin
        loc = where (*DataSet.IntAuxFrames[n] eq 9)
        avg(loc) = avg(loc)+ (*DataSet.Frames[n])[loc]
        num(loc) = num(loc) + 1
    end
    loc = where (num gt 0.0 )
    avg[loc] = avg[loc] / num[loc]

    ; Match levels of each frame one channel at a time.
    ; Lower left quadrant
    x1=0
    x2=1023
    y1=0
    y2=127
    for i = 0, 7 do begin
        for n = 0, (nFrames-1) do begin
            delta = median(avg[x1:x2,(y1+128*i):(y2+128*i)] - (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)])
            (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]=(*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]+delta
        end
    end

    ; Upper right quadrant
    x1=1024
    x2=2047
    y1=1024
    y2=1151
    for i = 0, 7 do begin
        for n = 0, (nFrames-1) do begin
            delta = median(avg[x1:x2,(y1+128*i):(y2+128*i)] - (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)])
            (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]=(*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]+delta
        end
    end

    ; Upper left quadrant
    x1=0
    x2=127
    y1=1024
    y2=2047
    for i = 0, 7 do begin
        for n = 0, (nFrames-1) do begin
            delta = median(avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2])
            (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]=(*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]+delta
        end
    end

    ; Lower right quadrant
    x1=1024
    x2=1151
    y1=0
    y2=1023
    for i = 0, 7 do begin
        for n = 0, (nFrames-1) do begin
            delta = median(avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2])
            (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]=(*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]+delta
        end
    end

    ; Now finally combine the frames into
    ; a single frame through medianing
    ; each pixel where valid.


    valid = bytarr(nFrames)
    data = fltarr(nFrames)
    for i = 0, 2047 do begin
        for j = 0, 2047 do begin
            for n = 0, (nFrames-1) do begin
                valid[n]=(*DataSet.IntAuxFrames[n])[i,j]
                data[n] =(*DataSet.Frames[n])[i,j]
            end
            loc = where( valid eq 9, cnt)
            (*DataSet.IntAuxFrames[0])[i,j] = 0
            if ( cnt gt 0 ) then begin
                (*DataSet.Frames[0])[i,j] = median( data[loc] )
                (*DataSet.IntAuxFrames[0])[i,j] = 9
            end
        end
    end

    for i = 1, (nFrames-1) do clear_frame, DataSet, i, /ALL
    dummy = Backbone->setValidFrameCount(DataSet.Name, 1)


    report_success, functionName, T

    RETURN, OK

END
