pro solve_global_wave_2017
; James Larkin April 4, 2016
; Pretty major changes for new detector. Still use basic 2x2 rotation
; and displacement matrix to map a central wavelength from lenslet
; 26,19 to central wavelength of all the other lenslets. But
; variability in dispersion also needs to be accounted for. It only
; has a strong dependency on the column and not on the row.

; modified slightly for 2017 - T. Do (2017-07-27)
  
basename="s170527_c005001.fits.gz"
length = strlen(basename)
bck = readfits(basename)

base2name="s170527_c005001.fits.gz"

numlam = 14    ; Number of wavelengths
box_half = 8   ; Half width of the gaussian box
order = 3      ; Order for polynomial fit
xlen = 51      ; number of columns in lenslet array
ylen = 66      ; Number of rows in lenslet arry
midwave = 2200.0 ; This is an offset in wavelength for the fits.

valid = intarr(xlen,ylen)
xfwhm=fltarr(numlam,xlen,ylen)
yfwhm=fltarr(numlam,xlen,ylen)
xcen =fltarr(numlam,xlen,ylen)
ycen =fltarr(numlam,xlen,ylen)
gxcen =fltarr(numlam,xlen,ylen)
gycen =fltarr(numlam,xlen,ylen)
coeffs = fltarr(order+1,xlen,ylen)
sigma = fltarr(xlen, ylen)   ; Wavelength error for arc line fits for each lenslet
pred_pos = fltarr(numlam,xlen, ylen)


x2cen =fltarr(numlam,xlen,ylen)
coeffs2 = fltarr(order+1,xlen,ylen)
sigma2 = fltarr(xlen, ylen)   ; Wavelength error for arc line fits for each lenslet
pred_pos2 = fltarr(numlam,xlen, ylen)

; Indexes used by the gaussian fit.
xloc = findgen(2048)
yloc = findgen(2048)

; Create arrays to hold fine sampling of wavelength
final_size=1600
new_lam = fltarr(final_size)
for i = 0, (final_size - 1) do begin
    new_lam[i]=(1970.0+float(i)*(2400.0-1970.0)/float(final_size))-midwave
end
locations=fltarr(final_size, xlen,ylen)

; cx and cy store the reference location of the important arclines in
; the 19th spectrum of the 28th frame of the scan (scan position
; 25). This is also the 26th column counting from the left starting at
; zero. So it is 26 offsets from the left most spectrum.
; This will later be referred to as lenslet [26,19]

; Ar Ne Kr Xe
; Lambda contains the vacuum wavelengths of the lines corresponding to
; the positions in the cx and cy arrays. Unit is microns 
; Scale ~ 0.28 microns/pixel
;lamp = [         Ar,        Ne,        Ne,        Ne,        Ar,        Ne,        Ar,        Kr,        Ar,        Kr,        Ar,        Ar,        Xe,        Ar]
inten = [        2.5,         5,        15,         3,         5,         6,         5,        35,         5,         6,        10,        20,        10,         3]
; Below are new centroids for 2016 data
cx = [           371,       419,       444,       576,       621,       833,       993,      1055,      1186,      1317,      1381,      1513,      1640,      1800]
cy = [          1434,      1434,      1434,      1434,      1434,      1435,      1435,      1435,      1435,      1436,      1436,      1436,      1436,      1436]
lambda = [  2385.154, 2371.5599, 2364.2934, 2326.6619,  2313.952, 2253.6528,  2208.321, 2190.8506,  2154.009, 2117.1260,  2099.194,  2062.186,  2026.777,  1982.291]
lambda = lambda - midwave

; Create an array for how far each spectral line is from spectral line
; 7 in spectrum [26,19] in the x-direction. This is what is used in
; combination with the resolution factor to go from the central
; wavelength to the other wavelengths in each spectrum.
cenwave=7
delx=cx-cx[cenwave]

; Create arrays to keep track of missed boxes
lx_off=fltarr(numlam)
ly_off=fltarr(numlam)
num_off=fltarr(numlam)
num_misses=fltarr(numlam)

; How to offset from one spectrum to the next.
; Spectra start the numbering at the upper left spectrum in the raw
; frame. This is 1,1 and winds up at the bottom left of the reduced
; spectrum. 

; The ox variable is how much to move the location of an arcline's 
; search box in the x-direction. The first element is how much to move
; as the column is changed, and the second element is how much to
; move as the row is changed.
ox = [29.12,-1.915]
; The oy variable is how much to move the location of an arcline's 
; search box in the y-direction. The first element is how much to move
; as the column is changed, and the second element is how much to
; move as the row is changed.
oy = [-2.019, -31.792]

; To map the central wavelength's location to other wavelengths we
; need to take into account the variable resolution with column
; number.
; We define resolution(26) =1.0 for column 26.
resolution = 1.0+(findgen(xlen)- 26.0)*0.000601

; Set the valid flag for all of the pixels to 1, then mark the pixels
; that aren't on the array as 0.
valid = valid + 1
; There are 3055 valid lenslets after masking.
valid[0,18:ylen-1] = 0
valid[1,34:ylen-1] = 0
valid[2,50:ylen-1] = 0
valid[48,0:15] = 0
valid[49,0:31] = 0
valid[50,0:47] = 0
valid[0:31,0] = 0
valid[0:15,1] = 0
; Upper row of lenslets (bottom of detector) has missing lenslets
;valid[43:(xlen-1),63] = 0
;valid[27:(xlen-1),64] = 0
;valid[12:(xlen-1),65] = 0
valid[39:(xlen-1),63] = 0
valid[26:(xlen-1),64] = 0
valid[11:(xlen-1),65] = 0

for number = 4, 54 do begin
    i = xlen-(number - 3) ; This is the column number 0-50
    deltax=delx*resolution[i] ; Scale the x offsets between lines
    if ( number gt 9 ) then begin
        ending = '0' + strtrim(STRING(number),2)
    endif else begin
        ending = '00' + strtrim(STRING(number),1)
    end
    
    filename = basename
    strput, filename, ending, length-11
    print, "Filename = ",filename

    array = readfits(filename)
    array = array - bck

;    filename = base2name
;    strput, filename, ending, length-8
;    print, "Filename = ",filename

;    array2 = readfits(filename)
;    array2 = array2 - bck

                                ; Since the data was taken after the
                                ; board swap in the Leach controllers
                                ; in late 2011, we need to rotate one
                                ; of the channels by one pixel.
; Commented out for new detector
;    quad=array2[1408:1535,0:1024] ; Grab the output channel
;    quad[0:131070]=quad[1:131071] ; linearly shift the channel
;    array2[1408:1535,0:1024]=quad ; Put it back in the array

    for j = 0, (ylen-1) do begin
        if ( valid[i,j] eq 1 ) then begin
            for lam = 0, (numlam-1) do begin
                                ; Calculate the box to use for calculating the center of each line.
                gx = cx[cenwave]+fix(deltax[lam]+(ox[0]*float(i-26))+(ox[1]*float(j-19)) )
                gy = cy[cenwave]+fix( (oy[0]*float(i-26))+(oy[1]*float(j-19)) )
                gxcen[lam,i,j] = gx
                gycen[lam,i,j] = gy
                sx = gx - box_half
                sy = gy - box_half
                fx = sx + 2*box_half
                fy = sy + 2*box_half
                
                if ( (gx ge 2) and (gy ge 2) and (gx lt 2045) and (gy lt 2045) ) then begin
                    sx = sx>0
                    sy = sy>0
                    fx = fx<2047
                    fy = fy<2047
			A=fltarr(6)
                        result = gauss2dfit(array[sx:fx, sy:fy], A, xloc[sx:fx], yloc[sy:fy])

                        ;; diagnostics
                        ;;if filename eq "s170527_c005021.fits.gz" then begin
                        ;;   print, A
                        ;;endif
                        if (A[2] lt 0) or (A[3] lt 0) then begin
                           print, 'bad fit:', a
                        endif


;                    result=mpfit2dpeak(array[sx:fx,sy:fy],A, xloc[sx:fx], yloc[sy:fy])
                    xfwhm[lam,i,j]=A[2]*2.35
                    yfwhm[lam,i,j]=A[3]*2.35
                    xcen[lam,i,j]=A[4]
                    ycen[lam,i,j]=A[5]
			A=fltarr(6)
; removed 2016                    result=mpfit2dpeak(array2[sx:fx,sy:fy],A, xloc[sx:fx], yloc[sy:fy])
;                    result=gauss2dfit(array2[sx:fx,sy:fy],A, xloc[sx:fx], yloc[sy:fy])
;                    x2cen[lam,i,j]=A[4]
                    if ( (abs(xcen[lam,i,j]-gx) le box_half) and (abs(ycen[lam,i,j]-gy) le box_half) ) then begin
                        lx_off[lam]=lx_off[lam]+xcen[lam,i,j]-gx                        
                        ly_off[lam]=ly_off[lam]+ycen[lam,i,j]-gy
                        num_off[lam] = num_off[lam]+1
                    end
                    if ( (abs(xcen[lam,i,j] - gx) gt 5.0) or (abs(ycen[lam,i,j] - gy) gt 5.0) ) then begin
                        xfwhm[lam,i,j]=0.0
                        yfwhm[lam,i,j]=0.0
                        xcen[lam,i,j]=-1000.0
                        ycen[lam,i,j]=0.0
                        num_misses[lam] = num_misses[lam]+1
                    end
 ;                   if ( (abs(x2cen[lam,i,j] - gx) gt 5.0) or (abs(A[5]-gy) gt 5.0) ) then begin
 ;                       x2cen[lam,i,j]=-1000.0
 ;                   end
 ;                   if ( (xcen[lam,i,j] gt 0) and (x2cen[lam,i,j] lt 0) ) then begin
 ;                       x2cen[lam,i,j] = xcen[lam,i,j]   ; Replace bad values of one with the other
 ;                   endif else begin
 ;                       if ( x2cen[lam,i,j] gt 0 ) then begin
 ;                           xcen[lam,i,j] = x2cen[lam,i,j]  ; if only 2 is valid, replace 1
 ;                       endif
 ;                   end
                endif else begin
                    xfwhm[lam,i,j]=0.0
                    yfwhm[lam,i,j]=0.0
                    xcen[lam,i,j]=-1000.0
  ;                  x2cen[lam,i,j]=-1000.0
                    ycen[lam,i,j]=0.0
                end
            end

            ok = where( (xcen[*,i,j] gt 0), count )
            if ( count gt 3 ) then begin
                torder = (count-2)<order 
                result = poly_fit(lambda[ok],xcen[ok,i,j],torder,sigma=dis,status=check)
                if (check eq 0) then begin
                    coeffs[*,i,j]=0.0
                    coeffs[0:torder,i,j]=result
                    pred_pos[ok,i,j]=poly(lambda[ok],result)
                    sigma[i,j] = stddev( (pred_pos[ok,i,j]-xcen[ok,i,j]) )
;                    locations[*,i,j]=poly(new_lam,result)
                end
            endif

   ;         ok = where( (x2cen[*,i,j] gt 0), count )
   ;         if ( count gt 3 ) then begin
   ;             torder = (count-2)<order 
  ;              result = poly_fit(lambda[ok],x2cen[ok,i,j],torder,sigma=dis,status=check)
  ;              if (check eq 0) then begin
  ;                  coeffs2[*,i,j]=0.0
  ;                  coeffs2[0:torder,i,j]=result
  ;                  pred_pos2[ok,i,j]=poly(lambda[ok],result)
  ;                  sigma2[i,j] = stddev( (pred_pos2[ok,i,j]-x2cen[ok,i,j]) )
; ;                   locations[*,i,j]=poly(new_lam,result)
  ;              end
  ;          endif

  ;          if ( sigma2[i,j] lt sigma[i,j] ) then begin
  ;              coeffs[*,i,j] = coeffs2[*,i,j]
  ;              sigma[i,j] = sigma2[i,j]
  ;          endif

;            plot, new_lam+midwave, locations[*,i,j], xrange=[1980,2400], yrange=[0, 2000]
;            wait, 0.25
        end
    end
end

for lam = 0, (numlam-1) do begin
    lx_off[lam]=lx_off[lam]/num_off[lam]
    ly_off[lam]=ly_off[lam]/num_off[lam]
end
plot, lx_off
oplot, ly_off

writefits,'coeffs_may2017.fits',coeffs
writefits,'sigma_may2017.fits', sigma
writefits,'xfwhm_may2017.fits', xfwhm
writefits,'yfwhm_may2017.fits', yfwhm
writefits,'wavelength_may2017.fits', lambda
writefits,'locations_may2017.fits', locations


end
