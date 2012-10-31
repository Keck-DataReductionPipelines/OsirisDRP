
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
; @MODIFICATIONS
;            - On June 5, 2006 changed it to only look prependicular
;              to spectra. JEL
;
;            - Also started checking the date of the observations. If
;              it is after May 18, 2006, then ignore the lowest
;              channel in the upper right quad. This includes marking
;              it as bad. This is done by checking the modified Julian
;              date against 53873 (May 18, 2006).
;
;            - Bad channel was fixed on June 27, 2006, so added check
;              if Julian date is after 53913. (SAW/JEL)
;
;	     - When temps are high (>75 K) threshold needs to be modified
;		dependent on julian date from 01/2009 to 10/2009
;		(SAW - Oct 2009)
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

        ; Calculate and subtract the difference between neighboring
        ; channels. Only subtract if the difference is less than 5
        ; datanumbers when corrected back to the total exposure time.
 

	;; Added a julian date search for high temp data in 2009A/B (saw edit)
	;; and changed the threshold for detecting difference in channels 
     itime = float(SXPAR(head,"ITIME",/SILENT))
     print, 'Julian Date for this Observations  ',jul_date
     if (jul_date ge 54832.5) and (jul_date le 55114.5) then begin 
		maxdiff = 6.0/itime
		print, 'Using threshold for warm detector mode in 2009' 
     endif else begin	
    	 maxdiff = 4.0/itime
	 print,'Using threshold for stable detector operating temps'
     endelse
;	if (jul_date ge 54832.5) and (jul_date le 55114.5) then maxdiff = 6.0/itime $
;		else maxdiff = 4.0/itime
     print, 'Maximum allowed offset= ', maxdiff

        ; For each channel boundary use 5 different sets of columns in order
        ; to find true background in the case that a spectrum spans the
        ; boundary.
        del = fltarr(5)
        d = fltarr(7)
   ;********************************************
   ; channels within the lower right quadrant
   ;********************************************
        for i = 0, 6 do begin
            ; For each channel boundary in the lower right quadrant, calculate the
            ; difference for the pixels on the boundary. Do this for five different
            ; sets of strips. For each set of paired strips take the median of
            ; those that are within 5 times the maximum allowed step function. Then
            ; median the five resulting measurements of the step functions.
            del = del - del
            tmp =( (*DataSet.Frames[n])[1151+128*i,0:1023]-(*DataSet.Frames[n])[1152+128*i,0:1023])
            loc = where ( abs(tmp) lt 2.0*maxdiff,cnt)
            if ( loc[0] ne -1 ) then $
            del[0] = median( tmp[loc] )
            tmp=( (*DataSet.Frames[n])[1146+128*i,0:1023]-(*DataSet.Frames[n])[1157+128*i,0:1023])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1] = median( tmp[loc] )
            tmp=( (*DataSet.Frames[n])[1141+128*i,0:1023]-(*DataSet.Frames[n])[1162+128*i,0:1023])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2] = median( tmp[loc] )
            tmp=( (*DataSet.Frames[n])[1136+128*i,0:1023]-(*DataSet.Frames[n])[1167+128*i,0:1023])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3] = median( tmp[loc] )
            tmp=( (*DataSet.Frames[n])[1131+128*i,0:1023]-(*DataSet.Frames[n])[1172+128*i,0:1023])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[4] = median( tmp[loc] )
            d[i] = median(del)
            ; If the measured step function is above the maximum allowed value,
            ; then ignore the step and set it to 0.0.
            if ( abs(d[i]) gt maxdiff ) then begin
                d(i) = 0.0
            end
	    ;print,'step function for lower right quadrant',abs(d[i])
        end
	; Apply the shifts for the channels in the lower right channel.
        for i = 0, 6 do begin
            (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] = (*DataSet.Frames[n])[1024:(1151+128*i),0:1023] - d[i]
        end
        (*DataSet.Frames[n])[1024:2047,0:1023] = (*DataSet.Frames[n])[1024:2047,0:1023] + mean(d)

   ;********************************************
   ; channels within the upper left quadrant
   ;********************************************
        for i = 0, 6 do begin
            ; For each channel boundary in the upper left quadrant, calculate the
            ; difference for the pixels on the boundary. Do this for five different
            ; sets of strips. For each set of paired strips take the median of
            ; those that are within 5 times the maximum allowed step function. Then
            ; median the five resulting measurements of the step functions.
            del = del - del
            tmp=((*DataSet.Frames[n])[127+128*i,1024:2047]-(*DataSet.Frames[n])[128+128*i,1024:2047])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[0] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[122+128*i,1024:2047]-(*DataSet.Frames[n])[133+128*i,1024:2047])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[117+128*i,1024:2047]-(*DataSet.Frames[n])[138+128*i,1024:2047])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[112+128*i,1024:2047]-(*DataSet.Frames[n])[143+128*i,1024:2047])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[107+128*i,1024:2047]-(*DataSet.Frames[n])[148+128*i,1024:2047])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[4] = median( tmp[loc] )
            d[i] = median(del)
	   ; print,'step function for upper left quadrant',abs(d[i])
	   ; If the measured step function is above the maximum allowed value,
            ; then ignore the step and set it to 0.0.
            if ( abs(d[i]) gt maxdiff ) then begin
                d(i) = 0.0
            end
	    print,'step function for upper left quadrant',abs(d[i])
        end
        ; Apply the shifts for the upper left channels.
        for i = 0, 6 do begin
            (*DataSet.Frames[n])[0:(127+128*i),1024:2047] = (*DataSet.Frames[n])[0:(127+128*i),1024:2047] - d[i]
        end
        (*DataSet.Frames[n])[0:1023,1024:2047] = (*DataSet.Frames[n])[0:1023,1024:2047] + mean(d)

; For the channels with boundaries aligned with the spectra, we check
; both sides of the channel, plus the end that overlaps with the first
; channel in the other quadrant.
        bound = fltarr(7) ; Measurement of the six channel boundaries
        ends = fltarr(8)  ; Measurement of the seven end boundaries
   ;********************************************
   ; channels within the lower left quadrant
   ;********************************************
        for i = 0, 6 do begin
            del = del - del
            ; Measure the boundaries between neighboring channels
            tmp= ((*DataSet.Frames[n])[0:1023,(128*i+127)]-(*DataSet.Frames[n])[0:1023,(128*i+129)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[0] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[0:1023,(128*i+126)]-(*DataSet.Frames[n])[0:1023,(128*i+128)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[0:1023,(128*i+125)]-(*DataSet.Frames[n])[0:1023,(128*i+131)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[0:1023,(128*i+124)]-(*DataSet.Frames[n])[0:1023,(128*i+130)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[0:1023,(128*i+123)]-(*DataSet.Frames[n])[0:1023,(128*i+133)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[4] = median( tmp[loc] )
            bound[i] = median(del)
        end
        for i = 0, 7 do begin
            del = del - del
            ; Measure the end boundaries.
            tmp=((*DataSet.Frames[n])[1018:1023,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1024:1029,(128*i):(127+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[0] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1012:1017,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1030:1035,(128*i):(127+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1006:1011,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1036:1041,(128*i):(127+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1000:1005,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1042:1047,(128*i):(127+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[994:999,(128*i):(127+128*i)]-(*DataSet.Frames[n])[1048:1053,(128*i):(127+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[4] = median( tmp[loc] )
            ends[i] = median(del)
        end
        shift = fltarr(8)
        for i = 1, 6 do begin
            s1 = ends[i]
            s2 = ends[i-1] - bound[i-1]
            s3 = bound[i] - ends[i+1]
            a1 = abs(s1)
            a2 = abs(s2)
            a3 = abs(s3)
            jk = [s1, s2, s3]
;            if ( (a1 lt a2) and (a1 lt a3) ) then shift[i] = s1 $	
;            else if ( a2 lt a3 ) then shift[i] = s2 $	
;            else shift[i] = s3	
            shift[i] = median(jk)
        end
        s1 = ends[0]
        s3 = bound[0] - ends[1]
;        if ( abs(s1) lt abs(s3) ) then shift[0] = s1 $	
;	     else shift[0]= s3			
        shift[0] = s3

        s1 = ends[7]
        s2 = ends[6] - bound[6]
 ;       if ( abs(s1) lt abs(s2) ) then shift[7] = s1 $	
  ;           else shift[7]= s2			
        shift[7] = s2
	
        ;print,'shifts for lower left quadrant (aligned with spectra)',abs(shift)

        for i = 0, 7 do begin	;******
            if ( abs(shift[i]) le maxdiff ) then $
              (*DataSet.Frames[n])[0:1023,(128*i):(128*i+127)] = (*DataSet.Frames[n])[0:1023,(128*i):(128*i+127)] - shift[i]
        end
        

   ;********************************************
   ; channels within the upper right quadrant
   ;********************************************
        bound = bound - bound
        ends = ends - ends
        for i = 0, 6 do begin
            del = del - del
            ; Measure the boundaries between neighboring channels
            tmp= ((*DataSet.Frames[n])[1024:2047,(128*i+1151)]-(*DataSet.Frames[n])[1024:2047,(128*i+1153)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[0] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[1024:2047,(128*i+1150)]-(*DataSet.Frames[n])[1024:2047,(128*i+1152)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[1] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[1024:2047,(128*i+1149)]-(*DataSet.Frames[n])[1024:2047,(128*i+1155)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[2] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[1024:2047,(128*i+1148)]-(*DataSet.Frames[n])[1024:2047,(128*i+1154)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[3] = median( tmp[loc] )
            tmp= ((*DataSet.Frames[n])[1024:2047,(128*i+1147)]-(*DataSet.Frames[n])[1024:2047,(128*i+1157)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[4] = median( tmp[loc] )
            bound[i] = median(del)
        end
        for i = 0, 7 do begin
            del = del - del
            ; Measure the end boundaries.
            tmp=((*DataSet.Frames[n])[1018:1023,(128*i+1024):(1151+128*i)]-(*DataSet.Frames[n])[1024:1029,(128*i+1024):(1151+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[0] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1012:1017,(128*i+1024):(1151+128*i)]-(*DataSet.Frames[n])[1030:1035,(128*i+1024):(1151+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[1] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1006:1011,(128*i+1024):(1151+128*i)]-(*DataSet.Frames[n])[1036:1041,(128*i+1024):(1151+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[2] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[1000:1005,(128*i+1024):(1151+128*i)]-(*DataSet.Frames[n])[1042:1047,(128*i+1024):(1151+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[3] = median( tmp[loc] )
            tmp=((*DataSet.Frames[n])[994:999,(128*i+1024):(1151+128*i)]-(*DataSet.Frames[n])[1048:1053,(128*i+1024):(1151+128*i)])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[4] = median( tmp[loc] )
            ends[i] = median(del)
        end
        shift = fltarr(8)
        for i = 1, 6 do begin
            s1 = ends[i]
            s2 = ends[i-1] + bound[i-1]
            s3 = ends[i+1] - bound[i]
            a1 = abs(s1)
            a2 = abs(s2)
            a3 = abs(s3)
 ;           if ( (a1 lt a2) and (a1 lt a3) ) then shift[i] = s1 $	
 ;           else if ( a2 lt a3 ) then shift[i] = s2 $	
 ;           else shift[i] = s3	
            jk = [s1, s2, s3]
            shift[i] = median(jk)
        end
        s1 = ends[0]
        s3 = ends[1] - bound[0]
;        if ( abs(s1) lt abs(s3) ) then shift[0] = s1 $	
;        else shift[0]= s3 
        shift[0]= s3

        s1 = ends[7]
        s2 = ends[6] + bound[6]
  ;      if ( abs(s1) lt abs(s2) ) then shift[7] = s1 $	
   ;        else shift[7]= s2	
        shift[7]= s2

	print,''
       ; print,'shifts for upper right quadrant (aligned with spectra)',abs(shift)
	
        for i = 0, 7 do begin
            if ( (jul_date ge 53873.0) and (i eq 0) and (jul_date le 53913.0) ) then begin
                (*DataSet.IntAuxFrames[n])[1024:2047,1024:1151]=0 ; Flag the channel as bad
                print, "Lower channel in upper right quad is marked as bad..."
            end
        if ( abs(shift[i]) le maxdiff ) then $				;******
              (*DataSet.Frames[n])[1024:2047,(128*i+1024):(128*i+1151)] = (*DataSet.Frames[n])[1024:2047,(128*i+1024):(128*i+1151)] + shift[i]
        end
        



        del = del - del
        ; match lower left and upper left quadrants
        tmp = ((*DataSet.Frames[n])[1023,0:1023]-(*DataSet.Frames[n])[1024,0:1023])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
       ; plot, loc, tmp[loc]
        if ( loc[0] ne -1 ) then $
        del[0] = median( tmp[loc] )
        tmp = ((*DataSet.Frames[n])[1022,0:1023]-(*DataSet.Frames[n])[1025,0:1023])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        ;oplot, loc, tmp[loc]
        if ( loc[0] ne -1 ) then $
        del[1] = median( tmp[loc] )
        tmp = ((*DataSet.Frames[n])[1021,0:1023]-(*DataSet.Frames[n])[1026,0:1023])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        ;oplot, loc, tmp[loc]
        if ( loc[0] ne -1 ) then $
        del[2] = median( tmp[loc] )
        tmp = ((*DataSet.Frames[n])[1020,0:1023]-(*DataSet.Frames[n])[1027,0:1023])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        ;oplot, loc, tmp[loc]
        if ( loc[0] ne -1 ) then $
        del[3] = median( tmp[loc] )
        tmp = ((*DataSet.Frames[n])[1019,0:1023]-(*DataSet.Frames[n])[1028,0:1023])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        ;oplot, loc, tmp[loc]
        if ( loc[0] ne -1 ) then $
        del[4] = median( tmp[loc] )
        d[0] = median( del )
        print, ' lower left to lower right quadrants ', d[0]
        if ( abs(d[0]) lt maxdiff ) then begin
            (*DataSet.Frames[n])[0:1023,0:1023] = (*DataSet.Frames[n])[0:1023,0:1023] - d[0]/2.0
            (*DataSet.Frames[n])[1024:2047,0:1023] = (*DataSet.Frames[n])[1024:2047,0:1023] + d[0]/2.0
        end

        del = del - del
        ; For temporary use, match left and right upper quadrants
        tmp=((*DataSet.Frames[n])[1023,1024:2047]-(*DataSet.Frames[n])[1024,1024:2047])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        if ( loc[0] ne -1 ) then $
        del[0] = median(tmp[loc])
        tmp=((*DataSet.Frames[n])[1022,1024:2047]-(*DataSet.Frames[n])[1025,1024:2047])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        if ( loc[0] ne -1 ) then $
        del[1] = median(tmp[loc])
        tmp=((*DataSet.Frames[n])[1021,1024:2047]-(*DataSet.Frames[n])[1026,1024:2047])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        if ( loc[0] ne -1 ) then $
        del[2] = median(tmp[loc])
        tmp=((*DataSet.Frames[n])[1020,1024:2047]-(*DataSet.Frames[n])[1027,1024:2047])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        if ( loc[0] ne -1 ) then $
        del[3] = median(tmp[loc])
        tmp=((*DataSet.Frames[n])[1019,1024:2047]-(*DataSet.Frames[n])[1028,1024:2047])
        loc = where ( abs(tmp) lt 2.0*maxdiff )
        if ( loc[0] ne -1 ) then $
        del[4] = median(tmp[loc])
        d[0] = median( del )
        print, ' upper left to lower right quadrants ', d[0]
        if ( abs(d[0]) lt maxdiff ) then begin
            (*DataSet.Frames[n])[0:1023,1024:2047] = (*DataSet.Frames[n])[0:1023,1024:2047] - d[0]/2.0
            (*DataSet.Frames[n])[1024:2047,1024:2047] = (*DataSet.Frames[n])[1024:2047,1024:2047] + d[0]/2.0
        end


        del = del - del
        ; Match upper and lower halves
        if ( (jul_date ge 53873.0) and (i eq 0) and (jul_date le 53913.0) ) then begin
            tmp = (*DataSet.Frames[n])[0:1023,1023]-(*DataSet.Frames[n])[0:1023,1025]
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[0]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:1023,1022]-(*DataSet.Frames[n])[0:1023,1026])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:1023,1021]-(*DataSet.Frames[n])[0:1023,1027])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:1023,1020]-(*DataSet.Frames[n])[0:1023,1028])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:1023,1019]-(*DataSet.Frames[n])[0:1023,1029])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[4]=median(tmp[loc])
            d[0] = median(del)
            print, ' upper and lower halves, using left side only, delta =', d[0]
        endif else begin
            tmp=((*DataSet.Frames[n])[0:2047,1023]-(*DataSet.Frames[n])[0:2047,1025])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[0]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:2047,1022]-(*DataSet.Frames[n])[0:2047,1026])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[1]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:2047,1021]-(*DataSet.Frames[n])[0:2047,1027])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[2]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:2047,1020]-(*DataSet.Frames[n])[0:2047,1028])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
            del[3]=median(tmp[loc])
            tmp=((*DataSet.Frames[n])[0:2047,1019]-(*DataSet.Frames[n])[0:2047,1029])
            loc = where ( abs(tmp) lt 2.0*maxdiff )
            if ( loc[0] ne -1 ) then $
              del[4]=median(tmp[loc])
            d[0] = median(del)
            print, ' upper and lower halves, using left side only, delta =', d[0]
        end
        if ( abs(d[0]) lt maxdiff ) then begin
            (*DataSet.Frames[n])[0:2047,0:1023] = (*DataSet.Frames[n])[0:2047,0:1023] - d[0]/2.0
            (*DataSet.Frames[n])[0:2047,1024:2047] = (*DataSet.Frames[n])[0:2047,1024:2047] + d[0]/2.0
        end

    end

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
