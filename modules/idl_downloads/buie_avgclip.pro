;=============================================================================
;+
; NAME:
;   buie_avgclip
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
;   2010-03-01. MDP: Removed badpar.pro dependency for OSIRIS distribution
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

;if badpar(thresh,[0,2,3,4,5],0,caller='AVGCLIP: (THRESH) ',default=3.0) then return
if ~(keyword_set(thresh)) then thresh=3

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
