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
; 	COMBINE_METHOD		can be "AVERAGE" or "MEDIAN"
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
; 	2007-10-23   Algorithm rewritten, vectorized. 60x speedup for combining 4
; 	frames. Also you can now choose to median or average and it works properly. 
; 		- M. Perrin
; 	2007-11-30. Minor bugfix for above changes. M. Perrin
;
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

	thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
	if tag_exist( Modules[thisModuleIndex], "Combine_Method") then Combine_Method = Modules[thisModuleIndex].Combine_Method else Combine_Method="MEDIAN"
	Combine_Method = strupcase(Combine_Method)
	if Combine_Method ne "AVERAGE" and  Combine_Method ne "MEDIAN" then return, error ('Error: '+combine_method+' is not a valid combination method.')
    

    ; do the subtraction
    n_Dims = size( *DataSet.Frames(0))
    print, "Number of frames = ", nFrames
    print, "Size of each =", n_Dims
	print, "Combining using method = "+combine_method
    if ( n_Dims(0) ne 2 ) then  $
      return, error ('Error, frames must be 2 dimensional')
    if ( n_Dims(1) ne 2048 ) then $
      return, error ('Error, x-dim must be 2048')
    if ( n_Dims(2) ne 2048 ) then $
      return, error ('Error, y-dim must be 2048')

    itime = float(SXPAR(*DataSet.Headers[0],'ITIME'))
    if ( itime lt 1.0 ) then itime = 2.0
    print, 'itime=', itime

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

    ; Define range to bin data for finding mode of distribution.
    range = 10.0
    bsize = range/(itime*100.0)
    bmin = -range/itime
    nbin = 200
    shifts = bsize*findgen(nbin)+bmin

    ; Match levels of each frame one channel at a time.
    ; Lower left quadrant
    x1=0
    x2=1023
    y1=0
    y2=127
    for i = 0, 7 do begin
        for n = 0, (nFrames-1) do begin
;            delta = median(avg[x1:x2,(y1+128*i):(y2+128*i)] -
;            (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)])
            ; Switch to using the mode of the distribution.
            temp = avg[x1:x2,(y1+128*i):(y2+128*i)] - (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]
            hist = histogram(temp,binsize=bsize,min=bmin,nbins=nbin)
            m = max(hist,loc)
            delta = shifts[loc] ; This will be the mode of the histogram.
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
;            delta = median(avg[x1:x2,(y1+128*i):(y2+128*i)] - (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)])
            temp = avg[x1:x2,(y1+128*i):(y2+128*i)] - (*DataSet.Frames[n])[x1:x2,(y1+128*i):(y2+128*i)]
            hist = histogram(temp,binsize=bsize,min=bmin,nbins=nbin)
            m = max(hist,loc)
            delta = shifts[loc] ; This will be the mode of the histogram.
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
;            delta = median(avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2])
            temp = avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]
            hist = histogram(temp,binsize=bsize,min=bmin,nbins=nbin)
            m = max(hist,loc)
            delta = shifts[loc] ; This will be the mode of the histogram.
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
;            delta = median(avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2])
            temp = avg[(x1+128*i):(x2+128*i),y1:y2] - (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]
            hist = histogram(temp,binsize=bsize,min=bmin,nbins=nbin)
            m = max(hist,loc)
            delta = shifts[loc] ; This will be the mode of the histogram.
            (*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]=(*DataSet.Frames[n])[(x1+128*i):(x2+128*i),y1:y2]+delta
        end
    end

    ; Now finally combine the frames into
    ; a single frame through medianing
    ; each pixel where valid.

	;t0 = systime(1)
	;print, "here"
	;--MDP New vectorized version follows
	tmparr = fltarr(2048,2048,nframes)
	; pack 'em all into one big 3D array
	for n=0L,nframes-1 do begin 
		tmparr[0,0,n] = *DataSet.Frames[n] 
		wbad = where((*DataSet.IntAuxFrames[n]) ne 9, badct) 
		if badct gt 0 then tmparr[wbad+ 2048l*2048l*n] = !values.f_nan 
	endfor 

	; combine!
	case combine_method of
	"AVERAGE":  tot = total(tmparr,3,/nan) / total(finite(tmparr),3,/nan)
	"MEDIAN": tot = median(tmparr,dim=3)
	"AVGCLIP": message, "AVGCLIP method not yet implemented!!"
	else:
	endcase

	valid = replicate(9b, 2048, 2048)
	; NOTE: do NOT use "where(not finite())" on BYTE type data, since not(1)=254
	; which is true!  You can use "where(~finite())" and that's OK but requires
	; IDL > 6.0
	wvalid = where(finite(tot), comp=wnotvalid, ncomp=nvcount) 
	if nvcount gt 0 then begin
		valid[wnotvalid] = 0
		tot[wnotvalid] = 0
	endif
	

	(*DataSet.Frames[0]) = tot
	(*DataSet.IntAuxFrames[0]) = valid
	
;OLD VERSION	;print, "here"
;OLD VERSION
;OLD VERSION	 T1 = systime(1)
;OLD VERSION	 
;OLD VERSION
;OLD VERSION    valid = bytarr(nFrames)
;OLD VERSION    data = fltarr(nFrames)
;OLD VERSION    for i = 0, 2047 do begin
;OLD VERSION        for j = 0, 2047 do begin
;OLD VERSION            for n = 0, (nFrames-1) do begin
;OLD VERSION                valid[n]=(*DataSet.IntAuxFrames[n])[i,j]
;OLD VERSION                data[n] =(*DataSet.Frames[n])[i,j]
;OLD VERSION            end
;OLD VERSION            loc = where( valid eq 9, cnt)
;OLD VERSION            (*DataSet.IntAuxFrames[0])[i,j] = 0
;OLD VERSION            if ( cnt gt 0 ) then begin
;OLD VERSION;                (*DataSet.Frames[0])[i,j] = median( data[loc] )
;OLD VERSION                (*DataSet.Frames[0])[i,j] = mean( data[loc] )
;OLD VERSION                (*DataSet.IntAuxFrames[0])[i,j] = 9
;OLD VERSION            end
;OLD VERSION        end
;OLD VERSION    end
;OLD VERSION
;OLD VERSION	 T2 = systime(1)
;OLD VERSION
;OLD VERSION	 print, "old method, avg:", t2-t1
;OLD VERSION	 print, "new method, avg -and- median:", t1-t0
;OLD VERSION	stop
	

    for i = 1, (nFrames-1) do clear_frame, DataSet, i, /ALL
    dummy = Backbone->setValidFrameCount(DataSet.Name, 1)

    itime = string(sxpar(*DataSet.Headers[0], 'ITIME'))


    fname = sxpar(*DataSet.Headers[0],'DATAFILE')
    fname = strtrim(fname,2) + '_combo_'+strtrim(itime,2)
    fname = strtrim(fname,2)
    print, fname
    SXADDPAR, *DataSet.Headers[0], "DATAFILE", fname
	sxaddhist, "Combined "+strtrim(string(nframes),2)+" frames via "+combine_method+" method."



    report_success, functionName, T

    RETURN, OK

END
