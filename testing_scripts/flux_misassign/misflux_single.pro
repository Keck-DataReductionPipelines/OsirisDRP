pro misflux_single,infile,refchannel=refchannel,plotflux=plotflux

; pass in a single-lenslet-column illuminated arc (reduced cube)
; and indicate the spectral channel of a bright isolated emission
; line with refchannel. Routine finds the illuminated lenslet column,
; calculates the flux in the line across the column, and also finds
; the amount of flux at +/- 32 channels in the adjacent
; spaxels. Returns the percentage of misassigned flux.

cube = mrdfits(infile,0,hdr)
wave = findgen((size(cube))[1])*sxpar(hdr,'CDELT1')+sxpar(hdr,'CRVAL1')

; the illuminated column is the brightest one in the collapsed cube
;img = median(cube,dimension=1)
img = reform(cube[refchannel,*,*])
peak = max(img,peakidx)
idxarr = array_indices(img,peakidx)
; want the entire illuminated column, not just the bright spaxel
ilcol = idxarr[1]
nrow = (size(cube))[2]

; right spaxel/wavelength
flux = fltarr(nrow)
; one column below, -32 channels
misflux1 = fltarr(nrow)
; one column above, +32 channels
misflux2 = fltarr(nrow)
; one column below, right channel
misflux3 = fltarr(nrow)
; one column above, right channel
misflux4 = fltarr(nrow)

reflo = refchannel - 32
refhi = refchannel + 32

for i=0,nrow-1 do begin
   ; get total flux in the correct spaxel/channel
   ; first subtract a smoothed version to get rid of the
   ; continuum level
   tmp = cube[*,i,ilcol]
   tmpsm = medsmooth(tmp,60)
   res = tmp-tmpsm
   ; then total across the spectral channels that contain the line
   tmpflux = total(res[refchannel-14:refchannel+14])
   flux[i] = tmpflux
   ; -32 channels, don't need to subtract continuum
   ; take abs in case some flux is negative
   tmpflux1 = total(abs(cube[reflo-9:reflo+9,i,ilcol-1]))
   misflux1[i] = tmpflux1
   ; +32 channels
   tmpflux2 = total(abs(cube[refhi-9:refhi+9,i,ilcol+1]))
   misflux2[i] = tmpflux2
   ; flux at the right wavelength, wrong spaxel
   tmpflux3 = total(abs(cube[refchannel-9:refchannel+9,i,ilcol-1]))
   misflux3[i] = tmpflux3
   tmpflux4 = total(abs(cube[refchannel-9:refchannel+9,i,ilcol+1]))
   misflux4[i] = tmpflux4
   if keyword_set(plotflux) then begin
      plot,tmp,xrange=[refchannel-50,refchannel+50],yrange=[-5,10],xtitle='Spectral channel',ytitle='DN/s',title='['+string(i,format='(i0)')+','+string(ilcol,format='(i0)')+']'
      oplot,tmpsm,color=cgcolor('cyan')
      oplot,res,color=cgcolor('green')
      oplot,findgen(29)+refchannel-14,res[refchannel-14:refchannel+14],color=cgcolor('red')
      al_legend,['spectrum','smoothed','residuals','summed'],color=['white','cyan','green','red'],linestyle=0
      stop
   endif 
endfor

fluxgood = total(flux)
mistot1 = total(misflux1)
mistot2 = total(misflux2)
mistot3 = total(misflux3)
mistot4 = total(misflux4)
fluxtot = fluxgood+mistot1+mistot2+mistot3+mistot4

print,'Locations of flux: '
print,'Right spaxel, right channel: '+string(100.*fluxgood/fluxtot,format='(f5.2)')+'%'
print,'-1 spaxel, -32 channels: '+string(100.*mistot1/fluxtot,format='(f5.2)')+'%'
print,'+1 spaxel, +32 channels: '+string(100.*mistot2/fluxtot,format='(f5.2)')+'%'
print,'-1 spaxel, right channel: '+string(100.*mistot3/fluxtot,format='(f5.2)')+'%'
print,'+1 spaxel, right channel: '+string(100.*mistot4/fluxtot,format='(f5.2)')+'%'
   
end
