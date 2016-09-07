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
; 	COMBINE_METHOD		can be "AVERAGE" or "MEDIAN" or "AVGCLIP"
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
; 	2009-12. Added 'AVGCLIP' option. M. Perrin
;
; @AUTHOR  James Larkin 
;
; @END
;
;-----------------------------------------------------------------------

; This function now includes the AVGCLIP option from Mark Buie's library,
; included here.
;
;=============================================================================
;+
; NAME:
;   avgclip
; PURPOSE:
;   Average over a 3-D array, clipping unusual deviants.
; DESCRIPTION:
;   Calculate the average value of an array, or calculate the average
;   value over one dimension of an array as a function of all the other
;   dimensions.
; CATEGORY:
;   CCD data processing
; CALLING SEQUENCE:
;   avgclip,array,average,SCALE=scale,NORMALIZE=normalize
; INPUTS:
;   array = 3-D input array.  May be any type except string.
; OPTIONAL INPUT PARAMETERS:
; KEYWORD PARAMETERS:
;   SCALE - 4 element vector which, if provide, defines the region of the
;           array dimensions that are used to scale the mean
;           of the arrays before combining.  If combined in this
;           manner, the arrays are combined weighted by the means.
;                 [x1,x2,y1,y2]
;
;   NORMALIZE - Flag, if set and SCALE used, leaves the output average
;                 normalized by the SCALE region.
;
;   SILENT - Flat, if set will suppress all messages to screen.
;
;   THRESH - Threshold, in units of a standard deviation, to flag and thus
;               remove outliers.  The default is 3.0 sigma.
;
; OUTPUTS:
;   average - 2-D array that is the robust average of the stack.
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;   1992 Dec 30, Marc W. Buie, Lowell Observatory, cloned from AVG
;      and added average sigma clipping.
;   95/03/10, MWB, extensive re-write to optimize.
;   97/06/19, MWB, added SILENT keyword
;   2000/09/22, MWB, added THRESH keyword
;   2006-10-20. MDP: Added /weight_by_exptimes and exptimes.
;-
PRO buie_avgclip,arr,average,scale=scale,NORMALIZE=normalize,SILENT=silent, $
       THRESH=thresh,$
	   weight_by_exptimes=weight_by_exptimes,exptimes=exptimes

;on_error,2

s = size(arr)

;Verify correct number of parameters.
if n_params() ne 2 then begin
   print,'avgclip,arr,result,[SCALE=region],[/NORMALIZE]'
   return
endif

;Verify correct type of input array.
if s[0] ne 3 then message,'Error *** Array must be 3-D.'
nimg=s[3]
if nimg le 2 then message,'Error *** There must be at least 3 images in cube.'

if badpar(thresh,[0,2,3,4,5],0,caller='AVGCLIP: (THRESH) ',default=3.0) then return

;Verify the scaling region, if passed.
if keyword_set(scale) then begin
   prescale = 1
   if n_elements(scale) ne 4 then begin
      print,'AVGCLIP: Error *** scaling region must be a four element vector'
      return
   endif
   x1 = scale[0]
   x2 = scale[1]
   y1 = scale[2]
   y2 = scale[3]

   if scale[0] lt 0    then message,'Start of X region is less than zero.'
   if scale[0] ge s[1] then message,'Start of X region is greater than array size.'
   if scale[1] lt 0    then message,'End of X region is less than zero.'
   if scale[1] ge s[1] then message,'End of X region is greater than array size.'
   if scale[2] lt 0    then message,'Start of Y region is less than zero.'
   if scale[2] ge s[2] then message,'Start of Y region is greater than array size.'
   if scale[3] lt 0    then message,'End of Y region is less than zero.'
   if scale[3] ge s[2] then message,'End of Y region is greater than array size.'
   if scale[0] gt scale[1] then message,'Start of X region is greater than end.'
   if scale[2] gt scale[3] then message,'Start of Y region is greater than end.'
endif else begin
   prescale = 0
endelse

average = fltarr( s[1], s[2], /nozero)

cr = string("15b)  ;"
form='($,a,a,i4,a,g,f6.1,1x,f6.1)'

;cputime,utimez,stimez

;Do scaled robust averaging
if prescale then begin
   means = fltarr( nimg )
   for i=0,nimg-1 do begin
      robomean,arr[x1:x2,y1:y2,i],3.0,0.5,meanval,dummy,sigma
      means[i] = meanval
;      means[i] = mean(arr[x1:x2,y1:y2,i])
      arr[*,*,i]=arr[*,*,i]/means[i]
      IF not keyword_set(silent) THEN $
         print,'Frame ',i,'  scaled by ',means[i]
   endfor
endif

IF not keyword_set(silent) THEN $
   print,'First pass median average of stack.'
;medarr_mwb,arr,avg
avg = median(arr, dim=3)
;return

;IF not keyword_set(silent) THEN $
;   print,'create minmax clipped average image'
;low = arr[*,*,0]
;hi  = arr[*,*,1]
;z = where(low gt hi, count)
;if count ne 0 then begin
;   tmp    = low[z]
;   low[z] = hi[z]
;   hi[z]  = tmp
;endif
;accum=fltarr(s[1],s[2])
;for i=2,nimg-1 do begin
;   new = arr[*,*,i]
;   z = where(new lt low, count)
;   if count ne 0 then begin
;      tmp = low[z]
;      low[z] = new[z]
;      new[z] = tmp
;   endif
;   z = where(new gt hi, count)
;   if count ne 0 then begin
;      tmp = hi[z]
;      hi[z] = new[z]
;      new[z] = tmp
;   endif
;   accum = accum + new
;endfor
;setwin,2,xsize=s[1],ysize=s[2]
;tvscl,accum
;avg=median(accum/(nimg-2),11)

;setwin,3,xsize=s[1],ysize=s[2]
;tvscl,avg

IF not keyword_set(silent) THEN print,'create sigma array'
;sig=fltarr(s[1],s[2])
;for i=0,nimg-1 do $
;   sig = sig + (arr[*,*,i]-avg)^2
sigma=sqrt(avg)
;sigma=replicate(1.0,s[1],s[2])
;z = where(sigma gt 0.,count)
;if count ne 0 then sigma[z] = sqrt(avg[z])
;sigall = total(sqrt(sig)/sigma)/sqrt(nimg-1.0)/n_elements(sig)
;sigma = sigma*sigall

;setwin,4,xsize=s[1],ysize=s[2]
;tvscl,sigma

;setwin,4,xsize=s[1],ysize=s[2]
;ans=''

IF not keyword_set(silent) THEN $
   print,'create residual image, ',strn(thresh,format='(f10.1)'),' sigma clipping threshold.'

asum = fltarr(s[1],s[2])
acnt = fltarr(s[1],s[2])
npts = s[1] * s[2]
average = fltarr(s[1],s[2])
for i=0,nimg-1 do begin
   new = arr[*,*,i]
   resid = (new-avg)/sigma
   skysclim,resid,lowval,hival,rmean,rsig
   resid = resid/rsig
   IF not keyword_set(silent) THEN $
      print,i,rsig
;print,minmax(new),minmax(sigma),minmax(resid)
;tvscl,new/sigma > thresh
;asdf
;read,prompt='continue? ',ans
   z = where(abs(resid) lt thresh,count)
   if count ne 0 then begin
	  if keyword_set(weight_by_exptimes) then begin
		  print,"Using weight "+strc(exptimes[i])+" for image "+strc(i+0)+"."
		; NEW WEIGHTED MEAN CODE BY MARSHALL
		if n_elements(exptimes) lt nimg then message,'Need to specify exptimes!'
		asum[z] += arr[z+npts*i]*exptimes[i]
		acnt[z] += exptimes[i]

	  endif else begin
	    ; ORIGINAL CODE BY BUIE
      	asum[z] = asum[z]+arr[z+npts*i]
      	acnt[z] = acnt[z] + 1.0
	  endelse
   endif
endfor
z = where(acnt ne 0,count)
if count ne 0 then begin
   average[z]= asum[z]/acnt[z]
endif

if prescale and not keyword_set(normalize) then average = average*means[0]

IF not keyword_set(silent) THEN $
   print,cr,'     done        '

end

;+
; NAME:
;  skysclim
; PURPOSE:
;  Compute stretch range for a hard stretch on the background in an image.
; DESCRIPTION:
; CATEGORY:
;  Image display
; CALLING SEQUENCE:
;  skysclim,image,lowval,hival,meanval,sigma
; INPUTS:
;  image - 2-d image to compute stretch range for.
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
; OUTPUTS:
;  lowval - Low DN value for sky stretch
;  hival  - High DN value for sky stretch
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  96/01/07 - Marc W. Buie
;-
pro skysclim,image,lowval,hival,meanval,sigma
   idx=randomu(seed,min([601,n_elements(image)]))*(n_elements(image)-1)
;   sub=image[idx]
;   s=sort(sub)
;   subs=sub[s]
;   meanval=subs[50]
;   sigma=stdev(subs[20:80])

	; MDP replace with call to sky...
   ;robomean,image[idx],2.0,0.5,meanval,dummy,sigma

	sky, image[idx], meanval, sigma

   lowval=meanval-3.0*sigma
   hival=meanval+5.0*sigma

end;
;=============================================================================
;=============================================================================



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
	if Combine_Method ne "AVERAGE" and  Combine_Method ne "MEDIAN" and Combine_method ne "AVGCLIP" then return, error ('Error: '+combine_method+' is not a valid combination method.')
    

    ; do the subtraction
    n_Dims = size( *DataSet.Frames[0])
    print, "--Now Combining Frames:--"
    print, "Number of frames = ", nFrames
    print, "Size of each =", n_Dims
	print, "Combining using method = "+combine_method
    if ( n_Dims(0) ne 2 ) then  $
      return, error ('Error, frames must be 2 dimensional')
    if ( n_Dims(1) ne 2048 ) then $
      return, error ('Error, x-dim must be 2048')
    if ( n_Dims(2) ne 2048 ) then $
      return, error ('Error, y-dim must be 2048')

    if ( nFrames lt 2 ) then $
      return, error ('Combframes requires at least 2 frames.')


    ; update for detector upgrade to H2RG:
    ; check Julian date of data: if after Jan. 1st, 2016, 
    ; then readout channel offsets are not adjusted before frames are combined,
    ; because data is from new H2RG detector.
    ; read in header of first frame to get MJD
    jul_date = sxpar(*DataSet.Headers[0], "MJD-OBS", count=num)
    if (jul_date ge 57388.0) then begin
        print, 'Data is from H2RG detector: readout channels do not need to be adjusted for offsets.'
    endif else begin

    itime = float(SXPAR(*DataSet.Headers[0],'ITIME'))
    if ( itime lt 1.0 ) then itime = 2.0
    print, 'itime=', itime

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

  endelse


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
    message,/info, "Now combinining "+string(nframes)+" via method="+combine_method
	
	case combine_method of
	"AVERAGE":  tot = total(tmparr,3,/nan) / total(finite(tmparr),3,/nan)
	"MEDIAN": tot = median(tmparr,dim=3)
	"AVGCLIP": begin
		;message, "AVGCLIP method not yet implemented!!"
		buie_avgclip, tmparr, tot
		end
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

    ; updated code for H2RG (by jlyke, added by A. Boehle - April 2016)
    ; For H2, this file name DOES NOT include the .fits file extension.
    ; For H2RG, this file name DOES include the .fits file extenstion.
    fname = sxpar(*DataSet.Headers[0],'DATAFILE')
    fn = STRSPLIT(fname, '.', /EXTRACT)
    fname = fn[0]
    fname = strtrim(fname,2) + '_combo_'+strtrim(itime,2)
    fname = strtrim(fname,2)
    message,/info, fname
    SXADDPAR,  *DataSet.Headers[0], "DATAFILE", fname
    SXADDPAR,  *DataSet.Headers[0], "COMBMETH", combine_method , "Method for combining frames to make this file"
	SXADDPAR,  *DataSet.Headers[0], "COMB_NUM", nframes, "Number of frames combined to make this file."
	sxaddhist, "Combined "+strtrim(string(nframes),2)+" frames via "+combine_method+" method.", *DataSet.Headers[0]



    report_success, functionName, T

    RETURN, OK

END
