;+
;
; NAME: ql_aperture
;
; PURPOSE:
;	Performs single object, single aperture photometry and returns
;	magnitude of object.
;
; INPUTS:
;	IMAGE:  Input image array.
;
;	XCENTER:  X location of center of aperture.
;
;	YCENTER:  Y location of center of aperture.
;
;	APER:	Radius, in pixels, of aperture.
;
;	INNER_AN:  Radius, in pixels, of inner sky annulus.
;
;	OUTER_AN:  Radius, in pixels, of outer sky annulus.
;
;
; OPTIONAL INPUTS:
;	ITIME:  Integration time of image.  Default is 1.0 seconds.
;
;	ZMAG:  Zero Magnitude. Default is 0.
;
;	BADPIX_LIMITS:  2 element vector giving the low and high limits for
;			valid pixels.
;
; OUTPUTS:
;	Returns corrected magnitude of object.  Calculated as:
;		m=zmag-2.5*log(cor_counts/itime)
;	where cor_counts is the sky corrected number of counts within the
;	aperture:
;		cor_counts=counts-(mean_sky*numpix_aper)
;	where numpix_aper is the number of pixels within the aperture.
;	
;	Returns NaN (Not a Number, !VALUE.D_NAN) on error.
;
;
; OPTIONAL OUTPUTS:
;
;	COUNTS:  Number of counts within aperture.
;
;	MEAN_SKY:  Mean value of each pixel between the sky annuli.
;
;	COR_COUNTS:  Sky corrected number of counts within aperture.(see above)
;
; REVISION HISTORY:
;	Jan 26, 2000 -- Jason L. Weiss (UCLA): written, with some code borrowed
;			from aper.pro from the astrolib.
;
;-

function ql_aperture, image, xcenter, ycenter, aper, inner_an, outer_an, $
	itime=itime, zmag=zmag, badpix_limits=badpix_limits, counts=counts, $
	mean_sky=mean_sky, cor_counts=cor_counts


NaN=!VALUES.D_NAN

; error checking for negative inputs
if (aper le 0.0) then begin
	print, 'Error: aperture < 0.'
	return, NaN
endif
if (inner_an le 0.0) then begin
	print, 'Error: Inner Sky Annulus < 0.'
	return, NaN
endif
if (outer_an le 0.0) then begin
	print, 'Error: Outer Sky Annulus < 0.'
	return, NaN
endif

; set default itime as 1.0 s
if not keyword_set(itime) then itime=1.0
; make sure itime > 0
if itime le 0.0 then begin
	print, 'Error: Itime < 0."
	print, 'Warning: Using Itime=1.0'
	itime=1.0
endif

; set default zero mag as 0.0
if not keyword_set(zmag) then zmag=0.0

; if limits are not given, assign the limits to +/- infinity.
; otherwise, make sure badpix_limits[0] < badpix_limits[1]
if not keyword_set(badpix_limits) then $
	badpix_limits=[-!VALUES.D_INFINITY, !VALUES.D_INFINITY] $
else begin
	if n_elements(badpix_limits) eq 2 then $
		badpix_limits=badpix_limits[sort(badpix_limits)] $
	else begin
		print, 'Error: badpix_limits variable must have 2 elements.'
		print, 'Warning: Not using badpix_limits.'
		badpix_limits=[-!VALUES.D_INFINITY, !VALUES.D_INFINITY]
	endelse
endelse

imsize=size(image)
if (imsize[0] ne 2) then begin
	print, 'Error: Image must be two dimensional'
	return, NaN
endif else begin
	im_xs=double(imsize[1])
	im_ys=double(imsize[2])
endelse

; check validity of centers
if xcenter lt 0 or xcenter ge im_xs or ycenter lt 0 or ycenter ge im_ys $
	then begin
	print, 'Error: Aperture center must be in image.'
	return, NaN
endif

; check validity of radii
if (inner_an gt outer_an) then begin
	print, 'Error: Outer Sky Annulus must be bigger than ', $
		'Inner Sky Annulus.'
	print, 'Warning: Using 0 for Sky.'
	skyarr=dblarr(1)
endif else begin
	;  Compute the limits of the submatrix.
	an_left = fix(xcenter-outer_an) > 0            ;Lower limit X direction
	an_right = fix(xcenter+outer_an) < (im_xs-1)   ;Upper limit X direction
	an_xs = an_right-an_left+1		  ;Number of pixels X direction
	an_bottom = fix(ycenter-outer_an) > 0	       ;Lower limit Y direction
	an_top = fix(ycenter+outer_an) < (im_ys-1)     ;Upper limit Y direction
	an_ys = an_top-an_bottom+1		  ;Number of pixels Y direction
	an_xc = xcenter-an_left			  ;Object's xcenter in subarray
	an_yc = ycenter-an_bottom                 ;Object's ycenter in subarray

	;Extract subarray from image
	skybuf = image[an_left:an_right, an_bottom:an_top]

	; RSQ will be an array, the same size as SKYBUF containing the 
	; square of the distance of each pixel to the center pixel.
	dxsq = (dindgen(an_xs)-an_xc)^2
	rsq = dblarr(an_xs, an_ys)

	for i=0, an_ys-1 do rsq[0,i]=dxsq+(i-an_yc)^2

	; Select pixels within sky annulus, and eliminate pixels outside of 
	; bad pixel limits. SKYARR will be 1-d array of sky pixels
	an_valid=where((rsq ge (double(inner_an)^2)) and $
		(rsq le (double(outer_an)^2)) and  $ 
		(skybuf gt badpix_limits[0]) and (skybuf lt badpix_limits[1]))
	if an_valid[0] eq -1 then begin
		print, 'Error: No valid pixels in between sky annuli.'
		print, 'Warning: Using 0 for Sky.'
		skyarr=dblarr(1)
	endif else skyarr = skybuf[an_valid]       
endelse

; get aperture counts
;  Compute the limits of the submatrix.
aper_left = fix(xcenter-aper) > 0		;Lower limit X direction
aper_right = fix(xcenter+aper) < (im_xs-1)	;Upper limit X direction
aper_xs = aper_right-aper_left+1		;Number of pixels X direction
aper_bottom = fix(ycenter-aper) > 0		;Lower limit Y direction
aper_top = fix(ycenter+aper) < (im_ys-1)	;Upper limit Y direction
aper_ys = aper_top-aper_bottom+1		;Number of pixels Y direction
aper_xc = xcenter-aper_left			;Object's xcenter in subarray
aper_yc = ycenter-aper_bottom			;Object's ycenter in subarray

;Extract subarray from image
aperbuf = image[aper_left:aper_right, aper_bottom:aper_top] 

; APER_RSQ will be an array, the same size as APERBUF containing the 
; square of the distance of each pixel to the center pixel.

aper_dxsq = (dindgen(aper_xs)-aper_xc)^2
aper_rsq = dblarr(aper_xs, aper_ys)
for i=0, aper_ys-1 do aper_rsq[0,i]=aper_dxsq+(i-aper_yc)^2

; Select pixels within aperature, and eliminate pixels outside of 
; bad pixel limits. APERARR will be 1-d array of aper pixels

aper_valid=where((aper_rsq le (double(aper)^2)) and $
	(aperbuf gt badpix_limits[0]) and (aperbuf lt badpix_limits[1]))
if aper_valid[0] eq -1 then begin
	print, 'Error: No valid pixels in aperature.'
	return, NaN
endif else aperarr = aperbuf[aper_valid]       

; get total value of pixels in aperture
counts=total(aperarr, /double)
; get number of pixels in aperture
numpix_aper=n_elements(aperarr)

; find mean sky value
mean_sky=mean(skyarr, /double)

; subtract sky from aperture counts
cor_counts=(counts-mean_sky*double(numpix_aper))

; if a non-positive corrected counts (i.e. more sky than signal), set 
; cor_counts equal to itime so that magnitude returned is equal to
; the zero magnitude
if cor_counts le 0 then cor_counts_temp=itime else cor_counts_temp=cor_counts

; calculate magnitude of object
mag=zmag-2.5*alog10(cor_counts_temp/itime)

; return value
return, mag

end
