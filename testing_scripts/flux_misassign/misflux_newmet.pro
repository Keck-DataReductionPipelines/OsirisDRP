pro misflux_newmet,infile,refchannel=refchannel,sumspax=sumspax

; pass in a single-lenslet-column illuminated arc (reduced cube)
; and indicate the spectral channel of a bright isolated emission
; line with refchannel. Routine finds the illuminated lenslet column,
; calculates the flux in the line across the column, and also finds
; the amount of flux at +/- 32 channels in the adjacent
; spaxels. Returns the percentage of misassigned flux as a percentage
; of the flux in the illuminated spaxel.
  
; refchannel : spectral channel where the peak of the emission line in
; the illuminated spaxel falls
; /sumspax : if set, sums spaxels in the illuminated column to
; increase S/N

cube = mrdfits(infile,0,hdr,/silent)
wave = findgen((size(cube))[1])*sxpar(hdr,'CDELT1')+sxpar(hdr,'CRVAL1')

; the illuminated column is the brightest one in the collapsed cube
img = reform(cube[refchannel,*,*])
; check if the data are single column or not
sz = size(img)
; longest dimension is along the lenslet column - use that
if sz[1] gt sz[2] then begin
   sumcol = total(img,1)
   midcol = floor(sz[2]/2)
   nrow = sz[1]
endif else begin
   sumcol = total(img,2)
   midcol = floor(sz[1]/2)
   nrow = sz[2]
endelse
; check if the brightest column is that much brighter (then
; it's single column). If not, then it's not single column, and just
; use the middle lenslet column
if max(sumcol) gt (median(sumcol) + 3.*stdev(sumcol)) then begin
   summax = max(sumcol,ilcol)
   print,'Single column data'
endif else begin
   ilcol = midcol
   print,'All column data'
endelse

reflo = refchannel - 32
refhi = refchannel + 32

halfbox = 15
sidehalfbox = 5

if keyword_set(sumspax) then begin
   ;if sz[1] gt sz[2] then tmpcube = total(cube,2) $
   ;else tmpcube = total(cube,3)
   if sz[1] gt sz[2] then tmpcube = median(cube,dimension=2) $
   else tmpcube = median(cube,dimension=3)
   tmp = tmpcube[*,ilcol]
   tmppos = tmpcube[*,ilcol+1]
   tmpneg = tmpcube[*,ilcol-1]
   tmpsm = medsmooth(tmp,60)
   tmppossm = medsmooth(tmppos,60)
   tmpnegsm = medsmooth(tmpneg,60)
   res = tmp - tmpsm
   respos = tmppos - tmppossm
   resneg = tmpneg - tmpnegsm
   peak = max(res[refchannel-halfbox:refchannel+halfbox])
   peakneg = max(abs(resneg[reflo-sidehalfbox:reflo+sidehalfbox]))
   peakpos = max(abs(respos[refhi-sidehalfbox:refhi+sidehalfbox]))
   misflux1 = peakneg/peak
   misflux2 = peakpos/peak

   outpeak = peak
   outmisflux1 = misflux1
   outmisflux2 = misflux2
   
endif else begin
   ; right spaxel/wavelength
   flux = fltarr(nrow)
   peak = fltarr(nrow)
   ; one column below, -32 channels
   misflux1 = fltarr(nrow)
   ; one column above, +32 channels
   misflux2 = fltarr(nrow)

   for i=0,nrow-1 do begin
      ; get total flux in the correct spaxel/channel
      ; first subtract a smoothed version to get rid of the
      ; continuum level
      if sz[1] gt sz[2] then begin
         tmp = cube[*,i,ilcol]
         tmppos = cube[*,i,ilcol+1]
         tmpneg = cube[*,i,ilcol-1]
      endif else begin
         tmp = cube[*,ilcol,i]
         tmppos = cube[*,ilcol+1,i]
         tmpneg = cube[*,ilcol-1,i]
      endelse
      tmpsm = medsmooth(tmp,60)
      res = tmp-tmpsm
      ; then total across the spectral channels that contain the line
      tmpflux = total(res[refchannel-halfbox:refchannel+halfbox])
      tmppeak = max(res[refchannel-halfbox:refchannel+halfbox])
      flux[i] = tmpflux
      peak[i] = tmppeak
      ; -32 channels
      ; take abs in case some flux is negative
      tmpnegsm = medsmooth(tmpneg,60)
      resneg = tmpneg - tmpnegsm
      tmpnegpeak = max(abs(resneg[reflo-sidehalfbox:reflo+sidehalfbox]))
      if tmppeak eq 0. then misflux1[i] = 0. else $
      misflux1[i] = tmpnegpeak/tmppeak
      ; +32 channels
      tmppossm = medsmooth(tmppos,60)
      respos = tmppos - tmppossm
      tmppospeak = max(abs(respos[refhi-sidehalfbox:refhi+sidehalfbox]))
      if tmppeak eq 0. then misflux2[i] = 0. else $
      misflux2[i] = tmppospeak/tmppeak
   endfor

   outpeak = median(peak)
   outmisflux1 = median(misflux1)
   outmisflux2 = median(misflux2)
endelse 

print,'Average peak flux, right channel: '+string(outpeak,format='(f8.1)')
print,'Peak flux, -1 spaxel, -32 channels: '+string(100.*outmisflux1,format='(f5.2)')+'%'
print,'Peak flux, +1 spaxel, +32 channels: '+string(100.*outmisflux2,format='(f5.2)')+'%'

;stop
end
